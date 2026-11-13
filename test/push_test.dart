import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reson/core/theme/reson_theme.dart';
import 'auth_flow_test.dart' as support;
import 'verification_cards_test.dart' as verified;

void main() {
  testWidgets('A verified session hands this device over, in its language', (
    tester,
  ) async {
    final asked = <String>[];
    final auth = verified.session();
    addTearDown(auth.dispose);
    final c = await support.launch(
      tester,
      repository: auth,
      pushRegistrar: (service, language) async => asked.add(language),
    );
    expect(asked, ['es']);

    c.read(localeProvider.notifier).set(const Locale('en'));
    await tester.pumpAndSettle();
    // A notification is written on the server, so the device has to say
    // which words it wants whenever that changes.
    expect(asked, ['es', 'en']);
  });

  testWidgets('An unverified session is never asked for permission', (
    tester,
  ) async {
    final asked = <String>[];
    final auth = verified.session(verified: false);
    addTearDown(auth.dispose);
    await support.launch(
      tester,
      repository: auth,
      pushRegistrar: (service, language) async => asked.add(language),
    );
    // Android gives one prompt. Spending it on an account that cannot use
    // the app yet wastes it.
    expect(asked, isEmpty);
  });

  testWidgets('A signed out session registers nothing', (tester) async {
    final asked = <String>[];
    final auth = support.TestAuthRepository();
    addTearDown(auth.dispose);
    await support.launch(
      tester,
      repository: auth,
      pushRegistrar: (service, language) async => asked.add(language),
    );
    expect(asked, isEmpty);
  });
}
