import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/domain/entities/provider_home_service_request.dart';
import 'package:toukh_provider/features/home_service_requests/cubit/home_service_schedule_helpers.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

String homeServiceVisitBadgeLabel(ProviderHomeServiceRequest request) {
  if (request.isOnTheWay) {
    return AppStrings.HomeServiceRequests.statusOnTheWay.tr;
  }

  final days = request.daysUntilVisitCount;
  if (days == null) return '';

  if (days < 0) {
    final overdueDays = days.abs();
    return overdueDays == 1
        ? AppStrings.HomeServiceRequests.visitOverdue.tr
        : AppStrings.HomeServiceRequests.visitOverdueDays.trParams({
            'days': '$overdueDays',
          });
  }
  if (days == 0) {
    return AppStrings.HomeServiceRequests.visitToday.tr;
  }
  if (days == 1) {
    return AppStrings.HomeServiceRequests.visitTomorrow.tr;
  }
  return AppStrings.HomeServiceRequests.visitInDays.trParams({'days': '$days'});
}

({Color background, Color foreground}) homeServiceVisitBadgeColors({
  required ProviderHomeServiceRequest request,
  required ColorScheme scheme,
}) {
  if (request.isOnTheWay) {
    return (
      background: AppColors.appColor.withValues(alpha: 0.14),
      foreground: AppColors.secondColor,
    );
  }

  final timing = request.visitTiming;
  return switch (timing) {
    VisitTiming.overdue => (
        background: scheme.errorContainer.withValues(alpha: 0.55),
        foreground: scheme.error,
      ),
    VisitTiming.today => (
        background: AppColors.secondColor.withValues(alpha: 0.14),
        foreground: AppColors.secondColor,
      ),
    VisitTiming.upcoming => (
        background: AppColors.appColor.withValues(alpha: 0.12),
        foreground: AppColors.appColor,
      ),
    null => (
        background: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        foreground: scheme.onSurface.withValues(alpha: 0.72),
      ),
  };
}

({Color background, Color border, double borderWidth}) homeServiceVisitCardDecoration({
  required ProviderHomeServiceRequest request,
  required ColorScheme scheme,
}) {
  if (request.isOverdueAccepted) {
    return (
      background: scheme.errorContainer.withValues(alpha: 0.35),
      border: scheme.error,
      borderWidth: 1.5,
    );
  }
  return (
    background: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
    border: scheme.outlineVariant.withValues(alpha: 0.45),
    borderWidth: 1,
  );
}

class HomeServiceVisitBadge extends StatelessWidget {
  const HomeServiceVisitBadge({super.key, required this.request});

  final ProviderHomeServiceRequest request;

  @override
  Widget build(BuildContext context) {
    final label = homeServiceVisitBadgeLabel(request);
    if (label.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final colors = homeServiceVisitBadgeColors(
      request: request,
      scheme: scheme,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: CustomText(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: colors.foreground,
        ),
      ),
    );
  }
}
