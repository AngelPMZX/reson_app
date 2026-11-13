import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import 'reson_palette.dart';
import 'reson_surfaces.dart';
import 'reson_theme.dart';

/// Whether the screen is too narrow for a row to also carry labels.
///
/// One threshold for the whole app, so the wordmark, the back link and a
/// conversation's actions all shed their words at the same width instead of
/// each guessing. 320 pixel phones are the case this exists for.
bool resonCompact(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 360;

/// The app-wide theme and language controls.
///
/// These used to float over the whole app from a `Stack` in `MaterialApp`, so
/// every screen had to leave a hole for them by hand: 132 logical pixels of
/// empty `AppBar` action in the chat, 80 of top padding in the profile, and an
/// unspoken agreement everywhere else. Laying them out instead of stacking them
/// means they cannot cover anything, and a new screen gets them by composing
/// [ResonHeader] rather than by remembering a magic number.
class ResonControls extends ConsumerWidget {
  const ResonControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    // Cycles whatever the app supports instead of flipping between two fixed
    // languages, so adding one to the ARB files is enough to reach it here.
    final supported = AppLocalizations.supportedLocales;
    final current = supported.indexWhere(
      (l) => l.languageCode == Localizations.localeOf(context).languageCode,
    );
    final next = supported[(current + 1) % supported.length];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: AppLocalizations.of(context)!.switchTheme,
          button: true,
          child: IconButton(
            key: const Key('themeToggle'),
            style: IconButton.styleFrom(
              backgroundColor: scheme.surfaceContainerHighest,
              foregroundColor: scheme.onSurface,
            ),
            onPressed: () => ref.read(appearanceProvider.notifier).toggle(),
            // Reads the brightness actually on screen: under ThemeMode.system
            // the mode alone does not say which one is showing.
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
        ),
        const SizedBox(width: ResonSpace.sm),
        Semantics(
          label: AppLocalizations.of(context)!.language,
          button: true,
          child: TextButton(
            key: const Key('languageToggle'),
            style: TextButton.styleFrom(
              backgroundColor: scheme.surfaceContainerHighest,
              foregroundColor: scheme.onSurface,
              minimumSize: const Size(48, 40),
              textStyle: Theme.of(context).textTheme.labelSmall,
            ),
            onPressed: () => ref.read(localeProvider.notifier).set(next),
            child: Text(next.languageCode.toUpperCase()),
          ),
        ),
      ],
    );
  }
}

/// The top band every screen shares: who we are on the left, the app-wide
/// controls on the right.
///
/// [leading] replaces the wordmark for screens that lead with something else.
/// [onBrand] is for the dark branded backgrounds of intro and sign-in, where
/// the wordmark is drawn in white regardless of the theme.
class ResonHeader extends StatelessWidget {
  const ResonHeader({super.key, this.leading, this.onBrand});
  final Widget? leading;
  final bool? onBrand;

  @override
  Widget build(BuildContext context) {
    final compact = resonCompact(context);
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child:
                leading ??
                ResonWordmark(
                  dark:
                      onBrand ??
                      Theme.of(context).brightness == Brightness.dark,
                  compact: compact,
                ),
          ),
        ),
        const SizedBox(width: ResonSpace.sm),
        const ResonControls(),
      ],
    );
  }
}

/// The Reson wordmark.
///
/// A logo is a fixed drawing, so its proportions stay hand-set rather than
/// following the type scale, the same exception the credentials get.
class ResonWordmark extends StatelessWidget {
  const ResonWordmark({super.key, this.dark = true, this.compact = false});
  final bool dark;

  /// Shows the mark alone, for widths where the lockup would not fit.
  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Semantics(
        label: 'Reson',
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: ResonTheme.brand,
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.graphic_eq_rounded,
            color: Colors.white,
            size: 25,
          ),
        ),
      ),
      if (!compact) ...[
        const SizedBox(width: ResonSpace.md),
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
    ],
  );
}

/// Who somebody is, at a glance.
///
/// Every row used to carry the same pale pink circle, which made a list of
/// people a column of identical shapes. The shade is picked from the name,
/// so it is the same on every device and in every session without anything
/// being stored, and it stays inside the brand's reds rather than reaching
/// for hues the product does not own.
class ResonAvatar extends StatelessWidget {
  const ResonAvatar({
    super.key,
    required this.name,
    this.radius = 20,
    this.muted = false,
  });

  final String name;
  final double radius;

  /// A connection that is blocked or declined. It is still a person, but it
  /// is not news, so it steps back to grey.
  final bool muted;

  static const _shades = [
    ResonPalette.carmine,
    ResonPalette.wine,
    ResonPalette.brightRed,
  ];

  /// A stable shade for [name]. Pure, so it can be asserted on directly.
  static Color shadeFor(String name) {
    var hash = 0;
    for (final unit in name.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return _shades[hash % _shades.length];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radius,
      backgroundColor: muted ? scheme.surfaceContainerHighest : shadeFor(name),
      foregroundColor: muted ? scheme.onSurfaceVariant : Colors.white,
      child: Text(
        name.characters.firstOrNull ?? 'R',
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.w600,
          color: muted ? scheme.onSurfaceVariant : Colors.white,
        ),
      ),
    );
  }
}
