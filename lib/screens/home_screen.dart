import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';
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
      appBar: AppBar(title: Text(_index == 0 ? 'ShanReminder' : ['Home', 'Calendar', 'Tasks', 'Settings'][_index])),
      body: pages[_index],
      floatingActionButton: _index == 3 ? null : FloatingActionButton(onPressed: _addTask, child: const Icon(Icons.add)),
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
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Icon(Icons.local_florist, color: AppTheme.gold), SizedBox(width: 8), Text('Plan Today • Achieve Tomorrow', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 16),
            const Text('“A focused mind creates a brighter future.”', style: TextStyle(color: Colors.white, fontSize: 17, fontStyle: FontStyle.italic)),
            const SizedBox(height: 5),
            const Text('— Shri Kashi Sureshan Iyer', style: TextStyle(color: AppTheme.gold)),
          ]),
        ),
        const SizedBox(height: 18),
        Text('Today • ${DateFormat('EEE, d MMMM yyyy').format(now)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(children: [
          _stat('Tasks', today.length, Icons.checklist),
          _stat('Completed', completed, Icons.check_circle_outline),
          _stat('Pending', today.length - completed, Icons.pending_actions),
          _stat('Overdue', overdue, Icons.warning_amber_rounded),
        ]),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("Today's Tasks", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          TextButton(onPressed: () => setState(() => _index = 2), child: const Text('View All')),
        ]),
        if (today.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(22), child: Center(child: Text('No tasks for today. Tap + to add one.'))))
        else
          ...today.map((task) => TaskTile(task: task, onChanged: (v) => widget.onToggle(task, v ?? false))),
      ],
    );
  }

  Widget _stat(String label, int value, IconData icon) => Expanded(
    child: Card(child: Padding(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4), child: Column(children: [Icon(icon, size: 20), const SizedBox(height: 4), Text('$value', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)), Text(label, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center)]))),
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
