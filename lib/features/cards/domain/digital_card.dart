import 'professional_profile.dart';

class DigitalCard {
  const DigitalCard({
    required this.id,
    required this.label,
    required this.displayName,
    required this.role,
    required this.company,
    required this.email,
    required this.phone,
    required this.website,
    required this.primaryHex,
    this.kind = 'work',
    this.layout = 'signature',
    this.bio = '',
    this.photoPath = '',
    this.visibleFields = defaultFields,
    this.professional = const ProfessionalProfile(),
  });
  static const defaultFields = [
    'photo',
    'role',
    'company',
    'email',
    'phone',
    'website',
    'bio',
    'location',
    'linkedin',
    'skills',
    'experience',
    'education',
    'sector',
    'specialty',
    'workMode',
    'projects',
    'certifications',
  ];
  final String kind, layout, bio, photoPath;
  final ProfessionalProfile professional;
  final List<String> visibleFields;
  bool shows(String field) => visibleFields.contains(field);
  DigitalCard withIdAndPhoto(String id, String photoPath) => DigitalCard(
    id: id,
    label: label,
    displayName: displayName,
    role: role,
    company: company,
    email: email,
    phone: phone,
    website: website,
    primaryHex: primaryHex,
    kind: kind,
    layout: layout,
    bio: bio,
    photoPath: photoPath,
    professional: professional,
    visibleFields: List.unmodifiable(visibleFields),
  );
  final String id;
  final String label;
  final String displayName;
  final String role;
  final String company;
  final String email;
  final String phone;
  final String website;
  final String primaryHex;
}

abstract interface class CardsRepository {
  Stream<List<DigitalCard>> watchCards();
  Stream<String?> watchActiveCardId();
  Future<void> save(DigitalCard card);
  Future<void> select(String cardId);
  String newId();
}
