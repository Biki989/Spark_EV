import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SparkTheme {
  // Colors
  static const Color primaryGreen = Color(0xFF00E676);
  static const Color primaryDark = Color(0xFF00C853);
  static const Color darkBg = Color(0xFF1A1A2E);
  static const Color surfaceDark = Color(0xFF16213E);
  static const Color cardDark = Color(0xFF1F2940);
  static const Color white = Colors.white;
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey800 = Color(0xFF424242);
  static const Color errorRed = Color(0xFFEF5350);
  static const Color warningYellow = Color(0xFFFFCA28);
  static const Color successGreen = Color(0xFF66BB6A);
  static const Color infoBlue = Color(0xFF42A5F5);

  // Pin colors for map
  static const Color pinAvailable = Color(0xFF4CAF50);
  static const Color pinLimited = Color(0xFFFFC107);
  static const Color pinFull = Color(0xFFF44336);

  // Charger type colors
  static const Color ccsColor = Color(0xFF2196F3);
  static const Color type2Color = Color(0xFF4CAF50);
  static const Color teslaColor = Color(0xFFE91E63);
  static const Color chademoColor = Color(0xFFFF9800);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.light,
        primary: primaryGreen,
        onPrimary: darkBg,
        secondary: primaryDark,
        surface: white,
        error: errorRed,
      ),
      scaffoldBackgroundColor: white,
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: grey800,
        displayColor: darkBg,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: white,
        foregroundColor: darkBg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: darkBg,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: darkBg,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: grey100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 1),
        ),
        hintStyle: GoogleFonts.inter(color: grey400, fontSize: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: primaryGreen,
        unselectedItemColor: grey400,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: grey100,
        selectedColor: primaryGreen.withOpacity(0.2),
        labelStyle: GoogleFonts.inter(fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: const DividerThemeData(
        color: grey200,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static Color getChargerColor(String type) {
    switch (type) {
      case 'CCS': return ccsColor;
      case 'Type2': return type2Color;
      case 'Tesla': return teslaColor;
      case 'CHAdeMO': return chademoColor;
      default: return grey600;
    }
  }

  static Color getPinColor(int availableSlots, int totalPorts) {
    if (totalPorts == 0) return pinFull;
    final ratio = availableSlots / totalPorts;
    if (ratio > 0.5) return pinAvailable;
    if (ratio > 0) return pinLimited;
    return pinFull;
  }
}
