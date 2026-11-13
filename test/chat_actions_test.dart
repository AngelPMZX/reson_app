import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'chat_design_test.dart' show openChat;

/// One stored message. [extra] carries whatever the case under test needs:
/// a quote, an edit stamp, or the withdrawn mark.
Map<String, dynamic> message(
  String sender,
  String text, {
  int minute = 30,
  Map<String, dynamic> extra = const {},
}) => {
  'sender': sender,
  'text': text,
  'createdAt': Timestamp.fromDate(DateTime(2026, 11, 11, 9, minute)),
  ...extra,
};

Future<void> hold(WidgetTester tester, String text) async {
  await tester.longPress(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  Map<String, dynamic> at(String sender, String text, DateTime when) => {
    'sender': sender,
    'text': text,
    'createdAt': Timestamp.fromDate(when),
  };

  testWidgets('The thread says where it turns a page', (tester) async {
    final now = DateTime.now();
    await openChat(
      tester,
      messages: [
        at('owner', 'Y esto es de hoy', now.subtract(const Duration(hours: 1))),
        at('other', 'Esto fue ayer', now.subtract(const Duration(days: 1))),
        at(
          'other',
          'Y esto, la semana pasada',
          now.subtract(const Duration(days: 8)),
        ),
      ],
    );
    // The date is written once above each day instead of on every bubble,
    // which is what the hour beside a message used to repeat.
    expect(find.text('Hoy'), findsOneWidget);
    expect(find.text('Ayer'), findsOneWidget);
    // Anything older than yesterday is named outright, and no bubble carries
    // a date any more.
    expect(find.textContaining('/'), findsNothing);
  });

  testWidgets('A run of messages from one person reads as one turn', (
    tester,
  ) async {
    final now = DateTime.now();
    await openChat(
      tester,
      messages: [
        at('other', 'Y otra mas', now),
        at('other', 'Una cosa mas', now.subtract(const Duration(minutes: 1))),
        at('owner', 'Hola', now.subtract(const Duration(minutes: 30))),
      ],
    );
    // Three messages, one day: exactly one separator, and the grouping
    // arithmetic survives a thread that never turns a page.
    expect(find.text('Hoy'), findsOneWidget);
    expect(find.text('Y otra mas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Someone else\'s message can be answered, not corrected', (
    tester,
  ) async {
    await openChat(tester, messages: [message('other', '¿Nos vemos?')]);
    await hold(tester, '¿Nos vemos?');
    expect(find.text('Responder'), findsOneWidget);
    expect(find.text('Copiar texto'), findsOneWidget);
    // Correcting or withdrawing what you did not write is not on offer, and
    // the backend refuses it too.
    expect(find.text('Editar'), findsNothing);
    expect(find.text('Eliminar'), findsNothing);
  });

  testWidgets('Answering says so, and the reply carries the quote', (
    tester,
  ) async {
    final service = await openChat(
      tester,
      messages: [message('other', '¿Nos vemos?')],
    );
    await hold(tester, '¿Nos vemos?');
    await tester.tap(find.text('Responder'));
    await tester.pumpAndSettle();
    // The composer has to show what it is about to answer; otherwise a reply
    // looks exactly like a new message.
    expect(find.text('Respondiendo a'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'El jueves me sirve.');
    await tester.tap(find.byIcon(Icons.arrow_upward));
    await tester.pumpAndSettle();
    final sent = service.calls.last;
    expect(sent['action'], 'message');
    expect(sent['replyTo'], 'm0');
    expect(sent['text'], 'El jueves me sirve.');
    // And the banner steps aside once the reply is gone.
    expect(find.text('Respondiendo a'), findsNothing);
  });

  testWidgets('An answer in progress can be called off', (tester) async {
    await openChat(tester, messages: [message('other', '¿Nos vemos?')]);
    await hold(tester, '¿Nos vemos?');
    await tester.tap(find.text('Responder'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Respondiendo a'), findsNothing);
  });

  testWidgets('Your own message can be corrected in place', (tester) async {
    final service = await openChat(
      tester,
      messages: [message('owner', 'Hola Maria')],
    );
    await hold(tester, 'Hola Maria');
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    expect(find.text('Editando un mensaje'), findsOneWidget);
    // The composer starts from what was written, so a correction is a small
    // change rather than typing the whole thing again.
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Hola Maria',
    );
    // Saving a correction is a different act from sending, and the button
    // says which one it is.
    expect(find.byIcon(Icons.check), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Hola María');
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    expect(service.calls.last, {
      'action': 'editMessage',
      'connectionId': 'chat',
      'messageId': 'm0',
      'text': 'Hola María',
    });
    expect(find.text('Editando un mensaje'), findsNothing);
  });

  testWidgets('Your own message can be withdrawn', (tester) async {
    final service = await openChat(
      tester,
      messages: [message('owner', 'Me equivoqué')],
    );
    await hold(tester, 'Me equivoqué');
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    expect(service.calls.last, {
      'action': 'deleteMessage',
      'connectionId': 'chat',
      'messageId': 'm0',
    });
  });

  testWidgets('A withdrawn message leaves a trace and offers nothing', (
    tester,
  ) async {
    await openChat(
      tester,
      messages: [
        message('owner', '', extra: const {'deleted': true}),
      ],
    );
    // The row stays so the thread still reads in order, but the words are
    // gone and there is nothing left to do to it.
    expect(find.text('Mensaje eliminado'), findsOneWidget);
    await hold(tester, 'Mensaje eliminado');
    expect(find.text('Responder'), findsNothing);
    expect(find.text('Eliminar'), findsNothing);
  });

  testWidgets('A corrected message says it was corrected', (tester) async {
    await openChat(
      tester,
      messages: [
        message(
          'owner',
          'Hola María',
          extra: {
            'editedAt': Timestamp.fromDate(DateTime(2026, 11, 11, 9, 31)),
          },
        ),
      ],
    );
    expect(find.textContaining('editado'), findsOneWidget);
  });

  testWidgets('A quote survives the message it answers being withdrawn', (
    tester,
  ) async {
    await openChat(
      tester,
      messages: [
        message(
          'owner',
          'El jueves me sirve.',
          minute: 40,
          extra: const {
            'replyTo': {'id': 'm1', 'sender': 'other', 'text': '¿Nos vemos?'},
          },
        ),
        message('other', '', minute: 30, extra: const {'deleted': true}),
      ],
    );
    // The quote is a copy stored with the reply, so the answer still makes
    // sense after the question is taken back.
    expect(find.text('¿Nos vemos?'), findsOneWidget);
    expect(find.text('Mensaje eliminado'), findsOneWidget);
  });
}
