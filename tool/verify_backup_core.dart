import '../lib/backup/backup_data.dart';
import '../lib/models/task.dart';
import '../lib/models/task_window.dart';

TaskItem task(String id, String title) => TaskItem(
  id: id,
  title: title,
  description: 'notes',
  dueAt: DateTime(2026, 10, 2, 15, 30),
  reminderMinutesBefore: 30,
  repeat: 'Weekly',
  priority: 'High',
  category: 'Astrology',
  completed: false,
);
void check(bool test, String message) {
  if (!test) throw StateError(message);
}

void main() {
  final original = task('1', 'Current');
  final data = BackupData(createdAt: DateTime(2026, 9, 29), tasks: [original]);
  final decoded = BackupData.decode(data.encode()).tasks.single;
  check(
    decoded.toJson().toString() == original.toJson().toString(),
    'roundtrip',
  );
  final merged = BackupData.merge(
    [original],
    [task('1', 'Old'), task('2', 'New')],
  );
  check(
    merged.length == 2 &&
        merged.firstWhere((t) => t.id == '1').title == 'Current',
    'merge',
  );
  for (final bad in [
    '{}',
    '{',
    BackupData(createdAt: DateTime.now(), tasks: [original, original]).encode(),
  ]) {
    var rejected = false;
    try {
      BackupData.decode(bad);
    } catch (_) {
      rejected = true;
    }
    check(rejected, 'reject bad backup');
  }
  final groups = taskWindows(DateTime(2026, 12, 31, 23, 59));
  check(!groups[0].contains(DateTime(2027)), 'exclusive today boundary');
  check(groups[1].contains(DateTime(2027)), 'tomorrow rollover');
  check(groups[2].start == DateTime(2027, 1, 4), 'next monday');
  check(!groups[2].contains(DateTime(2027, 1, 11)), 'exclusive week end');
  check(
    groups[3].start == DateTime(2027) && groups[4].end == DateTime(2028),
    'month year rollover',
  );
  check(
    taskWindows(DateTime(2028, 2, 28))[1].contains(DateTime(2028, 2, 29)),
    'leap day',
  );
  check(
    taskWindows(DateTime(2026, 9, 28))[2].start == DateTime(2026, 10, 5),
    'Monday means next week',
  );
  print('PASS: 12 backup and calendar boundary checks');
}
