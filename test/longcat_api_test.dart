import 'package:donkey_calendar/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final api = ApiService();

  test('bots list exposes three LongCat models', () async {
    final bots = await api.fetchBots();
    final models = bots.map((b) => b['model']).toList();
    expect(models, contains('LongCat-Flash-Chat'));
    expect(models, contains('LongCat-2.5-Preview'));
    expect(models, contains('LongCat-2.0'));
    expect(bots.first['service'], 'longcat');
  });

  test('prompt wrapper splits into system/user roles', () {
    const wrapped =
        '[SYSTEM]\nYou are a calendar.\n[/SYSTEM]\n\n[USER]\nhello there';
    final (system, user) = api.splitPrompt(wrapped);
    expect(system, 'You are a calendar.');
    expect(user, 'hello there');
  });

  test('plain message passes through as user text', () {
    final (system, user) = api.splitPrompt('just chatting');
    expect(system, isEmpty);
    expect(user, 'just chatting');
  });

  test('SSE chunk parsing yields delta text', () {
    const raw =
        '{"choices":[{"delta":{"content":"Hello"},"index":0}],"object":"chat.completion.chunk"}';
    expect(ApiService.parseSseChunk(raw), 'Hello');
    expect(ApiService.parseSseChunk('not json'), isEmpty);
    expect(ApiService.parseSseChunk('{"choices":[]}'), isEmpty);
  });

  test('missing key fails fast with guidance', () async {
    api.setMode('apikey');
    api.setKey('');
    expect(
      api.sendMessage(
          message: 'hi', model: 'LongCat-Flash-Chat', service: 'longcat', botId: 'x'),
      emitsError(predicate((e) => e.toString().contains('Settings'))),
    );
  });

  test('invalid key surfaces API auth error', () async {
    api.setMode('apikey');
    api.setKey('test-invalid-key-123');
    await expectLater(
      api.sendMessage(
          message: 'hi', model: 'LongCat-Flash-Chat', service: 'longcat', botId: 'x'),
      emitsError(predicate((e) => e.toString().contains('Invalid API key'))),
    );
  }, timeout: const Timeout(Duration(seconds: 60)));
}
