import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reson/core/theme/reson_theme.dart';
import 'package:reson/core/theme/reson_tokens.dart';

/// The eight layouts the card editor offers. A ninth one added there without
/// a skin here would silently fall back to the classic palette.
const _layouts = [
  'signature',
  'minimal',
  'bold',
  'aurora',
  'executive',
  'editorial',
  'noir',
  'studio',
];

Future<BuildContext> _context(
  WidgetTester tester, {
  bool reduceMotion = false,
  Brightness brightness = Brightness.dark,
}) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MaterialApp(
      theme: ResonTheme.forSeed(ResonTheme.brand, brightness: brightness),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  return captured;
}

void main() {
  testWidgets('Both token sets are registered on the theme', (tester) async {
    for (final brightness in Brightness.values) {
      final theme = ResonTheme.forSeed(
        ResonTheme.brand,
        brightness: brightness,
      );
      expect(theme.extension<ResonMotion>(), isNotNull);
      expect(theme.extension<ResonCredentials>(), isNotNull);
    }
  });

  testWidgets('Reduced motion stills every duration', (tester) async {
    final context = await _context(tester, reduceMotion: true);
    final motion = context.motion;

    expect(motion.isStill, isTrue);
    for (final duration in [
      motion.press,
      motion.expand,
      motion.transition,
      motion.entrance,
      motion.meter,
      motion.showcase,
    ]) {
      expect(duration, Duration.zero);
    }
    // Curves and the spring stay usable; only time is removed.
    expect(motion.deckSpring.stiffness, greaterThan(0));
  });

  testWidgets('Normal motion keeps its timings', (tester) async {
    final context = await _context(tester);
    final motion = context.motion;

    expect(motion.isStill, isFalse);
    expect(motion.press, lessThan(motion.expand));
    expect(motion.expand, lessThan(motion.transition));
    expect(motion.transition, lessThan(motion.entrance));
    expect(motion.entrance, lessThan(motion.showcase));
  });

  testWidgets('Every card layout has its own skin', (tester) async {
    final context = await _context(tester);
    final credentials = context.credentials;
    final fallback = credentials.skin('classic');

    for (final layout in _layouts) {
      expect(
        credentials.skins.containsKey(layout),
        isTrue,
        reason: '$layout has no skin and would fall back to the classic one',
      );
    }
    // An unknown layout must still render rather than throw.
    expect(credentials.skin('not-a-layout').ink, fallback.ink);
  });

  testWidgets('Skins keep enough contrast to read', (tester) async {
    final context = await _context(tester);
    final credentials = context.credentials;

    for (final layout in _layouts) {
      final skin = credentials.skin(layout);
      // Muted text is a step down from the primary ink, never the same, or
      // the hierarchy on the credential disappears.
      expect(
        skin.muted,
        isNot(skin.ink),
        reason: '$layout uses one colour for both text levels',
      );
      expect(skin.blend, inInclusiveRange(0, 1), reason: layout);
    }
  });
}
