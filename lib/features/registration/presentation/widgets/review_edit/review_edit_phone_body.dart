import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class ReviewEditPhoneBody extends StatefulWidget {
  const ReviewEditPhoneBody({super.key});

  @override
  State<ReviewEditPhoneBody> createState() => ReviewEditPhoneBodyState();
}

class ReviewEditPhoneBodyState extends State<ReviewEditPhoneBody> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phone;

  @override
  void initState() {
    super.initState();
    final d = context.read<RegistrationCubit>().state;
    _phone = TextEditingController(text: d.phoneNational);
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  bool save() {
    if (!_formKey.currentState!.validate()) return false;
    final national = _phone.text.replaceAll(RegExp(r'\D'), '');
    context.read<RegistrationCubit>().setPhoneNational(national);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: AppPhoneField(
        controller: _phone,
        label: AppStrings.Auth.phoneNumber,
        hint: AppStrings.Auth.phoneHint,
        invalidTenDigitsMessage: AppStrings.Auth.invalidPhone,
        textInputAction: TextInputAction.done,
      ),
    );
  }
}
