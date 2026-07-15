import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/media/safe_image_pick.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/id_photo_picker_card.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/registration_step_nav_footer.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/square_brand_image_block.dart';
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

  Future<void> _showPicker(
    BuildContext cardContext,
    void Function(File) onPicked,
  ) =>
      pickImageInto(cardContext, onPicked);

  void _continue() {
    if (!_formKey.currentState!.validate()) return;
    if (_brand == null) {
      AppSnack.show(
        context,
        message: AppStrings.Registration.brandImageRequired.tr,
        state: AppSnackState.warning,
        icon: ToukhIcons.image,
      );
      return;
    }
    if (_idFront == null || _idBack == null) {
      AppSnack.show(
        context,
        message: AppStrings.Auth.idPhotosRequired.tr,
        state: AppSnackState.warning,
        icon: PhosphorIconsRegular.identificationBadge,
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
          icon: Icon(ToukhIcons.back),
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
              SquareBrandImageBlock(
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
                    child: IdPhotoPickerCard(
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
                    child: IdPhotoPickerCard(
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
