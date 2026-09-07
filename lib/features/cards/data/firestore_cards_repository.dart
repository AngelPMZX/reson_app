import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/digital_card.dart';

class FirestoreCardsRepository implements CardsRepository {
  FirestoreCardsRepository(this._db, this._auth, this._uid);
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final String _uid;
  DocumentReference<Map<String, dynamic>> get _profile =>
      _db.collection('users').doc(_uid);
  CollectionReference<Map<String, dynamic>> get _cards =>
      _profile.collection('cards');

  Future<void> _requireVerifiedOwner() async {
    final user = _auth.currentUser;
    if (user == null || user.uid != _uid || !user.emailVerified) {
      throw StateError('Verified owner required');
    }
    var token = await user.getIdTokenResult();
    if (token.claims?['email_verified'] != true) {
      token = await user.getIdTokenResult(true);
    }
    if (token.claims?['email_verified'] != true ||
        _auth.currentUser?.uid != _uid) {
      throw StateError('Verified owner required');
    }
  }

  @override
  String newId() => _cards.doc().id;

  @override
  Stream<List<DigitalCard>> watchCards() async* {
    await _requireVerifiedOwner();
    yield* _cards
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) {
                final data = doc.data();
                final identity = data['identity'] as Map<String, dynamic>;
                final contact = data['contact'] as Map<String, dynamic>;
                final theme = data['theme'] as Map<String, dynamic>;
                return DigitalCard(
                  id: doc.id,
                  label: data['label'] as String,
                  displayName: identity['displayName'] as String,
                  role: identity['jobTitle'] as String,
                  company: identity['company'] as String,
                  email: contact['email'] as String,
                  phone: contact['phone'] as String,
                  website: contact['website'] as String,
                  primaryHex: theme['primaryHex'] as String,
                  kind: data['kind'] as String? ?? 'work',
                  layout: data['layout'] as String? ?? 'signature',
                  bio: data['bio'] as String? ?? '',
                  photoPath: data['photoPath'] as String? ?? '',
                  visibleFields: data['visibleFields'] == null
                      ? DigitalCard.defaultFields
                      : List<String>.from(data['visibleFields'] as List),
                );
              })
              .toList(growable: false),
        );
  }

  @override
  Stream<String?> watchActiveCardId() async* {
    await _requireVerifiedOwner();
    yield* _profile.snapshots().map(
      (snapshot) => snapshot.data()?['activeCardId'] as String?,
    );
  }

  @override
  Future<void> save(DigitalCard card) async {
    await _requireVerifiedOwner();
    final reference = _cards.doc(card.id);
    await _db.runTransaction((transaction) async {
      final profile = await transaction.get(_profile);
      final existing = await transaction.get(reference);
      transaction.set(reference, {
        'ownerId': _uid,
        'label': card.label,
        'kind': card.kind,
        'layout': card.layout,
        'bio': card.bio,
        'photoPath': card.photoPath,
        'visibleFields': card.visibleFields,
        'identity': {
          'displayName': card.displayName,
          'jobTitle': card.role,
          'company': card.company,
        },
        'contact': {
          'email': card.email,
          'phone': card.phone,
          'website': card.website,
        },
        'theme': {'primaryHex': card.primaryHex},
        'schemaVersion': 1,
        'createdAt':
            existing.data()?['createdAt'] ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!profile.exists) {
        transaction.set(_profile, {
          'displayName': _auth.currentUser?.displayName ?? '',
          'activeCardId': card.id,
          'schemaVersion': 1,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  @override
  Future<void> select(String cardId) async {
    await _requireVerifiedOwner();
    await _db.runTransaction((transaction) async {
      final card = await transaction.get(_cards.doc(cardId));
      if (!card.exists) throw StateError('Card no longer exists');
      transaction.update(_profile, {
        'activeCardId': cardId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
