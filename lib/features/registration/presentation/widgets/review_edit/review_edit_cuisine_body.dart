import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class ReviewEditCuisineBody extends StatefulWidget {
  const ReviewEditCuisineBody({super.key});

  @override
  State<ReviewEditCuisineBody> createState() => ReviewEditCuisineBodyState();
}

class ReviewEditCuisineBodyState extends State<ReviewEditCuisineBody> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(
      context.read<RegistrationCubit>().state.cuisineTags,
    );
  }

  bool apply() {
    if (_selected.isEmpty) {
      AppSnack.show(
        context,
        message: AppStrings.Registration.cuisineRequired.tr,
        state: AppSnackState.warning,
        icon: ToukhIcons.category,
      );
      return false;
    }
    context.read<RegistrationCubit>().setCuisineTags(_selected);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return CuisineTagsPicker(
      selectedIds: _selected,
      onChanged: (ids) => setState(() => _selected = ids),
      labelForTag: (tag) => tag.l10nKey.tr,
      labelForGroup: (group) => group.l10nKey.tr,
    );
  }
}
