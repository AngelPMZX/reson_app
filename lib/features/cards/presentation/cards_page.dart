import '../../../core/theme/reson_palette.dart';
import '../../profile/personal_profile.dart';
import '../../profile/profile_avatar.dart';
import 'animated_wallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/firebase/firebase_bootstrap.dart';
import '../../../core/theme/reson_motion.dart';
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 48),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResonLogo(dark: dark),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      ProfileAvatar(
                        name: name,
                        size: 42,
                        path: profile?.photoPath ?? '',
                        source: profile?.photoSource ?? 'google',
                        googleUrl: user.googlePhotoUrl,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.isEmpty
                                  ? s.homeWelcome
                                  : '${s.homeWelcome}, $name',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              s.homeWorkspace,
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
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
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/network'),
                    icon: const Icon(Icons.hub_outlined),
                    label: Text(
                      Localizations.localeOf(context).languageCode == 'es'
                          ? 'Mi red · Conexiones y chats'
                          : 'My network · Connections and chats',
                    ),
                  ),
                  const SizedBox(height: 24),
                  ResonReveal(
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: const [
                            ResonPalette.wine,
                            ResonPalette.deepWine,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: .35),
                        ),
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
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        s.homeEyebrow,
                                        style: TextStyle(
                                          color: ResonPalette.white,
                                          fontSize: 10,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 22),
                                Text(
                                  s.homeHeadline,
                                  style: TextStyle(
                                    fontSize: wide ? 38 : 28,
                                    height: 1.08,
                                    letterSpacing: -1.4,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  s.cardsIntro,
                                  style: TextStyle(
                                    color: ResonPalette.paleGrey,
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 24),
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
                  const SizedBox(height: 22),
                  if (active != null) _ProfileNudge(card: active),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.myCards,
                          style: const TextStyle(
                            fontSize: 27,
                            letterSpacing: -.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (state.asData != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            '${state.asData!.value.length}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
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
                  const SizedBox(height: 22),
                  if (_error)
                    FeedbackMessage(text: s.cardSaveError, error: true),
                  if (_busy) const LinearProgressIndicator(),
                  state.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
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
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 26,
                            vertical: 36,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: scheme.outlineVariant),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.style_outlined,
                                color: scheme.primary,
                                size: 42,
                              ),
                              const SizedBox(height: 18),
                              Text(
                                cards.isEmpty
                                    ? s.cardEmptyTitle
                                    : s.homeFilterEmpty,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                cards.isEmpty
                                    ? s.cardEmptyBody
                                    : s.homeFilterHint,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  height: 1.6,
                                ),
                              ),
                              if (cards.isNotEmpty)
                                TextButton(
                                  onPressed: () =>
                                      setState(() => _filter = 'all'),
                                  child: Text(s.homeAll),
                                ),
                            ],
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
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: scheme.surfaceContainerLow,
                                        borderRadius: BorderRadius.circular(
                                          context.credentials.panelRadius,
                                        ),
                                        border: Border.all(
                                          color: active?.id == card.id
                                              ? scheme.primary.withValues(
                                                  alpha: .5,
                                                )
                                              : scheme.outlineVariant,
                                        ),
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
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    s.privateCard,
                                                    style: TextStyle(
                                                      fontSize: 11,
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
                                          const SizedBox(height: 8),
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
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      'RESON  /  THEDARKINGSTUDIOS',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 9,
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
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(context.credentials.passRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(context.credentials.passRadius),
          onTap: () => context.push('/cards/${card.id}/edit'),
          child: Padding(
            padding: const EdgeInsets.all(18),
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
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        count == fields.length ? s.homeReady : s.homeImprove,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.homeNudgeBody,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
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
    );
  }
}
