import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/domain/entities/provider_home_service_request.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> contactHomeServiceCustomer(
  BuildContext context,
  ProviderHomeServiceRequest request,
) async {
  final phone = request.customerPhone?.trim();
  if (phone == null || phone.isEmpty) {
    AppSnack.show(
      context,
      message: AppStrings.HomeServiceRequests.contactCustomerUnavailable.tr,
      state: AppSnackState.error,
      icon: ToukhIcons.error,
    );
    return;
  }

  final uri = Uri(scheme: 'tel', path: phone);
  if (!await canLaunchUrl(uri)) {
    if (!context.mounted) return;
    AppSnack.show(
      context,
      message: AppStrings.HomeServiceRequests.contactCustomerUnavailable.tr,
      state: AppSnackState.error,
      icon: ToukhIcons.error,
    );
    return;
  }

  await launchUrl(uri);
}
