import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/domain/entities/provider_kind.dart';
import 'package:toukh_provider/core/widgets/toukh_service_logo.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/registration_step_nav_footer.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/working_hours_form.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class RegisterHoursScreen extends StatefulWidget {
  const RegisterHoursScreen({super.key});

  @override
  State<RegisterHoursScreen> createState() => _RegisterHoursScreenState();
}

class _RegisterHoursScreenState extends State<RegisterHoursScreen> {
  final _formKey = GlobalKey<WorkingHoursFormState>();

  void _next() {
    final hours = _formKey.currentState?.validate();
    if (hours == null) return;
    context.read<RegistrationCubit>().setWorkingHours(hours);
    final kind = context.read<RegistrationCubit>().state.kind;
    if (kind == ServiceType.homeService) {
      context.push(AppRoutes.registerReview);
    } else {
      context.push(AppRoutes.registerDelivery);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hours = context.read<RegistrationCubit>().state.workingHours;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(ToukhIcons.back),
          onPressed: () => context.pop(),
        ),
        title: CustomText(AppStrings.Registration.hoursTitle),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: AppSizes.screenPadding,
              children: [
                Center(
                  child: ToukhServiceLogo(
                    size: 56,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                SizedBox(height: AppSizes.spaceMd),
                WorkingHoursForm(key: _formKey, initial: hours),
              ],
            ),
          ),
          RegistrationStepNavFooter(
            onBack: () => context.pop(),
            onNext: _next,
          ),
        ],
      ),
    );
  }
}
