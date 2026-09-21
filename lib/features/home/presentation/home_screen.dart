import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_provider/shared/shared.dart';

/// Showcase home: greeting + mock stats; feature taps → Coming soon.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greetingLabel() {
    final h = DateTime.now().hour;
    if (h < 12) return AppStrings.Home.greetingMorning.tr;
    if (h < 17) return AppStrings.Home.greetingAfternoon.tr;
    return AppStrings.Home.greetingEvening.tr;
  }

  void _soon(BuildContext context, [String? title]) {
    context.push(AppRoutes.comingSoon, extra: title);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final auth = context.watch<AuthCubit>().state;
    final rawName =
        auth is Authenticated ? auth.profile.displayName.trim() : '';
    final name = rawName.isEmpty ? '' : rawName.split(RegExp(r'\s+')).first;
    final greeting = name.isEmpty ? _greetingLabel() : '${_greetingLabel()}, $name';

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: AppSizes.screenPadding.copyWith(
            top: AppSizes.spaceLg,
            bottom: AppSizes.space2xl,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Use Text (not CustomText) so composed greeting is not re-.tr'd.
              Text(
                greeting,
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  fontSize: AppSizes.fontHeadline,
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Demo dashboard — full tools coming soon'.tr,
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  fontSize: AppSizes.fontBody,
                  color: scheme.onSurface.withValues(alpha: 0.72),
                  height: 1.35,
                ),
              ),
              SizedBox(height: AppSizes.spaceXl),
              Row(
                children: [
                  Expanded(
                    child: _MockStatCard(
                      label: 'Orders today'.tr,
                      value: '8',
                    ),
                  ),
                  SizedBox(width: AppSizes.spaceSm),
                  Expanded(
                    child: _MockStatCard(
                      label: 'Revenue'.tr,
                      value: '1,240',
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.spaceSm),
              Row(
                children: [
                  Expanded(
                    child: _MockStatCard(
                      label: 'Pending'.tr,
                      value: '3',
                    ),
                  ),
                  SizedBox(width: AppSizes.spaceSm),
                  Expanded(
                    child: _MockStatCard(
                      label: 'Reviews'.tr,
                      value: '4.8',
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.spaceXl),
              AppFilledButton(
                text: AppStrings.Orders.title.tr,
                onTap: () => _soon(context, AppStrings.Orders.title.tr),
              ),
              SizedBox(height: AppSizes.spaceMd),
              if (ToukhFeatureFlags.walletEnabled) ...[
                AppOutlinedButton(
                  text: 'Wallet'.tr,
                  onTap: () => _soon(context, 'Wallet'),
                ),
                SizedBox(height: AppSizes.spaceMd),
              ],
              AppOutlinedButton(
                text: AppStrings.Notifications.title.tr,
                onTap: () =>
                    _soon(context, AppStrings.Notifications.title.tr),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _MockStatCard extends StatelessWidget {
  const _MockStatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spaceBase),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: AppSizes.fontCaption,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: AppSizes.spaceXs),
            Text(
              value,
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: AppSizes.fontHeadline,
                fontWeight: FontWeight.w900,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
