import '../db/app_database.dart';
import 'calendar_repository.dart';
import 'reminder_scheduler.dart';
import 'tool_call_parser.dart';

class ToolExecutionResult {
  final List<CalendarEvent> savedEvents;
  final List<List<Map<String, dynamic>>> pendingBatches;
  final String? error;

  ToolExecutionResult({
    this.savedEvents = const [],
    this.pendingBatches = const [],
    this.error,
  });
}

class CalendarToolExecutor {
  final CalendarRepository repo;
  final ReminderScheduler reminders;

  CalendarToolExecutor({required this.repo, required this.reminders});

  Future<ToolExecutionResult> execute(List<ToolCall> calls,
      {String sourceType = 'chat_text', bool defaultReminder = true}) async {
    final saved = <CalendarEvent>[];
    final pendingBatches = <List<Map<String, dynamic>>>[];
    String? error;

    for (final call in calls) {
      switch (call.name) {
        case 'create_event':
          final parsed = _parseEventArgs(call.arguments,
              defaultReminder: defaultReminder);
          if (parsed == null) {
            error =
                'Couldn’t understand that date. Try: “Math exam on 14 Oct at 10am”.';
            break;
          }
          final e = await repo.create(
            title: parsed['title'],
            dueDate: parsed['dueDate'],
            startTime: parsed['startTime'],
            endTime: parsed['endTime'],
            allDay: parsed['allDay'],
            location: parsed['location'],
            course: parsed['course'],
            category: parsed['category'],
            notes: parsed['notes'],
            reminderEnabled: parsed['reminder'],
            sourceType: sourceType,
            rawAiPayload: call.rawJson,
          );
          await reminders.schedule(e);
          saved.add(e);
          break;
        case 'create_events_batch':
          final events = call.arguments['events'];
          if (events is List && events.isNotEmpty) {
            pendingBatches.add(
              events.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(),
            );
          } else {
            error = 'No events found in the AI response.';
          }
          break;
        default:
          error = 'Unknown tool: ${call.name}';
      }
    }

    return ToolExecutionResult(
        savedEvents: saved, pendingBatches: pendingBatches, error: error);
  }

  Future<CalendarEvent?> confirmBatchEvent(Map<String, dynamic> args,
      {String sourceType = 'chat_image', bool defaultReminder = true}) async {
    final parsed = _parseEventArgs(args, defaultReminder: defaultReminder);
    if (parsed == null) return null;
    final e = await repo.create(
      title: parsed['title'],
      dueDate: parsed['dueDate'],
      startTime: parsed['startTime'],
      endTime: parsed['endTime'],
      allDay: parsed['allDay'],
      location: parsed['location'],
      course: parsed['course'],
      category: parsed['category'],
      notes: parsed['notes'],
      reminderEnabled: parsed['reminder'],
      sourceType: sourceType,
    );
    await reminders.schedule(e);
    return e;
  }

  Map<String, dynamic>? _parseEventArgs(Map<String, dynamic> a,
      {bool defaultReminder = true}) {
    final title = a['title']?.toString().trim();
    final dateStr = a['date']?.toString().trim();
    if (title == null || title.isEmpty || dateStr == null) return null;
    final due = DateTime.tryParse(dateStr);
    if (due == null) return null;

    DateTime? parseTime(dynamic v) {
      if (v == null || v.toString() == 'null' || v.toString().isEmpty) return null;
      final t = v.toString();
      final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(t);
      if (m == null) return null;
      return DateTime(due.year, due.month, due.day, int.parse(m.group(1)!),
          int.parse(m.group(2)!));
    }

    final start = parseTime(a['start_time']);
    final end = parseTime(a['end_time']);
    final allDay = a['all_day'] == true || (a['all_day'] != false && start == null);

    return {
      'title': title,
      'dueDate': DateTime(due.year, due.month, due.day),
      'startTime': allDay ? null : (start ?? due),
      'endTime': end,
      'allDay': allDay,
      'location': a['location']?.toString(),
      'course': a['course']?.toString(),
      'category': _category(a['category']),
      'notes': a['notes']?.toString(),
      'reminder': a.containsKey('reminder') ? a['reminder'] != false : defaultReminder,
    };
  }

  String _category(dynamic v) {
    const valid = {'academic', 'coding', 'exam', 'assignment', 'personal', 'other'};
    final c = v?.toString().toLowerCase().trim() ?? '';
    return valid.contains(c) ? c : 'other';
  }
}
