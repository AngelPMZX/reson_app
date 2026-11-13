import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/theme/reson_chrome.dart';
import '../../core/theme/reson_motion.dart';
import '../../core/theme/reson_skeleton.dart';
import '../../core/theme/reson_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/firebase/firebase_bootstrap.dart';
import '../../l10n/generated/app_localizations.dart';
import 'chat_media.dart';
import 'network_service.dart';
import 'network_widgets.dart';

/// An id for one draft, in the alphabet the backend accepts.
///
/// Twenty characters out of 62 is the same shape and the same collision
/// odds as a Firestore document id, which is what this used to borrow.
String draftId() {
  const alphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  final random = Random.secure();
  return String.fromCharCodes(
    Iterable.generate(
      20,
      (_) => alphabet.codeUnitAt(random.nextInt(alphabet.length)),
    ),
  );
}

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

  /// What the composer is doing beyond writing something new: answering a
  /// message, or correcting one already sent. Never both at once.
  Map<String, dynamic>? replyingTo;
  String? editingId, editingOriginal;

  /// A picture chosen but not yet sent. It is uploaded as part of sending,
  /// so backing out costs nothing and no orphan lands in Storage.
  Uint8List? attachment;

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

  /// Acts on one message: answering it, correcting it, or taking it back.
  Future<void> _act(String action, Map<String, dynamic> data) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref.read(networkServiceProvider).act(action, {
        'connectionId': widget.connectionId,
        ...data,
      });
    } catch (e) {
      if (mounted) setState(() => error = networkErrorText(context, e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> pickAttachment() async {
    if (busy) return;
    setState(() => error = null);
    try {
      final bytes = await ref.read(chatImagePickerProvider)();
      if (bytes != null && mounted) {
        setState(() {
          attachment = bytes;
          // A picture is something new to say, not a correction of something
          // already said.
          editingId = null;
          editingOriginal = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => error = AppLocalizations.of(context)!.designChooseAJPGPNGOrWebP,
        );
      }
    }
  }

  Future<void> send() async {
    final body = text.text.trim();
    final photo = attachment;
    // A picture is a message on its own; words beside it are a caption.
    if ((body.isEmpty && photo == null) || body.length > 2000 || busy) return;
    // Correcting something already sent is a different act from sending.
    final editing = editingId;
    if (editing != null) {
      await _act('editMessage', {'messageId': editing, 'text': body});
      if (mounted) {
        text.clear();
        setState(() {
          editingId = null;
          editingOriginal = null;
        });
      }
      return;
    }
    if (lastBody != body || (photo != null && lastId == null)) {
      // A stable id per draft, so a retry cannot post the message twice. It
      // is minted here rather than asked of Firestore: the id only has to be
      // unique and survive a retry, and reaching for the live instance tied
      // sending to a backend being present.
      lastId = draftId();
      lastBody = body;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final media = ref.read(chatMediaProvider);
      // The bytes go up first and the message names them afterwards: the
      // backend only accepts a path that belongs to this very message, and a
      // failed upload leaves no message pointing at nothing.
      if (photo != null) {
        await media.upload(widget.connectionId, lastId!, photo);
      }
      await ref.read(networkServiceProvider).act('message', {
        'connectionId': widget.connectionId,
        'messageId': lastId,
        'text': body,
        if (photo != null) 'image': media.path(widget.connectionId, lastId!),
        if (replyingTo != null) 'replyTo': replyingTo!['id'],
      });
      if (mounted) {
        text.clear();
        lastId = null;
        lastBody = null;
        setState(() {
          replyingTo = null;
          attachment = null;
        });
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
          action == 'block'
              ? AppLocalizations.of(ctx)!.blockConnection
              : AppLocalizations.of(ctx)!.reportConnection,
        ),
        content: action == 'block'
            ? Text(AppLocalizations.of(ctx)!.messagesAndNewRequestsBetween)
            : TextField(
                controller: reason,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(ctx)!.reason,
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              ctx,
              action == 'block' ? 'block' : reason.text.trim(),
            ),
            child: Text(AppLocalizations.of(ctx)!.confirm),
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
              content: Text(AppLocalizations.of(context)!.reportRecorded),
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
                                text: AppLocalizations.of(
                                  context,
                                )!.thisConversationIsUnavailable,
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
        Expanded(
          child: _messageList(
            context,
            uid,
            // When the other member last opened the thread. Their own marker
            // is what says whether what you sent has been seen.
            (d['reads'] as Map?)?[other] as Timestamp?,
          ),
        ),
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
        ResonAvatar(name: name),
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
            child: Text(AppLocalizations.of(context)!.viewCard),
          ),
        PopupMenuButton<String>(
          enabled: !busy,
          tooltip: AppLocalizations.of(context)!.moreOptions,
          onSelected: (value) => value == 'card'
              ? context.go('/receive/${(d['cards'] as Map)[other]}')
              : moderate(value),
          itemBuilder: (context) => [
            if (compact)
              PopupMenuItem(
                value: 'card',
                child: Text(AppLocalizations.of(context)!.viewCard),
              ),
            PopupMenuItem(
              value: 'block',
              child: Text(AppLocalizations.of(context)!.block),
            ),
            PopupMenuItem(
              value: 'report',
              child: Text(AppLocalizations.of(context)!.report),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _messageList(BuildContext context, String? uid, Timestamp? theirRead) {
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
                text: AppLocalizations.of(context)!.aGoodConversationStartsWith,
              );
            }
            return ListView.builder(
              reverse: true,
              padding: const EdgeInsets.symmetric(vertical: ResonSpace.sm),
              itemCount: docs.length + 1,
              itemBuilder: (context, i) {
                if (i == docs.length) {
                  return NetworkMore(
                    visible: docs.length >= ref.watch(messagesPageProvider(id)),
                    onPressed: () =>
                        ref.read(messagesPageProvider(id).notifier).grow(),
                  );
                }
                // The list runs newest first and is drawn upside down, so
                // the message above this one is the next in the list.
                final older = i + 1 < docs.length ? docs[i + 1].data() : null;
                final m = docs[i].data();
                final day = _dayBreak(m, older);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (day != null) _daySeparator(context, day),
                    _bubble(
                      context,
                      docs[i],
                      uid,
                      theirRead,
                      // A run of messages from one person reads as one turn
                      // in the conversation, not as several.
                      grouped: day == null && _samerun(m, older),
                    ),
                  ],
                );
              },
            );
          },
        );
  }

  /// The day this message belongs to, when it is not the day of the one
  /// above it. Null means the thread has not turned a page here.
  DateTime? _dayBreak(Map<String, dynamic> m, Map<String, dynamic>? older) {
    final date = (m['createdAt'] as Timestamp?)?.toDate();
    if (date == null) return null;
    final day = DateTime(date.year, date.month, date.day);
    final before = (older?['createdAt'] as Timestamp?)?.toDate();
    if (before == null) return day;
    return DateTime(before.year, before.month, before.day) == day ? null : day;
  }

  /// Whether this message continues the one above it: same person, close
  /// enough in time that it is still the same breath.
  bool _samerun(Map<String, dynamic> m, Map<String, dynamic>? older) {
    if (older == null || older['sender'] != m['sender']) return false;
    final a = (m['createdAt'] as Timestamp?)?.toDate();
    final b = (older['createdAt'] as Timestamp?)?.toDate();
    if (a == null || b == null) return false;
    return a.difference(b).inMinutes.abs() < 5;
  }

  /// Where the thread turns a page.
  ///
  /// With a date on the day instead of on every bubble, a message only has
  /// to carry the hour, which is the part that is ever read twice.
  Widget _daySeparator(BuildContext context, DateTime day) {
    final s = AppLocalizations.of(context)!;
    final today = DateTime.now();
    final midnight = DateTime(today.year, today.month, today.day);
    final label = day == midnight
        ? s.chatToday
        : day == midnight.subtract(const Duration(days: 1))
        ? s.chatYesterday
        : DateFormat.MMMMd(
            Localizations.localeOf(context).toLanguageTag(),
          ).format(day);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ResonSpace.md),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ResonSpace.md,
            vertical: ResonSpace.xs,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(ResonRadius.lg),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: .4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _bubble(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String? uid,
    Timestamp? theirRead, {
    bool grouped = false,
  }) {
    final s = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final m = doc.data();
    final mine = m['sender'] == uid;
    final gone = m['deleted'] == true;
    final quoted = (m['replyTo'] as Map?)?.cast<String, dynamic>();
    final date = (m['createdAt'] as Timestamp?)?.toDate();
    final ink = mine ? scheme.onPrimaryContainer : scheme.onSurface;
    // Read when their marker is at or past this message. A missing marker
    // means they have never opened the thread, so nothing is seen.
    final seen =
        mine &&
        date != null &&
        theirRead != null &&
        !theirRead.toDate().isBefore(date);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: busy ? null : () => _messageActions(doc, mine, gone),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          margin: EdgeInsets.only(
            bottom: grouped ? ResonSpace.xs : ResonSpace.sm,
          ),
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
              // Inside a run the edge facing the message above is pulled in,
              // so a sequence looks like one block rather than a stack of
              // identical lozenges.
              topLeft: Radius.circular(
                grouped && !mine ? ResonRadius.sm : ResonRadius.lg,
              ),
              topRight: Radius.circular(
                grouped && mine ? ResonRadius.sm : ResonRadius.lg,
              ),
              bottomLeft: Radius.circular(
                mine ? ResonRadius.lg : ResonRadius.sm,
              ),
              bottomRight: Radius.circular(
                mine ? ResonRadius.sm : ResonRadius.lg,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The quote is stored with the reply, so it survives the message
              // it answers being withdrawn.
              if (quoted != null)
                Container(
                  margin: const EdgeInsets.only(bottom: ResonSpace.sm),
                  padding: const EdgeInsets.only(left: ResonSpace.sm),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: ink.withValues(alpha: .45),
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    quoted['text'] as String? ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ink.withValues(alpha: .72),
                    ),
                  ),
                ),
              if (m['image'] is String && !gone)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: (m['text'] as String?)?.isNotEmpty == true
                        ? ResonSpace.sm
                        : 0,
                  ),
                  child: _attachment(context, m['image'] as String),
                ),
              if (gone)
                Text(
                  s.chatDeleted,
                  style: TextStyle(
                    color: ink.withValues(alpha: .6),
                    fontStyle: FontStyle.italic,
                  ),
                )
              else if ((m['text'] as String?)?.isNotEmpty == true)
                // Plain text, not selectable: a long press on a bubble opens
                // its actions, and a selection gesture inside the text would
                // win the arena and swallow it. Copying lives in that menu.
                Text(m['text'] as String, style: TextStyle(color: ink)),
              if (date != null)
                Padding(
                  padding: const EdgeInsets.only(top: ResonSpace.xs),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        // The day is written once, above the run; a bubble
                        // only needs the hour.
                        DateFormat.jm(
                          Localizations.localeOf(context).toLanguageTag(),
                        ).format(date),
                        // The hour is a footnote, not a second sentence: it keeps
                        // the bubble's ink but steps well back from the message.
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: (mine ? ink : scheme.onSurfaceVariant)
                              .withValues(alpha: .62),
                        ),
                      ),
                      if (m['editedAt'] != null && !gone) ...[
                        const SizedBox(width: ResonSpace.xs),
                        Text(
                          '· ${s.chatEdited}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: (mine ? ink : scheme.onSurfaceVariant)
                                    .withValues(alpha: .62),
                              ),
                        ),
                      ],
                      // Only on what you sent: whether it has been read is news
                      // to the sender, not to the person who read it.
                      if (mine) ...[
                        const SizedBox(width: ResonSpace.xs + 2),
                        Icon(
                          seen ? Icons.done_all : Icons.done,
                          size: 14,
                          color: ink.withValues(alpha: seen ? .9 : .5),
                          semanticLabel: seen ? s.chatSeen : s.chatSent,
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// A picture inside a bubble.
  ///
  /// The bytes are fetched through a provider rather than a download URL: a
  /// Storage download URL carries its own token and would hand anybody with
  /// the link a picture the rules were written to keep between two people.
  Widget _attachment(BuildContext context, String path) => ClipRRect(
    borderRadius: BorderRadius.circular(ResonRadius.sm),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 260),
      child: ref
          .watch(chatImageProvider(path))
          .when(
            loading: () => const ResonSkeleton(height: 180),
            error: (e, _) => ResonNotice(
              icon: Icons.image_not_supported_outlined,
              text: AppLocalizations.of(context)!.chatImageUnavailable,
            ),
            data: (bytes) => GestureDetector(
              // Tapping opens it big, because a 260px preview is enough to know
              // a picture arrived and not enough to read anything in it.
              onTap: () => _viewAttachment(context, bytes),
              child: Image.memory(bytes, fit: BoxFit.cover),
            ),
          ),
    ),
  );

  Future<void> _viewAttachment(BuildContext context, Uint8List bytes) =>
      showDialog<void>(
        context: context,
        builder: (ctx) => Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  maxScale: 5,
                  child: Image.memory(bytes, fit: BoxFit.contain),
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    tooltip: AppLocalizations.of(ctx)!.back,
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  /// What you can do to one message. Yours can be corrected or withdrawn;
  /// anybody's can be answered.
  Future<void> _messageActions(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    bool mine,
    bool gone,
  ) async {
    final s = AppLocalizations.of(context)!;
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!gone) ...[
              ListTile(
                leading: const Icon(Icons.reply),
                title: Text(s.chatReply),
                onTap: () => Navigator.pop(ctx, 'reply'),
              ),
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: Text(s.chatCopy),
                onTap: () => Navigator.pop(ctx, 'copy'),
              ),
            ],
            if (mine && !gone) ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(s.chatEdit),
                onTap: () => Navigator.pop(ctx, 'edit'),
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(ctx).colorScheme.error,
                ),
                title: Text(
                  s.chatDelete,
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                ),
                onTap: () => Navigator.pop(ctx, 'delete'),
              ),
            ],
          ],
        ),
      ),
    );
    if (chosen == null || !mounted) return;
    final m = doc.data();
    switch (chosen) {
      case 'reply':
        setState(() {
          editingId = null;
          replyingTo = {'id': doc.id, 'text': m['text'], 'sender': m['sender']};
        });
      case 'edit':
        text.text = m['text'] as String? ?? '';
        setState(() {
          replyingTo = null;
          editingId = doc.id;
          editingOriginal = text.text;
        });
      case 'copy':
        await Clipboard.setData(
          ClipboardData(text: m['text'] as String? ?? ''),
        );
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(s.chatCopied)));
        }
      case 'delete':
        await _act('deleteMessage', {'messageId': doc.id});
    }
  }

  Widget _composer(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final context_ = replyingTo != null
        ? (s.chatReplyingTo, replyingTo!['text'] as String? ?? '')
        : editingId != null
        ? (s.chatEditing, editingOriginal ?? '')
        : attachment != null
        ? (s.chatAttachment, '')
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // What the composer is about to do, and the way out of it. Without
        // this a reply looks exactly like a new message being typed.
        if (context_ != null)
          Container(
            margin: const EdgeInsets.only(top: ResonSpace.sm),
            padding: const EdgeInsets.fromLTRB(
              ResonSpace.md,
              ResonSpace.sm,
              ResonSpace.sm,
              ResonSpace.sm,
            ),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(ResonRadius.sm),
              border: Border(left: BorderSide(color: scheme.primary, width: 3)),
            ),
            child: Row(
              children: [
                // Seeing the picture is the only way to know the right one
                // was chosen before it is sent.
                if (attachment != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(ResonRadius.sm),
                    child: Image.memory(
                      attachment!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: ResonSpace.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context_.$1,
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: scheme.primary),
                      ),
                      if (context_.$2.isNotEmpty)
                        Text(
                          context_.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: attachment != null
                      ? s.chatRemoveAttachment
                      : s.chatCancelReply,
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    if (editingId != null) text.clear();
                    setState(() {
                      if (attachment != null) {
                        attachment = null;
                      } else {
                        replyingTo = null;
                      }
                      editingId = null;
                      editingOriginal = null;
                    });
                  },
                ),
              ],
            ),
          ),
        _composerRow(context, s),
      ],
    );
  }

  Widget _composerRow(BuildContext context, AppLocalizations s) => Padding(
    padding: const EdgeInsets.symmetric(vertical: ResonSpace.md),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Correcting a message that is already sent cannot gain a picture:
        // the attachment is written once, with the message.
        // The composer reads as a field with a round end at each side: one
        // to bring something in, one to send it out.
        IconButton.filledTonal(
          tooltip: s.chatAttach,
          onPressed: busy || editingId != null ? null : pickAttachment,
          icon: const Icon(Icons.add_photo_alternate_outlined),
        ),
        const SizedBox(width: ResonSpace.sm),
        Expanded(
          child: TextField(
            controller: text,
            enabled: !busy,
            minLines: 1,
            maxLines: 4,
            maxLength: 2000,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.writeAMessage,
              counterText: '',
            ),
          ),
        ),
        const SizedBox(width: ResonSpace.md),
        IconButton.filled(
          tooltip: editingId != null ? s.chatSave : s.sendMessage,
          onPressed: busy ? null : send,
          icon: busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              // Saving a correction is not sending something new, and the
              // glyph is the only thing that says which one is about to run.
              : Icon(editingId != null ? Icons.check : Icons.arrow_upward),
        ),
      ],
    ),
  );
}
