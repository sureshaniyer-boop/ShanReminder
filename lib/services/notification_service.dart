import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'shan_reminders_sound_v3';
  static const _channelName = 'Task reminder alerts';

  Future<void> initialize() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;

    // Time-zone setup is required for scheduled alerts, but it must never
    // prevent immediate test notifications from working.
    try {
      tzdata.initializeTimeZones();
      final local = await FlutterTimezone.getLocalTimezone();
      try {
        tz.setLocalLocation(tz.getLocation(local.identifier));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));
      }
    } catch (_) {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) await initialize();
  }

  NotificationDetails get alertDetails => NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Audible task and event reminder alerts',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 450, 180, 450, 180, 650]),
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.reminder,
        fullScreenIntent: false,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

  Future<void> schedule(TaskItem task) async {
    await _ensureInitialized();

    if (task.completed) {
      await cancel(task.id);
      return;
    }

    final notificationAt = task.dueAt.subtract(
      Duration(minutes: task.reminderMinutesBefore),
    );
    if (notificationAt.isBefore(DateTime.now())) return;

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (await android?.areNotificationsEnabled() != true) {
        throw StateError('Notifications are disabled for ShanReminder');
      }
      if (await android?.canScheduleExactNotifications() != true) {
        throw StateError('Alarm and reminder permission is required');
      }
    }

    final scheduled = tz.TZDateTime.from(notificationAt, tz.local);
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
      notificationDetails: alertDetails,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      matchDateTimeComponents: match,
      payload: task.id,
    );
  }

  Future<void> testAlert() async {
    await _ensureInitialized();

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (await android?.areNotificationsEnabled() != true) {
        throw StateError('Notifications are disabled for ShanReminder');
      }
    }

    await _plugin.show(
      id: 94001,
      title: 'ShanReminder test alert',
      body: 'Sound and vibration are working when you hear and feel this alert.',
      notificationDetails: alertDetails,
    );
  }

  Future<void> requestPermissions() async {
    await _ensureInitialized();
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    } else if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<void> openSettings() async {
    await _ensureInitialized();
    if (Platform.isAndroid) {
      await _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.openAppNotificationSettings();
    }
  }

  Future<void> cancel(String taskId) async {
    await _ensureInitialized();
    await _plugin.cancel(id: _notificationId(taskId));
  }

  int _notificationId(String id) => id.hashCode.abs() % 2147483000;

  String _timeText(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}
