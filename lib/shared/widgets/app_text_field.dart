import 'package:flutter/material.dart';
import 'package:toukh_provider/shared/icons/toukh_icons.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../theme/app_sizes.dart';

/// Standard filled text field: use this (or [AppPasswordField] / [AppPhoneField])
/// instead of raw [TextFormField].
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.formFieldKey,
    this.height,
    this.prefix,
    this.prefixIcon,
    this.prefixIconConstraints,
    this.prefixText,
    this.underFieldWidget,
    this.controller,
    this.hintText,
    this.hint,
    this.maxLines,
    this.maxLength,
    this.radius,
    this.labelText,
    this.label,
    this.suffixText,
    this.suffix,
    this.suffixIcon,
    this.suffixIconConstraints,
    this.textColor,
    this.backgroundColor,
    this.errorText,
    this.readOnly = false,
    this.readonly = false,
    this.initialValue,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.onEditingComplete,
    this.onSaved,
    this.onTap,
    this.enabled,
    this.obscureText = false,
    this.inputDecoration,
    this.margin,
    this.contentPadding,
    this.labelStyle,
    this.hintStyle,
    this.textStyle,
    this.focusNode,
    this.autoDirection = false,
    this.textDirection,
    this.inputFormatters,
    this.autofillHints,
    this.leadingIcon,
    this.unfocusOnTapOutside = true,
  });

  final Key? formFieldKey;

  final double? height;
  final Widget? prefix;
  final Widget? prefixIcon;
  final BoxConstraints? prefixIconConstraints;
  final String? prefixText;
  final Widget? underFieldWidget;

  final TextEditingController? controller;
  final String? hintText;
  final String? hint;
  final int? maxLines;
  final int? maxLength;
  final double? radius;
  final String? labelText;
  final String? label;
  final String? suffixText;
  final Widget? suffix;
  final Widget? suffixIcon;
  final BoxConstraints? suffixIconConstraints;
  final Color? textColor;
  final Color? backgroundColor;
  final String? errorText;
  final bool readOnly;
  /// Alias for [readOnly] (compat with older Toukh consumer code).
  final bool readonly;
  final String? initialValue;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final VoidCallback? onEditingComplete;
  final FormFieldSetter<String>? onSaved;
  final VoidCallback? onTap;
  final bool? enabled;
  final bool obscureText;
  final InputDecoration? inputDecoration;
  final EdgeInsetsGeometry? margin;
  final EdgeInsets? contentPadding;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final TextStyle? textStyle;
  final FocusNode? focusNode;
  final bool autoDirection;
  final TextDirection? textDirection;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;

  final IconData? leadingIcon;

  /// When true, tapping outside the field removes focus (keyboard dismiss).
  final bool unfocusOnTapOutside;

  bool get _effectiveReadOnly => readOnly || readonly;

  TextDirection? _effectiveTextDirection(BuildContext context) {
    if (textDirection != null) return textDirection;
    if (autoDirection) {
      return Directionality.of(context);
    }
    return null;
  }

  InputDecoration _buildDecoration(
    BuildContext context,
    ColorScheme scheme, {
    required double borderR,
  }) {
    final effectiveLabel = labelText ?? label;
    final effectiveHint = hintText ?? hint;
    final fill = backgroundColor ?? AppColors.fieldFill(context);

    final prefixIconWidget =
        prefixIcon ??
        (leadingIcon != null
            ? Icon(
                leadingIcon,
                size: AppSizes.iconMd,
                color: AppColors.secondColor.withValues(alpha: 0.85),
              )
            : null);

    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: fill,
      labelText: effectiveLabel?.tr,
      hintText: effectiveHint?.tr,
      errorText: errorText?.tr,
      prefix: prefix,
      prefixIcon: prefixIconWidget,
      prefixText: prefixText,
      suffix: suffix,
      suffixIcon: suffixIcon ?? suffix,
      suffixText: suffixText?.tr,
      labelStyle:
          labelStyle ??
          TextStyle(
            fontFamily: AppFonts.family,
            fontSize: AppSizes.fontLabel,
            color: scheme.onSurface.withValues(alpha: 0.65),
            fontWeight: FontWeight.w500,
          ),
      hintStyle:
          hintStyle ??
          TextStyle(
            fontFamily: AppFonts.family,
            fontSize: AppSizes.fontBody,
            color: scheme.onSurface.withValues(alpha: 0.4),
          ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderR),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderR),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderR),
        borderSide: const BorderSide(color: AppColors.appColor, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderR),
        borderSide: BorderSide(color: scheme.error.withValues(alpha: 0.8), width: 0.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderR),
        borderSide: BorderSide(color: scheme.error, width: 1),
      ),
      contentPadding:
          contentPadding ??
          const EdgeInsets.symmetric(
            horizontal: AppSizes.spaceBase,
            vertical: AppSizes.spaceBase,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderR = radius ?? AppSizes.radiusMd;

    assert(
      (controller != null) != (initialValue != null),
      'AppTextField: pass exactly one of controller or initialValue',
    );

    final defaultStyle = TextStyle(
      fontFamily: AppFonts.family,
      fontSize: AppSizes.fontBody,
      color: textColor ?? scheme.onSurface,
      fontWeight: FontWeight.w500,
    );
    final mergedStyle = textStyle == null
        ? defaultStyle
        : defaultStyle.merge(textStyle);

    InputDecoration dec = inputDecoration != null
        ? inputDecoration!
        : _buildDecoration(context, scheme, borderR: borderR);
    if (errorText != null) {
      dec = dec.copyWith(errorText: errorText!.tr);
    }
    if (contentPadding != null) {
      dec = dec.copyWith(contentPadding: contentPadding);
    }
    if (prefixIconConstraints != null) {
      dec = dec.copyWith(prefixIconConstraints: prefixIconConstraints);
    }
    if (suffixIconConstraints != null) {
      dec = dec.copyWith(suffixIconConstraints: suffixIconConstraints);
    }

    final effectiveMaxLines = obscureText ? 1 : maxLines;

    final field = TextFormField(
      key: formFieldKey,
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      enabled: enabled ?? true,
      maxLines: effectiveMaxLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator == null ? null : (value) => validator!(value)?.tr,
      readOnly: _effectiveReadOnly,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      onEditingComplete: onEditingComplete,
      onSaved: onSaved,
      onTap: onTap,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      autofillHints: autofillHints,
      focusNode: focusNode,
      obscureText: obscureText,
      style: mergedStyle,
      textDirection: _effectiveTextDirection(context),
      decoration: dec,
      onTapOutside: unfocusOnTapOutside
          ? (_) => FocusScope.of(context).unfocus()
          : null,
    );

    final column = underFieldWidget == null
        ? field
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [field, underFieldWidget!],
          );

    Widget out = height != null
        ? SizedBox(
            height: height,
            child: Align(alignment: Alignment.topCenter, child: column),
          )
        : column;

    if (margin != null) {
      out = Padding(padding: margin!, child: out);
    }

    return out;
  }
}

/// Filled password field with visibility toggle suffix.
class AppPasswordField extends StatefulWidget {
  const AppPasswordField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.hint,
    this.validator,
    this.textInputAction = TextInputAction.done,
    this.autofillHints = const [AutofillHints.password],
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final Iterable<String> autofillHints;

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: AppTextField(
        controller: widget.controller,
        label: widget.label,
        hint: widget.hint,
        obscureText: _obscure,
        keyboardType: TextInputType.visiblePassword,
        textInputAction: widget.textInputAction,
        validator: widget.validator,
        autofillHints: widget.autofillHints,
        leadingIcon: ToukhIcons.lock,
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(
            _obscure ? ToukhIcons.visibility : ToukhIcons.visibilityOff,
            size: AppSizes.iconMd,
            color: AppColors.secondColor.withValues(alpha: 0.75),
          ),
          tooltip: _obscure ? 'Show password' : 'Hide password',
        ),
      ),
    );
  }
}
