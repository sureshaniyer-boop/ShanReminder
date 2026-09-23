import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class BrandHeader extends StatelessWidget {
  final String themeName;
  final String appTitle;
  final bool compact;
  final VoidCallback onSettings;
  const BrandHeader({super.key, required this.themeName, required this.onSettings, this.appTitle = 'ShanReminder', this.compact = false});

  @override
  Widget build(BuildContext context) {
    final cream = themeName == 'Cream';
    final base = AppTheme.themeColors[themeName] ?? AppTheme.themeColors['Maroon']!;
    final gold = cream ? const Color(0xFF785119) : AppTheme.gold;
    final foreground = cream ? const Color(0xFF44341E) : const Color(0xFFFFFBEE);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: cream ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Container(
        decoration: BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: cream ? [const Color(0xFFFBF4E5), base]
            : [base, Color.lerp(base, Colors.black, 0.42)!],
        )),
        child: SafeArea(bottom: false, child: Stack(children: [
          Positioned(right: -20, bottom: 20, child: Opacity(
            opacity: 0.065, child: LotusMark(color: gold, size: 175))),
          Padding(
            padding: EdgeInsets.fromLTRB(24, compact ? 4 : 16, 20, compact ? 24 : 48),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                LotusMark(color: gold, size: 32),
                const SizedBox(width: 10),
                Expanded(child: Text(appTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Roboto',
                  fontSize: 18, fontWeight: FontWeight.w500, color: gold,
                  letterSpacing: -0.3))),
                IconButton(
                  tooltip: 'Appearance and settings', onPressed: onSettings,
                  style: IconButton.styleFrom(
                    side: BorderSide(color: gold.withValues(alpha: 0.22)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  icon: Icon(Icons.tune_rounded, size: 19, color: gold)),
              ]),
              if (!compact) ...[
              const SizedBox(height: 22),
              Text('PLAN TODAY · ACHIEVE TOMORROW', style: TextStyle(fontFamily: 'Roboto',
                fontSize: 9, fontWeight: FontWeight.w500,
                letterSpacing: 1.5, color: gold)),
              const SizedBox(height: 9),
              Text('Make today meaningful.', style: TextStyle(fontFamily: 'Roboto',
                fontSize: 28, height: 1.15, fontWeight: FontWeight.w400,
                letterSpacing: -0.8, color: foreground)),
              const SizedBox(height: 9),
              Text('A little focus. A brighter future.', style: TextStyle(fontFamily: 'Roboto',
                fontSize: 12, height: 1.4, color: foreground.withValues(alpha: 0.78))),
              ],
            ]),
          ),
        ])),
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
