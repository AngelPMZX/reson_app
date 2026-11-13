import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reson/app/reson_app.dart';
import 'package:reson/features/cards/domain/professional_profile.dart';
import 'package:reson/features/profile/personal_profile.dart';
import 'auth_flow_test.dart' as support;
import 'personal_profile_test.dart' show TestProfiles;
import 'verification_cards_test.dart' as verified;

PersonalProfile _filled() => PersonalProfile(
  fields: const {
    'name': 'Alex Rivera',
    'role': 'Diseñador de producto',
    'company': 'Acme',
    'bio': 'Diseño sistemas que la gente entiende sin manual.',
    'email': 'alex@example.com',
    'languages': 'Español, English',
    'services': 'Diseño de producto, Investigación',
  },
  availability: 'projects',
  professional: const ProfessionalProfile(
    location: 'CDMX',
    workMode: 'Remoto',
    skills: 'Figma, Research, Design systems',
    experience: [
      CareerEntry(
        title: 'Diseñador senior',
        organization: 'Acme',
        period: '2020 — 2024',
        details: 'Sistema de diseño y migración de producto.',
      ),
    ],
  ),
);

Future<void> openProfile(
  WidgetTester tester, {
  PersonalProfile? profile,
  Size size = const Size(390, 1400),
}) async {
  final auth = verified.session();
  addTearDown(auth.dispose);
  final profiles = TestProfiles()..current = profile;
  addTearDown(profiles.events.close);
  final c = await support.launch(
    tester,
    repository: auth,
    personalRepository: profiles,
    size: size,
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: const RepaintBoundary(
        key: ValueKey('profileCapture'),
        child: ResonApp(),
      ),
    ),
  );
  c.read(routerProvider).go('/profile');
  await tester.pumpAndSettle();
}

Future<void> capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('RESON_SCREENSHOTS')) return;
  await tester.runAsync(() async {
    final image = await tester
        .renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('profileCapture')),
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

  testWidgets('The profile presents you instead of asking you to type', (
    tester,
  ) async {
    await openProfile(tester, profile: _filled());
    expect(find.text('Alex Rivera'), findsWidgets);
    expect(find.text('Diseñador de producto · Acme'), findsOneWidget);
    expect(find.text('CDMX · Remoto'), findsOneWidget);
    expect(find.text('Abierto a proyectos'), findsOneWidget);
    expect(find.text('Sobre mí'), findsOneWidget);
    // Comma separated fields are shown as the lists they already are.
    expect(find.text('Figma'), findsOneWidget);
    expect(find.text('Design systems'), findsOneWidget);
    // The career presentation is the cards', reused rather than rebuilt.
    expect(find.text('Diseñador senior'), findsOneWidget);
    // Nothing is editable here; the form is one tap away.
    expect(find.byKey(const ValueKey('profile_name')), findsNothing);
    expect(find.text('Editar perfil'), findsOneWidget);
    await capture(tester, 'profile');
    expect(tester.takeException(), isNull);
  });

  testWidgets('An empty profile invites rather than shows blank panels', (
    tester,
  ) async {
    await openProfile(tester, size: const Size(390, 900));
    expect(find.text('Tu perfil está en blanco'), findsOneWidget);
    expect(find.text('Sobre mí'), findsNothing);
    await capture(tester, 'profile-empty');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Editing opens the form and comes back to the profile', (
    tester,
  ) async {
    await openProfile(tester, profile: _filled());
    await tester.tap(find.text('Editar perfil'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('profile_name')), findsOneWidget);
    // The form must open over the saved profile, not blank.
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('profile_name')))
          .controller!
          .text,
      'Alex Rivera',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Signing out is reachable and labelled, not a bare glyph', (
    tester,
  ) async {
    await openProfile(tester, profile: _filled());
    // It used to be a tune icon with only a tooltip, which shows nothing on a
    // phone, so the way out of the account looked like decoration.
    final settings = find.widgetWithText(TextButton, 'Ajustes');
    expect(settings, findsOneWidget);
    await tester.tap(settings);
    await tester.pumpAndSettle();
    final logout = find.text('Cerrar sesión');
    await tester.ensureVisible(logout);
    expect(logout, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0, 900.0]) {
    testWidgets('The profile fits $width', (tester) async {
      await openProfile(tester, profile: _filled(), size: Size(width, 1400));
      expect(tester.takeException(), isNull);
    });
  }
}
