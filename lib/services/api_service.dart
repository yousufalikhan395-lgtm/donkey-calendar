import 'dart:async';
import 'dart:io';

import 'chatglm_web_service.dart';

/// App-facing AI service. Speaks to chatglm.cn (GLM) through the phone's
/// own hidden browser session — no middleman server, no API keys.
/// Method signatures are unchanged so callers are unaffected.
class ApiService {
  ChatglmWebService? _web;
  bool _authed = false;

  void attachWeb(ChatglmWebService web) => _web = web;

  ChatglmWebService get _w {
    final w = _web;
    if (w == null) throw Exception('AI backend not ready yet.');
    return w;
  }

  Future<void> auth() async {
    await _w.ensureReady();
    _authed = true;
  }

  Future<List<Map<String, dynamic>>> fetchBots() async => [
        {
          'bot_id': 'glm-52',
          'name': 'GLM 5.2',
          'service': 'chatglm',
          'model': 'glm-5.2',
          'is_vip': false,
          'type': 'chat',
          'mime_support': 'image/*',
          'max_files': 1,
          'stream': true,
        },
      ];

  /// Flatten our internal [SYSTEM]/[USER] wrapper into plain prompt text
  /// the website understands.
  String _toPrompt(String message) {
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
    List<int>? bytes;
    if (imageFile != null) {
      try {
        bytes = await imageFile.readAsBytes();
      } catch (_) {}
    }
    final prompt = _toPrompt(message);
    yield* _w.send(
      message: prompt,
      imageBytes: bytes,
      imageName: imageFile != null
          ? imageFile.path.split('/').last
          : 'photo.jpg',
    );
  }

  void stopStreaming() => _web?.stop();

  void newChat() => _web?.newChat();

  String? get currentChatId => null;
  bool get isAuthed => _authed;

  // Chat history lives on the website; local stubs kept for API shape.
  Future<List<Map<String, dynamic>>> getConversations({int page = 1}) async => [];
  Future<void> deleteConversation(String chatId) async {}
  Future<void> updateTitle(String chatId, String title) async {}
}
