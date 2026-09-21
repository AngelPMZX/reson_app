import 'dart:typed_data';
import 'package:reson/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reson/app/reson_app.dart';
import 'package:reson/features/cards/domain/digital_card.dart';
import 'package:reson/features/cards/data/card_media_repository.dart';
import 'package:reson/features/cards/presentation/card_preview.dart';
import 'auth_flow_test.dart' as support;
import 'verification_cards_test.dart' as verified;

class DelayedCards extends support.TestCardsRepository {
  final pending = Completer<void>();
  int calls = 0;
  @override
  Future<void> save(DigitalCard card) async {
    calls++;
    await pending.future;
    await super.save(card);
  }
}

void main() {
  test(
    'Unavailable photo storage fails before Firebase or network access',
    () async {
      await expectLater(
        CardMediaRepository(
          'owner',
          uploadsEnabled: false,
        ).upload('test', Uint8List(0)),
        throwsA(isA<PhotoUploadsUnavailable>()),
      );
    },
  );
  testWidgets(
    'Card saves without a photo with either storage availability setting',
    (tester) async {
      final auth = verified.session();
      addTearDown(auth.dispose);
      final cards = support.TestCardsRepository();
      final container = await support.launch(
        tester,
        repository: auth,
        cardsRepository: cards,
      );
      container.read(routerProvider).go('/cards/new');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(const Key('choosePhoto')))
            .onPressed,
        photoUploadsEnabled ? isNotNull : isNull,
      );
      expect(
        find.textContaining('Las fotografías todavía no están disponibles'),
        photoUploadsEnabled ? findsNothing : findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const Key('card_label')),
        'Sin fotografía',
      );
      final save = find.byKey(const Key('saveCard'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(cards.cards.single.label, 'Sin fotografía');
      expect(cards.cards.single.photoPath, isEmpty);
    },
  );
  test(
    'Photo timeout requests cancellation and does not report success',
    () async {
      final pending = Completer<void>();
      var cancelled = false;
      await expectLater(
        awaitPhotoUpload(pending.future, () async {
          cancelled = true;
          return true;
        }, timeout: const Duration(milliseconds: 5)),
        throwsA(isA<TimeoutException>()),
      );
      expect(cancelled, isTrue);
      pending.complete();
    },
  );
  testWidgets(
    'Unconfirmed write unlocks fields, prevents overlapping save and preserves draft',
    (tester) async {
      final auth = verified.session();
      addTearDown(auth.dispose);
      final cards = DelayedCards();
      final container = await support.launch(
        tester,
        repository: auth,
        cardsRepository: cards,
      );
      container.read(routerProvider).go('/cards/new');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('card_label')), 'Primera');
      final save = find.byKey(const Key('saveCard'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pump();
      await tester.pump(const Duration(seconds: 31));
      await tester.pumpAndSettle();
      expect(find.textContaining('Aún no podemos confirmar'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('card_label')))
            .enabled,
        isTrue,
      );
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      await tester.enterText(
        find.byKey(const Key('card_label')),
        'Borrador nuevo',
      );
      cards.pending.complete();
      await tester.pumpAndSettle();
      expect(cards.calls, 1);
      expect(cards.cards.single.label, 'Primera');
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('card_label')))
            .controller!
            .text,
        'Borrador nuevo',
      );
      expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(cards.cards.length, 1);
      expect(cards.cards.single.label, 'Borrador nuevo');
    },
  );
  for (final style in [
    'signature',
    'minimal',
    'bold',
    'aurora',
    'executive',
    'editorial',
    'noir',
    'studio',
  ]) {
    testWidgets('$style fits narrow mobile with reduced motion', (
      tester,
    ) async {
      final auth = verified.session();
      addTearDown(auth.dispose);
      final cards = support.TestCardsRepository()
        ..cards.add(
          DigitalCard(
            id: 'abcdefghijklmnop0000',
            label: 'Trabajo',
            displayName: 'Alex Rivera',
            role: 'Consultoría tecnológica',
            company: 'Estudio Norte',
            email: 'alex@example.com',
            phone: '+52 555 010 0200',
            website: 'https://example.com',
            primaryHex: '#0D9488',
            layout: style,
          ),
        );
      await support.launch(
        tester,
        repository: auth,
        cardsRepository: cards,
        size: const Size(320, 1000),
      );
      expect(tester.takeException(), isNull);
      final preview = find.byType(CardPreview);
      final cardWidget = tester.widget<CardPreview>(preview);
      // Exercise system reduced-motion preference directly with the same preview.
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('es'),
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: CardPreview(card: cardWidget.card),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final tween = tester.widget<TweenAnimationBuilder<double>>(
        find.byType(TweenAnimationBuilder<double>),
      );
      expect(tween.duration, Duration.zero);
    });
  }
}
