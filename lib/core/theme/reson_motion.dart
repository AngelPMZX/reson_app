import 'package:flutter/material.dart';

import 'reson_tokens.dart';

/// One-shot entrance; respects the device's reduced-motion preference.
class ResonReveal extends StatelessWidget {
  const ResonReveal({super.key, required this.child, this.distance = 18});
  final Widget child;
  final double distance;
  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: motion.isStill ? 1 : 0, end: 1),
      duration: motion.entrance,
      curve: motion.standard,
      child: child,
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, distance * (1 - value)),
          child: child,
        ),
      ),
    );
  }
}

/// Tactile feedback for pointer and touch, without an always-running ticker.
///
/// Wrap anything tappable that is bigger than an icon: a pass, a card, a tile.
/// Material's own ink covers small controls well enough.
class ResonPress extends StatefulWidget {
  const ResonPress({super.key, required this.child, this.scale = .975});
  final Widget child;

  /// How far the child shrinks while held.
  final double scale;
  @override
  State<ResonPress> createState() => _ResonPressState();
}

class _ResonPressState extends State<ResonPress> {
  bool pressed = false;
  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    return Listener(
      onPointerDown: (_) => setState(() => pressed = true),
      onPointerUp: (_) => setState(() => pressed = false),
      onPointerCancel: (_) => setState(() => pressed = false),
      child: AnimatedScale(
        scale: pressed ? widget.scale : 1,
        duration: motion.press,
        curve: motion.settle,
        child: widget.child,
      ),
    );
  }
}
