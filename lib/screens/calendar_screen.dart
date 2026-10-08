import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../db/app_database.dart';
import '../services/calendar_repository.dart';
import '../services/reminder_scheduler.dart';
import '../theme.dart';
import 'event_edit_screen.dart';

class CalendarScreen extends StatefulWidget {
  final CalendarRepository repo;
  final ReminderScheduler reminders;

  const CalendarScreen({super.key, required this.repo, required this.reminders});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();

  Future<void> _openEditor(CalendarEvent? e) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventEditScreen(event: e, repo: widget.repo, reminders: widget.reminders),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Calendar'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppColors.accent, size: 28),
              tooltip: 'Add event',
              onPressed: () => _openEditor(null),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: StreamBuilder<List<CalendarEvent>>(
          stream: widget.repo.watchAll(),
          builder: (context, snap) {
            final events = snap.data ?? [];
            final byDay = <DateTime, List<CalendarEvent>>{};
            for (final e in events) {
              final d = DateTime(e.dueDate.year, e.dueDate.month, e.dueDate.day);
              byDay.putIfAbsent(d, () => []).add(e);
            }
            List<CalendarEvent> forDay(DateTime day) =>
                byDay[DateTime(day.year, day.month, day.day)] ?? [];
            final selectedEvents = forDay(_selected);

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 90),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: TableCalendar<CalendarEvent>(
                    firstDay: DateTime.utc(2024),
                    lastDay: DateTime.utc(2030),
                    focusedDay: _focused,
                    selectedDayPredicate: (d) => isSameDay(d, _selected),
                    eventLoader: forDay,
                    calendarFormat: CalendarFormat.month,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text),
                      leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.accentDark),
                      rightChevronIcon:
                          Icon(Icons.chevron_right, color: AppColors.accentDark),
                    ),
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekdayStyle: TextStyle(
                          fontFamily: 'Inter', fontSize: 11, color: AppColors.muted, letterSpacing: 1),
                      weekendStyle: TextStyle(
                          fontFamily: 'Inter', fontSize: 11, color: AppColors.muted, letterSpacing: 1),
                    ),
                    calendarStyle: CalendarStyle(
                      defaultTextStyle:
                          const TextStyle(fontFamily: 'Inter', color: AppColors.text),
                      weekendTextStyle:
                          const TextStyle(fontFamily: 'Inter', color: AppColors.text),
                      outsideTextStyle:
                          TextStyle(fontFamily: 'Inter', color: AppColors.muted.withValues(alpha: 0.5)),
                      todayDecoration: BoxDecoration(
                          color: AppColors.accentSoft,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.accent)),
                      selectedDecoration:
                          const BoxDecoration(color: AppColors.accentDark, shape: BoxShape.circle),
                      selectedTextStyle: const TextStyle(
                          fontFamily: 'Inter', color: Colors.white, fontWeight: FontWeight.w700),
                      todayTextStyle: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.accentDark,
                          fontWeight: FontWeight.w700),
                      markerDecoration:
                          const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                      markersMaxCount: 3,
                    ),
                    onDaySelected: (sel, focused) => setState(() {
                      _selected = sel;
                      _focused = focused;
                    }),
                    onPageChanged: (focused) => setState(() => _focused = focused),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
                  child: Text(DateFormat('EEEE, MMM d').format(_selected).toUpperCase(),
                      style: eyebrowStyle(context)),
                ),
                if (selectedEvents.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(
                      child: Text('Nothing due this day.',
                          style: TextStyle(fontFamily: 'Inter', color: AppColors.muted)),
                    ),
                  ),
                ...selectedEvents.map((e) {
                  final cat = CategoryStyle.of(e.category);
                  return GestureDetector(
                    onTap: () => _openEditor(e),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Row(children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(color: cat.bg, shape: BoxShape.circle),
                          child: Icon(cat.icon, color: cat.fg, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(e.title,
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    color: e.status == 'completed'
                                        ? AppColors.muted
                                        : AppColors.text,
                                    decoration: e.status == 'completed'
                                        ? TextDecoration.lineThrough
                                        : null)),
                            const SizedBox(height: 3),
                            Row(children: [
                              Text(
                                e.allDay || e.startTime == null
                                    ? 'All day'
                                    : DateFormat('h:mm a').format(e.startTime!),
                                style: const TextStyle(
                                    fontFamily: 'Inter', fontSize: 12.5, color: AppColors.muted),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                    color: cat.bg, borderRadius: BorderRadius.circular(100)),
                                child: Text(cat.label,
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: cat.fg)),
                              ),
                            ]),
                          ]),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                      ]),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}
