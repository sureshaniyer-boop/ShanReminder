import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'symbol_mark.dart';

class BrandHeader extends StatelessWidget {
  final String themeName;
  final PreferenceSymbol preferenceSymbol;
  final VoidCallback onSettings;

  const BrandHeader({
    super.key,
    required this.themeName,
    required this.preferenceSymbol,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final cream = themeName == 'Cream';
    final base = AppTheme.themeColors[themeName] ?? AppTheme.themeColors['Maroon']!;
    final gold = cream ? const Color(0xFF785119) : AppTheme.gold;
    final foreground = cream ? const Color(0xFF44341E) : const Color(0xFFFFFBEE);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: cream ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: cream
                ? [const Color(0xFFFBF4E5), base]
                : [base, Color.lerp(base, Colors.black, 0.42)!],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Positioned(
                right: -22,
                bottom: 14,
                child: Opacity(
                  opacity: 0.075,
                  child: SymbolMark(
                    symbol: preferenceSymbol,
                    color: gold,
                    size: 180,
                    strokeWidth: 2.0,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 20, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SymbolMark(
                          symbol: preferenceSymbol,
                          color: gold,
                          size: 32,
                          strokeWidth: 2.35,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'ShanReminder',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: gold,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Appearance and settings',
                          onPressed: onSettings,
                          style: IconButton.styleFrom(
                            side: BorderSide(color: gold.withValues(alpha: 0.22)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: Icon(Icons.tune_rounded, size: 19, color: gold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'PLAN TODAY · ACHIEVE TOMORROW',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.5,
                        color: gold,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      'Make today meaningful.',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 28,
                        height: 1.15,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.8,
                        color: foreground,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      'A little focus. A brighter future.',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        height: 1.4,
                        color: foreground.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
