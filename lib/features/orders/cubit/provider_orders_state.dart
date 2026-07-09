import 'package:equatable/equatable.dart';
import 'package:toukh_ui/toukh_ui.dart';

class ProviderOrdersState extends Equatable {
  const ProviderOrdersState({
    this.loading = true,
    this.orders = const [],
    this.providerUid,
    this.errorMessage,
    this.actionInFlightId,
    this.sort = ProviderOrdersSort.newest,
    this.withCourierOnly = false,
  });

  final bool loading;
  final List<MasterOrder> orders;
  final String? providerUid;
  final String? errorMessage;
  final String? actionInFlightId;
  final ProviderOrdersSort sort;
  final bool withCourierOnly;

  List<ProviderMasterOrderRow> forTab(
    ProviderOrdersTab tab, {
    OrderAcceptanceSla? acceptanceSla,
    String? serviceTypeKey,
  }) {
    final uid = providerUid;
    if (uid == null) return const [];
    var rows = ProviderMasterOrderTabFilters.forTab(orders, uid, tab);
    if (tab == ProviderOrdersTab.inProgress && withCourierOnly) {
      rows = ProviderMasterOrderTabFilters.withDeliveryPersonOnly(rows);
    }
    return ProviderMasterOrderTabFilters.applySort(
      rows,
      sort,
      tab: tab,
      sla: acceptanceSla,
      serviceTypeKey: serviceTypeKey,
    );
  }

  bool showWithCourierFilter(ProviderOrdersTab tab) {
    if (tab != ProviderOrdersTab.inProgress) return false;
    final uid = providerUid;
    if (uid == null) return false;
    return ProviderMasterOrderTabFilters.showWithCourierFilter(
      ProviderMasterOrderTabFilters.forTab(
        orders,
        uid,
        ProviderOrdersTab.inProgress,
      ),
    );
  }

  ProviderOrdersState copyWith({
    bool? loading,
    List<MasterOrder>? orders,
    String? providerUid,
    String? errorMessage,
    String? actionInFlightId,
    bool clearActionInFlight = false,
    ProviderOrdersSort? sort,
    bool? withCourierOnly,
    bool clearError = false,
  }) {
    return ProviderOrdersState(
      loading: loading ?? this.loading,
      orders: orders ?? this.orders,
      providerUid: providerUid ?? this.providerUid,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      actionInFlightId:
          clearActionInFlight ? null : (actionInFlightId ?? this.actionInFlightId),
      sort: sort ?? this.sort,
      withCourierOnly: withCourierOnly ?? this.withCourierOnly,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        orders,
        providerUid,
        errorMessage,
        actionInFlightId,
        sort,
        withCourierOnly,
      ];
}
