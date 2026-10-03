import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class QcTheme {
  // Core Dark Theme Palette (matching exact design in screenshots)
  static const Color bg = Color(0xFF12100E);
  static const Color surface = Color(0xFF1A1714);
  static const Color surfaceSunken = Color(0xFF221E1B);
  static const Color cardBg = Color(0xFF1A1715);
  static const Color border = Color(0xFF2C2723);
  static const Color borderSubtle = Color(0xFF24201D);
  static const Color borderLight = Color(0xFF38312B);

  // Amber / Gold Accent Colors
  static const Color primary = Color(0xFFC48A36);
  static const Color primaryLight = Color(0x26C48A36);
  static const Color primaryHover = Color(0xFFD97706);
  static const Color gold = Color(0xFFE8A849);

  // Typography Colors
  static const Color textMain = Color(0xFFFAF8F5);
  static const Color textMuted = Color(0xFFA8A29E);
  static const Color textSubtle = Color(0xFF78716C);

  // Status & Utility Colors
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0x2610B981);
  static const Color successBorder = Color(0x5910B981);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0x26F59E0B);
  static const Color warningBorder = Color(0x59F59E0B);

  static const Color danger = Color(0xFFEF4444);
  static const Color dangerBg = Color(0x26EF4444);
  static const Color dangerBorder = Color(0x59EF4444);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoBg = Color(0x263B82F6);

  // Category Badges Colors
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'design':
        return const Color(0xFFC48A36);
      case 'labor':
        return const Color(0xFF0EA5E9);
      case 'materials':
        return const Color(0xFF22C55E);
      case 'furniture':
        return const Color(0xFFF59E0B);
      case 'carpentry':
        return const Color(0xFFA855F7);
      case 'electrical':
        return const Color(0xFFEAB308);
      case 'painting':
        return const Color(0xFF6366F1);
      case 'plumbing':
        return const Color(0xFF14B8A6);
      case 'textiles':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFFA8A29E);
    }
  }

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFC48A36), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Font Styles
  static TextStyle serifTitle({double fontSize = 28, FontWeight fontWeight = FontWeight.w700, Color color = textMain}) {
    return GoogleFonts.playfairDisplay(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: -0.5,
    );
  }

  static TextStyle sansBody({double fontSize = 14, FontWeight fontWeight = FontWeight.w400, Color color = textMuted}) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static TextStyle money({double fontSize = 16, FontWeight fontWeight = FontWeight.w700, Color color = textMain}) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  // Helper formatting methods
  static String formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return 'LKR ${formatter.format(amount)}';
  }

  static String formatDate(DateTime? date, {bool short = false}) {
    if (date == null) return '—';
    if (short) {
      return DateFormat('MMM d').format(date);
    }
    return DateFormat('MMM d, yyyy').format(date);
  }
}
