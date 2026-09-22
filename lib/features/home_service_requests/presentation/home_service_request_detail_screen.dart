import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:toukh_provider/core/firebase/app_firebase_errors.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/domain/entities/provider_home_service_request.dart';
import 'package:toukh_provider/data/services/customer_home_service_on_my_way_notify_service.dart';
import 'package:toukh_provider/domain/repositories/provider_home_service_requests_repository.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/home_service_requests/cubit/home_service_schedule_helpers.dart';
import 'package:toukh_provider/features/home_service_requests/cubit/provider_home_service_requests_cubit.dart';
import 'package:toukh_provider/features/home_service_requests/presentation/widgets/home_service_contact_customer.dart';
import 'package:toukh_provider/features/home_service_requests/presentation/widgets/home_service_submit_quote_sheet.dart';
import 'package:toukh_provider/features/home_service_requests/presentation/widgets/home_service_trip_route_map_sheet.dart';
import 'package:toukh_provider/features/home_service_requests/presentation/widgets/home_service_visit_badge.dart';
import 'package:toukh_provider/features/orders/presentation/delivery_qr_scan_screen.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/order_detail/order_detail_client_details_card.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

const _pageBg = Color(0xFFF2F4F7);

class HomeServiceRequestDetailScreen extends StatelessWidget {
  const HomeServiceRequestDetailScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, auth) {
        if (auth is! Authenticated) {
          return  Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              title: CustomText(AppStrings.HomeServiceRequests.detailTitle.tr),
            ),
            body: Center(child: CustomText('Sign in required')),
          );
        }
        return _HomeServiceRequestDetailBody(
          requestId: requestId,
          providerId: auth.user.uid,
        );
      },
    );
  }
}

class _HomeServiceRequestDetailBody extends StatefulWidget {
  const _HomeServiceRequestDetailBody({
    required this.requestId,
    required this.providerId,
  });

  final String requestId;
  final String providerId;

  @override
  State<_HomeServiceRequestDetailBody> createState() =>
      _HomeServiceRequestDetailBodyState();
}

class _HomeServiceRequestDetailBodyState
    extends State<_HomeServiceRequestDetailBody> {
  bool _busy = false;
  bool _leftForTerminal = false;

  void _leaveDetail() {
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  void _goHomeForTerminal({required String message}) {
    if (_leftForTerminal || !mounted) return;
    _leftForTerminal = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppSnack.show(
        context,
        message: message,
        state: AppSnackState.alert,
        icon: ToukhIcons.info,
      );
      context.go(AppRoutes.home);
    });
  }

  Future<void> _respond(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      AppSnack.show(
        context,
        message: AppStrings.HomeServiceRequests.updated.tr,
        state: AppSnackState.success,
        icon: ToukhIcons.success,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnack.show(
        context,
        message: appFirebaseError(e),
        state: AppSnackState.error,
        icon: ToukhIcons.error,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = getIt<ProviderHomeServiceRequestsRepository>();
    final t = Theme.of(context).textTheme;

    return StreamBuilder<ProviderHomeServiceRequest?>(
      stream: repo.watchRequest(widget.requestId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Scaffold(
            backgroundColor: _pageBg,
            body: Center(child: AppLoadingMark()),
          );
        }
        final request = snap.data;
        if (request == null || request.providerId != widget.providerId) {
          _goHomeForTerminal(
            message: AppStrings.HomeServiceRequests.notFound.tr,
          );
          return Scaffold(
            backgroundColor: _pageBg,
            appBar: AppBar(
              backgroundColor: _pageBg,
              title: CustomText(AppStrings.HomeServiceRequests.detailTitle.tr),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _leaveDetail,
              ),
            ),
            body: Center(
              child: CustomText(AppStrings.HomeServiceRequests.notFound.tr),
            ),
          );
        }

        if (request.isCancelled) {
          _goHomeForTerminal(
            message: AppStrings.Orders.detailCancelledByCustomer.tr,
          );
          return Scaffold(
            backgroundColor: _pageBg,
            appBar: AppBar(
              backgroundColor: _pageBg,
              title: CustomText(AppStrings.HomeServiceRequests.detailTitle.tr),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _leaveDetail,
              ),
            ),
            body: Center(
              child: CustomText(
                AppStrings.Orders.detailCancelledByCustomer.tr,
              ),
            ),
          );
        }

        final requestsState =
            context.watch<ProviderHomeServiceRequestsCubit>().state;
        final activeVisit = requestsState.activeOnMyWayRequest;
        final hasOtherActiveOnMyWay =
            activeVisit != null && activeVisit.id != request.id;
        final canRespond = request.isPending;
        final canMarkOnMyWay =
            request.canMarkOnMyWay && !hasOtherActiveOnMyWay;
        final isBlockedOnMyWay =
            request.canMarkOnMyWay && hasOtherActiveOnMyWay;
        final canFinishVisit = request.isOnTheWay;
        final showContactCustomer = request.isOverdueAccepted;
        final showBottomBar = canRespond ||
            canMarkOnMyWay ||
            isBlockedOnMyWay ||
            canFinishVisit ||
            showContactCustomer;
        final created = request.createdAt;
        final statusLabel = _statusLabel(request.statusNormalized);

        return Scaffold(
          backgroundColor: _pageBg,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: _pageBg,
            title: CustomText(AppStrings.HomeServiceRequests.detailTitle.tr),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _leaveDetail,
            ),
          ),
          bottomNavigationBar: showBottomBar
              ? Material(
                  elevation: 8,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSizes.spaceXl,
                        AppSizes.spaceMd,
                        AppSizes.spaceXl,
                        AppSizes.spaceMd,
                      ),
                      child: canRespond
                          ? Row(
                              children: [
                                Expanded(
                                  child: AppOutlinedButton(
                                    text: AppStrings.HomeServiceRequests.decline,
                                    onTap: _busy
                                        ? null
                                        : () => _respond(
                                              () => context
                                                  .read<
                                                      ProviderHomeServiceRequestsCubit>()
                                                  .decline(request.id),
                                            ),
                                    status: _busy
                                        ? AppButtonStatus.disabled
                                        : AppButtonStatus.enabled,
                                  ),
                                ),
                                const SizedBox(width: AppSizes.spaceMd),
                                Expanded(
                                  child: AppFilledButton(
                                    text: AppStrings.HomeServiceRequests.sendQuote,
                                    onTap: _busy
                                        ? null
                                        : () async {
                                            final sent =
                                                await showHomeServiceSubmitQuoteSheet(
                                              context,
                                              request: request,
                                            );
                                            if (sent == true && mounted) {
                                              AppSnack.show(
                                                context,
                                                message: AppStrings
                                                    .HomeServiceRequests.updated.tr,
                                                state: AppSnackState.success,
                                                icon: ToukhIcons.success,
                                              );
                                            }
                                          },
                                    status: _busy
                                        ? AppButtonStatus.disabled
                                        : AppButtonStatus.enabled,
                                  ),
                                ),
                              ],
                            )
                          : canFinishVisit
                              ? AppFilledButton(
                                  text: AppStrings.HomeServiceRequests.finishVisit,
                                  onTap: _busy
                                      ? null
                                      : () async {
                                          final method =
                                              await showHandoffMethodSheet(
                                            context,
                                            title: AppStrings
                                                .Orders.deliverMethodTitle.tr,
                                            subtitle: AppStrings.Orders
                                                .deliverMethodSubtitle.tr,
                                            qrLabel: AppStrings
                                                .Orders.deliverWithQr.tr,
                                            otpLabel: AppStrings
                                                .Orders.deliverWithOtp.tr,
                                          );
                                          if (method == null || !mounted) {
                                            return;
                                          }
                                          if (method == HandoffMethod.qrCode) {
                                            final payload =
                                                await Navigator.of(context)
                                                    .push<String>(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const DeliveryQrScanScreen(),
                                              ),
                                            );
                                            if (payload == null || !mounted) {
                                              return;
                                            }
                                            await _respond(
                                              () => context
                                                  .read<
                                                      ProviderHomeServiceRequestsCubit>()
                                                  .markCompleted(
                                                    request.id,
                                                    qrPayload: payload,
                                                  ),
                                            );
                                            return;
                                          }
                                          final code =
                                              await showCompletionCodeSheet(
                                                  context);
                                          if (code == null || !mounted) return;
                                          await _respond(
                                            () => context
                                                .read<
                                                    ProviderHomeServiceRequestsCubit>()
                                                .markCompleted(
                                                  request.id,
                                                  completionCode: code,
                                                ),
                                          );
                                        },
                                  status: _busy
                                      ? AppButtonStatus.loading
                                      : AppButtonStatus.enabled,
                                )
                              : request.canMarkOnMyWay
                                  ? AppFilledButton(
                                      text: AppStrings.HomeServiceRequests.onMyWay,
                                      onTap: _busy
                                          ? null
                                          : isBlockedOnMyWay
                                              ? () => _showOnMyWayBlocked(
                                                    context,
                                                    activeVisit,
                                                  )
                                              : () => _respond(() async {
                                                    await context
                                                        .read<
                                                            ProviderHomeServiceRequestsCubit>()
                                                        .markOnMyWay(request.id);
                                                    await getIt<
                                                            CustomerHomeServiceOnMyWayNotifyService>()
                                                        .notifyOnMyWay(
                                                      requestId: request.id,
                                                    );
                                                  }),
                                      status: _busy
                                          ? AppButtonStatus.loading
                                          : AppButtonStatus.enabled,
                                    )
                                  : AppOutlinedButton(
                                      text: AppStrings
                                          .HomeServiceRequests.contactCustomer,
                                      onTap: _busy
                                          ? null
                                          : () => contactHomeServiceCustomer(
                                                context,
                                                request,
                                              ),
                                      status: _busy
                                          ? AppButtonStatus.disabled
                                          : AppButtonStatus.enabled,
                                    ),
                    ),
                  ),
                )
              : null,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.spaceXl,
              AppSizes.spaceSm,
              AppSizes.spaceXl,
              120,
            ),
            children: [
              if (request.isOverdueAccepted) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSizes.spaceMd),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .errorContainer
                        .withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            ToukhIcons.error,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: AppSizes.spaceSm),
                          Expanded(
                            child: HomeServiceVisitBadge(request: request),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.spaceSm),
                      CustomText(
                        AppStrings.HomeServiceRequests.visitOverdueBanner.tr,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onErrorContainer
                              .withValues(alpha: 0.9),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.spaceMd),
              ],
              _InfoCard(
                children: [
                  _DetailRow(
                    label: AppStrings.HomeServiceRequests.fieldCategory.tr,
                    value: request.categoryTitle,
                  ),
                  _DetailRow(
                    label: AppStrings.HomeServiceRequests.fieldStatus.tr,
                    value: statusLabel,
                    emphasized: true,
                  ),
                  if (request.clientPriceEgp != null)
                    _DetailRow(
                      label: AppStrings.HomeServiceRequests.fieldClientPrice.tr,
                      value: '${request.clientPriceEgp!.round()} EGP',
                    ),
                  if (request.quotedPriceEgp != null)
                    _DetailRow(
                      label: AppStrings.HomeServiceRequests.fieldQuotedPrice.tr,
                      value: '${request.quotedPriceEgp!.round()} EGP',
                      emphasized: true,
                    ),
                  if (request.scheduledAt != null && !request.isTripCategory)
                    _DetailRow(
                      label: AppStrings.HomeServiceRequests.fieldVisitDate.tr,
                      value: DateFormat.yMMMd()
                          .add_jm()
                          .format(request.scheduledAt!.toLocal()),
                    ),
                  if (created != null)
                    _DetailRow(
                      label: AppStrings.HomeServiceRequests.fieldRequested.tr,
                      value: DateFormat.yMMMd()
                          .add_jm()
                          .format(created.toLocal()),
                    ),
                  if (request.preferredTimeLabel.isNotEmpty)
                    _DetailRow(
                      label: AppStrings.HomeServiceRequests.fieldPreferredTime.tr,
                      value: request.preferredTimeLabel,
                    ),
                ],
              ),
              const SizedBox(height: AppSizes.spaceMd),
              ClientDetailsCard(
                data: ClientDetailsViewData(
                  name: request.customerName?.trim().isNotEmpty == true
                      ? request.customerName!.trim()
                      : AppStrings.HomeServiceRequests.customerFallback.tr,
                  phone: request.customerPhone,
                  photoUrl: request.customerPhotoUrl,
                  addressTitle: request.startAddressTitle ?? request.addressTitle,
                  addressFormatted: request.startAddressFormatted ??
                      request.addressFormatted,
                  lat: request.startLat ?? request.addressLat ?? 0,
                  lng: request.startLng ?? request.addressLng ?? 0,
                ),
              ),
              if (request.destinationAddressFormatted != null &&
                  request.destinationAddressFormatted!.trim().isNotEmpty) ...[
                const SizedBox(height: AppSizes.spaceMd),
                _InfoCard(
                  children: [
                    _DetailRow(
                      label:
                          AppStrings.HomeServiceRequests.fieldStartLocation.tr,
                      value: [
                        if ((request.startAddressTitle ?? request.addressTitle)
                                ?.trim()
                                .isNotEmpty ==
                            true)
                          (request.startAddressTitle ?? request.addressTitle)!
                              .trim(),
                        if ((request.startAddressFormatted ??
                                    request.addressFormatted)
                                ?.trim()
                                .isNotEmpty ==
                            true)
                          (request.startAddressFormatted ??
                                  request.addressFormatted)!
                              .trim(),
                      ].join('\n'),
                    ),
                    _DetailRow(
                      label:
                          AppStrings.HomeServiceRequests.fieldDestination.tr,
                      value: [
                        if (request.destinationAddressTitle
                                ?.trim()
                                .isNotEmpty ==
                            true)
                          request.destinationAddressTitle!.trim(),
                        request.destinationAddressFormatted!.trim(),
                      ].join('\n'),
                    ),
                    if (request.isTripCategory &&
                        tripCoordsUsable(
                          request.startLat ?? request.addressLat,
                          request.startLng ?? request.addressLng,
                        ) &&
                        tripCoordsUsable(
                          request.destinationLat,
                          request.destinationLng,
                        )) ...[
                      const SizedBox(height: AppSizes.spaceMd),
                      AppOutlinedButton(
                        text: AppStrings.HomeServiceRequests.viewRouteOnMap.tr,
                        onTap: () {
                          showTripRouteMapSheet(
                            context: context,
                            startLat:
                                (request.startLat ?? request.addressLat)!,
                            startLng:
                                (request.startLng ?? request.addressLng)!,
                            destinationLat: request.destinationLat!,
                            destinationLng: request.destinationLng!,
                            startLabel: request.startAddressTitle ??
                                request.addressTitle,
                            destinationLabel: request.destinationAddressTitle,
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ],
              if (request.preferredDate != null) ...[
                const SizedBox(height: AppSizes.spaceMd),
                _InfoCard(
                  children: [
                    _DetailRow(
                      label:
                          AppStrings.HomeServiceRequests.fieldPreferredDate.tr,
                      value: DateFormat.yMMMEd()
                          .format(request.preferredDate!.toLocal()),
                    ),
                  ],
                ),
              ],
              if (request.cargoDescription?.trim().isNotEmpty == true) ...[
                const SizedBox(height: AppSizes.spaceMd),
                _InfoCard(
                  children: [
                    _DetailRow(
                      label: AppStrings.HomeServiceRequests.fieldCargo.tr,
                      value: request.cargoDescription!.trim(),
                    ),
                  ],
                ),
              ],
              if (request.withDriver != null) ...[
                const SizedBox(height: AppSizes.spaceMd),
                _InfoCard(
                  children: [
                    _DetailRow(
                      label: AppStrings.HomeServiceRequests.fieldDriver.tr,
                      value: request.withDriver!
                          ? AppStrings.HomeServiceRequests.withDriver.tr
                          : AppStrings.HomeServiceRequests.withoutDriver.tr,
                    ),
                  ],
                ),
              ],
              if (request.note?.isNotEmpty == true) ...[
                const SizedBox(height: AppSizes.spaceMd),
                _InfoCard(
                  children: [
                    CustomText(
                      AppStrings.HomeServiceRequests.fieldProblem.tr,
                      style: t.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spaceSm),
                    CustomText(
                      request.note!,
                      style: t.bodyLarge?.copyWith(height: 1.45),
                    ),
                  ],
                ),
              ],
              if (request.preServiceAnswers.isNotEmpty) ...[
                const SizedBox(height: AppSizes.spaceMd),
                _InfoCard(
                  children: [
                    CustomText(
                      AppStrings.HomeServiceRequests.preServiceAnswersTitle.tr,
                      style: t.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    for (final a in request.preServiceAnswers) ...[
                      const SizedBox(height: AppSizes.spaceMd),
                      CustomText(
                        a.question,
                        style: t.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        a.answer,
                        style: t.bodyLarge?.copyWith(height: 1.4),
                      ),
                    ],
                  ],
                ),
              ],
              if (request.noteImageUrl?.trim().isNotEmpty == true) ...[
                const SizedBox(height: AppSizes.spaceMd),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  child: HavitNetworkImage(
                    imageUrl: request.noteImageUrl!,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showOnMyWayBlocked(
    BuildContext context,
    ProviderHomeServiceRequest? activeVisit,
  ) {
    final name = activeVisit?.customerName?.trim();
    final message = name != null && name.isNotEmpty
        ? AppStrings.HomeServiceRequests.onMyWayBlockedNamed.trParams({
            'name': name,
          })
        : AppStrings.HomeServiceRequests.onMyWayBlocked.tr;
    AppSnack.show(
      context,
      message: message,
      state: AppSnackState.error,
      icon: ToukhIcons.error,
    );
  }

  String _statusLabel(String status) {
    return ToukhStatusKeys.homeService(status).tr;
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.spaceMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spaceSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: CustomText(
              label,
              style: t.bodyMedium?.copyWith(
                color: Colors.blueGrey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: CustomText(
              value,
              textAlign: TextAlign.end,
              style: (emphasized ? t.titleSmall : t.bodyMedium)?.copyWith(
                fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
