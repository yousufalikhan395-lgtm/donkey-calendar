import 'package:flutter/material.dart';

import '../models/bot_model.dart';
import '../services/calendar_repository.dart';
import '../services/reminder_scheduler.dart';
import '../services/storage_service.dart';
import '../theme.dart';

class SettingsScreen extends StatefulWidget {
  final ReminderScheduler reminders;
  final StorageService storage;
  final CalendarRepository repo;
  final List<BotModel> bots;
  final BotModel? currentBot;
  final ValueChanged<BotModel> onBotChanged;

  const SettingsScreen({
    super.key,
    required this.reminders,
    required this.storage,
    required this.repo,
    required this.bots,
    required this.currentBot,
    required this.onBotChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _defaultReminder = true;

  @override
  void initState() {
    super.initState();
    widget.storage.loadDefaultReminder().then((v) {
      if (mounted) setState(() => _defaultReminder = v);
    });
  }

  void _showModelSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, ctrl) => Column(children: [
          const SizedBox(height: 12),
          Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.line, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          const Text('SELECT AI MODEL',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted)),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: widget.bots.length,
              itemBuilder: (_, i) {
                final b = widget.bots[i];
                final isSel = b.botId == widget.currentBot?.botId;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.accentSoft : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: isSel ? AppColors.accent : AppColors.line),
                    ),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.accent : AppColors.accentSoft,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            b.name.isNotEmpty ? b.name[0].toUpperCase() : '?',
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: isSel ? Colors.white : AppColors.accentDark),
                          ),
                        ),
                      ),
                      title: Text(b.name,
                          style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text)),
                      subtitle: Text('${b.service} / ${b.model}',
                          style: const TextStyle(
                              fontFamily: 'Inter', fontSize: 11.5, color: AppColors.muted)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (b.supportsImage)
                          const Icon(Icons.image_outlined, size: 16, color: AppColors.muted),
                        if (isSel)
                          const Icon(Icons.check_circle, color: AppColors.accent, size: 20),
                      ]),
                      onTap: () {
                        widget.onBotChanged(b);
                        widget.storage.saveBotId(b.botId);
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _clearData() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear all calendar data?'),
        content: const Text('This deletes every event and cancels all reminders.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear all')),
        ],
      ),
    );
    if (ok == true) {
      final events = await widget.repo.getAll();
      for (final e in events) {
        await widget.reminders.cancel(e.id);
      }
      await widget.repo.deleteAll();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Calendar cleared')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Settings')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
          children: [
            _section('AI MODEL'),
            _card(ListTile(
              leading: Container(
                width: 42,
                height: 42,
                decoration:
                    const BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle),
                child: const Icon(Icons.auto_awesome, color: AppColors.accentDark, size: 20),
              ),
              title: Text(widget.currentBot?.name ?? 'No model',
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text)),
              subtitle: Text(widget.currentBot == null
                  ? 'Loading…'
                  : '${widget.currentBot!.service} / ${widget.currentBot!.model}',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.muted)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              onTap: widget.bots.isEmpty ? null : _showModelSheet,
            )),
            _section('REMINDERS'),
            _card(Column(children: [
              SwitchListTile(
                title: const Text('Reminders on by default',
                    style: TextStyle(
                        fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text)),
                subtitle: const Text('Applies to new AI-created events',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.muted)),
                value: _defaultReminder,
                onChanged: (v) {
                  setState(() => _defaultReminder = v);
                  widget.storage.saveDefaultReminder(v);
                },
              ),
              const Divider(height: 1, indent: 20, endIndent: 20),
              ListTile(
                title: const Text('Notification permission',
                    style: TextStyle(
                        fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text)),
                subtitle: const Text('Required for reminders to appear',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.muted)),
                trailing: TextButton(
                  onPressed: () async {
                    final ok = await widget.reminders.requestPermission();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok ? 'Notifications enabled' : 'Permission denied')));
                    }
                  },
                  child: const Text('Check'),
                ),
              ),
            ])),
            _section('DATA & PRIVACY'),
            _card(Column(children: [
              const ListTile(
                title: Text('Privacy',
                    style: TextStyle(
                        fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text)),
                subtitle: Text(
                    'Messages and images are processed by the AI to create events. Your calendar stays on this device.',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12.5, height: 1.5, color: AppColors.muted)),
              ),
              const Divider(height: 1, indent: 20, endIndent: 20),
              ListTile(
                title: const Text('Clear local calendar',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9A3B22))),
                trailing: const Icon(Icons.delete_outline, color: Color(0xFF9A3B22)),
                onTap: _clearData,
              ),
            ])),
            _section('ABOUT'),
            _card(const ListTile(
              title: Text('Donkey Calendar v1.0',
                  style: TextStyle(
                      fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text)),
              subtitle: Text('Your private AI study calendar',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.muted)),
            )),
          ],
        ),
      ),
    );
  }

  Widget _section(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
        child: Text(label, style: eyebrowStyle(context)),
      );

  Widget _card(Widget child) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppColors.cardShadow,
        ),
        child: child,
      );
}
