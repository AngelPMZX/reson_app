import 'package:flutter/material.dart';
import '../../core/theme/reson_surfaces.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../cards/application/cards_providers.dart';
import '../cards/domain/digital_card.dart';
import '../cards/presentation/card_preview.dart';
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
      title: tr(context, 'Compartir tu identidad', 'Share your identity'),
      subtitle: tr(
        context,
        'Publica solo lo que quieras compartir. Cualquier persona con el enlace podrá verlo y reenviarlo.',
        'Publish only what you want to share. Anyone with the link can view and forward it.',
      ),
      child: cards.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text(networkErrorText(context, e)),
        data: (items) {
          final card = items.where((c) => c.id == widget.cardId).firstOrNull;
          if (card == null) {
            return Text(
              tr(context, 'Tarjeta no disponible', 'Card unavailable'),
            );
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
            'photo': tr(context, 'Fotografía', 'Photo'),
            'role': tr(context, 'Puesto', 'Role'),
            'company': tr(context, 'Empresa', 'Company'),
            'email': tr(context, 'Correo de contacto', 'Contact email'),
            'phone': tr(context, 'Teléfono', 'Phone'),
            'website': tr(context, 'Sitio web', 'Website'),
            'bio': tr(context, 'Biografía', 'Bio'),
            'location': tr(context, 'Ubicación', 'Location'),
            'linkedin': 'LinkedIn',
            'skills': tr(context, 'Habilidades', 'Skills'),
            'experience': tr(context, 'Experiencia', 'Experience'),
            'education': tr(context, 'Educación', 'Education'),
            'sector': tr(context, 'Sector', 'Industry'),
            'specialty': tr(context, 'Especialidades', 'Specialties'),
            'workMode': tr(context, 'Modalidad', 'Work mode'),
            'projects': tr(context, 'Proyectos', 'Projects'),
            'certifications': tr(context, 'Certificaciones', 'Certifications'),
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
                      tr(
                        context,
                        '1 · Elige los campos públicos',
                        '1 · Choose public fields',
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      tr(
                        context,
                        'El nombre y la etiqueta siempre aparecen. Los campos ocultos en tu tarjeta no se publican.',
                        'Name and label always appear. Fields hidden on your card are not published.',
                      ),
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
                          tr(
                            context,
                            'Permitir contacto por WhatsApp',
                            'Allow WhatsApp contact',
                          ),
                        ),
                        subtitle: Text(
                          tr(
                            context,
                            'Usará el número publicado con código de país.',
                            'Uses the published number including country code.',
                          ),
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
                tr(
                  context,
                  '2 · Vista previa de los datos',
                  '2 · Data preview',
                ),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: ResonSpace.md),
              CardPreview(card: preview, heroTag: cardHeroTag(widget.cardId)),
              const SizedBox(height: ResonSpace.lg),
              Text(
                tr(
                  context,
                  'La página pública adapta estos datos al navegador. Los cambios no se aplican al enlace hasta que publiques de nuevo.',
                  'The public page adapts these details to the browser. Changes only reach your link when you publish again.',
                ),
              ),
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
                  tr(
                    context,
                    url == null
                        ? 'Publicar y crear QR'
                        : 'Actualizar publicación',
                    url == null
                        ? 'Publish and create QR'
                        : 'Update publication',
                  ),
                ),
              ),
              if (url != null) ...[
                const SizedBox(height: ResonSpace.xl),
                NetworkPanel(
                  child: Column(
                    children: [
                      Text(
                        tr(
                          context,
                          'Tu enlace está activo',
                          'Your link is live',
                        ),
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
                          semanticsLabel: tr(
                            context,
                            'QR de tu tarjeta pública',
                            'Public card QR',
                          ),
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
                                      tr(
                                        context,
                                        'Enlace copiado',
                                        'Link copied',
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.copy),
                            label: Text(
                              tr(context, 'Copiar enlace', 'Copy link'),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => launchUrl(
                              Uri.parse(url),
                              mode: LaunchMode.externalApplication,
                            ),
                            icon: const Icon(Icons.open_in_new),
                            label: Text(tr(context, 'Abrir', 'Open')),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: busy ? null : () => act('unpublish'),
                        child: Text(
                          tr(context, 'Despublicar tarjeta', 'Unpublish card'),
                        ),
                      ),
                      Text(
                        tr(
                          context,
                          'Despublicar desactiva el enlace y el QR. No borra contactos descargados previamente.',
                          'Unpublishing disables the link and QR. Previously downloaded contacts cannot be revoked.',
                        ),
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
