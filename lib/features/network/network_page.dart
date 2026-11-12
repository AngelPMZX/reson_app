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
    // Conversations moved out to their own destination, so this screen is
    // about people and the cards they handed over, not about threads.
    return DefaultTabController(
      length: 2,
      child: NetworkShell(
        back: false,
        title: s.navNetwork,
        subtitle: tr(
          context,
          'Personas que conoces. Tarjetas que guardaste.',
          'People you know. Cards you kept.',
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TabBar(
              tabs: [
                Tab(text: s.networkConnections),
                Tab(text: s.networkSaved),
              ],
            ),
            const SizedBox(height: ResonSpace.lg),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: ResonSpace.md),
                child: Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (busy) const LinearProgressIndicator(),
            // A tab view needs a bounded height and this screen scrolls as a
            // whole, so each tab is built and only the chosen one is shown.
            _Tabs(children: [_people(context, uid, s), _saved(context, s)]),
          ],
        ),
      ),
    );
  }

  Widget _people(BuildContext context, String? uid, AppLocalizations s) => ref
      .watch(connectionsProvider)
      .when(
        loading: () => const ResonCardSkeleton(),
        error: (e, _) => ResonNotice(
          icon: Icons.cloud_off_outlined,
          text: networkErrorText(context, e),
        ),
        data: (docs) {
          final requests = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
          final connected = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
          final paused = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
          for (final doc in docs) {
            switch (doc.data()['status']) {
              case 'pending':
                requests.add(doc);
              case 'accepted':
                connected.add(doc);
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
                  ResonStagger(index: i, child: _request(context, doc, uid)),
                const SizedBox(height: ResonSpace.xl),
              ],
              // The tab already says "Connections"; a heading repeating it
              // only earns its place once there are other groups to tell it
              // apart from.
              if (requests.isNotEmpty || paused.isNotEmpty)
                _heading(context, s.networkConnections, connected.length),
              if (connected.isEmpty)
                NetworkPanel(
                  child: ResonNotice(
                    icon: Icons.hub_outlined,
                    text: tr(
                      context,
                      'Todavía no hay conexiones. Comparte tu QR para empezar.',
                      'No connections yet. Share your QR to get started.',
                    ),
                  ),
                )
              else
                for (final (i, doc) in connected.indexed)
                  ResonStagger(index: i, child: _connected(context, doc, uid)),
              NetworkMore(
                visible: docs.length >= ref.watch(connectionsPageProvider),
                onPressed: () =>
                    ref.read(connectionsPageProvider.notifier).grow(),
              ),
              if (paused.isNotEmpty) ...[
                const SizedBox(height: ResonSpace.xl),
                _heading(context, s.networkPaused, paused.length),
                for (final doc in paused) _paused(context, doc, uid),
              ],
            ],
          );
        },
      );

  Widget _saved(BuildContext context, AppLocalizations s) => ref
      .watch(receivedProvider)
      .when(
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
                    ResonStagger(index: i, child: _savedRow(context, d)),
                  NetworkMore(
                    visible: docs.length >= ref.watch(receivedPageProvider),
                    onPressed: () =>
                        ref.read(receivedPageProvider.notifier).grow(),
                  ),
                ],
              ),
      );

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

  /// Somebody asked to connect, or we did and are waiting.
  Widget _request(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String? uid,
  ) {
    final s = AppLocalizations.of(context)!;
    final d = doc.data();
    final other = otherMember(d, uid);
    final mine = d['recipient'] == uid;
    return NetworkPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: _Avatar(name: memberName(d, other)),
            title: Text(memberName(d, other)),
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

  /// Somebody you are connected to. The conversation lives in Messages, so
  /// here the row is about the person and their card.
  Widget _connected(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String? uid,
  ) {
    final d = doc.data();
    final other = otherMember(d, uid);
    return Padding(
      padding: const EdgeInsets.only(bottom: ResonSpace.md),
      child: ResonPanel(
        child: Row(
          children: [
            _Avatar(name: memberName(d, other)),
            const SizedBox(width: ResonSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    memberName(d, other),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    tr(context, 'Conexión aceptada', 'Connected'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: tr(context, 'Ver tarjeta', 'View card'),
              icon: const Icon(Icons.badge_outlined),
              onPressed: () =>
                  context.go('/receive/${(d['cards'] as Map)[other]}'),
            ),
            IconButton(
              tooltip: tr(context, 'Conversar', 'Chat'),
              icon: const Icon(Icons.forum_outlined),
              onPressed: () => context.go('/chat/${doc.id}'),
            ),
          ],
        ),
      ),
    );
  }

  /// Declined or blocked: set aside, with the way back if there is one.
  Widget _paused(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String? uid,
  ) {
    final blocked =
        ref.watch(blockedProvider).asData?.value ?? const <String>{};
    final d = doc.data();
    final other = otherMember(d, uid);
    final isBlocked = d['status'] == 'blocked';
    // Only the member who placed a block may lift it, so the screen asks the
    // account's own block list rather than the connection.
    final iBlocked = blocked.contains(other);
    return Padding(
      padding: const EdgeInsets.only(bottom: ResonSpace.md),
      child: ResonPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _Avatar(name: memberName(d, other), muted: true),
              title: Text(memberName(d, other)),
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
                // main move on this screen, so it carries weight without
                // shouting.
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

  Widget _savedRow(
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

/// Shows the selected tab's children inside a scrolling page.
///
/// `TabBarView` wants a bounded height, which a page that scrolls as a whole
/// cannot give it. Keeping both subtrees alive and showing one preserves each
/// tab's scroll position and its stream subscriptions.
class _Tabs extends StatelessWidget {
  const _Tabs({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => IndexedStack(
        index: controller.index,
        sizing: StackFit.loose,
        children: [
          for (final (i, child) in children.indexed)
            Visibility(
              visible: controller.index == i,
              maintainState: true,
              child: child,
            ),
        ],
      ),
    );
  }
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
