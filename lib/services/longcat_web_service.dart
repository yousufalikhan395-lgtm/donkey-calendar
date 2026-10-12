import 'dart:async';
import 'dart:convert';

import 'package:webview_flutter/webview_flutter.dart';

/// Drives longcat.ai/chat (guest, no login) inside a hidden WebView.
/// Real browser = H5guard risk SDK signs requests transparently, so the
/// phone runs its own independent session — no middleman, no API key.
///
/// Verified against the live site: contenteditable input, Enter submits,
/// assistant streams into the page, ~10s answers, guest 429s when over quota.
class LongcatWebService {
  static const homeUrl = 'https://longcat.ai/chat/';

  static const _limitMarkers = [
    'Too many requests',
    'try again later',
    'please log in',
    'please login',
    'Log in to continue',
  ];

  WebViewController? _controller;
  bool _cancelFlag = false;
  int _baselineLen = 0;

  void attach(WebViewController controller) => _controller = controller;

  WebViewController get _c {
    final c = _controller;
    if (c == null) throw Exception('Browser not ready yet. Please retry.');
    return c;
  }
  // ignore: unnecessary_null_comparison

  Future<String> _evalStr(String js) async {
    try {
      final r = await _c.runJavaScriptReturningResult(js);
      return r.toString();
    } catch (_) {
      return '';
    }
  }

  Future<void> ensureReady() async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final hasInput = await _evalStr(
            '(() => !!document.querySelector("[contenteditable=true]"))()');
        if (hasInput != 'true') {
          await _c.loadRequest(Uri.parse(homeUrl));
        }
        if (await _waitFor(
            '(() => !!document.querySelector("[contenteditable=true]"))()',
            const Duration(seconds: 45))) {
          return;
        }
      } catch (_) {}
      await Future.delayed(const Duration(seconds: 2));
    }
    throw Exception('Could not load longcat.ai — check your connection and retry.');
  }

  Future<bool> _waitFor(String conditionJs, Duration timeout) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      if (await _evalStr(conditionJs) == 'true') return true;
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return false;
  }

  /// Best-effort: switch off Search/Think toggles for faster extraction.
  Future<void> _calmToggles() async {
    try {
      await _evalStr('''
(() => {
  const out = [];
  document.querySelectorAll('button').forEach(b => {
    const t = (b.innerText || '').trim().toLowerCase();
    if ((t === 'search' || t === 'think') && b.getAttribute('aria-pressed') !== 'false') {
      // Only click if it looks active; harmless otherwise.
      if (b.className && /active|on|selected|enabled/i.test(b.className.toString())) { b.click(); out.push(t); }
    }
  });
  return out.join(',');
})()
''');
    } catch (_) {}
  }

  Stream<String> send({
    required String message,
    List<int>? imageBytes,
    String imageName = 'photo.jpg',
    String imageMime = 'image/jpeg',
  }) async* {
    _cancelFlag = false;
    await ensureReady();
    await _calmToggles();

    if (imageBytes != null) {
      await _uploadImage(imageBytes, imageName, imageMime);
      await Future.delayed(const Duration(milliseconds: 800));
    }

    _baselineLen = await _bodyLen();
    if (!await _submit(message)) {
      throw Exception('Could not send to longcat.ai — the page may have changed.');
    }

    var sent = 0;
    await for (final chunk in _watch()) {
      sent += chunk.length;
      yield chunk;
    }
    if (sent == 0) {
      throw Exception('longcat.ai did not answer. Please retry.');
    }
  }

  Future<int> _bodyLen() async =>
      int.tryParse(await _evalStr(
          '(() => document.body ? document.body.innerText.length : 0)()')) ??
      0;

  /// Type into the contenteditable and press Enter; fall back to clicking
  /// the send control inside the input area.
  Future<bool> _submit(String message) async {
    final payload = jsonEncode(message);
    final res = await _evalStr('''
(() => {
  const ed = document.querySelector('[contenteditable=true]');
  if (!ed) return 'NO_INPUT';
  ed.focus();
  document.execCommand('selectAll', false, null);
  const ok = document.execCommand('insertText', false, $payload);
  if (!ok) { ed.textContent = $payload; }
  ed.dispatchEvent(new InputEvent('input', {bubbles: true, inputType: 'insertText'}));
  const opts = {key: 'Enter', code: 'Enter', keyCode: 13, which: 13, bubbles: true};
  ed.dispatchEvent(new KeyboardEvent('keydown', opts));
  ed.dispatchEvent(new KeyboardEvent('keypress', opts));
  ed.dispatchEvent(new KeyboardEvent('keyup', opts));
  return 'SENT';
})()
''');
    if (!res.startsWith('SENT')) return false;
    await Future.delayed(const Duration(seconds: 4));
    if (await _progressSeen()) return true;
    // Fallback: click the send control near the input.
    await _evalStr('''
(() => {
  const ed = document.querySelector('[contenteditable=true]');
  if (!ed) return 'NO_INPUT';
  let box = ed.parentElement;
  for (let i = 0; i < 5 && box; i++) {
    const btns = box.querySelectorAll('button, [role=button], svg');
    for (const b of btns) {
      const r = b.getBoundingClientRect ? b.getBoundingClientRect() : null;
      if (r && r.width > 0 && r.height > 0) { b.click(); return 'CLICKED'; }
    }
    box = box.parentElement;
  }
  return 'NO_BTN';
})()
''');
    await Future.delayed(const Duration(seconds: 4));
    return _progressSeen();
  }

  /// Input cleared + page growing (or stop control visible) means sending worked.
  Future<bool> _progressSeen() async {
    final len = await _bodyLen();
    if (len > _baselineLen + 20) return true;
    final empty = await _evalStr('''
(() => {
  const ed = document.querySelector('[contenteditable=true]');
  return ed ? ((ed.innerText || '').trim().length === 0 ? 'EMPTY' : 'HAS_TEXT') : 'NO_INPUT';
})()
''');
    return empty == 'EMPTY';
  }

  /// Poll page text until the answer stops growing.
  Stream<String> _watch() async* {
    var sent = 0;
    final start = DateTime.now();
    var stableSince = DateTime.now();
    var lastText = '';
    var firstGrowth = false;
    final deadline = start.add(const Duration(minutes: 3));

    while (DateTime.now().isBefore(deadline)) {
      if (_cancelFlag) return;
      final full = await _evalStr(
          '(() => document.body ? document.body.innerText : "")()');
      final limit = _limitMarkers.any(full.contains);
      if (limit) {
        throw Exception(
            'longcat.ai is rate-limiting right now. Wait a bit and retry — or add an API key in Settings.');
      }
      // Assistant text = page text beyond what existed before sending.
      final text = full.length > _baselineLen
          ? full.substring(_baselineLen).trim()
          : '';
      if (text != lastText) {
        lastText = text;
        stableSince = DateTime.now();
        if (text.isNotEmpty) {
          firstGrowth = true;
          if (text.length > sent) {
            yield text.substring(sent);
            sent = text.length;
          }
        }
      } else if (firstGrowth &&
          text.isNotEmpty &&
          DateTime.now().difference(stableSince) > const Duration(seconds: 4) &&
          DateTime.now().difference(start) > const Duration(seconds: 8)) {
        return;
      }
      if (!firstGrowth &&
          DateTime.now().difference(start) > const Duration(seconds: 90)) {
        throw Exception('longcat.ai is taking too long. Please retry.');
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    throw Exception('longcat.ai timed out. Please retry.');
  }

  Future<void> _uploadImage(List<int> bytes, String name, String mime) async {
    final found = await _evalStr(
        '(() => !!document.querySelector(\'input[type="file"]\'))()');
    if (found != 'true') {
      throw Exception(
          'Photo upload is not available on longcat.ai right now — please describe the timetable in text.');
    }
    if (bytes.length > 12 * 1024 * 1024) {
      throw Exception('That photo is too large — please pick a smaller image.');
    }
    final b64 = base64Encode(bytes);
    final res = await _evalStr('''
(async () => {
  try {
    const inp = document.querySelector('input[type="file"]');
    if (!inp) return 'NONE';
    const res = await fetch("data:$mime;base64,$b64");
    let blob = await res.blob();
    try {
      const bitmap = await createImageBitmap(blob);
      const maxSide = 1568;
      const scale = Math.min(1, maxSide / Math.max(bitmap.width, bitmap.height));
      if (scale < 1) {
        const canvas = document.createElement('canvas');
        canvas.width = Math.round(bitmap.width * scale);
        canvas.height = Math.round(bitmap.height * scale);
        canvas.getContext('2d').drawImage(bitmap, 0, 0, canvas.width, canvas.height);
        blob = await new Promise(r => canvas.toBlob(r, 'image/jpeg', 0.85));
      }
    } catch (e) {}
    const file = new File([blob], ${jsonEncode(name)}, {type: blob.type || "$mime"});
    const dt = new DataTransfer();
    dt.items.add(file);
    inp.files = dt.files;
    inp.dispatchEvent(new Event('change', {bubbles: true}));
    inp.dispatchEvent(new Event('input', {bubbles: true}));
    return 'OK';
  } catch (e) { return 'ERR:' + e; }
})()
''');
    if (res != 'OK') {
      throw Exception(
          'Photo upload failed. Please describe the timetable in text.');
    }
  }

  void stop() => _cancelFlag = true;

  Future<void> newChat() async {
    try {
      final clicked = await _evalStr('''
(() => {
  const els = [...document.querySelectorAll('button,a')];
  for (const el of els) {
    const t = (el.innerText || '').trim().toLowerCase();
    if (t === 'start new chat' || t === 'new chat' || t === '开启新对话') { el.click(); return 'OK'; }
  }
  return 'NONE';
})()
''');
      if (clicked != 'OK') {
        await _c.loadRequest(Uri.parse(homeUrl));
      }
    } catch (_) {}
  }
}
