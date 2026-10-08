import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';

class CalendarRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  CalendarRepository(this._db);

  AppDatabase get db => _db;

  Stream<List<CalendarEvent>> watchAll() =>
      (_db.select(_db.calendarEvents)
            ..where((t) => t.status.equals('active'))
            ..orderBy([(t) => OrderingTerm.asc(t.dueDate)]))
          .watch();

  Future<List<CalendarEvent>> getAll() =>
      (_db.select(_db.calendarEvents)
            ..where((t) => t.status.equals('active'))
            ..orderBy([(t) => OrderingTerm.asc(t.dueDate)]))
          .get();

  Future<List<CalendarEvent>> eventsOn(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return (_db.select(_db.calendarEvents)
          ..where((t) =>
              t.status.equals('active') &
              t.dueDate.isBiggerOrEqualValue(start) &
              t.dueDate.isSmallerThanValue(end)))
        .get();
  }

  Future<CalendarEvent> create({
    required String title,
    required DateTime dueDate,
    DateTime? startTime,
    DateTime? endTime,
    bool allDay = true,
    String? location,
    String? course,
    String? category,
    String? notes,
    bool reminderEnabled = true,
    DateTime? reminderAt,
    String sourceType = 'chat_text',
    String? sourceMessageId,
    String? rawAiPayload,
  }) async {
    final now = DateTime.now();
    final event = CalendarEventsCompanion.insert(
      id: _uuid.v4(),
      title: title,
      dueDate: dueDate,
      startTime: Value(startTime),
      endTime: Value(endTime),
      allDay: Value(allDay),
      reminderEnabled: Value(reminderEnabled),
      reminderAt: Value(reminderAt),
      location: Value(location),
      course: Value(course),
      category: Value(category),
      description: Value(notes),
      sourceType: Value(sourceType),
      sourceMessageId: Value(sourceMessageId),
      rawAiPayload: Value(rawAiPayload),
      createdAt: now,
      updatedAt: now,
    );
    await _db.into(_db.calendarEvents).insert(event);
    return (await (_db.select(_db.calendarEvents)
              ..where((t) => t.id.equals(event.id.value)))
            .getSingle());
  }

  Future<void> update(CalendarEvent e) =>
      (_db.update(_db.calendarEvents)..where((t) => t.id.equals(e.id))).write(
        CalendarEventsCompanion(
          title: Value(e.title),
          dueDate: Value(e.dueDate),
          startTime: Value(e.startTime),
          endTime: Value(e.endTime),
          allDay: Value(e.allDay),
          reminderEnabled: Value(e.reminderEnabled),
          reminderAt: Value(e.reminderAt),
          location: Value(e.location),
          course: Value(e.course),
          category: Value(e.category),
          description: Value(e.description),
          status: Value(e.status),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> delete(String id) =>
      (_db.delete(_db.calendarEvents)..where((t) => t.id.equals(id))).go();

  Future<void> deleteAll() => _db.delete(_db.calendarEvents).go();

  Future<void> markCompleted(String id) async {
    final e = await (_db.select(_db.calendarEvents)
              ..where((t) => t.id.equals(id)))
            .getSingle();
    await update(e.copyWith(status: 'completed'));
  }

  Future<CalendarEvent> updateEvent(
    String id, {
    String? title,
    DateTime? dueDate,
    DateTime? startTime,
    DateTime? endTime,
    bool? allDay,
    String? location,
    String? course,
    String? category,
    String? notes,
    bool? reminderEnabled,
    DateTime? reminderAt,
    String? status,
  }) async {
    final e = await (_db.select(_db.calendarEvents)
              ..where((t) => t.id.equals(id)))
            .getSingle();
    final updated = e.copyWith(
      title: title ?? e.title,
      dueDate: dueDate ?? e.dueDate,
      startTime: Value(startTime ?? e.startTime),
      endTime: Value(endTime ?? e.endTime),
      allDay: allDay ?? e.allDay,
      location: Value(location ?? e.location),
      course: Value(course ?? e.course),
      category: Value(category ?? e.category),
      description: Value(notes ?? e.description),
      reminderEnabled: reminderEnabled ?? e.reminderEnabled,
      reminderAt: Value(reminderAt ?? e.reminderAt),
      status: status ?? e.status,
      updatedAt: DateTime.now(),
    );
    await (_db.update(_db.calendarEvents)..where((t) => t.id.equals(id)))
        .write(updated);
    return updated;
  }

  Future<List<CalendarEvent>> upcoming() =>
      (_db.select(_db.calendarEvents)
            ..where((t) =>
                t.status.equals('active') &
                t.dueDate.isBiggerOrEqualValue(DateTime.now()))
            ..orderBy([(t) => OrderingTerm.asc(t.dueDate)])
            ..limit(200))
          .get();
}
