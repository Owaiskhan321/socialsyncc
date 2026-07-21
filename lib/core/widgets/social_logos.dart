import 'package:flutter/material.dart';

/// Minimal multicolor Google "G" mark for social buttons.
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleGPainter(),
      ),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.42;
    const stroke = 3.2;

    void arc(Color color, double start, double sweep) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        start,
        sweep,
        false,
        paint,
      );
    }

    arc(const Color(0xFF4285F4), -0.4, 1.6);
    arc(const Color(0xFF34A853), 1.2, 1.1);
    arc(const Color(0xFFFBBC05), 2.3, 1.0);
    arc(const Color(0xFFEA4335), 3.3, 1.0);

    final bar = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, cy), Offset(cx + r, cy), bar);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Apple logo for Sign in with Apple button (iOS).
class AppleLogo extends StatelessWidget {
  const AppleLogo({super.key, this.size = 20, this.color = Colors.black});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.apple, size: size, color: color);
  }
}
