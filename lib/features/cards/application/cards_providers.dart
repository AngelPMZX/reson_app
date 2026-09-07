import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/firebase/firebase_bootstrap.dart';
import '../data/firestore_cards_repository.dart';
import '../domain/digital_card.dart';

final cardsRepositoryProvider = FutureProvider.autoDispose<CardsRepository?>((
  ref,
) async {
  final user = ref.watch(authSessionProvider).asData?.value;
  if (user == null || !user.emailVerified) return null;
  await ref.watch(authRepositoryProvider.future);
  return FirestoreCardsRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
    user.uid,
  );
});

final cardsProvider = StreamProvider.autoDispose<List<DigitalCard>>((
  ref,
) async* {
  if (!ref.mounted) return;
  final user = ref.watch(authSessionProvider).asData?.value;
  if (user == null || !user.emailVerified) {
    yield const [];
    return;
  }
  final repository = await ref.watch(cardsRepositoryProvider.future);
  if (!ref.mounted) return;
  if (repository == null) {
    yield const [];
    return;
  }
  yield* repository.watchCards();
});

final activeCardIdProvider = StreamProvider.autoDispose<String?>((ref) async* {
  if (!ref.mounted) return;
  final user = ref.watch(authSessionProvider).asData?.value;
  if (user == null || !user.emailVerified) {
    yield null;
    return;
  }
  final repository = await ref.watch(cardsRepositoryProvider.future);
  if (!ref.mounted) return;
  if (repository == null) {
    yield null;
    return;
  }
  yield* repository.watchActiveCardId();
});

final activeCardProvider = Provider<DigitalCard?>((ref) {
  final user = ref.watch(authSessionProvider).asData?.value;
  if (user == null || !user.emailVerified) return null;
  final cards = ref.watch(cardsProvider).asData?.value ?? [];
  final id = ref.watch(activeCardIdProvider).asData?.value;
  if (cards.isEmpty) return null;
  for (final card in cards) {
    if (card.id == id) return card;
  }
  return cards.first;
});
