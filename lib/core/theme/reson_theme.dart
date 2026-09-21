import 'reson_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Appearance extends Notifier<ThemeMode> {
  bool _changed = false;
  @override
  ThemeMode build() {
    Future<void>(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (ref.mounted && !_changed) {
          state = prefs.getBool('darkMode') == false
              ? ThemeMode.light
              : ThemeMode.dark;
        }
      } catch (_) {
        /* Device preferences are optional. */
      }
    });
    return ThemeMode.dark;
  }

  Future<void> toggle() async {
    _changed = true;
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final dark = state == ThemeMode.dark;
    try {
      await (await SharedPreferences.getInstance()).setBool('darkMode', dark);
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
