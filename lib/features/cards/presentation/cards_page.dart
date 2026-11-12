import '../../../core/theme/reson_chrome.dart';
import '../../../core/theme/reson_palette.dart';
import '../../profile/personal_profile.dart';
import '../../profile/profile_avatar.dart';
import 'animated_wallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/firebase/firebase_bootstrap.dart';
import '../../../core/theme/reson_motion.dart';
import '../../../core/theme/reson_skeleton.dart';
import '../../../core/theme/reson_surfaces.dart';
import '../../../core/theme/reson_tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/brand_widgets.dart';
import '../application/cards_providers.dart';
import '../domain/digital_card.dart';
import 'card_preview.dart';
import 'home_identity_art.dart';

class CardsPage extends ConsumerStatefulWidget {
  const CardsPage({super.key});
  @override
  ConsumerState<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends ConsumerState<CardsPage> {
  bool _busy = false;
  bool _error = false;
  String _filter = 'all';

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = false;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final user = ref.watch(authSessionProvider).asData?.value;
    if (user == null || !user.emailVerified) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(cardsProvider);
    final active = ref.watch(activeCardProvider);
    final profile = ref.watch(personalProfileProvider).asData?.value;
    final displayName = profile?.value('name').trim();
    final name =
        (displayName?.isNotEmpty == true ? displayName! : user.name ?? '')
            .split(RegExp(r'\s+'))
            .first;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: ResonSpace.screen,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ResonHeader(),
                  const SizedBox(height: ResonSpace.xl),
                  Row(
                    children: [
                      ProfileAvatar(
                        name: name,
                        size: 42,
                        path: profile?.photoPath ?? '',
                        source: profile?.photoSource ?? 'google',
                        googleUrl: user.googlePhotoUrl,
                      ),
                      const SizedBox(width: ResonSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.isEmpty
                                  ? s.homeWelcome
                                  : '${s.homeWelcome}, $name',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              s.homeWorkspace,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: s.profileTitle,
                        onPressed: () => context.go('/profile'),
                        icon: const Icon(
                          Icons.manage_accounts_outlined,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: ResonSpace.xl),
                  ResonReveal(
                    child: ResonPanel(
                      padding: EdgeInsets.zero,
                      raised: true,
                      clip: true,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [ResonPalette.wine, ResonPalette.deepWine],
                      ),
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final wide = box.maxWidth > 680;
                          final copy = Padding(
                            padding: EdgeInsets.all(wide ? 36 : 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: ResonPalette.brightRed,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: ResonSpace.sm),
                                    Expanded(
                                      child: Text(
                                        s.homeEyebrow,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: ResonPalette.white,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: ResonSpace.xl),
                                Text(
                                  s.homeHeadline,
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall
                                      ?.copyWith(
                                        fontSize: wide ? 40 : null,
                                        color: ResonPalette.white,
                                      ),
                                ),
                                const SizedBox(height: ResonSpace.lg),
                                Text(
                                  s.cardsIntro,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(color: ResonPalette.paleGrey),
                                ),
                                const SizedBox(height: ResonSpace.xl),
                                ResonPress(
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: ResonPalette.white,
                                      foregroundColor: ResonPalette.wine,
                                    ),
                                    onPressed: () => context.go('/cards/new'),
                                    icon: const Icon(
                                      Icons.add_rounded,
                                      size: 20,
                                    ),
                                    label: Text(s.newCard),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (wide) {
                            return Row(
                              children: [
                                Expanded(flex: 6, child: copy),
                                const Expanded(
                                  flex: 4,
                                  child: SizedBox(
                                    height: 260,
                                    child: HomeIdentityArt(),
                                  ),
                                ),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              copy,
                              const SizedBox(
                                height: 140,
                                width: double.infinity,
                                child: HomeIdentityArt(compact: true),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: ResonSpace.xl),
                  if (active != null) _ProfileNudge(card: active),
                  const SizedBox(height: ResonSpace.xxl),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.myCards,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      if (state.asData != null)
                        _CountBadge(count: state.asData!.value.length),
                    ],
                  ),
                  const SizedBox(height: ResonSpace.lg),
                  Wrap(
                    spacing: ResonSpace.sm,
                    runSpacing: ResonSpace.sm,
                    children: [
                      for (final item in {
                        'all': s.homeAll,
                        'work': s.homeWork,
                        'freelance': s.homeFreelance,
                        'personal': s.homePersonal,
                      }.entries)
                        ChoiceChip(
                          key: ValueKey('filter_${item.key}'),
                          label: Text(item.value),
                          selected: _filter == item.key,
                          onSelected: (_) => setState(() => _filter = item.key),
                          showCheckmark: false,
                          shape: const StadiumBorder(),
                        ),
                    ],
                  ),
                  const SizedBox(height: ResonSpace.xl),
                  if (_error)
                    FeedbackMessage(text: s.cardSaveError, error: true),
                  if (_busy) const LinearProgressIndicator(),
                  state.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: ResonSpace.sm),
                      child: ResonCardSkeleton(),
                    ),
                    error: (_, stack) => Column(
                      children: [
                        FeedbackMessage(text: s.cardLoadError, error: true),
                        TextButton(
                          onPressed: () {
                            ref.invalidate(cardsProvider);
                            ref.invalidate(activeCardIdProvider);
                          },
                          child: Text(s.retry),
                        ),
                      ],
                    ),
                    data: (cards) {
                      final visible = cards
                          .where(
                            (card) => _filter == 'all' || card.kind == _filter,
                          )
                          .toList();
                      if (visible.isEmpty) {
                        return ResonPanel(
                          padding: const EdgeInsets.symmetric(
                            horizontal: ResonSpace.xl,
                            vertical: ResonSpace.xxl,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: ResonNotice(
                              icon: Icons.style_outlined,
                              tone: scheme.primary,
                              title: cards.isEmpty
                                  ? s.cardEmptyTitle
                                  : s.homeFilterEmpty,
                              text: cards.isEmpty
                                  ? s.cardEmptyBody
                                  : s.homeFilterHint,
                              action: cards.isEmpty
                                  ? null
                                  : TextButton(
                                      onPressed: () =>
                                          setState(() => _filter = 'all'),
                                      child: Text(s.homeAll),
                                    ),
                            ),
                          ),
                        );
                      }
                      return LayoutBuilder(
                        builder: (context, box) => AnimatedWallet(
                          cards: visible,
                          children: visible
                              .map(
                                (card) => SizedBox(
                                  key: ValueKey(card.id),
                                  width: box.maxWidth >= 760
                                      ? (box.maxWidth - 22) / 2
                                      : box.maxWidth,
                                  child: ResonReveal(
                                    // Making a card active used to swap the
                                    // border instantly; now the highlight
                                    // travels with the rest of the change.
                                    child: AnimatedContainer(
                                      duration: context.motion.expand,
                                      curve: context.motion.standard,
                                      padding: const EdgeInsets.all(
                                        ResonSpace.md,
                                      ),
                                      decoration: BoxDecoration(
                                        color: scheme.surfaceContainerLow,
                                        borderRadius: BorderRadius.circular(
                                          context.surfaces.panelRadius,
                                        ),
                                        // The active card is the only panel
                                        // that still draws an edge: it is a
                                        // state, not a container.
                                        border: active?.id == card.id
                                            ? Border.all(
                                                color: scheme.primary
                                                    .withValues(alpha: .55),
                                                width: 1.5,
                                              )
                                            : null,
                                        boxShadow: active?.id == card.id
                                            ? context.surfaces.raised
                                            : context.surfaces.resting,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              6,
                                              2,
                                              6,
                                              12,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.lock_outline_rounded,
                                                  size: 14,
                                                  color:
                                                      scheme.onSurfaceVariant,
                                                ),
                                                const SizedBox(
                                                  width: ResonSpace.sm,
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    s.privateCard,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelSmall
                                                        ?.copyWith(
                                                          color: scheme
                                                              .onSurfaceVariant,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          CardPreview(
                                            card: card,
                                            heroTag: cardHeroTag(card.id),
                                          ),
                                          const SizedBox(height: ResonSpace.sm),
                                          Wrap(
                                            spacing: 4,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              TextButton.icon(
                                                onPressed: () => context.push(
                                                  '/cards/${card.id}/share',
                                                ),
                                                icon: const Icon(
                                                  Icons.qr_code_2,
                                                  size: 18,
                                                ),
                                                label: Text(
                                                  Localizations.localeOf(
                                                            context,
                                                          ).languageCode ==
                                                          'es'
                                                      ? 'Compartir / QR'
                                                      : 'Share / QR',
                                                ),
                                              ),
                                              TextButton.icon(
                                                onPressed: () => context.push(
                                                  '/cards/${card.id}/edit',
                                                ),
                                                icon: const Icon(
                                                  Icons.tune_rounded,
                                                  size: 17,
                                                ),
                                                label: Text(s.editCard),
                                              ),
                                              TextButton.icon(
                                                onPressed:
                                                    _busy ||
                                                        active?.id == card.id
                                                    ? null
                                                    : () => _run(() async {
                                                        final repo = await ref.read(
                                                          cardsRepositoryProvider
                                                              .future,
                                                        );
                                                        await repo?.select(
                                                          card.id,
                                                        );
                                                      }),
                                                icon: Icon(
                                                  active?.id == card.id
                                                      ? Icons
                                                            .check_circle_rounded
                                                      : Icons
                                                            .radio_button_unchecked,
                                                  size: 16,
                                                ),
                                                label: Text(
                                                  active?.id == card.id
                                                      ? s.activeCard
                                                      : s.activateCard,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: ResonSpace.xxl),
                  Center(
                    child: Text(
                      'RESON  /  THEDARKINGSTUDIOS',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        letterSpacing: 2,
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
  }
}

class _ProfileNudge extends StatelessWidget {
  const _ProfileNudge({required this.card});
  final DigitalCard card;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final fields = [
      card.role,
      card.bio,
      card.professional.skills,
      card.professional.linkedin,
    ];
    final count = fields.where((v) => v.trim().isNotEmpty).length;
    return ResonPress(
      child: ResonPanel(
        padding: EdgeInsets.zero,
        clip: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/cards/${card.id}/edit'),
            child: Padding(
              padding: const EdgeInsets.all(ResonSpace.lg + 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 38,
                    height: 38,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: count / fields.length),
                      duration: context.motion.meter,
                      builder: (_, value, child) => CircularProgressIndicator(
                        value: value,
                        backgroundColor: scheme.outlineVariant,
                        strokeWidth: 3,
                        semanticsLabel: s.homeProfileDetails,
                      ),
                    ),
                  ),
                  const SizedBox(width: ResonSpace.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: ResonSpace.xs),
                        Text(
                          count == fields.length ? s.homeReady : s.homeImprove,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: ResonSpace.xs),
                        Text(
                          s.homeNudgeBody,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: ResonSpace.sm),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 19,
                    color: scheme.primary,
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

/// Card count. Animates to its new value so adding a card is felt, not just
/// displayed.
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ResonSpace.md,
        vertical: ResonSpace.xs + 2,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(ResonRadius.xl),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: count.toDouble()),
        duration: context.motion.expand,
        curve: context.motion.standard,
        builder: (context, value, _) => Text(
          '${value.round()}',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
