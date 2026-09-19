import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';

class TaskTile extends StatelessWidget {
  final TaskItem task;
  final ValueChanged<bool?> onChanged;
  final VoidCallback? onDelete;
  const TaskTile({super.key, required this.task, required this.onChanged, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final categoryColor = switch (task.category) {
      'Work' => const Color(0xFF23568B),
      'Astrology' => const Color(0xFF704797),
      'Personal' => const Color(0xFF276749),
      _ => primary,
    };
    final categoryIcon = switch (task.category) {
      'Work' => Icons.work_outline,
      'Astrology' => Icons.spa_outlined,
      'Personal' => Icons.person_outline,
      _ => Icons.label_outline,
    };
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 12, 12, 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Checkbox(
            semanticLabel: 'Mark ${task.title} as ${task.completed ? "pending" : "completed"}',
            value: task.completed, onChanged: onChanged),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.title, style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: task.completed ? AppTheme.muted : AppTheme.ink,
                decoration: task.completed ? TextDecoration.lineThrough : null)),
              const SizedBox(height: 5),
              Text(DateFormat('EEE, d MMM • h:mm a').format(task.dueAt),
                style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(categoryIcon, size: 13, color: categoryColor),
                      const SizedBox(width: 5),
                      Text(task.category, style: TextStyle(fontSize: 11, color: categoryColor)),
                    ]),
                  ),
                  Text('${task.priority} priority',
                    style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
                ],
              ),
            ],
          )),
          if (onDelete != null) IconButton(
            tooltip: 'Delete task', onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.muted)),
        ]),
      ),
    );
  }
}
