import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// App-facing AI service. Calls Zhipu's official OpenAI-compatible API
/// (https://open.bigmodel.cn) straight from the phone — no middleman,
/// no browser hacks. Needs a user API key (free tier), entered in Settings.
class ApiService {
  static const _base = 'https://open.bigmodel.cn/api/paas/v4';
  static const visionModel = 'glm-4v-flash';

  String _apiKey = '';
  bool _cancelFlag = false;
  http.Client? _client;

  void setKey(String key) => _apiKey = key.trim();

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      };

  /// No handshake needed; key presence is checked per request so the
  /// app shell (calendar, reminders) works even before a key is added.
  Future<void> auth() async {}

  Future<List<Map<String, dynamic>>> fetchBots() async => [
        {
          'bot_id': 'glm-4-flash',
          'name': 'GLM-4-Flash',
          'service': 'zhipu',
          'model': 'glm-4-flash',
          'is_vip': false,
          'type': 'chat',
          'mime_support': 'image/*',
          'max_files': 1,
          'stream': true,
        },
        {
          'bot_id': 'glm-4',
          'name': 'GLM-4',
          'service': 'zhipu',
          'model': 'glm-4',
          'is_vip': false,
          'type': 'chat',
          'mime_support': 'image/*',
          'max_files': 1,
          'stream': true,
        },
        {
          'bot_id': 'glm-4v-flash',
          'name': 'GLM-4V-Flash',
          'service': 'zhipu',
          'model': 'glm-4v-flash',
          'is_vip': false,
          'type': 'chat',
          'mime_support': 'image/*',
          'max_files': 1,
          'stream': true,
        },
      ];

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

  Stream<String> sendMessage({
    required String message,
    required String model,
    required String service,
    required String botId,
    bool isImageBot = false,
    String? chatId,
    File? imageFile,
  }) async* {
    if (_apiKey.isEmpty) {
      throw Exception(
          'Add your Zhipu API key in Settings → AI Model to start chatting.');
    }
    _cancelFlag = false;
    _client?.close();
    _client = http.Client();

    String useModel = model.isNotEmpty ? model : 'glm-4-flash';
    Object content = toPrompt(message);
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
      useModel = visionModel; // images always route to the vision model
      content = [
        {'type': 'text', 'text': toPrompt(message)},
        {
          'type': 'image_url',
          'image_url': {'url': 'data:$mime;base64,${base64Encode(bytes)}'}
        },
      ];
    }

    final req = http.Request('POST', Uri.parse('$_base/chat/completions'))
      ..headers.addAll(_headers)
      ..body = jsonEncode({
        'model': useModel,
        'messages': [
          {'role': 'user', 'content': content}
        ],
        'stream': true,
        'temperature': 0.3,
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
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        final choices = j['choices'] as List?;
        final delta = (choices?.firstOrNull as Map?)?['delta'] as Map?;
        final text = delta?['content']?.toString() ?? '';
        if (text.isNotEmpty) yield text;
      } catch (_) {}
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
  }

  void newChat() {}

  String? get currentChatId => null;
  bool get isAuthed => true;

  Future<List<Map<String, dynamic>>> getConversations({int page = 1}) async => [];
  Future<void> deleteConversation(String chatId) async {}
  Future<void> updateTitle(String chatId, String title) async {}
}
