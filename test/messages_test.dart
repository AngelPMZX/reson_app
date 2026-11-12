import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reson/app/reson_app.dart';
import 'auth_flow_test.dart' as support;
import 'social_flow_test.dart' show SocialDoc, SocialService;
import 'verification_cards_test.dart' as verified;

/// One accepted conversation with [name], optionally carrying a last message.
SocialDoc _thread(
  String id,
  String name, {
  Map<String, dynamic>? last,
  int minutesAgo = 5,
  bool read = false,
}) {
  final at = Timestamp.fromDate(
    DateTime.now().subtract(Duration(minutes: minutesAgo)),
  );
  return SocialDoc(id, {
    'members': ['owner', id],
    'requester': id,
    'recipient': 'owner',
    'names': {id: name, 'owner': 'Alex'},
    'cards': {id: 'shared'},
    'status': 'accepted',
    'updatedAt': at,
    if (last != null) ...{'lastMessage': last, 'lastMessageAt': at},
    if (read)
      'reads': {
        'owner': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 1)),
        ),
      },
  });
}

Future<void> openMessages(
  WidgetTester tester,
  List<SocialDoc> threads, {
  Size size = const Size(390, 900),
}) async {
  final auth = verified.session();
  addTearDown(auth.dispose);
  final c = await support.launch(
    tester,
    repository: auth,
    size: size,
    connections: threads,
    networkService: SocialService(),
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: const RepaintBoundary(
        key: ValueKey('messagesCapture'),
        child: ResonApp(),
      ),
    ),
  );
  c.read(routerProvider).go('/messages');
  await tester.pumpAndSettle();
}

Future<void> capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('RESON_SCREENSHOTS')) return;
  await tester.runAsync(() async {
    final image = await tester
        .renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('messagesCapture')),
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

  testWidgets('Conversations have a destination of their own', (tester) async {
    await openMessages(tester, [
      _thread(
        'maria',
        'María',
        last: {'text': '¿Nos vemos el jueves?', 'sender': 'maria'},
      ),
      _thread(
        'luis',
        'Luis',
        last: {'text': 'Te paso mi tarjeta', 'sender': 'owner'},
        minutesAgo: 180,
        read: true,
      ),
      _thread('ana', 'Ana', minutesAgo: 0),
    ]);
    expect(find.text('María'), findsOneWidget);
    expect(find.text('¿Nos vemos el jueves?'), findsOneWidget);
    expect(find.text('5 min'), findsOneWidget);
    // Your own last message is prefixed, and a thread with nothing said yet
    // still earns a row.
    expect(find.textContaining('Tú: '), findsOneWidget);
    expect(find.text('3 h'), findsOneWidget);
    expect(find.text('Sin mensajes todavía'), findsOneWidget);
    await capture(tester, 'messages');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Only unread conversations carry the badge', (tester) async {
    await openMessages(tester, [
      _thread('maria', 'María', last: {'text': 'Hola', 'sender': 'maria'}),
      _thread(
        'luis',
        'Luis',
        last: {'text': 'Hola', 'sender': 'luis'},
        read: true,
      ),
      _thread('ana', 'Ana', last: {'text': 'Hola', 'sender': 'owner'}),
    ]);
    // Unread is derived: somebody else spoke and no later read marker exists.
    // One of the three qualifies, so the bar shows a count of one.
    expect(find.widgetWithText(Badge, '1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Search narrows the list by who you are talking to', (
    tester,
  ) async {
    await openMessages(tester, [
      _thread('maria', 'María', last: {'text': 'Hola', 'sender': 'maria'}),
      _thread('luis', 'Luis', last: {'text': 'Hola', 'sender': 'luis'}),
    ]);
    await tester.enterText(find.byType(TextField), 'lui');
    await tester.pumpAndSettle();
    expect(find.text('Luis'), findsOneWidget);
    expect(find.text('María'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(
      find.text('Ninguna conversación coincide con esa búsqueda.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('With nothing to read, it points at the network', (tester) async {
    await openMessages(tester, []);
    expect(find.text('Aún no hay conversaciones'), findsOneWidget);
    await capture(tester, 'messages-empty');
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0, 900.0]) {
    testWidgets('Messages fits $width', (tester) async {
      await openMessages(tester, [
        _thread(
          'maria',
          'María Fernanda de la Torre',
          last: {
            'text': 'Un mensaje largo para comprobar que la fila aguanta.',
            'sender': 'maria',
          },
        ),
      ], size: Size(width, 820));
      expect(tester.takeException(), isNull);
    });
  }
}
