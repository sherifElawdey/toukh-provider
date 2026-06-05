import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/core/notifications/provider_order_alert_controller.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/features/orders/cubit/provider_orders_cubit.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Persistent top banner for new orders while the provider app is in the foreground.
class ProviderOrderAlertOverlay extends StatelessWidget {
  const ProviderOrderAlertOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ProviderOrderAlertController.instance,
      builder: (context, _) {
        final alert = ProviderOrderAlertController.instance.active;
        return Stack(
          children: [
            child,
            if (alert != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _OrderAlertBanner(notification: alert),
              ),
          ],
        );
      },
    );
  }
}

class _OrderAlertBanner extends StatelessWidget {
  const _OrderAlertBanner({required this.notification});

  final ToukhNotification notification;

  String get _orderId =>
      notification.orderId ?? notification.payload['orderId']?.toString() ?? '';

  String _subtitle() {
    final payload = notification.payload;
    final items = payload['items'];
    if (items is List && items.isNotEmpty) {
      final lines = <String>[];
      for (final raw in items.take(3)) {
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        final name = m['name']?.toString() ?? 'Item';
        final qty = m['quantity'] ?? 1;
        final total = m['lineTotalEgp'] ?? m['unitPrice'];
        lines.add('$qty× $name — ${total ?? ''} EGP');
      }
      if (items.length > 3) {
        lines.add('+${items.length - 3} more');
      }
      final total = payload['totalEgp'];
      if (total != null) lines.add('Total: $total EGP');
      return lines.join('\n');
    }
    return notification.description;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final orderId = _orderId;
    final imageUrl = notification.imageUrl;

    return Material(
      elevation: 8,
      color: scheme.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl != null && imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderIcon(scheme),
                  ),
                )
              else
                _placeholderIcon(scheme),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      notification.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: AppSizes.fontLabel,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    CustomText(
                      _subtitle(),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        color: scheme.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: orderId.isEmpty
                                ? null
                                : () async {
                                    await getIt<ProviderOrdersCubit>()
                                        .approve(orderId);
                                    ProviderOrderAlertController.instance
                                        .dismiss();
                                  },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.success,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: CustomText(
                              AppStrings.Orders.actionApprove.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: orderId.isEmpty
                                ? null
                                : () async {
                                    await getIt<ProviderOrdersCubit>()
                                        .cancel(orderId);
                                    ProviderOrderAlertController.instance
                                        .dismiss();
                                  },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: CustomText(
                              AppStrings.Orders.actionCancel.tr,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: AppStrings.Orders.actionDismiss.tr,
                onPressed: ProviderOrderAlertController.instance.dismiss,
                icon: Icon(ToukhIcons.close, color: scheme.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderIcon(ColorScheme scheme) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.appColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(ToukhIcons.orders, color: AppColors.appColor),
    );
  }
}
