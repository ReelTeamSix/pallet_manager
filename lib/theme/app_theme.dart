// lib/theme/app_theme.dart

import 'package:flutter/material.dart';
import '../responsive_utils.dart';

/// Centralized theme management for the app
/// All theme-related configurations are defined here to maintain consistency
class AppTheme {
  // Brand colors - updated with a more modern palette
  static const Color primaryColor = Color(0xFF1A73E8); // Google Blue
  static const Color primaryDarkColor = Color(0xFF0D47A1);
  static const Color accentColor = Color(0xFF4285F4);
  static const Color errorColor = Color(0xFFEA4335); // Google Red

  // Background colors
  static const Color backgroundLight = Color(0xFFF8F9FA); // Light gray background
  static const Color backgroundWhite = Colors.white;
  static const Color surfaceColor = Colors.white;

  // Status colors
  static const Color successColor = Color(0xFF34A853); // Google Green
  static const Color warningColor = Color(0xFFFBBC05); // Google Yellow
  static const Color infoColor = Color(0xFF4285F4); // Google Blue

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

  /// Light theme implementation - updated for Material 3
  static ThemeData _getLightTheme(bool isTablet) {
    final ColorScheme colorScheme = ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      error: errorColor,
      surface: surfaceColor,
      background: backgroundLight,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black87,
      onBackground: Colors.black87,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundLight,

      // App bar theme
      appBarTheme: _buildAppBarTheme(isTablet, Brightness.light),

      // Button themes
      elevatedButtonTheme: _buildElevatedButtonTheme(isTablet, colorScheme),
      textButtonTheme: _buildTextButtonTheme(isTablet, colorScheme),

      // Card theme
      cardTheme: _buildCardTheme(isTablet),

      // Input decoration theme
      inputDecorationTheme: _buildInputDecorationTheme(isTablet),

      // Divider theme
      dividerTheme: _buildDividerTheme(isTablet),

      // Chip theme
      chipTheme: _buildChipTheme(isTablet),

      // Dialog theme
      dialogTheme: _buildDialogTheme(isTablet),

      // Bottom sheet theme
      bottomSheetTheme: _buildBottomSheetTheme(isTablet),
      
      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
    );
  }

  /// Dark theme implementation - updated for Material 3
  static ThemeData _getDarkTheme(bool isTablet) {
    final ColorScheme colorScheme = ColorScheme.dark(
      primary: primaryColor,
      secondary: accentColor,
      error: errorColor,
      surface: const Color(0xFF1F1F1F),
      background: const Color(0xFF121212),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white70,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme, 
      scaffoldBackgroundColor: colorScheme.background,
      appBarTheme: _buildAppBarTheme(isTablet, Brightness.dark),
      elevatedButtonTheme: _buildElevatedButtonTheme(isTablet, colorScheme),
      textButtonTheme: _buildTextButtonTheme(isTablet, colorScheme),
      cardTheme: _buildCardTheme(isTablet),
      inputDecorationTheme: _buildInputDecorationTheme(isTablet),
      dividerTheme: _buildDividerTheme(isTablet, isDark: true),
      chipTheme: _buildChipTheme(isTablet),
      dialogTheme: _buildDialogTheme(isTablet, isDark: true),
      bottomSheetTheme: _buildBottomSheetTheme(isTablet),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
    );
  }

  /// App bar theme builder
  static AppBarTheme _buildAppBarTheme(bool isTablet, Brightness brightness) {
    return AppBarTheme(
      backgroundColor: brightness == Brightness.light 
          ? Colors.white 
          : const Color(0xFF1F1F1F),
      titleTextStyle: TextStyle(
        color: brightness == Brightness.light ? Colors.black87 : Colors.white,
        fontSize: isTablet ? 22 : 20,
        fontWeight: FontWeight.w500,
      ),
      toolbarHeight: isTablet ? 64 : 56,
      iconTheme: IconThemeData(
        color: brightness == Brightness.light ? Colors.black87 : Colors.white,
      ),
      elevation: 0,
      centerTitle: false,
      actionsIconTheme: IconThemeData(
        color: brightness == Brightness.light ? Colors.black87 : Colors.white,
        size: isTablet ? 28 : 24,
      ),
    );
  }

  /// Elevated button theme builder
  static ElevatedButtonThemeData _buildElevatedButtonTheme(bool isTablet, ColorScheme colorScheme) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: colorScheme.onPrimary,
        backgroundColor: colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isTablet ? 14 : 12,
        ),
        textStyle: TextStyle(
          fontSize: isTablet ? 16 : 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        elevation: 0,
      ),
    );
  }

  /// Text button theme builder
  static TextButtonThemeData _buildTextButtonTheme(bool isTablet, ColorScheme colorScheme) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: isTablet ? 10 : 8,
        ),
        textStyle: TextStyle(
          fontSize: isTablet ? 15 : 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Card theme builder
  static CardTheme _buildCardTheme(bool isTablet) {
    return CardTheme(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
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
        horizontal: 16,
        vertical: isTablet ? 16 : 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: isTablet ? 16 : 14,
      ),
      hintStyle: TextStyle(
        fontSize: isTablet ? 15 : 14,
        color: Colors.grey.shade500,
      ),
    );
  }

  /// Divider theme builder
  static DividerThemeData _buildDividerTheme(bool isTablet, {bool isDark = false}) {
    return DividerThemeData(
      space: isTablet ? 16 : 12,
      thickness: 1,
      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      iconTheme: IconThemeData(
        size: isTablet ? 18 : 16,
      ),
    );
  }

  /// Dialog theme builder
  static DialogTheme _buildDialogTheme(bool isTablet, {bool isDark = false}) {
    return DialogTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      titleTextStyle: TextStyle(
        fontSize: isTablet ? 22 : 20,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : Colors.black87,
      ),
      contentTextStyle: TextStyle(
        fontSize: isTablet ? 16 : 14,
        color: isDark ? Colors.white70 : Colors.black87,
      ),
      backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
    );
  }

  /// Bottom sheet theme builder
  static BottomSheetThemeData _buildBottomSheetTheme(bool isTablet) {
    return BottomSheetThemeData(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
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

    // Create a custom painted logo until assets are available
    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pallet icon background
            Icon(
              Icons.view_in_ar_rounded,
              size: logoSize * 0.6,
              color: Colors.white.withOpacity(0.7),
            ),
            // Dollar sign for sales/profit
            Positioned(
              bottom: logoSize * 0.22,
              right: logoSize * 0.22,
              child: Container(
                padding: EdgeInsets.all(logoSize * 0.08),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.attach_money,
                  size: logoSize * 0.2,
                  color: AppTheme.accentColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get app icon as a widget
  static Widget getIcon(BuildContext context, {double? size}) {
    final iconSize = size ?? 48.0;
    // Create a custom icon until assets are available
    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(iconSize * 0.24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: iconSize * 0.12,
            offset: Offset(0, iconSize * 0.04),
          ),
        ],
      ),
      child: Icon(
        Icons.view_in_ar_rounded,
        size: iconSize * 0.5,
        color: Colors.white,
      ),
    );
  }
}
