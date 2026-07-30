import 'package:flutter/material.dart';

/// Single source of truth for colors, typography, and reusable containers
/// for the warm, light editorial theme (matches the Figma "Make" redesign).
///
/// Colors and fonts (DMSans body, Lora display) match the exact values a
/// teammate pulled from the same Figma export on a separate branch — ported
/// here so both halves of the app agree on one design language.
class AppColors {
  static const Color background = Color(0xFFF3F1F8);
  static const Color cardCool = Color(
    0xFFEDE9F5,
  ); // lavender stat-glimpse cards
  static const Color cardWarm = Color(
    0xFFFAF7F2,
  ); // cream reflection/edit cards

  static const Color primary = Color(0xFF7B6A9E); // purple — buttons, accents

  static const Color textPrimary = Color(0xFF2A2733);
  static const Color textSecondary = Color(0xFF8A849A);

  static const Color divider = Color(0x1A2A2733);
  static const Color white = Color(0xFFFDFBFF);

  // Telemetry metric colors (kept distinct per signal category)
  static const Color sleep = Color(0xFF8177C9);
  static const Color steps = Color(0xFF4CA37E);
  static const Color calendar = Color(0xFFCB8A3E);
  static const Color weatherRain = Color(0xFF4C8FBF);
  static const Color weatherSun = Color(0xFFCB8A3E);
}

/// Opaque rounded card — the light-theme replacement for the old
/// frosted-glass-over-dark `GlassContainer`.
class SoftCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BoxBorder? border;

  const SoftCard({
    super.key,
    required this.child,
    this.color = AppColors.cardCool,
    this.borderRadius = 20.0,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Pill-shaped primary action button (purple, bold white label) — matches
/// "Explore my day" / "Enter the scene" / "Save reflection" throughout the
/// Figma flow.
class PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool expand;

  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final child = Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(100),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 8),
                Icon(icon, color: Colors.white, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: child) : child;
  }
}

/// Secondary (text-only) action, e.g. "Go back to my moments".
class SecondaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;

  const SecondaryButton({
    super.key,
    required this.onPressed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }
}

ThemeData getLightSeenTheme() {
  return ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.primary,
    fontFamily: 'DMSans',
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.cardCool,
      surface: AppColors.background,
    ),
    textTheme: TextTheme(
      displayLarge: const TextStyle(
        fontFamily: 'Lora',
        fontSize: 34.0,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        fontStyle: FontStyle.italic,
      ),
      headlineLarge: const TextStyle(
        fontFamily: 'Lora',
        fontSize: 28.0,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      headlineMedium: const TextStyle(
        fontFamily: 'Lora',
        fontSize: 22.0,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleLarge: const TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleMedium: const TextStyle(
        fontSize: 15.0,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyLarge: const TextStyle(
        fontSize: 16.0,
        color: AppColors.textPrimary,
        height: 1.5,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14.0,
        color: AppColors.textSecondary,
        height: 1.45,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.background,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.background,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
    ),
    dividerColor: AppColors.divider,
  );
}
