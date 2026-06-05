import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:toukh_provider/core/notifications/provider_order_alert_controller.dart';
import 'package:toukh_provider/domain/entities/provider_order.dart';
import 'package:toukh_provider/domain/entities/provider_order_status_wire.dart';
import 'package:toukh_provider/domain/repositories/provider_orders_repository.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/orders/cubit/provider_orders_state.dart';
import 'package:toukh_ui/toukh_ui.dart';

export 'provider_orders_state.dart' show ProviderOrdersState;
export 'package:toukh_provider/domain/entities/provider_order.dart' show ProviderOrdersSort;

class ProviderOrdersCubit extends Cubit<ProviderOrdersState> {
  ProviderOrdersCubit({
    required AuthCubit authCubit,
    required ProviderOrdersRepository ordersRepository,
  })  : _authCubit = authCubit,
        _ordersRepository = ordersRepository,
        super(const ProviderOrdersState());

  final AuthCubit _authCubit;
  final ProviderOrdersRepository _ordersRepository;

  StreamSubscription<List<ProviderOrder>>? _ordersSub;
  String? _boundUid;
  final Set<String> _alertedIncomingOrderIds = {};
  bool _ordersStreamPrimed = false;

  void start() {
    _authCubit.stream.listen(_onAuth);
    _onAuth(_authCubit.state);
  }

  void _onAuth(AuthState auth) {
    if (auth is! Authenticated) {
      _boundUid = null;
      _alertedIncomingOrderIds.clear();
      _ordersStreamPrimed = false;
      _ordersSub?.cancel();
      _ordersSub = null;
      emit(const ProviderOrdersState(loading: false, orders: []));
      return;
    }

    final uid = auth.user.uid;
    if (_boundUid == uid) return;

    _boundUid = uid;
    _ordersSub?.cancel();
    _alertedIncomingOrderIds.clear();
    _ordersStreamPrimed = false;
    emit(state.copyWith(loading: true, clearError: true));

    _ordersSub = _ordersRepository.watchOrders(uid).listen(
      (orders) {
        _maybeShowIncomingOrderAlerts(uid, orders);
        emit(state.copyWith(loading: false, orders: orders, clearError: true));
      },
      onError: (Object e) {
        emit(state.copyWith(loading: false, errorMessage: e.toString()));
      },
    );
  }

  void setSort(ProviderOrdersSort sort) {
    emit(state.copyWith(sort: sort));
  }

  void setWithCourierOnly(bool value) {
    emit(state.copyWith(withCourierOnly: value));
  }

  Future<void> approve(String orderId) async {
    final auth = _authCubit.state;
    if (auth is! Authenticated) return;
    final order = _find(orderId);
    if (order == null) return;

    final storeDelivers = auth.profile.deliveryConfig?.offersDelivery ?? false;
    await _runAction(orderId, () => _ordersRepository.approveOrder(
          providerId: auth.user.uid,
          orderId: orderId,
          storeDelivers: storeDelivers,
        ));
  }

  Future<void> cancel(String orderId) async {
    final auth = _authCubit.state;
    if (auth is! Authenticated) return;
    await _runAction(orderId, () => _ordersRepository.cancelOrder(
          providerId: auth.user.uid,
          orderId: orderId,
        ));
  }

  Future<String?> requestDelivery({
    required String orderId,
    required Location searchCenter,
  }) async {
    final auth = _authCubit.state;
    if (auth is! Authenticated) return null;
    try {
      emit(state.copyWith(actionInFlightId: orderId));
      final requestId = await _ordersRepository.requestDelivery(
        providerId: auth.user.uid,
        orderId: orderId,
        searchCenter: searchCenter,
      );
      emit(state.copyWith(clearActionInFlight: true));
      return requestId;
    } catch (e) {
      emit(state.copyWith(
        actionInFlightId: null,
        errorMessage: e.toString(),
      ));
      return null;
    }
  }

  Future<void> markReadyForPickup(String orderId) async {
    final auth = _authCubit.state;
    if (auth is! Authenticated) return;
    await _runAction(orderId, () => _ordersRepository.markReadyForPickup(
          providerId: auth.user.uid,
          orderId: orderId,
        ));
  }

  Future<void> markStoreOutForDelivery(String orderId) async {
    final auth = _authCubit.state;
    if (auth is! Authenticated) return;
    await _runAction(orderId, () => _ordersRepository.markStoreOutForDelivery(
          providerId: auth.user.uid,
          orderId: orderId,
        ));
  }

  Future<void> confirmHandoff(String orderId) async {
    final auth = _authCubit.state;
    if (auth is! Authenticated) return;
    await _runAction(orderId, () => _ordersRepository.confirmHandoffToCourier(
          providerId: auth.user.uid,
          orderId: orderId,
        ));
  }

  ProviderOrder? orderById(String id) => _find(id);

  ProviderOrder? _find(String id) {
    for (final o in state.orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  Future<void> _runAction(String orderId, Future<void> Function() fn) async {
    try {
      emit(state.copyWith(actionInFlightId: orderId, clearError: true));
      await fn();
      emit(state.copyWith(clearActionInFlight: true));
    } catch (e) {
      emit(state.copyWith(
        clearActionInFlight: true,
        errorMessage: e.toString(),
      ));
    }
  }

  void _maybeShowIncomingOrderAlerts(String providerId, List<ProviderOrder> orders) {
    if (!_ordersStreamPrimed) {
      _ordersStreamPrimed = true;
      for (final order in orders) {
        if (ProviderOrderStatusWire.isIncoming(order.statusWire)) {
          _alertedIncomingOrderIds.add(order.id);
        }
      }
      return;
    }

    for (final order in orders) {
      if (!ProviderOrderStatusWire.isIncoming(order.statusWire)) continue;
      if (_alertedIncomingOrderIds.contains(order.id)) continue;
      _alertedIncomingOrderIds.add(order.id);

      final notification = ToukhOrderNotificationTemplates.notificationFromProviderOrder(
        notificationId: order.id,
        order: _orderToNotificationMap(order),
        providerId: providerId,
        orderId: order.id,
      );
      ProviderOrderAlertController.instance.show(notification);
    }
  }

  Map<String, dynamic> _orderToNotificationMap(ProviderOrder order) {
    return {
      'customerId': order.customerId,
      'customerName': order.customerName,
      'masterOrderId': order.masterOrderId,
      'orderPrice': order.orderPrice,
      'deliveryPrice': order.deliveryPrice,
      'totalEgp': order.totalEgp,
      'items': [
        for (final item in order.items)
          {
            'title': item.name,
            'quantity': item.quantity,
            'lineTotalEgp': item.lineTotalEgp,
          },
      ],
    };
  }

  @override
  Future<void> close() {
    _ordersSub?.cancel();
    return super.close();
  }
}
