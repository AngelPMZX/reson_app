import 'package:reson/features/profile/personal_profile.dart';
import 'personal_profile_test.dart' show TestProfiles;
import 'package:reson/l10n/generated/app_localizations.dart';
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

  if (const bool.fromEnvironment('RESON_SCREENSHOTS')) {
    for (final page in ['profile', 'wallet']) {
      testWidgets('$page visual preview', (tester) async {
        final auth = verified.session();
        addTearDown(auth.dispose);
        final profiles = TestProfiles()
          ..current = PersonalProfile(
            fields: {
              'name': 'Alex Rivera',
              'role': 'Diseñador de producto',
              'email': 'alex@example.com',
            },
          );
        addTearDown(profiles.events.close);
        final cards = support.TestCardsRepository();
        for (var i = 0; i < 3; i++) {
          cards.cards.add(card.withIdAndPhoto('card$i', ''));
        }
        final container = await support.launch(
          tester,
          repository: auth,
          cardsRepository: cards,
          personalRepository: profiles,
          size: const Size(390, 1000),
        );
        if (page == 'profile') container.read(routerProvider).go('/profile');
        final boundary = GlobalKey();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: RepaintBoundary(key: boundary, child: const ResonApp()),
          ),
        );
        await tester.pumpAndSettle();
        if (page == 'wallet') {
          await tester.ensureVisible(find.byKey(const Key('walletDeck')));
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('build/design-preview').create(recursive: true);
          await File(
            'build/design-preview/$page.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      });
    }

    for (final authRoute in ['register', 'login', 'reset-password']) {
      testWidgets('$authRoute visual preview', (tester) async {
        final auth = support.TestAuthRepository();
        addTearDown(auth.dispose);
        final container = await support.launch(
          tester,
          repository: auth,
          size: const Size(390, 1100),
        );
        container.read(routerProvider).go('/$authRoute');
        await tester.pumpAndSettle();
        final boundary = GlobalKey();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: RepaintBoundary(key: boundary, child: const ResonApp()),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('build/design-preview').create(recursive: true);
          await File(
            'build/design-preview/$authRoute.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      });
    }
    testWidgets('New styles visual sheet', (tester) async {
      final auth = verified.session();
      addTearDown(auth.dispose);
      final container = await support.launch(
        tester,
        repository: auth,
        size: const Size(1200, 1000),
      );
      final boundary = GlobalKey();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: RepaintBoundary(
            key: boundary,
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('es'),
              theme: ResonTheme.forSeed(
                ResonTheme.violet,
                brightness: Brightness.dark,
              ),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final style in ['noir', 'studio', 'editorial'])
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                children: [
                                  Text(
                                    style.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      letterSpacing: 3,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  CardPreview(
                                    card: DigitalCard(
                                      id: '',
                                      label: 'Estudio Norte',
                                      displayName: 'Alex Rivera',
                                      role: 'Diseño de producto',
                                      company: 'Ideas que conectan',
                                      email: 'alex@example.com',
                                      phone: '+52 555 010 0200',
                                      website: 'https://example.com',
                                      primaryHex: '#7C3AED',
                                      bio:
                                          'Transformo ideas en experiencias memorables.',
                                      layout: style,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final image =
            await (boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('build/design-preview').create(recursive: true);
        await File(
          'build/design-preview/new-styles.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    });
  }

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
