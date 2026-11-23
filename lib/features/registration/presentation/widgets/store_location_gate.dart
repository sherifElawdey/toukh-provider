import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Shown instead of the store-location map until the device position is
/// known: a loader while locating, else why it failed and how to fix it.
class StoreLocationGate extends StatelessWidget {
  const StoreLocationGate({
    super.key,
    required this.locating,
    required this.failure,
    required this.onAction,
  });

  final bool locating;
  final ToukhLocationFailure? failure;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = AppStrings.Permissions;
    return ToukhLocationGateView(
      locating: locating || failure == null,
      locatingLabel: p.locatingCurrent.tr,
      title: switch (failure) {
        ToukhLocationFailure.serviceOff => p.locationOffTitle.tr,
        ToukhLocationFailure.noFix => p.locationFailedTitle.tr,
        _ => p.locationNeededTitle.tr,
      },
      message: switch (failure) {
        ToukhLocationFailure.serviceOff => p.locationOffBody.tr,
        ToukhLocationFailure.noFix => p.locationFailedBody.tr,
        _ => p.storeLocationNeededBody.tr,
      },
      actionLabel: switch (failure) {
        ToukhLocationFailure.deniedForever => p.openSettings.tr,
        ToukhLocationFailure.serviceOff => p.turnOnLocation.tr,
        ToukhLocationFailure.noFix => AppStrings.Common.retry.tr,
        _ => p.allowLocation.tr,
      },
      onAction: locating ? null : onAction,
    );
  }
}
