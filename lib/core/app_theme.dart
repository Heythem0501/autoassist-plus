import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Thème centralisé de l'application AutoAssist+
///
/// Palette de couleurs inspirée de l'identité visuelle automobile :
/// - Bleu : confiance, technologie, fiabilité (couleur principale)
/// - Orange : énergie, action, alerte (couleur d'accent)
class AppTheme {
  // =========================================================================
  // PALETTE DE COULEURS
  // =========================================================================

  /// Bleu principal — utilisé pour les éléments clés (AppBar, boutons primaires)
  static const Color primaryBlue = Color(0xFF2563EB);

  /// Bleu foncé — pour les hovers et les états actifs
  static const Color primaryBlueDark = Color(0xFF1D4ED8);

  /// Bleu clair — pour les fonds subtils
  static const Color primaryBlueLight = Color(0xFFDBEAFE);

  /// Orange d'accent — utilisé pour les CTA secondaires et les alertes
  static const Color accentOrange = Color(0xFFF97316);

  /// Orange foncé
  static const Color accentOrangeDark = Color(0xFFEA580C);

  /// Couleurs de gravité (diagnostic)
  static const Color severityGreen = Color(0xFF22C55E);
  static const Color severityOrange = Color(0xFFF59E0B);
  static const Color severityRed = Color(0xFFEF4444);

  /// Couleurs neutres
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color borderGrey = Color(0xFFE2E8F0);

  // =========================================================================
  // THÈME CLAIR
  // =========================================================================

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: backgroundLight,

    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      onPrimary: Colors.white,
      secondary: accentOrange,
      onSecondary: Colors.white,
      surface: surfaceLight,
      onSurface: textPrimary,
      error: severityRed,
      onError: Colors.white,
    ),

    // Typographie avec Google Fonts (Poppins = moderne et lisible)
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      headlineLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        color: textPrimary,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        color: textSecondary,
      ),
    ),

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),

    // Boutons élevés (principaux)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Boutons texte (liens)
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentOrange,
        textStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Champs de saisie
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderGrey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: severityRed),
      ),
      labelStyle: GoogleFonts.poppins(
        color: textSecondary,
        fontSize: 14,
      ),
      hintStyle: GoogleFonts.poppins(
        color: textSecondary.withValues(alpha: 0.6),
        fontSize: 14,
      ),
    ),

    // Cartes
    cardTheme: CardThemeData(
      color: surfaceLight,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}