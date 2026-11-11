import 'package:flutter/material.dart';

import 'reson_palette.dart';

/// Named motion tokens for Reson.
///
/// Every animation used to invent its own timing: ten different durations,
/// each used exactly once. These six cover the same ground by intent, so a
/// change to how the product feels happens here instead of in ten files.
///
/// Read them through `context.motion`, which already collapses every duration
/// to zero when the device asks for reduced motion.
@immutable
class ResonMotion extends ThemeExtension<ResonMotion> {
  const ResonMotion({
    this.press = const Duration(milliseconds: 150),
    this.expand = const Duration(milliseconds: 320),
    this.transition = const Duration(milliseconds: 420),
    this.entrance = const Duration(milliseconds: 650),
    this.meter = const Duration(milliseconds: 800),
    this.showcase = const Duration(milliseconds: 1200),
    this.standard = Curves.easeOutCubic,
    this.settle = Curves.easeOut,
    this.overshoot = Curves.easeOutBack,
    this.deckSpring = const SpringDescription(
      mass: 1,
      stiffness: 320,
      // withDampingRatio(.9) is not a const constructor; this is that value.
      damping: 32.2,
    ),
    this.isStill = false,
  });

  /// Tactile feedback under a finger.
  final Duration press;

  /// Disclosure: a panel growing, a section unfolding.
  final Duration expand;

  /// One piece of content replacing another.
  final Duration transition;

  /// A screen or card arriving for the first time.
  final Duration entrance;

  /// A value filling up, such as the profile completeness ring.
  final Duration meter;

  /// Ambient, decorative motion that should never feel urgent.
  final Duration showcase;

  /// Default easing for anything that arrives and stops.
  final Curve standard;

  /// Easing for short, reversible feedback.
  final Curve settle;

  /// Easing with a slight overshoot, for moments worth celebrating.
  final Curve overshoot;

  /// Drives the wallet deck once a drag is released. Tune the feel here.
  final SpringDescription deckSpring;

  /// True when durations have been zeroed for reduced motion.
  ///
  /// A zero duration is safe for implicit animations, but `AnimatedSize`
  /// re-dirties itself during its own layout when given one. Check this flag
  /// and leave the widget out entirely instead of passing [Duration.zero].
  final bool isStill;

  /// Same tokens with every duration removed, for reduced motion.
  ResonMotion stilled() => ResonMotion(
    press: Duration.zero,
    expand: Duration.zero,
    transition: Duration.zero,
    entrance: Duration.zero,
    meter: Duration.zero,
    showcase: Duration.zero,
    standard: standard,
    settle: settle,
    overshoot: overshoot,
    deckSpring: deckSpring,
    isStill: true,
  );

  @override
  ResonMotion copyWith({
    Duration? press,
    Duration? expand,
    Duration? transition,
    Duration? entrance,
    Duration? meter,
    Duration? showcase,
    Curve? standard,
    Curve? settle,
    Curve? overshoot,
    SpringDescription? deckSpring,
    bool? isStill,
  }) => ResonMotion(
    press: press ?? this.press,
    expand: expand ?? this.expand,
    transition: transition ?? this.transition,
    entrance: entrance ?? this.entrance,
    meter: meter ?? this.meter,
    showcase: showcase ?? this.showcase,
    standard: standard ?? this.standard,
    settle: settle ?? this.settle,
    overshoot: overshoot ?? this.overshoot,
    deckSpring: deckSpring ?? this.deckSpring,
    isStill: isStill ?? this.isStill,
  );

  @override
  ResonMotion lerp(ThemeExtension<ResonMotion>? other, double t) {
    if (other is! ResonMotion) return this;
    // Curves and the spring have no meaningful midpoint, so they switch over.
    return t < .5 ? this : other;
  }
}

/// The fixed palette of one credential layout.
///
/// Only the constants live here. Anything derived from the owner's own colour
/// stays in the layout widget, because it depends on the card, not the theme.
@immutable
class ResonCredentialSkin {
  const ResonCredentialSkin({
    required this.ink,
    required this.muted,
    required this.backdrop,
    required this.blend,
    this.surface = const Color(0x00000000),
    this.accent,
  });

  /// Primary text on the credential.
  final Color ink;

  /// Secondary text: roles, contact lines, captions.
  final Color muted;

  /// The owner's colour is darkened toward this to build the card body.
  final Color backdrop;

  /// How far toward [backdrop] the owner's colour travels, 0 to 1.
  final double blend;

  /// Flat base for layouts that do not tint the owner's colour at all.
  final Color surface;

  /// Decorative mark on the credential. Null means the layout draws it in the
  /// owner's own colour instead of a fixed one.
  final Color? accent;

  static ResonCredentialSkin lerp(
    ResonCredentialSkin a,
    ResonCredentialSkin b,
    double t,
  ) => ResonCredentialSkin(
    ink: Color.lerp(a.ink, b.ink, t)!,
    muted: Color.lerp(a.muted, b.muted, t)!,
    backdrop: Color.lerp(a.backdrop, b.backdrop, t)!,
    blend: _lerp(a.blend, b.blend, t),
    surface: Color.lerp(a.surface, b.surface, t)!,
    accent: Color.lerp(a.accent, b.accent, t),
  );
}

/// Geometry and per-layout colours for the credential surfaces.
///
/// The eight card layouts each carried their own foreground, muted and
/// backdrop colours inline. Collecting them here keeps the deck, the editor
/// and the share screen describing the same object.
@immutable
class ResonCredentials extends ThemeExtension<ResonCredentials> {
  const ResonCredentials({
    this.passRadius = 22,
    this.panelRadius = 30,
    this.passFace = 186,
    this.passStep = 54,
    this.passInset = 8,
    this.passElevation = 9,
    this.skins = defaultSkins,
  });

  /// One entry per card layout. The lavender neutrals are inherited from the
  /// purple era of the product; recolouring the credentials to carmine is now
  /// a change to this map alone.
  static const defaultSkins = <String, ResonCredentialSkin>{
    'signature': ResonCredentialSkin(
      ink: ResonPalette.white,
      muted: ResonPalette.roseVeil,
      backdrop: ResonPalette.deepWine,
      blend: .8,
    ),
    'minimal': ResonCredentialSkin(
      ink: ResonPalette.wineInk,
      muted: ResonPalette.wineGrey,
      backdrop: ResonPalette.wineShadow,
      blend: .76,
    ),
    'bold': ResonCredentialSkin(
      ink: ResonPalette.white,
      muted: ResonPalette.roseVeil,
      backdrop: ResonPalette.wineShadow,
      blend: .76,
      accent: ResonPalette.roseAccent,
    ),
    'classic': ResonCredentialSkin(
      ink: ResonPalette.white,
      muted: ResonPalette.roseVeil,
      backdrop: ResonPalette.wineShadow,
      blend: .76,
      accent: ResonPalette.roseAccent,
    ),
    'aurora': ResonCredentialSkin(
      ink: ResonPalette.ivory,
      muted: ResonPalette.roseMist,
      backdrop: ResonPalette.nightWine,
      blend: .88,
    ),
    'executive': ResonCredentialSkin(
      ink: ResonPalette.ivory,
      muted: ResonPalette.roseMist,
      backdrop: ResonPalette.nightWine,
      blend: .88,
    ),
    'editorial': ResonCredentialSkin(
      ink: ResonPalette.wineInk,
      muted: ResonPalette.wineGrey,
      backdrop: ResonPalette.nightWine,
      blend: .88,
    ),
    'noir': ResonCredentialSkin(
      ink: ResonPalette.parchment,
      muted: ResonPalette.parchmentMuted,
      backdrop: ResonPalette.duskWine,
      blend: .6,
      surface: ResonPalette.coal,
    ),
    'studio': ResonCredentialSkin(
      ink: ResonPalette.studioInk,
      muted: ResonPalette.grey,
      backdrop: ResonPalette.duskWine,
      blend: .6,
      surface: ResonPalette.studioPaper,
    ),
  };

  /// Palette for [layout], falling back to the classic credential.
  ResonCredentialSkin skin(String layout) =>
      skins[layout] ?? skins['classic'] ?? defaultSkins['classic']!;

  final Map<String, ResonCredentialSkin> skins;

  /// Corner radius of a wallet pass.
  final double passRadius;

  /// Corner radius of the panels that hold a deck or a card detail.
  final double panelRadius;

  /// Height of the front pass, before text scaling.
  final double passFace;

  /// Vertical offset between stacked passes, before text scaling.
  final double passStep;

  /// Horizontal inset applied per slot of depth.
  final double passInset;

  /// Elevation of the front pass; passes behind it sit flat.
  final double passElevation;

  @override
  ResonCredentials copyWith({
    double? passRadius,
    double? panelRadius,
    double? passFace,
    double? passStep,
    double? passInset,
    double? passElevation,
    Map<String, ResonCredentialSkin>? skins,
  }) => ResonCredentials(
    passRadius: passRadius ?? this.passRadius,
    panelRadius: panelRadius ?? this.panelRadius,
    passFace: passFace ?? this.passFace,
    passStep: passStep ?? this.passStep,
    passInset: passInset ?? this.passInset,
    passElevation: passElevation ?? this.passElevation,
    skins: skins ?? this.skins,
  );

  @override
  ResonCredentials lerp(ThemeExtension<ResonCredentials>? other, double t) {
    if (other is! ResonCredentials) return this;
    return ResonCredentials(
      passRadius: _lerp(passRadius, other.passRadius, t),
      panelRadius: _lerp(panelRadius, other.panelRadius, t),
      passFace: _lerp(passFace, other.passFace, t),
      passStep: _lerp(passStep, other.passStep, t),
      passInset: _lerp(passInset, other.passInset, t),
      passElevation: _lerp(passElevation, other.passElevation, t),
      skins: {
        for (final entry in skins.entries)
          entry.key: other.skins[entry.key] == null
              ? entry.value
              : ResonCredentialSkin.lerp(
                  entry.value,
                  other.skins[entry.key]!,
                  t,
                ),
      },
    );
  }
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

extension ResonTokens on BuildContext {
  /// Motion tokens, already stilled when the device asks for reduced motion.
  ResonMotion get motion {
    const fallback = ResonMotion();
    final tokens = Theme.of(this).extension<ResonMotion>() ?? fallback;
    return MediaQuery.disableAnimationsOf(this) ? tokens.stilled() : tokens;
  }

  /// Credential geometry and colours.
  ResonCredentials get credentials =>
      Theme.of(this).extension<ResonCredentials>() ?? const ResonCredentials();
}
