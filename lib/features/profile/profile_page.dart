import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/firebase/firebase_bootstrap.dart';
import '../../core/theme/reson_chrome.dart';
import '../../core/theme/reson_motion.dart';
import '../../core/theme/reson_palette.dart';
import '../../core/theme/reson_surfaces.dart';
import '../../l10n/generated/app_localizations.dart';
import '../cards/domain/digital_card.dart';
import '../cards/presentation/professional_summary.dart';
import 'personal_profile.dart';
import 'profile_avatar.dart';

/// Who you are, shown rather than typed.
///
/// This screen used to be the edit form itself: a banner and then twenty
/// inputs, so you could fill yourself in but never look at yourself. The form
/// still exists behind the edit button; what changed is that the profile has
/// a face now, and the career data the app already collects is finally
/// presented somewhere other than a published card.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context)!;
    return ref
        .watch(personalProfileProvider)
        .when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, _) => Scaffold(
            body: ResonNotice(
              icon: Icons.cloud_off_outlined,
              text: s.cardLoadError,
              action: FilledButton(
                onPressed: () => ref.invalidate(personalProfileProvider),
                child: Text(s.retry),
              ),
            ),
          ),
          data: (profile) => _Profile(profile: profile),
        );
  }
}

/// Drops the fields a profile already states above its career block.
List<String> withoutIdentityChips(List<String> fields) =>
    fields.where((f) => f != 'location' && f != 'workMode').toList();

class _Profile extends ConsumerWidget {
  const _Profile({this.profile});
  final PersonalProfile? profile;

  /// The career sections read from a card, so the profile reuses the same
  /// presentation the cards already have instead of growing a second one.
  DigitalCard _asCard(PersonalProfile p) => DigitalCard(
    id: 'profile',
    label: '',
    // Location and work mode are already identity chips under the name, so
    // the career block hides them rather than saying them twice.
    visibleFields: withoutIdentityChips(DigitalCard.defaultFields),
    displayName: p.value('name'),
    role: p.value('role'),
    company: p.value('company'),
    email: p.value('email'),
    phone: p.value('phone'),
    website: p.value('website'),
    primaryHex: '#C8102E',
    bio: p.value('bio'),
    professional: p.professional,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final user = ref.watch(authSessionProvider).asData?.value;
    final p = profile ?? PersonalProfile(fields: const {});
    final name = p.value('name').isEmpty
        ? (user?.name ?? s.navProfile)
        : p.value('name');
    final empty = p.value('role').isEmpty && p.value('bio').isEmpty;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: ResonSpace.huge),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      ResonSpace.xl,
                      ResonSpace.xl,
                      ResonSpace.xl,
                      ResonSpace.lg,
                    ),
                    child: ResonHeader(
                      leading: IconButton(
                        tooltip: s.settings,
                        icon: const Icon(Icons.tune),
                        onPressed: () => context.go('/settings'),
                      ),
                    ),
                  ),
                  ProfileHero(
                    name: name,
                    role: p.value('role'),
                    company: p.value('company'),
                    location: p.professional.location,
                    workMode: p.professional.workMode,
                    photoPath: p.photoPath,
                    photoSource: p.photoSource,
                    imageUrl: user?.googlePhotoUrl,
                    badge: _availabilityLabel(s, p.availability),
                    action: FilledButton.icon(
                      onPressed: () => context.go('/profile/edit'),
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(s.profileEdit),
                    ),
                  ),
                  const SizedBox(height: ResonSpace.xl),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ResonSpace.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (empty)
                          ResonPanel(
                            child: ResonNotice(
                              icon: Icons.auto_awesome_outlined,
                              tone: scheme.primary,
                              title: s.profileEmptyTitle,
                              text: s.profileEmptyBody,
                              action: FilledButton(
                                onPressed: () => context.go('/profile/edit'),
                                child: Text(s.profileEdit),
                              ),
                            ),
                          )
                        else ...[
                          if (p.value('bio').isNotEmpty)
                            _Block(
                              title: s.profileAbout,
                              child: Text(
                                p.value('bio'),
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.copyWith(height: 1.6),
                              ),
                            ),
                          if (p.value('languages').isNotEmpty)
                            _Block(
                              title: s.profileLanguages,
                              child: _Tags(value: p.value('languages')),
                            ),
                          if (p.value('services').isNotEmpty)
                            _Block(
                              title: s.profileServices,
                              child: _Tags(value: p.value('services')),
                            ),
                          // The career section brings its own surface, and
                          // says nothing at all when there is nothing to
                          // say. Unfolded here: on a profile the career is
                          // the subject, not a detail behind a disclosure.
                          ProfessionalSummary(card: _asCard(p), open: true),
                        ],
                        const SizedBox(height: ResonSpace.lg),
                        _Block(
                          title: s.profileVerified,
                          child: Row(
                            children: [
                              Icon(
                                Icons.verified_outlined,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: ResonSpace.md),
                              Expanded(child: Text(user?.email ?? '')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _availabilityLabel(AppLocalizations s, String availability) =>
      switch (availability) {
        'projects' => s.profileStatusProjects,
        'employment' => s.profileStatusEmployment,
        'unavailable' => s.profileStatusUnavailable,
        _ => null,
      };
}

/// The top of a person: a brand band, their face over it, and who they are.
///
/// Shared so that looking at somebody else uses the same shape as looking at
/// yourself, rather than a card standing in for a person.
class ProfileHero extends StatelessWidget {
  const ProfileHero({
    super.key,
    required this.name,
    this.role = '',
    this.company = '',
    this.location = '',
    this.workMode = '',
    this.photoPath = '',
    this.photoSource = 'none',
    this.imageUrl,
    this.badge,
    this.action,
    this.inset = true,
  });
  final String name, role, company, location, workMode, photoPath, photoSource;

  /// A remote picture: your provider's, or the public copy of a published
  /// card when this is somebody else.
  final String? imageUrl;
  final String? badge;
  final Widget? action;

  /// Keeps the screen's own gutter. False where the caller already pads, as
  /// the network shell does.
  final bool inset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = [role, company].where((v) => v.isNotEmpty).join(' · ');
    final place = [location, workMode].where((v) => v.isNotEmpty).join(' · ');
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 132,
          margin: EdgeInsets.symmetric(horizontal: inset ? ResonSpace.xl : 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ResonRadius.lg),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ResonPalette.wine, ResonPalette.deepWine],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            inset ? ResonSpace.xl + ResonSpace.sm : ResonSpace.sm,
            96,
            inset ? ResonSpace.xl + ResonSpace.sm : ResonSpace.sm,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.surface, width: 4),
                ),
                child: ProfileAvatar(
                  name: name,
                  size: 88,
                  path: photoPath,
                  // A remote url is served over https either way, so the
                  // avatar treats both the same.
                  source: (imageUrl ?? '').isNotEmpty ? 'google' : photoSource,
                  imageUrl: imageUrl,
                ),
              ),
              const SizedBox(height: ResonSpace.md),
              Text(
                name,
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(letterSpacing: -1),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: ResonSpace.xs),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (place.isNotEmpty || badge != null) ...[
                const SizedBox(height: ResonSpace.md),
                Wrap(
                  spacing: ResonSpace.sm,
                  runSpacing: ResonSpace.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (place.isNotEmpty)
                      _Chip(icon: Icons.place_outlined, label: place),
                    if (badge != null)
                      _Chip(
                        icon: Icons.bolt_outlined,
                        label: badge!,
                        tone: scheme.primary,
                      ),
                  ],
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: ResonSpace.lg),
                Align(alignment: Alignment.centerLeft, child: action),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.icon, this.tone});

  /// Optional: a tag is a word, and a bullet beside every one of them reads
  /// as decoration rather than meaning.
  final IconData? icon;
  final String label;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colour = tone ?? scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ResonSpace.md,
        vertical: ResonSpace.sm - 2,
      ),
      decoration: BoxDecoration(
        color: tone == null
            ? scheme.surfaceContainerHigh
            : scheme.primaryContainer,
        borderRadius: BorderRadius.circular(ResonRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: colour),
            const SizedBox(width: ResonSpace.xs + 2),
          ],
          // Flexible, or a long skill on a 320 pixel phone pushes the chip
          // past the edge instead of ellipsising inside it.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: colour),
            ),
          ),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: ResonSpace.lg),
    child: ResonPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: ResonSpace.md),
          child,
        ],
      ),
    ),
  );
}

/// A comma separated field, shown as the list it already is.
class _Tags extends StatelessWidget {
  const _Tags({required this.value});
  final String value;

  @override
  Widget build(BuildContext context) {
    final items = value
        .split(RegExp('[,·]'))
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: ResonSpace.sm,
      runSpacing: ResonSpace.sm,
      children: [for (final item in items) _Chip(label: item)],
    );
  }
}
