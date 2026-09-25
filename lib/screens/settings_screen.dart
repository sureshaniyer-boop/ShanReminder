import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/symbol_mark.dart';

class SettingsScreen extends StatefulWidget {
  final String themeName;
  final PreferenceSymbol preferenceSymbol;
  final String appTitle;
  final List<TaskItem> tasks;
  final ValueChanged<String> onThemeChanged;
  final ValueChanged<PreferenceSymbol> onPreferenceSymbolChanged;
  final ValueChanged<String> onTitleChanged;

  const SettingsScreen({
    super.key,
    required this.themeName,
    required this.preferenceSymbol,
    required this.appTitle,
    required this.tasks,
    required this.onThemeChanged,
    required this.onPreferenceSymbolChanged,
    required this.onTitleChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;

  Future<void> _run(
    Future<void> Function() action, {
    required String success,
    String failurePrefix = 'Action failed',
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$failurePrefix: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changeTitle() async {
    final controller = TextEditingController(text: widget.appTitle);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your app title'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 28,
          decoration: const InputDecoration(
            labelText: 'App title',
            hintText: 'Enter a name',
            helperText:
                'Changes the name inside the app. Your phone icon keeps the ShanReminder name.',
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result == null) return;
    final cleaned = result.trim();
    if (cleaned.isEmpty) return;
    widget.onTitleChanged(cleaned);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Title updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: [
        _heading(
          context,
          'Notifications & Reminders',
          'Keep your reminders on track. Allow notifications to get timely alerts and stay consistent.',
        ),
        const SizedBox(height: 12),
        _actionTile(
          icon: Icons.notifications_active_outlined,
          title: 'Test sound & vibration',
          subtitle: 'Send a test notification now',
          onTap: _busy
              ? null
              : () => _run(
                    NotificationService.instance.testSoundAndVibration,
                    success:
                        'Sound and vibration test sent. Check your phone notification.',
                  ),
        ),
        _actionTile(
          icon: Icons.alarm_add_outlined,
          title: 'Allow reminder permissions',
          subtitle:
              'Request notification and exact alarm permissions for reliable reminders',
          onTap: _busy
              ? null
              : () => _run(
                    NotificationService.instance.requestPermissions,
                    success:
                        'Permission request completed. Check phone settings if alerts remain disabled.',
                  ),
        ),
        _actionTile(
          icon: Icons.settings_outlined,
          title: 'Phone notification settings',
          subtitle: 'Open ShanReminder notification settings on this phone',
          onTap: _busy
              ? null
              : () async {
                  try {
                    final opened = await NotificationService.instance
                        .openNotificationSettings();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          opened
                              ? 'Notification settings opened'
                              : 'Unable to open notification settings on this device.',
                        ),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Unable to open settings: $e')),
                    );
                  }
                },
        ),
        _actionTile(
          icon: Icons.refresh_rounded,
          title: 'Refresh scheduled reminders',
          subtitle: 'Use after allowing notifications and alarms',
          onTap: _busy
              ? null
              : () => _run(
                    () => NotificationService.instance
                        .refreshScheduledReminders(widget.tasks),
                    success: 'Upcoming reminders refreshed',
                    failurePrefix: 'Reminder refresh failed',
                  ),
        ),
        const SizedBox(height: 24),
        _heading(
          context,
          'Appearance',
          'Make ShanReminder feel like yours.',
        ),
        const SizedBox(height: 12),
        _sectionCard(
          context,
          title: 'App title',
          subtitle:
              'Personalize the name shown inside ShanReminder. The launcher icon name remains ShanReminder.',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: primary.withValues(alpha: 0.08),
              child: Icon(Icons.edit_outlined, color: primary),
            ),
            title: Text(
              widget.appTitle,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text('Tap to change'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _changeTitle,
          ),
        ),
        const SizedBox(height: 16),
        _sectionCard(
          context,
          title: 'Theme Color Selection',
          subtitle:
              'Gold remains the accent colour. Choose your main template colour.',
          child: Column(
            children: AppTheme.themeColors.entries.map((entry) {
              final selected = entry.key == widget.themeName;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => widget.onThemeChanged(entry.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? primary.withValues(alpha: 0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? primary : AppTheme.border,
                        width: selected ? 1.4 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: selected ? primary : AppTheme.muted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        CircleAvatar(
                          radius: 19,
                          backgroundColor: entry.value,
                          child: const Icon(
                            Icons.auto_awesome,
                            size: 18,
                            color: AppTheme.gold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        _sectionCard(
          context,
          title: 'Your Preference Symbols',
          subtitle:
              'Choose a symbol that represents you. Your chosen symbol will appear on the app header and hero background.',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth < 350
                  ? (constraints.maxWidth - 10) / 2
                  : (constraints.maxWidth - 20) / 3;

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: PreferenceSymbol.values.map((symbol) {
                  final selected = symbol == widget.preferenceSymbol;
                  return Semantics(
                    selected: selected,
                    button: true,
                    label: '${symbol.label} preference symbol',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: () => widget.onPreferenceSymbolChanged(symbol),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: itemWidth,
                        padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? primary.withValues(alpha: 0.05)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: selected ? primary : AppTheme.border,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              selected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              size: 18,
                              color: selected ? primary : AppTheme.muted,
                            ),
                            const SizedBox(height: 6),
                            SymbolMark(
                              symbol: symbol,
                              color: selected
                                  ? primary
                                  : const Color(0xFF9B7024),
                              size: 44,
                              strokeWidth: 2.1,
                            ),
                            const SizedBox(height: 7),
                            Text(
                              symbol.label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.15,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color:
                                    selected ? primary : AppTheme.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _heading(
    BuildContext context,
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppTheme.muted,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        trailing: _busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              height: 1.35,
              color: AppTheme.muted,
            ),
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}
