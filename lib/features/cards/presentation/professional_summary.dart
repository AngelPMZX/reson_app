import 'package:flutter/material.dart';
import '../../../core/theme/reson_surfaces.dart';
import '../../../core/theme/reson_tokens.dart';
import 'package:url_launcher/link.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/digital_card.dart';
import '../domain/professional_profile.dart';

class ProfessionalSummary extends StatelessWidget {
  const ProfessionalSummary({super.key, required this.card});
  final DigitalCard card;
  @override
  Widget build(BuildContext context) {
    final p = card.professional;
    final s = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final extras = {
      'sector': (s.careerSector, p.sector),
      'specialty': (s.careerSpecialty, p.specialty),
      'workMode': (s.careerWorkMode, p.workMode),
    };
    final hasExtras = extras.entries.any(
      (e) => card.shows(e.key) && e.value.$2.isNotEmpty,
    );
    final hasProjects = card.shows('projects') && p.projects.isNotEmpty;
    final hasCertifications =
        card.shows('certifications') && p.certifications.isNotEmpty;
    final hasExperience = card.shows('experience') && p.experience.isNotEmpty;
    final hasEducation = card.shows('education') && p.education.isNotEmpty;
    final hasLocation = card.shows('location') && p.location.isNotEmpty;
    final hasSkills = card.shows('skills') && p.skills.isNotEmpty;
    final uri = Uri.tryParse(p.linkedin);
    final hasLinkedin =
        card.shows('linkedin') &&
        uri != null &&
        uri.scheme == 'https' &&
        ['www.linkedin.com', 'linkedin.com'].contains(uri.host) &&
        uri.userInfo.isEmpty;
    if (!hasExtras &&
        !hasProjects &&
        !hasCertifications &&
        !hasExperience &&
        !hasEducation &&
        !hasLocation &&
        !hasSkills &&
        !hasLinkedin) {
      return const SizedBox.shrink();
    }
    Widget entries(String title, IconData icon, List<CareerEntry> values) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: ResonSpace.xl),
            Row(
              children: [
                Icon(icon, size: 19, color: scheme.primary),
                const SizedBox(width: ResonSpace.md),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            for (final e in values)
              Padding(
                padding: const EdgeInsets.only(top: 16, left: 8),
                child: Container(
                  padding: const EdgeInsets.only(left: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: scheme.outlineVariant, width: 2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        e.organization,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      if (e.period.isNotEmpty)
                        Text(
                          e.period,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: scheme.primary, height: 1.8),
                        ),
                      if (e.details.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            e.details,
                            style: const TextStyle(height: 1.5),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: ExpansionTile(
          key: ValueKey('professional_${card.id}'),
          shape: const Border(),
          expansionAnimationStyle: AnimationStyle(
            duration: context.motion.expand,
          ),
          leading: Icon(Icons.work_outline_rounded, color: scheme.primary),
          title: Text(s.professionalProfile),
          subtitle: Text(
            s.exploreProfile,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final e in extras.entries)
                    if (card.shows(e.key) && e.value.$2.isNotEmpty)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(e.value.$1),
                        subtitle: Text(e.value.$2),
                      ),
                  if (hasProjects)
                    entries(
                      s.careerProjects,
                      Icons.folder_outlined,
                      p.projects,
                    ),
                  if (hasCertifications)
                    entries(
                      s.careerCertifications,
                      Icons.workspace_premium_outlined,
                      p.certifications,
                    ),
                  if (hasLocation)
                    Text(
                      p.location,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  if (hasLinkedin)
                    Link(
                      uri: uri,
                      target: LinkTarget.blank,
                      builder: (context, follow) => TextButton.icon(
                        onPressed: follow,
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: Text(s.openLinkedin),
                      ),
                    ),
                  if (hasSkills)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final skill
                              in p.skills
                                  .split(',')
                                  .map((v) => v.trim())
                                  .where((v) => v.isNotEmpty))
                            Chip(
                              label: Text(skill),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    ),
                  if (hasExperience)
                    entries(
                      s.experience,
                      Icons.business_center_outlined,
                      p.experience,
                    ),
                  if (hasEducation)
                    entries(s.education, Icons.school_outlined, p.education),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
