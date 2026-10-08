import 'package:flutter/material.dart';
import '../theme.dart';

class EventPreviewCard extends StatefulWidget {
  final List<Map<String, dynamic>> events;
  final Future<void> Function(List<Map<String, dynamic>> selected) onConfirm;
  final VoidCallback onCancel;

  const EventPreviewCard({
    super.key,
    required this.events,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<EventPreviewCard> createState() => _EventPreviewCardState();
}

class _EventPreviewCardState extends State<EventPreviewCard> {
  late final List<bool> _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = List.filled(widget.events.length, true);
  }

  String _label(Map<String, dynamic> e) {
    final date = e['date']?.toString() ?? '';
    final time = e['start_time'];
    final t = (time == null || time.toString() == 'null') ? 'All day' : time.toString();
    return '${e['title'] ?? 'Untitled'} — $date${t == 'All day' ? '' : ', $t'}';
  }

  @override
  Widget build(BuildContext context) {
    final count = _selected.where((s) => s).length;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FOUND ${widget.events.length} POSSIBLE EVENTS',
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent)),
          const SizedBox(height: 6),
          ...List.generate(
              widget.events.length,
              (i) => CheckboxListTile(
                    value: _selected[i],
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.accent,
                    title: Text(_label(widget.events[i]),
                        style: const TextStyle(
                            fontFamily: 'Inter', fontSize: 13.5, color: AppColors.text)),
                    onChanged: (v) => setState(() => _selected[i] = v ?? false),
                  )),
          const SizedBox(height: 8),
          Row(children: [
            TextButton(
              onPressed: () => setState(() {
                final all = _selected.every((s) => s);
                for (var i = 0; i < _selected.length; i++) _selected[i] = !all;
              }),
              child: Text(_selected.every((s) => s) ? 'Deselect all' : 'Select all'),
            ),
            const Spacer(),
            OutlinedButton(onPressed: widget.onCancel, child: const Text('Cancel')),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _saving || count == 0
                  ? null
                  : () async {
                      setState(() => _saving = true);
                      final chosen = <Map<String, dynamic>>[];
                      for (var i = 0; i < widget.events.length; i++) {
                        if (_selected[i]) chosen.add(widget.events[i]);
                      }
                      await widget.onConfirm(chosen);
                      if (mounted) setState(() => _saving = false);
                    },
              child: Text(_saving ? 'Saving…' : 'Confirm $count'),
            ),
          ]),
        ],
      ),
    );
  }
}
