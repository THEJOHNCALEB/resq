import 'app_icon.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class CalmButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isEmergency;
  final bool isFullWidth;
  final bool isLoading;
  final double? height;

  const CalmButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isPrimary = true,
    this.isEmergency = false,
    this.isFullWidth = false,
    this.isLoading = false,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveHeight = height ?? 56.0;

    if (isEmergency) {
      return SizedBox(
        height: effectiveHeight,
        width: isFullWidth ? double.infinity : null,
        child: FilledButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onError,
                  ),
                )
              : AppIcon(icon ?? Icons.warning_rounded),
          label: Text(label),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.emergency,
            foregroundColor: AppColors.onError,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32),
          ),
        ),
      );
    }

    if (isPrimary) {
      return SizedBox(
        height: effectiveHeight,
        width: isFullWidth ? double.infinity : null,
        child: FilledButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.onPrimary,
                  ),
                )
              : icon != null
                  ? AppIcon(icon)
                  : null,
          label: Text(label),
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: effectiveHeight,
      width: isFullWidth ? double.infinity : null,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              )
            : icon != null
                ? AppIcon(icon)
                : null,
        label: Text(label),
      ),
    );
  }
}
