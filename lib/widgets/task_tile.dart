import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class TaskTile extends StatelessWidget {
  final TaskItem task;
  final ValueChanged<bool?> onChanged;
  final VoidCallback? onDelete;

  const TaskTile({super.key, required this.task, required this.onChanged, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Checkbox(value: task.completed, onChanged: onChanged),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            decoration: task.completed ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          '${DateFormat('EEE, d MMM • h:mm a').format(task.dueAt)}\n${task.category} • ${task.priority}',
        ),
        isThreeLine: true,
        trailing: onDelete == null
            ? null
            : IconButton(
                tooltip: 'Delete',
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              ),
      ),
    );
  }
}
