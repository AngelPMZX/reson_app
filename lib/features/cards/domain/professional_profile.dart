class CareerEntry {
  const CareerEntry({
    this.title = '',
    this.organization = '',
    this.period = '',
    this.details = '',
  });
  final String title, organization, period, details;
  Map<String, dynamic> toMap() => {
    'title': title,
    'organization': organization,
    'period': period,
    'details': details,
  };
  factory CareerEntry.fromMap(Map<String, dynamic> value) => CareerEntry(
    title: value['title'] as String? ?? '',
    organization: value['organization'] as String? ?? '',
    period: value['period'] as String? ?? '',
    details: value['details'] as String? ?? '',
  );
}

class ProfessionalProfile {
  const ProfessionalProfile({
    this.sector = '',
    this.specialty = '',
    this.workMode = '',
    this.projects = const [],
    this.certifications = const [],
    this.location = '',
    this.linkedin = '',
    this.skills = '',
    this.experience = const [],
    this.education = const [],
  });
  final String location, linkedin, skills, sector, specialty, workMode;
  final List<CareerEntry> experience, education, projects, certifications;
  bool get isEmpty =>
      sector.isEmpty &&
      specialty.isEmpty &&
      workMode.isEmpty &&
      projects.isEmpty &&
      certifications.isEmpty &&
      location.isEmpty &&
      linkedin.isEmpty &&
      skills.isEmpty &&
      experience.isEmpty &&
      education.isEmpty;
  Map<String, dynamic> toMap() => {
    'sector': sector,
    'specialty': specialty,
    'workMode': workMode,
    'projects': projects.map((e) => e.toMap()).toList(),
    'certifications': certifications.map((e) => e.toMap()).toList(),
    'location': location,
    'linkedin': linkedin,
    'skills': skills,
    'experience': experience.map((e) => e.toMap()).toList(),
    'education': education.map((e) => e.toMap()).toList(),
  };
  factory ProfessionalProfile.fromMap(Map<String, dynamic>? value) {
    if (value == null) return const ProfessionalProfile();
    List<CareerEntry> entries(String key) => (value[key] as List? ?? [])
        .map((e) => CareerEntry.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);
    return ProfessionalProfile(
      sector: value['sector'] as String? ?? '',
      specialty: value['specialty'] as String? ?? '',
      workMode: value['workMode'] as String? ?? '',
      projects: entries('projects'),
      certifications: entries('certifications'),
      location: value['location'] as String? ?? '',
      linkedin: value['linkedin'] as String? ?? '',
      skills: value['skills'] as String? ?? '',
      experience: entries('experience'),
      education: entries('education'),
    );
  }
}
