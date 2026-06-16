import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Shows a camera/gallery picker sheet and returns the chosen image file.
Future<File?> pickProfileImage(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(ToukhIcons.camera),
            title: CustomText(AppStrings.Settings.takePhoto),
            onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
          ),
          ListTile(
            leading: Icon(ToukhIcons.gallery),
            title: CustomText(AppStrings.Settings.pickFromGallery),
            onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null || !context.mounted) return null;

  try {
    final res = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 88,
    );
    return res == null ? null : File(res.path);
  } catch (e) {
    if (!context.mounted) return null;
    AppSnack.show(
      context,
      message: '$e',
      state: AppSnackState.error,
      icon: PhosphorIconsRegular.imageBroken,
    );
    return null;
  }
}
