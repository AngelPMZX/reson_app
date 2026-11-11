import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reson/app/reson_app.dart';
import 'package:reson/features/auth/domain/auth_repository.dart';
import 'package:reson/features/cards/domain/digital_card.dart';
import 'package:reson/features/cards/presentation/card_preview.dart';
import 'auth_flow_test.dart' as support;

const _cardId = 'abcdefghijklmnop0000';

support.TestAuthRepository _session() => support.TestAuthRepository()
  ..verified = true
  ..current = const AuthIdentity(
    uid: 'owner',
    email: 'owner@example.com',
    name: 'Alex',
    emailVerified: true,
  );

final _card = DigitalCard(
  id: _cardId,
  label: 'Trabajo',
  displayName: 'Alex Rivera',
  role: 'Consultoría tecnológica',
  company: 'Estudio Norte',
  email: 'alex@example.com',
  phone: '+52 555 010 0200',
  website: 'https://example.com',
  primaryHex: '#0D9488',
);

Finder _credential() => find.byWidgetPredicate(
  (widget) => widget is Hero && widget.tag == cardHeroTag(_cardId),
);

void main() {
  testWidgets('The credential flies from the wallet into the editor', (
    tester,
  ) async {
    final auth = _session();
    addTearDown(auth.dispose);
    final cards = support.TestCardsRepository()..cards.add(_card);
    final container = await support.launch(
      tester,
      repository: auth,
      cardsRepository: cards,
      size: const Size(390, 1000),
    );
    await tester.pumpAndSettle();
    expect(_credential(), findsOneWidget);

    final edit = find.text('Editar tarjeta');
    await tester.ensureVisible(edit);
    await tester.tap(edit);

    // Part way through the flight: the credential is in the air, so it is
    // mounted neither on the wallet nor on the editor.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle();
    expect(find.text('Guardar tarjeta'), findsOneWidget);
    expect(_credential(), findsOneWidget);

    // A hero needs a pushed route. If this ever goes back to context.go the
    // stack is replaced, the flight silently stops and only this fails.
    expect(container.read(routerProvider).canPop(), isTrue);
  });

  testWidgets('Going back from the editor flies the credential home', (
    tester,
  ) async {
    final auth = _session();
    addTearDown(auth.dispose);
    final cards = support.TestCardsRepository()..cards.add(_card);
    final container = await support.launch(
      tester,
      repository: auth,
      cardsRepository: cards,
      size: const Size(390, 1000),
    );
    await tester.pumpAndSettle();

    final edit = find.text('Editar tarjeta');
    await tester.ensureVisible(edit);
    await tester.tap(edit);
    await tester.pumpAndSettle();

    container.read(routerProvider).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle();
    expect(find.text('Editar tarjeta'), findsOneWidget);
    expect(_credential(), findsOneWidget);
  });

  testWidgets('A new card has no credential to fly from', (tester) async {
    final auth = _session();
    addTearDown(auth.dispose);
    final cards = support.TestCardsRepository();
    final container = await support.launch(
      tester,
      repository: auth,
      cardsRepository: cards,
      size: const Size(390, 1000),
    );
    container.read(routerProvider).go('/cards/new');
    await tester.pumpAndSettle();

    expect(find.text('Guardar tarjeta'), findsOneWidget);
    // An empty id must not produce a tag, or two blank cards would collide.
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Hero && widget.tag.toString().startsWith('credential_'),
      ),
      findsNothing,
    );
  });
}
