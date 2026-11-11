import '../../../core/theme/reson_palette.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/reson_tokens.dart';

/// Decorative identity cards drawn locally; never implies a real QR or contact.
class HomeIdentityArt extends StatelessWidget {
  const HomeIdentityArt({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: context.motion.showcase,
      curve: context.motion.standard,
      builder: (_, value, child) =>
          CustomPaint(painter: _IdentityPainter(value, compact)),
    ),
  );
}

class _IdentityPainter extends CustomPainter {
  _IdentityPainter(this.progress, this.compact);
  final double progress;
  final bool compact;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2 + (1 - progress) * 20);
    final scale = math.min(size.width / 330, compact ? .66 : size.height / 280);
    canvas.scale(scale);
    final ring = Paint()
      ..color = ResonPalette.brightRed.withValues(alpha: .18)
      ..style = PaintingStyle.stroke;
    for (final radius in [100.0, 135.0, 170.0]) {
      canvas.drawCircle(Offset.zero, radius, ring);
    }
    void card(double angle, Offset offset, Color color, bool front) {
      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.rotate(angle * progress);
      final rect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-104, -65, 208, 130),
        const Radius.circular(18),
      );
      canvas.drawShadow(Path()..addRRect(rect), Colors.black, 12, false);
      canvas.drawRRect(rect, Paint()..color = color);
      canvas.drawRRect(
        rect,
        Paint()
          ..color = Colors.white.withValues(alpha: .25)
          ..style = PaintingStyle.stroke,
      );
      if (front) {
        final ink = Paint()..color = const Color(0xFF542131);
        canvas.drawCircle(const Offset(-70, -30), 15, ink);
        canvas.drawCircle(
          const Offset(-70, -33),
          4,
          Paint()..color = ResonPalette.white,
        );
        canvas.drawArc(
          const Rect.fromLTWH(-78, -28, 16, 12),
          math.pi,
          math.pi,
          false,
          Paint()
            ..color = ResonPalette.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
        for (final row in [(62.0, 4.0), (110.0, 21.0), (78.0, 33.0)]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(-83, row.$2, row.$1, 4),
              const Radius.circular(2),
            ),
            Paint()..color = ResonPalette.grey.withValues(alpha: .7),
          );
        }
        for (var i = 0; i < 5; i++) {
          final h = [8.0, 17.0, 25.0, 13.0, 6.0][i];
          canvas.drawLine(
            Offset(62 + i * 5, -30 - h / 2),
            Offset(62 + i * 5, -30 + h / 2),
            Paint()
              ..color = ResonPalette.grey
              ..strokeWidth = 2
              ..strokeCap = StrokeCap.round,
          );
        }
      }
      canvas.restore();
    }

    card(-.18, const Offset(-20, -22), ResonPalette.wine, false);
    card(.12, const Offset(10, 8), ResonPalette.ivory, true);
    canvas.drawCircle(
      const Offset(121, -85),
      5,
      Paint()..color = ResonPalette.brightRed,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IdentityPainter oldDelegate) =>
      progress != oldDelegate.progress || compact != oldDelegate.compact;
}
