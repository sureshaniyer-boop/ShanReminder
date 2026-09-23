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
  final String appTitle;
  final Future<void> Function()? onRefreshReminders;
  final Future<void> Function(String)? onTitleChanged;
  final Future<void> Function(TaskItem task) onAdd;
  final Future<void> Function(TaskItem task, bool completed) onToggle;
  final Future<void> Function(TaskItem task) onUpdate;
  final Future<void> Function(TaskItem task) onDelete;
  final ValueChanged<String> onThemeChanged;

  const HomeScreen({
    super.key,
    this.appTitle = 'ShanReminder',
    this.onRefreshReminders,
    this.onTitleChanged,
    required this.tasks,
    required this.themeName,
    required this.onAdd,
    required this.onToggle,
    required this.onUpdate,
    required this.onDelete,
    required this.onThemeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  DateTime _selectedCalendarDay = DateTime.now();
  DateTime _visibleCalendarMonth = DateTime(DateTime.now().year, DateTime.now().month);

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final pages = [_dashboard(), _calendar(), _allTasks(),
      SettingsScreen(themeName: widget.themeName, onThemeChanged: widget.onThemeChanged,
        appTitle: widget.appTitle, onTitleChanged: widget.onTitleChanged,
        onRefreshReminders: widget.onRefreshReminders)];
    final todayHasTasks = widget.tasks.any((t) => _sameDay(t.dueAt, DateTime.now()));
    return Scaffold(
      appBar: _index == 0 ? null : AppBar(
        title: Text(['Home', 'Calendar', 'Tasks', 'Settings'][_index])),
      body: SafeArea(top: _index != 0, bottom: false, child: pages[_index]),
      floatingActionButton: _index == 3 || (_index == 0 && !todayHasTasks)
        ? null : FloatingActionButton(
          tooltip: 'Add task', onPressed: _addTask,
          child: const Icon(Icons.add_rounded, size: 28)),
      bottomNavigationBar: _navigation(),
    );
  }

  Widget _navigation() {
    const labels = ['Home', 'Calendar', 'Tasks', 'Settings'];
    const icons = [Icons.home_outlined, Icons.calendar_month_outlined,
      Icons.checklist_rounded, Icons.settings_outlined];
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: const BoxDecoration(color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border))),
      child: SafeArea(top: false, child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: List.generate(4, (index) {
          final selected = _index == index;
          return Expanded(child: Semantics(
            selected: selected, button: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _index = index),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(icons[index], size: 22,
                    color: selected ? primary : AppTheme.muted),
                  const SizedBox(height: 5),
                  Text(labels[index], textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Roboto', fontSize: 10, height: 1.2,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? primary : AppTheme.muted)),
                  const SizedBox(height: 5),
                  Container(width: 4, height: 4, decoration: BoxDecoration(
                    color: selected ? primary : Colors.transparent,
                    shape: BoxShape.circle)),
                ]),
              ),
            ),
          ));
        })),
      )),
    );
  }

  Widget _dashboard() {
    final now = DateTime.now();
    final today = widget.tasks.where((t) => _sameDay(t.dueAt, now)).toList()
      ..sort((a,b) => a.dueAt.compareTo(b.dueAt));
    final completed = today.where((t) => t.completed).length;
    final overdue = widget.tasks.where((t) => !t.completed && t.dueAt.isBefore(now)).length;
    final primary = Theme.of(context).colorScheme.primary;
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxHeight < 650 ||
          MediaQuery.textScalerOf(context).scale(12) > 16;
      return Column(children: [
        // This region is outside the task list's scroll viewport.
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: constraints.maxHeight * 0.62),
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(children: [
              BrandHeader(themeName: widget.themeName, appTitle: widget.appTitle,
                compact: compact, onSettings: () => setState(() => _index = 3)),
              Transform.translate(offset: const Offset(0, -16),
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: compact ? _compactSummary(today.length, completed, overdue, now) :
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppTheme.border),
                boxShadow: [BoxShadow(
                  color: primary.withValues(alpha: 0.055),
                  blurRadius: 24, offset: const Offset(0, 8))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('YOUR DAY AT A GLANCE', style: TextStyle(fontFamily: 'Roboto',
                      fontSize: 9, letterSpacing: 1.3,
                      fontWeight: FontWeight.w500, color: AppTheme.muted)),
                    const SizedBox(height: 7),
                    Text(DateFormat('EEEE, d MMM').format(now),
                      style: const TextStyle(fontFamily: 'Roboto', fontSize: 19, fontWeight: FontWeight.w500,
                        letterSpacing: -0.5)),
                  ])),
                  IconButton(
                    tooltip: 'View upcoming tasks',
                    onPressed: () => setState(() => _index = 1),
                    icon: Icon(Icons.calendar_today_outlined, size: 19, color: primary)),
                ]),
                const SizedBox(height: 16),
                LayoutBuilder(builder: (context, constraints) {
                  final columns = constraints.maxWidth < 280 ||
                    MediaQuery.textScalerOf(context).scale(12) > 16 ? 2 : 4;
                  final stats = [
                    _stat('Tasks', today.length, primary),
                    _stat('Completed', completed, const Color(0xFF397158)),
                    _stat('Pending', today.length - completed, const Color(0xFF966C22)),
                    _stat('Overdue', overdue, const Color(0xFFAE5060)),
                  ];
                  return Wrap(spacing: 8, runSpacing: 16,
                    children: stats.map((stat) => SizedBox(
                      width: (constraints.maxWidth - 8 * (columns - 1)) / columns,
                      child: stat)).toList());
                }),
                const SizedBox(height: 18),
                ClipRRect(borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: today.isEmpty ? 0 : completed / today.length,
                    minHeight: 4, color: primary,
                    backgroundColor: const Color(0xFFF0EEE8),
                    semanticsLabel: today.isEmpty ? 'No tasks today' : 'Today’s task completion')),
                const SizedBox(height: 9),
                Text(today.isEmpty ? 'A fresh start, at your own pace.'
                    : '$completed of ${today.length} tasks completed today',
                  style: const TextStyle(fontFamily: 'Roboto', fontSize: 11, color: AppTheme.muted)),
              ]),
            )
                )),
            ]),
          ),
        ),
        Expanded(child: ListView(
          key: const ValueKey('today-task-list'),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 90),
          children: [
            Row(children: [
              const Expanded(child: Text("Today's tasks",
                style: TextStyle(fontFamily: 'Roboto', color: AppTheme.ink, fontSize: 19, fontWeight: FontWeight.w500,
                  letterSpacing: -0.4))),
              TextButton(onPressed: () => setState(() => _index = 2),
                child: const Text('View all  →', style: TextStyle(fontFamily: 'Roboto', fontSize: 12))),
            ]),
            const SizedBox(height: 8),
            if (today.isEmpty) _emptyToday()
            else ...today.map((task) => TaskTile(
              task: task, onChanged: (v) => widget.onToggle(task, v ?? false))),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EFE5),
                borderRadius: BorderRadius.circular(16)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.format_quote_rounded, size: 22, color: Color(0xFF977539)),
                const SizedBox(width: 10),
                const Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('A focused mind creates a brighter future.',
                      style: TextStyle(fontFamily: 'Roboto', fontSize: 13, height: 1.5,
                        fontStyle: FontStyle.italic, color: Color(0xFF685637))),
                    SizedBox(height: 6),
                    Text('— Shri Kashi Sureshan Iyer',
                      style: TextStyle(fontFamily: 'Roboto', fontSize: 10, height: 1.4, color: Color(0xFF786747))),
                  ])),
              ]),
            ),

          ],
        )),
      ]);
    });
  }

  Widget _compactSummary(int total, int completed, int overdue, DateTime now) {
    return Card(child: Padding(padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(DateFormat('EEEE, d MMM').format(now),
          style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('$total tasks · $completed completed · ${total - completed} pending · $overdue overdue',
          style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
      ])));
  }

  Widget _emptyToday() {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border)),
      child: Column(children: [
        SizedBox(height: 70, width: 100,
          child: CustomPaint(painter: _PlannerIllustration(primary))),
        const SizedBox(height: 13),
        const Text('A little space for possibility.',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Roboto', fontSize: 17, fontWeight: FontWeight.w500, letterSpacing: -0.3)),
        const SizedBox(height: 7),
        const Text('Start with one thing that matters today.',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Roboto', fontSize: 12, color: AppTheme.muted, height: 1.5)),
        const SizedBox(height: 19),
        SizedBox(width: double.infinity, child: FilledButton.icon(
          onPressed: _addTask,
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Plan my first task',
            style: TextStyle(fontFamily: 'Roboto', fontSize: 13, fontWeight: FontWeight.w500)))),
      ]),
    );
  }

  Widget _stat(String label, int value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Container(width: 5, height: 5, decoration: BoxDecoration(
          color: color, shape: BoxShape.circle)),
        const SizedBox(width: 7),
        Flexible(child: Text('$value', style: const TextStyle(fontFamily: 'Roboto',
          fontSize: 25, height: 1.2, fontWeight: FontWeight.w400, color: AppTheme.ink))),
      ]),
      const SizedBox(height: 5),
      Text(label, style: const TextStyle(fontFamily: 'Roboto', fontSize: 10, color: AppTheme.muted)),
    ],
  );

  Widget _allTasks() {
    final tasks = [...widget.tasks]..sort((a,b)=>a.dueAt.compareTo(b.dueAt));
    if (tasks.isEmpty) return const Center(child: Text('No tasks yet. Tap + to create your first reminder.'));
    return ListView(padding: const EdgeInsets.all(18), children: tasks.map((t) => TaskTile(task: t, onChanged: (v)=>widget.onToggle(t,v??false), onDelete: ()=>widget.onDelete(t))).toList());
  }

  Widget _calendar() {
    final primary = Theme.of(context).colorScheme.primary;
    final selectedTasks = widget.tasks
        .where((t) => _sameDay(t.dueAt, _selectedCalendarDay))
        .toList()
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.border),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.06),
                blurRadius: 26,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(children: [
            Row(children: [
              IconButton(
                tooltip: 'Previous month',
                onPressed: () => _changeCalendarMonth(-1),
                icon: const Icon(Icons.chevron_left_rounded)),
              Expanded(
                child: Column(children: [
                  Text(
                    DateFormat('MMMM').format(_visibleCalendarMonth),
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5)),
                  Text(
                    DateFormat('yyyy').format(_visibleCalendarMonth),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.muted,
                      fontWeight: FontWeight.w500)),
                ]),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: () => _changeCalendarMonth(1),
                icon: const Icon(Icons.chevron_right_rounded)),
            ]),
            const SizedBox(height: 12),
            const Row(
              children: [
                _Weekday('M'), _Weekday('T'), _Weekday('W'),
                _Weekday('T'), _Weekday('F'), _Weekday('S'), _Weekday('S'),
              ],
            ),
            const SizedBox(height: 8),
            _calendarGrid(primary),
          ]),
        ),
        const SizedBox(height: 24),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          const Expanded(
            child: Text(
              'Task of the Day',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4))),
          Text(
            DateFormat('d MMM').format(_selectedCalendarDay),
            style: TextStyle(
              fontSize: 12,
              color: primary,
              fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 12),
        if (selectedTasks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.border)),
            child: Column(children: [
              Icon(Icons.event_available_outlined, size: 30, color: primary),
              const SizedBox(height: 10),
              const Text('No task scheduled for this day.',
                style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('Tap + to add a task for the selected date.',
                style: TextStyle(fontSize: 12, color: AppTheme.muted)),
            ]),
          )
        else
          ...selectedTasks.map((task) => _calendarTaskCard(task, primary)),
      ],
    );
  }

  Widget _calendarGrid(Color primary) {
    final first = DateTime(_visibleCalendarMonth.year, _visibleCalendarMonth.month, 1);
    final daysInMonth = DateTime(_visibleCalendarMonth.year, _visibleCalendarMonth.month + 1, 0).day;
    final leading = first.weekday - 1;
    final totalCells = ((leading + daysInMonth + 6) ~/ 7) * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalCells,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 4,
        childAspectRatio: 0.82),
      itemBuilder: (context, index) {
        final dayNumber = index - leading + 1;
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox.shrink();
        }

        final day = DateTime(_visibleCalendarMonth.year, _visibleCalendarMonth.month, dayNumber);
        final selected = _sameDay(day, _selectedCalendarDay);
        final today = _sameDay(day, DateTime.now());
        final tasks = widget.tasks.where((t) => _sameDay(t.dueAt, day)).toList();
        final hasPending = tasks.any((t) => !t.completed);
        final hasCompleted = tasks.any((t) => t.completed);

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _selectedCalendarDay = day),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              color: selected ? primary : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: today && !selected
                  ? Border.all(color: primary.withValues(alpha: 0.55))
                  : null),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('$dayNumber',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected || today ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.white : AppTheme.ink)),
              const SizedBox(height: 5),
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (hasPending)
                  Container(
                    width: 5, height: 5,
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : primary,
                      shape: BoxShape.circle)),
                if (hasPending && hasCompleted) const SizedBox(width: 3),
                if (hasCompleted)
                  Container(
                    width: 5, height: 5,
                    decoration: BoxDecoration(
                      color: selected ? Colors.white70 : const Color(0xFF4F8B6F),
                      shape: BoxShape.circle)),
              ]),
            ]),
          ),
        );
      },
    );
  }

  Widget _calendarTaskCard(TaskItem task, Color primary) {
    final priorityColor = switch (task.priority) {
      'High' => const Color(0xFFB42318),
      'Medium' => const Color(0xFF946200),
      'Low' => const Color(0xFF187442),
      _ => AppTheme.muted,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border)),
      child: Row(children: [
        Container(
          width: 4,
          height: 50,
          decoration: BoxDecoration(
            color: priorityColor,
            borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                decoration: task.completed ? TextDecoration.lineThrough : null,
                color: task.completed ? AppTheme.muted : AppTheme.ink)),
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.schedule_rounded, size: 15, color: primary),
              const SizedBox(width: 5),
              Text(DateFormat('h:mm a').format(task.dueAt),
                style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
              const SizedBox(width: 10),
              Flexible(child: Text(task.category,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppTheme.muted))),
            ]),
          ],
        )),
        IconButton(
          tooltip: 'Edit task',
          onPressed: () => _editTask(task),
          icon: Icon(Icons.edit_outlined, size: 20, color: primary)),
        IconButton(
          tooltip: 'Delete task',
          onPressed: () => _confirmDelete(task),
          icon: const Icon(Icons.delete_outline_rounded,
            size: 20, color: Color(0xFFB42318))),
      ]),
    );
  }

  void _changeCalendarMonth(int delta) {
    final next = DateTime(
      _visibleCalendarMonth.year,
      _visibleCalendarMonth.month + delta,
    );
    setState(() {
      _visibleCalendarMonth = next;
      _selectedCalendarDay = DateTime(next.year, next.month, 1);
    });
  }

  Future<void> _editTask(TaskItem task) async {
    final updated = await Navigator.push<TaskItem>(
      context,
      MaterialPageRoute(builder: (_) => AddTaskScreen(existingTask: task)),
    );
    if (updated != null) await widget.onUpdate(updated);
  }

  Future<void> _confirmDelete(TaskItem task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Delete “${task.title}”? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) await widget.onDelete(task);
  }

  Future<void> _addTask() async {
    final task = await Navigator.push<TaskItem>(context, MaterialPageRoute(builder: (_) => const AddTaskScreen()));
    if (task != null) await widget.onAdd(task);
  }
}

class _PlannerIllustration extends CustomPainter {
  final Color primary;
  _PlannerIllustration(this.primary);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 70);
    final fill = Paint()..color = primary.withValues(alpha: 0.055);
    canvas.drawCircle(const Offset(50, 35), 33, fill);
    canvas.save();
    canvas.translate(50, 35);
    canvas.rotate(-0.10);
    final paper = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-21, -26, 42, 52), const Radius.circular(6));
    canvas.drawRRect(paper, Paint()..color = Colors.white);
    canvas.drawRRect(paper, Paint()..color = primary.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke..strokeWidth = 1.2);
    final line = Paint()..color = primary.withValues(alpha: 0.4)
      ..strokeWidth = 1.5..strokeCap = StrokeCap.round;
    for (final y in [-9.0, 2.0, 13.0]) {
      canvas.drawCircle(Offset(-11, y), 2, line);
      canvas.drawLine(Offset(-3, y), Offset(12, y), line);
    }
    canvas.drawLine(const Offset(-9,-29), const Offset(-9,-21), line);
    canvas.drawLine(const Offset(9,-29), const Offset(9,-21), line);
    canvas.restore();
    final gold = Paint()..color = const Color(0xFFB69A59)..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(82,11), const Offset(82,19), gold);
    canvas.drawLine(const Offset(78,15), const Offset(86,15), gold);
    canvas.drawCircle(const Offset(16,51), 2, gold);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PlannerIllustration oldDelegate) => primary != oldDelegate.primary;
}

class _Weekday extends StatelessWidget {
  final String label;
  const _Weekday(this.label);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Center(
      child: Text(label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.muted))));
}
