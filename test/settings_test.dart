import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reson/app/reson_app.dart';
import 'package:reson/core/theme/reson_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_flow_test.dart' as support;
import 'verification_cards_test.dart' as verified;

Future<ProviderContainer> openSettings(
  WidgetTester tester, {
  Size size = const Size(390, 1000),
}) async {
  SharedPreferences.setMockInitialValues({});
  final auth = verified.session();
  addTearDown(auth.dispose);
  final c = await support.launch(tester, repository: auth, size: size);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: const RepaintBoundary(
        key: ValueKey('settingsCapture'),
        child: ResonApp(),
      ),
    ),
  );
  c.read(routerProvider).go('/settings');
  await tester.pumpAndSettle();
  return c;
}

Future<void> capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('RESON_SCREENSHOTS')) return;
  await tester.runAsync(() async {
    final image = await tester
        .renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('settingsCapture')),
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

  testWidgets('Settings gathers the preferences that were scattered', (
    tester,
  ) async {
    await openSettings(tester);
    expect(find.text('Ajustes'), findsWidgets);
    expect(find.text('Apariencia'), findsOneWidget);
    expect(find.text('Idioma'), findsOneWidget);
    // The chime used to sit at the top of the network screen, above other
    // people's requests.
    expect(find.text('Sonido al aceptar una conexión'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
    await capture(tester, 'settings');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Appearance can go back to following the device', (tester) async {
    final c = await openSettings(tester);
    expect(c.read(appearanceProvider), ThemeMode.system);

    await tester.tap(find.byKey(const Key('appearance-dark')));
    await tester.pumpAndSettle();
    expect(c.read(appearanceProvider), ThemeMode.dark);

    // The header toggle alone could never get back here: two states cannot
    // express "whichever my device is".
    await tester.tap(find.byKey(const Key('appearance-system')));
    await tester.pumpAndSettle();
    expect(c.read(appearanceProvider), ThemeMode.system);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Language can be chosen and handed back to the device', (
    tester,
  ) async {
    final c = await openSettings(tester);
    // The harness launches in Spanish, so the row starts on a real choice
    // rather than on "follow the device".
    expect(c.read(localeProvider), const Locale('es'));

    await tester.tap(find.byKey(const Key('language-en')));
    await tester.pumpAndSettle();
    expect(c.read(localeProvider), const Locale('en'));
    expect(find.text('Settings'), findsWidgets);

    await tester.tap(find.byKey(const Key('language-system')));
    await tester.pumpAndSettle();
    expect(c.read(localeProvider), isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A chosen language survives a restart', (tester) async {
    SharedPreferences.setMockInitialValues({'locale': 'en'});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(localeProvider);
    await tester.pumpAndSettle();
    // It used to live only in memory, so the app forgot it every launch.
    expect(container.read(localeProvider), const Locale('en'));
  });

  testWidgets('A saved system choice beats the legacy boolean', (tester) async {
    SharedPreferences.setMockInitialValues({
      'darkMode': true,
      'themeMode': 'system',
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(appearanceProvider);
    await tester.pumpAndSettle();
    expect(container.read(appearanceProvider), ThemeMode.system);
  });

  for (final width in [320.0, 390.0, 900.0]) {
    testWidgets('Settings fits $width', (tester) async {
      await openSettings(tester, size: Size(width, 900));
      expect(tester.takeException(), isNull);
    });
  }
}
