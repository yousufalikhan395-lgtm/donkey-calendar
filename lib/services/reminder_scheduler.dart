import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../db/app_database.dart';

class ReminderScheduler {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _inited = false;

  Future<void> init() async {
    if (_inited) return;
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _inited = true;
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? true;
  }

  DateTime computeReminderAt(CalendarEvent e) {
    if (e.reminderAt != null) return e.reminderAt!;
    if (e.allDay || e.startTime == null) {
      final day = DateTime(e.dueDate.year, e.dueDate.month, e.dueDate.day);
      return day.subtract(const Duration(days: 1)).copyWith(hour: 9, minute: 0);
    }
    return (e.startTime ?? e.dueDate).subtract(const Duration(hours: 1));
  }

  int _notifId(String eventId) => eventId.hashCode & 0x7FFFFFFF;

  Future<void> schedule(CalendarEvent e) async {
    if (!e.reminderEnabled) return;
    await init();
    final at = computeReminderAt(e);
    if (at.isBefore(DateTime.now())) return;
    final title = e.allDay || e.startTime == null
        ? '${e.title} tomorrow'
        : '${e.title} in 1 hour';
    final body = e.allDay || e.startTime == null
        ? 'Due on ${_fmt(e.dueDate)}. Tap to view.'
        : 'Starts at ${_fmtTime(e.startTime!)}. Tap to view.';
    await _plugin.zonedSchedule(
      _notifId(e.id),
      title,
      body,
      tz.TZDateTime.from(at, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'calendar_reminders',
          'Calendar reminders',
          channelDescription: 'Reminders for upcoming events',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: e.id,
    );
  }

  Future<void> cancel(String eventId) async {
    await init();
    await _plugin.cancel(_notifId(eventId));
  }

  Future<void> rescheduleAll(List<CalendarEvent> events) async {
    for (final e in events) {
      await cancel(e.id);
      if (e.status == 'active' && e.reminderEnabled) {
        await schedule(e);
      }
    }
  }

  String _fmt(DateTime d) =>
      '${_month(d.month)} ${d.day}';
  String _fmtTime(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final ap = d.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ap';
  }

  String _month(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m - 1];
}
