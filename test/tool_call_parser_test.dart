import 'package:donkey_calendar/services/tool_call_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = ToolCallParser();

  test('single create_event is extracted, visible text kept', () {
    const raw = 'Sure!\n<tool_call>\n{"name": "create_event", "arguments": '
        '{"title": "LeetCode review", "date": "2026-10-09", "all_day": true}}\n</tool_call>';
    final r = parser.parse(raw);
    expect(r.calls.length, 1);
    expect(r.calls.first.name, 'create_event');
    expect(r.calls.first.arguments['title'], 'LeetCode review');
    expect(r.visibleText, 'Sure!');
    expect(r.error, isNull);
  });

  test('no tool call passes text through untouched', () {
    const raw = 'Which day next week?';
    final r = parser.parse(raw);
    expect(r.calls, isEmpty);
    expect(r.visibleText, raw);
    expect(r.error, isNull);
  });

  test('incomplete tool call is dropped with error', () {
    const raw = 'Adding it <tool_call>\n{"name": "create_event",';
    final r = parser.parse(raw);
    expect(r.calls, isEmpty);
    expect(r.visibleText, 'Adding it');
    expect(r.error, isNotNull);
  });

  test('trailing commas are repaired', () {
    const raw = '<tool_call>{"name": "create_event", "arguments": '
        '{"title": "X", "date": "2026-10-09",},}</tool_call>';
    final r = parser.parse(raw);
    expect(r.calls.length, 1);
    expect(r.calls.first.arguments['title'], 'X');
  });

  test('batch call parses event list', () {
    const raw = '<tool_call>{"name": "create_events_batch", "arguments": '
        '{"events": [{"title": "Math", "date": "2026-10-14"}, '
        '{"title": "Physics", "date": "2026-10-16"}]}}</tool_call>';
    final r = parser.parse(raw);
    expect(r.calls.length, 1);
    expect(r.calls.first.name, 'create_events_batch');
    expect((r.calls.first.arguments['events'] as List).length, 2);
  });

  test('unknown tool name still parses (executor rejects)', () {
    const raw = '<tool_call>{"name": "fly_to_moon", "arguments": {}}</tool_call>';
    final r = parser.parse(raw);
    expect(r.calls.length, 1);
    expect(r.calls.first.name, 'fly_to_moon');
  });
}
