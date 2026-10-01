import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/utils/phone_e164.dart';
import 'package:toukh_provider/domain/entities/brand_info.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class BrandInfoScreen extends StatefulWidget {
  const BrandInfoScreen({super.key});

  @override
  State<BrandInfoScreen> createState() => _BrandInfoScreenState();
}

const _socialIconConstraints = BoxConstraints.tightFor(width: 48, height: 48);

class _SocialFieldIcon extends StatelessWidget {
  const _SocialFieldIcon(this.network);

  final ToukhSocialNetwork network;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Center(
        child: ToukhSocialIcon(network: network, size: AppSizes.iconMd),
      ),
    );
  }
}

class _PhoneDraft {
  _PhoneDraft({String text = '', this.whatsapp = false})
    : controller = TextEditingController(text: text);

  final TextEditingController controller;
  bool whatsapp;

  void dispose() => controller.dispose();
}

class _BrandInfoScreenState extends State<BrandInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _website = TextEditingController();
  final _facebook = TextEditingController();
  final _instagram = TextEditingController();
  final _tiktok = TextEditingController();
  final _email = TextEditingController();
  final List<_PhoneDraft> _phones = [];
  var _seeded = false;
  var _saving = false;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    final auth = context.read<AuthCubit>().state;
    if (auth is! Authenticated) return;
    _seed(auth.profile.brandInfo);
    _seeded = true;
  }

  void _seed(BrandInfo info) {
    if (info.phones.isEmpty) {
      _phones.add(_PhoneDraft());
    } else {
      for (final phone in info.phones) {
        final ten = egyptTenDigitsFromStored(phone.number);
        final local = ten == null ? '' : egyptLocalElevenFromTen(ten);
        _phones.add(_PhoneDraft(text: local, whatsapp: phone.whatsapp));
      }
    }
    _website.text = info.website;
    _facebook.text = info.facebook;
    _instagram.text = info.instagram;
    _tiktok.text = info.tiktok;
    _email.text = info.email;
  }

  @override
  void dispose() {
    for (final phone in _phones) {
      phone.dispose();
    }
    _website.dispose();
    _facebook.dispose();
    _instagram.dispose();
    _tiktok.dispose();
    _email.dispose();
    super.dispose();
  }

  String? _phoneValidator(String? value) {
    final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (digits.isEmpty) return null;
    return AppPhoneField.defaultTenDigitValidator(
      value,
      invalidMessage: AppStrings.Auth.invalidPhone,
    );
  }

  String? _emailValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (_emailPattern.hasMatch(trimmed)) return null;
    return AppStrings.Settings.brandEmailInvalid;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_formKey.currentState?.validate() != true) return;

    final phones = <BrandPhone>[];
    for (final draft in _phones) {
      final raw = draft.controller.text.trim();
      if (raw.isEmpty) continue;
      final e164 = egyptMobileE164(raw);
      if (e164.isEmpty) return;
      phones.add(BrandPhone(number: e164, whatsapp: draft.whatsapp));
    }

    final info = BrandInfo(
      phones: phones,
      website: _website.text,
      facebook: _facebook.text,
      instagram: _instagram.text,
      tiktok: _tiktok.text,
      email: _email.text,
    );

    setState(() => _saving = true);
    try {
      await context.read<AuthCubit>().updateBrandInfo(info);
      if (!mounted) return;
      AppSnack.show(
        context,
        message: AppStrings.Settings.brandSaved,
        state: AppSnackState.success,
      );
      context.pop();
    } catch (_) {
      if (!mounted) return;
      AppSnack.show(
        context,
        message: AppStrings.Settings.brandSaveFailed,
        state: AppSnackState.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!_seeded) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(ToukhIcons.back),
            onPressed: () => context.pop(),
          ),
          title: CustomText(AppStrings.Settings.brandInfo),
        ),
        body: const Center(child: AppLoadingMark()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(ToukhIcons.back),
          onPressed: () => context.pop(),
        ),
        title: CustomText(AppStrings.Settings.brandInfo),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSizes.screenPadding.copyWith(
            top: AppSizes.spaceMd,
            bottom: AppSizes.space2xl,
          ),
          children: [
            for (final draft in _phones) ...[
              AppPhoneField(
                controller: draft.controller,
                label: AppStrings.Settings.brandPhone,
                invalidTenDigitsMessage: AppStrings.Auth.invalidPhone,
                validator: _phoneValidator,
                textInputAction: TextInputAction.next,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: draft.whatsapp,
                activeColor: AppColors.secondColor,
                title: Row(
                  children: [
                    const ToukhSocialIcon(
                      network: ToukhSocialNetwork.whatsapp,
                      size: AppSizes.iconSm,
                    ),
                    const SizedBox(width: AppSizes.spaceSm),
                    Expanded(
                      child: CustomText(
                        AppStrings.Settings.brandPhoneWhatsapp,
                        style: TextStyle(
                          fontSize: AppSizes.fontBody,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                onChanged: _saving
                    ? null
                    : (value) {
                        setState(() => draft.whatsapp = value ?? false);
                      },
              ),
              if (_phones.length > 1)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AppTextButton(
                    text: AppStrings.Settings.brandRemovePhone,
                    color: AppColors.error,
                    onTap: _saving
                        ? null
                        : () {
                            setState(() {
                              _phones.remove(draft);
                              draft.dispose();
                            });
                          },
                  ),
                ),
              SizedBox(height: AppSizes.spaceSm),
            ],
            if (_phones.length < 2)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: AppTextButton(
                  text: AppStrings.Settings.brandAddPhone,
                  icon: ToukhIcons.add,
                  onTap: _saving
                      ? null
                      : () => setState(() => _phones.add(_PhoneDraft())),
                ),
              ),
            SizedBox(height: AppSizes.spaceLg),
            AppTextField(
              controller: _website,
              label: AppStrings.Settings.brandWebsite,
              leadingIcon: PhosphorIconsRegular.globe,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: AppSizes.spaceBase),
            AppTextField(
              controller: _facebook,
              label: AppStrings.Settings.brandFacebook,
              prefixIcon: const _SocialFieldIcon(ToukhSocialNetwork.facebook),
              prefixIconConstraints: _socialIconConstraints,
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: AppSizes.spaceBase),
            AppTextField(
              controller: _instagram,
              label: AppStrings.Settings.brandInstagram,
              prefixIcon: const _SocialFieldIcon(ToukhSocialNetwork.instagram),
              prefixIconConstraints: _socialIconConstraints,
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: AppSizes.spaceBase),
            AppTextField(
              controller: _tiktok,
              label: AppStrings.Settings.brandTiktok,
              prefixIcon: const _SocialFieldIcon(ToukhSocialNetwork.tiktok),
              prefixIconConstraints: _socialIconConstraints,
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: AppSizes.spaceBase),
            AppTextField(
              controller: _email,
              label: AppStrings.Settings.brandEmail,
              leadingIcon: ToukhIcons.email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              validator: _emailValidator,
              autofillHints: const [AutofillHints.email],
            ),
            SizedBox(height: AppSizes.spaceXl),
            AppFilledButton(
              text: AppStrings.Common.save,
              width: double.infinity,
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
