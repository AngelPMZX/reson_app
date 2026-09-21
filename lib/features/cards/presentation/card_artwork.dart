import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Vector artwork, independent of content; no image downloads or continuous ticker.
class CardArtwork extends CustomPainter {
  CardArtwork(this.style, this.accent, this.progress);
  final String style;
  final Color accent;
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    if (style == 'aurora') {
      for (var i = 0; i < 8; i++) {
        p.color = accent.withValues(alpha: .12 + i * .014);
        final path = Path()..moveTo(-40, size.height * .2 + i * 18);
        path.cubicTo(
          size.width * .4,
          -50 + progress * 35,
          size.width * .65,
          size.height * .8,
          size.width + 40,
          size.height * .32 + i * 22,
        );
        canvas.drawPath(path, p..strokeWidth = 14 - i.toDouble());
      }
    } else if (style == 'executive') {
      p.color = accent.withValues(alpha: .25);
      for (var i = 0; i < 9; i++) {
        canvas.drawLine(
          Offset(size.width * .58 + i * 18, 0),
          Offset(size.width, 90 + i * 25),
          p,
        );
      }
      canvas.drawRect(
        Rect.fromLTWH(16, 16, size.width - 32, size.height - 32),
        p,
      );
    } else {
      p.color = accent.withValues(alpha: .22);
      for (var i = 0; i < 5; i++) {
        canvas.drawArc(
          Rect.fromCircle(center: Offset(size.width, 20), radius: 45 + i * 22),
          math.pi / 2,
          math.pi,
          false,
          p..strokeWidth = 2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CardArtwork oldDelegate) =>
      oldDelegate.style != style ||
      oldDelegate.accent != accent ||
      oldDelegate.progress != progress;
}
