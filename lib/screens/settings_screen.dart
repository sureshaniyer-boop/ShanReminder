import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  final String themeName;
  final ValueChanged<String> onThemeChanged;
  const SettingsScreen({super.key, required this.themeName, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text('Appearance', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text('Gold remains the accent colour. Choose your main template colour.'),
        const SizedBox(height: 16),
        ...AppTheme.themeColors.entries.map((entry) => Card(
          child: RadioListTile<String>(
            value: entry.key,
            groupValue: themeName,
            onChanged: (value) { if (value != null) onThemeChanged(value); },
            title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w700)),
            secondary: CircleAvatar(backgroundColor: entry.value, child: const Icon(Icons.auto_awesome, color: AppTheme.gold)),
          ),
        )),
        const SizedBox(height: 20),
        const Card(child: ListTile(
          leading: Icon(Icons.notifications_active_outlined),
          title: Text('Reminder permissions'),
          subtitle: Text('For reliable alerts, allow notifications and exact alarms when Android requests them.'),
        )),
      ],
    );
  }
}
