import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/widgets/toukh_service_logo.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/registration_step_nav_footer.dart';
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(ToukhIcons.back),
          onPressed: () => context.pop(),
        ),
        title: CustomText(AppStrings.Registration.profileTitle),
      ),
      body: SingleChildScrollView(
        padding: AppSizes.screenPadding.copyWith(bottom: AppSizes.space3xl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ToukhServiceLogo(
                  size: 56,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              SizedBox(height: AppSizes.spaceMd),
              TextFormField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: AppStrings.Registration.brandName.tr,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              SizedBox(height: AppSizes.spaceMd),
              TextFormField(
                controller: _desc,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: AppStrings.Registration.description.tr,
                ),
              ),
              SizedBox(height: AppSizes.spaceXl),
              RegistrationStepNavFooter(
                useSafeArea: false,
                padding: EdgeInsets.zero,
                onBack: () => context.pop(),
                onNext: _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
