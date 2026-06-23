import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bonvo/config/themes/app_theme.dart';

enum AppButtonVariant { primary, dark, white }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final IconData? icon;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;

    late Decoration decoration;
    late Color textColor;

    switch (variant) {
      case AppButtonVariant.primary:
        decoration = BoxDecoration(
          gradient: disabled ? null : AppColors.gradient,
          color: disabled ? AppColors.textMuted : null,
          borderRadius: BorderRadius.circular(AppRadius.button),
          boxShadow: disabled ? [] : AppShadows.button,
        );
        textColor = Colors.white;
      case AppButtonVariant.dark:
        decoration = BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: BorderRadius.circular(AppRadius.button),
        );
        textColor = Colors.white;
      case AppButtonVariant.white:
        decoration = BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: AppColors.border),
        );
        textColor = AppColors.textPrimary;
    }

    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: decoration,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: InkWell(
            onTap: disabled ? null : onPressed,
            borderRadius: BorderRadius.circular(AppRadius.button),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: textColor),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: textColor, size: 18),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: GoogleFonts.plusJakartaSans(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
