import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:toukh_provider/core/firebase/app_firebase_errors.dart';
import 'package:toukh_provider/domain/entities/dashboard_firestore_payload.dart';
import 'package:toukh_provider/domain/entities/provider_dashboard_order.dart';
import 'package:toukh_provider/domain/entities/provider_profile.dart';
import 'package:toukh_provider/domain/repositories/provider_dashboard_repository.dart';
import 'package:toukh_provider/domain/repositories/provider_menu_repository.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/home/cubit/home_dashboard_state.dart';

class HomeDashboardCubit extends Cubit<HomeDashboardState> {
  HomeDashboardCubit({
    required AuthCubit authCubit,
    required ProviderDashboardRepository dashboardRepository,
    required ProviderMenuRepository menuRepository,
  })  : _authCubit = authCubit,
        _dashboardRepository = dashboardRepository,
        _menuRepository = menuRepository,
        super(HomeDashboardState.initial());

  final AuthCubit _authCubit;
  final ProviderDashboardRepository _dashboardRepository;
  final ProviderMenuRepository _menuRepository;

  StreamSubscription<AuthState>? _authSub;
  StreamSubscription<DashboardFirestorePayload>? _dashSub;
  StreamSubscription<ProviderMenuSnapshot>? _menuSub;

  DashboardFirestorePayload? _lastPayload;
  String? _boundDashboardUid;
  bool _hasMenuItems = false;

  void start() {
    _authSub?.cancel();
    _authSub = _authCubit.stream.listen(_onAuth);
    _onAuth(_authCubit.state);
  }

  void _onAuth(AuthState auth) {
    if (auth is! Authenticated) {
      _boundDashboardUid = null;
      _dashSub?.cancel();
      _dashSub = null;
      _menuSub?.cancel();
      _menuSub = null;
      _lastPayload = null;
      _hasMenuItems = false;
      emit(HomeDashboardState.initial().copyWith(loading: false, authenticated: false));
      return;
    }

    final uid = auth.user.uid;

    if (_boundDashboardUid != uid) {
      _boundDashboardUid = uid;
      _dashSub?.cancel();
      _dashSub = null;
      _menuSub?.cancel();
      _menuSub = null;
      _lastPayload = null;
      _hasMenuItems = false;

      _bindMenuStream(uid, auth.profile.isRestaurantShop);

      emit(
        HomeDashboardState.initial().copyWith(
          authenticated: true,
          providerDisplayName: _greetingName(auth.profile),
          walletBalanceEgp: auth.profile.walletBalanceEgp ?? 0,
          walletPendingEgp: auth.profile.walletPendingEgp,
          showMenuInsights: auth.profile.isRestaurantShop && _hasMenuItems,
          loading: true,
          clearError: true,
        ),
      );

      _dashSub = _dashboardRepository.watchFirestorePayload(uid).listen(
        (payload) {
          _lastPayload = payload;
          final current = _authCubit.state;
          if (current is! Authenticated) return;
          emit(_compute(current.profile, payload, state.chartPeriod));
        },
        onError: (Object e, StackTrace st) {
          emit(
            state.copyWith(
              loading: false,
              errorMessage: appFirebaseError(e),
            ),
          );
        },
      );
    } else {
      if (_lastPayload != null) {
        emit(_compute(auth.profile, _lastPayload!, state.chartPeriod));
      } else {
        emit(
          state.copyWith(
            authenticated: true,
            loading: true,
            providerDisplayName: _greetingName(auth.profile),
            walletBalanceEgp: auth.profile.walletBalanceEgp ?? 0,
            walletPendingEgp: auth.profile.walletPendingEgp,
            showMenuInsights: auth.profile.isRestaurantShop && _hasMenuItems,
            clearError: true,
          ),
        );
      }
    }
  }

  void setChartPeriod(DashboardChartPeriod period) {
    final auth = _authCubit.state;
    final payload = _lastPayload;
    if (auth is! Authenticated || payload == null) return;
    emit(_compute(auth.profile, payload, period));
  }

  /// Re-subscribes to Firestore after a stream error.
  void retry() {
    final auth = _authCubit.state;
    if (auth is! Authenticated) return;
    _dashSub?.cancel();
    _dashSub = null;
    _lastPayload = null;
    _boundDashboardUid = null;
    _onAuth(auth);
  }

  HomeDashboardState _compute(
    ProviderProfile profile,
    DashboardFirestorePayload payload,
    DashboardChartPeriod chartPeriod,
  ) {
    final orders = payload.orders;
    final reviews = payload.reviews;

    final inProgress = orders.where((o) => o.isInProgress).toList()
      ..sort(
        (a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
              a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
            ),
      );

    final weekOrders = _ordersInRollingWindow(orders, 7);
    final monthOrders = _ordersInRollingWindow(orders, 30);

    final weekMetrics = _metrics(weekOrders);
    final monthMetrics = _metrics(monthOrders);
    final todayMetrics = _metrics(_ordersToday(orders));

    final periodDays = chartPeriod == DashboardChartPeriod.week ? 7 : 30;
    final chartBuckets = _buildBucketsFilled(
      periodDays,
      _ordersInRollingWindow(orders, periodDays),
    );

    final bestsellers = profile.isRestaurantShop && _hasMenuItems
        ? _bestsellers(orders, 30)
        : <BestsellerRow>[];

    final visibleReviews = reviews.take(8).toList();

    return HomeDashboardState(
      loading: false,
      authenticated: true,
      providerDisplayName: _greetingName(profile),
      orders: orders,
      reviews: reviews,
      chartPeriod: chartPeriod,
      walletBalanceEgp: profile.walletBalanceEgp ?? 0,
      walletPendingEgp: profile.walletPendingEgp,
      showMenuInsights: profile.isRestaurantShop && _hasMenuItems,
      inProgressOrders: inProgress,
      weekMetrics: weekMetrics,
      monthMetrics: monthMetrics,
      todayMetrics: todayMetrics,
      chartBuckets: chartBuckets,
      bestsellers: bestsellers,
      visibleReviews: visibleReviews,
    );
  }

  static String _greetingName(ProviderProfile profile) {
    final raw = profile.name.trim();
    if (raw.isEmpty) return profile.displayName;
    final parts = raw.split(RegExp(r'\s+'));
    return parts.first;
  }

  static List<ProviderOrderDashboard> _ordersInRollingWindow(
    List<ProviderOrderDashboard> all,
    int days,
  ) {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    return all.where((o) {
      final c = o.createdAt;
      if (c == null) return false;
      return !c.isBefore(start);
    }).toList();
  }

  static List<ProviderOrderDashboard> _ordersToday(
    List<ProviderOrderDashboard> all,
  ) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    return all.where((o) {
      final c = o.createdAt;
      if (c == null) return false;
      return !c.isBefore(todayStart) && c.isBefore(tomorrowStart);
    }).toList();
  }

  static DashboardPeriodMetrics _metrics(List<ProviderOrderDashboard> window) {
    final placed = window.length;
    final denomPool =
        window.where((o) => !o.isCancelled && o.reachedAcceptedStage).toList();
    final denom = denomPool.length;
    final completed = denomPool.where((o) => o.isDelivered).length;
    final ratio = denom == 0 ? 0.0 : completed / denom;
    final revenue =
        window.where((o) => o.isDelivered).fold<double>(0, (a, o) => a + o.totalEgp);
    final canceled = window.where((o) => o.isCancelled).length;
    return DashboardPeriodMetrics(
      ordersPlaced: placed,
      completionRatio: ratio,
      revenueEgp: revenue,
      denominatorForCompletion: denom,
      completedCount: completed,
      ordersCanceled: canceled,
    );
  }

  static List<OrderRateBucket> _buildBucketsFilled(
    int daysBack,
    List<ProviderOrderDashboard> windowOrders,
  ) {
    final end = DateTime.now();
    final todayStart = DateTime(end.year, end.month, end.day);
    final startDay = todayStart.subtract(Duration(days: daysBack - 1));

    final counts = <DateTime, int>{};
    for (final o in windowOrders) {
      final c = o.createdAt;
      if (c == null) continue;
      final day = DateTime(c.year, c.month, c.day);
      if (day.isBefore(startDay)) continue;
      if (day.isAfter(todayStart)) continue;
      counts[day] = (counts[day] ?? 0) + 1;
    }

    final out = <OrderRateBucket>[];
    for (var i = 0; i < daysBack; i++) {
      final d = startDay.add(Duration(days: i));
      out.add(OrderRateBucket(dayStart: d, count: counts[d] ?? 0));
    }
    return out;
  }

  static List<BestsellerRow> _bestsellers(List<ProviderOrderDashboard> all, int days) {
    final window = _ordersInRollingWindow(all, days).where((o) => o.isDelivered).toList();
    final agg = <String, ({String label, int qty, double rev})>{};

    for (final o in window) {
      if (o.items.isEmpty) {
        final key = 'whole-${o.id}';
        agg[key] = (label: o.customerName ?? '—', qty: 1, rev: o.totalEgp);
        continue;
      }
      for (final line in o.items) {
        final key = line.itemId ?? line.name.toLowerCase();
        final prev = agg[key];
        final qty = (prev?.qty ?? 0) + line.quantity;
        final rev = (prev?.rev ?? 0) + line.lineTotalEgp;
        agg[key] = (label: line.name, qty: qty, rev: rev);
      }
    }

    final rows = agg.entries
        .map(
          (e) => BestsellerRow(
            label: e.value.label,
            itemId: e.key.startsWith('whole-') ? null : e.key,
            unitsSold: e.value.qty,
            revenueEgp: e.value.rev,
          ),
        )
        .toList()
      ..sort((a, b) => b.unitsSold.compareTo(a.unitsSold));

    return rows.take(10).toList();
  }

  void _bindMenuStream(String uid, bool isRestaurantShop) {
    _menuSub?.cancel();
    _menuSub = null;
    if (!isRestaurantShop) {
      _hasMenuItems = false;
      return;
    }
    _menuSub = _menuRepository.watchMenu(uid).listen((snapshot) {
      _hasMenuItems = snapshot.items.isNotEmpty;
      final payload = _lastPayload;
      final auth = _authCubit.state;
      if (payload != null && auth is Authenticated) {
        emit(_compute(auth.profile, payload, state.chartPeriod));
      } else if (auth is Authenticated) {
        emit(
          state.copyWith(
            showMenuInsights: auth.profile.isRestaurantShop && _hasMenuItems,
          ),
        );
      }
    });
  }

  @override
  Future<void> close() {
    _authSub?.cancel();
    _dashSub?.cancel();
    _menuSub?.cancel();
    return super.close();
  }
}
