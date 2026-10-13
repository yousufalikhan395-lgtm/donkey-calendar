import 'package:donkey_calendar/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final api = ApiService();

  test('bots list exposes OpenChat models', () async {
    final bots = await api.fetchBots();
    final ids = bots.map((b) => b['bot_id']).toList();
    expect(ids, contains('auto'));
    expect(ids, containsAll(['gpt4o', 'gpt5', 'claude45', 'gemini3', 'grok41', 'deepseek']));
    expect(bots.first['service'], 'openchat');
  });

  test('AES roundtrip matches Python-generated vector', () {
    // Generated with pycryptodome, same key/iv as the app.
    const blob =
        '184ll47FVkKD146N5Lx2oclwKZiT5dSaEbOhp/kqv8zM+ArZLAEFnjL2W65EkTUa';
    expect(ApiService.aesDecrypt(blob),
        '{"code":200,"data":{"content":"Hi there!"}}');
    final re = ApiService.aesEncrypt('{"ping":1}');
    expect(ApiService.aesDecrypt(re), '{"ping":1}');
  });

  test('SSE message block yields final_answer content only', () {
    const msgBlob =
        '7Z5GIQKdKDk9dCrcPcfCSKgsM+NZrOdhF8PUXwftJSCZFPd9sW5DZllJDsJKvD/QEamXrnjy6xbQODsGqJ00Yo5UdXa5hClbiQIya2Tw5gLuDKjYIfL663fXiK6/luNEv24N2XDH2bAQwPYipriXMu1/DVyRTUWJyN/TAaWbgQM=';
    expect(ApiService.parseSseBlock('message', msgBlob), 'LeetCode review');
  });

  test('reasoning blocks are skipped', () {
    const thinkBlob =
        '7Z5GIQKdKDk9dCrcPcfCSKgsM+NZrOdhF8PUXwftJSCZFPd9sW5DZllJDsJKvD/QQCuKBrnUeo3GuhS7BeIIS7DxAnVwKDTYx16mFZqteBv4Z2HlPmrZPNOpQZP1ncTFD9JSxmK30Lufo3D9GNn5Pdr7yOwdVH5y2/VFTaCXzjM=';
    expect(ApiService.parseSseBlock('message', thinkBlob), isEmpty);
  });

  test('end block yields nothing', () {
    const endBlob =
        '7Z5GIQKdKDk9dCrcPcfCSPwsS1MJzfasv4J3kzkog4kY9pMrf0vnIDownxQcVudW';
    expect(ApiService.parseSseBlock('end', endBlob), isEmpty);
  });

  test('garbage data is skipped, not thrown', () {
    expect(ApiService.parseSseBlock('message', '!!!not-base64!!!'), isEmpty);
  });

  test('prompt wrapper splits into plain text', () {
    const wrapped =
        '[SYSTEM]\nYou are a calendar.\n[/SYSTEM]\n\n[USER]\nhello there';
    expect(api.toPrompt(wrapped), contains('You are a calendar.'));
    expect(api.toPrompt(wrapped), contains('hello there'));
    expect(api.toPrompt('just chatting'), 'just chatting');
  });

  test('conversation sign format is uuid_millis', () {
    api.newChat();
    final id = api.currentChatId ?? '';
    expect(id.contains('_'), isTrue);
    expect(int.tryParse(id.split('_').last), isNotNull);
  });
}
