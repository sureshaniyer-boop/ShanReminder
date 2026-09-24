class TaskItem {
  final String id;
  final String title;
  final String description;
  final DateTime dueAt;
  final int reminderMinutesBefore;
  final String repeat;
  final String priority;
  final String category;
  final bool completed;

  const TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.dueAt,
    required this.reminderMinutesBefore,
    required this.repeat,
    required this.priority,
    required this.category,
    required this.completed,
  });

  TaskItem copyWith({
    String? title,
    String? description,
    DateTime? dueAt,
    int? reminderMinutesBefore,
    String? repeat,
    String? priority,
    String? category,
    bool? completed,
  }) => TaskItem(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        dueAt: dueAt ?? this.dueAt,
        reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
        repeat: repeat ?? this.repeat,
        priority: priority ?? this.priority,
        category: category ?? this.category,
        completed: completed ?? this.completed,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'dueAt': dueAt.toIso8601String(),
        'reminderMinutesBefore': reminderMinutesBefore,
        'repeat': repeat,
        'priority': priority,
        'category': category,
        'completed': completed,
      };

  factory TaskItem.fromJson(Map<String, dynamic> json) => TaskItem(
        id: json['id'] as String,
        title: json['title'] as String,
        description: (json['description'] ?? '') as String,
        dueAt: DateTime.parse(json['dueAt'] as String),
        reminderMinutesBefore: (json['reminderMinutesBefore'] ?? 0) as int,
        repeat: (json['repeat'] ?? 'None') as String,
        priority: (json['priority'] ?? 'Medium') as String,
        category: (json['category'] ?? 'Personal') as String,
        completed: (json['completed'] ?? false) as bool,
      );
}
