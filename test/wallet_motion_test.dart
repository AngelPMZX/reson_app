import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reson/features/cards/domain/digital_card.dart';
import 'package:reson/features/cards/presentation/animated_wallet.dart';
import 'package:reson/l10n/generated/app_localizations.dart';

DigitalCard _card(String id, String kind) => DigitalCard(
  id: id,
  label: 'Label $id',
  displayName: 'Name $id',
  role: 'Role',
  company: 'Company',
  email: 'a@example.com',
  phone: '+52 555 010 0200',
  website: 'https://example.com',
  primaryHex: '#0D9488',
  kind: kind,
);

/// Fixed width so the drag distance that advances one pass is deterministic.
Widget _host(Widget child, {bool reduceMotion = false}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('es'),
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(
      body: SingleChildScrollView(
        child: Center(child: SizedBox(width: 400, child: child)),
      ),
    ),
  ),
);

Widget _wallet(List<DigitalCard> cards) => AnimatedWallet(
  cards: cards,
  children: [for (final card in cards) Text('detail ${card.id}')],
);

double _passTop(WidgetTester tester, String id) =>
    tester.widget<Positioned>(find.byKey(ValueKey('pass_$id'))).top!;

void main() {
  final deck = [
    _card('a', 'work'),
    _card('b', 'freelance'),
    _card('c', 'personal'),
  ];

  testWidgets('The deck follows the finger before it is released', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_wallet(deck)));
    await tester.pumpAndSettle();
    final resting = _passTop(tester, 'a');

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('walletDeck'))),
    );
    // The first move past the touch slop only starts the drag, so the travel
    // that reaches onUpdate has to come from a second move.
    await gesture.moveBy(const Offset(-20, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-60, 0));
    await tester.pump();
    // The front pass slides out while still held, instead of waiting for the
    // gesture to finish and jumping.
    expect(_passTop(tester, 'a'), greaterThan(resting));

    // Past half of the reach, releasing commits to the next pass.
    await gesture.moveBy(const Offset(-80, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('detail b'), findsOneWidget);
  });

  testWidgets('A short drag springs back to the pass it started on', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_wallet(deck)));
    await tester.pumpAndSettle();
    final resting = _passTop(tester, 'a');

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('walletDeck'))),
    );
    await gesture.moveBy(const Offset(-20, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-30, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(_passTop(tester, 'a'), resting);
    expect(find.text('detail a'), findsOneWidget);
  });

  testWidgets('Reduced motion settles without running a spring', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_wallet(deck), reduceMotion: true));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('walletNext')));
    await tester.pump();
    expect(find.text('detail b'), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
  });

  testWidgets('Replacing the tree mid-spring does not use a disposed ticker', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_wallet(deck)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('walletNext')));
    await tester.pump(const Duration(milliseconds: 60));

    await tester.pumpWidget(_host(const Text('replaced')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('A deck that never animates disposes cleanly', (tester) async {
    // A single pass cannot be swiped, so the controller is never driven; it
    // still has to be built before dispose to keep ticker lookups safe.
    await tester.pumpWidget(_host(_wallet([deck.first])));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_host(const Text('replaced')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('The deck keeps its pass when the card list changes', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_wallet(deck)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('walletNext')));
    await tester.pumpAndSettle();
    expect(find.text('detail b'), findsOneWidget);

    // Dropping the first card keeps 'b' selected rather than resetting.
    await tester.pumpWidget(_host(_wallet([deck[1], deck[2]])));
    await tester.pumpAndSettle();
    expect(find.text('detail b'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
  });
}
