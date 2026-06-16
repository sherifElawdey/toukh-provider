import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:toukh_provider/core/notifications/provider_order_alert_controller.dart';
import 'package:toukh_provider/domain/repositories/provider_orders_repository.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/orders/cubit/provider_orders_state.dart';
import 'package:toukh_ui/toukh_ui.dart';

export 'provider_orders_state.dart' show ProviderOrdersState;

class ProviderOrdersCubit extends Cubit<ProviderOrdersState> {
  ProviderOrdersCubit({
    required AuthCubit authCubit,
    required ProviderOrdersRepository ordersRepository,
  })  : _authCubit = authCubit,
        _ordersRepository = ordersRepository,
        super(const ProviderOrdersState());

  final AuthCubit _authCubit;
  final ProviderOrdersRepository _ordersRepository;

  StreamSubscription<List<MasterOrder>>? _ordersSub;
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
    emit(state.copyWith(loading: true, providerUid: uid, clearError: true));

    _ordersSub = _ordersRepository.watchOrders(uid).listen(
      (orders) {
        _maybeShowIncomingOrderAlerts(uid, orders);
        emit(state.copyWith(loading: false, orders: orders, clearError: true));
      },
      onError: (Object e) {
        emit(state.copyWith(
          loading: false,
          errorMessage: _ordersStreamErrorMessage(e),
        ));
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
    if (_findRow(orderId) == null) return;

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

  Future<void> approvePharmacyRequest({
    required String orderId,
    required String pharmacistNote,
    required List<String> approvedItemIds,
    required double quotedSubtotalEgp,
    required double quotedDeliveryFeeEgp,
  }) async {
    final auth = _authCubit.state;
    if (auth is! Authenticated) return;
    await _runAction(
      orderId,
      () => _ordersRepository.approvePharmacyRequest(
        providerId: auth.user.uid,
        masterOrderId: orderId,
        pharmacistNote: pharmacistNote,
        approvedItemIds: approvedItemIds,
        quotedSubtotalEgp: quotedSubtotalEgp,
        quotedDeliveryFeeEgp: quotedDeliveryFeeEgp,
      ),
    );
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

  ProviderMasterOrderRow? orderById(String id) => _findRow(id);

  ProviderMasterOrderRow? _findRow(String id) {
    final uid = state.providerUid;
    if (uid == null) return null;
    for (final m in state.orders) {
      if (m.id == id && m.hasProviderSlice(uid)) {
        return ProviderMasterOrderRow.fromMaster(m, uid);
      }
    }
    return null;
  }

  static String _ordersStreamErrorMessage(Object e) {
    final text = e.toString();
    if (text.contains('FAILED_PRECONDITION') ||
        text.contains('requires an index')) {
      return 'Orders are loading — Firestore index is building. Try again shortly.';
    }
    return text;
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

  void _maybeShowIncomingOrderAlerts(String providerId, List<MasterOrder> orders) {
    if (!_ordersStreamPrimed) {
      _ordersStreamPrimed = true;
      for (final master in orders) {
        if (!master.hasProviderSlice(providerId)) continue;
        if (master.globalStatus.isTerminal) continue;
        final slice = master.sliceFor(providerId);
        if (slice != null && slice.isIncoming) {
          _alertedIncomingOrderIds.add(master.id);
        }
      }
      return;
    }

    for (final master in orders) {
      if (!master.hasProviderSlice(providerId)) continue;
      if (master.globalStatus.isTerminal) continue;
      final slice = master.sliceFor(providerId);
      if (slice == null || !slice.isIncoming) continue;
      if (_alertedIncomingOrderIds.contains(master.id)) continue;
      _alertedIncomingOrderIds.add(master.id);

      final notification = ToukhOrderNotificationTemplates.notificationFromProviderOrder(
        notificationId: master.id,
        order: _sliceToNotificationMap(master, slice),
        providerId: providerId,
        orderId: master.id,
      );
      ProviderOrderAlertController.instance.show(notification);
    }
  }

  Map<String, dynamic> _sliceToNotificationMap(
    MasterOrder master,
    ProviderOrderSlice slice,
  ) {
    final map = <String, dynamic>{
      'customerId': slice.customerId,
      'masterOrderId': master.id,
      'orderPrice': slice.orderPriceEgp,
      'deliveryPrice': slice.deliveryFeeEgp,
      'totalEgp': slice.totalEgp,
      'items': [
        for (final item in slice.items)
          {
            'title': item.name,
            'quantity': item.quantity,
            'lineTotalEgp': item.lineTotalEgp,
          },
      ],
    };
    if (providerCanViewCustomerContact(master, slice)) {
      final name = slice.customerName ?? master.customerName;
      if (name != null && name.trim().isNotEmpty) {
        map['customerName'] = name;
      }
    }
    return map;
  }

  @override
  Future<void> close() {
    _ordersSub?.cancel();
    return super.close();
  }
}
