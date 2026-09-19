import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_header.dart';
import '../widgets/task_tile.dart';
import 'add_task_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<TaskItem> tasks;
  final String themeName;
  final Future<void> Function(TaskItem task) onAdd;
  final Future<void> Function(TaskItem task, bool completed) onToggle;
  final Future<void> Function(TaskItem task) onDelete;
  final ValueChanged<String> onThemeChanged;

  const HomeScreen({
    super.key,
    required this.tasks,
    required this.themeName,
    required this.onAdd,
    required this.onToggle,
    required this.onDelete,
    required this.onThemeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final pages = [_dashboard(), _calendar(), _allTasks(), SettingsScreen(themeName: widget.themeName, onThemeChanged: widget.onThemeChanged)];
    return Scaffold(
      appBar: _index == 0 ? null : AppBar(title: Text(['Home', 'Calendar', 'Tasks', 'Settings'][_index])),
      body: SafeArea(top: _index != 0, bottom: false, child: pages[_index]),
      floatingActionButton: _index == 3 ? null : FloatingActionButton(tooltip: 'Add task', onPressed: _addTask, child: const Icon(Icons.add, size: 30)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (v) => setState(() => _index = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _dashboard() {
    final now = DateTime.now();
    final today = widget.tasks.where((t) => _sameDay(t.dueAt, now)).toList()..sort((a,b)=>a.dueAt.compareTo(b.dueAt));
    final completed = today.where((t) => t.completed).length;
    final overdue = widget.tasks.where((t) => !t.completed && t.dueAt.isBefore(now)).length;
    final primary = Theme.of(context).colorScheme.primary;
    final stats = [
      _stat('Tasks', today.length, primary, primary.withValues(alpha: 0.08)),
      _stat('Completed', completed, const Color(0xFF216347), const Color(0xFFE8F5EC)),
      _stat('Pending', today.length - completed, const Color(0xFF896014), const Color(0xFFFFF4D9)),
      _stat('Overdue', overdue, const Color(0xFFAA3544), const Color(0xFFFCEBEC)),
    ];
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: BrandHeader(
            themeName: widget.themeName,
            onSettings: () => setState(() => _index = 3),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              color: AppTheme.paper,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Today', style: TextStyle(color: AppTheme.muted, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(DateFormat('EEE, d MMMM yyyy').format(now),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    ],
                  )),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'View upcoming tasks',
                    onPressed: () => setState(() => _index = 1),
                    icon: const Icon(Icons.event_available_outlined),
                  ),
                ]),
                const SizedBox(height: 20),
                LayoutBuilder(builder: (context, constraints) {
                  final columns = constraints.maxWidth < 300 ||
                      MediaQuery.textScalerOf(context).scale(12) > 16 ? 2 : 4;
                  return Wrap(
                    spacing: 8, runSpacing: 8,
                    children: stats.map((stat) => SizedBox(
                      width: (constraints.maxWidth - 8 * (columns - 1)) / columns,
                      child: stat,
                    )).toList(),
                  );
                }),
                const SizedBox(height: 26),
                Row(children: [
                  const Expanded(child: Text("Today's Tasks",
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700))),
                  TextButton(
                    onPressed: () => setState(() => _index = 2),
                    child: const Text('View all ›'),
                  ),
                ]),
                const SizedBox(height: 6),
                if (today.isEmpty) _emptyToday()
                else ...today.map((task) => TaskTile(
                  task: task, onChanged: (v) => widget.onToggle(task, v ?? false))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyToday() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppTheme.border),
    ),
    child: Column(children: [
      Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.07),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.event_note_outlined, size: 32,
          color: Theme.of(context).colorScheme.primary),
      ),
      const SizedBox(height: 18),
      const Text('Make room for what matters',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      const Text('Your day is a fresh page. Add a task and let ShanReminder keep you on track.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppTheme.muted, height: 1.5)),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: _addTask,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Add your first task'),
      ),
    ]),
  );

  Widget _stat(String label, int value, Color foreground, Color background) => Container(
    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 4),
    decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(13)),
    child: Column(children: [
      Text('$value', style: TextStyle(color: foreground, fontSize: 27, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text(label, textAlign: TextAlign.center,
        style: TextStyle(color: foreground, fontSize: 11, fontWeight: FontWeight.w500)),
    ]),
  );

  Widget _allTasks() {
    final tasks = [...widget.tasks]..sort((a,b)=>a.dueAt.compareTo(b.dueAt));
    if (tasks.isEmpty) return const Center(child: Text('No tasks yet. Tap + to create your first reminder.'));
    return ListView(padding: const EdgeInsets.all(18), children: tasks.map((t) => TaskTile(task: t, onChanged: (v)=>widget.onToggle(t,v??false), onDelete: ()=>widget.onDelete(t))).toList());
  }

  Widget _calendar() {
    final upcoming = widget.tasks.where((t)=>!t.completed && t.dueAt.isAfter(DateTime.now().subtract(const Duration(minutes: 1)))).toList()..sort((a,b)=>a.dueAt.compareTo(b.dueAt));
    return ListView(padding: const EdgeInsets.all(18), children: [
      Text('Upcoming', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      if (upcoming.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(22), child: Text('Nothing upcoming.')))
      else ...upcoming.map((t)=>TaskTile(task:t,onChanged:(v)=>widget.onToggle(t,v??false))),
    ]);
  }

  Future<void> _addTask() async {
    final task = await Navigator.push<TaskItem>(context, MaterialPageRoute(builder: (_) => const AddTaskScreen()));
    if (task != null) await widget.onAdd(task);
  }
}
