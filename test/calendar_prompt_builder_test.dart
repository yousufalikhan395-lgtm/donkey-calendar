import 'package:donkey_calendar/services/calendar_prompt_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prompt contains today date and tool schema', () {
    final now = DateTime(2026, 10, 12);
    final p = CalendarPromptBuilder.build(now: now, tz: 'Asia/Karachi');
    expect(p, contains('2026-10-12'));
    expect(p, contains('Asia/Karachi'));
    expect(p, contains('create_event'));
    expect(p, contains('create_events_batch'));
    expect(p, contains('academic|coding|exam|assignment|personal|other'));
  });

  test('wrapped message hides prompt structure from user text', () {
    final w = CalendarPromptBuilder.wrapUserMessage('leetcode on 9th');
    expect(w, contains('[SYSTEM]'));
    expect(w, contains('[USER]'));
    expect(w, contains('leetcode on 9th'));
  });
}
