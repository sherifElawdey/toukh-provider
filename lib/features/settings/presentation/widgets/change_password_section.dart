import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/settings/presentation/widgets/settings_section_title.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Settings section: current password + new password, then "Change".
/// The current password is checked by signing in again before the new one
/// is set ([AuthCubit.changePassword]).
class ChangePasswordSection extends StatefulWidget {
  const ChangePasswordSection({super.key});

  static const minLength = 6;

  @override
  State<ChangePasswordSection> createState() => _ChangePasswordSectionState();
}

class _ChangePasswordSectionState extends State<ChangePasswordSection> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final error = await context.read<AuthCubit>().changePassword(
          currentPassword: _current.text,
          newPassword: _next.text,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      AppSnack.show(context, message: error, state: AppSnackState.error);
      return;
    }
    _formKey.currentState?.reset();
    _current.clear();
    _next.clear();
    _confirm.clear();
    AppSnack.show(
      context,
      message: AppStrings.Settings.changePasswordDone.tr,
      state: AppSnackState.success,
      icon: ToukhIcons.lock,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsSectionTitle(labelKey: AppStrings.Settings.changePasswordTitle),
          SizedBox(height: AppSizes.spaceSm),
          AppPasswordField(
            controller: _current,
            label: AppStrings.Settings.changePasswordCurrent,
            textInputAction: TextInputAction.next,
            validator: (v) => (v == null || v.isEmpty)
                ? AppStrings.Settings.changePasswordCurrentRequired
                : null,
          ),
          SizedBox(height: AppSizes.spaceBase),
          AppPasswordField(
            controller: _next,
            label: AppStrings.Settings.changePasswordNew,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            validator: (v) {
              final value = v ?? '';
              if (value.length < ChangePasswordSection.minLength) {
                return AppStrings.Settings.changePasswordTooShort;
              }
              if (value.trim() != value) {
                return AppStrings.Settings.changePasswordSpaces;
              }
              if (value == _current.text) {
                return AppStrings.Settings.changePasswordSame;
              }
              return null;
            },
          ),
          SizedBox(height: AppSizes.spaceBase),
          AppPasswordField(
            controller: _confirm,
            label: AppStrings.Settings.changePasswordConfirm,
            autofillHints: const [AutofillHints.newPassword],
            validator: (v) => v != _next.text
                ? AppStrings.Settings.changePasswordMismatch
                : null,
          ),
          SizedBox(height: AppSizes.spaceMd),
          AppFilledButton(
            text: AppStrings.Settings.changePasswordAction,
            icon: ToukhIcons.lock,
            status: _saving ? AppButtonStatus.loading : AppButtonStatus.enabled,
            onTap: _saving ? null : _submit,
          ),
        ],
      ),
    );
  }
}
