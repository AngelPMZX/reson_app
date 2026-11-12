import 'package:flutter/material.dart';
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
    final uid = ref.watch(authSessionProvider).asData?.value?.uid;
    final connections = ref.watch(connectionsProvider),
        received = ref.watch(receivedProvider);
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
          NetworkPanel(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                tr(
                  context,
                  'Sonido al aceptar una conexión',
                  'Sound when accepting a connection',
                ),
              ),
              subtitle: Text(
                tr(
                  context,
                  'Tono suave de Reson. Puedes desactivarlo cuando quieras.',
                  'A soft Reson chime. You can turn it off at any time.',
                ),
              ),
              value: sound,
              onChanged: (v) async {
                setState(() => sound = v);
                await (await SharedPreferences.getInstance()).setBool(
                  'connectionSound',
                  v,
                );
              },
            ),
          ),
          if (error != null)
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (busy) const LinearProgressIndicator(),
          Text(
            tr(context, 'Conexiones y chats', 'Connections and chats'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: ResonSpace.lg),
          connections.when(
            loading: () => const ResonCardSkeleton(),
            error: (e, _) => ResonNotice(
              icon: Icons.cloud_off_outlined,
              text: networkErrorText(context, e),
            ),
            data: (docs) {
              if (docs.isEmpty) {
                return NetworkPanel(
                  child: ResonNotice(
                    icon: Icons.hub_outlined,
                    text: tr(
                      context,
                      'Todavía no hay conexiones. Comparte tu QR para empezar.',
                      'No connections yet. Share your QR to get started.',
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (final (index, doc) in docs.indexed)
                    ResonStagger(
                      index: index,
                      child: Builder(
                        builder: (context) {
                          final d = doc.data();
                          final other = (d['members'] as List).firstWhere(
                            (v) => v != uid,
                          );
                          final name = (d['names'] as Map)[other] as String;
                          final status = d['status'];
                          return NetworkPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    child: Text(
                                      name.characters.firstOrNull ?? 'R',
                                    ),
                                  ),
                                  title: Text(name),
                                  subtitle: Text(
                                    status == 'accepted'
                                        ? tr(
                                            context,
                                            'Conexión aceptada',
                                            'Connected',
                                          )
                                        : status == 'pending'
                                        ? tr(
                                            context,
                                            'Solicitud pendiente',
                                            'Pending request',
                                          )
                                        : status == 'blocked'
                                        ? (blocked.contains(other)
                                              ? tr(
                                                  context,
                                                  'Bloqueaste a esta persona',
                                                  'You blocked this person',
                                                )
                                              : tr(
                                                  context,
                                                  'Conexión bloqueada',
                                                  'Blocked',
                                                ))
                                        : tr(
                                            context,
                                            'Solicitud rechazada',
                                            'Declined',
                                          ),
                                  ),
                                  trailing: status == 'accepted'
                                      ? IconButton(
                                          tooltip: tr(
                                            context,
                                            'Conversar',
                                            'Chat',
                                          ),
                                          onPressed: () =>
                                              context.go('/chat/${doc.id}'),
                                          icon: const Icon(
                                            Icons.chat_bubble_outline,
                                          ),
                                        )
                                      : null,
                                ),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    if (status == 'pending' &&
                                        d['recipient'] == uid) ...[
                                      FilledButton(
                                        onPressed: busy
                                            ? null
                                            : () => respond(doc.id, 'accept'),
                                        child: Text(
                                          tr(context, 'Aceptar', 'Accept'),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: busy
                                            ? null
                                            : () => respond(doc.id, 'decline'),
                                        child: Text(
                                          tr(context, 'Rechazar', 'Decline'),
                                        ),
                                      ),
                                    ],
                                    // A refusal is the recipient's own, so they
                                    // can still accept it after a wrong tap.
                                    if (status == 'declined' &&
                                        d['recipient'] == uid)
                                      FilledButton(
                                        onPressed: busy
                                            ? null
                                            : () => respond(doc.id, 'accept'),
                                        child: Text(
                                          tr(
                                            context,
                                            'Aceptar ahora',
                                            'Accept after all',
                                          ),
                                        ),
                                      ),
                                    // Lifting a block is deliberate but it is a
                                    // repair, not the main move on this screen,
                                    // so it carries weight without shouting.
                                    if (status == 'blocked' &&
                                        blocked.contains(other))
                                      OutlinedButton(
                                        onPressed: busy
                                            ? null
                                            : () => unblock(doc.id),
                                        child: Text(
                                          tr(context, 'Desbloquear', 'Unblock'),
                                        ),
                                      ),
                                    if (status != 'blocked')
                                      TextButton(
                                        onPressed: () => context.go(
                                          '/receive/${(d['cards'] as Map)[other]}',
                                        ),
                                        child: Text(
                                          tr(
                                            context,
                                            'Ver tarjeta',
                                            'View card',
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  NetworkMore(
                    visible: docs.length >= ref.watch(connectionsPageProvider),
                    onPressed: () =>
                        ref.read(connectionsPageProvider.notifier).grow(),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: ResonSpace.xl),
          Text(
            tr(context, 'Tarjetas recibidas', 'Saved cards'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: ResonSpace.lg),
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
                      for (final (index, d) in docs.indexed)
                        ResonStagger(
                          index: index,
                          child: NetworkPanel(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(d.data()['name'] as String),
                              subtitle: Text(d.data()['label'] as String),
                              onTap: () => context.go('/receive/${d.id}'),
                              trailing: IconButton(
                                tooltip: tr(
                                  context,
                                  'Quitar de mi colección',
                                  'Remove from collection',
                                ),
                                icon: const Icon(
                                  Icons.bookmark_remove_outlined,
                                ),
                                onPressed: busy
                                    ? null
                                    : () async {
                                        setState(() => busy = true);
                                        try {
                                          await ref
                                              .read(networkServiceProvider)
                                              .act('removeSaved', {
                                                'publicId': d.id,
                                              });
                                        } catch (e) {
                                          if (mounted) {
                                            setState(
                                              () => error = networkErrorText(
                                                context,
                                                e,
                                              ),
                                            );
                                          }
                                        } finally {
                                          if (mounted) {
                                            setState(() => busy = false);
                                          }
                                        }
                                      },
                              ),
                            ),
                          ),
                        ),
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
}
