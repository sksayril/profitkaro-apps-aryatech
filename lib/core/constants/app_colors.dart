import 'package:flutter/material.dart';

class AppColors {
  // Dark theme colors
  static const Color darkBackground = Color(0xFF0D0D1A);
  static const Color darkCardBackground = Color(0xFF1A1A2E);
  static const Color darkCardBackgroundLight = Color(0xFF2A2A3E);
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFF9E9E9E);
  static const Color darkBorder = Color(0xFF2A2A3E);
  static const Color darkBorderLight = Color(0xFF3A3A5A);
  
  // Light theme colors
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightCardBackground = Color(0xFFFFFFFF);
  static const Color lightCardBackgroundLight = Color(0xFFF9F9F9);
  static const Color lightTextPrimary = Colors.black; // Pure black for better visibility
  static const Color lightTextSecondary = Color(0xFF4A4A4A); // Darker grey for better contrast
  static const Color lightBorder = Color(0xFFE0E0E0);
  static const Color lightBorderLight = Color(0xFFD0D0D0);
  
  // Primary colors (same for both themes)
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFF4A90D9);
  
  // Secondary colors
  static const Color secondary = Color(0xFF4CAF50);
  static const Color green = Color(0xFF4ADE80);
  
  // Accent colors
  static const Color orange = Color(0xFFFF9800);
  static const Color purple = Color(0xFF9C27B0);
  static const Color pink = Color(0xFFE91E63);
  static const Color yellow = Color(0xFFFFEB3B);
  static const Color teal = Color(0xFF26A69A);
  static const Color cyan = Color(0xFF4DD0E1);
  static const Color amber = Color(0xFFFFC107);
  
  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4A90D9), Color(0xFF2563EB)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
  );
  
  // Icon background colors (same for both themes)
  static const Color iconBgBlue = Color(0xFF1E3A5F);
  static const Color iconBgOrange = Color(0xFF3D2A1A);
  static const Color iconBgPurple = Color(0xFF2A1A3D);
  static const Color iconBgPink = Color(0xFF3D1A2A);
  static const Color iconBgYellow = Color(0xFF3D3A1A);
  static const Color iconBgTeal = Color(0xFF1A3D3A);
  
  // Theme-aware getters (for backward compatibility)
  static Color background(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackground
        : lightBackground;
  }
  
  static Color cardBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCardBackground
        : lightCardBackground;
  }
  
  static Color textPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextPrimary
        : lightTextPrimary;
  }
  
  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextSecondary
        : lightTextSecondary;
  }
  
  static Color border(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBorder
        : lightBorder;
  }
  
  static Color cardBackgroundLight(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCardBackgroundLight
        : lightCardBackgroundLight;
  }
  
  static Color borderLight(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBorderLight
        : lightBorderLight;
  }
  
  // Shadow colors for cards
  static Color cardShadowColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.black.withOpacity(0.3)
        : Colors.black.withOpacity(0.15); // Black shadow for light mode
  }
  
  // Get shadow for cards based on theme
  static List<BoxShadow> cardShadow(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    } else {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 8,
          offset: const Offset(0, 2),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 4,
          offset: const Offset(0, 1),
          spreadRadius: 0,
        ),
      ];
    }
  }
}
