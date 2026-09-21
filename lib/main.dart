import 'package:flutter/material.dart';
import 'models/task.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

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
  String _appTitle = 'ShanReminder';
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _startup();
  }

  Future<void> _startup() async {
    // Always allow the UI to start. Notification/plugin failures must never
    // prevent ShanReminder from opening.
    try {
      await NotificationService.instance.initialize();
    } catch (e) {
      debugPrint('Notification initialization failed: $e');
    }

    try {
      final tasks = await _storage.loadTasks();
      final theme = await _storage.loadTheme();
      final title = await _storage.loadTitle();
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _themeName = theme;
        _appTitle = title;
        _ready = true;
      });
      // Migrate future alerts to the sound/vibration channel without dropping
      // past recurring schedules that Android is already managing.
      for (final task in tasks) {
        if (!task.completed && task.dueAt.subtract(
            Duration(minutes: task.reminderMinutesBefore)).isAfter(DateTime.now())) {
          try {
            await NotificationService.instance.schedule(task);
          } catch (e) {
            debugPrint('Reminder refresh failed: $e');
          }
        }
      }
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
      _messenger.currentState?.showSnackBar(const SnackBar(
        content: Text('Could not save or schedule this reminder. Check notification permissions in Settings and try again.')));
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

  Future<void> _refreshReminders() async {
    for (final task in _tasks) {
      if (!task.completed && task.dueAt.subtract(
          Duration(minutes: task.reminderMinutesBefore)).isAfter(DateTime.now())) {
        await NotificationService.instance.schedule(task);
      }
    }
  }

  Future<void> _changeTitle(String name) async {
    final title = name.trim();
    if (title.isEmpty || title.length > 40) return;
    await _storage.saveTitle(title);
    if (mounted) setState(() => _appTitle = title);
  }

  void _changeTheme(String name) {
    setState(() => _themeName = name);
    _storage.saveTheme(name).catchError((e) {
      debugPrint('Theme save failed: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: _appTitle,
      scaffoldMessengerKey: _messenger,
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
              appTitle: _appTitle,
              onTitleChanged: _changeTitle,
              onRefreshReminders: _refreshReminders,
              themeName: _themeName,
              onAdd: _add,
              onToggle: _toggle,
              onDelete: _delete,
              onThemeChanged: _changeTheme,
            ),
    );
  }
}
