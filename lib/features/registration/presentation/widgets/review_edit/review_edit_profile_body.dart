import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class ReviewEditProfileBody extends StatefulWidget {
  const ReviewEditProfileBody({super.key});

  @override
  State<ReviewEditProfileBody> createState() => ReviewEditProfileBodyState();
}

class ReviewEditProfileBodyState extends State<ReviewEditProfileBody> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _desc;

  @override
  void initState() {
    super.initState();
    final d = context.read<RegistrationCubit>().state;
    _name = TextEditingController(text: d.name);
    _desc = TextEditingController(text: d.description);
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  bool save() {
    if (!_formKey.currentState!.validate()) return false;
    context.read<RegistrationCubit>().setProfile(
          name: _name.text.trim(),
          description: _desc.text.trim(),
        );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
        ],
      ),
    );
  }
}
