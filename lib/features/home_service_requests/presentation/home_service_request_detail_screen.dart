import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:toukh_provider/core/firebase/app_firebase_errors.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/domain/entities/provider_home_service_request.dart';
import 'package:toukh_provider/domain/repositories/provider_home_service_requests_repository.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/home_service_requests/cubit/provider_home_service_requests_cubit.dart';
import 'package:toukh_provider/features/home_service_requests/presentation/widgets/home_service_submit_quote_sheet.dart';
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
          return const Scaffold(
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
          return Scaffold(
            backgroundColor: _pageBg,
            appBar: AppBar(
              backgroundColor: _pageBg,
              title: CustomText(AppStrings.HomeServiceRequests.detailTitle.tr),
            ),
            body: Center(
              child: CustomText(AppStrings.HomeServiceRequests.notFound.tr),
            ),
          );
        }

        final canRespond = request.isPending;
        final created = request.createdAt;

        return Scaffold(
          backgroundColor: _pageBg,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: _pageBg,
            title: CustomText(AppStrings.HomeServiceRequests.detailTitle.tr),
            centerTitle: true,
          ),
          bottomNavigationBar: canRespond
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
                      child: Row(
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
              _InfoCard(
                children: [
                  _DetailRow(
                    label: AppStrings.HomeServiceRequests.fieldCategory.tr,
                    value: request.categoryTitle,
                  ),
                  _DetailRow(
                    label: AppStrings.HomeServiceRequests.fieldStatus.tr,
                    value: request.status,
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
                  if (request.scheduledAt != null)
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
                ],
              ),
              const SizedBox(height: AppSizes.spaceMd),
              _InfoCard(
                children: [
                  _DetailRow(
                    label: AppStrings.HomeServiceRequests.fieldAddress.tr,
                    value: request.addressTitle?.trim().isNotEmpty == true
                        ? request.addressTitle!
                        : AppStrings.HomeServiceRequests.noAddress.tr,
                  ),
                  if (request.addressFormatted?.trim().isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: CustomText(
                        request.addressFormatted!,
                        style: t.bodyMedium?.copyWith(
                          color: Colors.blueGrey.shade600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  if (request.preferredTimeLabel.isNotEmpty) ...[
                    const SizedBox(height: AppSizes.spaceMd),
                    _DetailRow(
                      label: AppStrings.HomeServiceRequests.fieldPreferredTime.tr,
                      value: request.preferredTimeLabel,
                    ),
                  ],
                ],
              ),
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
              if (request.noteImageUrl?.trim().isNotEmpty == true) ...[
                const SizedBox(height: AppSizes.spaceMd),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  child: Image.network(
                    request.noteImageUrl!,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => ColoredBox(
                      color: AppColors.thirdColor.withValues(alpha: 0.4),
                      child: SizedBox(
                        height: 220,
                        child: Center(child: Icon(ToukhIcons.gallery)),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
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
