import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../../core/theme/reson_motion.dart';
import '../../../core/theme/reson_palette.dart';
import '../../../core/theme/reson_tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/digital_card.dart';
import 'card_preview.dart' show cardColor;

/// Deck of overlapping passes. A single fractional [_position] drives every
/// visual property, so a drag tracks the finger and releasing settles on a
/// spring instead of jumping between whole slots.
class AnimatedWallet extends StatefulWidget {
  const AnimatedWallet({
    super.key,
    required this.cards,
    required this.children,
  });
  final List<DigitalCard> cards;
  final List<Widget> children;
  @override
  State<AnimatedWallet> createState() => _AnimatedWalletState();
}

class _AnimatedWalletState extends State<AnimatedWallet>
    with SingleTickerProviderStateMixin {
  /// Passes drawn when settled; a fourth one enters from the back on a drag.
  static const _depth = 3;

  /// Share of the deck width that advances exactly one pass.
  static const _dragReach = .55;

  /// Normalised units per second that count as a fling instead of a nudge.
  static const _flingVelocity = 1.2;

  /// Built in [initState] rather than lazily: a deck that never animates would
  /// otherwise create its ticker from [dispose], once lookups are unsafe.
  late final AnimationController _settle;

  /// Fractional index of the front pass; whole values mean "settled".
  final _position = ValueNotifier<double>(0);
  int _index = 0;
  double _extent = 1;
  bool _dragging = false;
  bool _disposed = false;
  int _token = 0;

  @override
  void initState() {
    super.initState();
    _settle = AnimationController.unbounded(vsync: this)
      ..addListener(() => _moveTo(_settle.value));
  }

  @override
  void dispose() {
    // Disposing the controller cancels its ticker, which runs the settle
    // callback below; it must not touch the controller afterwards.
    _disposed = true;
    _settle.dispose();
    _position.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AnimatedWallet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cards.isEmpty) return;
    final oldId = oldWidget.cards.isEmpty
        ? null
        : oldWidget.cards[_index.clamp(0, oldWidget.cards.length - 1)].id;
    final next = widget.cards.indexWhere((card) => card.id == oldId);
    _token++;
    _settle.stop();
    _settle.value = (next < 0 ? 0 : next).toDouble();
  }

  void _moveTo(double value) {
    if (_disposed) return;
    _position.value = value;
    if (widget.cards.isEmpty) return;
    final index = value.round() % widget.cards.length;
    if (index != _index) setState(() => _index = index);
  }

  void _settleTo(double target, double velocity) {
    if (widget.cards.length < 2) return;
    final token = ++_token;
    final motion = context.motion;
    if (motion.isStill) {
      _settle.stop();
      _settle.value = target;
      return;
    }
    _settle
        .animateWith(
          SpringSimulation(
            motion.deckSpring,
            _position.value,
            target,
            velocity,
          ),
        )
        .whenCompleteOrCancel(() {
          // Keep the position within one lap so repeated swipes cannot drift;
          // wrapping by a whole lap leaves the layout identical.
          if (_disposed || token != _token || _dragging) return;
          _settle.value = (_position.value.round() % widget.cards.length)
              .toDouble();
        });
  }

  void _move(int direction) =>
      _settleTo(_position.value.roundToDouble() + direction, 0);

  void _onDragStart(DragStartDetails details) {
    _dragging = true;
    _token++;
    _settle.stop();
  }

  void _onDragUpdate(DragUpdateDetails details) =>
      _moveTo(_position.value - (details.primaryDelta ?? 0) / _extent);

  void _onDragEnd(DragEndDetails details) {
    _dragging = false;
    final velocity = -(details.primaryVelocity ?? 0) / _extent;
    var target = _position.value.roundToDouble();
    if (velocity.abs() > _flingVelocity) {
      // A fling carries past the nearest pass instead of snapping back.
      target = velocity > 0
          ? _position.value.ceilToDouble()
          : _position.value.floorToDouble();
      if (target == _position.value) target += velocity.sign;
    }
    _settleTo(target, velocity);
  }

  /// Swipe on the detail panel below the deck; it has no pass to follow, so it
  /// only reacts to a deliberate flick.
  void _onDetailFling(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() > 120) _move(velocity < 0 ? 1 : -1);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) return const SizedBox.shrink();
    final s = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final credentials = context.credentials;
    final many = widget.cards.length > 1;
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, box) {
            final depth = math.min(widget.cards.length, _depth);
            final scale = MediaQuery.textScalerOf(
              context,
            ).scale(1).clamp(1.0, 2.0);
            final step = credentials.passStep * scale;
            final faceHeight = credentials.passFace * scale;
            _extent = math.max(1, box.maxWidth * _dragReach);
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 20, 14, 14),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(
                      credentials.panelRadius,
                    ),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: GestureDetector(
                    onHorizontalDragStart: many ? _onDragStart : null,
                    onHorizontalDragUpdate: many ? _onDragUpdate : null,
                    onHorizontalDragEnd: many ? _onDragEnd : null,
                    child: SizedBox(
                      key: const Key('walletDeck'),
                      height: faceHeight + (depth - 1) * step,
                      child: ValueListenableBuilder<double>(
                        valueListenable: _position,
                        builder: (context, position, _) => Stack(
                          children: _deck(position, depth, step, faceHeight),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              key: const Key('walletPrevious'),
              tooltip: s.walletPrevious,
              onPressed: many ? () => _move(-1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Semantics(
              liveRegion: true,
              child: Text(
                '${_index + 1} / ${widget.cards.length}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              key: const Key('walletNext'),
              tooltip: s.walletNext,
              onPressed: many ? () => _move(1) : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        GestureDetector(
          onHorizontalDragEnd: many ? _onDetailFling : null,
          child: _detail(context.motion),
        ),
      ],
    );
  }

  /// Detail panel under the deck. With reduced motion it is swapped outright:
  /// a zero-duration [AnimatedSize] re-dirties itself during its own layout.
  Widget _detail(ResonMotion motion) {
    final child = KeyedSubtree(
      key: ValueKey(widget.cards[_index].id),
      child: widget.children[_index.clamp(0, widget.children.length - 1)],
    );
    if (motion.isStill) return child;
    return AnimatedSize(
      duration: motion.expand,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: motion.transition,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(.06, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: motion.standard),
                ),
            child: child,
          ),
        ),
        child: child,
      ),
    );
  }

  /// Lays out the visible passes back to front for the given [position].
  List<Widget> _deck(
    double position,
    int depth,
    double step,
    double faceHeight,
  ) {
    final length = widget.cards.length;
    // One extra pass covers the gap opening at the back during a drag, but a
    // short deck has no spare card to put there without drawing it twice.
    final slots = math.min(length, depth + 1);
    final base = position.floor();
    final fraction = position - base;
    return [
      for (var offset = slots - 1; offset >= 0; offset--)
        _pass(
          card: widget.cards[(base + offset) % length],
          target: (base + offset).toDouble(),
          // 0 is the front pass; negative is leaving, >= depth is entering.
          distance: offset - fraction,
          depth: depth,
          step: step,
          faceHeight: faceHeight,
        ),
    ];
  }

  Widget _pass({
    required DigitalCard card,
    required double target,
    required double distance,
    required int depth,
    required double step,
    required double faceHeight,
  }) {
    // A pass fades as it slides off the front and as it rises at the back.
    final opacity = distance < 0
        ? (1 + distance).clamp(0.0, 1.0)
        : (depth - distance).clamp(0.0, 1.0);
    final inset = math.max(0.0, distance) * context.credentials.passInset;
    return Positioned(
      key: ValueKey('pass_${card.id}'),
      top: (depth - 1 - distance) * step,
      left: inset,
      right: inset,
      height: faceHeight,
      child: Opacity(
        opacity: opacity,
        // Tactile feedback on the pass itself; the deck reads as a stack of
        // physical cards, so it should give under a finger.
        child: ResonPress(
          child: _WalletPass(
            card: card,
            prominence: (1 - distance).clamp(0.0, 1.0),
            onTap: () => _settleTo(target, 0),
          ),
        ),
      ),
    );
  }
}

class _WalletPass extends StatelessWidget {
  const _WalletPass({
    required this.card,
    required this.prominence,
    required this.onTap,
  });
  final DigitalCard card;

  /// 1 while this pass is the front one, 0 once it sits a full slot behind.
  final double prominence;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final seed = cardColor(card.primaryHex);
    final type = card.kind == 'work'
        ? s.homeWork
        : card.kind == 'freelance'
        ? s.homeFreelance
        : s.homePersonal;
    final credentials = context.credentials;
    final reveal = context.motion.settle.transform(prominence);
    final base = Color.lerp(seed, ResonPalette.coal, .78 - .23 * prominence)!;
    return Semantics(
      selected: prominence > .5,
      button: true,
      label: '${card.label}, $type',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(credentials.passRadius),
        elevation: credentials.passElevation * prominence,
        shadowColor: Colors.black.withValues(alpha: .28),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(credentials.passRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [base, Color.lerp(base, ResonPalette.coal, .55)!],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: .12 + .14 * prominence),
            ),
          ),
          child: InkWell(
            key: ValueKey(card.id),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        card.kind == 'work'
                            ? Icons.badge_outlined
                            : card.kind == 'freelance'
                            ? Icons.auto_awesome_outlined
                            : Icons.person_outline,
                        size: 18,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          card.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.graphic_eq_rounded,
                        color: Colors.white70,
                        size: 21,
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Kept in the tree and faded, so the identity does not pop
                  // into place while the pass is still travelling.
                  Opacity(
                    opacity: reveal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            height: 1.15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                type.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  letterSpacing: 1.8,
                                ),
                              ),
                            ),
                            const Text(
                              'reson',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
