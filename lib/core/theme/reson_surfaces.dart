import 'package:flutter/material.dart';

import 'reson_palette.dart';

/// Vertical and horizontal rhythm, on a 4pt grid.
///
/// The screens used to space themselves with twenty different gaps between 4
/// and 64. Sticking to these seven is most of what makes a layout read as
/// deliberate rather than assembled.
abstract final class ResonSpace {
  /// Between a label and the thing it labels.
  static const xs = 4.0;

  /// Inside a dense row.
  static const sm = 8.0;

  /// Between related lines.
  static const md = 12.0;

  /// Default gap inside a panel.
  static const lg = 16.0;

  /// Between blocks of content.
  static const xl = 24.0;

  /// Between sections of a screen.
  static const xxl = 32.0;

  /// Around a screen's main regions.
  static const huge = 48.0;

  /// The breathing room above a hero, and nothing smaller.
  static const hero = 64.0;

  /// What every screen keeps between its content and the edge of the display.
  ///
  /// Each screen used to pick its own: 22 on home and the network shell, 24 in
  /// the editor and the profile, 20 inside an expanded section. Nobody can see
  /// two pixels, but moving between screens whose text starts in a slightly
  /// different place is felt even when it is not noticed.
  static const EdgeInsets screen = EdgeInsets.fromLTRB(xl, xl, xl, huge);
}

/// Corner radii.
///
/// The chrome had grown eleven of them — 8, 11, 12, 18, 20, 22, 23, 24, 25, 28
/// and 30 — and the middle of that run is indistinguishable by eye while being
/// obviously unplanned in code. Four steps say everything the app needs. The
/// credentials keep their own radii in [ResonCredentials]: those are artwork.
abstract final class ResonRadius {
  /// Chips, badges, inline markers.
  static const sm = 12.0;

  /// Buttons, inputs, list tiles. Matches the component themes.
  static const md = 18.0;

  /// Panels and cards: anything that holds other content.
  static const lg = 24.0;

  /// Dialogs and sheets, the only things allowed to be rounder than a panel.
  static const xl = 28.0;

  static BorderRadius get small => BorderRadius.circular(sm);
  static BorderRadius get medium => BorderRadius.circular(md);
  static BorderRadius get large => BorderRadius.circular(lg);
  static BorderRadius get extraLarge => BorderRadius.circular(xl);
}

/// Depth tokens.
///
/// The app used to separate every surface with a one pixel border, so nothing
/// ever sat above anything else. These shadows carry that job instead; a
/// border is now the exception, not the default.
@immutable
class ResonSurfaces extends ThemeExtension<ResonSurfaces> {
  const ResonSurfaces({
    required this.resting,
    required this.raised,
    required this.floating,
    required this.hairline,
    this.panelRadius = 24,
    this.tileRadius = 18,
  });

  /// A panel at rest on the background.
  final List<BoxShadow> resting;

  /// Something interactive, or deliberately above its neighbours.
  final List<BoxShadow> raised;

  /// Sheets, dialogs and anything that floats over the page.
  final List<BoxShadow> floating;

  /// For the rare edge that still needs drawing.
  final Color hairline;

  final double panelRadius;
  final double tileRadius;

  /// Dark surfaces need a deeper, softer shadow to register at all; light
  /// ones need it barely there or the page looks dirty.
  factory ResonSurfaces.of(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    List<BoxShadow> shadow(double alpha, double blur, double dy) => [
      BoxShadow(
        color: Colors.black.withValues(alpha: alpha),
        blurRadius: blur,
        offset: Offset(0, dy),
      ),
    ];
    return ResonSurfaces(
      resting: dark ? shadow(.34, 18, 6) : shadow(.05, 14, 4),
      raised: dark ? shadow(.44, 30, 12) : shadow(.08, 26, 10),
      floating: dark ? shadow(.54, 46, 20) : shadow(.12, 40, 18),
      hairline: dark
          ? ResonPalette.darkBorder.withValues(alpha: .55)
          : ResonPalette.silver.withValues(alpha: .75),
    );
  }

  @override
  ResonSurfaces copyWith({
    List<BoxShadow>? resting,
    List<BoxShadow>? raised,
    List<BoxShadow>? floating,
    Color? hairline,
    double? panelRadius,
    double? tileRadius,
  }) => ResonSurfaces(
    resting: resting ?? this.resting,
    raised: raised ?? this.raised,
    floating: floating ?? this.floating,
    hairline: hairline ?? this.hairline,
    panelRadius: panelRadius ?? this.panelRadius,
    tileRadius: tileRadius ?? this.tileRadius,
  );

  @override
  ResonSurfaces lerp(ThemeExtension<ResonSurfaces>? other, double t) {
    if (other is! ResonSurfaces) return this;
    return ResonSurfaces(
      resting: BoxShadow.lerpList(resting, other.resting, t)!,
      raised: BoxShadow.lerpList(raised, other.raised, t)!,
      floating: BoxShadow.lerpList(floating, other.floating, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      panelRadius: panelRadius + (other.panelRadius - panelRadius) * t,
      tileRadius: tileRadius + (other.tileRadius - tileRadius) * t,
    );
  }
}

/// The type scale.
///
/// Twenty one font sizes were in use, none of them named. These eight roles
/// cover the same ground, and reading them from the theme means a change to
/// the voice of the product happens in one place.
abstract final class ResonType {
  static TextTheme of(ColorScheme scheme) {
    TextStyle style(
      double size,
      FontWeight weight, {
      double? spacing,
      double? height,
      Color? color,
    }) => TextStyle(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: spacing,
      height: height,
      color: color ?? scheme.onSurface,
      fontFamily: 'Roboto',
    );
    return TextTheme(
      // The one line that sells the screen.
      displaySmall: style(34, FontWeight.w700, spacing: -1.2, height: 1.08),
      // A screen's own title.
      headlineMedium: style(27, FontWeight.w700, spacing: -.8, height: 1.15),
      // A section within a screen.
      titleLarge: style(21, FontWeight.w700, spacing: -.4),
      // The heading of a panel or a tile.
      titleMedium: style(17, FontWeight.w600, spacing: -.1),
      // Body copy.
      bodyLarge: style(15, FontWeight.w400, height: 1.5),
      // Supporting copy, captions under a heading. Material uses this slot
      // as the default style for every unstyled Text, so it must carry the
      // normal ink colour; secondary text asks for onSurfaceVariant itself.
      bodyMedium: style(13, FontWeight.w400, height: 1.45),
      // Buttons, chips, anything a finger lands on.
      labelLarge: style(14, FontWeight.w600),
      // Eyebrows and overlines, always upper case at the call site.
      labelSmall: style(
        11,
        FontWeight.w700,
        spacing: 1.6,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
