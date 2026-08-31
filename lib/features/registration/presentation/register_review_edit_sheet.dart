import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/domain/entities/provider_kind.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/review_field.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/review_edit/review_edit_category_body.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/review_edit/review_edit_delivery_body.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/review_edit/review_edit_hours_body.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/review_edit/review_edit_kind_body.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/review_edit/review_edit_location_body.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/review_edit/review_edit_phone_body.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/review_edit/review_edit_pre_service_questions_body.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/review_edit/review_edit_profile_body.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

Future<void> showRegisterReviewEditSheet(
  BuildContext context, {
  required ReviewField field,
  Future<void> Function(RegistrationDraft draft)? onPersist,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSizes.radiusXl),
      ),
    ),
    builder: (sheetContext) => BlocProvider.value(
      value: context.read<RegistrationCubit>(),
      child: _RegisterReviewEditSheet(field: field, onPersist: onPersist),
    ),
  );
}

class _RegisterReviewEditSheet extends StatefulWidget {
  const _RegisterReviewEditSheet({
    required this.field,
    this.onPersist,
  });

  final ReviewField field;
  final Future<void> Function(RegistrationDraft draft)? onPersist;

  @override
  State<_RegisterReviewEditSheet> createState() =>
      _RegisterReviewEditSheetState();
}

class _RegisterReviewEditSheetState extends State<_RegisterReviewEditSheet> {
  final _kindKey = GlobalKey<ReviewEditKindBodyState>();
  final _categoryKey = GlobalKey<ReviewEditCategoryBodyState>();
  final _profileKey = GlobalKey<ReviewEditProfileBodyState>();
  final _phoneKey = GlobalKey<ReviewEditPhoneBodyState>();
  final _locationKey = GlobalKey<ReviewEditLocationBodyState>();
  final _hoursKey = GlobalKey<ReviewEditHoursBodyState>();
  final _deliveryKey = GlobalKey<ReviewEditDeliveryBodyState>();
  final _preServiceQuestionsKey =
      GlobalKey<ReviewEditPreServiceQuestionsBodyState>();

  late String _locationAddress;

  @override
  void initState() {
    super.initState();
    final draft = context.read<RegistrationCubit>().state;
    _locationAddress = draft.formattedAddress.trim();
  }

  String _titleKey(ReviewField field) {
    switch (field) {
      case ReviewField.kind:
        return AppStrings.Registration.reviewBusinessType;
      case ReviewField.category:
        final kind = context.read<RegistrationCubit>().state.kind;
        if (kind == ServiceType.homeService) {
          return AppStrings.Registration.serviceCategoryTitle;
        }
        return AppStrings.Registration.shopCategoryTitle;
      case ReviewField.profile:
        return AppStrings.Registration.brandName;
      case ReviewField.phone:
        return AppStrings.Auth.phoneNumber;
      case ReviewField.location:
        return AppStrings.Registration.mapTitle;
      case ReviewField.hours:
        return AppStrings.Registration.hoursTitle;
      case ReviewField.delivery:
        return AppStrings.Registration.deliveryTitle;
      case ReviewField.preServiceQuestions:
        return AppStrings.Registration.preServiceQuestionsTitle;
    }
  }

  bool get _tallSheet {
    switch (widget.field) {
      case ReviewField.kind:
      case ReviewField.location:
      case ReviewField.hours:
      case ReviewField.delivery:
      case ReviewField.category:
      case ReviewField.preServiceQuestions:
        return true;
      case ReviewField.profile:
      case ReviewField.phone:
        return false;
    }
  }

  Future<bool> _onSave(BuildContext sheetContext) async {
    final cubit = context.read<RegistrationCubit>();
    switch (widget.field) {
      case ReviewField.kind:
        if (_kindKey.currentState?.save() ?? false) return true;
        return false;
      case ReviewField.category:
        if (_categoryKey.currentState?.save() ?? false) return true;
        AppSnack.show(
          sheetContext,
          message: AppStrings.Auth.registrationDataMissing.tr,
          state: AppSnackState.warning,
          icon: ToukhIcons.category,
        );
        return false;
      case ReviewField.profile:
        return _profileKey.currentState?.save() ?? false;
      case ReviewField.phone:
        return _phoneKey.currentState?.save() ?? false;
      case ReviewField.location:
        return await (_locationKey.currentState?.save(cubit) ??
            Future.value(false));
      case ReviewField.hours:
        return _hoursKey.currentState?.save(sheetContext) ?? false;
      case ReviewField.delivery:
        return _deliveryKey.currentState?.save(sheetContext) ?? false;
      case ReviewField.preServiceQuestions:
        return _preServiceQuestionsKey.currentState?.save() ?? false;
    }
  }

  Future<void> _persistAndClose() async {
    if (!await _onSave(context)) return;
    if (!mounted) return;
    final draft = context.read<RegistrationCubit>().state;
    final persist = widget.onPersist;
    if (persist != null) {
      await context.withAppLoading(() => persist(draft));
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  Widget _body() {
    switch (widget.field) {
      case ReviewField.kind:
        return ReviewEditKindBody(key: _kindKey);
      case ReviewField.category:
        return ReviewEditCategoryBody(key: _categoryKey);
      case ReviewField.profile:
        return ReviewEditProfileBody(key: _profileKey);
      case ReviewField.phone:
        return ReviewEditPhoneBody(key: _phoneKey);
      case ReviewField.location:
        return ReviewEditLocationBody(
          key: _locationKey,
          onAddressChanged: (address) {
            if (!mounted || _locationAddress == address) return;
            setState(() => _locationAddress = address);
          },
        );
      case ReviewField.hours:
        return ReviewEditHoursBody(key: _hoursKey);
      case ReviewField.delivery:
        return ReviewEditDeliveryBody(key: _deliveryKey);
      case ReviewField.preServiceQuestions:
        return ReviewEditPreServiceQuestionsBody(key: _preServiceQuestionsKey);
    }
  }

  Widget _buildLocationSheet(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final height = MediaQuery.sizeOf(context).height * 0.92;

    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSizes.radiusXl),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _body(),
                  Positioned(
                    top: AppSizes.spaceSm,
                    right: AppSizes.spaceSm,
                    child: Material(
                      color: scheme.surface.withValues(alpha: 0.92),
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: IconButton(
                        tooltip: AppStrings.Common.cancel.tr,
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(ToukhIcons.close, color: scheme.onSurface),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Material(
            color: scheme.surface,
            elevation: 8,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: AppSizes.screenPadding.copyWith(
                  top: AppSizes.spaceMd,
                  bottom: AppSizes.spaceMd,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      _locationAddress.isEmpty ? '…' : _locationAddress,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: AppSizes.fontBody,
                        color: scheme.onSurface,
                      ),
                    ),
                    SizedBox(height: AppSizes.spaceMd),
                    AppFilledButton(
                      text: AppStrings.Registration.reviewEditSave,
                      onTap: _persistAndClose,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultSheet(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height *
        (_tallSheet ? 0.88 : 0.55);

    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: AppSizes.spaceSm),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
            ),
          ),
          Padding(
            padding: AppSizes.screenPadding.copyWith(
              top: AppSizes.spaceMd,
              bottom: AppSizes.spaceSm,
            ),
            child: CustomText(
              _titleKey(widget.field).tr,
              style: TextStyle(
                fontSize: AppSizes.fontTitle,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: AppSizes.screenPadding.copyWith(top: 0),
              child: _body(),
            ),
          ),
          Padding(
            padding: AppSizes.screenPadding.copyWith(
              bottom: AppSizes.spaceLg,
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppOutlinedButton(
                    text: AppStrings.Common.cancel,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                SizedBox(width: AppSizes.spaceMd),
                Expanded(
                  child: AppFilledButton(
                    text: AppStrings.Registration.reviewEditSave,
                    onTap: _persistAndClose,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.field == ReviewField.location) {
      return _buildLocationSheet(context);
    }
    return _buildDefaultSheet(context);
  }
}
