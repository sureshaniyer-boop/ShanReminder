import 'dart:convert';

import '../models/task.dart';

/// Portable format. No credentials or Google tokens are included in a backup.
class BackupData {
  final DateTime createdAt;
  final List<TaskItem> tasks;
  BackupData({required this.createdAt, required this.tasks});
  String encode() => jsonEncode({
    'app': 'ShanReminder',
    'schemaVersion': 1,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'tasks': tasks.map((t) => t.toJson()).toList(),
  });
  static BackupData decode(String text) {
    if (utf8.encode(text).length > 10 * 1024 * 1024) {
      throw const FormatException('Backup exceeds the 10 MB limit.');
    }
    final value = jsonDecode(text);
    if (value is! Map ||
        value['app'] != 'ShanReminder' ||
        value['schemaVersion'] != 1 ||
        value['tasks'] is! List ||
        (value['tasks'] as List).length > 50000) {
      throw const FormatException('Not a supported ShanReminder backup.');
    }
    final seen = <String>{};
    final tasks = (value['tasks'] as List).map((row) {
      final task = TaskItem.fromJson(Map<String, dynamic>.from(row as Map));
      if (task.id.isEmpty ||
          task.title.trim().isEmpty ||
          !seen.add(task.id) ||
          task.reminderMinutesBefore < 0 ||
          task.dueAt.year < 2000 ||
          task.dueAt.year > 2100) {
        throw const FormatException(
          'The backup contains invalid or duplicate tasks.',
        );
      }
      return task;
    }).toList();
    return BackupData(
      createdAt: DateTime.parse(value['createdAt'] as String),
      tasks: tasks,
    );
  }

  /// Keep current edits when the same ID is already present. Restore missing tasks.
  static List<TaskItem> merge(List<TaskItem> current, List<TaskItem> incoming) {
    final byId = {for (final task in incoming) task.id: task};
    for (final task in current) {
      byId[task.id] = task;
    }
    return byId.values.toList()..sort((a, b) => a.dueAt.compareTo(b.dueAt));
  }
}
