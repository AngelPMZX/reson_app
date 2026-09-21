import '../../../core/theme/reson_palette.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/reson_motion.dart';
import '../../../l10n/generated/app_localizations.dart';

class AuthWelcome extends StatefulWidget {
  const AuthWelcome({super.key, this.compact = false});
  final bool compact;
  @override
  State<AuthWelcome> createState() => _AuthWelcomeState();
}

class _AuthWelcomeState extends State<AuthWelcome> {
  int replay = 0;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(widget.compact ? 20 : 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ResonPalette.deepWine, ResonPalette.coal],
        ),
        border: Border.all(
          color: ResonPalette.darkBorder.withValues(alpha: .5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.blur_on_rounded,
                color: ResonPalette.white,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.authEyebrow,
                  style: const TextStyle(
                    color: ResonPalette.white,
                    fontSize: 9,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
              IconButton(
                tooltip: s.replayAnimation,
                onPressed: () => setState(() => replay++),
                icon: const Icon(
                  Icons.replay_rounded,
                  color: ResonPalette.white,
                  size: 18,
                ),
              ),
            ],
          ),
          ResonReveal(
            key: ValueKey(replay),
            distance: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(
                  s.authVisualTitle,
                  style: TextStyle(
                    fontSize: widget.compact ? 27 : 36,
                    height: 1.1,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 20),
                for (final item in [
                  (Icons.palette_outlined, s.authBenefit1),
                  (Icons.badge_outlined, s.authBenefit2),
                  (Icons.lock_outline, s.authBenefit3),
                ])
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(item.$1, color: ResonPalette.white, size: 17),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.$2,
                            style: const TextStyle(
                              color: ResonPalette.paleGrey,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
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
