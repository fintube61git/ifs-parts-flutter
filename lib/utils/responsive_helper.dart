import 'package:flutter/material.dart';
import 'constants.dart';

/// Helper class for responsive design decisions.
class ResponsiveHelper {
  /// Returns true if the screen width is mobile size.
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < AppConstants.mobileBreakpoint;
  }

  /// Returns true if the screen width is tablet size.
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= AppConstants.mobileBreakpoint && 
           width < AppConstants.desktopBreakpoint;
  }

  /// Returns true if the screen width is desktop size.
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= AppConstants.desktopBreakpoint;
  }

  /// Returns true if the screen width is wide desktop size.
  static bool isWideDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= AppConstants.wideDesktopBreakpoint;
  }

  /// Returns the appropriate padding based on screen size.
  static double getScreenPadding(BuildContext context) {
    if (isMobile(context)) {
      return AppConstants.smallPadding;
    } else if (isTablet(context)) {
      return AppConstants.defaultPadding;
    } else {
      return AppConstants.largePadding;
    }
  }

  /// Returns the number of columns for a grid based on screen width.
  static int getGridColumns(BuildContext context) {
    if (isMobile(context)) {
      return 1;
    } else if (isTablet(context)) {
      return 2;
    } else {
      return 3;
    }
  }

  /// Returns responsive font size scale.
  static double getFontScale(BuildContext context) {
    if (isMobile(context)) {
      return 0.9;
    } else if (isTablet(context)) {
      return 1.0;
    } else {
      return 1.1;
    }
  }

  /// Returns the device orientation.
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Returns the device orientation.
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }
}
