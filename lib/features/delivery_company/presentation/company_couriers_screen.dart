import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:toukh_provider/domain/entities/company_courier.dart';
import 'package:toukh_provider/domain/entities/delivery_company.dart';
import 'package:toukh_provider/features/delivery_company/cubit/company_fleet_cubit.dart';
import 'package:toukh_provider/features/delivery_company/presentation/widgets/company_invite_sheet.dart';
import 'package:toukh_provider/features/delivery_company/presentation/widgets/company_widgets.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

enum _CourierFilter { all, online, busy, disabled }

/// Couriers tab of a delivery company (in place of the menu / gallery tab):
/// search and filter the fleet, add couriers and answer join requests.
/// Editing a courier (enable, disable, remove) lives on the courier profile.
class CompanyCouriersScreen extends StatefulWidget {
  const CompanyCouriersScreen({
    super.key,
    required this.company,
    this.showRequests = false,
  });

  final DeliveryCompany company;

  /// Opens on the join requests (e.g. from the home banner).
  final bool showRequests;

  @override
  State<CompanyCouriersScreen> createState() => _CompanyCouriersScreenState();
}

class _CompanyCouriersScreenState extends State<CompanyCouriersScreen> {
  late bool _requests = widget.showRequests;
  _CourierFilter _filter = _CourierFilter.all;
  String _query = '';

  @override
  void didUpdateWidget(covariant CompanyCouriersScreen old) {
    super.didUpdateWidget(old);
    if (widget.showRequests && !old.showRequests) {
      setState(() => _requests = true);
    }
  }

  bool _matchesFilter(CompanyCourier c) => switch (_filter) {
    _CourierFilter.all => true,
    _CourierFilter.online => c.isAvailable,
    _CourierFilter.busy => c.isBusy,
    _CourierFilter.disabled => !c.enabled,
  };

  bool _matchesQuery(CompanyCourier c) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final digits = q.replaceAll(RegExp(r'\D'), '');
    return c.displayName.toLowerCase().contains(q) ||
        (digits.isNotEmpty && c.phone.contains(digits));
  }

  String _filterLabel(_CourierFilter f) => switch (f) {
    _CourierFilter.all => AppStrings.Company.filterAll.tr,
    _CourierFilter.online => AppStrings.Company.filterOnline.tr,
    _CourierFilter.busy => AppStrings.Company.busy.tr,
    _CourierFilter.disabled => AppStrings.Company.disabled.tr,
  };

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CompanyFleetCubit, CompanyFleetState>(
      listenWhen: (p, c) =>
          c.actionError != null && p.actionError != c.actionError,
      listener: (context, _) => AppSnack.show(
        context,
        message: AppStrings.Company.actionFailed.tr,
        state: AppSnackState.error,
        icon: ToukhIcons.error,
      ),
      builder: (context, state) {
        final members = state.members;
        final requests = state.requests.where(_matchesQuery).toList();
        final shown = members
            .where((c) => _matchesFilter(c) && _matchesQuery(c))
            .toList();
        final dateFmt = DateFormat.yMMMd(
          Localizations.localeOf(context).toLanguageTag(),
        );

        return ToukhRefresh(
          onRefresh: () => context.read<CompanyFleetCubit>().refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSizes.screenPadding.copyWith(
              top: AppSizes.spaceLg,
              bottom: AppSizes.space3xl,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: AppStrings.Company.couriersSearchHint.tr,
                        prefixIcon: Icon(ToukhIcons.search),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.spaceSm),
                  AppFilledButton(
                    text: AppStrings.Company.addCourier,
                    icon: ToukhIcons.add,
                    onTap: () => showCompanyInviteSheet(
                      context,
                      company: widget.company,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.spaceMd),
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: false,
                    label: Text(
                      '${AppStrings.Company.tabCouriers.tr} (${members.length})',
                    ),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(AppStrings.Company.tabRequests.tr),
                        if (state.requests.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Badge(label: Text('${state.requests.length}')),
                        ],
                      ],
                    ),
                  ),
                ],
                selected: {_requests},
                onSelectionChanged: (v) => setState(() => _requests = v.first),
              ),
              const SizedBox(height: AppSizes.spaceMd),
              if (state.loading)
                const Padding(
                  padding: EdgeInsets.all(AppSizes.spaceXl),
                  child: Center(child: AppLoadingMark()),
                )
              else if (_requests) ...[
                CustomText(
                  AppStrings.Company.requestsHint,
                  style: TextStyle(
                    fontSize: AppSizes.fontCaption,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: AppSizes.spaceMd),
                if (requests.isEmpty)
                  CompanyEmptyNote(
                    _query.trim().isEmpty
                        ? AppStrings.Company.noRequests
                        : AppStrings.Company.noCouriersMatch,
                    icon: ToukhIcons.group,
                  )
                else
                  for (final r in requests)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.spaceSm),
                      child: _RequestCard(
                        courier: r,
                        dateFmt: dateFmt,
                        busy: state.actionInProgress == r.uid,
                        anyBusy: state.actionInProgress != null,
                      ),
                    ),
              ] else ...[
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final f in _CourierFilter.values)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            end: AppSizes.spaceSm,
                          ),
                          child: ChoiceChip(
                            label: Text(_filterLabel(f)),
                            selected: _filter == f,
                            onSelected: (_) => setState(() => _filter = f),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.spaceMd),
                if (members.isEmpty)
                  _NoCouriersYet(company: widget.company)
                else if (shown.isEmpty)
                  CompanyEmptyNote(
                    AppStrings.Company.noCouriersMatch,
                    icon: ToukhIcons.search,
                  )
                else
                  for (final c in shown)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.spaceSm),
                      child: CompanyCourierTile(
                        courier: c,
                        ordersToday:
                            state.overview.todayByCourier[c.uid]?.orders,
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

class _NoCouriersYet extends StatelessWidget {
  const _NoCouriersYet({required this.company});

  final DeliveryCompany company;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CompanyEmptyNote(AppStrings.Company.noCouriers, icon: ToukhIcons.group),
        const SizedBox(height: AppSizes.spaceMd),
        AppOutlinedButton(
          text: AppStrings.Company.addCourier,
          icon: ToukhIcons.add,
          onTap: () => showCompanyInviteSheet(context, company: company),
        ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.courier,
    required this.dateFmt,
    required this.busy,
    required this.anyBusy,
  });

  final CompanyCourier courier;
  final DateFormat dateFmt;
  final bool busy;
  final bool anyBusy;

  Future<void> _respond(BuildContext context, {required bool accept}) async {
    final cubit = context.read<CompanyFleetCubit>();
    final ok = accept
        ? await cubit.accept(courier.uid)
        : await cubit.reject(courier.uid);
    if (!ok || !context.mounted) return;
    AppSnack.show(
      context,
      message:
          (accept
                  ? AppStrings.Company.requestAccepted
                  : AppStrings.Company.requestRejected)
              .tr,
      state: accept ? AppSnackState.success : AppSnackState.alert,
      icon: accept ? ToukhIcons.check : ToukhIcons.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.65);
    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceMd),
      decoration: ToukhCard.decoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CourierAvatar(courier: courier),
              const SizedBox(width: AppSizes.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      courier.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    CustomText(
                      [
                        courier.phone,
                        companyVehicleLabel(courier.vehicleType),
                      ].where((s) => s.isNotEmpty).join(' · '),
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                    if (courier.requestedAt != null)
                      CustomText(
                        AppStrings.Company.requestedOn.trParams({
                          'date': dateFmt.format(courier.requestedAt!),
                        }),
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (!courier.isPlatformActive) ...[
            const SizedBox(height: AppSizes.spaceSm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: CompanyChip(
                label: AppStrings.Company.awaitingAdmin.tr,
                color: AppColors.warning,
              ),
            ),
          ],
          const SizedBox(height: AppSizes.spaceMd),
          Row(
            children: [
              Expanded(
                child: AppOutlinedButton(
                  text: AppStrings.Drivers.reject.tr,
                  onTap: anyBusy
                      ? null
                      : () => _respond(context, accept: false),
                ),
              ),
              const SizedBox(width: AppSizes.spaceSm),
              Expanded(
                child: AppFilledButton(
                  text: AppStrings.Drivers.accept.tr,
                  status: busy
                      ? AppButtonStatus.loading
                      : AppButtonStatus.enabled,
                  onTap: anyBusy ? null : () => _respond(context, accept: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
