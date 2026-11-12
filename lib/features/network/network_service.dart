import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/firebase/firebase_bootstrap.dart';

final networkServiceProvider = Provider((ref) => NetworkService());

class NetworkService {
  Future<Map<String, dynamic>> act(
    String action,
    Map<String, dynamic> data,
  ) async {
    final result = await FirebaseFunctions.instance
        .httpsCallable(
          'socialAction',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 45)),
        )
        .call({'action': action, ...data});
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> shared(String id) async {
    final result = await FirebaseFunctions.instance
        .httpsCallable('getSharedCard')
        .call({'publicId': id});
    return Map<String, dynamic>.from(result.data as Map);
  }
}

final sharedCardProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>(
      (ref, id) => ref.watch(networkServiceProvider).shared(id),
    );
final publicationsProvider =
    StreamProvider.autoDispose<
      List<QueryDocumentSnapshot<Map<String, dynamic>>>
    >((ref) {
      final uid = ref.watch(authSessionProvider).asData?.value?.uid;
      if (uid == null) return Stream.value([]);
      return FirebaseFirestore.instance
          .collection('users/$uid/publications')
          .snapshots()
          .map((s) => s.docs);
    });

/// How many connections or saved cards one page of the network screen holds.
///
/// Both lists used to stream the whole collection and sort it on the device, so
/// opening the screen cost one read per contact the account had ever made. They
/// now grow a page at a time and the screen offers to load the next one.
const networkPageSize = 25;

/// How much of a network list the screen currently asks for.
class NetworkPageSize extends Notifier<int> {
  @override
  int build() => networkPageSize;
  void grow() => state += networkPageSize;
}

final connectionsPageProvider = NotifierProvider<NetworkPageSize, int>(
  NetworkPageSize.new,
);
final receivedPageProvider = NotifierProvider<NetworkPageSize, int>(
  NetworkPageSize.new,
);

final connectionsProvider =
    StreamProvider.autoDispose<
      List<QueryDocumentSnapshot<Map<String, dynamic>>>
    >((ref) {
      final uid = ref.watch(authSessionProvider).asData?.value?.uid;
      if (uid == null) return Stream.value([]);
      // Ordering server-side needs the composite index in
      // firestore.indexes.json; deploy firestore:indexes alongside this build.
      return FirebaseFirestore.instance
          .collection('connections')
          .where('members', arrayContains: uid)
          .orderBy('updatedAt', descending: true)
          .limit(ref.watch(connectionsPageProvider))
          .snapshots()
          .map((s) => s.docs);
    });
final receivedProvider =
    StreamProvider.autoDispose<
      List<QueryDocumentSnapshot<Map<String, dynamic>>>
    >((ref) {
      final uid = ref.watch(authSessionProvider).asData?.value?.uid;
      if (uid == null) return Stream.value([]);
      return FirebaseFirestore.instance
          .collection('users/$uid/received')
          .orderBy('savedAt', descending: true)
          .limit(ref.watch(receivedPageProvider))
          .snapshots()
          .map((s) => s.docs);
    });

/// One conversation's state.
final connectionProvider = StreamProvider.autoDispose
    .family<DocumentSnapshot<Map<String, dynamic>>, String>(
      (ref, id) =>
          FirebaseFirestore.instance.doc('connections/$id').snapshots(),
    );

const chatPageSize = 50;

/// How many messages of a conversation are on screen.
class MessagesPageSize extends Notifier<int> {
  MessagesPageSize(this.connectionId);
  final String connectionId;
  @override
  int build() => chatPageSize;
  void grow() => state += chatPageSize;
}

final messagesPageProvider =
    NotifierProvider.family<MessagesPageSize, int, String>(
      MessagesPageSize.new,
    );

/// A conversation's newest messages, newest first.
///
/// The chat used to hold its own Firestore handles and rebuild the stream from
/// `setState`, which left it impossible to drive from a test. Reading them
/// through providers matches the rest of the module and makes the screen
/// testable without a backend.
final messagesProvider = StreamProvider.autoDispose
    .family<List<QueryDocumentSnapshot<Map<String, dynamic>>>, String>((
      ref,
      id,
    ) {
      return FirebaseFirestore.instance
          .collection('connections/$id/messages')
          .orderBy('createdAt', descending: true)
          .limit(ref.watch(messagesPageProvider(id)))
          .snapshots()
          .map((s) => s.docs);
    });

/// The member of a connection who is not you.
String otherMember(Map<String, dynamic> d, String? uid) =>
    (d['members'] as List).firstWhere((v) => v != uid, orElse: () => '')
        as String;

/// The name a connection recorded for [member] when it was made.
String memberName(Map<String, dynamic> d, String member) =>
    (d['names'] as Map?)?[member] as String? ?? 'Reson';

/// Whether this connection has something the account has not read.
///
/// Unread is derived rather than stored: there is a last message, somebody
/// else sent it, and either no read marker exists or it predates the message.
bool connectionIsUnread(Map<String, dynamic> d, String? uid) {
  final last = d['lastMessage'] as Map<String, dynamic>?;
  final at = d['lastMessageAt'] as Timestamp?;
  if (last == null || at == null || last['sender'] == uid) return false;
  final read = (d['reads'] as Map?)?[uid] as Timestamp?;
  return read == null || read.compareTo(at) < 0;
}

/// How many conversations are waiting, for the badge on the bar.
///
/// Counted over the loaded page rather than the whole collection: Firestore
/// cannot compare two fields of the same document server-side, so a true count
/// would mean reading every connection on every launch.
final unreadCountProvider = Provider.autoDispose<int>((ref) {
  final uid = ref.watch(authSessionProvider).asData?.value?.uid;
  final docs = ref.watch(connectionsProvider).asData?.value ?? const [];
  return docs
      .where(
        (d) =>
            d.data()['status'] == 'accepted' &&
            connectionIsUnread(d.data(), uid),
      )
      .length;
});

/// Saved cards the account has blocked, so the screen can offer to undo its own
/// block without the connection ever recording who blocked whom.
final blockedProvider = StreamProvider.autoDispose<Set<String>>((ref) {
  final uid = ref.watch(authSessionProvider).asData?.value?.uid;
  if (uid == null) return Stream.value(const {});
  return FirebaseFirestore.instance
      .collection('users/$uid/blocks')
      .snapshots()
      .map((s) => s.docs.map((d) => d.id).toSet());
});
String networkError(Object error, bool es) {
  final code = error is FirebaseFunctionsException
      ? error.code
      : error is FirebaseException
      ? error.code
      : '';
  return switch (code) {
    'not-found' =>
      es
          ? 'La tarjeta ya no está disponible.'
          : 'This card is no longer available.',
    'resource-exhausted' =>
      es
          ? 'Espera un momento antes de volver a intentarlo.'
          : 'Please wait before trying again.',
    'permission-denied' =>
      es
          ? 'Esta acción no está disponible para esta conexión.'
          : 'This action is unavailable for this connection.',
    'unauthenticated' =>
      es
          ? 'Inicia sesión y verifica tu correo.'
          : 'Sign in and verify your email.',
    'failed-precondition' =>
      es
          ? 'Publica tu tarjeta primero. La conexión también puede haber sido cerrada.'
          : 'Publish your card first. This connection may also have been closed.',
    _ =>
      es
          ? 'No pudimos confirmar la operación. Revisa tu conexión e inténtalo de nuevo.'
          : 'We could not confirm the action. Check your connection and retry.',
  };
}
