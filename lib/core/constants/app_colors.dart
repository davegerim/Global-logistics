import 'package:flutter/material.dart';

/// Global Logistics PLC — refined teal + warm gold on soft, airy surfaces.
abstract final class AppColors {
  static const Color primary = Color(0xFF0E4A42);
  static const Color primaryLight = Color(0xFF1A6B5F);
  static const Color primaryDark = Color(0xFF083932);
  static const Color primarySoft = Color(0xFFE8F2F0);

  static const Color gold = Color(0xFFC4A24A);
  static const Color goldMuted = Color(0xFFD4BC6A);
  static const Color goldLight = Color(0xFFF5F0E3);
  static const Color goldGlow = Color(0x33C4A24A);

  /// Warm off-white — less sterile than pure grey.
  static const Color background = Color(0xFFF8FAF9);
  static const Color backgroundWarm = Color(0xFFF4F6F5);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F4F3);
  static const Color surfaceHighlight = Color(0xFFFAFCFB);

  static const Color textPrimary = Color(0xFF15201E);
  static const Color textSecondary = Color(0xFF5C6B68);
  static const Color textTertiary = Color(0xFF8A9794);

  static const Color border = Color(0xFFE2E8E6);
  static const Color borderLight = Color(0xFFEDF2F0);

  static const Color success = Color(0xFF0D9488);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);

  static const List<Color> splashGradient = [
    Color(0xFF062E29),
    Color(0xFF0E4A42),
    Color(0xFF135C52),
  ];

  static const List<Color> heroCardGradient = [
    Color(0xFF0E4A42),
    Color(0xFF0A5C52),
  ];
}
