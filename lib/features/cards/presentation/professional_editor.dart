import 'package:flutter/material.dart';
import '../../../core/theme/reson_surfaces.dart';
import '../../../core/theme/reson_tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/professional_profile.dart';

class ProfessionalEditor extends StatefulWidget {
  const ProfessionalEditor({
    super.key,
    required this.initial,
    required this.onChanged,
    required this.enabled,
    required this.visible,
    required this.onVisibility,
    this.showVisibility = true,
  });
  final bool showVisibility;
  final ProfessionalProfile initial;
  final ValueChanged<ProfessionalProfile> onChanged;
  final bool enabled;
  final Set<String> visible;
  final void Function(String, bool) onVisibility;
  @override
  State<ProfessionalEditor> createState() => _ProfessionalEditorState();
}

class _CareerDraft {
  _CareerDraft(CareerEntry entry)
    : title = TextEditingController(text: entry.title),
      organization = TextEditingController(text: entry.organization),
      period = TextEditingController(text: entry.period),
      details = TextEditingController(text: entry.details);
  final key = UniqueKey();
  final TextEditingController title, organization, period, details;
  CareerEntry get value => CareerEntry(
    title: title.text.trim(),
    organization: organization.text.trim(),
    period: period.text.trim(),
    details: details.text.trim(),
  );
  void dispose() {
    for (final c in [title, organization, period, details]) {
      c.dispose();
    }
  }
}

class _ProfessionalEditorState extends State<ProfessionalEditor> {
  late final TextEditingController location,
      linkedin,
      skills,
      sector,
      specialty,
      workMode;
  late final List<_CareerDraft> experience, education, projects, certifications;
  @override
  void initState() {
    super.initState();
    sector = TextEditingController(text: widget.initial.sector);
    specialty = TextEditingController(text: widget.initial.specialty);
    workMode = TextEditingController(text: widget.initial.workMode);
    projects = widget.initial.projects.map(_CareerDraft.new).toList();
    certifications = widget.initial.certifications
        .map(_CareerDraft.new)
        .toList();
    location = TextEditingController(text: widget.initial.location);
    linkedin = TextEditingController(text: widget.initial.linkedin);
    skills = TextEditingController(text: widget.initial.skills);
    experience = widget.initial.experience.map(_CareerDraft.new).toList();
    education = widget.initial.education.map(_CareerDraft.new).toList();
  }

  @override
  void dispose() {
    sector.dispose();
    specialty.dispose();
    workMode.dispose();
    location.dispose();
    linkedin.dispose();
    skills.dispose();
    for (final e in [
      ...experience,
      ...education,
      ...projects,
      ...certifications,
    ]) {
      e.dispose();
    }
    super.dispose();
  }

  void _emit() => widget.onChanged(
    ProfessionalProfile(
      sector: sector.text.trim(),
      specialty: specialty.text.trim(),
      workMode: workMode.text.trim(),
      projects: projects.map((e) => e.value).toList(),
      certifications: certifications.map((e) => e.value).toList(),
      location: location.text.trim(),
      linkedin: linkedin.text.trim(),
      skills: skills.text.trim(),
      experience: experience.map((e) => e.value).toList(),
      education: education.map((e) => e.value).toList(),
    ),
  );
  Widget _field(
    TextEditingController c,
    String label,
    int max, {
    String? field,
    bool required = false,
  }) {
    final s = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: ResonSpace.lg),
      child: TextFormField(
        key: field == null ? null : Key('professional_$field'),
        controller: c,
        enabled: widget.enabled,
        maxLines: field == 'details' ? 3 : 1,
        onChanged: (_) => _emit(),
        decoration: InputDecoration(
          labelText: label,
          suffixIcon:
              widget.showVisibility &&
                  field != null &&
                  [
                    'location',
                    'linkedin',
                    'skills',
                    'sector',
                    'specialty',
                    'workMode',
                  ].contains(field)
              ? IconButton(
                  tooltip: widget.visible.contains(field)
                      ? s.designHideOnCard
                      : s.designShowOnCard,
                  onPressed: widget.enabled
                      ? () => widget.onVisibility(
                          field,
                          !widget.visible.contains(field),
                        )
                      : null,
                  icon: Icon(
                    widget.visible.contains(field)
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                )
              : null,
        ),
        validator: (raw) {
          final v = (raw ?? '').trim();
          if (required && v.isEmpty) return s.required;
          if (v.length > max) return s.maxLength;
          if (field == 'linkedin' && v.isNotEmpty) {
            final uri = Uri.tryParse(v);
            if (uri == null ||
                uri.scheme != 'https' ||
                !['linkedin.com', 'www.linkedin.com'].contains(uri.host) ||
                uri.userInfo.isNotEmpty) {
              return s.invalidLinkedin;
            }
          }
          return null;
        },
      ),
    );
  }

  Widget _section(String id, String title, List<_CareerDraft> list) {
    final s = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.showVisibility)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: ResonSpace.lg),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        if (widget.showVisibility)
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            value: widget.visible.contains(id),
            onChanged: widget.enabled
                ? (v) => widget.onVisibility(id, v)
                : null,
          ),
        for (final entry in list)
          Container(
            key: entry.key,
            margin: const EdgeInsets.only(bottom: ResonSpace.lg),
            padding: const EdgeInsets.all(ResonSpace.lg),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(ResonRadius.md),
            ),
            child: Column(
              children: [
                _field(
                  entry.title,
                  id == 'experience'
                      ? s.careerRole
                      : id == 'education'
                      ? s.careerDegree
                      : s.careerItemTitle,
                  100,
                  required: true,
                ),
                _field(
                  entry.organization,
                  id == 'education'
                      ? s.careerSchool
                      : id == 'experience'
                      ? s.company
                      : s.careerOrganization,
                  100,
                  required: true,
                ),
                _field(entry.period, s.careerPeriod, 60),
                _field(entry.details, s.careerDetails, 300),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: widget.enabled
                        ? () {
                            setState(() => list.remove(entry));
                            _emit();
                            entry.dispose();
                          }
                        : null,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text(s.removeEntry),
                  ),
                ),
              ],
            ),
          ),
        if (list.length < 4 &&
            experience.length +
                    education.length +
                    projects.length +
                    certifications.length <
                8)
          OutlinedButton.icon(
            key: Key('add_$id'),
            onPressed: widget.enabled
                ? () {
                    setState(() => list.add(_CareerDraft(const CareerEntry())));
                    _emit();
                  }
                : null,
            icon: const Icon(Icons.add),
            label: Text(
              id == 'experience'
                  ? s.addExperience
                  : id == 'education'
                  ? s.addEducation
                  : s.addCareerItem,
            ),
          ),
        const SizedBox(height: ResonSpace.xl),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final motion = context.motion;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: ResonSpace.xl),
        Text(
          widget.showVisibility ? s.professionalTitle : s.profileCareerTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: ResonSpace.sm),
        Text(
          widget.showVisibility ? s.professionalHint : s.profileCareerHint,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: ResonSpace.xl),
        _field(sector, s.careerSector, 100, field: 'sector'),
        Text(
          s.careerSectorHint,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: ResonSpace.lg),
        _field(specialty, s.careerSpecialty, 180, field: 'specialty'),
        _field(workMode, s.careerWorkMode, 100, field: 'workMode'),
        _field(location, s.location, 100, field: 'location'),
        _field(linkedin, 'LinkedIn', 500, field: 'linkedin'),
        _field(skills, s.skills, 180, field: 'skills'),
        _section('experience', s.experience, experience),
        _section('education', s.education, education),
        _section('projects', s.careerProjects, projects),
        _section('certifications', s.careerCertifications, certifications),
      ],
    );
    // AnimatedSize re-dirties itself during its own layout when handed a zero
    // duration, so reduced motion drops the wrapper instead of stilling it.
    if (motion.isStill) return body;
    return AnimatedSize(
      duration: motion.expand,
      alignment: Alignment.topCenter,
      child: body,
    );
  }
}
