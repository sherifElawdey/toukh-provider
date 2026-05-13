import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/registration_step_nav_footer.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class RegisterCredentialsScreen extends StatefulWidget {
  const RegisterCredentialsScreen({super.key});

  @override
  State<RegisterCredentialsScreen> createState() =>
      _RegisterCredentialsScreenState();
}

class _RegisterCredentialsScreenState extends State<RegisterCredentialsScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  File? _brand;
  File? _idFront;
  File? _idBack;

  @override
  void initState() {
    super.initState();
    final d = context.read<RegistrationCubit>().state;
    if (d.phoneNational.isNotEmpty) {
      _phone.text = d.phoneNational;
    }
    _brand = d.brandImage;
    _idFront = d.idFront;
    _idBack = d.idBack;
  }

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<File?> _pickImage(ImageSource source) async {
    try {
      final res = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 88,
      );
      return res == null ? null : File(res.path);
    } catch (e) {
      if (!mounted) return null;
      AppSnack.show(
        context,
        message: '$e',
        state: AppSnackState.error,
        icon: Icons.image_not_supported_outlined,
      );
      return null;
    }
  }

  Future<void> _showPicker(void Function(File) onPicked) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final file = await _pickImage(source);
    if (file != null) onPicked(file);
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;
    if (_brand == null) {
      AppSnack.show(
        context,
        message: AppStrings.Registration.brandImageRequired.tr,
        state: AppSnackState.warning,
        icon: Icons.image_outlined,
      );
      return;
    }
    if (_idFront == null || _idBack == null) {
      AppSnack.show(
        context,
        message: AppStrings.Auth.idPhotosRequired.tr,
        state: AppSnackState.warning,
        icon: Icons.badge_outlined,
      );
      return;
    }
    final national = _phone.text.replaceAll(RegExp(r'\D'), '');
    context.read<RegistrationCubit>().setCredentials(
          phoneNational: national,
          password: _password.text,
          idFront: _idFront!,
          idBack: _idBack!,
          brandImage: _brand!,
        );
    context.push(AppRoutes.registerProfile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: AppSizes.screenPadding.copyWith(bottom: AppSizes.space3xl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SquareBrandImageBlock(
                file: _brand,
                onTapPick: _showPicker,
                onPicked: (f) => setState(() => _brand = f),
              ),
              SizedBox(height: AppSizes.spaceLg),
              AppPhoneField(
                controller: _phone,
                label: AppStrings.Auth.phoneNumber,
                hint: AppStrings.Auth.phoneHint,
                invalidTenDigitsMessage: AppStrings.Auth.invalidPhone,
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: AppSizes.spaceBase),
              AppPasswordField(
                controller: _password,
                label: AppStrings.Auth.password,
                textInputAction: TextInputAction.done,
                validator: (v) => (v == null || v.length < 6)
                    ? AppStrings.Auth.minPasswordLength
                    : null,
              ),
              SizedBox(height: AppSizes.spaceLg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _IdPhotoPickerCard(
                      title: AppStrings.Auth.idFrontPhoto,
                      aspectRatio: 4 / 5,
                      compactTitle: true,
                      compactPlaceholderIcon: true,
                      file: _idFront,
                      placeholderLabel: AppStrings.Auth.tapToAddPhoto.tr,
                      onPicked: (f) => setState(() => _idFront = f),
                      onTapPick: _showPicker,
                    ),
                  ),
                  SizedBox(width: AppSizes.spaceMd),
                  Expanded(
                    child: _IdPhotoPickerCard(
                      title: AppStrings.Auth.idBackPhoto,
                      aspectRatio: 4 / 5,
                      compactTitle: true,
                      compactPlaceholderIcon: true,
                      file: _idBack,
                      placeholderLabel: AppStrings.Auth.tapToAddPhoto.tr,
                      onPicked: (f) => setState(() => _idBack = f),
                      onTapPick: _showPicker,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.spaceXl),
              RegistrationStepNavFooter(
                useSafeArea: false,
                padding: EdgeInsets.zero,
                onBack: () => context.pop(),
                onNext: _continue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SquareBrandImageBlock extends StatelessWidget {
  const _SquareBrandImageBlock({
    required this.file,
    required this.onPicked,
    required this.onTapPick,
  });

  final File? file;
  final ValueChanged<File> onPicked;
  final Future<void> Function(void Function(File) onPicked) onTapPick;

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
              onTap: () => onTapPick(onPicked),
              child: SizedBox(
                width: _side,
                height: _side,
                child: file == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
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
                                Icons.broken_image_outlined,
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
                                      Icons.edit_outlined,
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

class _IdPhotoPickerCard extends StatelessWidget {
  const _IdPhotoPickerCard({
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
                            Icons.add_a_photo_outlined,
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
                              Icons.broken_image_outlined,
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
                                    Icons.edit_outlined,
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
