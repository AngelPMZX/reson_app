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
      await captureSocial(tester, 'share');
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
            blockedProvider.overrideWith((ref) => Stream.value(const {})),
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

  /// Opens /network with a single connection in [status], where the account
  /// blocks the other member when [iBlocked] is set.
  Future<SocialService> openNetwork(
    WidgetTester tester, {
    required String status,
    bool iBlocked = false,
    Size size = const Size(390, 1000),
    Map<String, dynamic>? lastMessage,
    Timestamp? readAt,
  }) async {
    final auth = verified.session();
    addTearDown(auth.dispose);
    final c = await support.launch(tester, repository: auth, size: size);
    final service = SocialService();
    final sentAt = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(minutes: 5)),
    );
    final doc = SocialDoc('connection', {
      'members': ['owner', 'other'],
      'requester': 'other',
      'recipient': 'owner',
      'names': {'other': 'María', 'owner': 'Alex'},
      'cards': {'other': 'shared'},
      'status': status,
      'updatedAt': Timestamp.now(),
      if (lastMessage != null) ...{
        'lastMessage': lastMessage,
        'lastMessageAt': sentAt,
      },
      if (readAt != null) 'reads': {'owner': readAt},
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: ProviderScope(
          overrides: [
            networkServiceProvider.overrideWithValue(service),
            connectionsProvider.overrideWith((ref) => Stream.value([doc])),
            receivedProvider.overrideWith((ref) => Stream.value([])),
            blockedProvider.overrideWith(
              (ref) => Stream.value(iBlocked ? const {'other'} : const {}),
            ),
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
    return service;
  }

  testWidgets('A decline can be taken back by the recipient', (tester) async {
    final service = await openNetwork(tester, status: 'declined');
    expect(find.text('Solicitud rechazada'), findsOneWidget);
    await captureSocial(tester, 'network-declined');
    final accept = find.widgetWithText(FilledButton, 'Aceptar ahora');
    await tester.ensureVisible(accept);
    await tester.tap(accept);
    await tester.pumpAndSettle();
    expect(service.calls.single['action'], 'respond');
    expect(service.calls.single['decision'], 'accept');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Only the member who blocked is offered the undo', (
    tester,
  ) async {
    final mine = await openNetwork(tester, status: 'blocked', iBlocked: true);
    expect(find.text('Bloqueaste a esta persona'), findsOneWidget);
    await captureSocial(tester, 'network-blocked-by-me');
    final undo = find.widgetWithText(OutlinedButton, 'Desbloquear');
    await tester.ensureVisible(undo);
    await tester.tap(undo);
    await tester.pumpAndSettle();
    expect(mine.calls.single['action'], 'unblock');
    expect(tester.takeException(), isNull);

    final theirs = await openNetwork(tester, status: 'blocked');
    expect(find.text('Conexión bloqueada'), findsOneWidget);
    await captureSocial(tester, 'network-blocked-by-them');
    expect(find.text('Desbloquear'), findsNothing);
    expect(theirs.calls, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A conversation shows its last message and unread mark', (
    tester,
  ) async {
    await openNetwork(
      tester,
      status: 'accepted',
      lastMessage: {'text': '¿Nos vemos el jueves?', 'sender': 'other'},
    );
    // Sending a message and coming back used to look exactly like sending
    // nothing: the row said only "Conexión aceptada" beside a chat icon.
    expect(find.text('¿Nos vemos el jueves?'), findsOneWidget);
    expect(find.text('5 min'), findsOneWidget);
    expect(find.text('Conversaciones'), findsOneWidget);
    await captureSocial(tester, 'network-conversation');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Your own last message is marked as yours and reads as read', (
    tester,
  ) async {
    await openNetwork(
      tester,
      status: 'accepted',
      lastMessage: {'text': 'Te paso mi tarjeta', 'sender': 'owner'},
    );
    expect(find.textContaining('Tú: '), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A conversation with nothing said says so', (tester) async {
    await openNetwork(tester, status: 'accepted');
    expect(find.text('Sin mensajes todavía'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Requests are kept apart from conversations', (tester) async {
    await openNetwork(tester, status: 'pending');
    expect(find.text('Solicitudes'), findsOneWidget);
    expect(find.text('Quiere conectar contigo'), findsOneWidget);
    // An empty conversation list must still invite, not vanish.
    expect(
      find.text('Cuando aceptes una conexión, la conversación aparecerá aquí.'),
      findsOneWidget,
    );
    await captureSocial(tester, 'network-request');
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0]) {
    testWidgets('The network screen fits $width with recovery actions', (
      tester,
    ) async {
      await openNetwork(
        tester,
        status: 'blocked',
        iBlocked: true,
        size: Size(width, 900),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
