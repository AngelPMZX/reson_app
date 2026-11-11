import 'package:flutter/material.dart';

import 'reson_surfaces.dart';
import 'reson_tokens.dart';

/// A raised surface.
///
/// Replaces the `Container` with a one pixel border that every screen used to
/// build by hand, so panels share one radius, one fill and one shadow.
class ResonPanel extends StatelessWidget {
  const ResonPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(ResonSpace.lg),
    this.raised = false,
    this.tint,
    this.gradient,
    this.clip = false,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Sits above its neighbours rather than resting on the background.
  final bool raised;

  /// Overrides the fill, for a panel that carries its own colour.
  final Color? tint;
  final Gradient? gradient;

  /// Clips the child, for panels holding artwork that runs to the edge.
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(surfaces.panelRadius);
    return AnimatedContainer(
      duration: context.motion.expand,
      curve: context.motion.standard,
      padding: padding,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: gradient != null ? null : (tint ?? scheme.surfaceContainerLow),
        gradient: gradient,
        borderRadius: radius,
        boxShadow: raised ? surfaces.raised : surfaces.resting,
      ),
      child: child,
    );
  }
}

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

/// Entrance for an item in a list.
///
/// Each row arrives just after the one above it, so a screen assembles in
/// reading order instead of flashing in all at once. The delay is folded into
/// a single implicit animation rather than a timer, so it still settles.
class ResonStagger extends StatelessWidget {
  const ResonStagger({
    super.key,
    required this.index,
    required this.child,
    this.step = const Duration(milliseconds: 70),
  });
  final int index;
  final Widget child;
  final Duration step;

  /// Beyond this many rows the wait stops growing, or a long list would take
  /// seconds to finish arriving.
  static const _maxSteps = 6;

  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    if (motion.isStill) return child;
    final delay = step * index.clamp(0, _maxSteps);
    final total = motion.entrance + delay;
    final start = total.inMicroseconds == 0
        ? 0.0
        : delay.inMicroseconds / total.inMicroseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: motion.standard),
      child: child,
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - value)),
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
