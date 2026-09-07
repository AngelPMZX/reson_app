import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/firebase/firebase_bootstrap.dart';
import '../../../core/theme/reson_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/brand_widgets.dart';
import '../application/cards_providers.dart';
import 'card_preview.dart';

class CardsPage extends ConsumerStatefulWidget {
  const CardsPage({super.key});
  @override
  ConsumerState<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends ConsumerState<CardsPage> {
  bool _busy = false;
  bool _error = false;
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
    // Defense in depth: do not render private content while auth is unresolved.
    if (user == null || !user.emailVerified) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final es = Localizations.localeOf(context).languageCode == 'es';
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(cardsProvider);
    final active = ref.watch(activeCardProvider);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResonLogo(
                    dark: Theme.of(context).brightness == Brightness.dark,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.name?.isNotEmpty == true
                              ? user.name!
                              : user.email,
                          style: const TextStyle(color: ResonTheme.muted),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _run(() async {
                                await (await ref.read(
                                  authRepositoryProvider.future,
                                ))?.signOut();
                              }),
                        icon: const Icon(Icons.logout, size: 16),
                        label: Text(s.logout),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF6B40C9), Color(0xFF322051)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0xFF9971E0).withValues(alpha: .4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              color: Color(0xFFD9C6FF),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                es
                                    ? 'TU IDENTIDAD, CON INTENCIÓN'
                                    : 'IDENTITY WITH INTENTION',
                                style: const TextStyle(
                                  color: Color(0xFFE4D4FF),
                                  fontSize: 10,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          s.myCards,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.cardsIntro,
                          style: const TextStyle(
                            color: Color(0xFFE4D4FF),
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFE9DCFF),
                            foregroundColor: const Color(0xFF341963),
                          ),
                          onPressed: () => context.go('/cards/new'),
                          icon: const Icon(Icons.add),
                          label: Text(s.newCard),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Icon(
                        Icons.layers_outlined,
                        size: 20,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          es ? 'Tu colección' : 'Your collection',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
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
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            state.asData!.value.length.toString(),
                            style: TextStyle(color: scheme.onPrimaryContainer),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (_error) ...[
                    FeedbackMessage(text: s.cardSaveError, error: true),
                    const SizedBox(height: 20),
                  ],
                  if (_busy) const LinearProgressIndicator(),
                  state.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, stack) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                    data: (cards) => cards.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.badge_outlined,
                                  size: 52,
                                  color: ResonTheme.violet,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  s.cardEmptyTitle,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  s.cardEmptyBody,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: ResonTheme.muted,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) => Wrap(
                              spacing: 20,
                              runSpacing: 24,
                              children: cards
                                  .map(
                                    (card) => SizedBox(
                                      width: constraints.maxWidth >= 720
                                          ? (constraints.maxWidth - 20) / 2
                                          : constraints.maxWidth,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          CardPreview(card: card),
                                          const SizedBox(height: 10),
                                          Wrap(
                                            spacing: 10,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              TextButton.icon(
                                                onPressed: () => context.go(
                                                  '/cards/${card.id}/edit',
                                                ),
                                                icon: const Icon(
                                                  Icons.edit_outlined,
                                                  size: 16,
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
                                                        if (repo != null) {
                                                          await repo.select(
                                                            card.id,
                                                          );
                                                        }
                                                      }),
                                                icon: Icon(
                                                  active?.id == card.id
                                                      ? Icons.check_circle
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
                                          Text(
                                            s.privateCard,
                                            style: const TextStyle(
                                              color: ResonTheme.muted,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
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
