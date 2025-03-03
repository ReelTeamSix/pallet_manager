// File: lib/responsive_utils.dart
import 'package:flutter/material.dart';

/// Utility class to manage responsive sizing throughout the app
class ResponsiveUtils {
  /// Private constructor to prevent instantiation
  ResponsiveUtils._();

  /// Screen size breakpoints
  static const double kPhoneSmall = 320; // iPhone SE, small Android
  static const double kPhoneMedium = 375; // iPhone 13/14 Pro, mid-size Android
  static const double kPhoneLarge = 414; // iPhone 13/14 Pro Max, large Android
  static const double kTabletSmall = 600; // Small tablets
  static const double kTabletLarge = 768; // iPad, larger tablets

  /// Font scale breakpoints
  static const double kFontScaleNormal = 1.0;
  static const double kFontScaleMedium = 1.25;
  static const double kFontScaleLarge = 1.5;

  /// Determine if the device is a tablet based on shortest side
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide >= kTabletSmall;
  }

  /// Determine device size category
  static DeviceSize getDeviceSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < kPhoneSmall) return DeviceSize.phoneXSmall;
    if (width < kPhoneMedium) return DeviceSize.phoneSmall;
    if (width < kPhoneLarge) return DeviceSize.phoneMedium;
    if (width < kTabletSmall) return DeviceSize.phoneLarge;
    if (width < kTabletLarge) return DeviceSize.tabletSmall;
    return DeviceSize.tabletLarge;
  }

  /// Determine font scale category
  static FontScale getFontScale(BuildContext context) {
    final fontScale = MediaQuery.of(context).textScaler.scale(1.0);

    if (fontScale <= kFontScaleNormal) return FontScale.normal;
    if (fontScale <= kFontScaleMedium) return FontScale.medium;
    return FontScale.large;
  }

  /// Get appropriate font size based on device size and textScaleFactor
  static double getFontSize(BuildContext context, FontSizeType type) {
    final deviceSize = getDeviceSize(context);
    final fontScale = getFontScale(context);

    // Base font sizes (in logical pixels)
    double baseSize;

    switch (type) {
      case FontSizeType.tiny:
        baseSize = 10;
        break;
      case FontSizeType.small:
        baseSize = 12;
        break;
      case FontSizeType.medium:
        baseSize = 14;
        break;
      case FontSizeType.large:
        baseSize = 16;
        break;
      case FontSizeType.xLarge:
        baseSize = 18;
        break;
      case FontSizeType.xxLarge:
        baseSize = 22;
        break;
    }

    // Apply device size adjustment
    double deviceSizeMultiplier = 1.0;
    if (deviceSize == DeviceSize.phoneXSmall) {
      deviceSizeMultiplier = 0.9;
    } else if (deviceSize == DeviceSize.tabletSmall ||
        deviceSize == DeviceSize.tabletLarge) {
      deviceSizeMultiplier = 1.1;
    }

    // Apply font scale adjustment (compressing for very large font scales)
    double fontScaleMultiplier = 1.0;
    if (fontScale == FontScale.large) {
      fontScaleMultiplier = 0.85; // Compress to avoid overflow
    }

    return baseSize * deviceSizeMultiplier * fontScaleMultiplier;
  }

  /// Get appropriate icon size based on device size
  static double getIconSize(BuildContext context, IconSizeType type) {
    final deviceSize = getDeviceSize(context);

    // Base icon sizes (in logical pixels)
    double baseSize;

    switch (type) {
      case IconSizeType.tiny:
        baseSize = 12;
        break;
      case IconSizeType.small:
        baseSize = 16;
        break;
      case IconSizeType.medium:
        baseSize = 22;
        break;
      case IconSizeType.large:
        baseSize = 28;
        break;
      case IconSizeType.xLarge:
        baseSize = 36;
        break;
    }

    // Apply device size adjustment
    double deviceSizeMultiplier = 1.0;
    if (deviceSize == DeviceSize.phoneXSmall) {
      deviceSizeMultiplier = 0.9;
    } else if (deviceSize == DeviceSize.tabletSmall ||
        deviceSize == DeviceSize.tabletLarge) {
      deviceSizeMultiplier = 1.2;
    }

    return baseSize * deviceSizeMultiplier;
  }

  /// Get appropriate padding based on device size
  static EdgeInsets getPadding(BuildContext context, PaddingType type) {
    final deviceSize = getDeviceSize(context);

    // Base padding values (in logical pixels)
    double base;

    switch (type) {
      case PaddingType.tiny:
        base = 4;
        break;
      case PaddingType.small:
        base = 8;
        break;
      case PaddingType.medium:
        base = 16;
        break;
      case PaddingType.large:
        base = 24;
        break;
      case PaddingType.xLarge:
        base = 32;
        break;
      case PaddingType.zero:
        base = 0;
        break;
    }

    // Apply device size adjustment
    double deviceSizeMultiplier = 1.0;
    if (deviceSize == DeviceSize.phoneXSmall) {
      deviceSizeMultiplier = 0.9;
    } else if (deviceSize == DeviceSize.tabletSmall) {
      deviceSizeMultiplier = 1.2;
    } else if (deviceSize == DeviceSize.tabletLarge) {
      deviceSizeMultiplier = 1.4;
    }

    final adjustedPadding = base * deviceSizeMultiplier;
    return EdgeInsets.all(adjustedPadding);
  }

  /// Get appropriate horizontal and vertical padding based on device size
  static EdgeInsets getPaddingHV(
      BuildContext context, PaddingType horizontal, PaddingType vertical) {
    final deviceSize = getDeviceSize(context);

    // Base padding values (in logical pixels)
    double baseH, baseV;

    switch (horizontal) {
      case PaddingType.tiny:
        baseH = 4;
        break;
      case PaddingType.small:
        baseH = 8;
        break;
      case PaddingType.medium:
        baseH = 16;
        break;
      case PaddingType.large:
        baseH = 24;
        break;
      case PaddingType.xLarge:
        baseH = 32;
        break;
      case PaddingType.zero:
        baseH = 0;
        break;
    }

    switch (vertical) {
      case PaddingType.tiny:
        baseV = 4;
        break;
      case PaddingType.small:
        baseV = 8;
        break;
      case PaddingType.medium:
        baseV = 16;
        break;
      case PaddingType.large:
        baseV = 24;
        break;
      case PaddingType.xLarge:
        baseV = 32;
        break;
      case PaddingType.zero:
        baseV = 0;
        break;
    }

    // Apply device size adjustment
    double deviceSizeMultiplier = 1.0;
    if (deviceSize == DeviceSize.phoneXSmall) {
      deviceSizeMultiplier = 0.9;
    } else if (deviceSize == DeviceSize.tabletSmall) {
      deviceSizeMultiplier = 1.2;
    } else if (deviceSize == DeviceSize.tabletLarge) {
      deviceSizeMultiplier = 1.4;
    }

    final adjustedPaddingH = baseH * deviceSizeMultiplier;
    final adjustedPaddingV = baseV * deviceSizeMultiplier;

    return EdgeInsets.symmetric(
        horizontal: adjustedPaddingH, vertical: adjustedPaddingV);
  }

  /// Calculate a responsive card height that adapts to content
  static double getResponsiveCardHeight(BuildContext context,
      {double baseHeight = 80, bool isExpanded = false}) {
    final fontScale = MediaQuery.of(context).textScaler.scale(1.0);
    final deviceSize = getDeviceSize(context);

    // Base adjustment
    double heightMultiplier = 1.0;

    // Adjust for font scale (larger fonts need more space)
    if (fontScale > kFontScaleMedium) {
      heightMultiplier *=
          fontScale * 0.9; // Slightly compress to avoid excessive height
    } else if (fontScale > kFontScaleNormal) {
      heightMultiplier *= fontScale;
    }

    // Adjust for device size
    if (deviceSize == DeviceSize.phoneXSmall ||
        deviceSize == DeviceSize.phoneSmall) {
      heightMultiplier *= 0.9;
    } else if (deviceSize == DeviceSize.tabletSmall ||
        deviceSize == DeviceSize.tabletLarge) {
      heightMultiplier *= 1.1;
    }

    // Expanded state adjustment
    if (isExpanded) {
      heightMultiplier *= 1.5;
    }

    return baseHeight * heightMultiplier;
  }

  /// Get layout for tablets (one or two columns)
  static int getGridColumnCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < kTabletSmall) return 1;
    if (width < 1200) return 2;
    return 3;
  }
}

/// Enum to classify device sizes
enum DeviceSize {
  phoneXSmall, // Smallest phones
  phoneSmall, // Small phones (e.g., iPhone SE)
  phoneMedium, // Medium phones (e.g., iPhone 13/14)
  phoneLarge, // Large phones (e.g., iPhone Max, Galaxy S)
  tabletSmall, // Small tablets
  tabletLarge, // Large tablets
}

/// Enum to classify font scale factors
enum FontScale {
  normal, // Normal font scale (≤ 1.0)
  medium, // Medium font scale (1.0 < scale ≤ 1.25)
  large, // Large font scale (> 1.25)
}

/// Font size types
enum FontSizeType {
  tiny, // Very small text (labels, captions)
  small, // Small text (secondary info)
  medium, // Medium text (primary content)
  large, // Large text (headers, titles)
  xLarge, // Extra large text (main titles)
  xxLarge, // Double extra large text (page titles)
}

/// Icon size types
enum IconSizeType {
  tiny, // Very small icons
  small, // Small icons
  medium, // Medium icons (standard)
  large, // Large icons (featured)
  xLarge, // Extra large icons (hero)
}

/// Padding size types
enum PaddingType {
  tiny, // Minimal spacing
  small, // Small spacing
  medium, // Standard spacing
  large, // Wide spacing
  xLarge, // Extra wide spacing
  zero, // No spacing (new)
}

/// Widget to handle keyboard visibility
class KeyboardAware extends StatelessWidget {
  final Widget child;
  final bool autoscroll;
  final ScrollController? scrollController;

  const KeyboardAware({
    super.key,
    required this.child,
    this.autoscroll = true,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isKeyboardVisible = mediaQuery.viewInsets.bottom > 0;

    // If keyboard is visible and autoscroll is enabled, use SingleChildScrollView
    if (isKeyboardVisible && autoscroll) {
      return SingleChildScrollView(
        controller: scrollController,
        physics: const ClampingScrollPhysics(),
        child: Padding(
          // Add padding at the bottom to prevent content from being obscured by keyboard
          padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
          child: child,
        ),
      );
    }

    // Otherwise, just return the child
    return child;
  }
}

/// Extension methods for responsive text styles
extension ResponsiveTextExtension on BuildContext {
  
  TextStyle get tinyText => TextStyle(
        fontSize: ResponsiveUtils.getFontSize(this, FontSizeType.tiny),
      );

  TextStyle get smallText => TextStyle(
        fontSize: ResponsiveUtils.getFontSize(this, FontSizeType.small),
      );

  TextStyle get mediumText => TextStyle(
        fontSize: ResponsiveUtils.getFontSize(this, FontSizeType.medium),
      );

  TextStyle get largeText => TextStyle(
        fontSize: ResponsiveUtils.getFontSize(this, FontSizeType.large),
      );

  TextStyle get xLargeText => TextStyle(
        fontSize: ResponsiveUtils.getFontSize(this, FontSizeType.xLarge),
      );

  TextStyle get xxLargeText => TextStyle(
        fontSize: ResponsiveUtils.getFontSize(this, FontSizeType.xxLarge),
      );

  // With colors
  TextStyle tinyTextColor(Color color) => tinyText.copyWith(color: color);
  TextStyle smallTextColor(Color color) => smallText.copyWith(color: color);
  TextStyle mediumTextColor(Color color) => mediumText.copyWith(color: color);
  TextStyle largeTextColor(Color color) => largeText.copyWith(color: color);
  TextStyle xLargeTextColor(Color color) => xLargeText.copyWith(color: color);
  TextStyle xxLargeTextColor(Color color) => xxLargeText.copyWith(color: color);

  // With weight
  TextStyle tinyTextWeight(FontWeight weight) =>
      tinyText.copyWith(fontWeight: weight);
  TextStyle smallTextWeight(FontWeight weight) =>
      smallText.copyWith(fontWeight: weight);
  TextStyle mediumTextWeight(FontWeight weight) =>
      mediumText.copyWith(fontWeight: weight);
  TextStyle largeTextWeight(FontWeight weight) =>
      largeText.copyWith(fontWeight: weight);
  TextStyle xLargeTextWeight(FontWeight weight) =>
      xLargeText.copyWith(fontWeight: weight);
  TextStyle xxLargeTextWeight(FontWeight weight) =>
      xxLargeText.copyWith(fontWeight: weight);

  TextStyle getFontSize(BuildContext context, FontSizeType type) {
    return TextStyle(
      fontSize: ResponsiveUtils.getFontSize(context, type),
    );
  }

}
