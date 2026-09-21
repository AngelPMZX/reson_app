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
final connectionsProvider =
    StreamProvider.autoDispose<
      List<QueryDocumentSnapshot<Map<String, dynamic>>>
    >((ref) {
      final uid = ref.watch(authSessionProvider).asData?.value?.uid;
      if (uid == null) return Stream.value([]);
      return FirebaseFirestore.instance
          .collection('connections')
          .where('members', arrayContains: uid)
          .snapshots()
          .map(
            (s) => s.docs
              ..sort(
                (a, b) => (b.data()['updatedAt'] as Timestamp).compareTo(
                  a.data()['updatedAt'] as Timestamp,
                ),
              ),
          );
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
          .snapshots()
          .map((s) => s.docs);
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
