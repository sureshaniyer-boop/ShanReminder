import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_header.dart';
import '../widgets/task_tile.dart';
import '../widgets/symbol_mark.dart';
import 'add_task_screen.dart';
import 'settings_screen.dart';
import 'task_groups_screen.dart';
import '../backup/backup_panel.dart';

class HomeScreen extends StatefulWidget {
  final List<TaskItem> tasks;
  final Future<void> Function(List<TaskItem>)? onRestore;
  final String themeName;
  final PreferenceSymbol preferenceSymbol;
  final String appTitle;
  final Future<void> Function(TaskItem task) onAdd;
  final Future<void> Function(TaskItem task, bool completed) onToggle;
  final Future<void> Function(TaskItem task) onDelete;
  final ValueChanged<String> onThemeChanged;
  final ValueChanged<PreferenceSymbol> onPreferenceSymbolChanged;
  final ValueChanged<String> onTitleChanged;

  const HomeScreen({
    super.key,
    required this.tasks,
    this.onRestore,
    required this.themeName,
    required this.preferenceSymbol,
    required this.appTitle,
    required this.onAdd,
    required this.onToggle,
    required this.onDelete,
    required this.onThemeChanged,
    required this.onPreferenceSymbolChanged,
    required this.onTitleChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final PageController _pages = PageController();
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    _pages.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _dashboard(),
      _titledPage('Calendar', _calendar()),
      _titledPage('Tasks', _allTasks()),
      _titledPage(
        'Settings',
        SettingsScreen(
          themeName: widget.themeName,
          preferenceSymbol: widget.preferenceSymbol,
          appTitle: widget.appTitle,
          tasks: widget.tasks,
          backupPanel: widget.onRestore == null
              ? null
              : BackupPanel(tasks: widget.tasks, onRestore: widget.onRestore!),
          onThemeChanged: widget.onThemeChanged,
          onPreferenceSymbolChanged: widget.onPreferenceSymbolChanged,
          onTitleChanged: widget.onTitleChanged,
        ),
      ),
    ];
    final todayHasTasks = widget.tasks.any(
      (t) => _sameDay(t.dueAt, DateTime.now()),
    );
    return Scaffold(
      body: PageView(
        key: const ValueKey('main-pages'),
        controller: _pages,
        onPageChanged: (index) => setState(() => _index = index),
        children: pages,
      ),
      floatingActionButton: _index == 3 || (_index == 0 && !todayHasTasks)
          ? null
          : FloatingActionButton(
              tooltip: 'Add task',
              onPressed: _addTask,
              child: const Icon(Icons.add_rounded, size: 28),
            ),
      bottomNavigationBar: _navigation(),
    );
  }

  Widget _titledPage(String title, Widget content) => Column(
    children: [
      AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Container(
          width: double.infinity,
          color: Theme.of(context).colorScheme.primary,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 56,
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.gold,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      Expanded(child: content),
    ],
  );

  Widget _navigation() {
    const labels = ['Home', 'Calendar', 'Tasks', 'Settings'];
    const icons = [
      Icons.home_outlined,
      Icons.calendar_month_outlined,
      Icons.checklist_rounded,
      Icons.settings_outlined,
    ];
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: List.generate(4, (index) {
              final selected = _index == index;
              return Expanded(
                child: Semantics(
                  selected: selected,
                  button: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _goTo(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icons[index],
                            size: 22,
                            color: selected ? primary : AppTheme.muted,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            labels[index],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 10,
                              height: 1.2,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: selected ? primary : AppTheme.muted,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: selected ? primary : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _dashboard() {
    final now = DateTime.now();
    final today = widget.tasks.where((t) => _sameDay(t.dueAt, now)).toList()
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    final completed = today.where((t) => t.completed).length;
    final overdue = widget.tasks
        .where((t) => !t.completed && t.dueAt.isBefore(now))
        .length;
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        BrandHeader(
          themeName: widget.themeName,
          preferenceSymbol: widget.preferenceSymbol,
          appTitle: widget.appTitle,
          onSettings: () => _goTo(3),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Transform.translate(
            offset: const Offset(0, -24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppTheme.border),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.055),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'YOUR DAY AT A GLANCE',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 9,
                                letterSpacing: 1.3,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.muted,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              DateFormat('EEEE, d MMM').format(now),
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 19,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'View upcoming tasks',
                        onPressed: () => _goTo(1),
                        icon: Icon(
                          Icons.calendar_today_outlined,
                          size: 19,
                          color: primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns =
                          constraints.maxWidth < 280 ||
                              MediaQuery.textScalerOf(context).scale(12) > 16
                          ? 2
                          : 4;
                      final stats = [
                        _stat('Tasks', today.length, primary),
                        _stat('Completed', completed, const Color(0xFF397158)),
                        _stat(
                          'Pending',
                          today.length - completed,
                          const Color(0xFF966C22),
                        ),
                        _stat('Overdue', overdue, const Color(0xFFAE5060)),
                      ];
                      return Wrap(
                        spacing: 8,
                        runSpacing: 16,
                        children: stats
                            .map(
                              (stat) => SizedBox(
                                width:
                                    (constraints.maxWidth - 8 * (columns - 1)) /
                                    columns,
                                child: stat,
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: today.isEmpty ? 0 : completed / today.length,
                      minHeight: 4,
                      color: primary,
                      backgroundColor: const Color(0xFFF0EEE8),
                      semanticsLabel: today.isEmpty
                          ? 'No tasks today'
                          : 'Today’s task completion',
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    today.isEmpty
                        ? 'A fresh start, at your own pace.'
                        : '$completed of ${today.length} tasks completed today',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11,
                      color: AppTheme.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            key: const PageStorageKey('today-tasks'),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            children: [
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Today's tasks",
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: AppTheme.ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _goTo(2),
                    child: const Text(
                      'View all  →',
                      style: TextStyle(fontFamily: 'Roboto', fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (today.isEmpty)
                _emptyToday()
              else
                ...today.map(
                  (task) => TaskTile(
                    task: task,
                    onChanged: (v) => widget.onToggle(task, v ?? false),
                  ),
                ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EFE5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.format_quote_rounded,
                      size: 22,
                      color: Color(0xFF977539),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'A focused mind creates a brighter future.',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 13,
                              height: 1.5,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF685637),
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            '— Shri Kashi Sureshan Iyer',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 10,
                              height: 1.4,
                              color: Color(0xFF786747),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyToday() {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 70,
            width: 100,
            child: CustomPaint(painter: _PlannerIllustration(primary)),
          ),
          const SizedBox(height: 13),
          const Text(
            'A little space for possibility.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 17,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Start with one thing that matters today.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              color: AppTheme.muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 19),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _addTask,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'Plan my first task',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, int value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              '$value',
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 25,
                height: 1.2,
                fontWeight: FontWeight.w400,
                color: AppTheme.ink,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),
      Text(
        label,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 10,
          color: AppTheme.muted,
        ),
      ),
    ],
  );

  Widget _allTasks() => TaskGroupsScreen(
    tasks: widget.tasks,
    onToggle: widget.onToggle,
    onDelete: widget.onDelete,
  );

  Widget _calendar() {
    final tasks =
        widget.tasks
            .where((t) => _sameDay(t.dueAt.toLocal(), _selectedDate))
            .toList()
          ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
      children: [
        Card(child: _monthGrid()),
        const SizedBox(height: 20),
        Text(
          DateFormat('EEEE, d MMMM').format(_selectedDate),
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          '${tasks.length} tasks · Tap + to add to this day',
          style: const TextStyle(color: AppTheme.muted),
        ),
        const SizedBox(height: 16),
        if (tasks.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Nothing planned for this day.'),
            ),
          )
        else
          ...tasks.map(
            (t) => TaskTile(
              task: t,
              onChanged: (v) => widget.onToggle(t, v ?? false),
              onDelete: () => widget.onDelete(t),
            ),
          ),
      ],
    );
  }

  Widget _monthGrid() {
    final first = DateTime(_visibleMonth.year, _visibleMonth.month);
    final start = first.weekday - 1; // Monday first.
    final days = DateUtils.getDaysInMonth(first.year, first.month);
    final primary = Theme.of(context).colorScheme.primary;
    final scheduled = widget.tasks
        .map((t) => DateUtils.dateOnly(t.dueAt.toLocal()))
        .toSet();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Previous month',
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(
                  () => _visibleMonth = DateTime(first.year, first.month - 1),
                ),
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(first),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(
                  () => _visibleMonth = DateTime(first.year, first.month + 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          ...List.generate(
            ((start + days) / 7).ceil(),
            (week) => Row(
              children: List.generate(7, (weekday) {
                final day = week * 7 + weekday - start + 1;
                if (day < 1 || day > days)
                  return const Expanded(child: SizedBox(height: 54));
                final date = DateTime(first.year, first.month, day);
                final selected = _sameDay(date, _selectedDate);
                final hasTasks = scheduled.contains(date);
                return Expanded(
                  child: Semantics(
                    label:
                        '${DateFormat('d MMMM yyyy').format(date)}${hasTasks ? ', has tasks' : ''}',
                    button: true,
                    child: InkWell(
                      onTap: () => setState(() => _selectedDate = date),
                      child: SizedBox(
                        height: 54,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected ? primary : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$day',
                                style: TextStyle(
                                  color: selected ? Colors.white : AppTheme.ink,
                                ),
                              ),
                            ),
                            Container(
                              key: ValueKey(
                                'calendar-dot-${date.year}-${date.month}-${date.day}',
                              ),
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: hasTasks ? primary : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addTask() async {
    final task = await Navigator.push<TaskItem>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddTaskScreen(initialDate: _index == 1 ? _selectedDate : null),
      ),
    );
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
      const Rect.fromLTWH(-21, -26, 42, 52),
      const Radius.circular(6),
    );
    canvas.drawRRect(paper, Paint()..color = Colors.white);
    canvas.drawRRect(
      paper,
      Paint()
        ..color = primary.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final line = Paint()
      ..color = primary.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (final y in [-9.0, 2.0, 13.0]) {
      canvas.drawCircle(Offset(-11, y), 2, line);
      canvas.drawLine(Offset(-3, y), Offset(12, y), line);
    }
    canvas.drawLine(const Offset(-9, -29), const Offset(-9, -21), line);
    canvas.drawLine(const Offset(9, -29), const Offset(9, -21), line);
    canvas.restore();
    final gold = Paint()
      ..color = const Color(0xFFB69A59)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(82, 11), const Offset(82, 19), gold);
    canvas.drawLine(const Offset(78, 15), const Offset(86, 15), gold);
    canvas.drawCircle(const Offset(16, 51), 2, gold);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PlannerIllustration oldDelegate) =>
      primary != oldDelegate.primary;
}
