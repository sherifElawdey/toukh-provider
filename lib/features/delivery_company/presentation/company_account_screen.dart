import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/domain/entities/delivery_company.dart';
import 'package:toukh_provider/domain/repositories/delivery_company_repository.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Company details: name and manager are editable; phone and location are
/// shown read-only (they are tied to sign-in and the service area).
class CompanyAccountScreen extends StatefulWidget {
  const CompanyAccountScreen({super.key});

  @override
  State<CompanyAccountScreen> createState() => _CompanyAccountScreenState();
}

class _CompanyAccountScreenState extends State<CompanyAccountScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _manager;
  bool _saving = false;

  DeliveryCompany? get _company => switch (context.read<AuthCubit>().state) {
    AuthenticatedCompany(:final company) => company,
    _ => null,
  };

  @override
  void initState() {
    super.initState();
    final c = _company;
    _name = TextEditingController(text: c?.companyName ?? '');
    _manager = TextEditingController(text: c?.managerName ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _manager.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final company = _company;
    if (company == null || !(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await getIt<DeliveryCompanyRepository>().updateInfo(
        company.uid,
        companyName: _name.text.trim(),
        managerName: _manager.text.trim(),
      );
      if (!mounted) return;
      AppSnack.show(
        context,
        message: AppStrings.Company.companyDetailsSaved.tr,
        state: AppSnackState.success,
        icon: ToukhIcons.check,
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      AppSnack.show(
        context,
        message: AppStrings.Company.actionFailed.tr,
        state: AppSnackState.error,
        icon: ToukhIcons.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? v) =>
      (v ?? '').trim().length < 2 ? AppStrings.Company.requiredField.tr : null;

  @override
  Widget build(BuildContext context) {
    final company = _company;
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.65);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(ToukhIcons.back),
          onPressed: () => context.pop(),
        ),
        title: CustomText(AppStrings.Company.companyDetails),
      ),
      body: company == null
          ? const Center(child: AppLoadingMark())
          : Form(
              key: _form,
              child: ListView(
                padding: AppSizes.screenPadding.copyWith(
                  top: AppSizes.spaceLg,
                  bottom: AppSizes.space2xl,
                ),
                children: [
                  AppTextField(
                    controller: _name,
                    labelText: AppStrings.Company.companyName.tr,
                    validator: _required,
                  ),
                  const SizedBox(height: AppSizes.spaceMd),
                  AppTextField(
                    controller: _manager,
                    labelText: AppStrings.Company.managerName.tr,
                    validator: _required,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: AppSizes.spaceMd),
                  AppTextField(
                    initialValue: company.phone,
                    labelText: AppStrings.Company.phone.tr,
                    readOnly: true,
                    enabled: false,
                  ),
                  const SizedBox(height: AppSizes.spaceMd),
                  AppTextField(
                    initialValue: [company.address, company.serviceAreaName]
                        .whereType<String>()
                        .where((s) => s.isNotEmpty)
                        .join(' · '),
                    labelText: AppStrings.Company.address.tr,
                    readOnly: true,
                    enabled: false,
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSizes.spaceSm),
                  CustomText(
                    AppStrings.Company.readOnlyHint,
                    style: TextStyle(
                      fontSize: AppSizes.fontCaption,
                      color: muted,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spaceXl),
                  AppFilledButton(
                    text: AppStrings.Common.save,
                    status: _saving
                        ? AppButtonStatus.loading
                        : AppButtonStatus.enabled,
                    onTap: _saving ? null : _save,
                  ),
                ],
              ),
            ),
    );
  }
}
