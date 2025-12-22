import 'package:flutter/material.dart';

/// Responsive Design Configuration for Can Can App
/// Provides consistent scaling and spacing across different screen sizes

class ResponsiveConfig {
  // Breakpoint definitions
  static const double mobileSmall = 360;   // iPhone SE
  static const double mobileMedium = 375;  // iPhone 12
  static const double mobileLarge = 414;   // iPhone Pro Max
  static const double tabletSmall = 768;   // iPad Mini
  static const double tabletLarge = 1024;  // iPad Pro

  // Get current screen size
  static Size get screenSize => MediaQueryData.fromView(WidgetsBinding.instance.platformDispatcher.views.first).size;

  // Check device type
  static bool get isMobile => screenSize.width < tabletSmall;
  static bool get isTablet => screenSize.width >= tabletSmall;
  static bool get isMobileSmall => screenSize.width < mobileMedium;
  static bool get isMobileLarge => screenSize.width >= mobileLarge;

  // Scaling factors
  static double get scaleFactor {
    if (screenSize.width < mobileSmall) return 0.85;
    if (screenSize.width < mobileMedium) return 0.9;
    if (screenSize.width < mobileLarge) return 1.0;
    if (screenSize.width < tabletSmall) return 1.1;
    return 1.2;
  }

  // Spacing system (8px grid)
  static double get xs => 4 * scaleFactor;      // 4px base
  static double get sm => 8 * scaleFactor;      // 8px base
  static double get md => 16 * scaleFactor;     // 16px base
  static double get lg => 24 * scaleFactor;     // 24px base
  static double get xl => 32 * scaleFactor;     // 32px base
  static double get xxl => 48 * scaleFactor;    // 48px base

  // Border radius scaling
  static double get radiusSmall => 8 * scaleFactor;
  static double get radiusMedium => 12 * scaleFactor;
  static double get radiusLarge => 16 * scaleFactor;
  static double get radiusXLarge => 24 * scaleFactor;

  // Font sizes
  static double get fontXs => 12 * scaleFactor;
  static double get fontSm => 14 * scaleFactor;
  static double get fontMd => 16 * scaleFactor;
  static double get fontLg => 18 * scaleFactor;
  static double get fontXl => 20 * scaleFactor;
  static double get font2Xl => 24 * scaleFactor;
  static double get font3Xl => 28 * scaleFactor;
  static double get font4Xl => 32 * scaleFactor;

  // Icon sizes
  static double get iconXs => 16 * scaleFactor;
  static double get iconSm => 20 * scaleFactor;
  static double get iconMd => 24 * scaleFactor;
  static double get iconLg => 28 * scaleFactor;
  static double get iconXl => 32 * scaleFactor;
  static double get icon2Xl => 48 * scaleFactor;

  // Component heights
  static double get buttonHeight => 48 * scaleFactor;
  static double get inputHeight => 48 * scaleFactor;
  static double get cardMinHeight => 80 * scaleFactor;
  static double get appBarHeight => kToolbarHeight * scaleFactor;

  // Grid columns for responsive layout
  static int get gridColumns {
    if (screenSize.width < mobileMedium) return 1;
    if (screenSize.width < mobileLarge) return 2;
    if (screenSize.width < tabletSmall) return 2;
    if (screenSize.width < tabletLarge) return 3;
    return 4;
  }

  // Content max width
  static double get contentMaxWidth {
    if (isTablet) {
      return screenSize.width * 0.8;
    }
    return double.infinity;
  }
}

/// Extension methods for responsive design
extension ResponsiveExtension on num {
  double get rs => this * ResponsiveConfig.scaleFactor;
  double get w => (this / 375) * ResponsiveConfig.screenSize.width;  // Width percentage based on iPhone 12
  double get h => (this / 812) * ResponsiveConfig.screenSize.height; // Height percentage based on iPhone 12
}