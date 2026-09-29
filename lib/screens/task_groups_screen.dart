import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../models/task_window.dart';
import '../widgets/task_tile.dart';

class TaskGroupsScreen extends StatefulWidget {
  final List<TaskItem> tasks;
  final Future<void> Function(TaskItem, bool) onToggle;
  final Future<void> Function(TaskItem) onDelete;
  const TaskGroupsScreen({
    super.key,
    required this.tasks,
    required this.onToggle,
    required this.onDelete,
  });
  @override
  State<TaskGroupsScreen> createState() => _TaskGroupsScreenState();
}

class _TaskGroupsScreenState extends State<TaskGroupsScreen>
    with AutomaticKeepAliveClientMixin {
  final Set<String> _expanded = {};
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final windows = taskWindows(DateTime.now());
    final other = widget.tasks
        .where((task) => !windows.any((w) => w.contains(task.dueAt)))
        .toList();
    return ListView(
      key: const PageStorageKey('task-groups'),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      children: [
        Text(
          'Make room for what matters.',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.7),
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.tasks.where((t) => !t.completed).length} pending tasks · Your calendar, organised',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        if (widget.tasks.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No tasks yet. Tap + to create your first reminder.',
              textAlign: TextAlign.center,
            ),
          ),
        for (final window in windows)
          _group(
            window.title,
            '${DateFormat('d MMM y').format(window.start)} – ${DateFormat('d MMM y').format(window.end.subtract(const Duration(days: 1)))}',
            widget.tasks.where((t) => window.contains(t.dueAt)).toList(),
          ),
        if (other.isNotEmpty)
          _group(
            'Other Dates',
            'Past tasks and dates outside the groups above',
            other,
          ),
      ],
    );
  }

  Widget _group(String title, String range, List<TaskItem> tasks) {
    tasks.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    final open = _expanded.contains(title);
    final colors = Theme.of(context).colorScheme;
    void toggle() => setState(() {
      open ? _expanded.remove(title) : _expanded.add(title);
    });
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: toggle,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${tasks.length} tasks · $range',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    key: ValueKey('expand-$title'),
                    tooltip: '${open ? 'Collapse' : 'Expand'} $title',
                    style: IconButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                    ),
                    onPressed: toggle,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        open ? Icons.remove : Icons.add,
                        key: ValueKey(open),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: !open
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                    child: tasks.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(18),
                            child: Text('No tasks scheduled for this period.'),
                          )
                        : Column(
                            children: [
                              for (final task in tasks)
                                TaskTile(
                                  task: task,
                                  onChanged: (value) =>
                                      widget.onToggle(task, value ?? false),
                                  onDelete: () => widget.onDelete(task),
                                ),
                            ],
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
