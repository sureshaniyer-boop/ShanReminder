import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatelessWidget {
  final String themeName;
  final String appTitle;
  final Future<void> Function()? onRefreshReminders;
  final ValueChanged<String> onThemeChanged;
  final Future<void> Function(String)? onTitleChanged;
  const SettingsScreen({super.key, required this.themeName,
    required this.onThemeChanged, this.appTitle = 'ShanReminder', this.onTitleChanged, this.onRefreshReminders});

  Future<void> _rename(BuildContext context) async {
    final name = await showDialog<String>(context: context,
      builder: (_) => _TitleDialog(title: appTitle));
    if (name != null && context.mounted) {
      await _run(context, () async { await onTitleChanged?.call(name); }, 'Title updated');
    }
  }

  Future<void> _run(BuildContext context, Future<void> Function() action, String message) async {
    try {
      await action();
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not complete this action. ${e.toString().replaceFirst('Bad state: ', '')}')));
    }
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    Text('Personalise', style: Theme.of(context).textTheme.titleLarge),
    Card(child: ListTile(leading: const Icon(Icons.edit_outlined),
      title: const Text('App title'), subtitle: Text(appTitle),
      trailing: const Icon(Icons.chevron_right), onTap: () => _rename(context))),
    const Text('Changes the name inside the app. Your phone icon keeps the ShanReminder name.'),
    const SizedBox(height: 24),
    Text('Reminders', style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 8),
    const Text('Alerts use your device notification tone and vibration. Allow banners and lock-screen notifications. On phones with a “Silent notification” switch, keep it OFF for ShanReminder if you want sound and vibration.'),
    Card(child: ListTile(leading: const Icon(Icons.notifications_active_outlined),
      title: const Text('Test sound & vibration'),
      subtitle: const Text('Send a test notification now'),
      onTap: () => _run(context, NotificationService.instance.testAlert,
        'Test alert sent. If it was silent, turn OFF Silent notification in phone settings.'))),
    Card(child: ListTile(leading: const Icon(Icons.alarm),
      title: const Text('Allow reminder permissions'),
      onTap: () => _run(context, NotificationService.instance.requestPermissions,
        'Permission request completed. Check phone settings if alerts remain disabled.'))),
    Card(child: ListTile(leading: const Icon(Icons.settings_outlined),
      title: const Text('Phone notification settings'),
      onTap: () => _run(context, NotificationService.instance.openSettings, 'Notification settings opened'))),
    Card(child: ListTile(leading: const Icon(Icons.refresh),
      title: const Text('Refresh scheduled reminders'),
      subtitle: const Text('Use after allowing notifications and alarms'),
      onTap: () => _run(context, () async { await onRefreshReminders?.call(); },
        'Upcoming reminders refreshed'))),
    const SizedBox(height: 24),
    Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 10),
    const Text('Gold remains the accent colour. Choose your main template colour.'),
    const SizedBox(height: 16),
    ...AppTheme.themeColors.entries.map((entry) => Card(child: RadioListTile<String>(
      value: entry.key, groupValue: themeName,
      onChanged: (value) { if (value != null) onThemeChanged(value); },
      title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w700)),
      secondary: CircleAvatar(backgroundColor: entry.value,
        child: const Icon(Icons.auto_awesome, color: AppTheme.gold)),
    ))),
  ]);
}

class _TitleDialog extends StatefulWidget {
  final String title;
  const _TitleDialog({required this.title});
  @override
  State<_TitleDialog> createState() => _TitleDialogState();
}

class _TitleDialogState extends State<_TitleDialog> {
  late final _controller = TextEditingController(text: widget.title);
  final _form = GlobalKey<FormState>();
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Your app title'),
    content: Form(key: _form, child: TextFormField(
      controller: _controller, autofocus: true, maxLength: 40,
      decoration: const InputDecoration(labelText: 'Name', hintText: 'My Daily Planner'),
      validator: (value) => value == null || value.trim().isEmpty ? 'Enter a name' : null)),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: () {
        if (_form.currentState!.validate()) Navigator.pop(context, _controller.text.trim());
      }, child: const Text('Save')),
    ]);
}
