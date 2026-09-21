import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reson/features/cards/domain/digital_card.dart';
import 'package:reson/features/cards/presentation/card_preview.dart';
import 'package:reson/l10n/generated/app_localizations.dart';

DigitalCard sample(String kind) => DigitalCard(
  id: '',
  label: kind == 'work'
      ? 'Estudio Norte'
      : kind == 'freelance'
      ? 'Diseño independiente'
      : 'Mi espacio',
  displayName: 'Alex Rivera',
  role: 'Diseño de producto',
  company: 'Estudio Norte',
  email: 'alex@example.com',
  phone: 'HIDDEN PHONE',
  website: 'alexrivera.design',
  primaryHex: '#7854CB',
  kind: kind,
  bio: 'Ideas claras. Conexiones que importan.',
  visibleFields: ['photo', 'role', 'company', 'email', 'website', 'bio'],
);
Widget page(Widget child, {double scale = 1}) => ProviderScope(
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('es'),
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: Scaffold(backgroundColor: const Color(0xFFF5F2FC), body: child),
    ),
  ),
);
void main() {
  for (final kind in ['work', 'freelance', 'personal']) {
    testWidgets('Credential $kind preserves privacy with enlarged text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        page(
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CardPreview(card: sample(kind)),
            ),
          ),
          scale: 1.8,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('credential_$kind')), findsOneWidget);
      expect(find.text('HIDDEN PHONE'), findsNothing);
      expect(find.text('alex@example.com'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  if (const bool.fromEnvironment('RESON_SCREENSHOTS')) {
    testWidgets('Credential design sheet', (tester) async {
      const dir = String.fromEnvironment('RESON_FONT_DIR');
      await tester.runAsync(() async {
        if (dir.isNotEmpty) {
          for (final item in [
            ('Roboto', 'roboto-regular.ttf'),
            ('MaterialIcons', 'materialicons-regular.otf'),
          ]) {
            await (FontLoader(item.$1)..addFont(
                  File(
                    '$dir/${item.$2}',
                  ).readAsBytes().then(ByteData.sublistView),
                ))
                .load();
          }
        }
      });
      tester.view.physicalSize = const Size(1200, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: page(
            Padding(
              padding: const EdgeInsets.all(30),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final kind in ['work', 'freelance', 'personal'])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: CardPreview(card: sample(kind)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('build/design-preview').create(recursive: true);
        await File(
          'build/design-preview/credentials.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    });
  }
}
