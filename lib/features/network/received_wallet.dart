import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/reson_motion.dart';
import '../../core/theme/reson_skeleton.dart';
import '../../core/theme/reson_surfaces.dart';
import '../../l10n/generated/app_localizations.dart';
import '../cards/presentation/card_preview.dart';
import 'network_service.dart';
import 'network_widgets.dart';

/// The cards other people handed you.
///
/// These were a list of two lines each — a name and a label — because saving
/// only kept those. The whole published snapshot is stored now, so the wallet
/// shows the credential its owner actually designed, which is the thing worth
/// keeping. Filters sit on top because a wallet you cannot sort through is
/// just a pile.
class ReceivedWallet extends ConsumerStatefulWidget {
  const ReceivedWallet({
    super.key,
    required this.busy,
    required this.onRemove,
    required this.onRefresh,
  });

  final bool busy;
  final void Function(String publicId) onRemove;

  /// Pulls the current version of one saved card. A saved card is a copy, so
  /// it ages: its owner can restyle it, change jobs, or take it down.
  final void Function(String publicId) onRefresh;

  @override
  ConsumerState<ReceivedWallet> createState() => _ReceivedWalletState();
}

class _ReceivedWalletState extends ConsumerState<ReceivedWallet> {
  final _search = TextEditingController();
  String _query = '';
  String _kind = 'all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(Map<String, dynamic> d) {
    final snapshot = (d['snapshot'] as Map?)?.cast<String, dynamic>();
    if (_kind != 'all' && (snapshot?['kind'] ?? 'work') != _kind) return false;
    if (_query.isEmpty) return true;
    final needle = _query.toLowerCase();
    // Cards are remembered by who gave them, where they work, or what the
    // owner called the card, so all three are searched.
    return [
      d['name'],
      d['label'],
      snapshot?['company'],
      snapshot?['role'],
      snapshot?['professional']?['location'],
    ].whereType<String>().any((v) => v.toLowerCase().contains(needle));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final kinds = {
      'all': s.homeAll,
      'work': s.homeWork,
      'freelance': s.homeFreelance,
      'personal': s.homePersonal,
    };
    return ref
        .watch(receivedProvider)
        .when(
          loading: () => const ResonCardSkeleton(),
          error: (e, _) => ResonNotice(
            icon: Icons.cloud_off_outlined,
            text: networkErrorText(context, e),
          ),
          data: (docs) {
            if (docs.isEmpty) {
              return NetworkPanel(
                child: ResonNotice(
                  icon: Icons.bookmark_border,
                  title: s.walletEmptyTitle,
                  text: s.walletEmptyBody,
                ),
              );
            }
            final visible = docs.where((d) => _matches(d.data())).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v.trim()),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: s.walletSearch,
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
                const SizedBox(height: ResonSpace.lg),
                // Wrap, not a rail: with four filters a scrolling row leaves
                // the last one off screen, the same call the home filters made.
                Wrap(
                  spacing: ResonSpace.sm,
                  runSpacing: ResonSpace.sm,
                  children: [
                    for (final entry in kinds.entries)
                      ChoiceChip(
                        key: Key('wallet-${entry.key}'),
                        label: Text(entry.value),
                        selected: _kind == entry.key,
                        onSelected: (_) => setState(() => _kind = entry.key),
                      ),
                  ],
                ),
                const SizedBox(height: ResonSpace.xl),
                if (visible.isEmpty)
                  NetworkPanel(
                    child: ResonNotice(
                      icon: Icons.search_off_outlined,
                      text: s.walletNoMatch,
                    ),
                  )
                else
                  for (final (i, d) in visible.indexed)
                    ResonStagger(
                      index: i,
                      child: _WalletCard(
                        doc: d,
                        busy: widget.busy,
                        onRemove: widget.onRemove,
                        onRefresh: widget.onRefresh,
                      ),
                    ),
                NetworkMore(
                  visible: docs.length >= ref.watch(receivedPageProvider),
                  onPressed: () =>
                      ref.read(receivedPageProvider.notifier).grow(),
                ),
              ],
            );
          },
        );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.doc,
    required this.busy,
    required this.onRemove,
    required this.onRefresh,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final bool busy;
  final void Function(String publicId) onRemove;
  final void Function(String publicId) onRefresh;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final d = doc.data();
    final snapshot = (d['snapshot'] as Map?)?.cast<String, dynamic>();
    final gone = d['active'] == false;
    return Padding(
      padding: const EdgeInsets.only(bottom: ResonSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ResonPress(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(ResonRadius.lg),
                onTap: () => context.go('/receive/${doc.id}'),
                // A card whose owner took it down is kept but shown faded,
                // rather than vanishing from the wallet without explanation.
                child: Opacity(
                  opacity: gone ? .45 : 1,
                  child: snapshot == null
                      // Saved before snapshots were kept: nothing to draw yet.
                      ? NetworkPanel(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(d['name'] as String? ?? ''),
                            subtitle: Text(d['label'] as String? ?? ''),
                          ),
                        )
                      : CardPreview(card: cardFromSnapshot(snapshot, doc.id)),
                ),
              ),
            ),
          ),
          const SizedBox(height: ResonSpace.sm),
          Row(
            children: [
              if (gone)
                Expanded(
                  child: Text(
                    s.walletUnavailable,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                const Spacer(),
              IconButton(
                tooltip: s.walletRefresh,
                icon: const Icon(Icons.refresh),
                onPressed: busy ? null : () => onRefresh(doc.id),
              ),
              IconButton(
                tooltip: s.walletRemove,
                icon: const Icon(Icons.bookmark_remove_outlined),
                onPressed: busy ? null : () => onRemove(doc.id),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
