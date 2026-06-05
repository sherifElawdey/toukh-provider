import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toukh_provider/domain/entities/provider_kind.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/register_kind_card.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Order tuned for registration UX (not enum declaration order).
const List<ServiceType> kRegistrationKindOrder = [
  ServiceType.restaurant,
  ServiceType.supermarket,
  ServiceType.grocery,
  ServiceType.pharmacy,
  ServiceType.homeService,
  ServiceType.homeBrands,
];

String reviewEditKindLabelKey(ServiceType t) {
  switch (t) {
    case ServiceType.restaurant:
      return AppStrings.Registration.kindRestaurant;
    case ServiceType.homeService:
      return AppStrings.Registration.kindHomeService;
    case ServiceType.supermarket:
      return AppStrings.Registration.kindSupermarket;
    case ServiceType.grocery:
      return AppStrings.Registration.kindGrocery;
    case ServiceType.homeBrands:
      return AppStrings.Registration.kindHomeBrands;
    case ServiceType.pharmacy:
      return AppStrings.Registration.kindPharmacy;
  }
}

IconData reviewEditKindIcon(ServiceType t) {
  switch (t) {
    case ServiceType.restaurant:
      return ToukhIcons.restaurant;
    case ServiceType.homeService:
      return PhosphorIconsRegular.wrench;
    case ServiceType.supermarket:
      return ToukhIcons.store;
    case ServiceType.grocery:
      return PhosphorIconsRegular.shoppingCart;
    case ServiceType.homeBrands:
      return PhosphorIconsRegular.seal;
    case ServiceType.pharmacy:
      return PhosphorIconsRegular.firstAid;
  }
}

class ReviewEditKindBody extends StatefulWidget {
  const ReviewEditKindBody({super.key});

  @override
  State<ReviewEditKindBody> createState() => ReviewEditKindBodyState();
}

class ReviewEditKindBodyState extends State<ReviewEditKindBody> {
  ServiceType? _selected;

  @override
  void initState() {
    super.initState();
    _selected = context.read<RegistrationCubit>().state.kind;
  }

  bool save() {
    final kind = _selected;
    if (kind == null) return false;
    context.read<RegistrationCubit>().selectKindForRegistration(kind);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSizes.spaceMd,
        crossAxisSpacing: AppSizes.spaceMd,
        childAspectRatio: 0.95,
      ),
      itemCount: kRegistrationKindOrder.length,
      itemBuilder: (context, index) {
        final kind = kRegistrationKindOrder[index];
        return RegisterKindCard(
          selected: _selected == kind,
          title: reviewEditKindLabelKey(kind),
          icon: reviewEditKindIcon(kind),
          onTap: () => setState(() => _selected = kind),
        );
      },
    );
  }
}
