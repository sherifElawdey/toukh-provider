import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/domain/entities/provider_linked_driver.dart';
import 'package:toukh_provider/domain/repositories/provider_drivers_repository.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Pick a restaurant-linked driver for store delivery.
Future<ProviderLinkedDriver?> showStoreDriverPickSheet(
  BuildContext context, {
  required String providerId,
}) {
  return showModalBottomSheet<ProviderLinkedDriver>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSizes.radiusXl),
      ),
    ),
    builder: (ctx) => _StoreDriverPickSheet(providerId: providerId),
  );
}

class _StoreDriverPickSheet extends StatefulWidget {
  const _StoreDriverPickSheet({required this.providerId});

  final String providerId;

  @override
  State<_StoreDriverPickSheet> createState() => _StoreDriverPickSheetState();
}

class _StoreDriverPickSheetState extends State<_StoreDriverPickSheet> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<ProviderLinkedDriver> _filtered(List<ProviderLinkedDriver> all) {
    final q = _search.text.trim().toLowerCase();
    final enabled = all.where((d) => d.enabledByProvider).toList()
      ..sort((a, b) {
        if (a.online != b.online) return a.online ? -1 : 1;
        return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
      });
    if (q.isEmpty) return enabled;
    return enabled.where((d) {
      return d.displayName.toLowerCase().contains(q) ||
          d.phone.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final height = MediaQuery.sizeOf(context).height * 0.72;

    return SizedBox(
      height: height,
      child: Padding(
        padding: AppSizes.screenPadding.copyWith(
          top: AppSizes.spaceMd,
          bottom: AppSizes.spaceLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomText(
              AppStrings.Orders.storeDriverPickTitle.tr,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: AppSizes.fontTitle,
                color: scheme.onSurface,
              ),
            ),
            SizedBox(height: AppSizes.spaceSm),
            CustomText(
              AppStrings.Orders.storeDriverPickSubtitle.tr,
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.65),
                height: 1.35,
              ),
            ),
            SizedBox(height: AppSizes.spaceMd),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: AppStrings.Orders.storeDriverSearchHint.tr,
                prefixIcon: Icon(ToukhIcons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
            ),
            SizedBox(height: AppSizes.spaceMd),
            Expanded(
              child: StreamBuilder<ProviderDriversSnapshot>(
                stream: getIt<ProviderDriversRepository>()
                    .watchDrivers(widget.providerId),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(
                      child: CustomText(
                        AppStrings.Orders.storeDriverLoadError.tr,
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  if (!snap.hasData) {
                    return const Center(child: AppLoadingMark());
                  }
                  final drivers = _filtered(snap.data!.linkedDrivers);
                  if (drivers.isEmpty) {
                    return Center(
                      child: CustomText(
                        AppStrings.Orders.storeDriverEmpty.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: drivers.length,
                    separatorBuilder: (_, _) =>
                        SizedBox(height: AppSizes.spaceSm),
                    itemBuilder: (context, index) {
                      final d = drivers[index];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd),
                          side: BorderSide(
                            color: scheme.onSurface.withValues(alpha: 0.08),
                          ),
                        ),
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.appColor.withValues(alpha: 0.15),
                          child: Icon(
                            ToukhIcons.delivery,
                            color: AppColors.appColor,
                          ),
                        ),
                        title: CustomText(
                          d.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: CustomText(
                          [
                            if (d.phone.isNotEmpty) d.phone,
                            if (d.vehicleType.isNotEmpty) d.vehicleType,
                            d.online
                                ? AppStrings.Orders.storeDriverOnline.tr
                                : AppStrings.Orders.storeDriverOffline.tr,
                          ].join(' · '),
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        trailing: Icon(ToukhIcons.chevronRight),
                        onTap: () => Navigator.of(context).pop(d),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
