import 'dart:ui';
import 'package:flutter/material.dart';

/// Single source of truth for colors, typography, and reusable "glass"
/// containers. Preserved verbatim from the original theme.dart so the
/// existing visual identity carries forward through the refactor.
class AppColors {
  static const Color backgroundStart = Color(0xFF0F172A); // Slate dark
  static const Color backgroundEnd = Color(0xFF181B34); // Deep indigo slate

  // Therapeutic Palette
  static const Color primary = Color(0xFF00BFA5); // Therapeutic Teal
  static const Color sage = Color(0xFFA7F3D0); // Soft Sage
  static const Color lavender = Color(0xFFC4B5FD); // Soft Lavender
  static const Color amber = Color(0xFFFDE047); // Warm Sunshine Amber
  static const Color coral = Color(0xFFF87171); // Soft Coral

  // Telemetry metric colors
  static const Color sleep = Color(0xFF818CF8); // Soft Indigo Blue
  static const Color steps = Color(0xFF34D399); // Emerald Mint
  static const Color calendar = Color(0xFFFBBF24); // Warm Amber
  static const Color weatherRain = Color(0xFF38BDF8); // Sky Blue
  static const Color weatherStorm = Color(0xFFFB7185); // Soft Rose

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color borderTranslucent = Color(0x1EFFFFFF);
  static const Color glassBackground = Color(0x10FFFFFF);
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BoxBorder? border;
  final Color? color;
  final List<BoxShadow>? boxShadow;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 16.0,
    this.borderRadius = 16.0,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.border,
    this.color,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                spreadRadius: -4,
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color ?? AppColors.glassBackground,
              borderRadius: BorderRadius.circular(borderRadius),
              border: border ??
                  Border.all(
                    color: AppColors.borderTranslucent,
                    width: 1.0,
                  ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class GlassButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color? glowColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const GlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.glowColor,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: glowColor != null
            ? [
                BoxShadow(
                  color: glowColor!.withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: GlassContainer(
            padding: padding,
            borderRadius: borderRadius,
            color: AppColors.glassBackground.withValues(alpha: 0.12),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

ThemeData getDarkSeenTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.backgroundStart,
    primaryColor: AppColors.primary,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.sage,
      surface: AppColors.backgroundEnd,
    ),
    fontFamily: 'Inter',
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
          fontSize: 32.0,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.5),
      headlineMedium: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: -0.5),
      titleLarge: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary),
      titleMedium: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary),
      bodyLarge: TextStyle(
          fontSize: 16.0, color: AppColors.textPrimary, height: 1.4),
      bodyMedium: TextStyle(
          fontSize: 14.0, color: AppColors.textSecondary, height: 1.4),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
  );
}
