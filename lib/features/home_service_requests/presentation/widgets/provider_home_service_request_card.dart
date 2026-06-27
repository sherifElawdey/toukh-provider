import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/domain/entities/provider_home_service_request.dart';
import 'package:toukh_provider/features/home_service_requests/cubit/provider_home_service_requests_state.dart';
import 'package:toukh_provider/features/home_service_requests/presentation/widgets/home_service_request_timed_builder.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/incoming_order_wait_counter.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class ProviderHomeServiceRequestCard extends StatelessWidget {
  const ProviderHomeServiceRequestCard({
    super.key,
    required this.request,
    required this.tab,
  });

  final ProviderHomeServiceRequest request;
  final ProviderHomeServiceRequestsTab tab;

  @override
  Widget build(BuildContext context) {
    if (tab == ProviderHomeServiceRequestsTab.incoming) {
      return HomeServiceRequestTimedBuilder(
        key: ValueKey(request.id),
        request: request,
        builder: (context, elapsed, urgency, hasCreatedTime) => _buildCard(
          context,
          urgency: urgency,
          elapsed: elapsed,
          hasCreatedTime: hasCreatedTime,
        ),
      );
    }
    return _buildCard(context);
  }

  Widget _buildCard(
    BuildContext context, {
    IncomingOrderUrgency urgency = IncomingOrderUrgency.normal,
    Duration elapsed = Duration.zero,
    bool hasCreatedTime = true,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final decoration = tab == ProviderHomeServiceRequestsTab.incoming
        ? incomingOrderUrgencyDecoration(urgency, scheme)
        : incomingOrderUrgencyDecoration(IncomingOrderUrgency.normal, scheme);
    final customerLabel = _customerLabel();
    final notePreview = request.note?.trim();
    final locale = Localizations.localeOf(context).toString();
    final created = request.createdAt;
    final dateLabel = created == null
        ? '—'
        : formatDateLabel(created, locale: locale);

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
                children: [
                  Expanded(
                    child: CustomText(
                      customerLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: AppSizes.fontTitle,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  _StatusChip(status: request.statusNormalized),
                ],
              ),
              const SizedBox(height: 6),
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
              if (notePreview != null && notePreview.isNotEmpty) ...[
                const SizedBox(height: 8),
                CustomText(
                  notePreview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.68),
                    fontSize: AppSizes.fontBody,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    ToukhIcons.clock,
                    size: 16,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: CustomText(
                      '${AppStrings.HomeServiceRequests.placedAtLabel.tr}: $dateLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.62),
                        fontSize: AppSizes.fontLabel,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (tab == ProviderHomeServiceRequestsTab.incoming)
                    IncomingOrderWaitCounter(
                      elapsed: elapsed,
                      urgency: urgency,
                      hasPlacementTime: hasCreatedTime,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _customerLabel() {
    final name = request.customerName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return AppStrings.HomeServiceRequests.customerFallback.tr;
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _statusColor(scheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: CustomText(
        _statusLabel(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  String _statusLabel() {
    return switch (status) {
      'pending' => AppStrings.HomeServiceRequests.statusPending.tr,
      'tendering' => AppStrings.HomeServiceRequests.statusTendering.tr,
      'quoted' => AppStrings.HomeServiceRequests.statusQuoted.tr,
      'awaiting_customer' =>
        AppStrings.HomeServiceRequests.statusAwaitingCustomer.tr,
      'awaiting_provider' =>
        AppStrings.HomeServiceRequests.statusAwaitingProvider.tr,
      'accepted' => AppStrings.HomeServiceRequests.statusAccepted.tr,
      'completed' => AppStrings.HomeServiceRequests.statusCompleted.tr,
      'cancelled' => AppStrings.HomeServiceRequests.statusCancelled.tr,
      'declined' || 'rejected' =>
        AppStrings.HomeServiceRequests.statusDeclined.tr,
      _ => status
          .split(RegExp(r'[_\s]+'))
          .where((p) => p.isNotEmpty)
          .map((p) => '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
          .join(' '),
    };
  }

  Color _statusColor(ColorScheme scheme) {
    return switch (status) {
      'pending' || 'tendering' || 'quoted' => AppColors.secondColor,
      'awaiting_customer' || 'awaiting_provider' => AppColors.warning,
      'accepted' => AppColors.success,
      'completed' => AppColors.appColor,
      'cancelled' || 'declined' || 'rejected' => scheme.error,
      _ => AppColors.appColor,
    };
  }
}
