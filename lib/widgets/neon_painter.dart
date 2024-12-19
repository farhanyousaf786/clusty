import 'package:flutter/material.dart';
import 'dart:math' as math;

class NeonPainter extends CustomPainter {
  final Color color;
  final double progress;

  NeonPainter({
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 10);

    final glowPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    final path = Path();
    path.moveTo(0, size.height * 0.3);

    // Create a wave pattern
    for (var i = 0.0; i <= size.width; i += 30) {
      path.lineTo(
        i,
        size.height * 0.3 +
            math.sin((i / size.width * 4 * math.pi) + (progress * math.pi * 2)) *
                20,
      );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Draw the glow effect
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);

    // Draw circles with glow
    final circlePaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final circleStroke = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (var i = 0; i < 3; i++) {
      final x = size.width * (0.2 + i * 0.3);
      final y = size.height * 0.15;
      final radius = 10.0 + math.sin(progress * math.pi * 2 + i) * 5;

      canvas.drawCircle(Offset(x, y), radius + 10, circlePaint);
      canvas.drawCircle(Offset(x, y), radius, circleStroke);
    }
  }

  @override
  bool shouldRepaint(NeonPainter oldDelegate) =>
      color != oldDelegate.color || progress != oldDelegate.progress;
}
