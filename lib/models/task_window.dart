class TaskWindow {
  final String title;
  final DateTime start;
  final DateTime end;
  const TaskWindow(this.title, this.start, this.end);
  bool contains(DateTime value) {
    final date = value.toLocal();
    return !date.isBefore(start) && date.isBefore(end);
  }
}

List<TaskWindow> taskWindows(DateTime now) {
  final day = DateTime(now.year, now.month, now.day);
  final nextMonday = DateTime(day.year, day.month, day.day + 8 - day.weekday);
  return [
    TaskWindow('Today', day, DateTime(day.year, day.month, day.day + 1)),
    TaskWindow(
      'Tomorrow',
      DateTime(day.year, day.month, day.day + 1),
      DateTime(day.year, day.month, day.day + 2),
    ),
    TaskWindow(
      'Next Week',
      nextMonday,
      DateTime(nextMonday.year, nextMonday.month, nextMonday.day + 7),
    ),
    TaskWindow(
      'Next Month',
      DateTime(day.year, day.month + 1),
      DateTime(day.year, day.month + 2),
    ),
    TaskWindow('Next Year', DateTime(day.year + 1), DateTime(day.year + 2)),
  ];
}
