import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/reson_skeleton.dart';
import '../../core/theme/reson_surfaces.dart';
import '../../core/theme/reson_motion.dart';
import '../../core/theme/reson_tokens.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/firebase/firebase_bootstrap.dart';
import 'network_service.dart';
import 'network_widgets.dart';

class NetworkPage extends ConsumerStatefulWidget {
  const NetworkPage({super.key});
  @override
  ConsumerState<NetworkPage> createState() => _NetworkPageState();
}

class _NetworkPageState extends ConsumerState<NetworkPage> {
  AudioPlayer? player;
  @override
  void dispose() {
    player?.dispose();
    super.dispose();
  }

  bool sound = false, busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) {
        setState(() => sound = p.getBool('connectionSound') ?? false);
      }
    });
  }

  Future<void> respond(String id, String decision) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref.read(networkServiceProvider).act('respond', {
        'connectionId': id,
        'decision': decision,
      });
      if (!mounted) return;
      if (decision == 'accept') {
        setState(() => busy = false);
        if (sound) {
          try {
            player ??= AudioPlayer();
            await player!.play(
              AssetSource('sounds/connected.wav'),
              volume: .35,
            );
          } catch (_) {
            /* A browser may block audio; connection success is unaffected. */
          }
        }
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ResonRadius.xl),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: .5, end: 1),
                  duration: ctx.motion.entrance,
                  curve: ctx.motion.overshoot,
                  builder: (_, v, child) =>
                      Transform.scale(scale: v, child: child),
                  child: Icon(
                    Icons.handshake_rounded,
                    size: 64,
                    color: Theme.of(ctx).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: ResonSpace.xl),
                Text(
                  tr(
                    ctx,
                    'Una conexión con propósito',
                    'A meaningful connection',
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: ResonSpace.md),
                Text(
                  tr(
                    ctx,
                    'Ya pueden conversar y explorar sus tarjetas.',
                    'You can now chat and explore each other’s cards.',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/chat/$id');
                },
                child: Text(tr(ctx, 'Abrir conversación', 'Open conversation')),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = networkErrorText(context, e));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> unblock(String id) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref.read(networkServiceProvider).act('unblock', {
        'connectionId': id,
      });
    } catch (e) {
      if (mounted) setState(() => error = networkErrorText(context, e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final uid = ref.watch(authSessionProvider).asData?.value?.uid;
    final connections = ref.watch(connectionsProvider);
    final received = ref.watch(receivedProvider);
    // Only the member who placed a block may lift it, so the screen offers the
    // undo from the account's own block list rather than from the connection.
    final blocked =
        ref.watch(blockedProvider).asData?.value ?? const <String>{};
    return NetworkShell(
      title: tr(context, 'Tu red', 'Your network'),
      subtitle: tr(
        context,
        'Personas que conoces. Conversaciones que importan.',
        'People you know. Conversations that matter.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: ResonSpace.md),
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (busy) const LinearProgressIndicator(),
          connections.when(
            loading: () => const ResonCardSkeleton(),
            error: (e, _) => ResonNotice(
              icon: Icons.cloud_off_outlined,
              text: networkErrorText(context, e),
            ),
            // One stream carries every kind of connection, so the screen sorts
            // them into what needs an answer, what is a live conversation and
            // what is set aside. Before, all four states shared one list and a
            // pending request looked like a chat.
            data: (docs) {
              final requests = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
              final chats = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
              final paused = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
              for (final doc in docs) {
                switch (doc.data()['status']) {
                  case 'pending':
                    requests.add(doc);
                  case 'accepted':
                    chats.add(doc);
                  default:
                    paused.add(doc);
                }
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (requests.isNotEmpty) ...[
                    _heading(context, s.networkRequests, requests.length),
                    for (final (i, doc) in requests.indexed)
                      ResonStagger(
                        index: i,
                        child: _request(context, doc, uid),
                      ),
                    const SizedBox(height: ResonSpace.xl),
                  ],
                  _heading(context, s.networkConversations, chats.length),
                  if (chats.isEmpty)
                    NetworkPanel(
                      child: ResonNotice(
                        icon: Icons.forum_outlined,
                        text: s.networkNoConversations,
                      ),
                    )
                  else
                    for (final (i, doc) in chats.indexed)
                      ResonStagger(
                        index: i,
                        child: _conversation(context, doc, uid),
                      ),
                  NetworkMore(
                    visible: docs.length >= ref.watch(connectionsPageProvider),
                    onPressed: () =>
                        ref.read(connectionsPageProvider.notifier).grow(),
                  ),
                  if (paused.isNotEmpty) ...[
                    const SizedBox(height: ResonSpace.xl),
                    _heading(context, s.networkPaused, paused.length),
                    for (final doc in paused)
                      _paused(context, doc, uid, blocked),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: ResonSpace.xxl),
          _heading(context, tr(context, 'Tarjetas recibidas', 'Saved cards')),
          received.when(
            loading: () => const ResonCardSkeleton(),
            error: (e, _) => ResonNotice(
              icon: Icons.cloud_off_outlined,
              text: networkErrorText(context, e),
            ),
            data: (docs) => docs.isEmpty
                ? NetworkPanel(
                    child: ResonNotice(
                      icon: Icons.bookmark_border,
                      text: tr(
                        context,
                        'Aquí estarán las tarjetas que guardes.',
                        'Cards you save will appear here.',
                      ),
                    ),
                  )
                : Column(
                    children: [
                      for (final (i, d) in docs.indexed)
                        ResonStagger(index: i, child: _saved(context, d)),
                      NetworkMore(
                        visible: docs.length >= ref.watch(receivedPageProvider),
                        onPressed: () =>
                            ref.read(receivedPageProvider.notifier).grow(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _heading(BuildContext context, String text, [int? count]) => Padding(
    padding: const EdgeInsets.only(bottom: ResonSpace.md),
    child: Row(
      children: [
        // Flexible, because a heading plus its count has to survive a long
        // translation, a narrow phone and an enlarged text size.
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        if (count != null && count > 0) ...[
          const SizedBox(width: ResonSpace.sm),
          _Pill(label: '$count'),
        ],
      ],
    ),
  );

  String _other(Map<String, dynamic> d, String? uid) =>
      (d['members'] as List).firstWhere((v) => v != uid, orElse: () => '')
          as String;

  String _name(Map<String, dynamic> d, String other) =>
      (d['names'] as Map?)?[other] as String? ?? 'Reson';

  /// Somebody asked to connect, or we did and are waiting.
  Widget _request(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String? uid,
  ) {
    final s = AppLocalizations.of(context)!;
    final d = doc.data();
    final other = _other(d, uid);
    final mine = d['recipient'] == uid;
    return NetworkPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: _Avatar(name: _name(d, other)),
            title: Text(_name(d, other)),
            subtitle: Text(
              mine
                  ? tr(context, 'Quiere conectar contigo', 'Wants to connect')
                  : s.networkWaiting,
            ),
          ),
          Wrap(
            spacing: ResonSpace.sm,
            children: [
              if (mine) ...[
                FilledButton(
                  onPressed: busy ? null : () => respond(doc.id, 'accept'),
                  child: Text(tr(context, 'Aceptar', 'Accept')),
                ),
                TextButton(
                  onPressed: busy ? null : () => respond(doc.id, 'decline'),
                  child: Text(tr(context, 'Rechazar', 'Decline')),
                ),
              ],
              TextButton(
                onPressed: () =>
                    context.go('/receive/${(d['cards'] as Map)[other]}'),
                child: Text(tr(context, 'Ver tarjeta', 'View card')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// A live conversation: the whole row opens it.
  ///
  /// It used to be a tiny chat icon beside a status line, with nothing to say
  /// whether anything had ever been said. Sending a message and coming back
  /// here looked exactly like sending nothing.
  Widget _conversation(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String? uid,
  ) {
    final s = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final d = doc.data();
    final other = _other(d, uid);
    final last = d['lastMessage'] as Map<String, dynamic>?;
    final at = d['lastMessageAt'] as Timestamp?;
    final read = (d['reads'] as Map?)?[uid] as Timestamp?;
    final unread =
        last != null &&
        last['sender'] != uid &&
        at != null &&
        (read == null || read.compareTo(at) < 0);
    final body = last == null
        ? s.networkNoMessages
        : '${last['sender'] == uid ? s.networkYouPrefix : ''}${last['text']}';
    return Padding(
      padding: const EdgeInsets.only(bottom: ResonSpace.md),
      child: ResonPress(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(context.surfaces.panelRadius),
            onTap: () => context.go('/chat/${doc.id}'),
            child: ResonPanel(
              child: Row(
                children: [
                  _Avatar(name: _name(d, other)),
                  const SizedBox(width: ResonSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name(d, other),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: unread
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: ResonSpace.xs),
                        Text(
                          body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: unread
                                    ? scheme.onSurface
                                    : scheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: ResonSpace.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (at != null && at.millisecondsSinceEpoch > 0)
                        Text(
                          shortMoment(context, at.toDate()),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      const SizedBox(height: ResonSpace.sm),
                      if (unread)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Declined or blocked: set aside, with the way back if there is one.
  Widget _paused(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String? uid,
    Set<String> blocked,
  ) {
    final d = doc.data();
    final other = _other(d, uid);
    final isBlocked = d['status'] == 'blocked';
    final iBlocked = blocked.contains(other);
    return Padding(
      padding: const EdgeInsets.only(bottom: ResonSpace.md),
      child: ResonPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _Avatar(name: _name(d, other), muted: true),
              title: Text(_name(d, other)),
              subtitle: Text(
                isBlocked
                    ? (iBlocked
                          ? tr(
                              context,
                              'Bloqueaste a esta persona',
                              'You blocked this person',
                            )
                          : tr(context, 'Conexión bloqueada', 'Blocked'))
                    : tr(context, 'Solicitud rechazada', 'Declined'),
              ),
            ),
            Wrap(
              spacing: ResonSpace.sm,
              children: [
                // A refusal is the recipient's own, so they can still accept
                // it after a wrong tap.
                if (!isBlocked && d['recipient'] == uid)
                  FilledButton(
                    onPressed: busy ? null : () => respond(doc.id, 'accept'),
                    child: Text(
                      tr(context, 'Aceptar ahora', 'Accept after all'),
                    ),
                  ),
                // Lifting a block is deliberate but it is a repair, not the
                // main move on this screen, so it carries weight without shouting.
                if (isBlocked && iBlocked)
                  OutlinedButton(
                    onPressed: busy ? null : () => unblock(doc.id),
                    child: Text(tr(context, 'Desbloquear', 'Unblock')),
                  ),
                if (!isBlocked)
                  TextButton(
                    onPressed: () =>
                        context.go('/receive/${(d['cards'] as Map)[other]}'),
                    child: Text(tr(context, 'Ver tarjeta', 'View card')),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _saved(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> d,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: ResonSpace.md),
    child: ResonPanel(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: _Avatar(name: d.data()['name'] as String? ?? 'R'),
        title: Text(d.data()['name'] as String),
        subtitle: Text(d.data()['label'] as String),
        onTap: () => context.go('/receive/${d.id}'),
        trailing: IconButton(
          tooltip: tr(
            context,
            'Quitar de mi colección',
            'Remove from collection',
          ),
          icon: const Icon(Icons.bookmark_remove_outlined),
          onPressed: busy
              ? null
              : () async {
                  setState(() => busy = true);
                  try {
                    await ref.read(networkServiceProvider).act('removeSaved', {
                      'publicId': d.id,
                    });
                  } catch (e) {
                    if (mounted) {
                      setState(() => error = networkErrorText(context, e));
                    }
                  } finally {
                    if (mounted) setState(() => busy = false);
                  }
                },
        ),
      ),
    ),
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.muted = false});
  final String name;
  final bool muted;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      backgroundColor: muted
          ? scheme.surfaceContainerHighest
          : scheme.primaryContainer,
      foregroundColor: muted
          ? scheme.onSurfaceVariant
          : scheme.onPrimaryContainer,
      child: Text(name.characters.firstOrNull ?? 'R'),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ResonSpace.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(ResonRadius.sm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
