import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reson/app/reson_app.dart';
import 'package:reson/features/cards/presentation/card_preview.dart';
import 'auth_flow_test.dart' as support;
import 'social_flow_test.dart' show SocialDoc, SocialService;
import 'verification_cards_test.dart' as verified;

/// A card somebody handed you, stored the way the backend now stores it.
SocialDoc _saved(
  String id,
  String name, {
  String kind = 'work',
  String company = '',
  String label = 'Trabajo',
  bool active = true,
  bool legacy = false,
}) => SocialDoc(id, {
  'publicId': id,
  'name': name,
  'label': label,
  'active': active,
  if (!legacy)
    'snapshot': {
      'name': name,
      'label': label,
      'role': 'Diseñadora',
      'company': company,
      'email': '',
      'phone': '',
      'website': '',
      'bio': '',
      'color': '#C8102E',
      'kind': kind,
      'layout': 'signature',
      'professional': <String, dynamic>{'location': 'CDMX'},
      'visibleFields': <String>['role', 'company'],
    },
});

Future<SocialService> openWallet(
  WidgetTester tester,
  List<SocialDoc> cards, {
  Size size = const Size(390, 1600),
}) async {
  final auth = verified.session();
  addTearDown(auth.dispose);
  final service = SocialService();
  final c = await support.launch(
    tester,
    repository: auth,
    size: size,
    received: cards,
    networkService: service,
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: const RepaintBoundary(
        key: ValueKey('walletCapture'),
        child: ResonApp(),
      ),
    ),
  );
  c.read(routerProvider).go('/network');
  await tester.pumpAndSettle();
  await tester.tap(find.text('Guardadas'));
  await tester.pumpAndSettle();
  return service;
}

Future<void> capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('RESON_SCREENSHOTS')) return;
  await tester.runAsync(() async {
    final image = await tester
        .renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('walletCapture')),
        )
        .toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('build/design-preview').create(recursive: true);
    await File(
      'build/design-preview/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    const dir = String.fromEnvironment('RESON_FONT_DIR');
    if (dir.isEmpty) return;
    for (final item in [
      ('Roboto', 'roboto-regular.ttf'),
      ('MaterialIcons', 'materialicons-regular.otf'),
    ]) {
      await (FontLoader(item.$1)..addFont(
            File('$dir/${item.$2}').readAsBytes().then(ByteData.sublistView),
          ))
          .load();
    }
  });

  testWidgets('The wallet draws the credentials people handed over', (
    tester,
  ) async {
    await openWallet(tester, [
      _saved('a', 'María Soto', company: 'Acme'),
      _saved('b', 'Luis Peña', kind: 'freelance', company: 'Estudio'),
    ]);
    // Saving used to keep only a name and a label, so the wallet could only
    // ever be a list of two lines. The snapshot is stored now.
    expect(find.byType(CardPreview), findsNWidgets(2));
    expect(find.text('María Soto'), findsWidgets);
    await capture(tester, 'wallet');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Filters narrow the wallet by kind and by text', (tester) async {
    await openWallet(tester, [
      _saved('a', 'María Soto', company: 'Acme'),
      _saved('b', 'Luis Peña', kind: 'freelance', company: 'Estudio'),
    ]);
    await tester.tap(find.byKey(const Key('wallet-freelance')));
    await tester.pumpAndSettle();
    expect(find.byType(CardPreview), findsOneWidget);
    expect(find.text('Luis Peña'), findsWidgets);

    await tester.tap(find.byKey(const Key('wallet-all')));
    await tester.pumpAndSettle();
    // Company is searchable too: a card is often remembered by where its
    // owner works rather than by their name.
    await tester.enterText(find.byType(TextField).last, 'acme');
    await tester.pumpAndSettle();
    expect(find.byType(CardPreview), findsOneWidget);
    expect(find.text('María Soto'), findsWidgets);

    await tester.enterText(find.byType(TextField).last, 'zzz');
    await tester.pumpAndSettle();
    expect(
      find.text('Ninguna tarjeta coincide con ese filtro.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('A withdrawn card is kept and explained, not hidden', (
    tester,
  ) async {
    await openWallet(tester, [_saved('a', 'María Soto', active: false)]);
    expect(find.text('Su dueño retiró esta tarjeta'), findsOneWidget);
    expect(find.byType(CardPreview), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A card saved before snapshots still shows its name', (
    tester,
  ) async {
    await openWallet(tester, [_saved('a', 'María Soto', legacy: true)]);
    // Accounts that saved cards under the old shape must not see a blank row.
    expect(find.byType(CardPreview), findsNothing);
    expect(find.text('María Soto'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Removing a card asks the backend once', (tester) async {
    final service = await openWallet(tester, [_saved('a', 'María Soto')]);
    final remove = find.byTooltip('Quitar de mi cartera');
    await tester.ensureVisible(remove);
    await tester.tap(remove);
    await tester.pumpAndSettle();
    expect(service.calls.single['action'], 'removeSaved');
    expect(service.calls.single['publicId'], 'a');
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0, 900.0]) {
    testWidgets('The wallet fits $width', (tester) async {
      await openWallet(tester, [
        _saved('a', 'María Fernanda de la Torre', company: 'Consultoría Beta'),
      ], size: Size(width, 1400));
      expect(tester.takeException(), isNull);
    });
  }
}
