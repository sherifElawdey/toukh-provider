import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/domain/entities/provider_home_service_request.dart';
import 'package:toukh_provider/features/home_service_requests/cubit/home_service_schedule_helpers.dart';
import 'package:toukh_provider/features/home_service_requests/presentation/widgets/home_service_visit_badge.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class HomeServiceScheduleJobCard extends StatelessWidget {
  const HomeServiceScheduleJobCard({super.key, required this.request});

  final ProviderHomeServiceRequest request;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final scheduled = request.scheduledAt!.toLocal();
    final timeLabel = DateFormat.jm().format(scheduled);
    final customer = request.customerName?.trim().isNotEmpty == true
        ? request.customerName!.trim()
        : AppStrings.HomeServiceRequests.customerFallback.tr;
    final address = request.addressFormatted?.trim() ??
        request.addressTitle?.trim();
    final price = request.quotedPriceEgp ?? request.clientPriceEgp;
    final decoration = homeServiceVisitCardDecoration(
      request: request,
      scheme: scheme,
    );

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: decoration.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: decoration.border,
          width: decoration.borderWidth,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () =>
            context.push(AppRoutes.homeServiceRequestDetailPath(request.id)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: request.isOverdueAccepted
                          ? scheme.errorContainer.withValues(alpha: 0.55)
                          : AppColors.appColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          ToukhIcons.clock,
                          size: 18,
                          color: request.isOverdueAccepted
                              ? scheme.error
                              : AppColors.secondColor,
                        ),
                        const SizedBox(height: 4),
                        CustomText(
                          timeLabel,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: AppSizes.fontLabel,
                            color: request.isOverdueAccepted
                                ? scheme.error
                                : AppColors.secondColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: CustomText(
                                customer,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: AppSizes.fontTitle,
                                  color: scheme.onSurface,
                                ),
                              ),
                            ),
                            _StatusChip(request: request),
                          ],
                        ),
                        const SizedBox(height: 4),
                        CustomText(
                          request.categoryTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: AppSizes.fontBody,
                            color: scheme.onSurface.withValues(alpha: 0.72),
                          ),
                        ),
                        const SizedBox(height: 8),
                        HomeServiceVisitBadge(request: request),
                      ],
                    ),
                  ),
                ],
              ),
              if (address != null && address.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      ToukhIcons.location,
                      size: 16,
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: CustomText(
                        address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: AppSizes.fontLabel,
                          color: scheme.onSurface.withValues(alpha: 0.68),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (price != null && price > 0) ...[
                const SizedBox(height: 10),
                CustomText(
                  AppStrings.HomeServiceSchedule.priceLabel.trParams({
                    'price': _formatEgp(price),
                  }),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: AppSizes.fontBody,
                    color: AppColors.appColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatEgp(double p) =>
      p % 1 == 0 ? p.toStringAsFixed(0) : p.toStringAsFixed(2);
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.request});

  final ProviderHomeServiceRequest request;

  @override
  Widget build(BuildContext context) {
    final label = request.isOnTheWay
        ? AppStrings.HomeServiceRequests.statusOnTheWay.tr
        : AppStrings.HomeServiceRequests.statusAccepted.tr;
    final color = request.isOnTheWay ? AppColors.secondColor : AppColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: CustomText(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
