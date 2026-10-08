import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../db/app_database.dart';
import '../services/calendar_repository.dart';
import '../services/reminder_scheduler.dart';
import '../theme.dart';
import '../widgets/event_card.dart';
import 'event_edit_screen.dart';

class HomeScreen extends StatefulWidget {
  final CalendarRepository repo;
  final ReminderScheduler reminders;
  final void Function({String? initialText, String? imagePath}) onOpenChat;

  const HomeScreen({
    super.key,
    required this.repo,
    required this.reminders,
    required this.onOpenChat,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _selected;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selected = DateTime(now.year, now.month, now.day);
  }

  List<DateTime> get _week {
    final monday = _selected.subtract(Duration(days: _selected.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  Future<void> _openEditor(CalendarEvent e) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventEditScreen(event: e, repo: widget.repo, reminders: widget.reminders),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final x = await _picker.pickImage(source: source);
    if (x != null && mounted) widget.onOpenChat(imagePath: x.path);
  }

  void _showImageSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: AppColors.accent),
            title: const Text('Choose from gallery',
                style: TextStyle(fontFamily: 'Inter', color: AppColors.text)),
            onTap: () {
              Navigator.pop(ctx);
              _pickImage(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined, color: AppColors.accent),
            title: const Text('Take a photo',
                style: TextStyle(fontFamily: 'Inter', color: AppColors.text)),
            onTap: () {
              Navigator.pop(ctx);
              _pickImage(ImageSource.camera);
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _header(),
              _weekStrip(),
              Expanded(
                child: StreamBuilder<List<CalendarEvent>>(
                  stream: widget.repo.watchAll(),
                  builder: (context, snap) {
                    final all = snap.data ?? [];
                    final dayEvents = all.where((e) {
                      final d = e.dueDate;
                      return d.year == _selected.year &&
                          d.month == _selected.month &&
                          d.day == _selected.day;
                    }).toList();
                    final upcoming = all
                        .where((e) => e.dueDate.isAfter(
                            _selected.add(const Duration(days: 1)).subtract(const Duration(seconds: 1))))
                        .take(3)
                        .toList();
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      children: [
                        if (dayEvents.isEmpty)
                          _emptyState()
                        else
                          ...dayEvents.map((e) => EventCard(
                                event: e,
                                onTap: () => _openEditor(e),
                              )),
                        if (upcoming.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text('COMING UP NEXT',
                              style: eyebrowStyle(context).copyWith(fontSize: 11)),
                          const SizedBox(height: 8),
                          ...upcoming.map((e) => _upcomingRow(e)),
                        ],
                      ],
                    );
                  },
                ),
              ),
              _captureBar(),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
      child: Row(children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.cardShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset('assets/donkey.png', fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.pets, color: AppColors.accent)),
          ),
        ),
        const SizedBox(width: 12),
        RichText(
          text: const TextSpan(
            style: TextStyle(
                fontFamily: 'Inter', fontSize: 26, letterSpacing: -0.8, color: AppColors.text),
            children: [
              TextSpan(text: 'Donkey', style: TextStyle(fontWeight: FontWeight.w800)),
              TextSpan(text: 'Calendar', style: TextStyle(fontWeight: FontWeight.w400)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _weekStrip() {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          final d = _week[i];
          final isSel = d.year == _selected.year &&
              d.month == _selected.month &&
              d.day == _selected.day;
          final isToday = d.year == today.year &&
              d.month == today.month &&
              d.day == today.day;
          return GestureDetector(
            onTap: () => setState(() => _selected = d),
            child: Container(
              width: 44,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSel ? AppColors.accentDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppColors.cardShadow,
                border: isToday && !isSel
                    ? Border.all(color: AppColors.accent, width: 1.5)
                    : null,
              ),
              child: Column(children: [
                Text(days[i],
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSel ? Colors.white70 : AppColors.muted)),
                const SizedBox(height: 2),
                Text('${d.day}',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isSel ? Colors.white : AppColors.text)),
              ]),
            ),
          );
        }),
      ),
    );
  }

  Widget _emptyState() {
    final isToday = () {
      final t = DateTime.now();
      return _selected.year == t.year &&
          _selected.month == t.month &&
          _selected.day == t.day;
    }();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          isToday ? 'Nothing due today. Enjoy the calm.' : 'Nothing due this day.',
          style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.text),
        ),
        const SizedBox(height: 6),
        const Text('Tell the AI what your teacher said and it will appear here.',
            style: TextStyle(fontFamily: 'Inter', fontSize: 13.5, color: AppColors.muted)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _chip('Leetcode problems on 9th'),
          _chip('Math exam on Friday 10am'),
          _chip('Physics file tomorrow'),
        ]),
      ]),
    );
  }

  Widget _chip(String text) {
    return InkWell(
      onTap: () => widget.onOpenChat(initialText: text),
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(text,
            style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.accentDark)),
      ),
    );
  }

  Widget _upcomingRow(CalendarEvent e) {
    final cat = CategoryStyle.of(e.category);
    return GestureDetector(
      onTap: () => _openEditor(e),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: cat.bg, shape: BoxShape.circle),
            child: Icon(cat.icon, color: cat.fg, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text)),
              Text(DateFormat('EEE, MMM d').format(e.dueDate),
                  style: const TextStyle(
                      fontFamily: 'Inter', fontSize: 12, color: AppColors.muted)),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ]),
      ),
    );
  }

  Widget _captureBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(children: [
          GestureDetector(
            onTap: _showImageSheet,
            child: Container(
              width: 46,
              height: 46,
              decoration:
                  const BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle),
              child: const Icon(Icons.image_outlined, color: AppColors.accentDark, size: 22),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              onTap: () => widget.onOpenChat(),
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Type something…',
                    style: TextStyle(
                        fontFamily: 'Inter', fontSize: 15, color: AppColors.muted)),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => widget.onOpenChat(),
            child: Container(
              width: 46,
              height: 46,
              decoration:
                  const BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: AppColors.accentDark, size: 22),
            ),
          ),
        ]),
      ),
    );
  }
}
