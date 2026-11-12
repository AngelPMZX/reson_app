import 'package:flutter/material.dart';
import '../../core/theme/reson_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../cards/presentation/card_preview.dart';
import '../../l10n/generated/app_localizations.dart';
import '../cards/presentation/professional_summary.dart';
import '../profile/profile_page.dart';
import 'network_service.dart';
import 'network_widgets.dart';

class ReceiveCardPage extends ConsumerStatefulWidget {
  const ReceiveCardPage({super.key, required this.publicId});
  final String publicId;
  @override
  ConsumerState<ReceiveCardPage> createState() => _ReceiveCardPageState();
}

class _ReceiveCardPageState extends ConsumerState<ReceiveCardPage> {
  bool busy = false;
  String? feedback, own;
  Future<void> act(String action) async {
    setState(() {
      busy = true;
      feedback = null;
    });
    try {
      await ref.read(networkServiceProvider).act(action, {
        'publicId': widget.publicId,
        'ownPublicId': own,
      });
      if (mounted) {
        setState(
          () => feedback = action == 'save'
              ? AppLocalizations.of(context)!.cardSavedInNetwork
              : AppLocalizations.of(context)!.requestSentChatLater,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => feedback = networkErrorText(context, e));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(sharedCardProvider(widget.publicId));
    final publications = ref.watch(publicationsProvider);
    return NetworkShell(
      title: AppLocalizations.of(context)!.aNewConnection,
      subtitle: AppLocalizations.of(context)!.saveThisCardOrIntroduce,
      child: result.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => NetworkPanel(
          child: Column(
            children: [
              Text(networkErrorText(context, e)),
              TextButton(
                onPressed: () =>
                    ref.invalidate(sharedCardProvider(widget.publicId)),
                child: Text(AppLocalizations.of(context)!.retry2),
              ),
            ],
          ),
        ),
        data: (p) {
          final card = cardFromSnapshot(p, widget.publicId);
          // Location and work mode are identity chips under the name, so the
          // career block below hides them rather than repeating them.
          final career = card.withVisibleFields(
            withoutIdentityChips(card.visibleFields),
          );
          final ownCards =
              publications.asData?.value
                  .where((v) => v.data()['active'] == true)
                  .toList() ??
              [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Leads with the person, not with the artwork. A connection
              // used to be a card and nothing else: no face, no career, no
              // way to see who you were about to talk to.
              ProfileHero(
                name: card.displayName,
                role: card.role,
                company: card.company,
                location: card.professional.location,
                workMode: card.professional.workMode,
                imageUrl: p['photoUrl'] as String?,
                inset: false,
              ),
              const SizedBox(height: ResonSpace.xl),
              if (card.bio.isNotEmpty) ...[
                NetworkPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.profileAbout,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: ResonSpace.md),
                      Text(card.bio, style: const TextStyle(height: 1.6)),
                    ],
                  ),
                ),
              ],
              // The same career presentation the profile uses, so looking at
              // somebody else has the shape of looking at yourself.
              ProfessionalSummary(card: career, open: true),
              const SizedBox(height: ResonSpace.xl),
              Text(
                AppLocalizations.of(context)!.theirCard,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: ResonSpace.md),
              CardPreview(card: card),
              const SizedBox(height: ResonSpace.xl),
              FilledButton.icon(
                onPressed: busy ? null : () => act('save'),
                icon: const Icon(Icons.bookmark_add_outlined),
                label: Text(AppLocalizations.of(context)!.saveToMyNetwork),
              ),
              const SizedBox(height: ResonSpace.md),
              OutlinedButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse('https://reson-app.web.app/c/${widget.publicId}'),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new),
                label: Text(AppLocalizations.of(context)!.viewContactOptions),
              ),
              const SizedBox(height: ResonSpace.xl),
              NetworkPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.exchangeCards,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: ResonSpace.md),
                    Text(
                      AppLocalizations.of(context)!.chooseWhichPublishedCardTo,
                    ),
                    const SizedBox(height: ResonSpace.lg),
                    if (ownCards.isEmpty)
                      Text(AppLocalizations.of(context)!.publishACardFromMy)
                    else ...[
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: own,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.yourCard,
                        ),
                        items: [
                          for (final c in ownCards)
                            DropdownMenuItem(
                              value: c.data()['id'] as String,
                              child: Text(
                                c.data()['label'] as String? ?? c.id,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: busy ? null : (v) => setState(() => own = v),
                      ),
                      const SizedBox(height: ResonSpace.lg),
                      FilledButton.icon(
                        onPressed: busy || own == null
                            ? null
                            : () => act('request'),
                        icon: const Icon(Icons.handshake_outlined),
                        label: Text(
                          AppLocalizations.of(context)!.requestConnection,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (busy) const LinearProgressIndicator(),
              if (feedback != null) Text(feedback!),
            ],
          );
        },
      ),
    );
  }
}
