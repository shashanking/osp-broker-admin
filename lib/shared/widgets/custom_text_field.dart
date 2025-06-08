import 'package:flutter/material.dart';
import 'package:osp_broker_admin/core/theme/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? initialValue;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String?)? onSaved;
  final void Function()? onTap;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Widget? prefix;
  final Widget? suffix;
  final String? prefixText;
  final String? suffixText;
  final String? errorText;
  final String? helperText;
  final EdgeInsetsGeometry? contentPadding;
  final InputBorder? border;
  final InputBorder? enabledBorder;
  final InputBorder? focusedBorder;
  final InputBorder? errorBorder;
  final InputBorder? focusedErrorBorder;
  final Color? fillColor;
  final bool filled;
  final double borderRadius;
  final double? width;
  final double? height;
  final TextCapitalization textCapitalization;
  final FocusNode? focusNode;
  final TextAlign textAlign;

  const CustomTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.initialValue,
    this.validator,
    this.onChanged,
    this.onSaved,
    this.onTap,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.prefix,
    this.suffix,
    this.prefixText,
    this.suffixText,
    this.errorText,
    this.helperText,
    this.contentPadding,
    this.border,
    this.enabledBorder,
    this.focusedBorder,
    this.errorBorder,
    this.focusedErrorBorder,
    this.fillColor = Colors.transparent,
    this.filled = true,
    this.borderRadius = 8.0,
    this.width,
    this.height,
    this.textCapitalization = TextCapitalization.none,
    this.focusNode,
    this.textAlign = TextAlign.start,
  });

  const CustomTextField.outlined({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.initialValue,
    this.validator,
    this.onChanged,
    this.onSaved,
    this.onTap,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.prefix,
    this.suffix,
    this.prefixText,
    this.suffixText,
    this.errorText,
    this.helperText,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.border = const OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.border),
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    this.enabledBorder = const OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.border),
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    this.focusedBorder = const OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    this.errorBorder = const OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.error),
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    this.focusedErrorBorder = const OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.error, width: 1.5),
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    this.fillColor = Colors.transparent,
    this.filled = true,
    this.borderRadius = 8.0,
    this.width,
    this.height,
    this.textCapitalization = TextCapitalization.none,
    this.focusNode,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      hintText: hintText,
      labelText: labelText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      prefix: prefix,
      suffix: suffix,
      prefixText: prefixText,
      suffixText: suffixText,
      errorText: errorText,
      helperText: helperText,
      contentPadding: contentPadding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: border ??
          OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide.none,
          ),
      enabledBorder: enabledBorder ??
          OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: AppColors.border),
          ),
      focusedBorder: focusedBorder ??
          OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
      errorBorder: errorBorder ??
          OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: const BorderSide(color: AppColors.error),
          ),
      focusedErrorBorder: focusedErrorBorder ??
          OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
      fillColor: fillColor,
      filled: filled,
    );

    final textField = TextFormField(
      controller: controller,
      initialValue: initialValue,
      validator: validator,
      onChanged: onChanged,
      onSaved: onSaved,
      onTap: onTap,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      autofocus: autofocus,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      focusNode: focusNode,
      textAlign: textAlign,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: enabled ? null : AppColors.textDisabled,
          ),
      decoration: inputDecoration,
    );

    if (width != null || height != null) {
      return SizedBox(
        width: width,
        height: height,
        child: textField,
      );
    }

    return textField;
  }
}
