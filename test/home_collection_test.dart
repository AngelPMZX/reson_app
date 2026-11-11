import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reson/features/cards/domain/digital_card.dart';
import 'package:reson/features/cards/presentation/card_preview.dart';
import 'auth_flow_test.dart' as support;
import 'verification_cards_test.dart' as verified;

void main() {
  testWidgets(
    'Collection filters preserve cards and recover from empty category',
    (tester) async {
      final auth = verified.session();
      addTearDown(auth.dispose);
      final cards = support.TestCardsRepository();
      for (final kind in ['work', 'personal']) {
        cards.cards.add(
          DigitalCard(
            id: kind,
            label: kind,
            displayName: 'Alex',
            role: '',
            company: '',
            email: '',
            phone: '',
            website: '',
            primaryHex: '#7860E9',
            kind: kind,
          ),
        );
      }
      await support.launch(
        tester,
        repository: auth,
        cardsRepository: cards,
        size: const Size(390, 1000),
      );
      expect(find.byType(CardPreview), findsOneWidget);
      final next = find.byKey(const Key('walletNext'));
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(
        tester.widget<CardPreview>(find.byType(CardPreview)).card.kind,
        'personal',
      );
      final workTab = find.byWidgetPredicate(
        (w) => w is InkWell && w.key == const ValueKey('work'),
      );
      await tester.ensureVisible(workTab);
      await tester.tap(
        find.descendant(of: workTab, matching: find.text('work')),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<CardPreview>(find.byType(CardPreview)).card.kind,
        'work',
      );
      final personal = find.byKey(const ValueKey('filter_personal'));
      await tester.ensureVisible(personal);
      await tester.tap(personal);
      await tester.pumpAndSettle();
      expect(
        tester.widget<CardPreview>(find.byType(CardPreview)).card.kind,
        'personal',
      );
      await tester.tap(find.byKey(const ValueKey('filter_freelance')));
      await tester.pumpAndSettle();
      expect(find.byType(CardPreview), findsNothing);
      expect(find.text('Una nueva faceta por descubrir'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('filter_all')));
      await tester.pumpAndSettle();
      expect(find.byType(CardPreview), findsOneWidget);
      expect(cards.cards.length, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
