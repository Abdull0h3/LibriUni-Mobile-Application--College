import 'package:flutter/material.dart';

/// Color palette for the LibriUni application based on the design specifications.
class AppColors {
  // Primary brand colors
  static const Color primary = Color(0xFF1A365D); // Navy Blue
  static const Color secondary = Color(0xFF0F1D2E); // Dark Navy
  static const Color accent = Color(0xFFEA4335); // Red

  // Secondary palette colors
  static const Color green = Color(0xFF34A853); // Green
  static const Color yellow = Color(0xFFF4B400); // Yellow
  static const Color white = Color(0xFFFFFFFF); // White
  static const Color lightGray = Color(0xFFE0E0E0); // Light Gray

  // Text colors
  static const Color textPrimary = Color(0xFF0F1D2E); // Dark Navy
  static const Color textSecondary = Color(0xFF666666); // Medium Gray
  static const Color textLight = Color(0xFFFFFFFF); // White

  // Status colors
  static const Color success = Color(0xFF34A853); // Green
  static const Color error = Color(0xFFEA4335); // Red
  static const Color warning = Color(0xFFF4B400); // Yellow
  static const Color info = Color(0xFF1A365D); // Navy Blue

  // Background colors
  static const Color background = Color(0xFFFFFFFF); // White
  static const Color cardBackground = Color(0xFFE0E0E0); // Light Gray
  static const Color disabledBackground = Color(0xFFE0E0E0); // Light Gray

  // Dark mode specific colors
  static const Color darkBackground = Color(0xFF121212); // Dark background
  static const Color darkCardBackground = Color(0xFF1E1E1E); // Dark card background
  static const Color darkSurface = Color(0xFF1E1E1E); // Dark surface color
  static const Color darkDivider = Color(0xFF333333); // Dark divider color
  static const Color darkTextPrimary = Color(0xFFFFFFFF); // Dark mode primary text
  static const Color darkTextSecondary = Color(0xFFB3B3B3); // Dark mode secondary text
  static const Color darkIconColor = Color(0xFFFFFFFF); // Dark mode icon color
  static const Color darkSelectedItemColor = Color(0xFFF4B400); // Dark mode selected item color
  static const Color darkUnselectedItemColor = Color(0xFFB3B3B3); // Dark mode unselected item color

  // Navigation colors
  static const Color navBarBackground = Color(0xFFFFFFFF); // Light mode nav bar background
  static const Color darkNavBarBackground = Color(0xFF1E1E1E); // Dark mode nav bar background
  static const Color navBarSelectedItem = Color(0xFF1A365D); // Light mode selected item
  static const Color navBarUnselectedItem = Color(0xFF666666); // Light mode unselected item

  // Input field colors
  static const Color inputBackground = Color(0xFFFFFFFF); // Light mode input background
  static const Color darkInputBackground = Color(0xFF1E1E1E); // Dark mode input background
  static const Color inputBorder = Color(0xFFE0E0E0); // Light mode input border
  static const Color darkInputBorder = Color(0xFF333333); // Dark mode input border

  // Card colors
  static const Color cardBorder = Color(0xFFE0E0E0); // Light mode card border
  static const Color darkCardBorder = Color(0xFF333333); // Dark mode card border

  // Legacy colors (kept for backward compatibility)
  static const Color primaryColor = Color(0xFF1A365D); // Dark Blue
  static const Color secondaryColor = Color(0xFFF4B400); // Yellow
  static const Color backgroundColor = Color(0xFFE0E0E0); // Light Grey
  static const Color cardBackgroundColor = Color(0xFFFFFFFF); // White
  static const Color textColorDark = Color(0xFF0F1D2E); // Very Dark Blue/Black
  static const Color textColorLight = Color(0xFFFFFFFF); // White
  static const Color successColor = Color(0xFF34A853); // Green
  static const Color dangerColor = Color(0xFFEA4335); // Red

  // Helper method to get appropriate text color based on background
  static Color getTextColorForBackground(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5 ? textPrimary : textLight;
  }

  // Helper method to get appropriate icon color based on background
  static Color getIconColorForBackground(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5 ? textPrimary : textLight;
  }
}

class AppConstants {
  // Placeholder for your logo asset path
  static const String libriUniLogoPath = 'assets/libriuni_logo_combination.png';
}