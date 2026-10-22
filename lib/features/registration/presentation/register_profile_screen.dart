import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/registration_step_layout.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class RegisterProfileScreen extends StatefulWidget {
  const RegisterProfileScreen({super.key});

  @override
  State<RegisterProfileScreen> createState() => _RegisterProfileScreenState();
}

class _RegisterProfileScreenState extends State<RegisterProfileScreen> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final d = context.read<RegistrationCubit>().state;
    _name.text = d.name;
    _desc.text = d.description;
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    context.read<RegistrationCubit>().setProfile(
      name: _name.text.trim(),
      description: _desc.text.trim(),
    );
    context.push(AppRoutes.registerMap);
  }

  @override
  Widget build(BuildContext context) {
    return RegistrationStepScaffold(
      stage: RegistrationStage.account,
      icon: PhosphorIconsDuotone.storefront,
      title: AppStrings.Registration.profileTitle,
      subtitle: AppStrings.Registration.profileSubtitle,
      onNext: _next,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RegistrationSectionCard(
                icon: PhosphorIconsDuotone.storefront,
                title: AppStrings.Registration.secBrandTitle,
                hint: AppStrings.Registration.secBrandHint,
                child: TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: AppStrings.Registration.brandName.tr,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? AppStrings.Registration.fieldRequired.tr
                      : null,
                ),
              ),
              RegistrationSectionCard(
                icon: PhosphorIconsDuotone.pencilSimple,
                title: AppStrings.Registration.secDescriptionTitle,
                hint: AppStrings.Registration.secDescriptionHint,
                child: TextFormField(
                  controller: _desc,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: AppStrings.Registration.description.tr,
                    hintText: AppStrings.Registration.descriptionExample.tr,
                    alignLabelWithHint: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
