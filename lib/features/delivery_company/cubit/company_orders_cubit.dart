import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:toukh_provider/domain/entities/company_courier_stats.dart';
import 'package:toukh_provider/domain/repositories/delivery_company_repository.dart';

enum CompanyOrdersFilter { all, active, delivered, cancelled }

class CompanyOrdersState extends Equatable {
  const CompanyOrdersState({
    this.loading = true,
    this.failed = false,
    this.orders = const [],
    this.days = 1,
    this.filter = CompanyOrdersFilter.all,
    this.query = '',
  });

  final bool loading;
  final bool failed;

  /// Everything the server returned for [days]; live jobs first.
  final List<CompanyOrder> orders;

  /// 1 = today, 7, or 30.
  final int days;
  final CompanyOrdersFilter filter;

  /// Matches courier name, pickup or drop-off.
  final String query;

  int count(CompanyOrdersFilter f) =>
      orders.where((o) => _matches(o, f)).length;

  List<CompanyOrder> get visible {
    final q = query.trim().toLowerCase();
    return orders.where((o) {
      if (!_matches(o, filter)) return false;
      if (q.isEmpty) return true;
      return [
        o.courierName,
        o.pickupLabel,
        o.dropoffLabel,
        o.orderId,
      ].whereType<String>().any((s) => s.toLowerCase().contains(q));
    }).toList();
  }

  static bool _matches(CompanyOrder o, CompanyOrdersFilter f) => switch (f) {
    CompanyOrdersFilter.all => true,
    CompanyOrdersFilter.active => o.active,
    CompanyOrdersFilter.delivered => o.delivered,
    CompanyOrdersFilter.cancelled => o.cancelled,
  };

  CompanyOrdersState copyWith({
    bool? loading,
    bool? failed,
    List<CompanyOrder>? orders,
    int? days,
    CompanyOrdersFilter? filter,
    String? query,
  }) {
    return CompanyOrdersState(
      loading: loading ?? this.loading,
      failed: failed ?? this.failed,
      orders: orders ?? this.orders,
      days: days ?? this.days,
      filter: filter ?? this.filter,
      query: query ?? this.query,
    );
  }

  @override
  List<Object?> get props => [loading, failed, orders, days, filter, query];
}

class CompanyOrdersCubit extends Cubit<CompanyOrdersState> {
  CompanyOrdersCubit(this._repo) : super(const CompanyOrdersState()) {
    load();
  }

  final DeliveryCompanyRepository _repo;
  int _request = 0;

  Future<void> load() async {
    final request = ++_request;
    emit(state.copyWith(loading: true, failed: false));
    try {
      final orders = await _repo.fetchOrders(days: state.days);
      if (isClosed || request != _request) return;
      emit(state.copyWith(loading: false, orders: orders));
    } catch (e) {
      debugPrint('CompanyOrdersCubit: load failed: $e');
      if (isClosed || request != _request) return;
      emit(state.copyWith(loading: false, failed: true));
    }
  }

  void setDays(int days) {
    if (days == state.days) return;
    emit(state.copyWith(days: days));
    load();
  }

  void setFilter(CompanyOrdersFilter filter) =>
      emit(state.copyWith(filter: filter));

  void setQuery(String query) => emit(state.copyWith(query: query));
}
