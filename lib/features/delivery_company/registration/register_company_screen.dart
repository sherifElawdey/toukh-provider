import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/features/delivery_company/registration/delivery_company_registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/registration_step_layout.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Step 1 of the delivery company sign-up: company, manager, phone, password.
class RegisterCompanyScreen extends StatefulWidget {
  const RegisterCompanyScreen({super.key});

  @override
  State<RegisterCompanyScreen> createState() => _RegisterCompanyScreenState();
}

class _RegisterCompanyScreenState extends State<RegisterCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyName = TextEditingController();
  final _managerName = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void initState() {
    super.initState();
    final d = context.read<DeliveryCompanyRegistrationCubit>().state;
    _companyName.text = d.companyName;
    _managerName.text = d.managerName;
    _phone.text = d.phoneNational;
  }

  @override
  void dispose() {
    _companyName.dispose();
    _managerName.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? AppStrings.Company.requiredField : null;

  void _continue() {
    if (!_formKey.currentState!.validate()) return;
    context.read<DeliveryCompanyRegistrationCubit>().setDetails(
      companyName: _companyName.text,
      managerName: _managerName.text,
      phoneNational: _phone.text.replaceAll(RegExp(r'\D'), ''),
      password: _password.text,
    );
    context.push(AppRoutes.registerCompanyMap);
  }

  @override
  Widget build(BuildContext context) {
    return RegistrationStepScaffold(
      stage: RegistrationStage.account,
      icon: PhosphorIconsDuotone.truck,
      title: AppStrings.Company.registerTitle,
      subtitle: AppStrings.Company.registerSubtitle,
      onNext: _continue,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RegistrationSectionCard(
                icon: PhosphorIconsDuotone.buildings,
                title: AppStrings.Company.secInfoTitle,
                hint: AppStrings.Company.secInfoHint,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _companyName,
                      label: AppStrings.Company.companyName,
                      leadingIcon: ToukhIcons.delivery,
                      validator: _required,
                    ),
                    SizedBox(height: AppSizes.spaceBase),
                    AppTextField(
                      controller: _managerName,
                      label: AppStrings.Company.managerName,
                      leadingIcon: ToukhIcons.person,
                      validator: _required,
                    ),
                  ],
                ),
              ),
              RegistrationSectionCard(
                icon: PhosphorIconsDuotone.lockKey,
                title: AppStrings.Company.secLoginTitle,
                hint: AppStrings.Company.secLoginHint,
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
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.length < 6)
                          ? AppStrings.Auth.minPasswordLength
                          : null,
                    ),
                    SizedBox(height: AppSizes.spaceBase),
                    AppPasswordField(
                      controller: _confirm,
                      label: AppStrings.Company.confirmPassword,
                      textInputAction: TextInputAction.done,
                      validator: (v) => v != _password.text
                          ? AppStrings.Company.passwordsMismatch
                          : null,
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
