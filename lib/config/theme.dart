import 'package:flutter/material.dart';

/// Can Can App Theme — clean/minimal, matching the admin panel palette.
class AppTheme {
  // Brand Colors (from the admin design system)
  static const Color primaryBlue = Color(0xFF6DD3DC); // teal primary (name kept for compatibility)
  static const Color primaryBlueDark = Color(0xFF4BBFC9);
  static const Color secondary = Color(0xFFA9E06D); // fresh green
  static const Color secondaryDark = Color(0xFF8FCA53);
  static const Color soft = Color(0xFFE3F0B6);
  static const Color successGreen = Color(0xFF3FBF6F);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);

  // Neutrals (slate scale, matching admin)
  static const Color background = Color(0xFFFAF8F0); // warm off-white app background
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF8FAFC); // slate-50
  static const Color mediumGray = Color(0xFFE2E8F0); // slate-200 (borders)
  static const Color darkGray = Color(0xFF94A3B8); // slate-400
  static const Color textPrimary = Color(0xFF0F172A); // slate-900
  static const Color textSecondary = Color(0xFF64748B); // slate-500

  // Status backgrounds (soft tints)
  static const Color pendingBg = Color(0xFFFEF3C7); // amber-100
  static const Color completedBg = Color(0xFFDCFCE7); // green-100
  static const Color cancelledBg = Color(0xFFFEE2E2); // red-100

  // Spacing (8dp grid)
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXL = 20.0;
  static const double spacingXXL = 24.0;
  static const double spacingXXXL = 32.0;

  // Padding
  static const EdgeInsets paddingXS = EdgeInsets.all(4.0);
  static const EdgeInsets paddingS = EdgeInsets.all(8.0);
  static const EdgeInsets paddingM = EdgeInsets.all(12.0);
  static const EdgeInsets paddingL = EdgeInsets.all(16.0);
  static const EdgeInsets paddingXL = EdgeInsets.all(20.0);
  static const EdgeInsets paddingXXL = EdgeInsets.all(24.0);

  static const EdgeInsets paddingHorizontalS = EdgeInsets.symmetric(horizontal: 8.0);
  static const EdgeInsets paddingHorizontalM = EdgeInsets.symmetric(horizontal: 12.0);
  static const EdgeInsets paddingHorizontalL = EdgeInsets.symmetric(horizontal: 16.0);
  static const EdgeInsets paddingHorizontalXL = EdgeInsets.symmetric(horizontal: 20.0);
  static const EdgeInsets paddingHorizontalXXL = EdgeInsets.symmetric(horizontal: 24.0);

  static const EdgeInsets paddingVerticalS = EdgeInsets.symmetric(vertical: 8.0);
  static const EdgeInsets paddingVerticalM = EdgeInsets.symmetric(vertical: 12.0);
  static const EdgeInsets paddingVerticalL = EdgeInsets.symmetric(vertical: 16.0);
  static const EdgeInsets paddingVerticalXL = EdgeInsets.symmetric(vertical: 20.0);

  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(20.0);

  static const EdgeInsets screenPadding = EdgeInsets.all(16.0);
  static const EdgeInsets screenPaddingHorizontal = EdgeInsets.symmetric(horizontal: 16.0);
  static const EdgeInsets screenPaddingVertical = EdgeInsets.symmetric(vertical: 16.0);

  // Radii (rounded-xl feel)
  static const double radius = 14.0;
  static const double radiusSmall = 10.0;

  // Kept for compatibility with screens that still reference a gradient — now a
  // subtle, near-flat teal so headers read as clean rather than heavy.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, primaryBlueDark],
  );

  /// Reusable minimal card decoration: white, subtle border, gentle radius.
  static BoxDecoration cardDecoration({Color? borderColor}) => BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? mediumGray),
      );

  /// Light Theme — minimal, flat, slate + teal.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        onPrimary: textPrimary,
        secondary: secondary,
        error: errorRed,
        surface: white,
        surfaceContainerHighest: lightGray,
      ),
      fontFamily: 'Agrandir',
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: textPrimary),
        displayMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textPrimary),
        displaySmall: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary),
        titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
        titleSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: textPrimary),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: textSecondary),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textPrimary),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: textSecondary),
      ).apply(fontFamily: 'Agrandir'),

      // Flat, clean app bar — white surface, dark text (no colored gradient bar).
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: background,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          fontFamily: 'Agrandir',
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: mediumGray),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Agrandir'),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: mediumGray),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Agrandir'),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlueDark,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Agrandir'),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: mediumGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: mediumGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: primaryBlueDark, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: const TextStyle(color: darkGray, fontSize: 14, fontFamily: 'Agrandir'),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: primaryBlueDark,
        unselectedItemColor: darkGray,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'Agrandir'),
        unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, fontFamily: 'Agrandir'),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryBlue,
        foregroundColor: textPrimary,
        elevation: 1,
      ),

      dividerTheme: const DividerThemeData(color: mediumGray, thickness: 1),
    );
  }
}
