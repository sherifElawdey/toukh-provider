import 'package:toukh_ui/toukh_ui.dart';
import 'package:toukh_provider/domain/entities/provider_dashboard_order.dart';
import 'package:toukh_provider/domain/entities/provider_review_summary.dart';

/// Demo dashboard payload for debug/profile when Firestore has no orders.
abstract final class ProviderDashboardMockSeed {
  static List<ProviderReviewSummary> get reviews {
    final now = DateTime.now();
    return [
      ProviderReviewSummary(
        id: 'r1',
        rating: 5,
        comment: 'Fresh food and fast preparation. Highly recommended.',
        authorName: 'Layla H.',
        createdAt: now.subtract(const Duration(days: 2, hours: 4)),
      ),
      ProviderReviewSummary(
        id: 'r2',
        rating: 4,
        comment: 'Great portions. Packaging could be tighter.',
        authorName: 'Karim A.',
        createdAt: now.subtract(const Duration(days: 6)),
      ),
      ProviderReviewSummary(
        id: 'r3',
        rating: 5,
        comment: null,
        authorName: 'Nour',
        createdAt: now.subtract(const Duration(days: 11)),
      ),
    ];
  }

  static List<ProviderOrderDashboard> get orders {
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    final out = <ProviderOrderDashboard>[];

    void addGenerated({
      required int seq,
      required DateTime created,
      required OrderStatus status,
      required String wire,
      required double total,
      String? customer,
      List<ProviderOrderLineItem>? items,
      DateTime? acceptedAt,
      DateTime? deliveredAt,
    }) {
      out.add(
        ProviderOrderDashboard(
          id: 'mock-$seq',
          status: status,
          statusWire: wire,
          createdAt: created,
          acceptedAt: acceptedAt,
          deliveredAt: deliveredAt,
          totalEgp: total,
          customerName: customer,
          items: items ??
              [
                ProviderOrderLineItem(
                  itemId: 'demo-item-${seq % 5}',
                  name: _demoItemNames[seq % _demoItemNames.length],
                  quantity: 1 + (seq % 3),
                  lineTotalEgp: total,
                ),
              ],
        ),
      );
    }

    var seq = 0;

    // In-progress strip (today)
    addGenerated(
      seq: ++seq,
      created: today.subtract(const Duration(minutes: 18)),
      status: OrderStatus.placed,
      wire: 'placed',
      total: 94,
      customer: 'Omar K.',
      acceptedAt: null,
    );
    addGenerated(
      seq: ++seq,
      created: today.subtract(const Duration(minutes: 42)),
      status: OrderStatus.accepted,
      wire: 'preparing',
      total: 156,
      customer: 'Sara M.',
      acceptedAt: today.subtract(const Duration(minutes: 35)),
      items: [
        const ProviderOrderLineItem(
          itemId: 'demo-item-1',
          name: 'Classic foul',
          quantity: 2,
          lineTotalEgp: 96,
        ),
        const ProviderOrderLineItem(
          itemId: 'demo-item-2',
          name: 'Taameya plate',
          quantity: 1,
          lineTotalEgp: 60,
        ),
      ],
    );
    addGenerated(
      seq: ++seq,
      created: today.subtract(const Duration(hours: 1, minutes: 10)),
      status: OrderStatus.pickedUp,
      wire: 'picked_up',
      total: 72,
      customer: 'Youssef',
      acceptedAt: today.subtract(const Duration(minutes: 50)),
    );

    // Historical volume for charts / bestsellers
    for (var dayOffset = 0; dayOffset < 32; dayOffset++) {
      final bucketCount = 2 + (dayOffset % 5);
      for (var k = 0; k < bucketCount; k++) {
        final created = dayStart
            .subtract(Duration(days: dayOffset, hours: k * 3))
            .add(Duration(minutes: (seq * 7) % 120));
        final delivered = dayOffset >= 1;
        if (delivered) {
          addGenerated(
            seq: ++seq,
            created: created,
            status: OrderStatus.delivered,
            wire: 'delivered',
            total: 45 + (seq % 18) * 7.5,
            customer: 'Guest ${seq % 40}',
            acceptedAt: created.add(const Duration(minutes: 4)),
            deliveredAt: created.add(Duration(minutes: 28 + seq % 40)),
            items: [
              ProviderOrderLineItem(
                itemId: 'demo-item-${seq % 5}',
                name: _demoItemNames[seq % _demoItemNames.length],
                quantity: 1 + (seq % 2),
                lineTotalEgp: 45 + (seq % 18) * 7.5,
              ),
            ],
          );
        } else {
          addGenerated(
            seq: ++seq,
            created: created,
            status: OrderStatus.accepted,
            wire: 'accepted',
            total: 60 + (seq % 12) * 5,
            acceptedAt: created.add(const Duration(minutes: 2)),
          );
        }
      }
    }

    return out;
  }

  static const _demoItemNames = [
    'Classic foul',
    'Taameya plate',
    'Cheese trio',
    'Ful medames XL',
    'Breakfast combo',
  ];
}
