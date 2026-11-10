// lib/app/theme/theme.dart
import 'package:flutter/material.dart';
import 'package:marketing_companion_frontend/app/palette.dart';

final ThemeData appTheme = ThemeData(
  // -------------------------------------------------------------
  // Color scheme – ties directly to the palette defined above
  // -------------------------------------------------------------
  colorScheme: const ColorScheme(
    primary: AppPalette.terracotta,
    secondary: AppPalette.deepIndigo,
    surface: AppPalette.warmIvory,
    background: AppPalette.warmIvory,
    error: AppPalette.error,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.black87,
    onBackground: Colors.black87,
    onError: Colors.white,
    brightness: Brightness.light,
  ),

  // -------------------------------------------------------------
  // Material‑3 flag (gives the modern look while still allowing
  // custom colours)
  // -------------------------------------------------------------
  useMaterial3: true,

  // -------------------------------------------------------------
  // Scaffold background – matches the warm ivory surface colour
  // -------------------------------------------------------------
  scaffoldBackgroundColor: AppPalette.warmIvory,

  // -------------------------------------------------------------
  // Typography – using the default font family (or any font you
  // already have in the project). Adjust sizes if you have a
  // custom font asset.
  // -------------------------------------------------------------
  textTheme: const TextTheme(
    // Large headings (e.g., screen titles)
    headlineLarge: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w600,
      color: AppPalette.deepIndigo,
    ),
    // Section headings inside screens
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      color: AppPalette.deepIndigo,
    ),
    // Form field labels / smaller headings
    titleMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: Colors.black87,
    ),
    // Body text
    bodyLarge: TextStyle(
      fontSize: 16,
      color: Colors.black87,
    ),
    // Small helper / caption text
    bodySmall: TextStyle(
      fontSize: 14,
      color: Colors.black54,
    ),
  ),

  // -------------------------------------------------------------
  // Primary button style – terracotta background, rounded corners
  // -------------------------------------------------------------
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppPalette.terracotta,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
    ),
  ),

  // -------------------------------------------------------------
  // Outlined / text button style – consistent rounded borders
  // -------------------------------------------------------------
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppPalette.deepIndigo,
      side: const BorderSide(color: AppPalette.sageGreen),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
    ),
  ),

  // -------------------------------------------------------------
  // Input fields – outlined with sage‑green focus colour
  // -------------------------------------------------------------
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: AppPalette.sageGreen, width: 2),
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    labelStyle: TextStyle(color: AppPalette.deepIndigo),
  ),

  // -------------------------------------------------------------
  // AppBar – deep indigo background, white title text
  // -------------------------------------------------------------
  appBarTheme: const AppBarTheme(
    backgroundColor: AppPalette.deepIndigo,
    foregroundColor: Colors.white,
    elevation: 2,
    titleTextStyle: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    iconTheme: IconThemeData(color: Colors.white),
  ),

  // -------------------------------------------------------------
  // Card – subtle elevation, warm ivory surface, optional brass border
  // -------------------------------------------------------------
  cardTheme: CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    color: AppPalette.warmIvory,
    surfaceTintColor: AppPalette.warmIvory,
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
  ),

  // -------------------------------------------------------------
  // Divider – thin, using a muted colour
  // -------------------------------------------------------------
  dividerTheme: const DividerThemeData(
    thickness: 1,
    color: Color(0xFFE0E0E0),
    space: 24,
  ),
);