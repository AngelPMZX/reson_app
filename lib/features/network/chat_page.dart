import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/theme/reson_chrome.dart';
import '../../core/theme/reson_motion.dart';
import '../../core/theme/reson_skeleton.dart';
import '../../core/theme/reson_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/firebase/firebase_bootstrap.dart';
import '../../l10n/generated/app_localizations.dart';
import 'network_service.dart';
import 'network_widgets.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key, required this.connectionId});
  final String connectionId;
  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final text = TextEditingController();
  bool busy = false;
  String? error, lastBody, lastId;

  @override
  void initState() {
    super.initState();
    _markRead();
  }

  /// Clears the unread mark the network list reads.
  ///
  /// Opening the thread is the only thing that counts as reading it, and a
  /// failure here is not worth telling anyone about: the worst case is a dot
  /// that stays on until the next visit.
  Future<void> _markRead() async {
    try {
      await ref.read(networkServiceProvider).act('markRead', {
        'connectionId': widget.connectionId,
      });
    } catch (_) {
      /* An unread mark is not worth an error message. */
    }
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  Future<void> send() async {
    final body = text.text.trim();
    if (body.isEmpty || body.length > 2000 || busy) return;
    if (lastBody != body) {
      // A stable id per draft, so a retry cannot post the message twice.
      lastId = FirebaseFirestore.instance
          .collection('connections/${widget.connectionId}/messages')
          .doc()
          .id;
      lastBody = body;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref.read(networkServiceProvider).act('message', {
        'connectionId': widget.connectionId,
        'messageId': lastId,
        'text': body,
      });
      if (mounted) {
        text.clear();
        lastId = null;
        lastBody = null;
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = networkErrorText(context, e));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> moderate(String action) async {
    final reason = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          tr(
            ctx,
            action == 'block' ? 'Bloquear conexión' : 'Reportar conexión',
            action == 'block' ? 'Block connection' : 'Report connection',
          ),
        ),
        content: action == 'block'
            ? Text(
                tr(
                  ctx,
                  'Se detendrán los mensajes y las nuevas solicitudes entre ambas cuentas.',
                  'Messages and new requests between these accounts will be stopped.',
                ),
              )
            : TextField(
                controller: reason,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: tr(ctx, 'Motivo', 'Reason'),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr(ctx, 'Cancelar', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              ctx,
              action == 'block' ? 'block' : reason.text.trim(),
            ),
            child: Text(tr(ctx, 'Confirmar', 'Confirm')),
          ),
        ],
      ),
    );
    reason.dispose();
    if (result == null || result.isEmpty || !mounted) return;
    setState(() => busy = true);
    try {
      await ref.read(networkServiceProvider).act(action, {
        'connectionId': widget.connectionId,
        'reason': result,
      });
      if (mounted) {
        if (action == 'block') {
          // A blocked thread no longer belongs in Messages, so the list of
          // people is the right place to land.
          context.go('/network');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                tr(context, 'Reporte registrado.', 'Report recorded.'),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => error = networkErrorText(context, e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authSessionProvider).asData?.value?.uid;
    // The chat keeps its own scaffold instead of NetworkShell, because its
    // header and composer must stay put while only the messages scroll. It
    // borrows the shell's header, width and rhythm so it still reads as the
    // same app: this was the one screen built from raw values, down to 132
    // logical pixels of empty AppBar reserving room for the global controls.
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: ResonSpace.xl),
              child: Column(
                children: [
                  const SizedBox(height: ResonSpace.xl),
                  // Back to the list this thread came from, which is the
                  // Messages destination now, not the network screen.
                  ResonHeader(
                    leading: resonCompact(context)
                        ? IconButton(
                            onPressed: () => context.go('/messages'),
                            tooltip: AppLocalizations.of(context)!.navMessages,
                            icon: const Icon(Icons.arrow_back),
                          )
                        : TextButton.icon(
                            onPressed: () => context.go('/messages'),
                            icon: const Icon(Icons.arrow_back),
                            label: Text(
                              AppLocalizations.of(context)!.navMessages,
                            ),
                          ),
                  ),
                  const SizedBox(height: ResonSpace.lg),
                  Expanded(
                    child: ref
                        .watch(connectionProvider(widget.connectionId))
                        .when(
                          loading: () => const Padding(
                            padding: EdgeInsets.only(top: ResonSpace.xl),
                            child: ResonSkeleton(height: 96),
                          ),
                          error: (e, _) => ResonNotice(
                            icon: Icons.cloud_off_outlined,
                            text: networkErrorText(context, e),
                          ),
                          data: (snapshot) {
                            final d = snapshot.data();
                            if (d == null || d['status'] != 'accepted') {
                              return ResonNotice(
                                icon: Icons.lock_outline,
                                text: tr(
                                  context,
                                  'La conversación no está habilitada.',
                                  'This conversation is unavailable.',
                                ),
                              );
                            }
                            return _conversation(context, d, uid);
                          },
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

  Widget _conversation(
    BuildContext context,
    Map<String, dynamic> d,
    String? uid,
  ) {
    final other = (d['members'] as List).where((v) => v != uid).firstOrNull;
    final name = (d['names'] as Map)[other] as String? ?? 'Reson';
    return Column(
      children: [
        _header(context, d, name, other, compact: resonCompact(context)),
        const SizedBox(height: ResonSpace.lg),
        Expanded(child: _messageList(context, uid)),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: ResonSpace.sm),
            child: Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        _composer(context),
      ],
    );
  }

  /// Who you are talking to, and what you can do about it.
  ///
  /// Blocking and reporting used to hide behind an overflow menu in the app
  /// bar; they belong beside the person they act on.
  Widget _header(
    BuildContext context,
    Map<String, dynamic> d,
    String name,
    Object? other, {
    required bool compact,
  }) => ResonPanel(
    padding: const EdgeInsets.symmetric(
      horizontal: ResonSpace.lg,
      vertical: ResonSpace.md,
    ),
    child: Row(
      children: [
        CircleAvatar(child: Text(name.characters.firstOrNull ?? 'R')),
        const SizedBox(width: ResonSpace.md),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        // On a narrow phone the card link folds into the menu rather than
        // squeezing the name it sits beside.
        if (!compact)
          TextButton(
            onPressed: () =>
                context.go('/receive/${(d['cards'] as Map)[other]}'),
            child: Text(tr(context, 'Ver tarjeta', 'View card')),
          ),
        PopupMenuButton<String>(
          enabled: !busy,
          tooltip: tr(context, 'Más opciones', 'More options'),
          onSelected: (value) => value == 'card'
              ? context.go('/receive/${(d['cards'] as Map)[other]}')
              : moderate(value),
          itemBuilder: (context) => [
            if (compact)
              PopupMenuItem(
                value: 'card',
                child: Text(tr(context, 'Ver tarjeta', 'View card')),
              ),
            PopupMenuItem(
              value: 'block',
              child: Text(tr(context, 'Bloquear', 'Block')),
            ),
            PopupMenuItem(
              value: 'report',
              child: Text(tr(context, 'Reportar', 'Report')),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _messageList(BuildContext context, String? uid) {
    final id = widget.connectionId;
    return ref
        .watch(messagesProvider(id))
        .when(
          loading: () => const ResonSkeleton(height: 72),
          error: (e, _) => ResonNotice(
            icon: Icons.cloud_off_outlined,
            text: networkErrorText(context, e),
          ),
          data: (docs) {
            if (docs.isEmpty) {
              return ResonNotice(
                icon: Icons.waving_hand_outlined,
                text: tr(
                  context,
                  'Una buena conversación empieza con un hola.',
                  'A good conversation starts with hello.',
                ),
              );
            }
            return ListView.builder(
              reverse: true,
              padding: const EdgeInsets.symmetric(vertical: ResonSpace.sm),
              itemCount: docs.length + 1,
              itemBuilder: (context, i) => i == docs.length
                  ? NetworkMore(
                      visible:
                          docs.length >= ref.watch(messagesPageProvider(id)),
                      onPressed: () =>
                          ref.read(messagesPageProvider(id).notifier).grow(),
                    )
                  : _bubble(context, docs[i].data(), uid),
            );
          },
        );
  }

  Widget _bubble(BuildContext context, Map<String, dynamic> m, String? uid) {
    final scheme = Theme.of(context).colorScheme;
    final mine = m['sender'] == uid;
    final date = (m['createdAt'] as Timestamp?)?.toDate();
    final ink = mine ? scheme.onPrimaryContainer : scheme.onSurface;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        margin: const EdgeInsets.only(bottom: ResonSpace.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: ResonSpace.lg,
          vertical: ResonSpace.md,
        ),
        decoration: BoxDecoration(
          // surfaceContainerHighest is the heavy silver; beside the warm
          // blush of an outgoing bubble it reads cold. One step down is mist.
          color: mine ? scheme.primaryContainer : scheme.surfaceContainerHigh,
          // Square off the corner nearest the sender, so a bubble points at
          // whoever wrote it instead of floating between the two columns.
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(ResonRadius.lg),
            topRight: const Radius.circular(ResonRadius.lg),
            bottomLeft: Radius.circular(mine ? ResonRadius.lg : ResonRadius.sm),
            bottomRight: Radius.circular(
              mine ? ResonRadius.sm : ResonRadius.lg,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(m['text'] as String, style: TextStyle(color: ink)),
            if (date != null)
              Padding(
                padding: const EdgeInsets.only(top: ResonSpace.xs),
                child: Text(
                  '${date.day}/${date.month} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                  // The hour is a footnote, not a second sentence: it keeps
                  // the bubble's ink but steps well back from the message.
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: (mine ? ink : scheme.onSurfaceVariant).withValues(
                      alpha: .62,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _composer(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: ResonSpace.md),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: text,
            enabled: !busy,
            minLines: 1,
            maxLines: 4,
            maxLength: 2000,
            decoration: InputDecoration(
              hintText: tr(context, 'Escribe un mensaje…', 'Write a message…'),
              counterText: '',
            ),
          ),
        ),
        const SizedBox(width: ResonSpace.md),
        IconButton.filled(
          tooltip: tr(context, 'Enviar mensaje', 'Send message'),
          onPressed: busy ? null : send,
          icon: busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.arrow_upward),
        ),
      ],
    ),
  );
}
