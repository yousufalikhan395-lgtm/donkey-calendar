import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
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
  bool _freshDone = false;

  void attach(WebViewController controller) => _controller = controller;

  void _log(String msg) {
    debugPrint('[longcat-web] $msg');
  }

  /// Forward page console messages to logcat (diagnostics).
  void attachConsoleBridge(WebViewController controller) {
    try {
      controller.setOnConsoleMessage((msg) {
        debugPrint('[longcat-page:${msg.level.name}] ${msg.message}');
      });
    } catch (_) {}
  }

  WebViewController get _c {
    final c = _controller;
    if (c == null) throw Exception('Browser not ready yet. Please retry.');
    return c;
  }
  // ignore: unnecessary_null_comparison

  Future<String> _evalStr(String js,
      {Duration timeout = const Duration(seconds: 12)}) async {
    try {
      final r =
          await _c.runJavaScriptReturningResult(js).timeout(timeout);
      return r.toString();
    } catch (_) {
      return '';
    }
  }

  Future<void> ensureReady() async {
    if (!_freshDone) {
      _freshDone = true;
      await freshIdentity();
    }
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
    _diag.clear();
    _log('send start len=${message.length}');
    await ensureReady();
    _log('ready');

    if (imageBytes != null) {
      await _uploadImage(imageBytes, imageName, imageMime);
      await Future.delayed(const Duration(milliseconds: 800));
    }

    await _calmToggles();
    for (var attempt = 0; attempt < 2; attempt++) {
      final step = await _submitVerified(message);
      if (!step) {
        throw Exception('Send failed (${_diag.join(' → ')}). Please retry.');
      }
      // Rebase AFTER the user bubble exists, so the watcher only tracks AI text.
      _baselineLen = await _bodyLen();

      try {
        var sent = 0;
        await for (final chunk in _watch()) {
          sent += chunk.length;
          yield chunk;
        }
        if (sent == 0) {
          throw Exception(
              'Message sent but no answer arrived (${_diag.join(' → ')}). The site may be rate-limiting — wait a bit and retry.');
        }
        return;
      } on _LimitHit {
        // Guest wall hit mid-chat: burn this identity, mint a fresh one,
        // resubmit once. If the wall is IP-based this still fails —
        // and the final error says so plainly.
        _diag.add('429: fresh identity + retry');
        await hardReset();
        continue;
      }
    }
    throw Exception(
        'longcat.ai is rate-limiting this network right now. Wait a while and retry — or switch to API key mode in Settings.');
  }

  final List<String> _diag = [];
  String get lastReport => _diag.join(' → ');

  Future<int> _bodyLen() async =>
      int.tryParse(await _evalStr(
          '(() => document.body ? document.body.innerText.length : 0)()')) ??
      0;

  /// Verified send: force text into the box (checked), press Enter, else
  /// click the real send button (found spatially, toggles excluded), then
  /// confirm the user bubble exists. Every step is recorded for diagnostics.
  Future<bool> _submitVerified(String message) async {
    final payload = jsonEncode(message);
    final trimmed = message.trim();
    final tail = trimmed.length <= 24
        ? trimmed
        : trimmed.substring(trimmed.length - 24);
    final tailJson = jsonEncode(tail);

    final setRes = await _evalStr('''
(() => {
  const ed = document.querySelector('[contenteditable=true]');
  if (!ed) return 'NO_INPUT';
  try { ed.scrollIntoView({block: 'nearest'}); } catch (e) {}
  ed.focus();
  try {
    const sel = window.getSelection();
    const range = document.createRange();
    range.selectNodeContents(ed);
    sel.removeAllRanges();
    sel.addRange(range);
  } catch (e) {}
  let ok = false;
  try { ok = document.execCommand('insertText', false, $payload); } catch (e) {}
  let present = (ed.innerText || '').includes($tailJson);
  if (!present) {
    try { ed.textContent = $payload; } catch (e) {}
    present = (ed.innerText || '').includes($tailJson);
  }
  try {
    ed.dispatchEvent(new InputEvent('beforeinput', {bubbles: true, inputType: 'insertText', data: $payload}));
    ed.dispatchEvent(new InputEvent('input', {bubbles: true, inputType: 'insertText', data: $payload}));
  } catch (e) {}
  return present ? 'TEXT_YES' : 'TEXT_NO';
})()
''');
    _diag.add('text:$setRes');
    _log('text set: $setRes');
    if (setRes != 'TEXT_YES') return false;

    await _evalStr('''
(() => {
  const ed = document.querySelector('[contenteditable=true]');
  if (!ed) return 'NO_INPUT';
  const opts = {key: 'Enter', code: 'Enter', keyCode: 13, which: 13, bubbles: true};
  ed.dispatchEvent(new KeyboardEvent('keydown', opts));
  ed.dispatchEvent(new KeyboardEvent('keypress', opts));
  ed.dispatchEvent(new KeyboardEvent('keyup', opts));
  return 'KEY_SENT';
})()
''');
    await Future.delayed(const Duration(seconds: 3));
    if (await _sendConfirmed(tailJson)) {
      _diag.add('via:enter');
      return true;
    }

    final clickRes = await _evalStr('''
(() => {
  const ed = document.querySelector('[contenteditable=true]');
  if (!ed) return 'NO_INPUT';
  const r = ed.getBoundingClientRect();
  const cx = r.left + r.width / 2, cy = r.top + r.height / 2;
  const skip = /think|search|attach|upload|image|video|mic|voice/i;
  let best = null, bestScore = 1e15;
  document.querySelectorAll('button, [role=button]').forEach(b => {
    const q = b.getBoundingClientRect();
    if (!q || q.width < 8 || q.height < 8) return;
    const t = (b.innerText || '') + ' ' + (b.getAttribute('aria-label') || '');
    if (skip.test(t)) return;
    const dx = (q.left + q.width / 2) - cx, dy = (q.top + q.height / 2) - cy;
    let score = dx * dx + dy * dy;
    if (dx > 0) score -= 1e9;
    if (score < bestScore) { bestScore = score; best = b; }
  });
  if (!best) return 'NO_BTN';
  best.click();
  return 'CLICKED';
})()
''');
    _diag.add('click:$clickRes');
    _log('send click: $clickRes');
    await Future.delayed(const Duration(seconds: 3));
    if (await _sendConfirmed(tailJson)) {
      _diag.add('via:click');
      return true;
    }
    // Last chance: the page may have navigated on submit and still be
    // loading — our bubble survives navigation, so check once more late.
    _log('send re-check after navigation settle');
    await Future.delayed(const Duration(seconds: 6));
    if (await _sendConfirmed(tailJson)) {
      _diag.add('via:late-confirm');
      return true;
    }
    _diag.add('confirm:no');
    return false;
  }

  /// Sent iff the box emptied (framework accepted it) or our text now
  /// lives in a message bubble outside the input.
  Future<bool> _sendConfirmed(String tailJson) async {
    final res = await _evalStr('''
(() => {
  const ed = document.querySelector('[contenteditable=true]');
  const tail = $tailJson;
  const boxText = ed ? (ed.innerText || '') : '';
  if (boxText.trim().length === 0) return 'BOX_EMPTY';
  const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
  let node;
  while ((node = walker.nextNode())) {
    if (node.textContent && node.textContent.includes(tail) && !ed.contains(node)) {
      return 'BUBBLE_FOUND';
    }
  }
  return 'STILL_TYPING';
})()
''');
    _diag.add('confirm:$res');
    _log('send confirm: $res');
    return res == 'BOX_EMPTY' || res == 'BUBBLE_FOUND';
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
        _log('LIMIT markers hit');
        throw _LimitHit();
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

  /// Burn the current guest identity and load a fresh one.
  Future<void> hardReset() async {
    await freshIdentity();
    try {
      await _c.loadRequest(Uri.parse(homeUrl));
      await _waitFor(
          '(() => !!document.querySelector("[contenteditable=true]"))()',
          const Duration(seconds: 45));
    } catch (_) {}
  }

  /// True incognito: wipe cookies + site storage so the next load mints
  /// a brand-new guest identity.
  Future<void> freshIdentity() async {
    try {
      await WebViewCookieManager().clearCookies();
    } catch (_) {}
    try {
      await _evalStr(
          "(() => { try { localStorage.clear(); sessionStorage.clear(); } catch (e) {} return 'OK'; })()");
    } catch (_) {}
  }

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

class _LimitHit implements Exception {}
