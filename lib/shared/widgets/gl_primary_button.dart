import 'package:flutter/material.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';

class GlPrimaryButton extends StatelessWidget {
  const GlPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.useGoldAccent = false,
    this.showShadow = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool useGoldAccent;

  /// When false, no outer [BoxShadow] is drawn (button still uses [FilledButton] with elevation 0).
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final bg = useGoldAccent ? AppColors.gold : AppColors.primary;
    final fg = useGoldAccent ? AppColors.textPrimary : Colors.white;
    final shadow = useGoldAccent
        ? AppColors.gold.withValues(alpha: 0.35)
        : AppColors.primary.withValues(alpha: 0.4);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: !showShadow || onPressed == null || isLoading
            ? null
            : [
                BoxShadow(
                  color: shadow,
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            disabledBackgroundColor: bg.withValues(alpha: 0.5),
            elevation: 0,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: isLoading
              ? SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 22),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
