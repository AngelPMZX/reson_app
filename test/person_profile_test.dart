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
import 'social_flow_test.dart' show SocialService;
import 'verification_cards_test.dart' as verified;

Map<String, dynamic> _person() => {
  'id': 'shared',
  'label': 'Trabajo',
  'name': 'María Soto',
  'role': 'Diseñadora de producto',
  'company': 'Acme',
  'email': '',
  'phone': '',
  'website': '',
  'color': '#C8102E',
  'kind': 'work',
  'layout': 'signature',
  'bio': 'Diseño sistemas que la gente entiende sin manual.',
  'professional': <String, dynamic>{
    'location': 'CDMX',
    'workMode': 'Remoto',
    'skills': 'Figma, Research',
    'experience': [
      {
        'title': 'Diseñadora senior',
        'organization': 'Acme',
        'period': '2020 — 2024',
        'details': '',
      },
    ],
  },
  'visibleFields': <String>[
    'role',
    'company',
    'bio',
    'location',
    'workMode',
    'skills',
    'experience',
  ],
  'photoUrl': '',
};

Future<void> openPerson(
  WidgetTester tester, {
  Size size = const Size(390, 1600),
}) async {
  final auth = verified.session();
  addTearDown(auth.dispose);
  final c = await support.launch(
    tester,
    repository: auth,
    size: size,
    networkService: SocialService(card: _person()),
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: const RepaintBoundary(
        key: ValueKey('personCapture'),
        child: ResonApp(),
      ),
    ),
  );
  c.read(routerProvider).go('/receive/shared');
  await tester.pumpAndSettle();
}

Future<void> capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('RESON_SCREENSHOTS')) return;
  await tester.runAsync(() async {
    final image = await tester
        .renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('personCapture')),
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

  testWidgets('Opening a shared card shows the person behind it', (
    tester,
  ) async {
    await openPerson(tester);
    // A connection used to be a credential and nothing else: no face, no
    // career, no way to see who you were about to talk to.
    expect(find.text('María Soto'), findsWidgets);
    expect(find.text('Diseñadora de producto · Acme'), findsOneWidget);
    expect(find.text('CDMX · Remoto'), findsOneWidget);
    expect(find.text('Sobre mí'), findsOneWidget);
    expect(find.text('Diseñadora senior'), findsOneWidget);
    // The card is still there, now as one part of the person.
    expect(find.text('Su tarjeta'), findsOneWidget);
    expect(find.byType(CardPreview), findsOneWidget);
    await capture(tester, 'person');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Saving and connecting are still offered', (tester) async {
    await openPerson(tester);
    expect(find.text('Guardar en mi red'), findsOneWidget);
    expect(find.text('Intercambiar tarjetas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0, 900.0]) {
    testWidgets('A person fits $width', (tester) async {
      await openPerson(tester, size: Size(width, 1600));
      expect(tester.takeException(), isNull);
    });
  }
}
