import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tzdata.initializeTimeZones();
    final local = await FlutterTimezone.getLocalTimezone();
    try {
      tz.setLocalLocation(tz.getLocation(local.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );

    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();
    } else if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<void> schedule(TaskItem task) async {
    await cancel(task.id);
    if (task.completed) return;

    final notificationAt = task.dueAt.subtract(
      Duration(minutes: task.reminderMinutesBefore),
    );
    if (notificationAt.isBefore(DateTime.now())) return;

    final scheduled = tz.TZDateTime.from(notificationAt, tz.local);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'shan_reminders',
        'ShanReminder Alerts',
        channelDescription: 'Task and event reminder alerts',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    DateTimeComponents? match;
    if (task.repeat == 'Daily') match = DateTimeComponents.time;
    if (task.repeat == 'Weekly') match = DateTimeComponents.dayOfWeekAndTime;
    if (task.repeat == 'Monthly') match = DateTimeComponents.dayOfMonthAndTime;

    await _plugin.zonedSchedule(
      id: _notificationId(task.id),
      title: task.title,
      body: task.description.isEmpty
          ? 'Your task is due at ${_timeText(task.dueAt)}.'
          : task.description,
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: match,
      payload: task.id,
    );
  }

  Future<void> cancel(String taskId) => _plugin.cancel(id: _notificationId(taskId));

  int _notificationId(String id) => id.hashCode.abs() % 2147483647;

  String _timeText(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}
