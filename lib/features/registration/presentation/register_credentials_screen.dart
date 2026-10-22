import 'package:flutter/material.dart';
import 'package:toukh_provider/core/media/picked_media.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/media/safe_image_pick.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/id_photo_picker_card.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/registration_step_layout.dart';
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

  PickedMedia? _brand;
  PickedMedia? _idFront;
  PickedMedia? _idBack;

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
    void Function(PickedMedia) onPicked,
  ) => pickImageInto(cardContext, onPicked);

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
    return RegistrationStepScaffold(
      stage: RegistrationStage.account,
      icon: PhosphorIconsDuotone.identificationCard,
      title: AppStrings.Registration.credentialsTitle,
      subtitle: AppStrings.Registration.credentialsSubtitle,
      onNext: _continue,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RegistrationSectionCard(
                icon: PhosphorIconsDuotone.imageSquare,
                title: AppStrings.Registration.secLogoTitle,
                hint: AppStrings.Registration.secLogoHint,
                child: SquareBrandImageBlock(
                  file: _brand,
                  onTapPick: _showPicker,
                  onPicked: (f) => setState(() => _brand = f),
                ),
              ),
              RegistrationSectionCard(
                icon: PhosphorIconsDuotone.lockKey,
                title: AppStrings.Registration.secLoginTitle,
                hint: AppStrings.Registration.secLoginHint,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                  ],
                ),
              ),
              RegistrationSectionCard(
                icon: PhosphorIconsDuotone.identificationCard,
                title: AppStrings.Registration.secIdTitle,
                hint: AppStrings.Registration.secIdHint,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: IdPhotoPickerCard(
                        title: AppStrings.Auth.idFrontPhoto,
                        aspectRatio: 4 / 3,
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
                        aspectRatio: 4 / 3,
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
              ),
            ],
          ),
        ),
      ],
    );
  }
}
