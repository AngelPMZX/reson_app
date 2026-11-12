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
        // `themeMode` can also say 'system', which the old boolean could not
        // express: once you had tapped the toggle there was no way back to
        // following the device. The boolean is still read for accounts that
        // saved one before.
        final mode = switch (prefs.getString('themeMode')) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          'system' => ThemeMode.system,
          _ => switch (prefs.getBool('darkMode')) {
            true => ThemeMode.dark,
            false => ThemeMode.light,
            null => null,
          },
        };
        if (ref.mounted && !_changed && mode != null) state = mode;
      } catch (_) {
        /* Device preferences are optional. */
      }
    });
    return ThemeMode.system;
  }

  /// Whether the device itself is currently dark, for when no choice is saved.
  bool get _deviceIsDark =>
      PlatformDispatcher.instance.platformBrightness == Brightness.dark;

  Future<void> set(ThemeMode mode) async {
    _changed = true;
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('themeMode', mode.name);
      if (mode == ThemeMode.system) {
        await prefs.remove('darkMode');
      } else {
        await prefs.setBool('darkMode', mode == ThemeMode.dark);
      }
    } catch (_) {}
  }

  /// Switches away from whatever is on screen right now, which is not the same
  /// as negating [state] while that state is [ThemeMode.system].
  Future<void> toggle() async {
    final showingDark = switch (state) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => _deviceIsDark,
    };
    await set(showingDark ? ThemeMode.light : ThemeMode.dark);
  }
}

final appearanceProvider = NotifierProvider<Appearance, ThemeMode>(
  Appearance.new,
);

/// Chosen language, or null to follow the device.
///
/// It sits beside [appearanceProvider] because both are app-wide presentation
/// choices driven by the same header control; keeping it here lets that header
/// live in core instead of reaching back into the app layer.
class LocaleController extends Notifier<Locale?> {
  bool _changed = false;

  @override
  Locale? build() {
    // The choice used to live only in memory, so the app forgot it on every
    // restart and silently went back to the device language.
    Future<void>(() async {
      try {
        final stored = (await SharedPreferences.getInstance()).getString(
          'locale',
        );
        if (ref.mounted && !_changed && stored != null) {
          state = Locale(stored);
        }
      } catch (_) {
        /* Device preferences are optional. */
      }
    });
    return null;
  }

  Future<void> set(Locale locale) async {
    _changed = true;
    state = locale;
    try {
      await (await SharedPreferences.getInstance()).setString(
        'locale',
        locale.languageCode,
      );
    } catch (_) {}
  }

  /// Goes back to whatever language the device is in.
  Future<void> follow() async {
    _changed = true;
    state = null;
    try {
      await (await SharedPreferences.getInstance()).remove('locale');
    } catch (_) {}
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
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
      borderRadius: BorderRadius.circular(ResonRadius.md),
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
        padding: const EdgeInsets.symmetric(
          horizontal: ResonSpace.md,
          vertical: ResonSpace.sm,
        ),
        labelStyle: ResonType.of(scheme).labelLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? ResonPalette.graphite : ResonPalette.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ResonSpace.lg,
          vertical: ResonSpace.xl - 5,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        disabledBorder: border.copyWith(
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: .5),
          ),
        ),
        errorBorder: border.copyWith(
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: border.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 54),
          // Reads the scheme instead of pinning carmine, so dark mode gets its
          // brighter red and FilledButton.tonal stops being indistinguishable
          // from a primary action.
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.onSurface.withValues(alpha: .12),
          disabledForegroundColor: scheme.onSurface.withValues(alpha: .38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ResonRadius.md),
          ),
          textStyle: ResonType.of(scheme).labelLarge,
        ),
      ),
      // An outlined button is the repair move: real weight, no shouting.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          foregroundColor: scheme.primary,
          disabledForegroundColor: scheme.onSurface.withValues(alpha: .38),
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ResonRadius.md),
          ),
          textStyle: ResonType.of(scheme).labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: scheme.primary,
          disabledForegroundColor: scheme.onSurface.withValues(alpha: .38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ResonRadius.sm),
          ),
        ),
      ),
      // Keyboard focus was invisible everywhere: Material's default ring is
      // drawn from the unthemed primary and vanished against the carmine.
      focusColor: scheme.primary.withValues(alpha: .12),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResonRadius.xl),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResonRadius.sm),
        ),
      ),
    );
  }
}
