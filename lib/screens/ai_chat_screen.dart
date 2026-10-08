import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../models/bot_model.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';
import '../services/calendar_prompt_builder.dart';
import '../services/calendar_repository.dart';
import '../services/calendar_tool_executor.dart';
import '../services/reminder_scheduler.dart';
import '../services/storage_service.dart';
import '../services/tool_call_parser.dart';
import '../theme.dart';
import '../widgets/event_card.dart';
import '../widgets/event_preview_card.dart';
import 'event_edit_screen.dart';

String fmtTime(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

class AiChatScreen extends StatefulWidget {
  final ApiService api;
  final StorageService storage;
  final CalendarRepository repo;
  final ReminderScheduler reminders;
  final CalendarToolExecutor toolExecutor;
  final List<BotModel> bots;
  final BotModel? currentBot;
  final ValueChanged<BotModel> onBotChanged;
  final String? initialText;
  final String? initialImagePath;
  final bool autoSend;

  const AiChatScreen({
    super.key,
    required this.api,
    required this.storage,
    required this.repo,
    required this.reminders,
    required this.toolExecutor,
    required this.bots,
    required this.currentBot,
    required this.onBotChanged,
    this.initialText,
    this.initialImagePath,
    this.autoSend = false,
  });

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _controller = TextEditingController();
  final _picker = ImagePicker();
  final _scrollCtrl = ScrollController();
  final _uuid = const Uuid();

  List<ChatMessage> _messages = [];
  bool _streaming = false;
  bool _wasStopped = false;
  File? _pendingImage;
  String? _lastUserText;
  String? _lastUserImage;

  @override
  void initState() {
    super.initState();
    if (widget.initialText != null) _controller.text = widget.initialText!;
    if (widget.initialImagePath != null) _pendingImage = File(widget.initialImagePath!);
    if (widget.autoSend && (widget.initialText?.isNotEmpty == true || widget.initialImagePath != null)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _send());
    }
  }

  @override
  void didUpdateWidget(AiChatScreen old) {
    super.didUpdateWidget(old);
    if (widget.currentBot?.botId != old.currentBot?.botId && widget.currentBot != null) {
      widget.api.newChat();
      setState(() => _messages = []);
      _toast('Switched to ${widget.currentBot!.name}');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  String _stripToolCalls(String text) {
    final idx = text.indexOf('<tool_call>');
    return idx == -1 ? text : text.substring(0, idx);
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty && _pendingImage == null) return;
    if (widget.currentBot == null || _streaming) return;
    final imagePath = _pendingImage?.path;
    _controller.clear();
    setState(() => _pendingImage = null);
    _runSend(text, imagePath);
  }

  Future<void> _runSend(String text, String? imagePath) async {
    if (widget.currentBot == null || _streaming) return;
    _lastUserText = text;
    _lastUserImage = imagePath;
    final userMsg =
        ChatMessage(id: _uuid.v4(), role: 'user', content: text, imagePath: imagePath);
    final aiMsg = ChatMessage(id: _uuid.v4(), role: 'assistant', content: '');

    setState(() {
      _messages.add(userMsg);
      _messages.add(aiMsg);
      _streaming = true;
      _wasStopped = false;
    });
    _scrollDown();

    final buf = StringBuffer();
    final parser = ToolCallParser();

    try {
      final stream = widget.api.sendMessage(
        message: CalendarPromptBuilder.wrapUserMessage(
          text.isEmpty
              ? 'Extract all deadlines, exams, and schedules from this image.'
              : text,
        ),
        model: widget.currentBot!.model,
        service: widget.currentBot!.service,
        botId: widget.currentBot!.botId,
        isImageBot: widget.currentBot!.isImageBot,
        imageFile: imagePath != null ? File(imagePath) : null,
      );
      await for (final chunk in stream) {
        buf.write(chunk);
        final idx = _messages.length - 1;
        setState(() => _messages[idx] = ChatMessage(
            id: aiMsg.id,
            role: 'assistant',
            content: _stripToolCalls(buf.toString()),
            timestamp: aiMsg.timestamp));
        _scrollDown();
      }
    } catch (e) {
      final idx = _messages.length - 1;
      setState(() => _messages[idx] = ChatMessage(
          id: aiMsg.id,
          role: 'assistant',
          content: '',
          timestamp: aiMsg.timestamp,
          parseError: 'Network error: $e'));
    }

    final fullResponse = buf.toString();
    final parsed = parser.parse(fullResponse);
    final isImage = imagePath != null;
    final defaultReminder = await widget.storage.loadDefaultReminder();
    final execResult = await widget.toolExecutor.execute(
      parsed.calls,
      sourceType: isImage ? 'chat_image' : 'chat_text',
      defaultReminder: defaultReminder,
    );

    var visible = parsed.visibleText;
    final err = parsed.error ?? execResult.error;
    final idx = _messages.length - 1;
    setState(() {
      _messages[idx] = ChatMessage(
        id: aiMsg.id,
        role: 'assistant',
        content: visible,
        timestamp: aiMsg.timestamp,
        savedEvents: execResult.savedEvents.isNotEmpty ? execResult.savedEvents : null,
        pendingBatch: execResult.pendingBatches.isNotEmpty ? execResult.pendingBatches.first : null,
        parseError: err,
      );
      _streaming = false;
    });
    _save();
    _scrollDown();

    if (buf.isEmpty && _wasStopped) {
      final idx2 = _messages.length - 1;
      setState(() => _messages[idx2] = ChatMessage(
          id: aiMsg.id, role: 'assistant', content: 'Stopped', timestamp: aiMsg.timestamp));
      _save();
    }
  }

  void _stop() {
    _wasStopped = true;
    widget.api.stopStreaming();
  }

  void _save() {
    if (widget.api.currentChatId != null) {
      widget.storage.saveMessages(widget.api.currentChatId!, _messages);
    }
  }

  Future<void> _undoEvent(ChatMessage msg, int eventIndex) async {
    final events = List<CalendarEvent>.of(msg.savedEvents ?? []);
    if (eventIndex >= events.length) return;
    final e = events[eventIndex];
    await widget.reminders.cancel(e.id);
    await widget.repo.delete(e.id);
    events.removeAt(eventIndex);
    setState(() {
      final i = _messages.indexOf(msg);
      if (i >= 0) {
        _messages[i] = ChatMessage(
          id: msg.id, role: msg.role, content: msg.content, timestamp: msg.timestamp,
          imagePath: msg.imagePath,
          savedEvents: events.isEmpty ? null : events,
          pendingBatch: msg.pendingBatch, parseError: msg.parseError,
        );
      }
    });
    _toast('Event deleted');
  }

  Future<void> _confirmBatch(ChatMessage msg, List<Map<String, dynamic>> selected) async {
    final defaultReminder = await widget.storage.loadDefaultReminder();
    for (final args in selected) {
      await widget.toolExecutor.confirmBatchEvent(args, defaultReminder: defaultReminder);
    }
    final i = _messages.indexOf(msg);
    if (i >= 0) {
      setState(() => _messages[i] = ChatMessage(
        id: msg.id, role: msg.role, content: msg.content, timestamp: msg.timestamp,
        imagePath: msg.imagePath, parseError: msg.parseError,
      ));
    }
    _toast('${selected.length} event${selected.length == 1 ? '' : 's'} saved');
  }

  void _retry() {
    if (_lastUserText == null && _lastUserImage == null) return;
    setState(() => _messages = _messages
        .where((m) => m.content.isNotEmpty || m.savedEvents != null || m.pendingBatch != null)
        .toList());
    _runSend(_lastUserText ?? '', _lastUserImage);
  }

  Future<void> _selectImage(ImageSource source) async {
    final x = await _picker.pickImage(source: source);
    if (x != null) setState(() => _pendingImage = File(x.path));
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
              _selectImage(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined, color: AppColors.accent),
            title: const Text('Take a photo',
                style: TextStyle(fontFamily: 'Inter', color: AppColors.text)),
            onTap: () {
              Navigator.pop(ctx);
              _selectImage(ImageSource.camera);
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _newChat() {
    widget.api.newChat();
    setState(() => _messages = []);
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 150), curve: Curves.easeOut);
      }
    });
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _toast('Copied');
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
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('AI Assistant'),
            Text(widget.currentBot?.name ?? 'Loading…',
                style: const TextStyle(
                    fontFamily: 'Inter', fontSize: 12, color: AppColors.muted)),
          ]),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_comment_outlined),
              tooltip: 'New chat',
              onPressed: _streaming ? null : _newChat,
            ),
          ],
        ),
        body: Column(children: [
          Expanded(
            child: _messages.isEmpty
                ? _emptyHints()
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final msg = _messages[i];
                      final isUser = msg.role == 'user';
                      return Column(
                        crossAxisAlignment:
                            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          if (msg.imagePath != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.file(File(msg.imagePath!),
                                    width: 180, fit: BoxFit.cover),
                              ),
                            ),
                          if (msg.content.isNotEmpty)
                            GestureDetector(
                              onLongPress: () => _copy(msg.content),
                              child: Container(
                                margin: EdgeInsets.only(
                                    bottom: 6, left: isUser ? 48 : 0, right: isUser ? 0 : 48),
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isUser ? AppColors.accentDark : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(22),
                                    topRight: const Radius.circular(22),
                                    bottomLeft: Radius.circular(isUser ? 22 : 6),
                                    bottomRight: Radius.circular(isUser ? 6 : 22),
                                  ),
                                  boxShadow: AppColors.cardShadow,
                                ),
                                child: isUser
                                    ? Text(msg.content,
                                        style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 15,
                                            height: 1.5,
                                            color: Colors.white))
                                    : MarkdownBody(
                                        data: msg.content,
                                        styleSheet: _mdStyle(),
                                      ),
                              ),
                            ),
                          if (msg.savedEvents != null)
                            ...List.generate(msg.savedEvents!.length, (j) {
                              final e = msg.savedEvents![j];
                              return EventCard(
                                event: e,
                                onUndo: () => _undoEvent(msg, j),
                                onEdit: () async {
                                  await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => EventEditScreen(
                                              event: e,
                                              repo: widget.repo,
                                              reminders: widget.reminders)));
                                },
                              );
                            }),
                          if (msg.pendingBatch != null)
                            EventPreviewCard(
                              events: msg.pendingBatch!,
                              onConfirm: (sel) => _confirmBatch(msg, sel),
                              onCancel: () {
                                final idx = _messages.indexOf(msg);
                                if (idx >= 0) {
                                  setState(() => _messages[idx] = ChatMessage(
                                        id: msg.id,
                                        role: msg.role,
                                        content: msg.content,
                                        timestamp: msg.timestamp,
                                        imagePath: msg.imagePath,
                                        savedEvents: msg.savedEvents,
                                        parseError: msg.parseError,
                                      ));
                                }
                              },
                            ),
                          if (msg.parseError != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8, right: 48),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBE2D9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(children: [
                                Expanded(
                                  child: Text(msg.parseError!,
                                      style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 13,
                                          color: Color(0xFF9A3B22))),
                                ),
                                TextButton(
                                  onPressed: _streaming ? null : _retry,
                                  child: const Text('Retry'),
                                ),
                              ]),
                            ),
                        ],
                      );
                    },
                  ),
          ),
          if (_pendingImage != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppColors.cardShadow,
              ),
              child: Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_pendingImage!,
                      width: 72, height: 72, fit: BoxFit.cover),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: GestureDetector(
                    onTap: () => setState(() => _pendingImage = null),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                          color: AppColors.accentDark, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 13, color: Colors.white),
                    ),
                  ),
                ),
              ]),
            ),
          _inputBar(),
        ]),
      ),
    );
  }

  Widget _emptyHints() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      children: [
        const Text('Tell me what\nyour teacher said.',
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 30,
                height: 1.15,
                letterSpacing: -0.8,
                fontWeight: FontWeight.w800,
                color: AppColors.text)),
        const SizedBox(height: 10),
        const Text(
          'Type it casually — or snap a photo of a timetable. I will turn it into calendar events with reminders.',
          style: TextStyle(fontFamily: 'Inter', fontSize: 14.5, height: 1.6, color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        ...[
          'mam said she is gonna see leetcode problems on 9th',
          'Physics exam on 14 Oct at 10am',
          'Math assignment due Friday',
        ].map((s) => GestureDetector(
              onTap: () {
                _controller.text = s;
                _send();
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Row(children: [
                  Expanded(
                    child: Text('“$s”',
                        style: const TextStyle(
                            fontFamily: 'Inter', fontSize: 14, color: AppColors.text)),
                  ),
                  const Icon(Icons.north_east_rounded, color: AppColors.accent, size: 18),
                ]),
              ),
            )),
      ],
    );
  }

  Widget _inputBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            IconButton(
              onPressed: _streaming ? null : _showImageSheet,
              tooltip: 'Attach image',
              icon: const Icon(Icons.image_outlined, size: 24),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: AppColors.line),
                ),
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 6,
                  cursorColor: AppColors.accent,
                  autofocus: true,
                  style: const TextStyle(
                      fontFamily: 'Inter', fontSize: 15, height: 1.4, color: AppColors.text),
                  textInputAction: TextInputAction.send,
                  onSubmitted: _streaming ? null : (_) => _send(),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Type something…',
                    hintStyle:
                        TextStyle(fontFamily: 'Inter', fontSize: 15, color: AppColors.muted),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: _streaming ? AppColors.line : AppColors.accent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _streaming ? _stop : _send,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    _streaming ? Icons.stop_rounded : Icons.arrow_upward_rounded,
                    size: 24,
                    color: _streaming ? AppColors.text : Colors.white,
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  MarkdownStyleSheet _mdStyle() => MarkdownStyleSheet(
        p: const TextStyle(fontFamily: 'Inter', fontSize: 15, height: 1.55, color: AppColors.text),
        strong: const TextStyle(
            fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 15.5, color: AppColors.text),
        em: const TextStyle(
            fontFamily: 'InstrumentSerif',
            fontStyle: FontStyle.italic,
            fontSize: 17,
            color: AppColors.accent),
        a: const TextStyle(color: AppColors.accent, decoration: TextDecoration.underline),
        code: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 13,
            color: AppColors.accentDark,
            backgroundColor: AppColors.accentSoft),
        codeblockPadding: const EdgeInsets.all(12),
        codeblockDecoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(14),
        ),
        blockquote: const TextStyle(
            fontFamily: 'Inter', fontSize: 14.5, height: 1.55, color: AppColors.muted),
        listBullet: const TextStyle(fontSize: 15, color: AppColors.accent),
        h1: const TextStyle(
            fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text),
        h2: const TextStyle(
            fontFamily: 'Inter', fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.text),
        h3: const TextStyle(
            fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text),
      );
}
