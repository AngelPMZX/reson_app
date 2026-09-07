import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reson/app/reson_app.dart';
import 'package:reson/core/theme/reson_theme.dart';
import 'package:reson/features/cards/data/card_media_repository.dart';
import 'package:reson/features/cards/domain/digital_card.dart';
import 'package:reson/features/cards/presentation/card_preview.dart';
import 'auth_flow_test.dart' as support;
import 'verification_cards_test.dart' as verified;

const card = DigitalCard(
  id: 'abcdefghijklmnop0000',
  label: 'Consultoría',
  displayName: 'Alex Rivera',
  role: 'Consultor de tecnología',
  company: 'Estudio Norte',
  email: 'alex@example.com',
  phone: '+52 555 010 0200',
  website: 'https://example.com',
  primaryHex: '#956DFF',
  bio: 'Conecto ideas, personas y tecnología.',
);

void main() {
  setUpAll(() async {
    const dir = String.fromEnvironment('RESON_FONT_DIR');
    if (dir.isNotEmpty) {
      final text = FontLoader('Roboto')
        ..addFont(
          File(
            '$dir/roboto-regular.ttf',
          ).readAsBytes().then((b) => ByteData.sublistView(b)),
        );
      final icons = FontLoader('MaterialIcons')
        ..addFont(
          File(
            '$dir/materialicons-regular.otf',
          ).readAsBytes().then((b) => ByteData.sublistView(b)),
        );
      await text.load();
      await icons.load();
    }
  });
  test(
    'Legacy card defaults keep contact visible and cloning keeps design',
    () {
      expect(card.shows('email'), isTrue);
      expect(card.kind, 'work');
      final clone = card.withIdAndPhoto(
        'abcdefghijklmnop0001',
        'users/owner/cards/abcdefghijklmnop0001/1',
      );
      expect(clone.bio, card.bio);
      expect(clone.layout, card.layout);
      expect(clone.visibleFields, card.visibleFields);
    },
  );
  test('Photo input rejects oversized and unsupported content', () {
    expect(
      () => photoContentType(Uint8List(maxPhotoBytes + 1)),
      throwsFormatException,
    );
    expect(
      () => photoContentType(Uint8List.fromList([60, 115, 118, 103])),
      throwsFormatException,
    );
    expect(
      photoContentType(Uint8List.fromList([255, 216, 255, 224])),
      'image/jpeg',
    );
  });
  testWidgets('Templates preserve draft data and visibility is persisted', (
    tester,
  ) async {
    final auth = verified.session();
    addTearDown(auth.dispose);
    final cards = support.TestCardsRepository()..cards.add(card);
    final container = await support.launch(
      tester,
      repository: auth,
      cardsRepository: cards,
    );
    container.read(routerProvider).go('/cards/${card.id}/edit');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Personal'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Personal'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('card_company')))
          .controller!
          .text,
      card.company,
    );
    final preview = tester.widget<CardPreview>(find.byType(CardPreview));
    expect(preview.card.shows('company'), isFalse);
    expect(preview.card.shows('phone'), isFalse);
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Minimalista'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Minimalista'));
    await tester.ensureVisible(find.byKey(const Key('saveCard')));
    await tester.tap(find.byKey(const Key('saveCard')));
    await tester.pumpAndSettle();
    expect(cards.cards.single.company, card.company);
    expect(cards.cards.single.shows('company'), isFalse);
    expect(cards.cards.single.layout, 'minimal');
    expect(cards.cards.single.bio, card.bio);
  });
  testWidgets('Appearance toggle keeps the editor draft intact', (
    tester,
  ) async {
    final auth = verified.session();
    addTearDown(auth.dispose);
    final container = await support.launch(tester, repository: auth);
    container.read(routerProvider).go('/cards/new');
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('card_label')), 'Borrador');
    await tester.tap(find.byKey(const Key('themeToggle')));
    await tester.pumpAndSettle();
    expect(container.read(appearanceProvider), ThemeMode.light);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('card_label')))
          .controller!
          .text,
      'Borrador',
    );
  });
  for (final dark in [true, false]) {
    testWidgets(
      'Styled mobile collection fits in ${dark ? 'dark' : 'light'} mode',
      (tester) async {
        final auth = verified.session();
        addTearDown(auth.dispose);
        final cards = support.TestCardsRepository()..cards.add(card);
        final container = await support.launch(
          tester,
          repository: auth,
          cardsRepository: cards,
          size: const Size(390, 1000),
        );
        if (!dark) await container.read(appearanceProvider.notifier).toggle();
        final boundary = GlobalKey();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: RepaintBoundary(key: boundary, child: const ResonApp()),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (const bool.fromEnvironment('RESON_SCREENSHOTS')) {
          await tester.runAsync(() async {
            final image =
                await (boundary.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await Directory('build/design-preview').create(recursive: true);
            await File(
              'build/design-preview/${dark ? 'dark' : 'light'}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      },
    );
  }
}
