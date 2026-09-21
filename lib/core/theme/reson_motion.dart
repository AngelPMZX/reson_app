import 'package:flutter/material.dart';

/// One-shot entrance; respects the device's reduced-motion preference.
class ResonReveal extends StatelessWidget {
  const ResonReveal({super.key, required this.child, this.distance = 18});
  final Widget child;
  final double distance;
  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduced ? 1 : 0, end: 1),
      duration: reduced ? Duration.zero : const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
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
class ResonPress extends StatefulWidget {
  const ResonPress({super.key, required this.child});
  final Widget child;
  @override
  State<ResonPress> createState() => _ResonPressState();
}

class _ResonPressState extends State<ResonPress> {
  bool pressed = false;
  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => setState(() => pressed = true),
    onPointerUp: (_) => setState(() => pressed = false),
    onPointerCancel: (_) => setState(() => pressed = false),
    child: AnimatedScale(
      scale: pressed ? .975 : 1,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}
