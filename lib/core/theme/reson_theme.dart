import 'reson_palette.dart';
import 'reson_surfaces.dart';
import 'reson_tokens.dart';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode. Follows the device until the user picks a side by hand, and
/// remembers that choice from then on.
class Appearance extends Notifier<ThemeMode> {
  bool _changed = false;
  @override
  ThemeMode build() {
    Future<void>(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final stored = prefs.getBool('darkMode');
        if (ref.mounted && !_changed && stored != null) {
          state = stored ? ThemeMode.dark : ThemeMode.light;
        }
      } catch (_) {
        /* Device preferences are optional. */
      }
    });
    return ThemeMode.system;
  }

  /// Whether the device itself is currently dark, for when no choice is saved.
  bool get _deviceIsDark =>
      PlatformDispatcher.instance.platformBrightness == Brightness.dark;

  /// Switches away from whatever is on screen right now, which is not the same
  /// as negating [state] while that state is [ThemeMode.system].
  Future<void> toggle() async {
    _changed = true;
    final showingDark = switch (state) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => _deviceIsDark,
    };
    state = showingDark ? ThemeMode.light : ThemeMode.dark;
    try {
      await (await SharedPreferences.getInstance()).setBool(
        'darkMode',
        state == ThemeMode.dark,
      );
    } catch (_) {}
  }
}

final appearanceProvider = NotifierProvider<Appearance, ThemeMode>(
  Appearance.new,
);

abstract final class ResonTheme {
  static const ink = ResonPalette.coal;
  static const muted = ResonPalette.grey;
  static const brand = ResonPalette.carmine;
  static const violet = brand;
  static const canvas = ResonPalette.ivory;
  static const night = ResonPalette.coal;
  static ThemeData get light => forSeed(brand);
  static ThemeData forSeed(
    Color seed, {
    Brightness brightness = Brightness.light,
  }) {
    final dark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: seed,
          brightness: brightness,
          surface: dark ? night : canvas,
        ).copyWith(
          primary: dark ? ResonPalette.brightRed : ResonPalette.carmine,
          onPrimary: ResonPalette.white,
          primaryContainer: dark ? ResonPalette.wine : ResonPalette.blush,
          onPrimaryContainer: dark ? ResonPalette.white : ResonPalette.wine,
          secondary: dark ? ResonPalette.paleGrey : ResonPalette.grey,
          onSecondary: dark ? ResonPalette.coal : ResonPalette.white,
          secondaryContainer: dark ? ResonPalette.slate : ResonPalette.mist,
          onSecondaryContainer: dark ? ResonPalette.white : ResonPalette.coal,
          tertiary: dark ? ResonPalette.brightRed : ResonPalette.wine,
          surfaceContainerLowest: dark ? ResonPalette.coal : ResonPalette.white,
          surfaceContainerLow: dark
              ? ResonPalette.graphite
              : ResonPalette.white,
          surfaceContainer: dark ? ResonPalette.graphite : ResonPalette.mist,
          surfaceContainerHigh: dark ? ResonPalette.slate : ResonPalette.mist,
          surfaceContainerHighest: dark
              ? ResonPalette.slate
              : ResonPalette.silver,
          onSurface: dark ? ResonPalette.ivory : ResonPalette.coal,
          onSurfaceVariant: dark ? ResonPalette.paleGrey : ResonPalette.grey,
          outline: dark ? ResonPalette.paleGrey : ResonPalette.grey,
          outlineVariant: dark ? ResonPalette.darkBorder : ResonPalette.silver,
        );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(
        color: dark ? ResonPalette.darkBorder : ResonPalette.silver,
      ),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: ResonType.of(scheme),
      extensions: [
        const ResonMotion(),
        const ResonCredentials(),
        ResonSurfaces.of(brightness),
      ],
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: .45),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: dark ? ResonPalette.graphite : ResonPalette.mist,
        selectedColor: scheme.primaryContainer,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        labelStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 13,
          fontFamily: 'Roboto',
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? ResonPalette.graphite : ResonPalette.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 19,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 54),
          backgroundColor: ResonPalette.carmine,
          foregroundColor: ResonPalette.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
    );
  }
}
