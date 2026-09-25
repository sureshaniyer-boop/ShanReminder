import 'package:flutter/material.dart';
import 'models/task.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'widgets/symbol_mark.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShanReminderApp());
}

class ShanReminderApp extends StatefulWidget {
  const ShanReminderApp({super.key});

  @override
  State<ShanReminderApp> createState() => _ShanReminderAppState();
}

class _ShanReminderAppState extends State<ShanReminderApp> {
  final StorageService _storage = StorageService();
  List<TaskItem> _tasks = [];
  String _themeName = 'Maroon';
  PreferenceSymbol _preferenceSymbol = PreferenceSymbol.lotus;
  String _appTitle = 'ShanReminder';
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _startup();
  }

  Future<void> _startup() async {
    try {
      await NotificationService.instance.initialize();
    } catch (e) {
      debugPrint('Notification initialization failed: $e');
    }

    try {
      final tasks = await _storage.loadTasks();
      final theme = await _storage.loadTheme();
      final symbolValue = await _storage.loadPreferenceSymbol();
      final appTitle = await _storage.loadTitle();
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _themeName = theme;
        _preferenceSymbol = PreferenceSymbol.fromStorage(symbolValue);
        _appTitle = appTitle;
        _ready = true;
      });
    } catch (e) {
      debugPrint('Local storage initialization failed: $e');
      if (!mounted) return;
      setState(() => _ready = true);
    }
  }

  Future<void> _add(TaskItem task) async {
    setState(() => _tasks = [..._tasks, task]);
    try {
      await _storage.saveTasks(_tasks);
      await NotificationService.instance.schedule(task);
    } catch (e) {
      debugPrint('Task save/schedule failed: $e');
    }
  }

  Future<void> _toggle(TaskItem task, bool completed) async {
    final updated = task.copyWith(completed: completed);
    setState(() => _tasks = _tasks.map((t) => t.id == task.id ? updated : t).toList());
    try {
      await _storage.saveTasks(_tasks);
      if (completed) {
        await NotificationService.instance.cancel(task.id);
      } else {
        await NotificationService.instance.schedule(updated);
      }
    } catch (e) {
      debugPrint('Task update failed: $e');
    }
  }

  Future<void> _delete(TaskItem task) async {
    setState(() => _tasks = _tasks.where((t) => t.id != task.id).toList());
    try {
      await _storage.saveTasks(_tasks);
      await NotificationService.instance.cancel(task.id);
    } catch (e) {
      debugPrint('Task delete failed: $e');
    }
  }

  void _changeTheme(String name) {
    setState(() => _themeName = name);
    _storage.saveTheme(name).catchError((e) {
      debugPrint('Theme save failed: $e');
    });
  }

  void _changePreferenceSymbol(PreferenceSymbol symbol) {
    setState(() => _preferenceSymbol = symbol);
    _storage.savePreferenceSymbol(symbol.storageValue).catchError((e) {
      debugPrint('Preference symbol save failed: $e');
    });
  }

  void _changeTitle(String title) {
    final cleaned = title.trim().isEmpty ? 'ShanReminder' : title.trim();
    setState(() => _appTitle = cleaned);
    _storage.saveTitle(cleaned).catchError((e) {
      debugPrint('Title save failed: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ShanReminder',
      theme: AppTheme.build(_themeName),
      home: !_ready
          ? const Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 14),
                    Text('Starting ShanReminder...'),
                  ],
                ),
              ),
            )
          : HomeScreen(
              tasks: _tasks,
              themeName: _themeName,
              preferenceSymbol: _preferenceSymbol,
              appTitle: _appTitle,
              onAdd: _add,
              onToggle: _toggle,
              onDelete: _delete,
              onThemeChanged: _changeTheme,
              onPreferenceSymbolChanged: _changePreferenceSymbol,
              onTitleChanged: _changeTitle,
            ),
    );
  }
}
