import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/firebase/firebase_bootstrap.dart';
import '../cards/domain/digital_card.dart';
import '../cards/domain/professional_profile.dart';

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

/// What a typed query becomes: one term for Firestore, the rest for here.
///
/// Mirrors `searchQuery` in functions/domain.js. Only one `arrayContains` is
/// allowed per query, so the longest word goes to the server and the others
/// narrow the result on the device.
({String term, List<String> rest}) searchQuery(String text) {
  final words = _plain(
    text,
  ).split(RegExp('[^a-z0-9]+')).where((w) => w.length >= 2).toList();
  if (words.isEmpty) return (term: '', rest: const []);
  final longest = words.reduce((a, b) => b.length > a.length ? b : a);
  return (
    term: longest.substring(0, longest.length.clamp(0, 14)),
    rest: words.where((w) => w != longest).toList(),
  );
}

String _plain(String value) => value.toLowerCase().replaceAllMapped(
  RegExp('[áàäâãéèëêíìïîóòöôõúùüûñç]'),
  (m) => const {
    'á': 'a',
    'à': 'a',
    'ä': 'a',
    'â': 'a',
    'ã': 'a',
    'é': 'e',
    'è': 'e',
    'ë': 'e',
    'ê': 'e',
    'í': 'i',
    'ì': 'i',
    'ï': 'i',
    'î': 'i',
    'ó': 'o',
    'ò': 'o',
    'ö': 'o',
    'ô': 'o',
    'õ': 'o',
    'ú': 'u',
    'ù': 'u',
    'ü': 'u',
    'û': 'u',
    'ñ': 'n',
    'ç': 'c',
  }[m[0]]!,
);

/// People who asked to be findable, matching [query].
///
/// The directory holds only what its owner already published, and only while
/// they want to be in it: nobody is listed for having a card.
final directoryProvider = StreamProvider.autoDispose
    .family<List<QueryDocumentSnapshot<Map<String, dynamic>>>, String>((
      ref,
      query,
    ) {
      final parsed = searchQuery(query);
      if (parsed.term.isEmpty) return Stream.value([]);
      final uid = ref.watch(authSessionProvider).asData?.value?.uid;
      return FirebaseFirestore.instance
          .collection('directory')
          .where('terms', arrayContains: parsed.term)
          .limit(30)
          .snapshots()
          .map(
            (s) => s.docs.where((d) {
              if (d.id == uid) return false;
              if (parsed.rest.isEmpty) return true;
              final terms = List<String>.from(
                (d.data()['terms'] as List?) ?? const [],
              );
              return parsed.rest.every(terms.contains);
            }).toList(),
          );
    });

/// Whether this account is listed, and under which card.
final discoverableProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>?, String?>(
      (ref, uid) => uid == null
          ? Stream.value(null)
          : FirebaseFirestore.instance
                .doc('directory/$uid')
                .snapshots()
                .map((d) => d.data()),
    );

/// Rebuilds a card from the sanitised snapshot the backend publishes.
///
/// The receive screen and the wallet both draw somebody else's credential, so
/// the mapping lives here once. `photo` is dropped from the visible fields:
/// the bytes are served over HTTP by the public endpoint, not held locally.
DigitalCard cardFromSnapshot(Map<String, dynamic> p, String publicId) =>
    DigitalCard(
      id: publicId,
      label: p['label'] as String? ?? '',
      displayName: p['name'] as String? ?? '',
      role: p['role'] as String? ?? '',
      company: p['company'] as String? ?? '',
      email: p['email'] as String? ?? '',
      phone: p['phone'] as String? ?? '',
      website: p['website'] as String? ?? '',
      primaryHex: p['color'] as String? ?? '#C8102E',
      kind: p['kind'] as String? ?? 'work',
      layout: p['layout'] as String? ?? 'signature',
      bio: p['bio'] as String? ?? '',
      professional: ProfessionalProfile.fromMap(
        Map<String, dynamic>.from((p['professional'] as Map?) ?? const {}),
      ),
      visibleFields: List<String>.from(
        (p['visibleFields'] as List?) ?? const <String>[],
      )..remove('photo'),
    );

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

/// The backend code behind a failure, or an empty string.
///
/// The wording lives in the ARB files; this only says which message to read.
/// It used to pick between two hardcoded languages with a boolean, which made
/// a third language impossible without touching Dart.
String networkErrorCode(Object error) => error is FirebaseFunctionsException
    ? error.code
    : error is FirebaseException
    ? error.code
    : '';
