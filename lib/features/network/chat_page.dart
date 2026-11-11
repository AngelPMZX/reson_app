import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/theme/reson_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/firebase/firebase_bootstrap.dart';
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
  int limit = 50;
  late final DocumentReference<Map<String, dynamic>> connection;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> status;
  late Stream<QuerySnapshot<Map<String, dynamic>>> messages;
  @override
  void initState() {
    super.initState();
    connection = FirebaseFirestore.instance.doc(
      'connections/${widget.connectionId}',
    );
    status = connection.snapshots();
    messages = _messages();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _messages() => connection
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots();
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  Future<void> send() async {
    final body = text.text.trim();
    if (body.isEmpty || body.length > 2000 || busy) return;
    if (lastBody != body) {
      lastId = connection.collection('messages').doc().id;
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
        setState(
          () => error = networkError(
            e,
            Localizations.localeOf(context).languageCode == 'es',
          ),
        );
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
      if (mounted) setState(() => error = networkError(e, true));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authSessionProvider).asData?.value?.uid;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/network'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          tr(context, 'Conversación', 'Conversation'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          PopupMenuButton<String>(
            enabled: !busy,
            onSelected: moderate,
            itemBuilder: (context) => [
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
          // Reserve space for the app-wide theme and language controls.
          const SizedBox(width: 132),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: status,
              builder: (context, state) {
                if (state.hasError) {
                  return Center(child: Text(networkError(state.error!, true)));
                }
                if (!state.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final d = state.data!.data();
                if (d == null) {
                  return Center(
                    child: Text(
                      tr(
                        context,
                        'Conversación no disponible',
                        'Conversation unavailable',
                      ),
                    ),
                  );
                }
                final other = (d['members'] as List)
                    .where((v) => v != uid)
                    .firstOrNull;
                final name = (d['names'] as Map)[other] as String? ?? 'Reson';
                if (d['status'] != 'accepted') {
                  return Center(
                    child: Text(
                      tr(
                        context,
                        'La conversación no está habilitada.',
                        'This conversation is unavailable.',
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            child: Text(name.characters.firstOrNull ?? 'R'),
                          ),
                          const SizedBox(width: ResonSpace.md),
                          Expanded(
                            child: Text(
                              name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go(
                              '/receive/${(d['cards'] as Map)[other]}',
                            ),
                            child: Text(
                              tr(context, 'Ver tarjeta', 'View card'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: messages,
                        builder: (context, s) {
                          if (s.hasError) {
                            return Center(
                              child: Text(networkError(s.error!, true)),
                            );
                          }
                          if (!s.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final docs = s.data!.docs;
                          if (docs.isEmpty) {
                            return Center(
                              child: Text(
                                tr(
                                  context,
                                  'Una buena conversación empieza con un hola.',
                                  'A good conversation starts with hello.',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return ListView.builder(
                            reverse: true,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            itemCount: docs.length + 1,
                            itemBuilder: (context, i) {
                              if (i == docs.length) {
                                return docs.length < limit
                                    ? const SizedBox.shrink()
                                    : TextButton(
                                        onPressed: () => setState(() {
                                          limit += 50;
                                          messages = _messages();
                                        }),
                                        child: Text(
                                          tr(
                                            context,
                                            'Cargar anteriores',
                                            'Load older messages',
                                          ),
                                        ),
                                      );
                              }
                              final m = docs[i].data();
                              final mine = m['sender'] == uid;
                              final date = (m['createdAt'] as Timestamp?)
                                  ?.toDate();
                              return Align(
                                alignment: mine
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    maxWidth: 460,
                                  ),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: mine
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer
                                        : Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SelectableText(
                                        m['text'] as String,
                                        style: TextStyle(
                                          color: mine
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.onPrimaryContainer
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                        ),
                                      ),
                                      if (date != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 6,
                                          ),
                                          child: Text(
                                            '${date.day}/${date.month} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: mine
                                                      ? Theme.of(context)
                                                            .colorScheme
                                                            .onPrimaryContainer
                                                      : Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(14),
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
                                hintText: tr(
                                  context,
                                  'Escribe un mensaje…',
                                  'Write a message…',
                                ),
                                counterText: '',
                              ),
                            ),
                          ),
                          const SizedBox(width: ResonSpace.md),
                          IconButton.filled(
                            tooltip: tr(
                              context,
                              'Enviar mensaje',
                              'Send message',
                            ),
                            onPressed: busy ? null : send,
                            icon: busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.arrow_upward),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
