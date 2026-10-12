#!/usr/bin/env python3
"""longcat_test.py — contract + pipeline tester for the LongCat backend.

Usage:
  python3 tools/longcat_test.py models
  python3 tools/longcat_test.py chat "hello" [--key KEY] [--model MODEL]
  python3 tools/longcat_test.py calendar "mam said leetcode problems on 9th" [--key KEY]
  python3 tools/longcat_test.py image photo.jpg "Extract exams" [--key KEY]

Key via --key or LONGCAT_API_KEY env. Without a key only contract checks run.
Stdlib only.
"""
import json
import os
import sys
import urllib.request
import urllib.error

BASE = "https://api.longcat.chat/openai/v1"
DEFAULT_MODEL = "LongCat-Flash-Chat"

SYSTEM_PROMPT = """You are Donkey Calendar AI, a private student calendar assistant.
Your job is to convert the user's messages and images into calendar events.
Today is Monday, 2026-10-12. User timezone: Asia/Karachi.
Rules:
1. Extract deadlines, exams, assignments, submissions, classes, and reviews.
2. Infer dates carefully. "9th" without a month = nearest upcoming 9th.
3. Always set "category" to one of: academic, coding, exam, assignment, personal, other.
4. Do not invent information.
5. If the date or title is unclear, ask a short clarifying question.
6. If the user wants to add an event, respond using the tool_call XML format below - and only that.
7. For one event, use create_event. For multiple events, use create_events_batch.
8. Keep titles short and useful.
Tool format:
<tool_call>
{"name": "create_event", "arguments": {"title": "string, required",
"date": "YYYY-MM-DD, required", "start_time": "HH:mm or null",
"end_time": "HH:mm or null", "all_day": "boolean",
"location": "string or null", "course": "string or null",
"category": "academic|coding|exam|assignment|personal|other",
"notes": "string or null", "reminder": "boolean"}}
</tool_call>"""


def api(path, key, payload=None, stream=False):
    url = BASE + path
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(
        url, data=data,
        headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"},
        method="POST" if payload is not None else "GET")
    try:
        resp = urllib.request.urlopen(req, timeout=120)
        if stream:
            return _read_stream(resp)
        return resp.status, resp.read().decode()
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()


def _read_stream(resp):
    text = ""
    for raw in resp:
        line = raw.decode(errors="replace").strip()
        if not line.startswith("data:"):
            continue
        payload = line[5:].strip()
        if payload == "[DONE]":
            break
        try:
            j = json.loads(payload)
            delta = j["choices"][0].get("delta", {}).get("content", "")
            if delta:
                text += delta
                print(delta, end="", flush=True)
        except (json.JSONDecodeError, KeyError, IndexError):
            pass
    print()
    return resp.status, text


def cmd_models(key):
    if not key:
        print("contract check: GET /models without key ...")
        status, body = api("/models", "bad-key")
        print(f"  -> {status} {body[:120]}")
        print("PASS: endpoint live, rejects bad keys" if status == 401 else "FAIL")
        return
    status, body = api("/models", key)
    print(f"-> {status}\n{body[:800]}")


def cmd_chat(key, message, model):
    if not key:
        print("need a key: --key KEY or LONGCAT_API_KEY")
        return
    status, _ = api("/chat/completions", key, {
        "model": model,
        "messages": [{"role": "user", "content": message}],
        "max_tokens": 500, "temperature": 0.3,
        "thinking": {"type": "disabled"}, "stream": True}, stream=True)
    print(f"[http {status}]")


def extract_tool_call(text):
    start = text.find("<tool_call>")
    if start == -1:
        return None, "no <tool_call> block"
    end = text.find("</tool_call>", start)
    if end == -1:
        return None, "incomplete <tool_call> (no closing tag)"
    raw = text[start + len("<tool_call>"):end].strip()
    # brace-depth extraction
    i = raw.find("{")
    depth, instr, esc = 0, False, False
    for j in range(i, len(raw)):
        c = raw[j]
        if instr:
            if esc:
                esc = False
            elif c == "\\":
                esc = True
            elif c == '"':
                instr = False
        elif c == '"':
            instr = True
        elif c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                candidate = raw[i:j + 1]
                break
    else:
        return None, "unbalanced JSON braces"
    try:
        call = json.loads(candidate)
    except json.JSONDecodeError:
        fixed = candidate.replace(",", "}")
        try:
            call = json.loads(fixed)
        except json.JSONDecodeError as e:
            return None, f"invalid JSON: {e}"
    if not isinstance(call, dict) or "name" not in call or not isinstance(call.get("arguments"), dict):
        return None, "missing name/arguments"
    return call, None


def cmd_calendar(key, message, model):
    if not key:
        print("need a key: --key KEY or LONGCAT_API_KEY")
        return
    print("sending calendar pipeline prompt ...")
    status, reply = api("/chat/completions", key, {
        "model": model,
        "messages": [{"role": "system", "content": SYSTEM_PROMPT},
                     {"role": "user", "content": message}],
        "max_tokens": 800, "temperature": 0.3,
        "thinking": {"type": "disabled"}, "stream": True}, stream=True)
    print(f"[http {status}]")
    call, err = extract_tool_call(reply)
    if err:
        print(f"PIPELINE FAIL: {err}")
        print("--- raw reply ---"); print(reply[:600])
        return
    args = call["arguments"]
    problems = []
    if not args.get("title"):
        problems.append("missing title")
    import re
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", str(args.get("date", ""))):
        problems.append(f"bad date: {args.get('date')!r}")
    if args.get("category") not in (
            "academic", "coding", "exam", "assignment", "personal", "other"):
        problems.append(f"bad category: {args.get('category')!r}")
    if problems:
        print("PIPELINE FAIL:", "; ".join(problems))
    else:
        print(f"PIPELINE PASS: {call['name']} title={args['title']!r} "
              f"date={args['date']!r} category={args.get('category')!r}")


def cmd_image(key, path, message, model):
    import base64
    if not key:
        print("need a key: --key KEY or LONGCAT_API_KEY")
        return
    with open(path, "rb") as f:
        blob = f.read()
    ext = path.rsplit(".", 1)[-1].lower()
    mime = {"png": "image/png", "webp": "image/webp"}.get(ext, "image/jpeg")
    print(f"sending {len(blob)} bytes as {mime} ...")
    status, reply = api("/chat/completions", key, {
        "model": model,
        "messages": [{"role": "user", "content": [
            {"type": "text", "text": message},
            {"type": "image_url",
             "image_url": {"url": f"data:{mime};base64," + base64.b64encode(blob).decode()}}]}],
        "max_tokens": 800, "temperature": 0.3,
        "thinking": {"type": "disabled"}, "stream": True}, stream=True)
    print(f"[http {status}]")
    if status != 200:
        print("VISION REJECTED:", reply[:300])


def main(argv):
    key = os.environ.get("LONGCAT_API_KEY", "")
    model = DEFAULT_MODEL
    args = []
    i = 1
    while i < len(argv):
        if argv[i] == "--key" and i + 1 < len(argv):
            key, i = argv[i + 1], i + 2
        elif argv[i] == "--model" and i + 1 < len(argv):
            model, i = argv[i + 1], i + 2
        else:
            args.append(argv[i]); i += 1
    if not args or args[0] not in ("models", "chat", "calendar", "image"):
        print(__doc__.split("\n\n")[1])
        return 1
    cmd, rest = args[0], args[1:]
    if cmd == "models":
        cmd_models(key)
    elif cmd == "chat":
        cmd_chat(key, rest[0] if rest else "Say hi in five words.", model)
    elif cmd == "calendar":
        cmd_calendar(key, rest[0] if rest else "mam said leetcode problems on 9th", model)
    elif cmd == "image":
        if not rest:
            print("usage: image PHOTO.JPG [prompt]")
            return 1
        cmd_image(key, rest[0], rest[1] if len(rest) > 1 else "Extract exams from this image.", model)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
