import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/reson_motion.dart';
import '../../core/theme/reson_skeleton.dart';
import '../../core/theme/reson_surfaces.dart';
import '../../l10n/generated/app_localizations.dart';
import 'network_service.dart';
import 'network_widgets.dart';

/// Finding somebody you have not met in person.
///
/// Until now the only way to connect was to be handed a QR or a link, which
/// made this a digital business card rather than a network. Nobody is listed
/// for having published a card: the directory holds only people who asked to
/// be in it, and only what they had already made public.
class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});
  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return NetworkShell(
      title: s.discoverTitle,
      subtitle: s.discoverSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _search,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: (v) => setState(() => _query = v.trim()),
            decoration: InputDecoration(
              hintText: s.discoverHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: s.messagesClearSearch,
                      onPressed: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
          ),
          const SizedBox(height: ResonSpace.xl),
          if (searchQuery(_query).term.isEmpty)
            ResonNotice(
              icon: Icons.person_search_outlined,
              text: s.discoverPrompt,
            )
          else
            ref
                .watch(directoryProvider(_query))
                .when(
                  loading: () => const ResonCardSkeleton(),
                  error: (e, _) => ResonNotice(
                    icon: Icons.cloud_off_outlined,
                    text: networkErrorText(context, e),
                  ),
                  data: (people) => people.isEmpty
                      ? ResonNotice(
                          icon: Icons.search_off_outlined,
                          text: s.discoverNoResults,
                        )
                      : Column(
                          children: [
                            for (final (i, p) in people.indexed)
                              ResonStagger(
                                index: i,
                                child: _Person(data: p.data()),
                              ),
                          ],
                        ),
                ),
        ],
      ),
    );
  }
}

class _Person extends StatelessWidget {
  const _Person({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = data['name'] as String? ?? '';
    final where = [
      data['role'],
      data['company'],
    ].whereType<String>().where((v) => v.isNotEmpty).join(' · ');
    final place = [
      data['sector'],
      data['location'],
    ].whereType<String>().where((v) => v.isNotEmpty).join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: ResonSpace.md),
      child: ResonPress(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(ResonRadius.lg),
            onTap: () => context.go('/receive/${data['publicId']}'),
            child: ResonPanel(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                    child: Text(name.characters.firstOrNull ?? 'R'),
                  ),
                  const SizedBox(width: ResonSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (where.isNotEmpty)
                          Text(
                            where,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        if (place.isNotEmpty)
                          Text(
                            place,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: ResonSpace.sm),
                  Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
