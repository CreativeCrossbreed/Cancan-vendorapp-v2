import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Can Can App Theme Configuration
/// Based on official Can Can Design Guidelines
class AppTheme {
  // Brand Colors from Design Guidelines
  static const Color successBackground =
      Color(0xFFa3cf00); // Success Background
  static const Color surfaceColor = Color(0xFFf0efec); // Surface Colors
  static const Color cautionColor = Color(0xFF9f7200); // Caution
  static const Color stopColor = Color(0xFFff073a); // Stop/Error
  static const Color infoColor = Color(0xFF2196F3); // Info (assumed blue)

  // Legacy color aliases for compatibility
  static const Color primaryBlue = infoColor; // #2196F3
  static const Color primaryBlueDark = Color(0xFF1976D2); // Darker blue
  static const Color successGreen = primaryGreen; // #a3cf00

  // Extended Color Palette
  static const Color primaryGreen = Color(0xFFa3cf00); // Primary brand green
  static const Color primaryGreenDark = Color(0xFF8bb800); // Darker variant
  static const Color surfaceLight = Color(0xFFf0efec); // Main surface color
  static const Color surfaceDark = Color(0xFFe0dfd8); // Darker surface
  static const Color warningOrange = Color(0xFF9f7200); // Warning/caution
  static const Color errorRed = Color(0xFFff073a); // Error/stop

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF8F8F8);
  static const Color mediumGray = Color(0xFFCCCCCC);
  static const Color darkGray = Color(0xFF666666);
  static const Color textPrimary = Color(0xFF1a1a1a);
  static const Color textSecondary = Color(0xFF666666);

  // Spacing and Layout
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 40.0;
  static const double spacingXXXL = 48.0;

  // Padding
  static const EdgeInsets paddingS = EdgeInsets.all(spacingS);
  static const EdgeInsets paddingM = EdgeInsets.all(spacingM);
  static const EdgeInsets paddingL = EdgeInsets.all(spacingL);
  static const EdgeInsets paddingXL = EdgeInsets.all(spacingXL);
  static const EdgeInsets paddingXXL = EdgeInsets.all(spacingXXL);
  static const EdgeInsets screenPadding = EdgeInsets.all(spacingM);
  static const EdgeInsets screenPaddingHorizontal =
      EdgeInsets.symmetric(horizontal: spacingM);
  static const EdgeInsets cardPadding = EdgeInsets.all(spacingM);
  static const EdgeInsets paddingVerticalS =
      EdgeInsets.symmetric(vertical: spacingS);
  static const EdgeInsets paddingVerticalM =
      EdgeInsets.symmetric(vertical: spacingM);
  static const EdgeInsets paddingVerticalL =
      EdgeInsets.symmetric(vertical: spacingL);

  // Status Colors (updated to match brand)
  static const Color pendingBg = Color(0xFFfff3cd); // Light warning
  static const Color completedBg = Color(0xFFd4edda); // Light success
  static const Color cancelledBg = Color(0xFFf8d7da); // Light error

  // Chart Colors (updated to match brand palette)
  static const List<Color> chartColors = [
    primaryGreen, // Chart 1 - Primary Green
    infoColor, // Chart 2 - Info Blue
    warningOrange, // Chart 3 - Warning Orange
    errorRed, // Chart 4 - Error Red
    Color(0xFF6f42c1), // Chart 5 - Purple
  ];

  // Chart Grid & Axis Colors
  static const Color chartGridColor = Color(0xFFE0E0E0);
  static const Color chartAxisColor = Color(0xFF757575);
  static const Color chartBackgroundColor = Color(0xFFf0efec);

  // Trend Indicator Colors
  static const Color trendUpColor = primaryGreen;
  static const Color trendDownColor = errorRed;
  static const Color trendNeutralColor = darkGray;

  // Brand Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGreen, primaryGreenDark],
  );

  // Surface Gradient
  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surfaceLight, surfaceDark],
  );

  /// Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        secondary: infoColor,
        error: errorRed,
        surface: surfaceLight,
        surfaceContainerHighest: surfaceDark,
      ),

      // Text Theme using Can Can and Agrandir fonts
      // Note: Using similar Google Fonts as placeholders for custom fonts
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        // Headings: Can Can font (using Poppins as placeholder)
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.25,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.15,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),

        // Subheadings: Agrandir Regular (using Roboto as placeholder)
        titleLarge: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        titleSmall: GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),

        // Body: Agrandir Bold/Regular (using Roboto as placeholder)
        bodyLarge: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodySmall: GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),

        // Labels
        labelLarge: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        labelMedium: GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        labelSmall: GoogleFonts.roboto(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: primaryGreen,
        foregroundColor: white,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: white,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),

      // Card Theme with brand colors
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: surfaceLight,
        surfaceTintColor: primaryGreen,
        shadowColor: Colors.black.withOpacity(0.1),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Elevated Button Theme with brand styling
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: white,
          elevation: 0,
          shadowColor: primaryGreen.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          textStyle: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme with brand styling
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: mediumGray, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: mediumGray, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.roboto(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: GoogleFonts.roboto(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: GoogleFonts.roboto(
          color: primaryGreen,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Bottom Navigation Bar Theme with brand colors
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceLight,
        selectedItemColor: primaryGreen,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: surfaceLight,
        selectedColor: primaryGreen.withOpacity(0.2),
        disabledColor: mediumGray,
        labelStyle: GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        side: const BorderSide(color: mediumGray),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryGreen,
        linearTrackColor: surfaceLight,
        circularTrackColor: surfaceLight,
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryGreen;
          }
          return mediumGray;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryGreen.withOpacity(0.5);
          }
          return mediumGray.withOpacity(0.5);
        }),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryGreen;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryGreen;
          }
          return mediumGray;
        }),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: mediumGray,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
