import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reson/features/network/chat_media.dart';
import 'package:reson/features/network/network_service.dart';

import 'chat_design_test.dart' show openChat;

/// A real 2x2 crimson PNG, so the content-type sniffing the uploader does and
/// the decode the layout depends on both run on bytes that are actually an
/// image rather than on a stand-in.
final png = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAEklEQVR4nGM4IaB3QkCP'
    'AUIBAB8eBBlIimilAAAAAElFTkSuQmCC',
  ),
);

class FakeMedia extends ChatMedia {
  const FakeMedia(this.uploads);
  final List<String> uploads;
  @override
  Future<void> upload(
    String connectionId,
    String messageId,
    Uint8List bytes,
  ) async => uploads.add(path(connectionId, messageId));
}

Map<String, dynamic> message(String sender, Map<String, dynamic> extra) => {
  'sender': sender,
  'text': '',
  'createdAt': Timestamp.fromDate(DateTime(2026, 11, 11, 9, 30)),
  ...extra,
};

void main() {
  // Decoded pictures outlive the tree that asked for them, and the global
  // cache would hand a disposed widget a frame mid-teardown.
  tearDown(() {
    imageCache.clear();
    imageCache.clearLiveImages();
  });

  testWidgets('A chosen photo is shown before it is sent, and can be dropped', (
    tester,
  ) async {
    await openChat(
      tester,
      messages: const [],
      picker: () async => png,
      media: const FakeMedia([]),
    );
    await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined));
    await tester.pumpAndSettle();
    // Choosing is not sending: the picture waits where it can be seen and
    // called off.
    expect(find.text('Foto adjunta'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Foto adjunta'), findsNothing);
  });

  testWidgets('A photo goes up before the message that names it', (
    tester,
  ) async {
    final uploads = <String>[];
    final service = await openChat(
      tester,
      messages: const [],
      picker: () async => png,
      media: FakeMedia(uploads),
    );
    await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined));
    await tester.pumpAndSettle();
    // No words: a picture is a message on its own.
    await tester.tap(find.byIcon(Icons.arrow_upward));
    await tester.pumpAndSettle();
    expect(uploads, hasLength(1));
    final sent = service.calls.last;
    expect(sent['action'], 'message');
    expect(sent['text'], '');
    // The path the backend accepts is this very message's own object, so the
    // uploaded object and the named one have to agree.
    expect(sent['image'], uploads.single);
    expect(sent['image'], 'connections/chat/${sent['messageId']}');
    expect(find.text('Foto adjunta'), findsNothing);
  });

  testWidgets('A photo that cannot be read says so and sends nothing', (
    tester,
  ) async {
    final uploads = <String>[];
    final service = await openChat(
      tester,
      messages: const [],
      picker: () async => throw const FormatException('Unsupported photo'),
      media: FakeMedia(uploads),
    );
    await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined));
    await tester.pumpAndSettle();
    expect(
      find.text('Elige una imagen JPG, PNG o WebP de hasta 3 MB.'),
      findsOneWidget,
    );
    expect(uploads, isEmpty);
    expect(service.calls.where((c) => c['action'] == 'message'), isEmpty);
  });

  testWidgets('A received photo is drawn in its bubble', (tester) async {
    await openChat(
      tester,
      messages: [
        message('other', const {'image': 'connections/chat/m0'}),
      ],
      images: {'connections/chat/m0': png},
    );
    expect(find.byType(Image), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A photo that will not load leaves a legible gap', (
    tester,
  ) async {
    await openChat(
      tester,
      messages: [
        message('other', const {'image': 'connections/chat/m0'}),
      ],
    );
    // No override for this path, so the provider reaches the real bucket and
    // fails. A broken picture must not take the thread down with it.
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Correcting a message cannot gain a picture', (tester) async {
    await openChat(
      tester,
      messages: [
        {
          'sender': 'owner',
          'text': 'Hola',
          'createdAt': Timestamp.fromDate(DateTime(2026, 11, 11, 9, 30)),
        },
      ],
      picker: () async => png,
      media: const FakeMedia([]),
    );
    await tester.longPress(find.text('Hola'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    // The attachment is written once, with the message: an edit only touches
    // the words.
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.add_photo_alternate_outlined),
          )
          .onPressed,
      isNull,
    );
  });

  for (final width in [320.0, 390.0, 900.0]) {
    testWidgets('A thread with pictures fits $width', (tester) async {
      await openChat(
        tester,
        size: Size(width, 820),
        picker: () async => png,
        media: const FakeMedia([]),
        messages: [
          message('other', const {
            'image': 'connections/chat/m0',
            'text': 'Mira el stand, quedó enorme de verdad.',
          }),
        ],
        images: {'connections/chat/m0': png},
      );
      await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined));
      await tester.pumpAndSettle();
      // Decoding is real work on a real thread, so the frames that matter
      // only exist once the test lets the outside world run. Without this the
      // layout under test is the placeholder's, not the picture's.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 80)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Foto adjunta'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  group('What a conversation row says it last held', () {
    test('a picture with no caption borrows the reader\'s language', () {
      expect(
        lastMessageBody(
          {
            'lastMessage': {'text': '', 'sender': 'other', 'image': true},
          },
          'owner',
          none: 'Sin mensajes',
          youPrefix: 'Tú: ',
          photo: 'Foto',
        ),
        'Foto',
      );
    });

    test('a caption wins over the fallback', () {
      expect(
        lastMessageBody(
          {
            'lastMessage': {
              'text': 'Mira esto',
              'sender': 'owner',
              'image': true,
            },
          },
          'owner',
          none: 'Sin mensajes',
          youPrefix: 'Tú: ',
          photo: 'Foto',
        ),
        'Tú: Mira esto',
      );
    });

    test('nothing said at all is not a picture', () {
      expect(
        lastMessageBody(
          const {},
          'owner',
          none: 'Sin mensajes',
          youPrefix: 'Tú: ',
          photo: 'Foto',
        ),
        'Sin mensajes',
      );
    });
  });
}
