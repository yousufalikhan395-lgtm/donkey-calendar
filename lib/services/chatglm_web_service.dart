import 'dart:async';
import 'dart:convert';

import 'package:webview_flutter/webview_flutter.dart';

/// Drives chatglm.cn (GLM guest chat) inside a hidden WebView.
/// The phone runs its own real browser session — no middleman server.
///
/// DOM logic is ported from the proven desktop automation:
/// textarea `textarea.scroll-display-none`, answers in `.markdown-body`,
/// send/stop button `.enter`, guest-limit reset via storage clear.
class ChatglmWebService {
  static const homeUrl = 'https://chatglm.cn/';
  static const _limitMarkers = ['您已多次体验过对话', '请登录后继续使用'];

  WebViewController? _controller;
  bool _cancelFlag = false;
  int _baseline = 0;
  final List<Map<String, String>> _history = [];

  void attach(WebViewController controller) => _controller = controller;

  WebViewController get _c {
    final c = _controller;
    if (c == null) throw Exception('Browser not ready yet. Please retry.');
    return c;
  }

  Future<Object?> _eval(String js) => _c.runJavaScriptReturningResult(js);

  Future<String> _evalStr(String js) async {
    try {
      final r = await _eval(js);
      return r?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Load the site (if needed) and wait for the chat input.
  Future<void> ensureReady() async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final hasInput = await _evalStr(
            '(() => !!document.querySelector("textarea"))()');
        if (hasInput != 'true') {
          await _c.loadRequest(Uri.parse(homeUrl));
        }
        final ok = await _waitFor(
            '(() => !!document.querySelector("textarea.scroll-display-none, textarea"))()',
            const Duration(seconds: 45));
        if (ok) return;
      } catch (_) {}
      await Future.delayed(const Duration(seconds: 2));
    }
    throw Exception('Could not load chatglm.cn — check your connection and retry.');
  }

  Future<bool> _waitFor(String conditionJs, Duration timeout) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      if (await _evalStr(conditionJs) == 'true') return true;
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return false;
  }

  /// Send [message] and stream the reply in chunks.
  /// If [imageBytes] is set, uploads it first via the page file input.
  Stream<String> send({
    required String message,
    List<int>? imageBytes,
    String imageName = 'photo.jpg',
    String imageMime = 'image/jpeg',
  }) async* {
    _cancelFlag = false;
    await ensureReady();

    if (imageBytes != null) {
      await _uploadImage(imageBytes, imageName, imageMime);
      await Future.delayed(const Duration(milliseconds: 800));
    }

    var msg = message;
    for (var attempt = 0; attempt < 2; attempt++) {
      final sent = await _submit(msg);
      if (!sent) {
        throw Exception('Could not send message to chatglm.cn — the page may have changed.');
      }
      try {
        await for (final chunk in _watch()) {
          yield chunk;
        }
        _history.add({'role': 'user', 'content': message});
        _history.add({'role': 'assistant', 'content': _lastFull});
        if (_history.length > 12) _history.removeRange(0, _history.length - 12);
        return;
      } on _LimitHit {
        await hardReset();
        msg = _withContext(message);
        continue;
      }
    }
    throw Exception('chatglm.cn asked to sign in (guest limit). Please try again later.');
  }

  String _lastFull = '';

  String _withContext(String message) {
    if (_history.isEmpty) return message;
    final lines = <String>[];
    for (final m in _history.take(6)) {
      final role = m['role'] == 'user' ? 'User' : 'Assistant';
      var content = m['content'] ?? '';
      if (content.length > 300) content = content.substring(0, 300);
      lines.add('$role: ${content.replaceAll('\n', ' ')}');
    }
    return '[Previous conversation:\n${lines.join('\n')}\n]\n\n$message';
  }

  /// Fill the box and dispatch Enter; fall back to clicking send.
  Future<bool> _submit(String message) async {
    final payload = jsonEncode(message);
    final res = await _evalStr('''
(() => {
  const ta = document.querySelector('textarea.scroll-display-none') || document.querySelector('textarea');
  if (!ta) return 'NO_TEXTAREA';
  ta.focus();
  try {
    const desc = Object.getOwnPropertyDescriptor(window.HTMLTextAreaElement.prototype, 'value');
    if (desc && desc.set) desc.set.call(ta, $payload); else ta.value = $payload;
  } catch (e) { ta.value = $payload; }
  ta.dispatchEvent(new Event('input', {bubbles: true}));
  ta.dispatchEvent(new Event('change', {bubbles: true}));
  const before = document.querySelectorAll('.markdown-body').length;
  const opts = {key: 'Enter', code: 'Enter', keyCode: 13, which: 13, bubbles: true};
  ta.dispatchEvent(new KeyboardEvent('keydown', opts));
  ta.dispatchEvent(new KeyboardEvent('keypress', opts));
  ta.dispatchEvent(new KeyboardEvent('keyup', opts));
  return 'SENT:' + before;
})()
''');
    if (!res.startsWith('SENT:')) return false;
    _baseline = int.tryParse(res.substring(5)) ?? 0;

    // Verify something happened; otherwise click the send button.
    await Future.delayed(const Duration(seconds: 5));
    if (await _progressSeen()) return true;
    final click = await _evalStr('''
(() => {
  const b = document.querySelector('.enter');
  if (!b) return 'NO_BTN';
  b.click();
  return 'CLICKED:' + document.querySelectorAll('.markdown-body').length;
})()
''');
    if (click.startsWith('CLICKED:')) {
      _baseline = int.tryParse(click.substring(8)) ?? _baseline;
    }
    await Future.delayed(const Duration(seconds: 5));
    return _progressSeen();
  }

  Future<bool> _progressSeen() async {
    final count = int.tryParse(await _evalStr(
            '(() => document.querySelectorAll(".markdown-body").length)()')) ??
        0;
    if (count > _baseline) return true;
    final btn = await _evalStr(
        "(() => { const b = document.querySelector('.enter'); return b ? (b.className.baseVal !== undefined ? b.className.baseVal : (b.className || '')) : ''; })()");
    return btn.contains('searching') || btn.contains('stop') || btn.contains('loading');
  }

  /// Poll the page until the answer stops growing.
  Stream<String> _watch() async* {
    _lastFull = '';
    var sent = 0;
    final start = DateTime.now();
    var stableSince = DateTime.now();
    var lastText = '';
    final deadline = start.add(const Duration(minutes: 3));

    while (DateTime.now().isBefore(deadline)) {
      if (_cancelFlag) return;
      final text = await _extractFrom(_baseline);
      if (await _isLimitPage()) throw _LimitHit();

      if (text != lastText) {
        lastText = text;
        stableSince = DateTime.now();
        if (text.length > sent) {
          yield text.substring(sent);
          sent = text.length;
          _lastFull = text;
        }
      } else if (text.isNotEmpty &&
          DateTime.now().difference(stableSince) > const Duration(seconds: 3) &&
          DateTime.now().difference(start) > const Duration(seconds: 5) &&
          !await _isSearching()) {
        _lastFull = text;
        return;
      }
      if (text.isEmpty && DateTime.now().difference(start) > const Duration(seconds: 60)) {
        throw Exception('chatglm.cn did not answer in time. Please retry.');
      }
      await Future.delayed(const Duration(milliseconds: 400));
    }
    throw Exception('chatglm.cn timed out. Please retry.');
  }

  Future<bool> _isSearching() async {
    final btn = await _evalStr(
        "(() => { const b = document.querySelector('.enter'); return b ? (b.className.baseVal !== undefined ? b.className.baseVal : (b.className || '')) : ''; })()");
    return btn.contains('searching');
  }

  Future<bool> _isLimitPage() async {
    final body = await _evalStr(
        "(() => (document.body ? document.body.innerText.slice(0, 4000) : ''))()");
    return _limitMarkers.any(body.contains);
  }

  /// Extract rendered answer text from `.markdown-body` blocks [skip..].
  Future<String> _extractFrom(int skip) async {
    const fn = '''
(skip) => {
  const items = document.querySelectorAll('.markdown-body');
  if (!items.length || items.length <= skip) return '';
  const block = ["P","DIV","H1","H2","H3","H4","H5","H6","BLOCKQUOTE","PRE","TABLE","TR","TD","TH","LI"];
  const textFn = (n, st) => {
    if (n.nodeType === 3) return n.textContent;
    if (n.nodeType !== 1) return '';
    const tag = n.tagName;
    if (tag === 'OL') { st.in_ol = true; st.li_count = 0; }
    if (tag === 'UL') { st.in_ol = false; }
    let t = '';
    for (const c of n.childNodes) t += textFn(c, st);
    if (tag === 'OL' || tag === 'UL') { st.in_ol = false; }
    if (tag === 'BR') return '\\n';
    if (tag === 'LI') {
      st.li_count++;
      const prefix = st.in_ol ? st.li_count + '. ' : '- ';
      return '\\n' + prefix + t.trim();
    }
    if (tag === 'HR') return '\\n\\n---\\n\\n';
    if (block.includes(tag)) { const s = t.trim(); return s ? '\\n\\n' + s : ''; }
    return t;
  };
  let result = '';
  for (let idx = skip; idx < items.length; idx++) {
    const el = items[idx].cloneNode(true);
    el.querySelectorAll('button').forEach(b => b.remove());
    el.querySelectorAll('svg').forEach(s => s.remove());
    const st = { in_ol: false, li_count: 0 };
    const extracted = textFn(el, st).trim();
    result += (result ? '\\n\\n' : '') + extracted;
  }
  return result.replace(/\\n{3,}/g, '\\n\\n');
}
''';
    final out = await _evalStr('($fn)($skip)');
    return _stripNoise(out);
  }

  static const _noise = [
    '以上内容为 AI 生成', '不代表开发者立场', '请勿删除或修改本标记',
    '内容由AI生成', '请仔细甄别', '用户协议', '隐私政策', '本次回答已被终止',
  ];

  String _stripNoise(String text) {
    var t = text;
    for (final n in _noise) {
      t = t.replaceAll(n, '');
    }
    return t.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }

  /// Upload an image through the page's file input (downscaled in-page).
  Future<void> _uploadImage(List<int> bytes, String name, String mime) async {
    final found = await _evalStr(
        '(() => { const i = document.querySelector(\'input[type="file"]\'); return i ? "FOUND" : "NONE"; })()');
    if (found != 'FOUND') {
      throw Exception('Photo upload is not supported by chatglm.cn right now — please describe the timetable in text.');
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
    const file = new File([blob], ${jsonEncode(name)}, {type: blob.type || $mime});
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
      throw Exception('Photo upload failed ($res). Please describe the timetable in text.');
    }
  }

  void stop() => _cancelFlag = true;

  Future<void> newChat() async {
    _history.clear();
    try {
      await _c.loadRequest(Uri.parse(homeUrl));
    } catch (_) {}
  }

  /// Full guest-limit reset: wipe storage + cookies, reload, wait.
  Future<void> hardReset() async {
    _history.clear();
    try {
      await WebViewCookieManager().clearCookies();
    } catch (_) {}
    try {
      await _evalStr(
          "(() => { try { localStorage.clear(); sessionStorage.clear(); } catch (e) {} return 'OK'; })()");
      await _c.loadRequest(Uri.parse(homeUrl));
      await _waitFor(
          '(() => !!document.querySelector("textarea.scroll-display-none, textarea"))()',
          const Duration(seconds: 45));
    } catch (_) {}
  }
}

class _LimitHit implements Exception {}
