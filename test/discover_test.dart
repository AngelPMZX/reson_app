import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reson/app/reson_app.dart';
import 'package:reson/features/network/network_service.dart';
import 'auth_flow_test.dart' as support;
import 'social_flow_test.dart' show SocialDoc, SocialService;
import 'verification_cards_test.dart' as verified;

SocialDoc _listed(
  String uid,
  String name, {
  String role = 'Diseñadora',
  String company = 'Acme',
  String location = 'CDMX',
}) => SocialDoc(uid, {
  'uid': uid,
  'publicId': 'public-$uid',
  'name': name,
  'role': role,
  'company': company,
  'sector': 'Tecnología',
  'location': location,
  'terms': [
    for (final word
        in '$name $role $company $location'
            .toLowerCase()
            .replaceAll('í', 'i')
            .replaceAll('ñ', 'n')
            .replaceAll('á', 'a')
            .replaceAll('é', 'e')
            .replaceAll('ó', 'o')
            .split(RegExp('[^a-z0-9]+'))
            .where((w) => w.length >= 2))
      for (var i = 2; i <= word.length; i++) word.substring(0, i),
  ],
});

Future<void> openDiscover(
  WidgetTester tester,
  List<SocialDoc> people, {
  Size size = const Size(390, 1000),
}) async {
  final auth = verified.session();
  addTearDown(auth.dispose);
  final c = await support.launch(
    tester,
    repository: auth,
    size: size,
    networkService: SocialService(),
    directory: people,
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: const RepaintBoundary(
        key: ValueKey('discoverCapture'),
        child: ResonApp(),
      ),
    ),
  );
  c.read(routerProvider).go('/discover');
  await tester.pumpAndSettle();
}

Future<void> capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('RESON_SCREENSHOTS')) return;
  await tester.runAsync(() async {
    final image = await tester
        .renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('discoverCapture')),
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

  group('What a typed query becomes', () {
    test('matches the backend, so both sides agree on a term', () {
      // Mirrors searchQuery in functions/domain.js: one array-contains term
      // for the server, the rest to narrow on the device.
      expect(searchQuery('María diseño').term, 'diseno');
      expect(searchQuery('María diseño').rest, ['maria']);
      expect(searchQuery('  ').term, '');
      expect(searchQuery('a').term, '');
      expect(searchQuery('Z' * 40).term.length, 14);
    });
  });

  testWidgets('Nothing is searched until something is typed', (tester) async {
    await openDiscover(tester, [_listed('maria', 'María Soto')]);
    expect(find.text('Escribe para empezar a buscar.'), findsOneWidget);
    expect(find.text('María Soto'), findsNothing);
    await capture(tester, 'discover-empty');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Typing finds people who chose to be findable', (tester) async {
    await openDiscover(tester, [
      _listed('maria', 'María Soto'),
      _listed('luis', 'Luis Peña', company: 'Estudio', location: 'Lima'),
    ]);
    // Accents are normalised on both sides, so typing plainly still finds
    // somebody who writes their name with them.
    await tester.enterText(find.byType(TextField).first, 'maria');
    await tester.pumpAndSettle();
    expect(find.text('María Soto'), findsOneWidget);
    expect(find.text('Diseñadora · Acme'), findsOneWidget);
    await capture(tester, 'discover');
    expect(tester.takeException(), isNull);
  });

  testWidgets('A search that matches nobody says so', (tester) async {
    await openDiscover(tester, []);
    await tester.enterText(find.byType(TextField).first, 'zzzz');
    await tester.pumpAndSettle();
    expect(find.text('Nadie coincide con esa búsqueda.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Being findable is off until asked for', (tester) async {
    final auth = verified.session();
    addTearDown(auth.dispose);
    final service = SocialService();
    final c = await support.launch(
      tester,
      repository: auth,
      size: const Size(390, 1400),
      networkService: service,
      publications: [
        SocialDoc('card', {
          'id': 'public-card',
          'label': 'Trabajo',
          'active': true,
        }),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const ResonApp()),
    );
    c.read(routerProvider).go('/settings');
    await tester.pumpAndSettle();
    final toggle = find.byKey(const Key('discoverableToggle'));
    await tester.ensureVisible(toggle);
    // Nobody is listed for having published a card: it is a separate consent.
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    expect(service.calls, isEmpty);

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(service.calls.single['action'], 'setDiscoverable');
    expect(service.calls.single['enabled'], isTrue);
    expect(service.calls.single['publicId'], 'public-card');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Without a published card there is nothing to be listed as', (
    tester,
  ) async {
    final auth = verified.session();
    addTearDown(auth.dispose);
    final c = await support.launch(
      tester,
      repository: auth,
      size: const Size(390, 1400),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const ResonApp()),
    );
    c.read(routerProvider).go('/settings');
    await tester.pumpAndSettle();
    expect(
      find.text('Publica una tarjeta para poder aparecer en el buscador.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('discoverableToggle')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0, 900.0]) {
    testWidgets('Search fits $width', (tester) async {
      await openDiscover(tester, [
        _listed('maria', 'Maria Fernanda de la Torre', company: 'Consultoria'),
      ], size: Size(width, 900));
      await tester.enterText(find.byType(TextField).first, 'maria');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
