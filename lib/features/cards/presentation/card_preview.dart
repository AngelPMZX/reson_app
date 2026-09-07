import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/card_media_repository.dart';
import '../domain/digital_card.dart';

Color cardColor(String hex) => RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(hex)
    ? Color(int.parse('FF${hex.substring(1)}', radix: 16))
    : const Color(0xFF7860E9);

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
          color: const Color(0xFF6C4AA1),
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

class CardPreview extends StatelessWidget {
  const CardPreview({super.key, required this.card, this.photoBytes});
  final DigitalCard card;
  final Uint8List? photoBytes;
  @override
  Widget build(BuildContext context) {
    final seed = cardColor(card.primaryHex);
    final minimal = card.layout == 'minimal';
    final bold = card.layout == 'bold';
    final dark = Color.lerp(seed, const Color(0xFF130C27), .76)!;
    final fg = minimal ? const Color(0xFF241636) : Colors.white;
    final muted = minimal ? const Color(0xFF655477) : const Color(0xFFE2D5F7);
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
                        ? [const Color(0xFFFDFBFF), const Color(0xFFEAE0F8)]
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
                          color: minimal ? seed : const Color(0xFFD6C0FF),
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
