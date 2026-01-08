import 'package:flutter/material.dart';

/// Can Can App Theme Configuration
class AppTheme {
  // Brand Colors - Enhanced
  static const Color primaryBlue = Color(0xFF4A90E2);
  static const Color primaryBlueDark = Color(0xFF357ABD);
  static const Color successGreen = Color(0xFF52C41A);
  static const Color warningOrange = Color(0xFFFFA940);
  static const Color errorRed = Color(0xFFFF4D4F);

  // Neutral Colors - Enhanced
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFFAFAFA);
  static const Color mediumGray = Color(0xFFD9D9D9);
  static const Color darkGray = Color(0xFF8C8C8C);
  static const Color textPrimary = Color(0xFF262626);
  static const Color textSecondary = Color(0xFF8C8C8C);

  // Status Colors
  static const Color pendingBg = Color(0xFFFFE0B2);
  static const Color completedBg = Color(0xFFC8E6C9);
  static const Color cancelledBg = Color(0xFFFFCDD2);

  // Spacing Constants (8dp grid system)
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXL = 20.0;
  static const double spacingXXL = 24.0;
  static const double spacingXXXL = 32.0;
  
  // Padding Constants
  static const EdgeInsets paddingXS = EdgeInsets.all(4.0);
  static const EdgeInsets paddingS = EdgeInsets.all(8.0);
  static const EdgeInsets paddingM = EdgeInsets.all(12.0);
  static const EdgeInsets paddingL = EdgeInsets.all(16.0);
  static const EdgeInsets paddingXL = EdgeInsets.all(20.0);
  static const EdgeInsets paddingXXL = EdgeInsets.all(24.0);
  
  // Horizontal Padding
  static const EdgeInsets paddingHorizontalS = EdgeInsets.symmetric(horizontal: 8.0);
  static const EdgeInsets paddingHorizontalM = EdgeInsets.symmetric(horizontal: 12.0);
  static const EdgeInsets paddingHorizontalL = EdgeInsets.symmetric(horizontal: 16.0);
  static const EdgeInsets paddingHorizontalXL = EdgeInsets.symmetric(horizontal: 20.0);
  static const EdgeInsets paddingHorizontalXXL = EdgeInsets.symmetric(horizontal: 24.0);
  
  // Vertical Padding
  static const EdgeInsets paddingVerticalS = EdgeInsets.symmetric(vertical: 8.0);
  static const EdgeInsets paddingVerticalM = EdgeInsets.symmetric(vertical: 12.0);
  static const EdgeInsets paddingVerticalL = EdgeInsets.symmetric(vertical: 16.0);
  static const EdgeInsets paddingVerticalXL = EdgeInsets.symmetric(vertical: 20.0);
  
  // Card Padding
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(20.0);
  
  // Screen Padding
  static const EdgeInsets screenPadding = EdgeInsets.all(16.0);
  static const EdgeInsets screenPaddingHorizontal = EdgeInsets.symmetric(horizontal: 16.0);
  static const EdgeInsets screenPaddingVertical = EdgeInsets.symmetric(vertical: 16.0);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, primaryBlueDark],
  );

  /// Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: successGreen,
        error: errorRed,
        surface: white,
        surfaceContainerHighest: lightGray,
      ),

      // Text Theme using Agrandir font
      fontFamily: 'Agrandir',
      textTheme: const TextTheme(
        // Headings - Agrandir Bold
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          fontFamily: 'Agrandir',
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          fontFamily: 'Agrandir',
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          fontFamily: 'Agrandir',
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          fontFamily: 'Agrandir',
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          fontFamily: 'Agrandir',
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          fontFamily: 'Agrandir',
        ),
        // Subheadings - Agrandir (regular)
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.normal,
          color: textPrimary,
          fontFamily: 'Agrandir',
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimary,
          fontFamily: 'Agrandir',
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textPrimary,
          fontFamily: 'Agrandir',
        ),
        // Body - Agrandir (regular)
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimary,
          fontFamily: 'Agrandir',
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textPrimary,
          fontFamily: 'Agrandir',
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textSecondary,
          fontFamily: 'Agrandir',
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textPrimary,
          fontFamily: 'Agrandir',
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textPrimary,
          fontFamily: 'Agrandir',
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.normal,
          color: textSecondary,
          fontFamily: 'Agrandir',
        ),
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: primaryBlue,
        foregroundColor: white,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: white,
          fontFamily: 'Agrandir',
        ),
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        color: white,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Agrandir',
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'Agrandir',
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(
          color: darkGray,
          fontSize: 14,
          fontFamily: 'Agrandir',
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: primaryBlue,
        unselectedItemColor: darkGray,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'Agrandir',
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          fontFamily: 'Agrandir',
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryBlue,
        foregroundColor: white,
        elevation: 4,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: mediumGray,
        thickness: 1,
      ),
    );
  }
}
