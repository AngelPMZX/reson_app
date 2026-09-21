import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/firebase/firebase_bootstrap.dart';
import '../cards/domain/digital_card.dart';
import '../cards/domain/professional_profile.dart';

class PersonalProfile {
  PersonalProfile({
    Map<String, String> fields = const {},
    this.professional = const ProfessionalProfile(),
    this.photoPath = '',
    this.photoSource = 'google',
    this.availability = 'private',
  }) : fields = Map.unmodifiable(fields);
  final Map<String, String> fields;
  final ProfessionalProfile professional;
  final String photoPath, photoSource, availability;
  static const limits = {
    'name': 80,
    'role': 100,
    'company': 100,
    'bio': 240,
    'email': 254,
    'phone': 32,
    'website': 500,
    'languages': 180,
    'services': 240,
  };
  String value(String key) => fields[key] ?? '';
  Map<String, dynamic> toMap() => {
    for (final key in limits.keys) key: value(key),
    'professional': professional.toMap(),
    'photoPath': photoPath,
    'photoSource': photoSource,
    'availability': availability,
  };
  factory PersonalProfile.fromMap(Map<String, dynamic> data) => PersonalProfile(
    photoPath: data['photoPath'] as String? ?? '',
    photoSource: data['photoSource'] as String? ?? 'google',
    availability: data['availability'] as String? ?? 'private',
    fields: {for (final key in limits.keys) key: data[key] as String? ?? ''},
    professional: ProfessionalProfile.fromMap(
      data['professional'] as Map<String, dynamic>?,
    ),
  );
  DigitalCard newCard({
    required String fallbackName,
    required String fallbackEmail,
  }) => DigitalCard(
    id: '',
    label: '',
    displayName: value('name').isEmpty ? fallbackName : value('name'),
    role: value('role'),
    company: value('company'),
    bio: value('bio'),
    email: fields.containsKey('email') ? value('email') : fallbackEmail,
    phone: value('phone'),
    website: value('website'),
    primaryHex: '#D32945',
    photoPath: photoSource == 'upload' ? photoPath : '',
    professional: ProfessionalProfile.fromMap(professional.toMap()),
  );
}

abstract class PersonalProfileRepository {
  Stream<PersonalProfile?> watch();
  Future<void> save(PersonalProfile profile);
}

class FirebasePersonalProfileRepository implements PersonalProfileRepository {
  FirebasePersonalProfileRepository(this.uid);
  final String uid;
  DocumentReference<Map<String, dynamic>> get _doc =>
      FirebaseFirestore.instance.doc('users/$uid/settings/identity');
  void _check() {
    final u = FirebaseAuth.instance.currentUser;
    if (u?.uid != uid || u?.emailVerified != true) {
      throw StateError('Verified owner required');
    }
  }

  @override
  Stream<PersonalProfile?> watch() {
    _check();
    return _doc.snapshots().map(
      (s) => s.exists ? PersonalProfile.fromMap(s.data()!) : null,
    );
  }

  @override
  Future<void> save(PersonalProfile profile) async {
    _check();
    await _doc.set({
      ...profile.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

final personalProfileRepositoryProvider = Provider<PersonalProfileRepository?>((
  ref,
) {
  final user = ref.watch(authSessionProvider).asData?.value;
  if (user == null || !user.emailVerified) return null;
  return FirebasePersonalProfileRepository(user.uid);
});
final personalProfileProvider = StreamProvider.autoDispose<PersonalProfile?>((
  ref,
) {
  return ref.watch(personalProfileRepositoryProvider)?.watch() ??
      Stream.value(null);
});
