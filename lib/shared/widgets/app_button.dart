import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../theme/app_sizes.dart';
import 'custom_text.dart';

/// Vertical and horizontal padding scale for [AppButtonSize].
enum AppButtonSize {
  small,
  medium,
  large,
}

/// Visual / interaction state. [AppButtonStatus.disabled] and [AppButtonStatus.loading]
/// block taps; other statuses allow taps when [onTap] or [onLongTap] is non-null.
enum AppButtonStatus {
  enabled,
  disabled,
  loading,
  error,
  success,
}

enum _AppButtonVariant { filled, outline, text }

class _AppButtonStyleSpec {
  const _AppButtonStyleSpec({
    required this.fontSize,
    required this.iconSize,
    required this.minHeight,
    required this.horizontalPadding,
    required this.verticalPadding,
  });

  final double fontSize;
  final double iconSize;
  final double minHeight;
  final double horizontalPadding;
  final double verticalPadding;

  static _AppButtonStyleSpec forSize(AppButtonSize size) {
    switch (size) {
      case AppButtonSize.small:
        return const _AppButtonStyleSpec(
          fontSize: AppSizes.fontCaption,
          iconSize: AppSizes.iconSm,
          minHeight: 40,
          horizontalPadding: AppSizes.spaceLg,
          verticalPadding: AppSizes.spaceSm,
        );
      case AppButtonSize.medium:
        return const _AppButtonStyleSpec(
          fontSize: AppSizes.fontLabel,
          iconSize: AppSizes.iconMd,
          minHeight: 44,
          horizontalPadding: AppSizes.space2xl,
          verticalPadding: AppSizes.spaceBase,
        );
      case AppButtonSize.large:
        return const _AppButtonStyleSpec(
          fontSize: AppSizes.fontBody,
          iconSize: AppSizes.iconLg,
          minHeight: 48,
          horizontalPadding: AppSizes.space2xl + AppSizes.spaceSm,
          verticalPadding: AppSizes.spaceMd,
        );
    }
  }
}

class _ResolvedAppButtonColors {
  const _ResolvedAppButtonColors({
    required this.background,
    required this.foreground,
    required this.border,
    required this.showBorder,
    required this.splash,
  });

  final Color background;
  final Color foreground;
  final Color border;
  final bool showBorder;
  final Color splash;
}

class _AppButtonCore extends StatelessWidget {
  const _AppButtonCore({
    required this.variant,
    required this.text,
    required this.size,
    required this.status,
    this.color,
    this.borderColor,
    this.icon,
    this.onTap,
    this.onLongTap,
    this.padding,
    this.width,
    this.height,
    this.underlineLabel = false,
    this.semanticsLabel,
    this.foregroundColor,
    this.trailingIcon,
    this.alignment,
  });

  final _AppButtonVariant variant;
  final String text;
  final AppButtonSize size;
  final AppButtonStatus status;
  final Color? color;
  final Color? borderColor;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback? onTap;
  final VoidCallback? onLongTap;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final bool underlineLabel;
  final String? semanticsLabel;
  final Color? foregroundColor;
  final MainAxisAlignment? alignment;

  bool get _interactive {
    if (status == AppButtonStatus.disabled || status == AppButtonStatus.loading) {
      return false;
    }
    return onTap != null || onLongTap != null;
  }

  String get _a11yLabel {
    if (semanticsLabel != null && semanticsLabel!.isNotEmpty) {
      return semanticsLabel!;
    }
    if (text.isNotEmpty) return text;
    return 'Button';
  }

  _ResolvedAppButtonColors _resolveColors(ColorScheme scheme) {
    switch (status) {
      case AppButtonStatus.disabled:
        final muted = scheme.onSurface.withValues(alpha: 0.38);
        final track = scheme.onSurface.withValues(alpha: 0.12);
        switch (variant) {
          case _AppButtonVariant.filled:
            return _ResolvedAppButtonColors(
              background: track,
              foreground: muted,
              border: Colors.transparent,
              showBorder: false,
              splash: muted.withValues(alpha: 0.12),
            );
          case _AppButtonVariant.outline:
            return _ResolvedAppButtonColors(
              background: Colors.transparent,
              foreground: muted,
              border: scheme.onSurface.withValues(alpha: 0.12),
              showBorder: true,
              splash: muted.withValues(alpha: 0.08),
            );
          case _AppButtonVariant.text:
            return _ResolvedAppButtonColors(
              background: Colors.transparent,
              foreground: muted,
              border: Colors.transparent,
              showBorder: false,
              splash: muted.withValues(alpha: 0.08),
            );
        }
      case AppButtonStatus.loading:
        return _resolveEnabled(scheme, loadingTint: true);
      case AppButtonStatus.error:
        return _resolveSemantic(
          scheme,
          fill: scheme.error,
          onFill: scheme.onError,
          strokeAndFg: scheme.error,
        );
      case AppButtonStatus.success:
        return _resolveSemantic(
          scheme,
          fill: AppColors.success,
          onFill: AppColors.surface,
          strokeAndFg: AppColors.success,
        );
      case AppButtonStatus.enabled:
        return _resolveEnabled(scheme);
    }
  }

  _ResolvedAppButtonColors _resolveEnabled(ColorScheme scheme, {bool loadingTint = false}) {
    final primary = color ?? scheme.primary;
    final onPrimary = scheme.onPrimary;

    switch (variant) {
      case _AppButtonVariant.filled:
        final bg = primary;
        final fg = foregroundColor ?? onPrimary;
        return _ResolvedAppButtonColors(
          background: loadingTint ? bg.withValues(alpha: 0.92) : bg,
          foreground: fg,
          border: Colors.transparent,
          showBorder: false,
          splash: fg.withValues(alpha: 0.14),
        );
      case _AppButtonVariant.outline:
        final stroke = borderColor ?? primary;
        final fg = foregroundColor ?? (color ?? primary);
        return _ResolvedAppButtonColors(
          background: Colors.transparent,
          foreground: fg,
          border: loadingTint ? stroke.withValues(alpha: 0.85) : stroke,
          showBorder: true,
          splash: primary.withValues(alpha: 0.10),
        );
      case _AppButtonVariant.text:
        final fg = foregroundColor ?? (color ?? primary);
        return _ResolvedAppButtonColors(
          background: Colors.transparent,
          foreground: fg,
          border: Colors.transparent,
          showBorder: false,
          splash: fg.withValues(alpha: 0.12),
        );
    }
  }

  _ResolvedAppButtonColors _resolveSemantic(
    ColorScheme scheme, {
    required Color fill,
    required Color onFill,
    required Color strokeAndFg,
  }) {
    switch (variant) {
      case _AppButtonVariant.filled:
        return _ResolvedAppButtonColors(
          background: fill,
          foreground: onFill,
          border: Colors.transparent,
          showBorder: false,
          splash: onFill.withValues(alpha: 0.14),
        );
      case _AppButtonVariant.outline:
        return _ResolvedAppButtonColors(
          background: Colors.transparent,
          foreground: strokeAndFg,
          border: borderColor ?? strokeAndFg,
          showBorder: true,
          splash: strokeAndFg.withValues(alpha: 0.10),
        );
      case _AppButtonVariant.text:
        return _ResolvedAppButtonColors(
          background: Colors.transparent,
          foreground: strokeAndFg,
          border: Colors.transparent,
          showBorder: false,
          splash: strokeAndFg.withValues(alpha: 0.12),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final spec = _AppButtonStyleSpec.forSize(size);
    final colors = _resolveColors(scheme);

    final defaultPadding = EdgeInsets.symmetric(
      horizontal: spec.horizontalPadding,
      vertical: spec.verticalPadding,
    );
    final effectivePadding = padding ?? defaultPadding;

    final borderSide = colors.showBorder
        ? BorderSide(color: colors.border, width: 1.5)
        : BorderSide.none;

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      side: borderSide,
    );

    final child = ConstrainedBox(
      constraints: BoxConstraints(minHeight: spec.minHeight),
      child: Padding(
        padding: effectivePadding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: alignment ?? MainAxisAlignment.center,
          children: [
            if (status == AppButtonStatus.loading) ...[
              SizedBox(
                width: spec.iconSize,
                height: spec.iconSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.foreground,
                ),
              ),
              if (text.isNotEmpty) SizedBox(width: AppSizes.spaceSm),
            ] else if (icon != null) ...[
              Icon(icon, size: spec.iconSize, color: colors.foreground),
              if (text.isNotEmpty) SizedBox(width: AppSizes.spaceSm),
            ],
            if (text.isNotEmpty)
              Flexible(
                child: CustomText(
                  text,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  fontSize: spec.fontSize,
                  fontWeight: FontWeight.w600,
                  color: colors.foreground,
                  textDecoration:
                      underlineLabel ? TextDecoration.underline : null,
                  style: const TextStyle(fontFamily: AppFonts.family),
                ),
              ),
            if (trailingIcon != null &&
                status != AppButtonStatus.loading) ...[
              if (text.isNotEmpty) SizedBox(width: AppSizes.spaceSm),
              Icon(
                trailingIcon,
                size: spec.iconSize,
                color: colors.foreground,
              ),
            ],
          ],
        ),
      ),
    );

    Widget material = Material(
      color: colors.background,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _interactive ? onTap : null,
        onLongPress: _interactive ? onLongTap : null,
        customBorder: shape,
        splashColor: colors.splash,
        highlightColor: colors.splash.withValues(alpha: 0.06),
        child: child,
      ),
    );

    if (width != null || height != null) {
      material = SizedBox(width: width, height: height, child: material);
    }

    return Semantics(
      button: true,
      enabled: _interactive,
      label: _a11yLabel,
      child: MergeSemantics(
        child: material,
      ),
    );
  }
}

/// Filled (primary-style) button. [color] sets the background when [status] is [AppButtonStatus.enabled] or [AppButtonStatus.loading].
class AppFilledButton extends StatelessWidget {
  const AppFilledButton({
    super.key,
    required this.text,
    this.size = AppButtonSize.medium,
    this.color,
    this.borderColor,
    this.icon,
    this.onTap,
    this.onLongTap,
    this.status = AppButtonStatus.enabled,
    this.padding,
    this.width,
    this.height,
    this.semanticsLabel,
    this.foregroundColor,
    this.trailingIcon,
  });

  final String text;
  final AppButtonSize size;
  final Color? color;
  final Color? borderColor;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback? onTap;
  final VoidCallback? onLongTap;
  final AppButtonStatus status;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final String? semanticsLabel;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return _AppButtonCore(
      variant: _AppButtonVariant.filled,
      text: text,
      size: size,
      status: status,
      color: color,
      borderColor: borderColor,
      icon: icon,
      trailingIcon: trailingIcon,
      onTap: onTap,
      onLongTap: onLongTap,
      padding: padding,
      width: width,
      height: height,
      semanticsLabel: semanticsLabel,
      foregroundColor: foregroundColor,
    );
  }
}

/// Outlined button. [color] drives label/icon; [borderColor] overrides the border when set.
class AppOutlinedButton extends StatelessWidget {
  const AppOutlinedButton({
    super.key,
    required this.text,
    this.size = AppButtonSize.medium,
    this.color,
    this.borderColor,
    this.icon,
    this.onTap,
    this.onLongTap,
    this.status = AppButtonStatus.enabled,
    this.padding,
    this.width,
    this.height,
    this.semanticsLabel,
    this.foregroundColor,
    this.trailingIcon,
  });

  final String text;
  final AppButtonSize size;
  final Color? color;
  final Color? borderColor;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback? onTap;
  final VoidCallback? onLongTap;
  final AppButtonStatus status;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final String? semanticsLabel;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return _AppButtonCore(
      variant: _AppButtonVariant.outline,
      text: text,
      size: size,
      status: status,
      color: color,
      borderColor: borderColor,
      icon: icon,
      trailingIcon: trailingIcon,
      onTap: onTap,
      onLongTap: onLongTap,
      padding: padding,
      width: width,
      height: height,
      semanticsLabel: semanticsLabel,
      foregroundColor: foregroundColor,
    );
  }
}

/// Text-only button with underlined label.
class AppTextButton extends StatelessWidget {
  const AppTextButton({
    super.key,
    required this.text,
    this.size = AppButtonSize.medium,
    this.color,
    this.borderColor,
    this.icon,
    this.onTap,
    this.onLongTap,
    this.status = AppButtonStatus.enabled,
    this.padding,
    this.width,
    this.height,
    this.semanticsLabel,
    this.foregroundColor,
    this.trailingIcon,
    this.underlineLabel = false,
    this.alignment,
  });

  final String text;
  final AppButtonSize size;
  final Color? color;
  final Color? borderColor;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback? onTap;
  final VoidCallback? onLongTap;
  final AppButtonStatus status;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final String? semanticsLabel;
  final Color? foregroundColor;
  final bool underlineLabel;
  final MainAxisAlignment? alignment;

  @override
  Widget build(BuildContext context) {
    return _AppButtonCore(
      variant: _AppButtonVariant.text,
      text: text,
      size: size,
      status: status,
      color: color,
      borderColor: borderColor,
      icon: icon,
      trailingIcon: trailingIcon,
      onTap: onTap,
      onLongTap: onLongTap,
      padding: padding,
      width: width,
      height: height,
      underlineLabel: underlineLabel,
      semanticsLabel: semanticsLabel,
      foregroundColor: foregroundColor,
      alignment: alignment,
    );
  }
}
