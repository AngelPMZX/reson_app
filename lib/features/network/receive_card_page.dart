import 'package:flutter/material.dart';
import '../../core/theme/reson_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../cards/domain/digital_card.dart';
import '../cards/domain/professional_profile.dart';
import '../cards/presentation/card_preview.dart';
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
          () => feedback = tr(
            context,
            action == 'save'
                ? 'Tarjeta guardada en tu red.'
                : 'Solicitud enviada. Podrán conversar cuando sea aceptada.',
            action == 'save'
                ? 'Card saved in your network.'
                : 'Request sent. Chat becomes available after acceptance.',
          ),
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
      title: tr(context, 'Una nueva conexión', 'A new connection'),
      subtitle: tr(
        context,
        'Guarda esta tarjeta o presenta una de las tuyas para conectar.',
        'Save this card or introduce yourself with one of yours.',
      ),
      child: result.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => NetworkPanel(
          child: Column(
            children: [
              Text(networkErrorText(context, e)),
              TextButton(
                onPressed: () =>
                    ref.invalidate(sharedCardProvider(widget.publicId)),
                child: Text(tr(context, 'Reintentar', 'Retry')),
              ),
            ],
          ),
        ),
        data: (p) {
          final card = DigitalCard(
            id: widget.publicId,
            label: p['label'] as String,
            displayName: p['name'] as String,
            role: p['role'] as String,
            company: p['company'] as String,
            email: p['email'] as String,
            phone: p['phone'] as String,
            website: p['website'] as String,
            primaryHex: p['color'] as String,
            kind: p['kind'] as String,
            layout: p['layout'] as String,
            bio: p['bio'] as String,
            professional: ProfessionalProfile.fromMap(
              Map<String, dynamic>.from(p['professional'] as Map),
            ),
            visibleFields: List<String>.from(p['visibleFields'] as List)
              ..remove('photo'),
          );
          final ownCards =
              publications.asData?.value
                  .where((v) => v.data()['active'] == true)
                  .toList() ??
              [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if ((p['photoUrl'] as String).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: ResonSpace.lg),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(ResonRadius.lg),
                      child: Image.network(
                        p['photoUrl'] as String,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        errorBuilder: (_, e, st) =>
                            const Icon(Icons.person, size: 60),
                      ),
                    ),
                  ),
                ),
              CardPreview(card: card),
              const SizedBox(height: ResonSpace.xl),
              FilledButton.icon(
                onPressed: busy ? null : () => act('save'),
                icon: const Icon(Icons.bookmark_add_outlined),
                label: Text(
                  tr(context, 'Guardar en mi red', 'Save to my network'),
                ),
              ),
              const SizedBox(height: ResonSpace.md),
              OutlinedButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse('https://reson-app.web.app/c/${widget.publicId}'),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new),
                label: Text(
                  tr(
                    context,
                    'Ver opciones de contacto',
                    'View contact options',
                  ),
                ),
              ),
              const SizedBox(height: ResonSpace.xl),
              NetworkPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      tr(context, 'Intercambiar tarjetas', 'Exchange cards'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: ResonSpace.md),
                    Text(
                      tr(
                        context,
                        'Elige qué tarjeta publicada enviar. Tu perfil privado no se comparte.',
                        'Choose which published card to send. Your private profile is not shared.',
                      ),
                    ),
                    const SizedBox(height: ResonSpace.lg),
                    if (ownCards.isEmpty)
                      Text(
                        tr(
                          context,
                          'Publica una tarjeta desde Mis tarjetas para solicitar conexiones.',
                          'Publish a card from My cards to request connections.',
                        ),
                      )
                    else ...[
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: own,
                        decoration: InputDecoration(
                          labelText: tr(context, 'Tu tarjeta', 'Your card'),
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
                          tr(
                            context,
                            'Solicitar conexión',
                            'Request connection',
                          ),
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
