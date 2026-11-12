import 'package:flutter/material.dart';
import '../../core/theme/reson_surfaces.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../cards/application/cards_providers.dart';
import '../cards/domain/digital_card.dart';
import '../cards/presentation/card_preview.dart';
import '../../l10n/generated/app_localizations.dart';
import 'network_service.dart';
import 'network_widgets.dart';

class ShareCardPage extends ConsumerStatefulWidget {
  const ShareCardPage({super.key, required this.cardId});
  final String cardId;
  @override
  ConsumerState<ShareCardPage> createState() => _ShareCardPageState();
}

class _ShareCardPageState extends ConsumerState<ShareCardPage> {
  Set<String>? fields;
  bool whatsapp = false, busy = false;
  String? error;
  Future<void> act(String action) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref.read(networkServiceProvider).act(action, {
        'cardId': widget.cardId,
        'fields': fields?.toList() ?? [],
        'whatsapp': whatsapp,
      });
    } catch (e) {
      if (mounted) {
        setState(() => error = networkErrorText(context, e));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(cardsProvider);
    final publications = ref.watch(publicationsProvider);
    return NetworkShell(
      title: AppLocalizations.of(context)!.shareYourIdentity,
      subtitle: AppLocalizations.of(context)!.publishOnlyWhatYouWant,
      child: cards.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text(networkErrorText(context, e)),
        data: (items) {
          final card = items.where((c) => c.id == widget.cardId).firstOrNull;
          if (card == null) {
            return Text(AppLocalizations.of(context)!.cardUnavailable);
          }
          fields ??= card.visibleFields.toSet();
          final pub = publications.asData?.value
              .where((p) => p.id == card.id)
              .firstOrNull
              ?.data();
          final url = pub?['active'] == true
              ? 'https://reson-app.web.app/c/${pub!['id']}'
              : null;
          final labels = {
            'photo': AppLocalizations.of(context)!.photo,
            'role': AppLocalizations.of(context)!.careerRole,
            'company': AppLocalizations.of(context)!.company,
            'email': AppLocalizations.of(context)!.contactEmail,
            'phone': AppLocalizations.of(context)!.phone,
            'website': AppLocalizations.of(context)!.website,
            'bio': AppLocalizations.of(context)!.bio,
            'location': AppLocalizations.of(context)!.location,
            'linkedin': 'LinkedIn',
            'skills': AppLocalizations.of(context)!.profileSkills,
            'experience': AppLocalizations.of(context)!.experience2,
            'education': AppLocalizations.of(context)!.education,
            'sector': AppLocalizations.of(context)!.industry,
            'specialty': AppLocalizations.of(context)!.specialties,
            'workMode': AppLocalizations.of(context)!.workMode,
            'projects': AppLocalizations.of(context)!.projects,
            'certifications': AppLocalizations.of(context)!.certifications,
          };
          final preview = DigitalCard(
            id: card.id,
            label: card.label,
            displayName: card.displayName,
            role: card.role,
            company: card.company,
            email: card.email,
            phone: card.phone,
            website: card.website,
            primaryHex: card.primaryHex,
            kind: card.kind,
            layout: card.layout,
            bio: card.bio,
            photoPath: card.photoPath,
            professional: card.professional,
            visibleFields: fields!.toList(),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NetworkPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.net1ChoosePublicFields,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.nameAndLabelAlwaysAppear,
                    ),
                    const SizedBox(height: ResonSpace.md),
                    Wrap(
                      spacing: 7,
                      runSpacing: 5,
                      children: [
                        for (final f in card.visibleFields)
                          FilterChip(
                            label: Text(labels[f] ?? f),
                            selected: fields!.contains(f),
                            onSelected: busy
                                ? null
                                : (v) => setState(
                                    () =>
                                        v ? fields!.add(f) : fields!.remove(f),
                                  ),
                          ),
                      ],
                    ),
                    if (fields!.contains('phone') && card.phone.isNotEmpty)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          AppLocalizations.of(context)!.allowWhatsappContact,
                        ),
                        subtitle: Text(
                          AppLocalizations.of(
                            context,
                          )!.usesThePublishedNumberIncluding,
                        ),
                        value: whatsapp,
                        onChanged: busy
                            ? null
                            : (v) => setState(() => whatsapp = v),
                      ),
                  ],
                ),
              ),
              Text(
                AppLocalizations.of(context)!.net2DataPreview,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: ResonSpace.md),
              CardPreview(card: preview, heroTag: cardHeroTag(widget.cardId)),
              const SizedBox(height: ResonSpace.lg),
              Text(AppLocalizations.of(context)!.thePublicPageAdaptsThese),
              const SizedBox(height: ResonSpace.lg),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: ResonSpace.md),
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              FilledButton.icon(
                onPressed: busy ? null : () => act('publish'),
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.publish_outlined),
                label: Text(
                  url == null
                      ? AppLocalizations.of(context)!.publishAndCreateQr
                      : AppLocalizations.of(context)!.updatePublication,
                ),
              ),
              if (url != null) ...[
                const SizedBox(height: ResonSpace.xl),
                NetworkPanel(
                  child: Column(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.yourLinkIsLive,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: ResonSpace.lg),
                      Container(
                        padding: const EdgeInsets.all(ResonSpace.md),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(ResonRadius.lg),
                        ),
                        child: QrImageView(
                          data: url,
                          size: 200,
                          backgroundColor: Colors.white,
                          semanticsLabel: AppLocalizations.of(
                            context,
                          )!.publicCardQr,
                        ),
                      ),
                      const SizedBox(height: ResonSpace.lg),
                      SelectableText(url, textAlign: TextAlign.center),
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: url));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppLocalizations.of(context)!.linkCopied,
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.copy),
                            label: Text(AppLocalizations.of(context)!.copyLink),
                          ),
                          TextButton.icon(
                            onPressed: () => launchUrl(
                              Uri.parse(url),
                              mode: LaunchMode.externalApplication,
                            ),
                            icon: const Icon(Icons.open_in_new),
                            label: Text(AppLocalizations.of(context)!.open),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: busy ? null : () => act('unpublish'),
                        child: Text(
                          AppLocalizations.of(context)!.unpublishCard,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.unpublishingDisablesTheLinkAnd,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
