import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/domain/entities/provider_kind.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/registration_step_layout.dart';
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

    return RegistrationStepScaffold(
      stage: RegistrationStage.place,
      icon: PhosphorIconsDuotone.clock,
      title: AppStrings.Registration.hoursTitle,
      subtitle: AppStrings.Registration.hoursSubtitle,
      onNext: _next,
      children: [WorkingHoursForm(key: _formKey, initial: hours)],
    );
  }
}
