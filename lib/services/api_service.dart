import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'longcat_web_service.dart';

/// App-facing AI service with two independent backends:
/// - website (default): drives longcat.ai/chat guest session in the
///   phone's own hidden browser. No key needed.
/// - apikey: LongCat official OpenAI-compatible API with a user key.
/// Method signatures are unchanged so callers are unaffected.
class ApiService {
  static const _base = 'https://api.longcat.chat/openai/v1';

  static const _bots = [
    {
      'bot_id': 'longcat-flash-chat',
      'name': 'LongCat Flash',
      'service': 'longcat',
      'model': 'LongCat-Flash-Chat',
      'is_vip': false,
      'type': 'chat',
      'mime_support': 'image/*',
      'max_files': 1,
      'stream': true,
    },
    {
      'bot_id': 'longcat-25-preview',
      'name': 'LongCat 2.5',
      'service': 'longcat',
      'model': 'LongCat-2.5-Preview',
      'is_vip': false,
      'type': 'chat',
      'mime_support': 'image/*',
      'max_files': 1,
      'stream': true,
    },
    {
      'bot_id': 'longcat-20',
      'name': 'LongCat 2.0',
      'service': 'longcat',
      'model': 'LongCat-2.0',
      'is_vip': false,
      'type': 'chat',
      'mime_support': 'image/*',
      'max_files': 1,
      'stream': true,
    },
  ];

  String _apiKey = '';
  String _mode = 'website'; // website | apikey
  LongcatWebService? _web;
  bool _cancelFlag = false;
  http.Client? _client;

  void setKey(String key) => _apiKey = key.trim();
  void setMode(String mode) => _mode = mode;
  String get mode => _mode;
  void attachWeb(LongcatWebService web) => _web = web;

  LongcatWebService get _w {
    final w = _web;
    if (w == null) throw Exception('AI backend not ready yet.');
    return w;
  }

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      };

  /// No handshake needed; readiness is checked per request so the
  /// app shell (calendar, reminders) works even before setup.
  Future<void> auth() async {
    if (_mode == 'website') {
      await _w.ensureReady();
    }
  }

  Future<List<Map<String, dynamic>>> fetchBots() async =>
      _bots.map((b) => Map<String, dynamic>.from(b)).toList();

  /// Ping the API to validate the stored key. Returns null when OK,
  /// otherwise a human-readable error.
  Future<String?> testKey(String key) async {
    try {
      final r = await http
          .get(Uri.parse('$_base/models'), headers: {
            'Authorization': 'Bearer ${key.trim()}',
          })
          .timeout(const Duration(seconds: 20));
      if (r.statusCode == 200) return null;
      if (r.statusCode == 401) return 'Invalid API key.';
      return 'Server returned ${r.statusCode}.';
    } on TimeoutException {
      return 'Timed out — check your connection.';
    } catch (e) {
      return 'Could not reach the API: $e';
    }
  }

  /// Split our internal [SYSTEM]/[USER] wrapper into proper roles.
  /// Returns (system, user).
  (String, String) splitPrompt(String message) {
    if (!message.contains('[SYSTEM]')) return ('', message);
    final sysMatch =
        RegExp(r'\[SYSTEM\]\s*(.*?)\s*\[/SYSTEM\]', dotAll: true).firstMatch(message);
    final userMatch =
        RegExp(r'\[USER\]\s*(.*)', dotAll: true).firstMatch(message);
    return (
      sysMatch?.group(1)?.trim() ?? '',
      userMatch?.group(1)?.trim() ?? message,
    );
  }

  /// Calendar extraction wants fast, deterministic output.
  bool _thinkingFor(String model) => model == 'LongCat-2.5-Preview';

  Stream<String> sendMessage({
    required String message,
    required String model,
    required String service,
    required String botId,
    bool isImageBot = false,
    String? chatId,
    File? imageFile,
  }) async* {
    if (_mode == 'website') {
      List<int>? bytes;
      if (imageFile != null) {
        try {
          bytes = await imageFile.readAsBytes();
        } catch (_) {}
      }
      final (system, user) = splitPrompt(message);
      final prompt = system.isEmpty ? user : '$system\n\nUser message: $user';
      final ext = imageFile?.path.split('.').last.toLowerCase() ?? 'jpg';
      yield* _w.send(
        message: prompt,
        imageBytes: bytes,
        imageName: imageFile != null ? imageFile.path.split('/').last : 'photo.jpg',
        imageMime: ext == 'png'
            ? 'image/png'
            : ext == 'webp'
                ? 'image/webp'
                : 'image/jpeg',
      );
      return;
    }
    if (_apiKey.isEmpty) {
      throw Exception(
          'Add your LongCat API key in Settings → AI Model to start chatting.');
    }
    _cancelFlag = false;
    _client?.close();
    _client = http.Client();

    String useModel = model.isNotEmpty ? model : 'LongCat-Flash-Chat';
    final (system, user) = splitPrompt(message);
    final messages = <Map<String, dynamic>>[
      if (system.isNotEmpty) {'role': 'system', 'content': system},
    ];
    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      if (bytes.length > 8 * 1024 * 1024) {
        throw Exception('That photo is too large — please pick a smaller image.');
      }
      final ext = imageFile.path.split('.').last.toLowerCase();
      final mime = ext == 'png'
          ? 'image/png'
          : ext == 'webp'
              ? 'image/webp'
              : 'image/jpeg';
      useModel = 'LongCat-2.5-Preview'; // flagship model for image input
      messages.add({
        'role': 'user',
        'content': [
          {'type': 'text', 'text': user},
          {
            'type': 'image_url',
            'image_url': {'url': 'data:$mime;base64,${base64Encode(bytes)}'}
          },
        ],
      });
    } else {
      messages.add({'role': 'user', 'content': user});
    }

    final req = http.Request('POST', Uri.parse('$_base/chat/completions'))
      ..headers.addAll(_headers)
      ..body = jsonEncode({
        'model': useModel,
        'messages': messages,
        'stream': true,
        'temperature': 0.3,
        'thinking': {'type': _thinkingFor(useModel) ? 'enabled' : 'disabled'},
      });

    http.StreamedResponse resp;
    try {
      resp = await _client!.send(req).timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw Exception('Timed out reaching the AI. Check your connection.');
    }
    if (resp.statusCode == 401) {
      throw Exception('Invalid API key — update it in Settings → AI Model.');
    }
    if (resp.statusCode == 429) {
      throw Exception('Rate limited — wait a minute and retry.');
    }
    if (resp.statusCode != 200) {
      final body = await resp.stream.bytesToString();
      throw Exception('AI error ${resp.statusCode}: ${_short(body)}');
    }

    final lines =
        resp.stream.transform(utf8.decoder).transform(const LineSplitter());
    await for (final line in lines) {
      if (_cancelFlag) return;
      var raw = line.trim();
      if (raw.isEmpty || !raw.startsWith('data:')) continue;
      raw = raw.substring(5).trim();
      if (raw == '[DONE]') return;
      final chunk = parseSseChunk(raw);
      if (chunk.isNotEmpty) yield chunk;
    }
  }

  /// Parse one SSE `data:` payload into text. Pure — unit tested.
  static String parseSseChunk(String raw) {
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final choices = j['choices'] as List?;
      final delta = (choices?.firstOrNull as Map?)?['delta'] as Map?;
      return delta?['content']?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  String _short(String body, [int max = 200]) {
    try {
      final j = jsonDecode(body) as Map?;
      final err = j?['error'] as Map?;
      final msg = err?['message']?.toString() ?? body;
      return msg.length <= max ? msg : msg.substring(0, max);
    } catch (_) {
      return body.length <= max ? body : body.substring(0, max);
    }
  }

  void stopStreaming() {
    _cancelFlag = true;
    _client?.close();
    _client = null;
    _web?.stop();
  }

  void newChat() {
    _web?.newChat();
  }

  String? get currentChatId => null;
  bool get isAuthed => true;

  Future<List<Map<String, dynamic>>> getConversations({int page = 1}) async => [];
  Future<void> deleteConversation(String chatId) async {}
  Future<void> updateTitle(String chatId, String title) async {}
}
