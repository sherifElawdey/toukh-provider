import 'package:flutter_test/flutter_test.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/core/router/provider_redirect.dart';
import 'package:toukh_provider/domain/entities/company_courier_stats.dart';
import 'package:toukh_provider/domain/entities/delivery_company.dart';
import 'package:toukh_provider/domain/entities/provider_account_status.dart';
import 'package:toukh_provider/features/delivery_company/cubit/company_orders_cubit.dart';

DeliveryCompany _company({
  required ProviderAccountStatus status,
  bool phoneVerified = true,
}) {
  return DeliveryCompany(
    uid: 'co1',
    companyName: 'Fast Fleet',
    managerName: 'Mona',
    phone: '201012345678',
    email: 'provider201012345678@toukh.com',
    phoneVerified: phoneVerified,
    status: status,
    lat: 30.4,
    lng: 31.2,
    address: 'Toukh',
  );
}

void main() {
  group('resolveCompanyRedirect', () {
    test('unverified phone goes to verify-phone, sign-up review may stay', () {
      final c = _company(
        status: ProviderAccountStatus.unverified,
        phoneVerified: false,
      );
      expect(
        resolveCompanyRedirect(AppRoutes.home, c),
        AppRoutes.accountVerifyPhone,
      );
      expect(
        resolveCompanyRedirect(AppRoutes.registerCompanyReview, c),
        isNull,
      );
      expect(resolveCompanyRedirect(AppRoutes.verifyOtp, c), isNull);
    });

    test('verified but not active waits on the status screen', () {
      final c = _company(status: ProviderAccountStatus.unverified);
      expect(
        resolveCompanyRedirect(AppRoutes.home, c),
        AppRoutes.companyStatus,
      );
      expect(resolveCompanyRedirect(AppRoutes.companyStatus, c), isNull);
    });

    test('active companies use the shell tabs and company pages only', () {
      final c = _company(status: ProviderAccountStatus.active);
      for (final tab in [
        AppRoutes.home,
        AppRoutes.orders,
        AppRoutes.menu,
        AppRoutes.settings,
        AppRoutes.companyAccount,
        AppRoutes.companyEarnings,
        AppRoutes.aboutApp,
      ]) {
        expect(resolveCompanyRedirect(tab, c), isNull, reason: tab);
      }
      // Shop-only pages bounce back to the company home tab.
      for (final shopOnly in [
        AppRoutes.wallet,
        AppRoutes.revenues,
        AppRoutes.reviews,
        AppRoutes.accountDetails,
        AppRoutes.companyStatus,
        '/orders/o1',
      ]) {
        expect(
          resolveCompanyRedirect(shopOnly, c),
          AppRoutes.home,
          reason: shopOnly,
        );
      }
      expect(
        resolveCompanyRedirect(AppRoutes.companyCourierPath('d1'), c),
        isNull,
      );
    });

    test('blocked companies see the status screen', () {
      final c = _company(status: ProviderAccountStatus.blocked);
      expect(
        resolveCompanyRedirect(AppRoutes.home, c),
        AppRoutes.companyStatus,
      );
    });
  });

  test('DeliveryCompany never registers itself as active', () {
    final map = _company(status: ProviderAccountStatus.active).toCreateMap();
    expect(map['status'], 'unverified');
    expect(map['phoneVerified'], false);
    expect(map.containsKey('password'), isFalse);
  });

  test('CourierStats parses the callable payload', () {
    final stats = CourierStats.fromMap({
      'today': {
        'orders': 2,
        'cancelled': 1,
        'earningsEgp': 70,
        'distanceMeters': 10000,
      },
      'week': {'orders': 3},
      'month': {'orders': 4, 'earningsEgp': 115.5},
      'daily': [
        {'day': '2026-10-14', 'orders': 1},
        {'day': '2026-10-15', 'orders': 2},
        {'day': 'bad'},
      ],
      'weekly': [
        {'weekStart': '2026-09-24', 'orders': 1},
      ],
      'breakdown': {'ride': 1, 'restaurants': 3, 'other': 0},
      'activeJobs': [
        {'id': 'r1', 'type': 'ride', 'status': 'in_progress', 'feeEgp': 35},
      ],
    });
    expect(stats.today.orders, 2);
    expect(stats.today.distanceKm, 10);
    expect(stats.month.earningsEgp, 115.5);
    expect(stats.daily.length, 2);
    expect(stats.daily.last.date, DateTime(2026, 10, 15));
    expect(stats.weekly.single.summary.orders, 1);
    expect(stats.breakdown.map((e) => e.key), ['restaurants', 'ride']);
    expect(stats.activeJobs.single.isRide, isTrue);
  });

  test('FleetOverview flattens active jobs with courier names', () {
    final o = FleetOverview.fromMap({
      'totals': {'orders': 5, 'earningsEgp': 120},
      'couriers': {
        'd1': {
          'name': 'Ali',
          'today': {'orders': 3},
          'activeJobs': [
            {
              'id': 't1',
              'type': 'delivery',
              'startedAt': '2026-10-15T08:00:00Z',
            },
          ],
        },
        'd2': {
          'name': 'Sara',
          'today': {'orders': 2},
          'activeJobs': [],
        },
      },
    });
    expect(o.totals.orders, 5);
    expect(o.todayByCourier['d2']?.orders, 2);
    expect(o.activeJobs.single.courierName, 'Ali');
    expect(o.activeJobs.single.courierId, 'd1');
  });

  test('CompanyOrder and CompanyOrdersState filter by status and text', () {
    final orders = [
      {
        'id': 'live',
        'type': 'ride',
        'status': 'in_progress',
        'active': true,
        'courierName': 'Ali',
        'at': '2026-10-15T09:00:00Z',
      },
      {
        'id': 'o1',
        'type': 'delivery',
        'status': 'delivered',
        'feeEgp': 25,
        'courierName': 'Sara',
        'pickupLabel': 'Bakery',
      },
      {
        'id': 'c1',
        'type': 'ride',
        'status': 'cancelled',
        'cancelled': true,
        'courierName': 'Ali',
      },
    ].map(CompanyOrder.fromMap).toList();
    expect(orders.first.isRide, isTrue);
    expect(orders.first.at, isNotNull);
    expect(orders[1].delivered, isTrue);
    expect(orders[1].feeEgp, 25);

    final state = CompanyOrdersState(loading: false, orders: orders);
    expect(state.count(CompanyOrdersFilter.active), 1);
    expect(state.count(CompanyOrdersFilter.delivered), 1);
    expect(state.count(CompanyOrdersFilter.cancelled), 1);
    expect(state.copyWith(query: 'bak').visible.map((o) => o.id), ['o1']);
    expect(
      state
          .copyWith(filter: CompanyOrdersFilter.cancelled, query: 'ali')
          .visible
          .map((o) => o.id),
      ['c1'],
    );
  });

  test('CompanyEarnings parses the callable payload', () {
    final e = CompanyEarnings.fromMap({
      'today': {'earningsEgp': 25},
      'week': {'earningsEgp': 85},
      'month': {'orders': 2, 'earningsEgp': 85},
      'daily': [
        {'day': '2026-10-15', 'orders': 1, 'earningsEgp': 25},
      ],
      'couriers': [
        {
          'courierId': 'd2',
          'name': 'Sara',
          'month': {'earningsEgp': 60},
        },
      ],
    });
    expect(e.week.earningsEgp, 85);
    expect(e.daily.single.summary.earningsEgp, 25);
    expect(e.couriers.single.courierId, 'd2');
    expect(e.couriers.single.month.earningsEgp, 60);
  });
}
