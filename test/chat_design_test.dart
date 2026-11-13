import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reson/app/reson_app.dart';
import 'package:reson/core/theme/reson_theme.dart';
import 'package:reson/features/network/network_service.dart';
import 'auth_flow_test.dart' as support;
import 'social_flow_test.dart' show SocialDoc, SocialService;
import 'verification_cards_test.dart' as verified;

// ignore: subtype_of_sealed_class
class _ConnectionDoc extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  _ConnectionDoc(this.value);
  final Map<String, dynamic>? value;
  @override
  Map<String, dynamic>? data() => value;
}

Map<String, dynamic> _message(String sender, String text, int minute) => {
  'sender': sender,
  'text': text,
  'createdAt': Timestamp.fromDate(DateTime(2026, 11, 11, 9, minute)),
};

/// Opens a conversation with [messages], newest first.
Future<SocialService> openChat(
  WidgetTester tester, {
  required List<Map<String, dynamic>> messages,
  String status = 'accepted',
  Size size = const Size(390, 900),
  bool dark = false,
  DateTime? theyReadAt,
}) async {
  final auth = verified.session();
  addTearDown(auth.dispose);
  final c = await support.launch(tester, repository: auth, size: size);
  // The default follows the device, so drive the toggle until it is the mode
  // under test rather than assuming one tap lands on it.
  final wanted = dark ? ThemeMode.dark : ThemeMode.light;
  while (c.read(appearanceProvider) != wanted) {
    await c.read(appearanceProvider.notifier).toggle();
  }
  final service = SocialService();
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: ProviderScope(
        overrides: [
          networkServiceProvider.overrideWithValue(service),
          connectionProvider('chat').overrideWith(
            (ref) => Stream.value(
              _ConnectionDoc({
                'members': ['owner', 'other'],
                'requester': 'other',
                'recipient': 'owner',
                'names': {'other': 'María', 'owner': 'Alex'},
                'cards': {'other': 'shared'},
                'status': status,
                if (theyReadAt != null)
                  'reads': {'other': Timestamp.fromDate(theyReadAt)},
              }),
            ),
          ),
          messagesProvider('chat').overrideWith(
            (ref) => Stream.value([
              for (final (i, m) in messages.indexed) SocialDoc('m$i', m),
            ]),
          ),
        ],
        child: const RepaintBoundary(
          key: ValueKey('chatCapture'),
          child: ResonApp(),
        ),
      ),
    ),
  );
  c.read(routerProvider).go('/chat/chat');
  await tester.pumpAndSettle();
  return service;
}

Future<void> capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('RESON_SCREENSHOTS')) return;
  await tester.runAsync(() async {
    final image = await tester
        .renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('chatCapture')),
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

  testWidgets('A conversation shows both sides and its own actions', (
    tester,
  ) async {
    await openChat(
      tester,
      messages: [
        _message('owner', 'Perfecto, te paso mi tarjeta.', 42),
        _message('other', '¿Nos vemos el jueves?', 38),
        _message('owner', 'Hola María, un gusto saludarte.', 30),
      ],
    );
    expect(find.text('María'), findsOneWidget);
    expect(find.text('Ver tarjeta'), findsOneWidget);
    expect(find.text('¿Nos vemos el jueves?'), findsOneWidget);
    // The back link replaced an AppBar that reserved 132px for the global
    // controls; both must now be on screen at once. It points at Messages,
    // which is where a thread is reached from.
    expect(find.text('Mensajes'), findsOneWidget);
    expect(find.byKey(const Key('themeToggle')), findsOneWidget);
    expect(find.byKey(const Key('languageToggle')), findsOneWidget);
    await capture(tester, 'chat');
    expect(tester.takeException(), isNull);
  });

  testWidgets('A conversation holds up in dark mode', (tester) async {
    await openChat(
      tester,
      dark: true,
      messages: [
        _message('owner', 'Perfecto, te paso mi tarjeta.', 42),
        _message('other', '¿Nos vemos el jueves?', 38),
        _message('owner', 'Hola María, un gusto saludarte.', 30),
      ],
    );
    expect(find.text('María'), findsOneWidget);
    await capture(tester, 'chat-dark');
    expect(tester.takeException(), isNull);
  });

  testWidgets('An empty conversation invites the first message', (
    tester,
  ) async {
    await openChat(tester, messages: []);
    expect(
      find.text('Una buena conversación empieza con un hola.'),
      findsOneWidget,
    );
    await capture(tester, 'chat-empty');
    expect(tester.takeException(), isNull);
  });

  testWidgets('A conversation that is not accepted says so instead', (
    tester,
  ) async {
    await openChat(tester, messages: [], status: 'pending');
    expect(find.text('La conversación no está habilitada.'), findsOneWidget);
    expect(find.text('Ver tarjeta'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('What you sent says whether it has been read', (tester) async {
    await openChat(
      tester,
      // They opened the thread at 09:40: the 09:30 message is read, the
      // 09:42 one is not, and their own message never carries a mark.
      theyReadAt: DateTime(2026, 11, 11, 9, 40),
      messages: [
        _message('owner', 'Perfecto, te paso mi tarjeta.', 42),
        _message('other', '¿Nos vemos el jueves?', 38),
        _message('owner', 'Hola María, un gusto saludarte.', 30),
      ],
    );
    // The data for this was already stored and never shown.
    // One of yours is read, the other is not. Theirs never carries a mark.
    expect(find.byIcon(Icons.done_all), findsOneWidget);
    expect(find.byIcon(Icons.done), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Nothing is read until they have opened the thread', (
    tester,
  ) async {
    await openChat(tester, messages: [_message('owner', 'Hola María.', 30)]);
    expect(find.byIcon(Icons.done_all), findsNothing);
    expect(find.byIcon(Icons.done), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0, 900.0]) {
    testWidgets('The chat fits $width', (tester) async {
      await openChat(
        tester,
        messages: [
          _message('owner', 'Un mensaje con bastante texto para medir.', 42),
          _message('other', 'Y una respuesta igual de larga por el otro.', 38),
        ],
        size: Size(width, 820),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
