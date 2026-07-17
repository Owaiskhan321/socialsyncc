import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

enum AppBtnVariant { primary, secondary, outline, ghost, danger }
enum AppBtnSize { sm, md, lg }

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppBtnVariant.primary,
    this.size = AppBtnSize.lg,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppBtnVariant variant;
  final AppBtnSize size;
  final IconData? icon;
  final bool loading;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final pad = switch (widget.size) {
      AppBtnSize.sm => const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      AppBtnSize.md => const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      AppBtnSize.lg => const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    };
    final fontSize = widget.size == AppBtnSize.lg ? 16.0 : 14.0;

    final (bg, fg, border) = switch (widget.variant) {
      AppBtnVariant.primary => (AppColors.primary, AppColors.white, null),
      AppBtnVariant.secondary => (AppColors.gray100, AppColors.gray800, null),
      AppBtnVariant.outline => (Colors.transparent, AppColors.primary, AppColors.primary),
      AppBtnVariant.ghost => (Colors.transparent, AppColors.primary, null),
      AppBtnVariant.danger => (AppColors.red50, AppColors.danger, null),
    };

    final enabled = widget.onPressed != null && !widget.loading;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              HapticFeedback.lightImpact();
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1,
        duration: const Duration(milliseconds: 100),
        child: AnimatedOpacity(
          opacity: enabled || widget.loading ? 1 : 0.55,
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: widget.size == AppBtnSize.lg ? double.infinity : null,
            padding: pad,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: border != null ? Border.all(color: border, width: 2) : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: widget.size == AppBtnSize.lg ? MainAxisSize.max : MainAxisSize.min,
              children: [
                if (widget.loading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(fg),
                    ),
                  )
                else ...[
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 16, color: fg),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: fg,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
