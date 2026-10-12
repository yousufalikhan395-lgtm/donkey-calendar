import 'package:donkey_calendar/db/app_database.dart';
import 'package:donkey_calendar/services/calendar_repository.dart';
import 'package:donkey_calendar/services/calendar_tool_executor.dart';
import 'package:donkey_calendar/services/reminder_scheduler.dart';
import 'package:donkey_calendar/services/tool_call_parser.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// ReminderScheduler without platform channels for tests.
class _NoopReminders extends ReminderScheduler {
  @override
  Future<void> schedule(CalendarEvent e) async {}
  @override
  Future<void> cancel(String eventId) async {}
  @override
  Future<void> rescheduleAll(List<CalendarEvent> events) async {}
}

void main() {
  late AppDatabase db;
  late CalendarRepository repo;
  late CalendarToolExecutor executor;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = CalendarRepository(db);
    executor = CalendarToolExecutor(repo: repo, reminders: _NoopReminders());
  });

  tearDown(() => db.close());

  test('create_event tool saves event with category + reminder default', () async {
    final call = ToolCallParser()
        .parse('<tool_call>{"name": "create_event", "arguments": '
            '{"title": "LeetCode review", "date": "2026-10-09", '
            '"category": "coding", "notes": "mam will check"}}'
            '</tool_call>')
        .calls
        .first;
    final res = await executor.execute([call]);
    expect(res.savedEvents.length, 1);
    final e = res.savedEvents.first;
    expect(e.title, 'LeetCode review');
    expect(e.dueDate, DateTime(2026, 10, 9));
    expect(e.allDay, isTrue);
    expect(e.category, 'coding');
    expect(e.reminderEnabled, isTrue);

    final all = await repo.getAll();
    expect(all.length, 1);
  });

  test('unknown category normalizes to other', () async {
    final call = ToolCallParser()
        .parse('<tool_call>{"name": "create_event", "arguments": '
            '{"title": "X", "date": "2026-10-09", "category": "party"}}'
            '</tool_call>')
        .calls
        .first;
    final res = await executor.execute([call]);
    expect(res.savedEvents.first.category, 'other');
  });

  test('timed event parses start time, not all-day', () async {
    final call = ToolCallParser()
        .parse('<tool_call>{"name": "create_event", "arguments": '
            '{"title": "Math Exam", "date": "2026-10-14", '
            '"start_time": "10:00", "all_day": false}}'
            '</tool_call>')
        .calls
        .first;
    final res = await executor.execute([call]);
    final e = res.savedEvents.first;
    expect(e.allDay, isFalse);
    expect(e.startTime, DateTime(2026, 10, 14, 10, 0));
  });

  test('bad date yields friendly error, saves nothing', () async {
    final call = ToolCallParser()
        .parse('<tool_call>{"name": "create_event", "arguments": '
            '{"title": "X", "date": "someday"}}'
            '</tool_call>')
        .calls
        .first;
    final res = await executor.execute([call]);
    expect(res.savedEvents, isEmpty);
    expect(res.error == null, isFalse);
    expect(await repo.getAll(), isEmpty);
  });

  test('batch tool stages events for preview, saves nothing yet', () async {
    final call = ToolCallParser()
        .parse('<tool_call>{"name": "create_events_batch", "arguments": '
            '{"events": [{"title": "A", "date": "2026-10-14"}, '
            '{"title": "B", "date": "2026-10-15"}]}}'
            '</tool_call>')
        .calls
        .first;
    final res = await executor.execute([call]);
    expect(res.savedEvents, isEmpty);
    expect(res.pendingBatches.length, 1);
    expect(await repo.getAll(), isEmpty);

    final confirmed =
        await executor.confirmBatchEvent(res.pendingBatches.first.first);
    expect(confirmed == null, isFalse);
    expect((await repo.getAll()).length, 1);
  });

  test('repository CRUD + day query + complete + delete', () async {
    final e = await repo.create(
        title: 'T', dueDate: DateTime(2026, 10, 20), category: 'exam');
    expect((await repo.eventsOn(DateTime(2026, 10, 20))).length, 1);
    expect((await repo.eventsOn(DateTime(2026, 10, 21))).length, 0);

    final updated = await repo.updateEvent(e.id,
        title: 'T2', dueDate: DateTime(2026, 10, 21));
    expect(updated.title, 'T2');
    expect((await repo.eventsOn(DateTime(2026, 10, 21))).length, 1);

    await repo.markCompleted(e.id);
    expect(await repo.getAll(), isEmpty); // completed hidden from active

    await repo.delete(e.id);
    expect(await repo.upcoming(), isEmpty);
  });

  test('default reminder off is honored when AI omits flag', () async {
    final call = ToolCallParser()
        .parse('<tool_call>{"name": "create_event", "arguments": '
            '{"title": "X", "date": "2026-10-09"}}'
            '</tool_call>')
        .calls
        .first;
    final res = await executor.execute([call], defaultReminder: false);
    expect(res.savedEvents.first.reminderEnabled, isFalse);
  });
}
