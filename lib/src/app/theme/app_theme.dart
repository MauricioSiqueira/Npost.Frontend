import 'package:flutter/material.dart';

class AppTheme {
  static const Color _sand = Color(0xFFF2E7CC);
  static const Color _cream = Color(0xFFF8F4EA);
  static const Color _ink = Color(0xFF202430);
  static const Color _muted = Color(0xFF8E949F);
  static const Color _accent = Color(0xFF5F7CFF);
  static const Color _button = Color(0xFFDEB887);
  static const Color _darkBg = Color(0xFF12161F);
  static const Color _darkCard = Color(0xFF1B2230);
  static const Color _darkField = Color(0xFF242D3D);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _accent,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _sand,
      textTheme: _textTheme(Brightness.light),
      inputDecorationTheme: _inputDecorationTheme(
        fillColor: Colors.white,
        hintColor: _muted,
      ),
      checkboxTheme: CheckboxThemeData(
        side: const BorderSide(color: _muted),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      elevatedButtonTheme: elevatedButtonTheme(_button, Colors.white),
      cardTheme: const CardThemeData(
        color: _cream,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _accent,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _darkBg,
      textTheme: _textTheme(Brightness.dark),
      inputDecorationTheme: _inputDecorationTheme(
        fillColor: _darkField,
        hintColor: const Color(0xFF95A0B5),
      ),
      checkboxTheme: CheckboxThemeData(
        side: const BorderSide(color: Color(0xFF95A0B5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      elevatedButtonTheme: elevatedButtonTheme(_accent, Colors.white),
      cardTheme: const CardThemeData(
        color: _darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
    );
  }

  static ElevatedButtonThemeData elevatedButtonTheme(
    Color background,
    Color foreground,
  ) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: background.withAlpha(120),
        disabledForegroundColor: foreground.withAlpha(180),
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: background),
        ),
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static TextTheme _textTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : _ink,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: isDark ? Colors.white : _ink,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: isDark ? const Color(0xFFB7C0D1) : _muted,
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : _ink,
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme({
    required Color fillColor,
    required Color hintColor,
  }) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      hintStyle: TextStyle(color: hintColor, fontSize: 15),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _accent, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}
