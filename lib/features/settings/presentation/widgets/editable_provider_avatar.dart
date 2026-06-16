import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/settings/presentation/widgets/pick_profile_image_sheet.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Provider brand/profile avatar with camera edit affordance and upload flow.
class EditableProviderAvatar extends StatefulWidget {
  const EditableProviderAvatar({
    super.key,
    required this.imageUrl,
    required this.size,
    this.fallbackIcon = PhosphorIconsRegular.storefront,
  });

  final String? imageUrl;
  final double size;
  final IconData fallbackIcon;

  @override
  State<EditableProviderAvatar> createState() => _EditableProviderAvatarState();
}

class _EditableProviderAvatarState extends State<EditableProviderAvatar> {
  bool _uploading = false;
  File? _localPreview;

  @override
  void didUpdateWidget(EditableProviderAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrl != oldWidget.imageUrl) {
      _localPreview = null;
    }
  }

  Future<void> _onTap() async {
    if (_uploading) return;

    final file = await pickProfileImage(context);
    if (file == null || !mounted) return;

    setState(() {
      _uploading = true;
      _localPreview = file;
    });
    try {
      await context.read<AuthCubit>().updateBrandImage(file);
      if (!mounted) return;
      AppSnack.show(
        context,
        message: AppStrings.Settings.profilePhotoUpdated.tr,
        state: AppSnackState.success,
        icon: ToukhIcons.image,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _localPreview = null);
      AppSnack.show(
        context,
        message: AppStrings.Settings.profilePhotoFailed.tr,
        state: AppSnackState.error,
        icon: PhosphorIconsRegular.imageBroken,
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Widget _avatarImage(ColorScheme scheme) {
    if (_localPreview != null) {
      return Image.file(
        _localPreview!,
        key: ValueKey(_localPreview!.path),
        fit: BoxFit.cover,
      );
    }

    final url = widget.imageUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        key: ValueKey(url),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => ColoredBox(
          color: AppColors.thirdColor.withValues(alpha: 0.6),
          child: Icon(
            widget.fallbackIcon,
            size: widget.size * 0.45,
            color: scheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
      );
    }

    return ColoredBox(
      color: AppColors.thirdColor.withValues(alpha: 0.6),
      child: Icon(
        widget.fallbackIcon,
        size: widget.size * 0.45,
        color: scheme.onSurface.withValues(alpha: 0.45),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final badgeSize = widget.size * 0.34;

    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipOval(
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: _avatarImage(scheme),
              ),
            ),
            if (_uploading)
              Positioned.fill(
                child: ClipOval(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.45),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  color: AppColors.appColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: scheme.surface,
                    width: 2,
                  ),
                ),
                child: Icon(
                  ToukhIcons.camera,
                  size: badgeSize * 0.52,
                  color: scheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
