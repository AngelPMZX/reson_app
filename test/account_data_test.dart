import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reson/app/reson_app.dart';
import 'auth_flow_test.dart' as support;
import 'social_flow_test.dart' show SocialService;
import 'verification_cards_test.dart' as verified;

final saved = <String>[];

Future<SocialService> openSettings(WidgetTester tester) async {
  saved.clear();
  final auth = verified.session();
  addTearDown(auth.dispose);
  final service = SocialService();
  final c = await support.launch(
    tester,
    repository: auth,
    size: const Size(390, 1600),
    networkService: service,
    exportSink: (json) async => saved.add(json),
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(container: c, child: const ResonApp()),
  );
  c.read(routerProvider).go('/settings');
  await tester.pumpAndSettle();
  return service;
}

void main() {
  testWidgets('An account can be taken away from inside the app', (
    tester,
  ) async {
    final service = await openSettings(tester);
    final delete = find.byKey(const Key('deleteAccount'));
    await tester.ensureVisible(delete);
    expect(delete, findsOneWidget);
    expect(service.deletions, 0);
  });

  testWidgets('Deleting asks for the word and refuses until it is right', (
    tester,
  ) async {
    final service = await openSettings(tester);
    final delete = find.byKey(const Key('deleteAccount'));
    await tester.ensureVisible(delete);
    await tester.tap(delete);
    await tester.pumpAndSettle();

    // Every other control here is reversible; this one asks to be meant.
    final confirm = find.byKey(const Key('deleteConfirmAction'));
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

    await tester.enterText(find.byKey(const Key('deleteConfirm')), 'borrar');
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

    await tester.enterText(find.byKey(const Key('deleteConfirm')), 'ELIMINAR');
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
    expect(service.deletions, 0);

    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(service.deletions, 1);
  });

  testWidgets('Cancelling a deletion deletes nothing', (tester) async {
    final service = await openSettings(tester);
    final delete = find.byKey(const Key('deleteAccount'));
    await tester.ensureVisible(delete);
    await tester.tap(delete);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('deleteConfirm')), 'ELIMINAR');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(service.deletions, 0);
  });

  testWidgets('Exporting asks the backend for everything it holds', (
    tester,
  ) async {
    final service = await openSettings(tester);
    final export = find.byKey(const Key('exportAccount'));
    await tester.ensureVisible(export);
    await tester.tap(export);
    await tester.pumpAndSettle();
    expect(service.exports, 1);
    // What the backend returns is what the person is handed.
    expect(saved.single, contains('"cards"'));
    expect(find.text('Datos descargados.'), findsOneWidget);
  });
}
