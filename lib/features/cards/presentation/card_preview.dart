import 'professional_summary.dart';
import 'card_artwork.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/card_media_repository.dart';
import '../../../core/theme/reson_palette.dart';
import '../../../core/theme/reson_tokens.dart';
import '../domain/digital_card.dart';

part 'credential_card.dart';

Color cardColor(String hex) => RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(hex)
    ? Color(int.parse('FF${hex.substring(1)}', radix: 16))
    : ResonPalette.carmine;

/// Shared tag that lets one credential fly between the wallet, the editor and
/// the share screen. Only one widget per screen may carry a given tag.
String cardHeroTag(String cardId) => 'credential_$cardId';

class CardPortrait extends ConsumerWidget {
  const CardPortrait({super.key, required this.card, this.bytes});
  final DigitalCard card;
  final Uint8List? bytes;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data =
        bytes ??
        (card.photoPath.isEmpty
            ? null
            : ref.watch(cardPhotoProvider(card.photoPath)).asData?.value);
    final fallback = Center(
      child: Text(
        card.displayName.trim().isEmpty
            ? 'R'
            : card.displayName.trim().characters.first.toUpperCase(),
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
    return Container(
      width: 76,
      height: 76,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: .45)),
      ),
      child: ClipOval(
        child: ColoredBox(
          color: cardColor(card.primaryHex),
          child: data == null
              ? fallback
              : Image.memory(
                  data,
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stack) => fallback,
                ),
        ),
      ),
    );
  }
}

class _ClassicCard extends StatelessWidget {
  const _ClassicCard({required this.card, this.photoBytes});
  final DigitalCard card;
  final Uint8List? photoBytes;
  @override
  Widget build(BuildContext context) {
    final seed = cardColor(card.primaryHex);
    final minimal = card.layout == 'minimal';
    final bold = card.layout == 'bold';
    final skin = context.credentials.skin(card.layout);
    final dark = Color.lerp(seed, skin.backdrop, skin.blend)!;
    final fg = skin.ink;
    final muted = skin.muted;
    final es = Localizations.localeOf(context).languageCode == 'es';
    Widget line(String field, String text, IconData icon) =>
        card.shows(field) && text.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 16, color: muted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(color: muted, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: seed.withValues(alpha: .16),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: minimal
                        ? [ResonPalette.paperRose, ResonPalette.paperRoseDeep]
                        : bold
                        ? [Color.lerp(seed, Colors.black, .25)!, dark]
                        : [dark, Color.lerp(seed, dark, .38)!],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -75,
              right: -80,
              child: ExcludeSemantics(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: fg.withValues(alpha: .10),
                      width: 36,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: DefaultTextStyle(
                style: TextStyle(
                  color: fg,
                  fontFamily: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.fontFamily,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.graphic_eq_rounded,
                          color: skin.accent ?? seed,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            card.label.isEmpty
                                ? (es
                                      ? 'Tu nueva identidad'
                                      : 'Your new identity')
                                : card.label,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .6,
                            ),
                          ),
                        ),
                        Icon(
                          bold ? Icons.auto_awesome : Icons.north_east,
                          size: 20,
                          color: muted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    if (card.shows('photo')) ...[
                      CardPortrait(card: card, bytes: photoBytes),
                      const SizedBox(height: 18),
                    ],
                    Text(
                      card.displayName.isEmpty
                          ? (es ? 'Tu nombre' : 'Your name')
                          : card.displayName,
                      style: TextStyle(
                        fontSize: bold ? 32 : 27,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.8,
                      ),
                    ),
                    if (card.shows('role') && card.role.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          card.role,
                          style: TextStyle(fontSize: 15, color: muted),
                        ),
                      ),
                    if (card.shows('company') && card.company.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          card.company,
                          style: TextStyle(fontSize: 13, color: muted),
                        ),
                      ),
                    if (card.shows('bio') && card.bio.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          card.bio,
                          style: TextStyle(color: muted, height: 1.5),
                        ),
                      ),
                    const SizedBox(height: 18),
                    Divider(color: fg.withValues(alpha: .18), height: 1),
                    line('email', card.email, Icons.alternate_email),
                    line('phone', card.phone, Icons.phone_outlined),
                    line('website', card.website, Icons.language),
                    const SizedBox(height: 20),
                    Text(
                      'RESON  /  ${card.kind == 'work' ? (es ? 'PROFESIONAL' : 'PROFESSIONAL') : card.kind.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 9,
                        color: muted,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CardPreview extends StatelessWidget {
  const CardPreview({
    super.key,
    required this.card,
    this.photoBytes,
    this.heroTag,
  });
  final DigitalCard card;
  final Uint8List? photoBytes;

  /// When set, the credential itself flies to the next screen. Build it with
  /// [cardHeroTag] and leave it null wherever the same card is already shown.
  final String? heroTag;
  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _flight(
          TweenAnimationBuilder<double>(
            key: ValueKey('${card.layout}/${card.primaryHex}'),
            tween: Tween(begin: motion.isStill ? 1 : 0, end: 1),
            duration: motion.entrance,
            curve: motion.standard,
            builder: (context, value, _) => Opacity(
              opacity: .5 + value * .5,
              child: Transform.translate(
                offset: Offset(0, 12 * (1 - value)),
                child: card.layout == 'signature'
                    ? _CredentialCard(card: card, photoBytes: photoBytes)
                    : ['noir', 'studio'].contains(card.layout)
                    ? _PortfolioCard(card: card, photoBytes: photoBytes)
                    : ['aurora', 'executive', 'editorial'].contains(card.layout)
                    ? _DesignedCard(
                        card: card,
                        photoBytes: photoBytes,
                        progress: value,
                      )
                    : _ClassicCard(card: card, photoBytes: photoBytes),
              ),
            ),
          ),
        ),
        ProfessionalSummary(card: card),
      ],
    );
  }

  /// Wraps the credential in its [Hero] when a tag is set. The trajectory
  /// summary stays behind: its height differs per screen, so carrying it would
  /// distort the card mid-flight.
  Widget _flight(Widget credential) => heroTag == null
      ? credential
      : Hero(
          tag: heroTag!,
          // Mid-flight the credential is laid out at an interpolated height,
          // which overflows its own column by a fraction of a pixel. Giving
          // the shuttle unbounded height lets it keep its natural size and
          // simply be scaled into the rect the flight is drawing.
          flightShuttleBuilder: (_, _, _, _, toHero) => Material(
            type: MaterialType.transparency,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: toHero.widget,
            ),
          ),
          child: credential,
        );
}

class _DesignedCard extends StatelessWidget {
  const _DesignedCard({
    required this.card,
    this.photoBytes,
    required this.progress,
  });
  final DigitalCard card;
  final Uint8List? photoBytes;
  final double progress;
  @override
  Widget build(BuildContext context) {
    final seed = cardColor(card.primaryHex);
    final editorial = card.layout == 'editorial';
    final executive = card.layout == 'executive';
    final skin = context.credentials.skin(card.layout);
    final fg = skin.ink;
    final subtle = skin.muted;
    final accent = Color.lerp(seed, Colors.white, .6)!;
    final dark = Color.lerp(seed, skin.backdrop, skin.blend)!;
    final es = Localizations.localeOf(context).languageCode == 'es';
    final name = card.displayName.isEmpty
        ? (es ? 'Tu nombre' : 'Your name')
        : card.displayName;
    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: TextStyle(
            color: fg,
            fontSize: editorial ? 32 : 27,
            height: 1.1,
            fontWeight: executive ? FontWeight.w500 : FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        if (card.shows('role') && card.role.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              card.role,
              style: TextStyle(color: subtle, fontSize: 14, height: 1.4),
            ),
          ),
        if (card.shows('company') && card.company.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              card.company,
              style: TextStyle(color: subtle, fontSize: 12, letterSpacing: 1),
            ),
          ),
      ],
    );
    final contacts = <Widget>[
      for (final item in [
        ('email', card.email, Icons.alternate_email_rounded),
        ('phone', card.phone, Icons.phone_outlined),
        ('website', card.website, Icons.language_rounded),
      ])
        if (card.shows(item.$1) && item.$2.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: editorial
                  ? Colors.white.withValues(alpha: .8)
                  : Colors.white.withValues(alpha: .065),
              borderRadius: BorderRadius.circular(executive ? 4 : 14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.$3, size: 17, color: editorial ? skin.muted : accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.$2,
                    style: TextStyle(color: subtle, fontSize: 13, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
    ];
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(executive ? 12 : 28),
        boxShadow: [
          BoxShadow(
            color: seed.withValues(alpha: .17),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(executive ? 12 : 28),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: editorial
                  ? [
                      ResonPalette.paperCream,
                      Color.lerp(seed, Colors.white, .89)!,
                    ]
                  : executive
                  ? [dark, ResonPalette.coal]
                  : [dark, Color.lerp(seed, ResonPalette.nightWine, .6)!],
            ),
          ),
          child: CustomPaint(
            painter: CardArtwork(
              card.layout,
              editorial ? seed : accent,
              progress,
            ),
            child: Padding(
              padding: EdgeInsets.all(executive ? 30 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.graphic_eq_rounded,
                        color: editorial ? dark : accent,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          card.label.isEmpty ? 'RESON' : card.label,
                          style: TextStyle(
                            color: subtle,
                            fontSize: 11,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        executive
                            ? Icons.diamond_outlined
                            : Icons.auto_awesome_outlined,
                        color: subtle,
                        size: 17,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  if (editorial) ...[
                    Container(height: 6, width: 52, color: seed),
                    const SizedBox(height: 22),
                    identity,
                    if (card.shows('photo')) ...[
                      const SizedBox(height: 22),
                      CardPortrait(card: card, bytes: photoBytes),
                    ],
                  ] else ...[
                    if (card.shows('photo')) ...[
                      Align(
                        alignment: executive
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: CardPortrait(card: card, bytes: photoBytes),
                      ),
                      const SizedBox(height: 24),
                    ],
                    identity,
                  ],
                  if (card.shows('bio') && card.bio.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 22),
                      child: Text(
                        card.bio,
                        style: TextStyle(
                          color: subtle,
                          height: 1.6,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Divider(color: fg.withValues(alpha: .15), height: 1),
                  const SizedBox(height: 12),
                  ...contacts,
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: editorial ? dark : accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'RESON / ${card.kind.toUpperCase()}',
                        style: TextStyle(
                          color: subtle,
                          fontSize: 9,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  const _PortfolioCard({required this.card, this.photoBytes});
  final DigitalCard card;
  final Uint8List? photoBytes;
  @override
  Widget build(BuildContext context) {
    final studio = card.layout == 'studio';
    final seed = cardColor(card.primaryHex);
    final skin = context.credentials.skin(card.layout);
    final fg = skin.ink;
    final minor = skin.muted;
    final es = Localizations.localeOf(context).languageCode == 'es';
    return ClipRRect(
      borderRadius: BorderRadius.circular(studio ? 28 : 8),
      child: Container(
        width: double.infinity,
        color: skin.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (studio)
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      seed,
                      Color.lerp(seed, skin.backdrop, skin.blend)!,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(Icons.graphic_eq, color: Colors.white),
                      const Spacer(),
                      Expanded(
                        flex: 3,
                        child: Text(
                          card.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(26),
              child: DefaultTextStyle(
                style: TextStyle(color: fg, fontFamily: 'Roboto'),
                child: Column(
                  crossAxisAlignment: studio
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    if (!studio) ...[
                      Row(
                        children: [
                          Icon(Icons.graphic_eq, color: minor),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              card.label,
                              style: TextStyle(
                                color: minor,
                                fontSize: 11,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Container(
                        height: 2,
                        width: 48,
                        color: Color.lerp(seed, Colors.white, .65),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (card.shows('photo')) ...[
                      Align(
                        alignment: studio
                            ? Alignment.center
                            : Alignment.centerLeft,
                        child: CardPortrait(card: card, bytes: photoBytes),
                      ),
                      const SizedBox(height: 20),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        card.displayName.isEmpty
                            ? (es ? 'Tu nombre' : 'Your name')
                            : card.displayName,
                        textAlign: studio ? TextAlign.center : TextAlign.left,
                        style: TextStyle(
                          fontSize: studio ? 29 : 36,
                          height: 1.1,
                          fontWeight: studio
                              ? FontWeight.w700
                              : FontWeight.w300,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    if (card.shows('role') && card.role.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          card.role,
                          style: TextStyle(color: minor, height: 1.5),
                        ),
                      ),
                    if (card.shows('company') && card.company.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          card.company,
                          style: TextStyle(color: minor, fontSize: 12),
                        ),
                      ),
                    if (card.shows('bio') && card.bio.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 22),
                        child: Text(
                          card.bio,
                          textAlign: studio ? TextAlign.center : TextAlign.left,
                          style: TextStyle(color: minor, height: 1.7),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Divider(color: minor.withValues(alpha: .25)),
                    for (final item in [
                      ('email', card.email, Icons.alternate_email),
                      ('phone', card.phone, Icons.phone_outlined),
                      ('website', card.website, Icons.language),
                    ])
                      if (card.shows(item.$1) && item.$2.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(item.$3, color: minor, size: 16),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.$2,
                                  style: TextStyle(color: minor, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                    const SizedBox(height: 20),
                    Text(
                      'R E S O N',
                      style: TextStyle(color: minor, fontSize: 9),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
