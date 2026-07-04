import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/core/updates/app_version_gate_service.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/home/cubit/home_dashboard_cubit.dart';
import 'package:toukh_provider/features/home/cubit/home_dashboard_state.dart';
import 'package:toukh_provider/features/home/presentation/widgets/home_dashboard_overview_tab.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AppVersionGateService _versionGate;
  bool _updateDialogVisible = false;

  @override
  void initState() {
    super.initState();
    _versionGate = getIt<AppVersionGateService>();
    _versionGate.addListener(_onVersionGateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_syncFcmToken());
      unawaited(_presentMandatoryUpdateIfNeeded());
    });
  }

  @override
  void dispose() {
    _versionGate.removeListener(_onVersionGateChanged);
    super.dispose();
  }

  void _onVersionGateChanged() {
    unawaited(_presentMandatoryUpdateIfNeeded());
  }

  Future<void> _presentMandatoryUpdateIfNeeded() async {
    if (!mounted || _updateDialogVisible) return;
    final result = await _versionGate.ensureChecked();
    if (!mounted || !result.needsUpdate || _updateDialogVisible) return;
    final storeUri = _versionGate.storeUri;
    if (storeUri == null) return;

    _updateDialogVisible = true;
    await showAppMandatoryUpdateDialog(
      context,
      title: AppStrings.AppUpdate.title.tr,
      description: AppStrings.AppUpdate.description.tr,
      storeUri: storeUri,
      updateButtonLabel: AppStrings.AppUpdate.openStore.tr,
      imageAsset: 'assets/branding/app_icon_provider.png',
      imagePackage: null,
    );
    if (mounted) {
      _updateDialogVisible = false;
      unawaited(_presentMandatoryUpdateIfNeeded());
    }
  }

  Future<void> _syncFcmToken() async {
    final auth = getIt<AuthCubit>().state;
    if (auth is! Authenticated) return;
    await ToukhFcmTokenSync.syncIfNeeded(
      uid: auth.user.uid,
      existingFcmTokens: auth.profile.fcmTokens,
      firestore: FirebaseFirestore.instance,
      recipient: ToukhNotificationRecipient.provider,
    );
  }

  String _greetingTr() {
    final h = DateTime.now().hour;
    if (h < 12) return AppStrings.Home.greetingMorning.tr;
    if (h < 17) return AppStrings.Home.greetingAfternoon.tr;
    return AppStrings.Home.greetingEvening.tr;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<HomeDashboardCubit, HomeDashboardState>(
      builder: (context, state) {
        if (!state.authenticated) {
          return const SizedBox.shrink();
        }

        if (state.errorMessage != null &&
            !state.loading &&
            state.orders.isEmpty &&
            state.reviews.isEmpty) {
          return Padding(
            padding: AppSizes.screenPadding.copyWith(top: AppSizes.spaceXl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomText(
                  AppStrings.Common.error.tr,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: AppSizes.fontHeadline,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSizes.spaceSm),
                CustomText(
                  state.errorMessage!,
                  style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.72)),
                ),
                const SizedBox(height: AppSizes.spaceLg),
                AppFilledButton(
                  text: AppStrings.Common.retry.tr,
                  onTap: () => context.read<HomeDashboardCubit>().retry(),
                ),
              ],
            ),
          );
        }

        if (state.loading &&
            state.orders.isEmpty &&
            state.reviews.isEmpty &&
            state.errorMessage == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return HomeDashboardOverviewTab(
          state: state,
          greeting: _greetingTr(),
        );
      },
    );
  }
}
