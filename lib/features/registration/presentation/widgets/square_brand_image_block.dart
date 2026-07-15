import 'dart:io';

import 'package:flutter/material.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class SquareBrandImageBlock extends StatelessWidget {
  const SquareBrandImageBlock({
    super.key,
    required this.file,
    required this.onPicked,
    required this.onTapPick,
  });

  final File? file;
  final ValueChanged<File> onPicked;
  final Future<void> Function(
    BuildContext context,
    void Function(File) onPicked,
  ) onTapPick;

  static const double _side = 128;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Material(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              side: BorderSide(
                color: file != null
                    ? AppColors.secondColor.withValues(alpha: 0.45)
                    : scheme.outline.withValues(alpha: 0.22),
                width: file != null ? 2 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onTapPick(context, onPicked),
              child: SizedBox(
                width: _side,
                height: _side,
                child: file == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            ToukhIcons.camera,
                            size: 36,
                            color: scheme.onSurface.withValues(alpha: 0.38),
                          ),
                          SizedBox(height: AppSizes.spaceXs),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.spaceSm,
                            ),
                            child: CustomText(
                              AppStrings.Auth.tapToAddPhoto,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: AppSizes.fontCaption,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface.withValues(alpha: 0.55),
                              ),
                            ),
                          ),
                        ],
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
                                size: 40,
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
                                    Colors.black.withValues(alpha: 0.5),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSizes.spaceXs,
                                  horizontal: AppSizes.spaceSm,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      ToukhIcons.edit,
                                      size: 14,
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
        ),
        SizedBox(height: AppSizes.spaceMd),
        CustomText(
          AppStrings.Auth.createAccountSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppSizes.fontBody,
            height: 1.45,
            color: scheme.onSurface.withValues(alpha: 0.72),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
