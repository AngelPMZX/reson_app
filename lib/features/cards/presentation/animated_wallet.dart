import '../../../core/theme/reson_palette.dart';
import 'card_preview.dart' show cardColor;
import 'package:flutter/material.dart';
import '../domain/digital_card.dart';
import '../../../l10n/generated/app_localizations.dart';

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

class _AnimatedWalletState extends State<AnimatedWallet> {
  int _index = 0;
  @override
  void didUpdateWidget(covariant AnimatedWallet oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldId = oldWidget.cards.isEmpty
        ? null
        : oldWidget.cards[_index.clamp(0, oldWidget.cards.length - 1)].id;
    final next = widget.cards.indexWhere((c) => c.id == oldId);
    _index = next < 0 ? 0 : next;
  }

  void _move(int direction) {
    setState(() => _index = (_index + direction) % widget.cards.length);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) return const SizedBox.shrink();
    final s = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Column(
      children: [
        if (widget.cards.isNotEmpty) ...[
          LayoutBuilder(
            builder: (context, box) {
              final count = widget.cards.length.clamp(0, 3);
              final scale = MediaQuery.textScalerOf(
                context,
              ).scale(1).clamp(1.0, 2.0);
              final step = 54.0 * scale;
              final faceHeight = 186.0 * scale;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 20, 14, 14),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: GestureDetector(
                      onHorizontalDragEnd: (d) {
                        if ((d.primaryVelocity ?? 0).abs() > 120) {
                          _move(d.primaryVelocity! < 0 ? 1 : -1);
                        }
                      },
                      child: SizedBox(
                        key: const Key('walletDeck'),
                        height: faceHeight + (count - 1) * step,
                        child: Stack(
                          children: [
                            for (var slot = count - 1; slot >= 0; slot--)
                              AnimatedPositioned(
                                key: ValueKey(
                                  'pass_${widget.cards[(_index + slot) % widget.cards.length].id}',
                                ),
                                duration: reduced
                                    ? Duration.zero
                                    : const Duration(milliseconds: 460),
                                curve: Curves.easeInOutCubic,
                                top: (count - 1 - slot) * step,
                                left: slot * 8.0,
                                right: slot * 8.0,
                                height: faceHeight,
                                child: _WalletPass(
                                  card:
                                      widget.cards[(_index + slot) %
                                          widget.cards.length],
                                  selected: slot == 0,
                                  onTap: () => setState(
                                    () => _index =
                                        (_index + slot) % widget.cards.length,
                                  ),
                                ),
                              ),
                          ],
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
                onPressed: widget.cards.length > 1 ? () => _move(-1) : null,
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
                onPressed: widget.cards.length > 1 ? () => _move(1) : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
        GestureDetector(
          onHorizontalDragEnd: widget.cards.length < 2
              ? null
              : (details) {
                  if (details.primaryVelocity != null &&
                      details.primaryVelocity!.abs() > 120) {
                    _move(details.primaryVelocity! < 0 ? 1 : -1);
                  }
                },
          child: AnimatedSize(
            duration: reduced
                ? Duration.zero
                : const Duration(milliseconds: 320),
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: reduced
                  ? Duration.zero
                  : const Duration(milliseconds: 420),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(.06, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(widget.cards[_index].id),
                child: widget.children[_index],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WalletPass extends StatelessWidget {
  const _WalletPass({
    required this.card,
    required this.selected,
    required this.onTap,
  });
  final DigitalCard card;
  final bool selected;
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
    final base = Color.lerp(seed, ResonPalette.coal, selected ? .55 : .78)!;
    return Semantics(
      selected: selected,
      button: true,
      label: '${card.label}, $type',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        elevation: selected ? 9 : 0,
        shadowColor: Colors.black.withValues(alpha: .28),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [base, Color.lerp(base, ResonPalette.coal, .55)!],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: selected ? .26 : .12),
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
                  if (selected) ...[
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
