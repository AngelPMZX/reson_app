import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reson/features/network/network_service.dart';
import 'package:reson/features/network/network_widgets.dart';

FirebaseException _failure(String code) =>
    FirebaseException(plugin: 'cloud_functions', code: code);

void main() {
  group('Backend failures speak the reader language', () {
    const codes = [
      'not-found',
      'resource-exhausted',
      'permission-denied',
      'unauthenticated',
      'failed-precondition',
      'something-unmapped',
    ];

    test('every mapped code has a distinct Spanish and English wording', () {
      for (final code in codes) {
        final es = networkError(_failure(code), true);
        final en = networkError(_failure(code), false);
        expect(es, isNotEmpty, reason: code);
        expect(en, isNotEmpty, reason: code);
        expect(en, isNot(es), reason: 'Untranslated copy for $code');
      }
    });

    testWidgets('networkErrorText follows the active locale', (tester) async {
      final error = _failure('not-found');
      final rendered = <String, String>{};
      // The Builder element is reused across pumps, so a captured context must
      // be read inside its own pump instead of compared afterwards.
      for (final code in const ['es', 'en']) {
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(code),
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            supportedLocales: const [Locale('es'), Locale('en')],
            home: Builder(
              builder: (context) =>
                  Text(networkErrorText(context, error), key: Key(code)),
            ),
          ),
        );
        rendered[code] = tester.widget<Text>(find.byKey(Key(code))).data!;
      }
      expect(rendered['es'], networkError(error, true));
      expect(rendered['en'], networkError(error, false));
      expect(rendered['en'], isNot(rendered['es']));
    });

    test('no screen resolves an error with a hardcoded language flag', () {
      // Eight call sites once passed a literal `true`, so every reader saw
      // Spanish. Screens must go through networkErrorText and read the locale.
      final screens = Directory('lib/features/network')
          .listSync()
          .whereType<File>()
          .where(
            (f) =>
                f.path.endsWith('.dart') &&
                !f.path.endsWith('network_service.dart') &&
                !f.path.endsWith('network_widgets.dart'),
          );
      expect(screens, isNotEmpty);
      for (final screen in screens) {
        expect(
          screen.readAsStringSync(),
          isNot(contains('networkError(')),
          reason: '${screen.path} must call networkErrorText(context, error)',
        );
      }
    });
  });
}
