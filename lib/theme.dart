import 'package:flutter/material.dart';

// ── Design constants ──────────────────────────────────────────────────────────
const Color kBg = Color(0xFFFBFBFD);
const Color kInk = Color(0xFF1D1D1F);
const Color kMuted = Color(0xFF6E6E73);
const Color kAccent = Color(0xFF0071E3);
const Color kLine = Color(0xFFD2D2D7);
const double kRadius = 18.0;

// ── Apple-inspired bright theme (Material 3) ──────────────────────────────────
ThemeData heirloomTheme() {
  final base = ColorScheme.fromSeed(
    seedColor: kAccent,
    brightness: Brightness.light,
    surface: Colors.white,
    onSurface: kInk,
  ).copyWith(
    primary: kAccent,
    onPrimary: Colors.white,
    secondary: kAccent,
    onSecondary: Colors.white,
    surface: Colors.white,
    onSurface: kInk,
    surfaceContainerHighest: kBg,
    outline: kLine,
  );

  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(kRadius),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: base,
    scaffoldBackgroundColor: kBg,

    // ── Text ──────────────────────────────────────────────────────────────
    // San Francisco on iOS via the system font cascade; Roboto elsewhere.
    fontFamily: null, // relies on platform default
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: kInk, fontWeight: FontWeight.w700),
      displayMedium: TextStyle(color: kInk, fontWeight: FontWeight.w700),
      displaySmall: TextStyle(color: kInk, fontWeight: FontWeight.w600),
      headlineLarge: TextStyle(color: kInk, fontWeight: FontWeight.w700),
      headlineMedium: TextStyle(color: kInk, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(color: kInk, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: kInk, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: kInk, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(color: kInk, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: kInk),
      bodyMedium: TextStyle(color: kInk),
      bodySmall: TextStyle(color: kMuted),
      labelLarge: TextStyle(color: kInk, fontWeight: FontWeight.w500),
      labelMedium: TextStyle(color: kMuted),
      labelSmall: TextStyle(color: kMuted),
    ),

    // ── AppBar ────────────────────────────────────────────────────────────
    appBarTheme: const AppBarTheme(
      backgroundColor: kBg,
      foregroundColor: kInk,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: kLine,
      titleTextStyle: TextStyle(
        color: kInk,
        fontWeight: FontWeight.w600,
        fontSize: 17,
      ),
    ),

    // ── Cards ─────────────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: shape,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),

    // ── Filled buttons (pill) ─────────────────────────────────────────────
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kAccent,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadius),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),

    // ── Elevated buttons ──────────────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadius),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),

    // ── Text buttons ──────────────────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kAccent,
        textStyle: const TextStyle(fontWeight: FontWeight.w500),
      ),
    ),

    // ── Input decoration ──────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadius),
        borderSide: const BorderSide(color: kLine),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadius),
        borderSide: const BorderSide(color: kLine),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadius),
        borderSide: const BorderSide(color: kAccent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      hintStyle: const TextStyle(color: kMuted),
    ),

    // ── List tile ─────────────────────────────────────────────────────────
    listTileTheme: const ListTileThemeData(
      iconColor: kMuted,
      subtitleTextStyle: TextStyle(color: kMuted),
    ),

    // ── Divider ───────────────────────────────────────────────────────────
    dividerTheme: const DividerThemeData(color: kLine, space: 1, thickness: 1),

    // ── Bottom nav ────────────────────────────────────────────────────────
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: kAccent,
      unselectedItemColor: kMuted,
      elevation: 0,
    ),
  );
}
