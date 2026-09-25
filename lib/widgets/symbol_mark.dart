import 'package:flutter/material.dart';

enum PreferenceSymbol {
  lotus('Lotus', 'lotus'),
  infinity('Infinity', 'infinity'),
  treeOfLife('Tree of Life', 'tree_of_life'),
  evilEye('Evil Eye', 'evil_eye'),
  manekiNeko('Maneki Neko', 'maneki_neko'),
  beagleDog('Beagle Dog', 'beagle_dog');

  final String label;
  final String storageValue;
  const PreferenceSymbol(this.label, this.storageValue);

  static PreferenceSymbol fromStorage(String value) {
    return PreferenceSymbol.values.firstWhere(
      (item) => item.storageValue == value,
      orElse: () => PreferenceSymbol.lotus,
    );
  }
}

class SymbolMark extends StatelessWidget {
  final PreferenceSymbol symbol;
  final Color color;
  final double size;
  final double strokeWidth;

  const SymbolMark({
    super.key,
    required this.symbol,
    required this.color,
    this.size = 48,
    this.strokeWidth = 2.4,
  });

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _SymbolPainter(symbol, color, strokeWidth),
      ),
    );
  }
}

class _SymbolPainter extends CustomPainter {
  final PreferenceSymbol symbol;
  final Color color;
  final double strokeWidth;

  _SymbolPainter(this.symbol, this.color, this.strokeWidth);

  Paint get _pen => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 64, size.height / 64);
    switch (symbol) {
      case PreferenceSymbol.lotus:
        _lotus(canvas);
        break;
      case PreferenceSymbol.infinity:
        _infinity(canvas);
        break;
      case PreferenceSymbol.treeOfLife:
        _tree(canvas);
        break;
      case PreferenceSymbol.evilEye:
        _evilEye(canvas);
        break;
      case PreferenceSymbol.manekiNeko:
        _manekiNeko(canvas);
        break;
      case PreferenceSymbol.beagleDog:
        _beagle(canvas);
        break;
    }
    canvas.restore();
  }

  void _lotus(Canvas canvas) {
    final pen = _pen;
    canvas.drawPath(Path()
      ..moveTo(32, 7)
      ..cubicTo(17, 23, 20, 36, 32, 46)
      ..cubicTo(44, 36, 47, 23, 32, 7)
      ..close(), pen);
    canvas.drawPath(Path()
      ..moveTo(24, 25)
      ..quadraticBezierTo(16, 18, 9, 19)
      ..cubicTo(8, 37, 17, 47, 32, 49)
      ..cubicTo(47, 47, 56, 37, 55, 19)
      ..quadraticBezierTo(48, 18, 40, 25), pen);
    canvas.drawPath(Path()
      ..moveTo(13, 36)
      ..quadraticBezierTo(7, 33, 3, 35)
      ..quadraticBezierTo(10, 54, 32, 55)
      ..quadraticBezierTo(54, 54, 61, 35)
      ..quadraticBezierTo(57, 33, 51, 36), pen);
  }

  void _infinity(Canvas canvas) {
    final pen = _pen..strokeWidth = strokeWidth * 1.25;
    final path = Path()
      ..moveTo(32, 32)
      ..cubicTo(23, 18, 9, 18, 8, 32)
      ..cubicTo(9, 46, 23, 46, 32, 32)
      ..cubicTo(41, 18, 55, 18, 56, 32)
      ..cubicTo(55, 46, 41, 46, 32, 32);
    canvas.drawPath(path, pen);
  }

  void _tree(Canvas canvas) {
    final pen = _pen;
    canvas.drawCircle(const Offset(32, 31), 22, pen);
    canvas.drawPath(Path()
      ..moveTo(32, 51)
      ..cubicTo(31, 43, 31, 38, 32, 30)
      ..moveTo(32, 36)
      ..cubicTo(25, 32, 22, 27, 20, 21)
      ..moveTo(32, 35)
      ..cubicTo(39, 31, 42, 26, 44, 20)
      ..moveTo(31, 31)
      ..cubicTo(27, 27, 27, 22, 28, 17)
      ..moveTo(33, 31)
      ..cubicTo(37, 27, 37, 22, 36, 17), pen);
    final leaf = Paint()..color = color..style = PaintingStyle.fill;
    for (final p in const [
      Offset(18, 23), Offset(23, 16), Offset(31, 13), Offset(40, 16),
      Offset(46, 23), Offset(19, 31), Offset(45, 31), Offset(25, 26),
      Offset(39, 26), Offset(27, 39), Offset(37, 39)
    ]) {
      canvas.drawOval(Rect.fromCenter(center: p, width: 5.2, height: 3.2), leaf);
    }
  }

  void _evilEye(Canvas canvas) {
    final pen = _pen;
    canvas.drawPath(Path()
      ..moveTo(17, 26)
      ..lineTo(17, 11)
      ..quadraticBezierTo(17, 7, 20, 7)
      ..quadraticBezierTo(23, 7, 23, 11)
      ..lineTo(23, 21)
      ..lineTo(23, 8)
      ..quadraticBezierTo(23, 4, 26, 4)
      ..quadraticBezierTo(29, 4, 29, 8)
      ..lineTo(29, 20)
      ..lineTo(29, 7)
      ..quadraticBezierTo(29, 3, 32, 3)
      ..quadraticBezierTo(35, 3, 35, 7)
      ..lineTo(35, 20)
      ..lineTo(35, 9)
      ..quadraticBezierTo(35, 5, 38, 5)
      ..quadraticBezierTo(41, 5, 41, 9)
      ..lineTo(41, 23)
      ..lineTo(41, 13)
      ..quadraticBezierTo(41, 9, 44, 9)
      ..quadraticBezierTo(47, 9, 47, 13)
      ..lineTo(47, 30)
      ..cubicTo(47, 45, 40, 55, 32, 58)
      ..cubicTo(24, 55, 17, 45, 17, 30)
      ..close(), pen);
    canvas.drawOval(Rect.fromCenter(center: const Offset(32, 36), width: 18, height: 12), pen);
    canvas.drawCircle(const Offset(32, 36), 4.5, pen);
    canvas.drawCircle(const Offset(32, 36), 1.2, Paint()..color = color);
  }

  void _manekiNeko(Canvas canvas) {
    final pen = _pen;
    canvas.drawPath(Path()
      ..moveTo(18, 23)
      ..lineTo(20, 11)
      ..lineTo(27, 17)
      ..quadraticBezierTo(32, 14, 37, 17)
      ..lineTo(44, 11)
      ..lineTo(46, 24)
      ..quadraticBezierTo(47, 38, 39, 43)
      ..quadraticBezierTo(32, 48, 25, 43)
      ..quadraticBezierTo(17, 38, 18, 23)
      ..close(), pen);
    canvas.drawCircle(const Offset(26, 29), 1.4, Paint()..color = color);
    canvas.drawCircle(const Offset(38, 29), 1.4, Paint()..color = color);
    canvas.drawPath(Path()
      ..moveTo(29, 35)
      ..quadraticBezierTo(32, 38, 35, 35), pen);
    canvas.drawPath(Path()
      ..moveTo(24, 45)
      ..quadraticBezierTo(20, 53, 21, 59)
      ..moveTo(40, 45)
      ..quadraticBezierTo(45, 53, 43, 59)
      ..moveTo(21, 58)
      ..lineTo(43, 58), pen);
    canvas.drawPath(Path()
      ..moveTo(43, 42)
      ..quadraticBezierTo(54, 38, 53, 26)
      ..quadraticBezierTo(52, 21, 48, 22)
      ..quadraticBezierTo(44, 23, 46, 28), pen);
    canvas.drawCircle(const Offset(46.5, 27), 2.1, pen);
  }

  void _beagle(Canvas canvas) {
    final pen = _pen;
    canvas.drawPath(Path()
      ..moveTo(19, 22)
      ..quadraticBezierTo(14, 15, 10, 20)
      ..cubicTo(5, 28, 8, 40, 17, 40)
      ..moveTo(45, 22)
      ..quadraticBezierTo(50, 15, 54, 20)
      ..cubicTo(59, 28, 56, 40, 47, 40), pen);
    canvas.drawPath(Path()
      ..moveTo(18, 24)
      ..quadraticBezierTo(20, 12, 32, 12)
      ..quadraticBezierTo(44, 12, 46, 24)
      ..quadraticBezierTo(48, 39, 39, 45)
      ..quadraticBezierTo(32, 50, 25, 45)
      ..quadraticBezierTo(16, 39, 18, 24)
      ..close(), pen);
    canvas.drawCircle(const Offset(26, 30), 1.5, Paint()..color = color);
    canvas.drawCircle(const Offset(38, 30), 1.5, Paint()..color = color);
    canvas.drawOval(Rect.fromCenter(center: const Offset(32, 36), width: 5.5, height: 4), pen);
    canvas.drawPath(Path()
      ..moveTo(32, 38)
      ..lineTo(32, 40)
      ..moveTo(32, 40)
      ..quadraticBezierTo(28, 43, 25, 40)
      ..moveTo(32, 40)
      ..quadraticBezierTo(36, 43, 39, 40), pen);
    canvas.drawPath(Path()
      ..moveTo(24, 46)
      ..quadraticBezierTo(20, 53, 21, 59)
      ..moveTo(40, 46)
      ..quadraticBezierTo(44, 53, 43, 59)
      ..moveTo(21, 58)
      ..lineTo(43, 58), pen);
  }

  @override
  bool shouldRepaint(covariant _SymbolPainter oldDelegate) {
    return oldDelegate.symbol != symbol ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
