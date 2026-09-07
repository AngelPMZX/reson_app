import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reson/app/reson_app.dart';
import 'package:reson/features/auth/domain/auth_repository.dart';
import 'package:reson/features/cards/application/cards_providers.dart';
import 'package:reson/features/cards/domain/digital_card.dart';
import 'auth_flow_test.dart' as support;

support.TestAuthRepository session({bool verified = true}) =>
    support.TestAuthRepository()
      ..verified = verified
      ..current = AuthIdentity(
        uid: 'owner',
        email: 'owner@example.com',
        name: 'Alex',
        emailVerified: verified,
      );

void main() {
  testWidgets('Unverified sessions cannot enter private routes or read cards', (
    tester,
  ) async {
    final auth = session(verified: false);
    addTearDown(auth.dispose);
    final cards = support.TestCardsRepository();
    final container = await support.launch(
      tester,
      repository: auth,
      cardsRepository: cards,
    );
    for (final path in [
      '/home',
      '/cards/new',
      '/cards/abcdefghijklmnop0000/edit',
    ]) {
      container.read(routerProvider).go(path);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('checkVerification')), findsOneWidget);
      expect(cards.watchCalls, 0);
    }
    expect(auth.verificationCalls, 1);
    expect(
      tester
          .widget<TextButton>(find.byKey(const Key('resendVerification')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const Key('checkVerification')));
    await tester.pumpAndSettle();
    expect(find.textContaining('El correo sigue pendiente'), findsOneWidget);
    expect(find.text('Mis tarjetas'), findsNothing);
    auth.verified = true;
    await tester.tap(find.byKey(const Key('checkVerification')));
    await tester.pumpAndSettle();
    expect(find.text('Mis tarjetas'), findsOneWidget);
    expect(cards.watchCalls, greaterThan(0));
  });

  testWidgets('Verification can be resent after cooldown', (tester) async {
    final auth = session(verified: false);
    addTearDown(auth.dispose);
    await support.launch(tester, repository: auth, size: const Size(320, 850));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 61));
    final resend = find.byKey(const Key('resendVerification'));
    await tester.ensureVisible(resend);
    await tester.tap(resend);
    await tester.pumpAndSettle();
    expect(auth.verificationCalls, 2);
  });

  testWidgets(
    'Create, edit and activate cards while preserving failed drafts',
    (tester) async {
      final auth = session();
      addTearDown(auth.dispose);
      final cards = support.TestCardsRepository();
      final container = await support.launch(
        tester,
        repository: auth,
        cardsRepository: cards,
      );
      container.read(routerProvider).go('/cards/new');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('card_label')), 'Freelance');
      await tester.enterText(
        find.byKey(const Key('card_website')),
        'javascript:alert(1)',
      );
      var save = find.byKey(const Key('saveCard'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(cards.cards, isEmpty);
      expect(find.textContaining('https:// o http://'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('card_website')),
        'https://example.com',
      );
      cards.failSave = true;
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.textContaining('No pudimos guardar'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('card_label')))
            .controller!
            .text,
        'Freelance',
      );
      cards.failSave = false;
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(cards.cards.single.label, 'Freelance');
      expect(find.text('Mis tarjetas'), findsOneWidget);
      final first = cards.cards.single;
      container.read(routerProvider).go('/cards/${first.id}/edit');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('card_label')), 'Mi marca');
      save = find.byKey(const Key('saveCard'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(cards.cards.single.label, 'Mi marca');
      expect(cards.cards.single.id, first.id);
      const second = DigitalCard(
        id: 'abcdefghijklmnop0001',
        label: 'Personal',
        displayName: 'Alex',
        role: '',
        company: '',
        email: '',
        phone: '',
        website: '',
        primaryHex: '#0D9488',
      );
      await cards.save(second);
      await tester.pumpAndSettle();
      await cards.select(second.id);
      await tester.pumpAndSettle();
      expect(container.read(activeCardProvider)?.id, second.id);
      await auth.signOut();
      await tester.pumpAndSettle();
      expect(container.read(activeCardProvider), isNull);
      expect(find.text('Mi marca'), findsNothing);
    },
  );

  for (final width in [320.0, 390.0, 1200.0]) {
    for (final locale in ['en', 'es']) {
      testWidgets('Cards and editor fit $width in $locale', (tester) async {
        final auth = session();
        addTearDown(auth.dispose);
        final container = await support.launch(
          tester,
          repository: auth,
          size: Size(width, 850),
          locale: locale,
        );
        expect(tester.takeException(), isNull);
        container.read(routerProvider).go('/cards/new');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
