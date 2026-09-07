import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/reson_theme.dart';
import '../../../l10n/generated/app_localizations.dart';

class ResonLogo extends StatelessWidget {
  const ResonLogo({super.key, this.dark = true});
  final bool dark;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: ResonTheme.violet,
          borderRadius: BorderRadius.circular(11),
        ),
        child: const Icon(
          Icons.graphic_eq_rounded,
          color: Colors.white,
          size: 25,
        ),
      ),
      const SizedBox(width: 10),
      Text(
        'reson',
        style: TextStyle(
          fontSize: 28,
          letterSpacing: -1.2,
          fontWeight: FontWeight.w700,
          color: dark ? Colors.white : ResonTheme.ink,
        ),
      ),
    ],
  );
}

class BrandBackground extends StatelessWidget {
  const BrandBackground({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: RadialGradient(
        center: Alignment(0.8, -0.3),
        radius: 1.4,
        colors: [Color(0xFF302345), ResonTheme.night],
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
                          color: const Color(0xFF443653),
                          borderRadius: BorderRadius.circular(23),
                          border: Border.all(color: const Color(0xFF776086)),
                        ),
                      ),
                    ),
                    Transform.rotate(
                      angle: 0.075,
                      child: Container(
                        width: width,
                        height: 204,
                        decoration: BoxDecoration(
                          color: const Color(0xFF9983E7),
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
                          colors: [Color(0xFFEDE5FF), Color(0xFFCCBCEB)],
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
                                color: Color(0xFF43325F),
                              ),
                              const SizedBox(width: 8),
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
                                      backgroundColor: Color(0xFFB6A1D4),
                                      child: Text(
                                        'AM',
                                        style: TextStyle(
                                          color: Color(0xFF3B2856),
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      s.sampleName,
                                      style: const TextStyle(
                                        color: Color(0xFF2E2243),
                                        fontSize: 23,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.8,
                                      ),
                                    ),
                                    Text(
                                      s.sampleRole,
                                      style: const TextStyle(
                                        color: Color(0xFF5A476E),
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
                                  color: Color(0xFF3B2856),
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
              color: Color(0xFFB8ACCD),
              fontSize: 9,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 20),
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
                          ? const Color(0xFF443456)
                          : const Color(0xFF24202E),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: const Color(0xFF554462)),
                    ),
                    child: Text(
                      entry.$2,
                      style: TextStyle(
                        color: entry.$1 == 0
                            ? const Color(0xFFE7D7FF)
                            : const Color(0xFFBAB2C8),
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
        color: error ? const Color(0xFFFFEEEE) : const Color(0xFFEEEAF9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            error ? Icons.error_outline : Icons.info_outline,
            size: 19,
            color: error ? const Color(0xFFA52A38) : ResonTheme.violet,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: error
                    ? const Color(0xFFA52A38)
                    : const Color(0xFF574B72),
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
