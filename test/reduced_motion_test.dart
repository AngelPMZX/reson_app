import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reson/core/theme/reson_theme.dart';
import 'package:reson/features/cards/domain/professional_profile.dart';
import 'package:reson/features/cards/presentation/professional_editor.dart';
import 'package:reson/l10n/generated/app_localizations.dart';

/// `AnimatedSize` re-dirties itself during its own layout when it is handed a
/// zero duration, so every screen has to drop the widget under reduced motion
/// rather than still it. These are the surfaces that wrap one.
Widget _host(Widget child, {required bool reduceMotion}) => MaterialApp(
  theme: ResonTheme.forSeed(ResonTheme.brand, brightness: Brightness.dark),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('es'),
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

Widget _professionalEditor() => ProfessionalEditor(
  initial: const ProfessionalProfile(sector: 'Tecnología'),
  onChanged: (_) {},
  enabled: true,
  visible: const {'sector'},
  onVisibility: (_, _) {},
);

void main() {
  for (final reduceMotion in [false, true]) {
    final label = reduceMotion ? 'reduced motion' : 'full motion';

    testWidgets('The career editor lays out and changes with $label', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(_professionalEditor(), reduceMotion: reduceMotion),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Typing grows the section, which is what drives the size animation.
      await tester.enterText(
        find.byKey(const Key('professional_skills')),
        'Diseño, estrategia, producto',
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Diseño, estrategia, producto'), findsOneWidget);
    });
  }

  testWidgets('The career editor keeps the animation at full motion', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_professionalEditor(), reduceMotion: false));
    await tester.pumpAndSettle();
    expect(find.byType(AnimatedSize), findsOneWidget);
  });

  testWidgets('The career editor drops the animation under reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_professionalEditor(), reduceMotion: true));
    await tester.pumpAndSettle();
    // Not stilled with a zero duration: removed, or it asserts during layout.
    expect(find.byType(AnimatedSize), findsNothing);
  });
}
