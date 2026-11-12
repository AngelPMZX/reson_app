part of 'card_preview.dart';

/// The default identity card adapts its composition to the selected purpose.
class _CredentialCard extends StatelessWidget {
  const _CredentialCard({required this.card, this.photoBytes});
  final DigitalCard card;
  final Uint8List? photoBytes;

  @override
  Widget build(BuildContext context) {
    final work = card.kind == 'work';
    final freelance = card.kind == 'freelance';
    final seed = cardColor(card.primaryHex);
    final skin = context.credentials.skin(card.layout);
    final ink = Color.lerp(seed, skin.backdrop, skin.blend)!;
    final accent = Color.lerp(seed, Colors.black, .3)!;
    final wash = Color.lerp(seed, Colors.white, .91)!;
    final title = work
        ? AppLocalizations.of(context)!.credentialProfessionalIdentity
        : freelance
        ? AppLocalizations.of(context)!.credentialIndependentTalent
        : AppLocalizations.of(context)!.credentialPersonalConnections;
    final icon = work
        ? Icons.badge_outlined
        : freelance
        ? Icons.auto_awesome_outlined
        : Icons.favorite_border_rounded;
    final name = card.displayName.isEmpty
        ? AppLocalizations.of(context)!.cardYourName
        : card.displayName;
    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: TextStyle(
            color: ink,
            fontSize: 25,
            height: 1.12,
            letterSpacing: -.8,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (card.shows('role') && card.role.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            card.role,
            style: TextStyle(
              color: accent,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (card.shows('company') && card.company.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            card.company,
            style: TextStyle(color: ink, fontSize: 12, height: 1.4),
          ),
        ],
      ],
    );
    return Container(
      key: ValueKey('credential_${card.kind}'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(work ? 22 : 30),
        border: Border.all(color: Color.lerp(seed, Colors.white, .73)!),
        boxShadow: [
          BoxShadow(
            color: seed.withValues(alpha: .12),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            color: work ? ink : wash,
            child: Row(
              children: [
                Icon(
                  Icons.graphic_eq_rounded,
                  size: 23,
                  color: work ? Colors.white : accent,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    card.label.isEmpty ? 'reson' : card.label,
                    style: TextStyle(
                      color: work ? Colors.white : ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(icon, color: work ? Colors.white70 : accent, size: 21),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (work) ...[
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: wash,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
                Text(
                  title,
                  style: TextStyle(
                    color: accent,
                    fontSize: 9,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, box) {
                    final portrait = Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: wash,
                        borderRadius: BorderRadius.circular(work ? 18 : 50),
                      ),
                      child: CardPortrait(card: card, bytes: photoBytes),
                    );
                    if (!card.shows('photo')) return identity;
                    if (freelance ||
                        box.maxWidth < 270 ||
                        MediaQuery.textScalerOf(context).scale(1) > 1.3) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          portrait,
                          const SizedBox(height: 18),
                          identity,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        portrait,
                        const SizedBox(width: 16),
                        Expanded(child: identity),
                      ],
                    );
                  },
                ),
                if (card.shows('bio') && card.bio.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    card.bio,
                    style: TextStyle(color: ink, fontSize: 13, height: 1.5),
                  ),
                ],
                const SizedBox(height: 20),
                Divider(color: wash, height: 1, thickness: 2),
                for (final item in [
                  ('email', card.email, Icons.alternate_email_rounded),
                  ('phone', card.phone, Icons.phone_outlined),
                  ('website', card.website, Icons.language_rounded),
                ])
                  if (card.shows(item.$1) && item.$2.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 13),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(item.$3, size: 16, color: accent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.$2,
                              style: TextStyle(
                                color: ink,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
          Container(
            color: wash,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            child: Row(
              children: [
                Text(
                  'reson',
                  style: TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: -.6,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.credentialTagline,
                    textAlign: TextAlign.end,
                    style: TextStyle(color: accent, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
