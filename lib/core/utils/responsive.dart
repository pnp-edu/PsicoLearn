import 'package:flutter/material.dart';

class Responsive {
  Responsive._();

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;
  static bool isSmallMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 360;
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1024;
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  static double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;
  static double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;

  static double horizontalPadding(BuildContext context) {
    if (isDesktop(context)) return 40.0;
    if (isTablet(context)) return 28.0;
    if (isSmallMobile(context)) return 12.0;
    return 18.0;
  }

  static double verticalPadding(BuildContext context) {
    if (isDesktop(context)) return 28.0;
    if (isTablet(context)) return 22.0;
    return 18.0;
  }

  static double scaleFactor(BuildContext context) {
    final width = screenWidth(context);
    if (width > 600) return 1.0;
    return (width / 375.0).clamp(0.8, 1.0);
  }

  static double titleFontSize(
    BuildContext context, {
    double mobile = 24,
    double tablet = 32,
    double desktop = 40,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile * scaleFactor(context);
  }

  static double subtitleFontSize(
    BuildContext context, {
    double mobile = 16,
    double tablet = 18,
    double desktop = 20,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile * scaleFactor(context);
  }
}
