import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reson/features/network/network_service.dart';
import 'package:reson/features/network/network_widgets.dart';
import 'package:reson/l10n/generated/app_localizations.dart';

FirebaseException _failure(String code) =>
    FirebaseException(plugin: 'cloud_functions', code: code);

/// Renders [build] under [locale] and returns what it produced.
Future<String> _under(
  WidgetTester tester,
  String locale,
  String Function(BuildContext context) build,
) async {
  late String result;
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          result = build(context);
          return const SizedBox();
        },
      ),
    ),
  );
  return result;
}

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

    test('the failure code is read without deciding on a language', () {
      expect(networkErrorCode(_failure('not-found')), 'not-found');
      expect(networkErrorCode(StateError('boom')), '');
    });

    testWidgets('every code reads differently in each language', (
      tester,
    ) async {
      for (final code in codes) {
        final error = _failure(code);
        final spanish = await _under(
          tester,
          'es',
          (c) => networkErrorText(c, error),
        );
        final english = await _under(
          tester,
          'en',
          (c) => networkErrorText(c, error),
        );
        expect(spanish, isNotEmpty, reason: code);
        expect(english, isNotEmpty, reason: code);
        expect(english, isNot(spanish), reason: 'Untranslated copy for $code');
      }
    });

    test('the network module holds no wording of its own', () {
      // Every string the module shows comes from the ARB files, so adding a
      // language is a translation rather than a code change. These are the
      // shapes that used to decide between two languages in Dart: a tr()
      // helper with both texts inline, and a boolean language flag.
      final screens = Directory(
        'lib/features/network',
      ).listSync().whereType<File>().where((f) => f.path.endsWith('.dart'));
      expect(screens, isNotEmpty);
      for (final screen in screens) {
        final source = screen.readAsStringSync();
        expect(
          source,
          isNot(contains("tr(")),
          reason: '${screen.path} still carries inline translations',
        );
        expect(
          source,
          isNot(contains("languageCode == 'es'")),
          reason: '${screen.path} still branches on the language itself',
        );
      }
    });
  });
}
