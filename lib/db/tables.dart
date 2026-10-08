import 'package:drift/drift.dart';

class CalendarEvents extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get category => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get course => text().nullable()();
  TextColumn get location => text().nullable()();
  DateTimeColumn get dueDate => dateTime()();
  DateTimeColumn get startTime => dateTime().nullable()();
  DateTimeColumn get endTime => dateTime().nullable()();
  BoolColumn get allDay => boolean().withDefault(const Constant(true))();
  BoolColumn get reminderEnabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get reminderAt => dateTime().nullable()();
  TextColumn get sourceType => text().withDefault(const Constant('chat_text'))();
  TextColumn get sourceMessageId => text().nullable()();
  TextColumn get rawAiPayload => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
