import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/core/widgets/toukh_service_logo.dart';
import 'package:toukh_provider/domain/entities/provider_account_status.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Delivery company that is blocked, or verified but not yet activated.
/// Activation is retried automatically once; the router moves on as soon as
/// the company doc turns active.
class CompanyStatusScreen extends StatefulWidget {
  const CompanyStatusScreen({super.key});

  @override
  State<CompanyStatusScreen> createState() => _CompanyStatusScreenState();
}

class _CompanyStatusScreenState extends State<CompanyStatusScreen> {
  bool _activating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _activate(quiet: true));
  }

  Future<void> _activate({bool quiet = false}) async {
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthenticatedCompany ||
        auth.company.status == ProviderAccountStatus.blocked ||
        !auth.company.phoneVerified ||
        _activating) {
      return;
    }
    setState(() => _activating = true);
    final ok = await context.read<AuthCubit>().activateCompany();
    if (!mounted) return;
    setState(() => _activating = false);
    if (!ok && !quiet) {
      AppSnack.show(
        context,
        message: AppStrings.Company.actionFailed.tr,
        state: AppSnackState.error,
        icon: ToukhIcons.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    final blocked =
        auth is AuthenticatedCompany &&
        auth.company.status == ProviderAccountStatus.blocked;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          AppTextButton(
            text: AppStrings.AccountStatus.signOut,
            onTap: () => context.read<AuthCubit>().signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSizes.screenPadding,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ToukhServiceLogo(size: AppSizes.logoAuth),
                  SizedBox(height: AppSizes.spaceXl),
                  Icon(
                    blocked ? ToukhIcons.lock : ToukhIcons.clock,
                    size: 48,
                    color: blocked ? scheme.error : AppColors.secondColor,
                  ),
                  SizedBox(height: AppSizes.spaceMd),
                  CustomText(
                    blocked
                        ? AppStrings.Company.blockedTitle
                        : AppStrings.Company.activatingTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: AppSizes.fontTitle,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: AppSizes.spaceSm),
                  CustomText(
                    blocked
                        ? AppStrings.Company.blockedBody
                        : AppStrings.Company.activatingBody,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppSizes.fontBody,
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      height: 1.4,
                    ),
                  ),
                  if (!blocked) ...[
                    SizedBox(height: AppSizes.spaceXl),
                    AppFilledButton(
                      text: AppStrings.Company.retryActivation,
                      icon: ToukhIcons.refresh,
                      status: _activating
                          ? AppButtonStatus.loading
                          : AppButtonStatus.enabled,
                      onTap: _activating ? null : () => _activate(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
