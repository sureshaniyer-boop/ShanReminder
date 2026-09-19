import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class BrandHeader extends StatelessWidget {
  final String themeName;
  final VoidCallback onSettings;
  const BrandHeader({super.key, required this.themeName, required this.onSettings});

  @override
  Widget build(BuildContext context) {
    final cream = themeName == 'Cream';
    final base = AppTheme.themeColors[themeName] ?? AppTheme.themeColors['Maroon']!;
    final accent = cream ? const Color(0xFF875915) : AppTheme.gold;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: cream ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: cream
                ? [const Color(0xFFFFFCF3), base]
                : [Color.lerp(base, Colors.white, 0.08)!, Color.lerp(base, Colors.black, 0.3)!],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Stack(children: [
            Positioned(right: -15, bottom: 10,
              child: Opacity(opacity: 0.08,
                child: LotusMark(color: accent, size: 125))),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 14, 28),
              child: Column(children: [
                Row(children: [
                  LotusMark(color: accent, size: 48),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ShanReminder', style: TextStyle(
                        color: accent, fontSize: 24, fontWeight: FontWeight.w600,
                        letterSpacing: -0.6)),
                      const SizedBox(height: 5),
                      Text('Plan Today • Achieve Tomorrow',
                        style: TextStyle(color: accent, fontSize: 11, height: 1.4)),
                    ],
                  )),
                  IconButton(
                    tooltip: 'Appearance and settings',
                    onPressed: onSettings,
                    icon: Icon(Icons.settings_outlined, color: accent, size: 22),
                  ),
                ]),
                const SizedBox(height: 19),
                Divider(color: accent.withValues(alpha: 0.3), height: 1),
                const SizedBox(height: 17),
                Text('“A focused mind creates a brighter future.”',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: accent, fontFamily: 'serif',
                    fontStyle: FontStyle.italic, fontSize: 16, height: 1.5)),
                const SizedBox(height: 5),
                Text('— Shri Kashi Sureshan Iyer',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: accent, fontSize: 11, height: 1.5)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Crisp vector branding at every device density; no emoji or font dependency.
class LotusMark extends StatelessWidget {
  final Color color;
  final double size;
  const LotusMark({super.key, required this.color, this.size = 48});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(size: Size.square(size), painter: _LotusPainter(color)),
  );
}

class _LotusPainter extends CustomPainter {
  final Color color;
  _LotusPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 64, size.height / 64);
    final pen = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(Path()
      ..moveTo(32, 7)..cubicTo(17, 23, 20, 36, 32, 46)
      ..cubicTo(44, 36, 47, 23, 32, 7)..close(), pen);
    canvas.drawPath(Path()
      ..moveTo(24, 25)..quadraticBezierTo(16, 18, 9, 19)
      ..cubicTo(8, 37, 17, 47, 32, 49)
      ..cubicTo(47, 47, 56, 37, 55, 19)
      ..quadraticBezierTo(48, 18, 40, 25), pen);
    canvas.drawPath(Path()
      ..moveTo(13, 36)..quadraticBezierTo(7, 33, 3, 35)
      ..quadraticBezierTo(10, 54, 32, 55)
      ..quadraticBezierTo(54, 54, 61, 35)
      ..quadraticBezierTo(57, 33, 51, 36), pen);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LotusPainter oldDelegate) => color != oldDelegate.color;
}
