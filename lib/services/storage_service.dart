import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class StorageService {
  static const _tasksKey = 'shan_reminder_tasks';
  static const _themeKey = 'shan_reminder_theme';
  static const _symbolKey = 'shan_reminder_preference_symbol';
  static const _titleKey = 'shan_reminder_title';
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  Future<List<TaskItem>> loadTasks() async {
    final raw = await _prefs.getString(_tasksKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => TaskItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> saveTasks(List<TaskItem> tasks) async {
    await _prefs.setString(
      _tasksKey,
      jsonEncode(tasks.map((e) => e.toJson()).toList()),
    );
  }

  Future<String> loadTheme() async =>
      await _prefs.getString(_themeKey) ?? 'Maroon';

  Future<void> saveTheme(String themeName) async {
    await _prefs.setString(_themeKey, themeName);
  }

  Future<String> loadPreferenceSymbol() async =>
      await _prefs.getString(_symbolKey) ?? 'lotus';

  Future<void> savePreferenceSymbol(String symbolName) async {
    await _prefs.setString(_symbolKey, symbolName);
  }

  Future<String> loadTitle() async =>
      await _prefs.getString(_titleKey) ?? 'ShanReminder';

  Future<void> saveTitle(String title) async {
    final cleaned = title.trim();
    await _prefs.setString(_titleKey, cleaned.isEmpty ? 'ShanReminder' : cleaned);
  }
}

