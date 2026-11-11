import 'package:flutter/material.dart';

import 'reson_surfaces.dart';
import 'reson_tokens.dart';

/// A placeholder block that stands in for content still loading.
///
/// A spinner says "something is happening"; a skeleton says what is about to
/// arrive and where, so the page does not jump when it does.
class ResonSkeleton extends StatefulWidget {
  const ResonSkeleton({
    super.key,
    this.width,
    required this.height,
    this.radius = 10,
  });
  final double? width;
  final double height;
  final double radius;

  @override
  State<ResonSkeleton> createState() => _ResonSkeletonState();
}

class _ResonSkeletonState extends State<ResonSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    // Only run the sweep where motion is welcome. A repeating animation also
    // never lets a test settle, so reduced motion gets a still block.
    if (!WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations) {
      _sweep.repeat();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHigh;
    final glint = Color.lerp(base, scheme.onSurface, .07)!;
    final shape = BorderRadius.circular(widget.radius);
    if (context.motion.isStill) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(color: base, borderRadius: shape),
      );
    }
    return AnimatedBuilder(
      animation: _sweep,
      builder: (context, _) {
        final slide = _sweep.value * 2 - 1;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: shape,
            gradient: LinearGradient(
              begin: Alignment(slide - 1, 0),
              end: Alignment(slide + 1, 0),
              colors: [base, glint, base],
              stops: const [.1, .5, .9],
            ),
          ),
        );
      },
    );
  }
}

/// The shape of the wallet while its cards are on their way.
class ResonCardSkeleton extends StatelessWidget {
  const ResonCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final credentials = context.credentials;
    return Semantics(
      label: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResonSkeleton(
            height: credentials.passFace,
            radius: credentials.passRadius,
          ),
          const SizedBox(height: ResonSpace.xl),
          const ResonSkeleton(width: 180, height: 22),
          const SizedBox(height: ResonSpace.md),
          const ResonSkeleton(width: 240, height: 14),
          const SizedBox(height: ResonSpace.sm),
          const ResonSkeleton(width: 200, height: 14),
        ],
      ),
    );
  }
}
