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
  static const ink = Color(0xFF211735);
  static const muted = Color(0xFF9386AB);
  static const violet = Color(0xFF956DFF);
  static const canvas = Color(0xFFF6F2FC);
  static const night = Color(0xFF151027);
  static ThemeData get light => forSeed(violet);
  static ThemeData forSeed(
    Color seed, {
    Brightness brightness = Brightness.light,
  }) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      surface: dark ? night : canvas,
    );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(
        color: dark ? const Color(0xFF3D3056) : const Color(0xFFE2D8EF),
      ),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF231B38) : Colors.white,
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
