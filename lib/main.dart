import 'package:flutter/material.dart';
import 'models/task.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
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
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tasks = await _storage.loadTasks();
    final theme = await _storage.loadTheme();
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _themeName = theme;
      _ready = true;
    });
  }

  Future<void> _add(TaskItem task) async {
    setState(() => _tasks = [..._tasks, task]);
    await _storage.saveTasks(_tasks);
    await NotificationService.instance.schedule(task);
  }

  Future<void> _toggle(TaskItem task, bool completed) async {
    final updated = task.copyWith(completed: completed);
    setState(() => _tasks = _tasks.map((t) => t.id == task.id ? updated : t).toList());
    await _storage.saveTasks(_tasks);
    if (completed) {
      await NotificationService.instance.cancel(task.id);
    } else {
      await NotificationService.instance.schedule(updated);
    }
  }

  Future<void> _delete(TaskItem task) async {
    setState(() => _tasks = _tasks.where((t) => t.id != task.id).toList());
    await _storage.saveTasks(_tasks);
    await NotificationService.instance.cancel(task.id);
  }

  void _changeTheme(String name) {
    setState(() => _themeName = name);
    _storage.saveTheme(name);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ShanReminder',
      theme: AppTheme.build(_themeName),
      home: !_ready
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : HomeScreen(
              tasks: _tasks,
              themeName: _themeName,
              onAdd: _add,
              onToggle: _toggle,
              onDelete: _delete,
              onThemeChanged: _changeTheme,
            ),
    );
  }
}
