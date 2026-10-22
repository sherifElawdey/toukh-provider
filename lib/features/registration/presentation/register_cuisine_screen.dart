import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/domain/entities/provider_kind.dart';
import 'package:toukh_provider/domain/entities/shop_category.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/registration_step_layout.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class RegisterCuisineScreen extends StatefulWidget {
  const RegisterCuisineScreen({super.key});

  @override
  State<RegisterCuisineScreen> createState() => _RegisterCuisineScreenState();
}

class _RegisterCuisineScreenState extends State<RegisterCuisineScreen> {
  late List<String> _selected;

  bool _isRestaurant(RegistrationDraft d) =>
      d.kind == ServiceType.restaurant &&
      d.shopCategory == ShopCategory.restaurant;

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(
      context.read<RegistrationCubit>().state.cuisineTags,
    );
  }

  void _next() {
    if (_selected.isEmpty) {
      AppSnack.show(
        context,
        message: AppStrings.Registration.cuisineRequired.tr,
        state: AppSnackState.warning,
        icon: ToukhIcons.category,
      );
      return;
    }
    context.read<RegistrationCubit>().setCuisineTags(_selected);
    context.push(AppRoutes.registerReview);
  }

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<RegistrationCubit>().state;
    if (!_isRestaurant(draft)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.pushReplacement(AppRoutes.registerReview);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return RegistrationStepScaffold(
      stage: RegistrationStage.place,
      icon: PhosphorIconsDuotone.cookingPot,
      title: AppStrings.Registration.cuisineTitle,
      subtitle: AppStrings.Registration.cuisineSubtitle,
      onNext: _next,
      children: [
        RegistrationSectionCard(
          icon: PhosphorIconsDuotone.forkKnife,
          title: AppStrings.Registration.cuisineTitle,
          hint: AppStrings.Registration.cuisineIllustrationHint,
          child: CuisineTagsPicker(
            selectedIds: _selected,
            onChanged: (ids) => setState(() => _selected = ids),
            labelForTag: (tag) => tag.l10nKey.tr,
            labelForGroup: (group) => group.l10nKey.tr,
          ),
        ),
      ],
    );
  }
}
