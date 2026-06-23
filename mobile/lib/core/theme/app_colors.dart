import 'package:flutter/material.dart';

/// Brand palette for the Dr.Plus client. A calm medical blue paired with a
/// teal accent, on soft neutral surfaces.
abstract final class AppColors {
  static const Color primary = Color(0xFF1666F2);
  static const Color primaryDark = Color(0xFF0B4FCB);
  static const Color accent = Color(0xFF14C2A3);

  static const Color background = Color(0xFFF4F6FB);
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFEEF2FA);

  static const Color textPrimary = Color(0xFF101828);
  static const Color textSecondary = Color(0xFF667085);
  static const Color textTertiary = Color(0xFF98A2B3);

  static const Color border = Color(0xFFE4E7EC);
  static const Color danger = Color(0xFFE5484D);
  static const Color success = Color(0xFF12B76A);
  static const Color star = Color(0xFFF5A623);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF1A73F2), Color(0xFF14C2A3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x14101828),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0D101828),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];
}
