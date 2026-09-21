import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reson/app/reson_app.dart';
import 'package:reson/features/network/network_service.dart';
import 'auth_flow_test.dart' as support;
import 'verification_cards_test.dart' as verified;
import 'card_design_test.dart' show card;

// Test double for immutable Firestore snapshots; never used in application code.
// ignore: subtype_of_sealed_class
class SocialDoc extends Fake
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  SocialDoc(this.id, this.value);
  @override
  final String id;
  final Map<String, dynamic> value;
  @override
  Map<String, dynamic> data() => value;
}

class SocialService extends NetworkService {
  final calls = <Map<String, dynamic>>[];
  @override
  Future<Map<String, dynamic>> act(
    String action,
    Map<String, dynamic> data,
  ) async {
    calls.add({'action': action, ...data});
    return {};
  }

  @override
  Future<Map<String, dynamic>> shared(String id) async => {
    'id': id,
    'label': 'Trabajo',
    'name': 'Alex',
    'role': 'Diseño',
    'company': '',
    'email': '',
    'phone': '',
    'website': '',
    'color': '#C8102E',
    'kind': 'work',
    'layout': 'signature',
    'bio': '',
    'professional': <String, dynamic>{},
    'visibleFields': <String>[],
    'photoUrl': '',
  };
}

Future<void> captureSocial(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('RESON_SCREENSHOTS')) return;
  await tester.runAsync(() async {
    final image = await tester
        .renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('socialCapture')),
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
    if (dir.isNotEmpty) {
      for (final item in [
        ('Roboto', 'roboto-regular.ttf'),
        ('MaterialIcons', 'materialicons-regular.otf'),
      ]) {
        await (FontLoader(item.$1)..addFont(
              File('$dir/${item.$2}').readAsBytes().then(ByteData.sublistView),
            ))
            .load();
      }
    }
  });
  testWidgets(
    'Publishing requires explicit action and excludes deselected email',
    (tester) async {
      final auth = verified.session();
      addTearDown(auth.dispose);
      final cards = support.TestCardsRepository()..cards.add(card);
      final service = SocialService();
      final c = await support.launch(
        tester,
        repository: auth,
        cardsRepository: cards,
        size: const Size(390, 1000),
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: ProviderScope(
            overrides: [
              networkServiceProvider.overrideWithValue(service),
              publicationsProvider.overrideWith((ref) => Stream.value([])),
            ],
            child: const RepaintBoundary(
              key: ValueKey('socialCapture'),
              child: ResonApp(),
            ),
          ),
        ),
      );
      c.read(routerProvider).go('/cards/${card.id}/share');
      await tester.pumpAndSettle();
      expect(service.calls, isEmpty);
      final email = find.widgetWithText(FilterChip, 'Correo de contacto');
      await tester.ensureVisible(email);
      await tester.tap(email);
      await tester.pumpAndSettle();
      final publish = find.widgetWithText(FilledButton, 'Publicar y crear QR');
      await tester.ensureVisible(publish);
      await tester.tap(publish);
      await tester.pumpAndSettle();
      expect(service.calls.single['action'], 'publish');
      expect(service.calls.single['fields'], isNot(contains('email')));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Shared destination survives authentication', (tester) async {
    final auth = support.TestAuthRepository()..verified = true;
    addTearDown(auth.dispose);
    final c = await support.launch(tester, repository: auth);
    final service = SocialService();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: ProviderScope(
          overrides: [
            networkServiceProvider.overrideWithValue(service),
            publicationsProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const RepaintBoundary(
            key: ValueKey('socialCapture'),
            child: ResonApp(),
          ),
        ),
      ),
    );
    c.read(routerProvider).go('/receive/abc');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('email')), findsOneWidget);
    await auth.signIn('test@example.com', 'password');
    await tester.pumpAndSettle();
    expect(find.text('Una nueva conexión'), findsOneWidget);
    await captureSocial(tester, 'received');
    expect(service.calls, isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Recipient accepts a request explicitly and sees confirmation', (
    tester,
  ) async {
    final auth = verified.session();
    addTearDown(auth.dispose);
    final c = await support.launch(
      tester,
      repository: auth,
      size: const Size(390, 1000),
    );
    final service = SocialService();
    final doc = SocialDoc('connection', {
      'members': ['owner', 'other'],
      'requester': 'other',
      'recipient': 'owner',
      'names': {'other': 'María', 'owner': 'Alex'},
      'cards': {'other': 'shared'},
      'status': 'pending',
      'updatedAt': Timestamp.now(),
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: ProviderScope(
          overrides: [
            networkServiceProvider.overrideWithValue(service),
            connectionsProvider.overrideWith((ref) => Stream.value([doc])),
            receivedProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const RepaintBoundary(
            key: ValueKey('socialCapture'),
            child: ResonApp(),
          ),
        ),
      ),
    );
    c.read(routerProvider).go('/network');
    await tester.pumpAndSettle();
    expect(service.calls, isEmpty);
    await captureSocial(tester, 'network');
    final accept = find.widgetWithText(FilledButton, 'Aceptar');
    await tester.ensureVisible(accept);
    await tester.tap(accept);
    await tester.pumpAndSettle();
    expect(service.calls.single['decision'], 'accept');
    expect(find.text('Una conexión con propósito'), findsOneWidget);
    await captureSocial(tester, 'connection-success');
    expect(tester.takeException(), isNull);
  });
}
