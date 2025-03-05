// lib/theme/app_theme.dart

import 'package:flutter/material.dart';
import '../responsive_utils.dart';

/// Centralized theme management for the app
/// All theme-related configurations are defined here to maintain consistency
class AppTheme {
  // Brand colors
  static const Color primaryColor = Color(0xFF02838A);
  static const Color primaryDarkColor = Color(0xFF026670);
  static const Color accentColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFD32F2F);

  // Background colors
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color backgroundWhite = Colors.white;

  // Status colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color infoColor = Color(0xFF2196F3);

  // Brand identity
  // (Placeholder paths - update with actual assets when available)
  static const String logoPath = 'assets/images/logo.png';
  static const String iconPath = 'assets/images/icon.png';

  /// Get the main app theme based on device type and brightness
  static ThemeData getTheme(
      {required bool isTablet, Brightness brightness = Brightness.light}) {
    return brightness == Brightness.dark
        ? _getDarkTheme(isTablet)
        : _getLightTheme(isTablet);
  }

  /// Light theme implementation
  static ThemeData _getLightTheme(bool isTablet) {
    return ThemeData(
      primarySwatch: Colors.teal,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundLight,

      // App bar theme
      appBarTheme: _buildAppBarTheme(isTablet, Brightness.light),

      // Button themes
      elevatedButtonTheme: _buildElevatedButtonTheme(isTablet),
      textButtonTheme: _buildTextButtonTheme(isTablet),

      // Card theme
      cardTheme: _buildCardTheme(isTablet),

      // Input decoration theme
      inputDecorationTheme: _buildInputDecorationTheme(isTablet),

      // Divider theme
      dividerTheme: _buildDividerTheme(isTablet),

      // Chip theme
      chipTheme: _buildChipTheme(isTablet),

      // Color scheme
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        error: errorColor,
        surface: backgroundWhite,
        background: backgroundLight,
      ),

      // Dialog theme
      dialogTheme: _buildDialogTheme(isTablet),

      // Bottom sheet theme
      bottomSheetTheme: _buildBottomSheetTheme(isTablet),
    );
  }

  /// Dark theme implementation (for future use)
  static ThemeData _getDarkTheme(bool isTablet) {
    // This is a placeholder for future dark theme implementation
    return ThemeData.dark().copyWith(
      primaryColor: primaryDarkColor,
      colorScheme: ColorScheme.dark(
        primary: primaryDarkColor,
        secondary: accentColor,
        surface: Color(0xFF121212), // Standard dark theme surface color
      ),
      appBarTheme: _buildAppBarTheme(isTablet, Brightness.dark),
      // Other dark theme customizations would go here
    );
  }

  /// App bar theme builder
  static AppBarTheme _buildAppBarTheme(bool isTablet, Brightness brightness) {
    return AppBarTheme(
      backgroundColor:
          brightness == Brightness.light ? primaryColor : primaryDarkColor,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: isTablet ? 22 : 20,
        fontWeight: FontWeight.bold,
      ),
      // Taller app bar for tablets
      toolbarHeight: isTablet ? 64 : 56,
      iconTheme: const IconThemeData(color: Colors.white),
      // Responsive padding
      actionsIconTheme: IconThemeData(
        color: Colors.white,
        size: isTablet ? 28 : 24,
      ),
    );
  }

  /// Elevated button theme builder
  static ElevatedButtonThemeData _buildElevatedButtonTheme(bool isTablet) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        // Larger touch targets on tablets
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isTablet ? 12 : 10,
        ),
        // Larger text on tablets
        textStyle: TextStyle(
          fontSize: isTablet ? 16 : 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Text button theme builder
  static TextButtonThemeData _buildTextButtonTheme(bool isTablet) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        // Increased padding for better touch targets
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: isTablet ? 10 : 8,
        ),
        // Responsive text
        textStyle: TextStyle(
          fontSize: isTablet ? 15 : 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Card theme builder
  static CardTheme _buildCardTheme(bool isTablet) {
    return CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.symmetric(
        vertical: 4,
        horizontal: isTablet ? 10 : 8,
      ),
    );
  }

  /// Input decoration theme builder
  static InputDecorationTheme _buildInputDecorationTheme(bool isTablet) {
    return InputDecorationTheme(
      isDense: !isTablet, // Only dense on phones
      contentPadding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: isTablet ? 16 : 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      // Responsive label text
      labelStyle: TextStyle(
        fontSize: isTablet ? 16 : 14,
      ),
      // Responsive hint text
      hintStyle: TextStyle(
        fontSize: isTablet ? 15 : 14,
        color: Colors.grey.shade500,
      ),
    );
  }

  /// Divider theme builder
  static DividerThemeData _buildDividerTheme(bool isTablet) {
    return DividerThemeData(
      space: isTablet ? 16 : 12,
      thickness: 1,
      color: Colors.grey.shade300,
    );
  }

  /// Chip theme builder
  static ChipThemeData _buildChipTheme(bool isTablet) {
    return ChipThemeData(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 10 : 8,
        vertical: isTablet ? 8 : 6,
      ),
      labelStyle: TextStyle(
        fontSize: isTablet ? 14 : 12,
      ),
      iconTheme: IconThemeData(
        size: isTablet ? 18 : 16,
      ),
    );
  }

  /// Dialog theme builder
  static DialogTheme _buildDialogTheme(bool isTablet) {
    return DialogTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      titleTextStyle: TextStyle(
        fontSize: isTablet ? 22 : 20,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      contentTextStyle: TextStyle(
        fontSize: isTablet ? 16 : 14,
        color: Colors.black87,
      ),
    );
  }

  /// Bottom sheet theme builder
  static BottomSheetThemeData _buildBottomSheetTheme(bool isTablet) {
    return BottomSheetThemeData(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      // More space on tablets
      constraints: BoxConstraints(
        maxWidth: isTablet ? 600 : double.infinity,
      ),
    );
  }

  static T responsiveValue<T>({
    required BuildContext context,
    required T phone,
    required T tablet,
    T? phoneLarge,
    T? phoneSmall,
  }) {
    final deviceSize = ResponsiveUtils.getDeviceSize(context);

    if (deviceSize == DeviceSize.tabletSmall ||
        deviceSize == DeviceSize.tabletLarge) {
      return tablet;
    } else if (deviceSize == DeviceSize.phoneLarge && phoneLarge != null) {
      return phoneLarge;
    } else if (deviceSize == DeviceSize.phoneSmall && phoneSmall != null) {
      return phoneSmall;
    } else {
      return phone;
    }
  }
}

/// Helper class for brand assets management
class BrandAssets {
  /// Get the app logo with appropriate size for current context
  static Widget getLogo(BuildContext context, {double? size}) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final logoSize = size ?? (isTablet ? 120.0 : 80.0);

    // Eventually replace this placeholder with actual logo
    return Placeholder(
      fallbackWidth: logoSize,
      fallbackHeight: logoSize,
      color: AppTheme.primaryColor,
      /* When assets are available:
      return Image.asset(
        AppTheme.logoPath,
        width: logoSize,
        height: logoSize,
      );
      */
    );
  }

  /// Get app icon as a widget
  static Widget getIcon(BuildContext context, {double? size}) {
    final iconSize = size ?? 48.0;

    // Eventually replace this placeholder with actual icon
    return Placeholder(
      fallbackWidth: iconSize,
      fallbackHeight: iconSize,
      color: AppTheme.accentColor,
    );
  }
}
