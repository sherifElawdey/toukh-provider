import 'dart:io';

import 'package:flutter/material.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class IdPhotoPickerCard extends StatelessWidget {
  const IdPhotoPickerCard({
    super.key,
    required this.title,
    this.aspectRatio = 16 / 10,
    this.compactTitle = false,
    this.compactPlaceholderIcon = false,
    required this.file,
    required this.placeholderLabel,
    required this.onPicked,
    required this.onTapPick,
  });

  final String title;
  final double aspectRatio;
  final bool compactTitle;
  final bool compactPlaceholderIcon;
  final File? file;
  final String placeholderLabel;
  final ValueChanged<File> onPicked;
  final Future<void> Function(void Function(File) onPicked) onTapPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final titleSize =
        compactTitle ? AppSizes.fontLabel : AppSizes.fontTitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomText(
          title,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        SizedBox(height: AppSizes.spaceSm),
        Material(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            side: BorderSide(
              color: file != null
                  ? AppColors.secondColor.withValues(alpha: 0.35)
                  : scheme.outline.withValues(alpha: 0.2),
              width: file != null ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onTapPick(onPicked),
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: file == null
                  ? Padding(
                      padding: const EdgeInsets.all(AppSizes.spaceSm),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            ToukhIcons.camera,
                            size: compactPlaceholderIcon ? 28 : 40,
                            color: scheme.onSurface.withValues(alpha: 0.38),
                          ),
                          SizedBox(height: AppSizes.spaceSm),
                          CustomText(
                            placeholderLabel,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: compactTitle
                                  ? AppSizes.fontCaption
                                  : AppSizes.fontLabel,
                              color: scheme.onSurface.withValues(alpha: 0.55),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          file!,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(
                              PhosphorIconsRegular.imageBroken,
                              size: 48,
                              color: scheme.onSurface.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.55),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSizes.spaceSm,
                                horizontal: AppSizes.spaceMd,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    ToukhIcons.edit,
                                    size: 18,
                                    color: Colors.white.withValues(alpha: 0.95),
                                  ),
                                  SizedBox(width: AppSizes.spaceXs),
                                  Flexible(
                                    child: CustomText(
                                      AppStrings.Auth.tapToReplaceIdPhoto,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: AppSizes.fontCaption,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white
                                            .withValues(alpha: 0.95),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
