// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CalendarEventsTable extends CalendarEvents
    with TableInfo<$CalendarEventsTable, CalendarEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalendarEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _courseMeta = const VerificationMeta('course');
  @override
  late final GeneratedColumn<String> course = GeneratedColumn<String>(
      'course', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _locationMeta =
      const VerificationMeta('location');
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
      'location', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dueDateMeta =
      const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
      'due_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
      'start_time', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
      'end_time', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _allDayMeta = const VerificationMeta('allDay');
  @override
  late final GeneratedColumn<bool> allDay = GeneratedColumn<bool>(
      'all_day', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("all_day" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _reminderEnabledMeta =
      const VerificationMeta('reminderEnabled');
  @override
  late final GeneratedColumn<bool> reminderEnabled = GeneratedColumn<bool>(
      'reminder_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("reminder_enabled" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _reminderAtMeta =
      const VerificationMeta('reminderAt');
  @override
  late final GeneratedColumn<DateTime> reminderAt = GeneratedColumn<DateTime>(
      'reminder_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _sourceTypeMeta =
      const VerificationMeta('sourceType');
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
      'source_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('chat_text'));
  static const VerificationMeta _sourceMessageIdMeta =
      const VerificationMeta('sourceMessageId');
  @override
  late final GeneratedColumn<String> sourceMessageId = GeneratedColumn<String>(
      'source_message_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _rawAiPayloadMeta =
      const VerificationMeta('rawAiPayload');
  @override
  late final GeneratedColumn<String> rawAiPayload = GeneratedColumn<String>(
      'raw_ai_payload', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('active'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        category,
        description,
        course,
        location,
        dueDate,
        startTime,
        endTime,
        allDay,
        reminderEnabled,
        reminderAt,
        sourceType,
        sourceMessageId,
        rawAiPayload,
        status,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calendar_events';
  @override
  VerificationContext validateIntegrity(Insertable<CalendarEvent> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('course')) {
      context.handle(_courseMeta,
          course.isAcceptableOrUnknown(data['course']!, _courseMeta));
    }
    if (data.containsKey('location')) {
      context.handle(_locationMeta,
          location.isAcceptableOrUnknown(data['location']!, _locationMeta));
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    } else if (isInserting) {
      context.missing(_dueDateMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    }
    if (data.containsKey('all_day')) {
      context.handle(_allDayMeta,
          allDay.isAcceptableOrUnknown(data['all_day']!, _allDayMeta));
    }
    if (data.containsKey('reminder_enabled')) {
      context.handle(
          _reminderEnabledMeta,
          reminderEnabled.isAcceptableOrUnknown(
              data['reminder_enabled']!, _reminderEnabledMeta));
    }
    if (data.containsKey('reminder_at')) {
      context.handle(
          _reminderAtMeta,
          reminderAt.isAcceptableOrUnknown(
              data['reminder_at']!, _reminderAtMeta));
    }
    if (data.containsKey('source_type')) {
      context.handle(
          _sourceTypeMeta,
          sourceType.isAcceptableOrUnknown(
              data['source_type']!, _sourceTypeMeta));
    }
    if (data.containsKey('source_message_id')) {
      context.handle(
          _sourceMessageIdMeta,
          sourceMessageId.isAcceptableOrUnknown(
              data['source_message_id']!, _sourceMessageIdMeta));
    }
    if (data.containsKey('raw_ai_payload')) {
      context.handle(
          _rawAiPayloadMeta,
          rawAiPayload.isAcceptableOrUnknown(
              data['raw_ai_payload']!, _rawAiPayloadMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CalendarEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalendarEvent(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      course: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}course']),
      location: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}location']),
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}due_date'])!,
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_time']),
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_time']),
      allDay: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}all_day'])!,
      reminderEnabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}reminder_enabled'])!,
      reminderAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}reminder_at']),
      sourceType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_type'])!,
      sourceMessageId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_message_id']),
      rawAiPayload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}raw_ai_payload']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CalendarEventsTable createAlias(String alias) {
    return $CalendarEventsTable(attachedDatabase, alias);
  }
}

class CalendarEvent extends DataClass implements Insertable<CalendarEvent> {
  final String id;
  final String title;
  final String? category;
  final String? description;
  final String? course;
  final String? location;
  final DateTime dueDate;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool allDay;
  final bool reminderEnabled;
  final DateTime? reminderAt;
  final String sourceType;
  final String? sourceMessageId;
  final String? rawAiPayload;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CalendarEvent(
      {required this.id,
      required this.title,
      this.category,
      this.description,
      this.course,
      this.location,
      required this.dueDate,
      this.startTime,
      this.endTime,
      required this.allDay,
      required this.reminderEnabled,
      this.reminderAt,
      required this.sourceType,
      this.sourceMessageId,
      this.rawAiPayload,
      required this.status,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || course != null) {
      map['course'] = Variable<String>(course);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    map['due_date'] = Variable<DateTime>(dueDate);
    if (!nullToAbsent || startTime != null) {
      map['start_time'] = Variable<DateTime>(startTime);
    }
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<DateTime>(endTime);
    }
    map['all_day'] = Variable<bool>(allDay);
    map['reminder_enabled'] = Variable<bool>(reminderEnabled);
    if (!nullToAbsent || reminderAt != null) {
      map['reminder_at'] = Variable<DateTime>(reminderAt);
    }
    map['source_type'] = Variable<String>(sourceType);
    if (!nullToAbsent || sourceMessageId != null) {
      map['source_message_id'] = Variable<String>(sourceMessageId);
    }
    if (!nullToAbsent || rawAiPayload != null) {
      map['raw_ai_payload'] = Variable<String>(rawAiPayload);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CalendarEventsCompanion toCompanion(bool nullToAbsent) {
    return CalendarEventsCompanion(
      id: Value(id),
      title: Value(title),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      course:
          course == null && nullToAbsent ? const Value.absent() : Value(course),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      dueDate: Value(dueDate),
      startTime: startTime == null && nullToAbsent
          ? const Value.absent()
          : Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      allDay: Value(allDay),
      reminderEnabled: Value(reminderEnabled),
      reminderAt: reminderAt == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderAt),
      sourceType: Value(sourceType),
      sourceMessageId: sourceMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceMessageId),
      rawAiPayload: rawAiPayload == null && nullToAbsent
          ? const Value.absent()
          : Value(rawAiPayload),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalendarEvent(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      category: serializer.fromJson<String?>(json['category']),
      description: serializer.fromJson<String?>(json['description']),
      course: serializer.fromJson<String?>(json['course']),
      location: serializer.fromJson<String?>(json['location']),
      dueDate: serializer.fromJson<DateTime>(json['dueDate']),
      startTime: serializer.fromJson<DateTime?>(json['startTime']),
      endTime: serializer.fromJson<DateTime?>(json['endTime']),
      allDay: serializer.fromJson<bool>(json['allDay']),
      reminderEnabled: serializer.fromJson<bool>(json['reminderEnabled']),
      reminderAt: serializer.fromJson<DateTime?>(json['reminderAt']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      sourceMessageId: serializer.fromJson<String?>(json['sourceMessageId']),
      rawAiPayload: serializer.fromJson<String?>(json['rawAiPayload']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'category': serializer.toJson<String?>(category),
      'description': serializer.toJson<String?>(description),
      'course': serializer.toJson<String?>(course),
      'location': serializer.toJson<String?>(location),
      'dueDate': serializer.toJson<DateTime>(dueDate),
      'startTime': serializer.toJson<DateTime?>(startTime),
      'endTime': serializer.toJson<DateTime?>(endTime),
      'allDay': serializer.toJson<bool>(allDay),
      'reminderEnabled': serializer.toJson<bool>(reminderEnabled),
      'reminderAt': serializer.toJson<DateTime?>(reminderAt),
      'sourceType': serializer.toJson<String>(sourceType),
      'sourceMessageId': serializer.toJson<String?>(sourceMessageId),
      'rawAiPayload': serializer.toJson<String?>(rawAiPayload),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CalendarEvent copyWith(
          {String? id,
          String? title,
          Value<String?> category = const Value.absent(),
          Value<String?> description = const Value.absent(),
          Value<String?> course = const Value.absent(),
          Value<String?> location = const Value.absent(),
          DateTime? dueDate,
          Value<DateTime?> startTime = const Value.absent(),
          Value<DateTime?> endTime = const Value.absent(),
          bool? allDay,
          bool? reminderEnabled,
          Value<DateTime?> reminderAt = const Value.absent(),
          String? sourceType,
          Value<String?> sourceMessageId = const Value.absent(),
          Value<String?> rawAiPayload = const Value.absent(),
          String? status,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      CalendarEvent(
        id: id ?? this.id,
        title: title ?? this.title,
        category: category.present ? category.value : this.category,
        description: description.present ? description.value : this.description,
        course: course.present ? course.value : this.course,
        location: location.present ? location.value : this.location,
        dueDate: dueDate ?? this.dueDate,
        startTime: startTime.present ? startTime.value : this.startTime,
        endTime: endTime.present ? endTime.value : this.endTime,
        allDay: allDay ?? this.allDay,
        reminderEnabled: reminderEnabled ?? this.reminderEnabled,
        reminderAt: reminderAt.present ? reminderAt.value : this.reminderAt,
        sourceType: sourceType ?? this.sourceType,
        sourceMessageId: sourceMessageId.present
            ? sourceMessageId.value
            : this.sourceMessageId,
        rawAiPayload:
            rawAiPayload.present ? rawAiPayload.value : this.rawAiPayload,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CalendarEvent copyWithCompanion(CalendarEventsCompanion data) {
    return CalendarEvent(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      category: data.category.present ? data.category.value : this.category,
      description:
          data.description.present ? data.description.value : this.description,
      course: data.course.present ? data.course.value : this.course,
      location: data.location.present ? data.location.value : this.location,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      allDay: data.allDay.present ? data.allDay.value : this.allDay,
      reminderEnabled: data.reminderEnabled.present
          ? data.reminderEnabled.value
          : this.reminderEnabled,
      reminderAt:
          data.reminderAt.present ? data.reminderAt.value : this.reminderAt,
      sourceType:
          data.sourceType.present ? data.sourceType.value : this.sourceType,
      sourceMessageId: data.sourceMessageId.present
          ? data.sourceMessageId.value
          : this.sourceMessageId,
      rawAiPayload: data.rawAiPayload.present
          ? data.rawAiPayload.value
          : this.rawAiPayload,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalendarEvent(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('course: $course, ')
          ..write('location: $location, ')
          ..write('dueDate: $dueDate, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('allDay: $allDay, ')
          ..write('reminderEnabled: $reminderEnabled, ')
          ..write('reminderAt: $reminderAt, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceMessageId: $sourceMessageId, ')
          ..write('rawAiPayload: $rawAiPayload, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      category,
      description,
      course,
      location,
      dueDate,
      startTime,
      endTime,
      allDay,
      reminderEnabled,
      reminderAt,
      sourceType,
      sourceMessageId,
      rawAiPayload,
      status,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalendarEvent &&
          other.id == this.id &&
          other.title == this.title &&
          other.category == this.category &&
          other.description == this.description &&
          other.course == this.course &&
          other.location == this.location &&
          other.dueDate == this.dueDate &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.allDay == this.allDay &&
          other.reminderEnabled == this.reminderEnabled &&
          other.reminderAt == this.reminderAt &&
          other.sourceType == this.sourceType &&
          other.sourceMessageId == this.sourceMessageId &&
          other.rawAiPayload == this.rawAiPayload &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CalendarEventsCompanion extends UpdateCompanion<CalendarEvent> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> category;
  final Value<String?> description;
  final Value<String?> course;
  final Value<String?> location;
  final Value<DateTime> dueDate;
  final Value<DateTime?> startTime;
  final Value<DateTime?> endTime;
  final Value<bool> allDay;
  final Value<bool> reminderEnabled;
  final Value<DateTime?> reminderAt;
  final Value<String> sourceType;
  final Value<String?> sourceMessageId;
  final Value<String?> rawAiPayload;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CalendarEventsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.category = const Value.absent(),
    this.description = const Value.absent(),
    this.course = const Value.absent(),
    this.location = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.allDay = const Value.absent(),
    this.reminderEnabled = const Value.absent(),
    this.reminderAt = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceMessageId = const Value.absent(),
    this.rawAiPayload = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CalendarEventsCompanion.insert({
    required String id,
    required String title,
    this.category = const Value.absent(),
    this.description = const Value.absent(),
    this.course = const Value.absent(),
    this.location = const Value.absent(),
    required DateTime dueDate,
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.allDay = const Value.absent(),
    this.reminderEnabled = const Value.absent(),
    this.reminderAt = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceMessageId = const Value.absent(),
    this.rawAiPayload = const Value.absent(),
    this.status = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        dueDate = Value(dueDate),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<CalendarEvent> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? category,
    Expression<String>? description,
    Expression<String>? course,
    Expression<String>? location,
    Expression<DateTime>? dueDate,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<bool>? allDay,
    Expression<bool>? reminderEnabled,
    Expression<DateTime>? reminderAt,
    Expression<String>? sourceType,
    Expression<String>? sourceMessageId,
    Expression<String>? rawAiPayload,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (category != null) 'category': category,
      if (description != null) 'description': description,
      if (course != null) 'course': course,
      if (location != null) 'location': location,
      if (dueDate != null) 'due_date': dueDate,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (allDay != null) 'all_day': allDay,
      if (reminderEnabled != null) 'reminder_enabled': reminderEnabled,
      if (reminderAt != null) 'reminder_at': reminderAt,
      if (sourceType != null) 'source_type': sourceType,
      if (sourceMessageId != null) 'source_message_id': sourceMessageId,
      if (rawAiPayload != null) 'raw_ai_payload': rawAiPayload,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CalendarEventsCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String?>? category,
      Value<String?>? description,
      Value<String?>? course,
      Value<String?>? location,
      Value<DateTime>? dueDate,
      Value<DateTime?>? startTime,
      Value<DateTime?>? endTime,
      Value<bool>? allDay,
      Value<bool>? reminderEnabled,
      Value<DateTime?>? reminderAt,
      Value<String>? sourceType,
      Value<String?>? sourceMessageId,
      Value<String?>? rawAiPayload,
      Value<String>? status,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return CalendarEventsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      course: course ?? this.course,
      location: location ?? this.location,
      dueDate: dueDate ?? this.dueDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      allDay: allDay ?? this.allDay,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderAt: reminderAt ?? this.reminderAt,
      sourceType: sourceType ?? this.sourceType,
      sourceMessageId: sourceMessageId ?? this.sourceMessageId,
      rawAiPayload: rawAiPayload ?? this.rawAiPayload,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (course.present) {
      map['course'] = Variable<String>(course.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (allDay.present) {
      map['all_day'] = Variable<bool>(allDay.value);
    }
    if (reminderEnabled.present) {
      map['reminder_enabled'] = Variable<bool>(reminderEnabled.value);
    }
    if (reminderAt.present) {
      map['reminder_at'] = Variable<DateTime>(reminderAt.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (sourceMessageId.present) {
      map['source_message_id'] = Variable<String>(sourceMessageId.value);
    }
    if (rawAiPayload.present) {
      map['raw_ai_payload'] = Variable<String>(rawAiPayload.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalendarEventsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('course: $course, ')
          ..write('location: $location, ')
          ..write('dueDate: $dueDate, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('allDay: $allDay, ')
          ..write('reminderEnabled: $reminderEnabled, ')
          ..write('reminderAt: $reminderAt, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceMessageId: $sourceMessageId, ')
          ..write('rawAiPayload: $rawAiPayload, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CalendarEventsTable calendarEvents = $CalendarEventsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [calendarEvents];
}

typedef $$CalendarEventsTableCreateCompanionBuilder = CalendarEventsCompanion
    Function({
  required String id,
  required String title,
  Value<String?> category,
  Value<String?> description,
  Value<String?> course,
  Value<String?> location,
  required DateTime dueDate,
  Value<DateTime?> startTime,
  Value<DateTime?> endTime,
  Value<bool> allDay,
  Value<bool> reminderEnabled,
  Value<DateTime?> reminderAt,
  Value<String> sourceType,
  Value<String?> sourceMessageId,
  Value<String?> rawAiPayload,
  Value<String> status,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$CalendarEventsTableUpdateCompanionBuilder = CalendarEventsCompanion
    Function({
  Value<String> id,
  Value<String> title,
  Value<String?> category,
  Value<String?> description,
  Value<String?> course,
  Value<String?> location,
  Value<DateTime> dueDate,
  Value<DateTime?> startTime,
  Value<DateTime?> endTime,
  Value<bool> allDay,
  Value<bool> reminderEnabled,
  Value<DateTime?> reminderAt,
  Value<String> sourceType,
  Value<String?> sourceMessageId,
  Value<String?> rawAiPayload,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$CalendarEventsTableFilterComposer
    extends Composer<_$AppDatabase, $CalendarEventsTable> {
  $$CalendarEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get course => $composableBuilder(
      column: $table.course, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get allDay => $composableBuilder(
      column: $table.allDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get reminderEnabled => $composableBuilder(
      column: $table.reminderEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get reminderAt => $composableBuilder(
      column: $table.reminderAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceType => $composableBuilder(
      column: $table.sourceType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceMessageId => $composableBuilder(
      column: $table.sourceMessageId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rawAiPayload => $composableBuilder(
      column: $table.rawAiPayload, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$CalendarEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $CalendarEventsTable> {
  $$CalendarEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get course => $composableBuilder(
      column: $table.course, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get allDay => $composableBuilder(
      column: $table.allDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get reminderEnabled => $composableBuilder(
      column: $table.reminderEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get reminderAt => $composableBuilder(
      column: $table.reminderAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceType => $composableBuilder(
      column: $table.sourceType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceMessageId => $composableBuilder(
      column: $table.sourceMessageId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rawAiPayload => $composableBuilder(
      column: $table.rawAiPayload,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$CalendarEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CalendarEventsTable> {
  $$CalendarEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get course =>
      $composableBuilder(column: $table.course, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<bool> get allDay =>
      $composableBuilder(column: $table.allDay, builder: (column) => column);

  GeneratedColumn<bool> get reminderEnabled => $composableBuilder(
      column: $table.reminderEnabled, builder: (column) => column);

  GeneratedColumn<DateTime> get reminderAt => $composableBuilder(
      column: $table.reminderAt, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
      column: $table.sourceType, builder: (column) => column);

  GeneratedColumn<String> get sourceMessageId => $composableBuilder(
      column: $table.sourceMessageId, builder: (column) => column);

  GeneratedColumn<String> get rawAiPayload => $composableBuilder(
      column: $table.rawAiPayload, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CalendarEventsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CalendarEventsTable,
    CalendarEvent,
    $$CalendarEventsTableFilterComposer,
    $$CalendarEventsTableOrderingComposer,
    $$CalendarEventsTableAnnotationComposer,
    $$CalendarEventsTableCreateCompanionBuilder,
    $$CalendarEventsTableUpdateCompanionBuilder,
    (
      CalendarEvent,
      BaseReferences<_$AppDatabase, $CalendarEventsTable, CalendarEvent>
    ),
    CalendarEvent,
    PrefetchHooks Function()> {
  $$CalendarEventsTableTableManager(
      _$AppDatabase db, $CalendarEventsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalendarEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalendarEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CalendarEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> course = const Value.absent(),
            Value<String?> location = const Value.absent(),
            Value<DateTime> dueDate = const Value.absent(),
            Value<DateTime?> startTime = const Value.absent(),
            Value<DateTime?> endTime = const Value.absent(),
            Value<bool> allDay = const Value.absent(),
            Value<bool> reminderEnabled = const Value.absent(),
            Value<DateTime?> reminderAt = const Value.absent(),
            Value<String> sourceType = const Value.absent(),
            Value<String?> sourceMessageId = const Value.absent(),
            Value<String?> rawAiPayload = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CalendarEventsCompanion(
            id: id,
            title: title,
            category: category,
            description: description,
            course: course,
            location: location,
            dueDate: dueDate,
            startTime: startTime,
            endTime: endTime,
            allDay: allDay,
            reminderEnabled: reminderEnabled,
            reminderAt: reminderAt,
            sourceType: sourceType,
            sourceMessageId: sourceMessageId,
            rawAiPayload: rawAiPayload,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            Value<String?> category = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> course = const Value.absent(),
            Value<String?> location = const Value.absent(),
            required DateTime dueDate,
            Value<DateTime?> startTime = const Value.absent(),
            Value<DateTime?> endTime = const Value.absent(),
            Value<bool> allDay = const Value.absent(),
            Value<bool> reminderEnabled = const Value.absent(),
            Value<DateTime?> reminderAt = const Value.absent(),
            Value<String> sourceType = const Value.absent(),
            Value<String?> sourceMessageId = const Value.absent(),
            Value<String?> rawAiPayload = const Value.absent(),
            Value<String> status = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CalendarEventsCompanion.insert(
            id: id,
            title: title,
            category: category,
            description: description,
            course: course,
            location: location,
            dueDate: dueDate,
            startTime: startTime,
            endTime: endTime,
            allDay: allDay,
            reminderEnabled: reminderEnabled,
            reminderAt: reminderAt,
            sourceType: sourceType,
            sourceMessageId: sourceMessageId,
            rawAiPayload: rawAiPayload,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$CalendarEventsTable, CalendarEvent>(table),
                    BaseReferences<_$AppDatabase, $CalendarEventsTable,
                        CalendarEvent>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CalendarEventsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CalendarEventsTable,
    CalendarEvent,
    $$CalendarEventsTableFilterComposer,
    $$CalendarEventsTableOrderingComposer,
    $$CalendarEventsTableAnnotationComposer,
    $$CalendarEventsTableCreateCompanionBuilder,
    $$CalendarEventsTableUpdateCompanionBuilder,
    (
      CalendarEvent,
      BaseReferences<_$AppDatabase, $CalendarEventsTable, CalendarEvent>
    ),
    CalendarEvent,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CalendarEventsTableTableManager get calendarEvents =>
      $$CalendarEventsTableTableManager(_db, _db.calendarEvents);
}
