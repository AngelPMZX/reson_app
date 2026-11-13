import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/firebase/firebase_bootstrap.dart';
import '../../core/theme/reson_chrome.dart';
import '../../core/theme/reson_motion.dart';
import '../../core/theme/reson_skeleton.dart';
import '../../core/theme/reson_surfaces.dart';
import '../../l10n/generated/app_localizations.dart';
import 'network_service.dart';
import 'network_widgets.dart';

/// Every conversation, newest first.
///
/// Conversations used to be rows inside the network screen, between pending
/// requests and saved cards, reachable only through a small icon. A thread you
/// talk in every day deserves its own place.
class MessagesPage extends ConsumerStatefulWidget {
  const MessagesPage({super.key});
  @override
  ConsumerState<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends ConsumerState<MessagesPage> {
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
    final uid = ref.watch(authSessionProvider).asData?.value?.uid;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: ResonSpace.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: ResonSpace.xl),
                  const ResonHeader(),
                  const SizedBox(height: ResonSpace.xl),
                  Text(
                    s.navMessages,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(letterSpacing: -1),
                  ),
                  const SizedBox(height: ResonSpace.lg),
                  TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v.trim()),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: s.messagesSearch,
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
                  Expanded(child: _list(context, uid, s)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _list(BuildContext context, String? uid, AppLocalizations s) => ref
      .watch(connectionsProvider)
      .when(
        loading: () => const ResonCardSkeleton(),
        error: (e, _) => ResonNotice(
          icon: Icons.cloud_off_outlined,
          text: networkErrorText(context, e),
        ),
        data: (docs) {
          final threads = docs.where((d) {
            if (d.data()['status'] != 'accepted') return false;
            if (_query.isEmpty) return true;
            final other = otherMember(d.data(), uid);
            return memberName(
              d.data(),
              other,
            ).toLowerCase().contains(_query.toLowerCase());
          }).toList();
          if (threads.isEmpty) {
            return ResonNotice(
              icon: _query.isEmpty
                  ? Icons.forum_outlined
                  : Icons.search_off_outlined,
              title: _query.isEmpty ? s.messagesEmptyTitle : null,
              text: _query.isEmpty ? s.messagesEmptyBody : s.messagesNoMatch,
              action: _query.isEmpty
                  ? FilledButton.icon(
                      onPressed: () => context.go('/network'),
                      icon: const Icon(Icons.hub_outlined),
                      label: Text(s.navNetwork),
                    )
                  : null,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: ResonSpace.huge),
            itemCount: threads.length + 1,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              indent: 56 + ResonSpace.md,
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: .4),
            ),
            itemBuilder: (context, i) => i == threads.length
                ? NetworkMore(
                    visible: docs.length >= ref.watch(connectionsPageProvider),
                    onPressed: () =>
                        ref.read(connectionsPageProvider.notifier).grow(),
                  )
                : ConversationRow(doc: threads[i], uid: uid),
          );
        },
      );
}

/// One conversation, laid out like any messaging app: who, what was said last,
/// when, and whether it is waiting for you.
class ConversationRow extends StatelessWidget {
  const ConversationRow({super.key, required this.doc, required this.uid});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final String? uid;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final d = doc.data();
    final other = otherMember(d, uid);
    final name = memberName(d, other);
    final at = d['lastMessageAt'] as Timestamp?;
    final unread = connectionIsUnread(d, uid);
    final body = lastMessageBody(
      d,
      uid,
      none: s.networkNoMessages,
      youPrefix: s.networkYouPrefix,
      photo: s.chatPhoto,
    );
    return ResonPress(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(ResonRadius.md),
          onTap: () => context.go('/chat/${doc.id}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ResonSpace.sm,
              vertical: ResonSpace.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResonAvatar(name: name, radius: 28),
                const SizedBox(width: ResonSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: unread
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                            ),
                          ),
                          if (at != null && at.millisecondsSinceEpoch > 0)
                            Text(
                              shortMoment(context, at.toDate()),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: unread
                                        ? scheme.primary
                                        : scheme.onSurfaceVariant,
                                    fontWeight: unread ? FontWeight.w700 : null,
                                  ),
                            ),
                        ],
                      ),
                      const SizedBox(height: ResonSpace.xs),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: unread
                                        ? scheme.onSurface
                                        : scheme.onSurfaceVariant,
                                    fontWeight: unread ? FontWeight.w600 : null,
                                  ),
                            ),
                          ),
                          if (unread)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: ResonSpace.sm,
                              ),
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: scheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
