import '../../../core/theme/reson_palette.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/reson_surfaces.dart';
import '../../../core/theme/reson_theme.dart';
import '../../../l10n/generated/app_localizations.dart';

class BrandBackground extends StatelessWidget {
  const BrandBackground({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: RadialGradient(
        center: Alignment(0.8, -0.3),
        radius: 1.4,
        colors: [ResonPalette.wine, ResonTheme.night],
      ),
    ),
    child: child,
  );
}

class IdentityPreview extends StatelessWidget {
  const IdentityPreview({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Semantics(
      label: s.sampleLabel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: compact ? 250 : 310,
            width: 400,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = math.min(constraints.maxWidth - 30, 340.0);
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.rotate(
                      angle: -0.12,
                      child: Container(
                        width: width,
                        height: 204,
                        decoration: BoxDecoration(
                          color: ResonPalette.wine,
                          borderRadius: BorderRadius.circular(23),
                          border: Border.all(color: ResonPalette.darkBorder),
                        ),
                      ),
                    ),
                    Transform.rotate(
                      angle: 0.075,
                      child: Container(
                        width: width,
                        height: 204,
                        decoration: BoxDecoration(
                          color: ResonPalette.carmine,
                          borderRadius: BorderRadius.circular(23),
                        ),
                      ),
                    ),
                    Container(
                      width: width,
                      padding: const EdgeInsets.all(23),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [ResonPalette.ivory, ResonPalette.ivory],
                        ),
                        borderRadius: BorderRadius.circular(23),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x44000000),
                            blurRadius: 40,
                            offset: Offset(0, 20),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.blur_on_rounded,
                                color: ResonPalette.grey,
                              ),
                              const SizedBox(width: ResonSpace.sm),
                              Expanded(
                                child: Text(
                                  s.sampleCompany,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Icon(Icons.north_east, size: 18),
                            ],
                          ),
                          // The sample card is artwork on a fixed canvas, so
                          // its inner gaps stay hand-set rather than snapping
                          // to the app rhythm and overflowing the frame.
                          const SizedBox(height: 26),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const CircleAvatar(
                                      radius: 21,
                                      backgroundColor: ResonPalette.carmine,
                                      child: Text(
                                        'AM',
                                        style: TextStyle(
                                          color: ResonPalette.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: ResonSpace.md),
                                    Text(
                                      s.sampleName,
                                      style: const TextStyle(
                                        color: ResonPalette.coal,
                                        fontSize: 23,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.8,
                                      ),
                                    ),
                                    Text(
                                      s.sampleRole,
                                      style: const TextStyle(
                                        color: ResonPalette.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const ExcludeSemantics(
                                child: Icon(
                                  Icons.qr_code_2_rounded,
                                  size: 49,
                                  color: ResonPalette.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Text(
            s.sampleLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ResonPalette.paleGrey,
              fontSize: 9,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: ResonSpace.xl),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [s.sampleWork, s.sampleFreelance, s.samplePersonal]
                .indexed
                .map(
                  (entry) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: entry.$1 == 0
                          ? ResonPalette.wine
                          : ResonPalette.coal,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: ResonPalette.darkBorder),
                    ),
                    child: Text(
                      entry.$2,
                      style: TextStyle(
                        color: entry.$1 == 0
                            ? ResonPalette.white
                            : ResonPalette.paleGrey,
                        fontSize: 11,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class FeedbackMessage extends StatelessWidget {
  const FeedbackMessage({super.key, required this.text, this.error = false});
  final String text;
  final bool error;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: error ? const Color(0xFFFFEEEE) : ResonPalette.blush,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            error ? Icons.error_outline : Icons.info_outline,
            size: 19,
            color: error ? const Color(0xFFA52A38) : ResonTheme.brand,
          ),
          const SizedBox(width: ResonSpace.md),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: error ? const Color(0xFFA52A38) : ResonPalette.grey,
                height: 1.5,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
