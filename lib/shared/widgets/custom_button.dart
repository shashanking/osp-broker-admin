import 'package:flutter/material.dart';
import 'package:osp_broker_admin/core/theme/app_colors.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isFullWidth;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double borderRadius;
  final bool isLoading;
  final bool disabled;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isFullWidth = false,
    this.padding,
    this.width,
    this.height = 48,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius = 8,
    this.isLoading = false,
    this.disabled = false,
  });

  const CustomButton.primary({
    super.key,
    required this.onPressed,
    required this.child,
    this.isFullWidth = true,
    this.padding,
    this.width,
    this.height = 48,
    this.backgroundColor = AppColors.primary,
    this.foregroundColor = Colors.white,
    this.borderRadius = 8,
    this.isLoading = false,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: (disabled || isLoading) ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
        foregroundColor: foregroundColor ?? Colors.white,
        padding: padding ?? const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        minimumSize: Size(
          isFullWidth ? double.infinity : 0,
          height!,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: isLoading
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: foregroundColor ?? Colors.white,
                strokeWidth: 2,
              ),
            )
          : child,
    );

    if (width != null) {
      return SizedBox(
        width: width,
        height: height,
        child: button,
      );
    }

    return button;
  }
}
