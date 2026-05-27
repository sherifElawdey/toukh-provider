import 'package:equatable/equatable.dart';
import 'package:toukh_provider/domain/entities/provider_order.dart';

class ProviderOrdersState extends Equatable {
  const ProviderOrdersState({
    this.loading = true,
    this.orders = const [],
    this.errorMessage,
    this.actionInFlightId,
    this.sort = ProviderOrdersSort.newest,
    this.withCourierOnly = false,
  });

  final bool loading;
  final List<ProviderOrder> orders;
  final String? errorMessage;
  final String? actionInFlightId;
  final ProviderOrdersSort sort;
  final bool withCourierOnly;

  List<ProviderOrder> forTab(ProviderOrdersTab tab) {
    var list = ProviderOrderTabFilters.forTab(orders, tab);
    if (tab == ProviderOrdersTab.inProgress && withCourierOnly) {
      list = ProviderOrderTabFilters.withDeliveryPersonOnly(list);
    }
    return ProviderOrderTabFilters.applySort(
      list,
      sort == ProviderOrdersSort.newest
          ? ProviderOrdersSort.newest
          : ProviderOrdersSort.oldest,
      tab: tab,
    );
  }

  bool showWithCourierFilter(ProviderOrdersTab tab) {
    if (tab != ProviderOrdersTab.inProgress) return false;
    return ProviderOrderTabFilters.showWithCourierFilter(
      ProviderOrderTabFilters.forTab(orders, ProviderOrdersTab.inProgress),
    );
  }

  ProviderOrdersState copyWith({
    bool? loading,
    List<ProviderOrder>? orders,
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
        errorMessage,
        actionInFlightId,
        sort,
        withCourierOnly,
      ];
}
