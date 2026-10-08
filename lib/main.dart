import 'package:flutter/material.dart';
import 'db/app_database.dart';
import 'models/bot_model.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'services/api_service.dart';
import 'services/calendar_repository.dart';
import 'services/calendar_tool_executor.dart';
import 'services/reminder_scheduler.dart';
import 'services/storage_service.dart';
import 'theme.dart';

void main() => runApp(const CalendarApp());

class CalendarApp extends StatelessWidget {
  const CalendarApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Donkey Calendar',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const _AppShell(),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell();
  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  final _api = ApiService();
  final _storage = StorageService();
  late final AppDatabase _db = AppDatabase();
  late final CalendarRepository _repo = CalendarRepository(_db);
  late final ReminderScheduler _reminders = ReminderScheduler();
  late final CalendarToolExecutor _executor =
      CalendarToolExecutor(repo: _repo, reminders: _reminders);

  int _tab = 0;
  bool _ready = false;
  String? _error;
  List<BotModel> _bots = [];
  BotModel? _bot;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      await _api.auth();
      final raw = await _api.fetchBots();
      final bots = raw.map((b) => BotModel.fromJson(b)).toList();
      final lastId = await _storage.loadBotId();
      BotModel? sel;
      if (lastId != null) {
        sel = bots.cast<BotModel?>().firstWhere((b) => b!.botId == lastId, orElse: () => null);
      }
      sel ??= bots.isNotEmpty ? bots.first : null;
      try {
        await _reminders.init();
        await _reminders.requestPermission();
        final events = await _repo.getAll();
        await _reminders.rescheduleAll(events);
      } catch (_) {
        // Notification failures must never block app startup.
      }
      if (!mounted) return;
      setState(() {
        _bots = bots;
        _bot = sel;
        _ready = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  void _openChat({String? initialText, String? imagePath}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiChatScreen(
          api: _api,
          storage: _storage,
          repo: _repo,
          reminders: _reminders,
          toolExecutor: _executor,
          bots: _bots,
          currentBot: _bot,
          onBotChanged: _selectBot,
          initialText: initialText,
          initialImagePath: imagePath,
          autoSend: initialText != null,
        ),
      ),
    );
  }

  void _selectBot(BotModel b) {
    _storage.saveBotId(b.botId);
    setState(() => _bot = b);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Could not connect',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
                const SizedBox(height: 8),
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'Inter', color: AppColors.muted)),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    setState(() => _error = null);
                    _boot();
                  },
                  child: const Text('Retry'),
                ),
              ]),
            ),
          ),
        ),
      );
    }

    if (!_ready) return const _BootScreen();

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _tab,
        children: [
          HomeScreen(repo: _repo, reminders: _reminders, onOpenChat: _openChat),
          CalendarScreen(repo: _repo, reminders: _reminders),
          SettingsScreen(
            reminders: _reminders,
            storage: _storage,
            repo: _repo,
            bots: _bots,
            currentBot: _bot,
            onBotChanged: _selectBot,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_today),
              label: 'Calendar'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings'),
        ],
      ),
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: AppColors.cardShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset('assets/donkey.png', fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.pets, color: AppColors.accent, size: 44)),
              ),
            ),
            const SizedBox(height: 18),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 28,
                    letterSpacing: -0.8,
                    color: AppColors.text),
                children: [
                  TextSpan(text: 'Donkey', style: TextStyle(fontWeight: FontWeight.w800)),
                  TextSpan(text: 'Calendar', style: TextStyle(fontWeight: FontWeight.w400)),
                ],
              ),
            ),
            const SizedBox(height: 26),
            const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 2.5)),
          ]),
        ),
      ),
    );
  }
}
