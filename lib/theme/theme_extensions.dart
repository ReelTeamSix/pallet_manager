import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Extension methods to access theme properties throughout the app
extension ThemeExtensions on BuildContext {
  /// Get the app's primary color
  Color get primaryColor => AppTheme.primaryColor;

  /// Get the app's primary dark color
  Color get primaryDarkColor => AppTheme.primaryDarkColor;

  /// Get the app's accent color
  Color get accentColor => AppTheme.accentColor;

  /// Get the app's error color
  Color get errorColor => AppTheme.errorColor;

  /// Get the app's success color
  Color get successColor => AppTheme.successColor;

  /// Get the app's warning color
  Color get warningColor => AppTheme.warningColor;

  /// Get the app's info color
  Color get infoColor => AppTheme.infoColor;

  /// Get the app's light background color
  Color get backgroundLight => AppTheme.backgroundLight;

  /// Get the app's white background color
  Color get backgroundWhite => AppTheme.backgroundWhite;

  /// Get standard corner radius for cards, buttons, etc.
  BorderRadius get standardBorderRadius => BorderRadius.circular(8.0);

  /// Get larger corner radius for dialogs and modals
  BorderRadius get largeBorderRadius => BorderRadius.circular(16.0);

  /// Get rounded rectangle shape with standard radius
  RoundedRectangleBorder get standardRoundedShape => RoundedRectangleBorder(
        borderRadius: standardBorderRadius,
      );

  /// Get rounded rectangle shape with large radius
  RoundedRectangleBorder get largeRoundedShape => RoundedRectangleBorder(
        borderRadius: largeBorderRadius,
      );

  /// Get standard container decoration
  BoxDecoration get standardBoxDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: standardBorderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      );

  /// Determine if current device is a tablet
  bool get isTablet => MediaQuery.of(this).size.shortestSide >= 600;

  /// Gets a responsive value based on device type
  T responsiveValue<T>({
    required T phone,
    required T tablet,
  }) =>
      AppTheme.responsiveValue<T>(
        context: this,
        phone: phone,
        tablet: tablet,
      );
      
  // Text style extensions
  
  /// Extra small (tiny) text style
  TextStyle get tinyText => TextStyle(fontSize: 10);
  
  /// Small text style
  TextStyle get smallText => TextStyle(fontSize: 12);
  
  /// Medium text style
  TextStyle get mediumText => TextStyle(fontSize: 14);
  
  /// Large text style
  TextStyle get largeText => TextStyle(fontSize: 16);
  
  /// Extra large text style
  TextStyle get xLargeText => TextStyle(fontSize: 18);
  
  /// Tiny text style with weight
  TextStyle tinyTextWeight(FontWeight weight) => tinyText.copyWith(fontWeight: weight);
  
  /// Small text style with weight
  TextStyle smallTextWeight(FontWeight weight) => smallText.copyWith(fontWeight: weight);
  
  /// Medium text style with weight
  TextStyle mediumTextWeight(FontWeight weight) => mediumText.copyWith(fontWeight: weight);
  
  /// Large text style with weight
  TextStyle largeTextWeight(FontWeight weight) => largeText.copyWith(fontWeight: weight);
  
  /// Extra large text style with weight
  TextStyle xLargeTextWeight(FontWeight weight) => xLargeText.copyWith(fontWeight: weight);
  
  /// Tiny text style with color
  TextStyle tinyTextColor(Color color) => tinyText.copyWith(color: color);
  
  /// Small text style with color
  TextStyle smallTextColor(Color color) => smallText.copyWith(color: color);
  
  /// Medium text style with color
  TextStyle mediumTextColor(Color color) => mediumText.copyWith(color: color);
  
  /// Large text style with color
  TextStyle largeTextColor(Color color) => largeText.copyWith(color: color);
  
  /// Extra large text style with color
  TextStyle xLargeTextColor(Color color) => xLargeText.copyWith(color: color);
}
