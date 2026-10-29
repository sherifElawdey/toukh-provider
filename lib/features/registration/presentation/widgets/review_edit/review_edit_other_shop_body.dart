import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/other_shop_picker.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class ReviewEditOtherShopBody extends StatefulWidget {
  const ReviewEditOtherShopBody({super.key});

  @override
  State<ReviewEditOtherShopBody> createState() => ReviewEditOtherShopBodyState();
}

class ReviewEditOtherShopBodyState extends State<ReviewEditOtherShopBody> {
  String? _categoryId;
  List<String> _typeIds = const [];
  ProviderOrderMode? _orderMode;

  @override
  void initState() {
    super.initState();
    final d = context.read<RegistrationCubit>().state;
    _categoryId = d.otherShopCategoryId;
    _typeIds = d.otherShopTypeIds;
    _orderMode = d.orderMode;
  }

  bool save() {
    if ((_categoryId?.isEmpty ?? true) || _typeIds.isEmpty || _orderMode == null) {
      AppSnack.show(
        context,
        message: AppStrings.Registration.otherShopPickCategory.tr,
        state: AppSnackState.warning,
        icon: ToukhIcons.category,
      );
      return false;
    }
    context.read<RegistrationCubit>().updateOtherShop(_categoryId, _typeIds, _orderMode);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return OtherShopPicker(
      categoryId: _categoryId,
      typeIds: _typeIds,
      orderMode: _orderMode,
      onChanged: (c, t, m) => setState(() {
        _categoryId = c;
        _typeIds = t;
        _orderMode = m;
      }),
    );
  }
}
