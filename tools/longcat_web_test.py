#!/usr/bin/env python3
"""longcat_web_test.py — guest pipeline tester for longcat.ai/chat.

Drives the real website (guest, no login) like the chatglm project does:
sends the Donkey Calendar system prompt + a deadline message, then validates
the AI reply contains a well-formed create_event tool call.

Usage:
  python3 tools/longcat_web_test.py ["message"] [--model-note]

Needs: /tmp/chatglm-env (playwright + chromium) or any playwright install.
Stdlib + playwright only. Guest quota is IP-limited; 429s mean "wait and retry".
"""
import json
import re
import sys
import time

URL = "https://longcat.ai/chat/"

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


def extract_tool_call(text):
    start = text.find("<tool_call>")
    if start == -1:
        return None, "no <tool_call> block"
    end = text.find("</tool_call>", start)
    if end == -1:
        return None, "incomplete <tool_call>"
    raw = text[start + 11:end].strip()
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
        return None, "unbalanced JSON"
    try:
        call = json.loads(candidate)
    except json.JSONDecodeError as e:
        return None, f"invalid JSON: {e}"
    if not isinstance(call, dict) or "name" not in call or not isinstance(call.get("arguments"), dict):
        return None, "missing name/arguments"
    return call, None


def main():
    message = sys.argv[1] if len(sys.argv) > 1 and not sys.argv[1].startswith("--") else "mam said leetcode problems on 9th"
    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        print("playwright not installed. Run: /tmp/chatglm-env/bin/python3 tools/longcat_web_test.py ...")
        return 3
    with sync_playwright() as pw:
        b = pw.chromium.launch(headless=True, args=["--no-sandbox", "--disable-blink-features=AutomationControlled"])
        pg = b.new_page(
            user_agent="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/125.0.0.0 Safari/537.36",
            viewport={"width": 1280, "height": 800}, locale="en-US")
        statuses = []
        pg.on("response", lambda r: statuses.append((r.status, r.url[:100]))
              if "chat-completion" in r.url else None)
        print("loading longcat.ai/chat ...")
        pg.goto(URL, wait_until="load", timeout=60000)
        try:
            pg.wait_for_selector("[contenteditable=true]", timeout=30000)
        except Exception:
            print("FAIL: no chat input (login wall?)")
            return 1
        pg.wait_for_timeout(4000)
        full = f"{SYSTEM_PROMPT}\n\nUser message: {message}"
        pg.click("[contenteditable=true]", force=True)
        pg.wait_for_timeout(400)
        # paste in chunks to avoid typing all day
        pg.evaluate("""(t) => {
          const ed = document.querySelector('[contenteditable=true]');
          ed.focus();
          document.execCommand('selectAll', false, null);
          document.execCommand('insertText', false, t);
        }""", full)
        pg.wait_for_timeout(500)
        pg.keyboard.press("Enter")
        print("sent, waiting (up to 3 min) ...")
        baseline = pg.evaluate("() => document.body.innerText.length")
        start, stable, last = time.time(), time.time(), ""
        answer = ""
        while time.time() - start < 180:
            time.sleep(3)
            body = pg.evaluate("() => document.body.innerText")
            if any(m in body for m in ("Too many requests", "try again later")):
                print("RATE LIMITED by guest quota (429). Wait and retry later.")
                return 2
            text = body[baseline:].strip() if len(body) > baseline else ""
            if text != last:
                last, stable = text, time.time()
            elif text and time.time() - stable > 5 and time.time() - start > 10:
                answer = text
                break
        b.close()
    if not answer:
        print("FAIL: no answer arrived")
        return 1
    print("--- reply tail ---")
    print(answer[-800:])
    call, err = extract_tool_call(answer)
    if err:
        print(f"PIPELINE FAIL: {err}")
        return 1
    args = call["arguments"]
    problems = []
    if not args.get("title"):
        problems.append("missing title")
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", str(args.get("date", ""))):
        problems.append(f"bad date: {args.get('date')!r}")
    if args.get("category") not in ("academic", "coding", "exam", "assignment", "personal", "other"):
        problems.append(f"bad category: {args.get('category')!r}")
    if problems:
        print("PIPELINE FAIL:", "; ".join(problems))
        return 1
    print(f"PIPELINE PASS: {call['name']} title={args['title']!r} "
          f"date={args['date']!r} category={args.get('category')!r}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
