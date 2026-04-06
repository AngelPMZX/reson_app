class ProfileModel {
  final String id;
  final String name;
  final String email;
  final String bio;
  final String photoUrl;
  final bool isPublic;
  final Map<String, String> socialLinks; // Ej: {'instagram': '@usuario'}

  ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.bio = '',
    this.photoUrl = '',
    this.isPublic = true,
    this.socialLinks = const {},
  });

  // Convertimos un mapa de Firebase (JSON) a nuestro objeto ProfileModel
  factory ProfileModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ProfileModel(
      id: documentId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      bio: map['bio'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      isPublic: map['isPublic'] ?? true,
      socialLinks: Map<String, String>.from(map['socialLinks'] ?? {}),
    );
  }

  // Convertimos nuestro objeto a un mapa para guardarlo en Firebase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'bio': bio,
      'photoUrl': photoUrl,
      'isPublic': isPublic,
      'socialLinks': socialLinks,
    };
  }
}
