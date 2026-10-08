import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/app_database.dart';
import '../theme.dart';

/// Light event card matching the Home design: tinted background,
/// circular category icon badge, bold title, time + category pill.
class EventCard extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback? onUndo;
  final VoidCallback? onEdit;
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.event,
    this.onUndo,
    this.onEdit,
    this.onTap,
  });

  String _timeLabel() {
    if (event.allDay || event.startTime == null) return 'All day';
    return DateFormat('h:mm a').format(event.startTime!);
  }

  @override
  Widget build(BuildContext context) {
    final cat = CategoryStyle.of(event.category);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cat.bg.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: cat.bg, shape: BoxShape.circle),
                  child: Icon(cat.icon, color: cat.fg, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        color: AppColors.text),
                  ),
                ),
                if (event.status == 'completed')
                  const Icon(Icons.check_circle, color: AppColors.accent, size: 22),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 66),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 16, color: AppColors.muted),
                  const SizedBox(width: 5),
                  Text(_timeLabel(),
                      style: const TextStyle(
                          fontFamily: 'Inter', fontSize: 14, color: AppColors.text)),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                        color: cat.bg, borderRadius: BorderRadius.circular(100)),
                    child: Text(cat.label,
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: cat.fg)),
                  ),
                ],
              ),
            ),
            if (onUndo != null || onEdit != null) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 66),
                child: Row(children: [
                  if (onUndo != null)
                    _ActionChip(label: 'Undo', onTap: onUndo!),
                  if (onEdit != null) ...[
                    const SizedBox(width: 8),
                    _ActionChip(label: 'Edit', onTap: onEdit!),
                  ],
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ActionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.line),
        ),
        child: Text(label,
            style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.accentDark)),
      ),
    );
  }
}
