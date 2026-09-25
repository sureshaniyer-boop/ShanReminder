import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/symbol_mark.dart';

class SettingsScreen extends StatelessWidget {
  final String themeName;
  final PreferenceSymbol preferenceSymbol;
  final ValueChanged<String> onThemeChanged;
  final ValueChanged<PreferenceSymbol> onPreferenceSymbolChanged;

  const SettingsScreen({
    super.key,
    required this.themeName,
    required this.preferenceSymbol,
    required this.onThemeChanged,
    required this.onPreferenceSymbolChanged,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: [
        Text(
          'Appearance',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Make ShanReminder feel like yours.',
          style: TextStyle(color: AppTheme.muted),
        ),
        const SizedBox(height: 18),
        _sectionCard(
          context,
          title: 'Theme Color Selection',
          subtitle: 'Gold remains the accent colour. Choose your main template colour.',
          child: Column(
            children: AppTheme.themeColors.entries.map((entry) {
              final selected = entry.key == themeName;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onThemeChanged(entry.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: selected ? primary.withValues(alpha: 0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? primary : AppTheme.border,
                        width: selected ? 1.4 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: entry.key,
                          groupValue: themeName,
                          onChanged: (value) {
                            if (value != null) onThemeChanged(value);
                          },
                        ),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w700),
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
          subtitle: 'Choose a symbol that represents you. Your chosen symbol will appear on the app header and hero background.',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth < 350
                  ? (constraints.maxWidth - 10) / 2
                  : (constraints.maxWidth - 20) / 3;

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: PreferenceSymbol.values.map((symbol) {
                  final selected = symbol == preferenceSymbol;
                  return Semantics(
                    selected: selected,
                    button: true,
                    label: '${symbol.label} preference symbol',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: () => onPreferenceSymbolChanged(symbol),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: itemWidth,
                        padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                        decoration: BoxDecoration(
                          color: selected ? primary.withValues(alpha: 0.05) : Colors.white,
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
                              color: selected ? primary : const Color(0xFF9B7024),
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
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                                color: selected ? primary : AppTheme.ink,
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
        const SizedBox(height: 18),
        const Card(
          child: ListTile(
            leading: Icon(Icons.notifications_active_outlined),
            title: Text('Reminder permissions'),
            subtitle: Text(
              'For reliable alerts, allow notifications and exact alarms when Android requests them.',
            ),
          ),
        ),
      ],
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
