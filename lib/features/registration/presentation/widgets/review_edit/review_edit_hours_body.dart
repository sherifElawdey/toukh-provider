import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/working_hours_form.dart';

class ReviewEditHoursBody extends StatefulWidget {
  const ReviewEditHoursBody({super.key});

  @override
  State<ReviewEditHoursBody> createState() => ReviewEditHoursBodyState();
}

class ReviewEditHoursBodyState extends State<ReviewEditHoursBody> {
  final _formKey = GlobalKey<WorkingHoursFormState>();

  bool save(BuildContext context) {
    final hours = _formKey.currentState?.validate();
    if (hours == null) return false;
    context.read<RegistrationCubit>().setWorkingHours(hours);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final hours = context.read<RegistrationCubit>().state.workingHours;
    return WorkingHoursForm(key: _formKey, initial: hours);
  }
}
