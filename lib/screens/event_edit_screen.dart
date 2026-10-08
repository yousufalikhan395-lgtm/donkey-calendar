import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db/app_database.dart';
import '../services/calendar_repository.dart';
import '../services/reminder_scheduler.dart';
import '../theme.dart';

class EventEditScreen extends StatefulWidget {
  final CalendarEvent? event;
  final CalendarRepository repo;
  final ReminderScheduler reminders;

  const EventEditScreen({super.key, this.event, required this.repo, required this.reminders});

  @override
  State<EventEditScreen> createState() => _EventEditScreenState();
}

class _EventEditScreenState extends State<EventEditScreen> {
  late final TextEditingController _title;
  late final TextEditingController _location;
  late final TextEditingController _course;
  late final TextEditingController _notes;
  late DateTime _date;
  late bool _allDay;
  TimeOfDay? _start;
  TimeOfDay? _end;
  late bool _reminder;
  late String _category;
  bool _saving = false;

  bool get _isEdit => widget.event != null;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _title = TextEditingController(text: e?.title ?? '');
    _location = TextEditingController(text: e?.location ?? '');
    _course = TextEditingController(text: e?.course ?? '');
    _notes = TextEditingController(text: e?.description ?? '');
    _date = e?.dueDate ?? DateTime.now();
    _allDay = e?.allDay ?? true;
    _start = e?.startTime != null ? TimeOfDay.fromDateTime(e!.startTime!) : null;
    _end = e?.endTime != null ? TimeOfDay.fromDateTime(e!.endTime!) : null;
    _reminder = e?.reminderEnabled ?? true;
    _category = CategoryStyle.normalize(e?.category);
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _course.dispose();
    _notes.dispose();
    super.dispose();
  }

  DateTime? _combine(TimeOfDay? t) =>
      t == null ? null : DateTime(_date.year, _date.month, _date.day, t.hour, t.minute);

  String? _clean(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final start = _allDay ? null : (_combine(_start) ?? _combine(const TimeOfDay(hour: 9, minute: 0)));
    if (_isEdit) {
      final updated = await widget.repo.updateEvent(
        widget.event!.id,
        title: _title.text.trim(),
        dueDate: _date,
        startTime: start,
        endTime: _combine(_end),
        allDay: _allDay,
        location: _location.text.trim().isEmpty ? null : _location.text.trim(),
        course: _course.text.trim().isEmpty ? null : _course.text.trim(),
        category: _category,
        notes: _clean(_notes),
        reminderEnabled: _reminder,
      );
      await widget.reminders.cancel(updated.id);
      await widget.reminders.schedule(updated);
    } else {
      final e = await widget.repo.create(
        title: _title.text.trim(),
        dueDate: _date,
        startTime: start,
        endTime: _combine(_end),
        allDay: _allDay,
        location: _clean(_location),
        course: _clean(_course),
        category: _category,
        notes: _clean(_notes),
        reminderEnabled: _reminder,
        sourceType: 'manual',
      );
      await widget.reminders.schedule(e);
    }
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete event?'),
        content: const Text('This will remove the event and its reminder.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && widget.event != null) {
      await widget.reminders.cancel(widget.event!.id);
      await widget.repo.delete(widget.event!.id);
      if (mounted) Navigator.pop(context, true);
    }
  }

  Future<void> _complete() async {
    if (widget.event == null) return;
    await widget.reminders.cancel(widget.event!.id);
    await widget.repo.markCompleted(widget.event!.id);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.text),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(_isEdit ? 'Edit event' : 'New event'),
          actions: [
            if (_isEdit)
              IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  tooltip: 'Mark complete',
                  onPressed: _complete),
            if (_isEdit)
              IconButton(
                  icon: const Icon(Icons.delete_outline, color: Color(0xFF9A3B22)),
                  tooltip: 'Delete',
                  onPressed: _delete),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
          child: Column(children: [
            _card(TextField(
              controller: _title,
              style: const TextStyle(
                  fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text),
              decoration: const InputDecoration(
                  labelText: 'Title', border: InputBorder.none, enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none, filled: false, contentPadding: EdgeInsets.zero),
            )),
            const SizedBox(height: 12),
            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('CATEGORY', style: TextStyle(fontFamily: 'Inter', fontSize: 11, letterSpacing: 2, color: AppColors.muted)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CategoryStyle.all.entries.map((entry) {
                  final sel = entry.key == _category;
                  return GestureDetector(
                    onTap: () => setState(() => _category = entry.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: sel ? entry.value.fg : entry.value.bg,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(entry.value.icon, size: 16, color: sel ? Colors.white : entry.value.fg),
                        const SizedBox(width: 6),
                        Text(entry.value.label,
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: sel ? Colors.white : entry.value.fg)),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ])),
            const SizedBox(height: 12),
            _card(Column(children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date',
                    style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: AppColors.text)),
                subtitle: Text(DateFormat('EEEE, MMM d, yyyy').format(_date),
                    style: const TextStyle(color: AppColors.muted, fontFamily: 'Inter')),
                trailing: const Icon(Icons.calendar_today_outlined, color: AppColors.accent),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2030),
                  );
                  if (d != null) setState(() => _date = d);
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('All day',
                    style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: AppColors.text)),
                value: _allDay,
                onChanged: (v) => setState(() => _allDay = v),
              ),
              if (!_allDay) ...[
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Start time',
                      style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: AppColors.text)),
                  subtitle: Text(_start == null ? 'Not set' : _start!.format(context),
                      style: const TextStyle(color: AppColors.muted, fontFamily: 'Inter')),
                  onTap: () async {
                    final t = await showTimePicker(
                        context: context, initialTime: _start ?? TimeOfDay.now());
                    if (t != null) setState(() => _start = t);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('End time',
                      style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: AppColors.text)),
                  subtitle: Text(_end == null ? 'Not set' : _end!.format(context),
                      style: const TextStyle(color: AppColors.muted, fontFamily: 'Inter')),
                  onTap: () async {
                    final t = await showTimePicker(
                        context: context, initialTime: _end ?? TimeOfDay.now());
                    if (t != null) setState(() => _end = t);
                  },
                ),
              ],
              const Divider(height: 1),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Reminder',
                    style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: AppColors.text)),
                value: _reminder,
                onChanged: (v) => setState(() => _reminder = v),
              ),
            ])),
            const SizedBox(height: 12),
            _card(Column(children: [
              TextField(controller: _location, decoration: _plain('Location')),
              const Divider(height: 1),
              TextField(controller: _course, decoration: _plain('Course')),
              const Divider(height: 1),
              TextField(controller: _notes, maxLines: 3, decoration: _plain('Notes')),
            ])),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  InputDecoration _plain(String label) => InputDecoration(
      labelText: label,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      filled: false,
      contentPadding: const EdgeInsets.symmetric(vertical: 6));

  Widget _card(Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppColors.cardShadow,
        ),
        child: child,
      );
}
