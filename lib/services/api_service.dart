import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

/// App-facing AI service. Speaks the OpenChat backend
/// (https://gptapi.rotech.dev/api/v5) directly from the phone:
/// form envelope + AES-128-CBC bodies, SSE streaming chat, model
/// single-shots, and the S3 image-analysis pipeline.
/// Verified live against the real server. No login, no API key.
class ApiService {
  static const _base = 'https://gptapi.rotech.dev/api/v5/';
  static const _pkg = 'open.chat.gpt.aichat.bot.free.app';
  static const _ver = '1.4.0';
  // Working key/iv derived from the ORIGINAL APK signature (verified live).
  static const _key = '8a678654d5872049';
  static const _iv = '60f88b97a8896ec5';

  static const _bots = [
    {'bot_id': 'auto', 'name': 'Auto (live)', 'model': 'auto'},
    {'bot_id': 'gpt4o', 'name': 'GPT-4o', 'model': 'gpt4o'},
    {'bot_id': 'gpt5', 'name': 'GPT-5', 'model': 'gpt5'},
    {'bot_id': 'claude45', 'name': 'Claude 4.5', 'model': 'claude45'},
    {'bot_id': 'gemini3', 'name': 'Gemini 3', 'model': 'gemini3'},
    {'bot_id': 'grok41', 'name': 'Grok 4.1', 'model': 'grok41'},
    {'bot_id': 'deepseek', 'name': 'DeepSeek R1', 'model': 'deepseek'},
  ];

  final _uuid = const Uuid();
  final _rand = Random();
  late String _uid = _uuid.v4();
  late String _sign = _convoSign();
  int _turns = 0;

  bool _cancelFlag = false;
  http.Client? _client;

  String _convoSign() => '${_uid}_${DateTime.now().millisecondsSinceEpoch}';

  Map<String, dynamic> _common(Map<String, dynamic> o) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    o['gp_token'] = '';
    o['firebase_uid'] = '';
    o['sign'] = '$ts${10000 + _rand.nextInt(90000)}';
    return o;
  }

  /// AES-128-CBC/PKCS7 encrypt JSON → Base64 NO_WRAP. Pure — unit tested.
  static String aesEncrypt(String json) {
    final e = enc.Encrypter(enc.AES(enc.Key.fromUtf8(_key), mode: enc.AESMode.cbc));
    return e.encrypt(json, iv: enc.IV.fromUtf8(_iv)).base64;
  }

  /// Reverse of [aesEncrypt]. Pure — unit tested.
  static String aesDecrypt(String blob) {
    final e = enc.Encrypter(enc.AES(enc.Key.fromUtf8(_key), mode: enc.AESMode.cbc));
    return e.decrypt(enc.Encrypted.fromBase64(blob.trim()), iv: enc.IV.fromUtf8(_iv));
  }

  Map<String, String> _form(String jsonBody) => {
        'pkg': _pkg,
        'version': _ver,
        'modetype': '1',
        'data': aesEncrypt(jsonBody),
      };

  Future<http.StreamedResponse> _post(
      String endpoint, Map<String, dynamic> body) async {
    _client?.close();
    _client = http.Client();
    final req = http.Request('POST', Uri.parse('$_base$endpoint'))
      ..headers.addAll({
        'User-Agent': 'okhttp/4.12.4',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'text/event-stream,application/json',
      })
      ..bodyFields = _form(jsonEncode(body));
    return _client!.send(req).timeout(const Duration(seconds: 30));
  }

  Future<Map<String, dynamic>> _postJson(
      String endpoint, Map<String, dynamic> body) async {
    final resp = await _post(endpoint, body);
    final raw = await resp.stream.bytesToString();
    if (resp.statusCode != 200) {
      throw Exception('AI error ${resp.statusCode}. Please retry.');
    }
    final outer = jsonDecode(aesDecrypt(raw)) as Map<String, dynamic>;
    if (outer['code'] != 200) {
      throw Exception('AI error ${outer['code']}: ${outer['message'] ?? 'unknown'}.');
    }
    final data = outer['data'];
    return data is String ? jsonDecode(data) as Map<String, dynamic> : data as Map<String, dynamic>;
  }

  Future<void> auth() async {
    _uid = _uuid.v4();
    newChat();
  }

  Future<List<Map<String, dynamic>>> fetchBots() async => _bots
      .map((b) => {
            'bot_id': b['bot_id'],
            'name': b['name'],
            'service': 'openchat',
            'model': b['model'],
            'is_vip': false,
            'type': 'chat',
            'mime_support': 'image/*',
            'max_files': 1,
            'stream': true,
          })
      .toList();

  /// Flatten our internal [SYSTEM]/[USER] wrapper into plain prompt text.
  String toPrompt(String message) {
    if (!message.contains('[SYSTEM]')) return message;
    final sysMatch =
        RegExp(r'\[SYSTEM\]\s*(.*?)\s*\[/SYSTEM\]', dotAll: true).firstMatch(message);
    final userMatch =
        RegExp(r'\[USER\]\s*(.*)', dotAll: true).firstMatch(message);
    final sys = sysMatch?.group(1)?.trim() ?? '';
    final user = userMatch?.group(1)?.trim() ?? message;
    if (sys.isEmpty) return user;
    return '$sys\n\nUser message: $user';
  }

  /// Parse one SSE `event:`/`data:` block into streamed text.
  /// Returns '' for non-answer chunks. Pure — unit tested.
  static String parseSseBlock(String event, String dataB64) {
    String outer;
    try {
      outer = aesDecrypt(dataB64.split(RegExp(r'\s')).firstWhere((s) => s.isNotEmpty));
    } catch (_) {
      return '';
    }
    Map<String, dynamic> o;
    try {
      o = jsonDecode(outer) as Map<String, dynamic>;
    } catch (_) {
      return '';
    }
    if (event == 'error') {
      throw Exception('AI error: ${o['message'] ?? 'unknown'}.');
    }
    if (event != 'message') return '';
    final inner = o['data'];
    final m = inner is String ? jsonDecode(inner) as Map<String, dynamic> : inner as Map<String, dynamic>?;
    if (m == null) return '';
    if (m['block_name'] != 'final_answer') return '';
    return m['content']?.toString() ?? '';
  }

  Stream<String> sendMessage({
    required String message,
    required String model,
    required String service,
    required String botId,
    bool isImageBot = false,
    String? chatId,
    File? imageFile,
  }) async* {
    _cancelFlag = false;
    var prompt = toPrompt(message);

    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      if (bytes.length > 12 * 1024 * 1024) {
        throw Exception('That photo is too large — please pick a smaller image.');
      }
      final ext = imageFile.path.split('.').last.toLowerCase();
      final mime = ext == 'png'
          ? 'image/png'
          : ext == 'webp'
              ? 'image/webp'
              : 'image/jpeg';
      final name = imageFile.path.split('/').last;
      prompt = await _visionDescribe(bytes, name, mime, prompt);
    }

    final idArgs = _turns == 0 ? <String, dynamic>{} : {'id': 0};
    _turns++;

    if (botId == 'deepseek') {
      final d = await _postJson(
          'chat/question-dp',
          _common({
            'question': prompt,
            'conversation_sign': _sign,
            ...idArgs,
          }));
      final text = d['content']?.toString() ?? d['msg']?.toString() ?? '';
      if (text.isNotEmpty) yield text;
      return;
    }

    if (botId != 'auto') {
      final d = await _postJson(
          'chat/common_question',
          _common({
            'uuid': _uid,
            'conversation_sign': _sign,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'question': prompt,
            'lang': 'en',
            'model': model.isNotEmpty ? model : 'auto',
            'length': 'auto',
            'style': 'auto',
            ...idArgs,
          }));
      final text = d['content']?.toString() ?? d['msg']?.toString() ?? '';
      if (text.isNotEmpty) yield text;
      return;
    }

    // Streaming main chat.
    final resp = await _post(
        'aq/chat',
        _common({
          'conversation_sign': _sign,
          'msg_type': 0,
          'msg': prompt,
          'language': 'en',
          ...idArgs,
        }));
    if (resp.statusCode != 200) {
      throw Exception('AI error ${resp.statusCode}. Please retry.');
    }
    var event = '';
    var data = '';
    var gotAny = false;
    final lines =
        resp.stream.transform(utf8.decoder).transform(const LineSplitter());
    await for (final line in lines) {
      if (_cancelFlag) return;
      final t = line.trim();
      if (t.isEmpty) {
        if (data.isNotEmpty) {
          final chunk = parseSseBlock(event, data);
          if (chunk.isNotEmpty) {
            gotAny = true;
            yield chunk;
          }
        }
        event = '';
        data = '';
        continue;
      }
      if (t.startsWith('event:')) {
        event = t.substring(6).trim().split(RegExp(r'\s')).first;
      } else if (t.startsWith('data:')) {
        final piece = t.substring(5).trim();
        data = data.isEmpty ? piece : '$data$piece';
      }
    }
    if (data.isNotEmpty) {
      final chunk = parseSseBlock(event, data);
      if (chunk.isNotEmpty) {
        gotAny = true;
        yield chunk;
      }
    }
    if (!gotAny) throw Exception('Empty reply from AI. Please retry.');
  }

  /// Vision pipeline: upload → analyze → description text.
  Future<String> _visionDescribe(
      List<int> bytes, String name, String mime, String instruction) async {
    final up = await _postJson(
        'chat/file/get_upload_url', _common({'filenames': [name]}));
    final urls = (up['url_list'] as List?) ?? [];
    if (urls.isEmpty) throw Exception('Upload failed. Please retry.');
    final item = urls.first as Map<String, dynamic>;
    final putUrl = item['url']?.toString() ?? '';
    final s3Url = item['s3_url']?.toString() ?? '';
    if (putUrl.isEmpty || s3Url.isEmpty) throw Exception('Upload failed. Please retry.');

    final put = await http.put(Uri.parse(putUrl),
        headers: {'Content-Type': mime, 'x-amz-acl': 'public-read'}, body: bytes);
    if (put.statusCode != 200) {
      throw Exception('Upload failed (HTTP ${put.statusCode}). Please retry.');
    }

    await _postJson(
        'chat/images/analysis',
        _common({
          'conversation_sign': _sign,
          'type': '1',
          'text': instruction.isNotEmpty ? instruction : 'Describe this image in detail.',
          'img_url': s3Url,
        }));
    for (var i = 0; i < 12; i++) {
      await Future.delayed(const Duration(seconds: 5));
      if (_cancelFlag) throw Exception('Stopped.');
      final p = await _postJson('chat/images/analysis_pull',
          _common({'conversation_sign': _sign, 'type': '1'}));
      final content = p['content']?.toString() ?? '';
      if (content.isNotEmpty) return 'The timetable image shows:\n$content';
    }
    throw Exception('Image analysis timed out. Please describe it in text.');
  }

  void stopStreaming() {
    _cancelFlag = true;
    _client?.close();
    _client = null;
  }

  void newChat() {
    _sign = _convoSign();
    _turns = 0;
  }

  String? get currentChatId => _sign;
  bool get isAuthed => true;

  Future<List<Map<String, dynamic>>> getConversations({int page = 1}) async => [];
  Future<void> deleteConversation(String chatId) async {}
  Future<void> updateTitle(String chatId, String title) async {}
}
