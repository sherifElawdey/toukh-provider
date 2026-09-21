import 'package:toukh_provider/domain/entities/provider_home_service_request.dart';
import 'package:toukh_provider/domain/repositories/provider_gallery_repository.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// In-memory showcase samples for requests, notifications, and gallery.
abstract final class ProviderShowcaseMocks {
  ProviderShowcaseMocks._();

  static List<MasterOrder> ordersFor(String providerUid) {
    final now = DateTime.now();
    final delivery = const Location(
      lat: 30.05,
      lng: 31.24,
      label: 'Customer',
      formattedAddress: '15 Nile St, Cairo',
    );
    final store = const Location(
      lat: 30.0444,
      lng: 31.2357,
      label: 'Store',
      formattedAddress: 'Downtown Cairo',
    );

    MasterOrder build({
      required String id,
      required String status,
      required String providerState,
      required ProviderSubState subState,
      required double price,
      required List<ProviderOrderSliceLineItem> items,
      DateTime? createdAt,
    }) {
      final created = createdAt ?? now.subtract(const Duration(minutes: 12));
      final fee = 25.0;
      final total = price + fee;
      return MasterOrder(
        id: id,
        clientId: 'mock-customer',
        globalStatus: GlobalOrderStatus.pending,
        customerName: 'Sara Ahmed',
        customerPhone: '01001234567',
        deliveryAddress: delivery,
        providerIds: [providerUid],
        providerStatusMap: {providerUid: subState},
        providerOrderRefs: [
          ProviderOrderRef(
            providerId: providerUid,
            providerOrderId: id,
            providerState: subState,
            fulfillmentMode: FulfillmentMode.courier,
            orderPriceEgp: price,
            deliveryFeeEgp: fee,
          ),
        ],
        providerSlices: {
          providerUid: ProviderOrderSlice(
            providerId: providerUid,
            status: status,
            providerState: providerState,
            fulfillmentMode: FulfillmentMode.courier,
            customerName: 'Sara Ahmed',
            customerPhone: '01001234567',
            storeLocation: store,
            deliveryAddress: delivery,
            orderPriceEgp: price,
            deliveryFeeEgp: fee,
            totalEgp: total,
            createdAt: created,
            items: items,
          ),
        },
        subtotalEgp: price,
        deliveryFeeEgp: fee,
        totalEgp: total,
        paymentMethod: 'cash',
        createdAt: created,
        updatedAt: created,
      );
    }

    return [
      build(
        id: 'mock_order_incoming',
        status: ProviderOrderStatusWire.placed,
        providerState: 'pending',
        subState: ProviderSubState.pending,
        price: 145,
        items: const [
          ProviderOrderSliceLineItem(
            name: 'Grilled chicken meal',
            quantity: 1,
            lineTotalEgp: 85,
          ),
          ProviderOrderSliceLineItem(
            name: 'Soft drink',
            quantity: 2,
            lineTotalEgp: 40,
          ),
        ],
      ),
      build(
        id: 'mock_order_preparing',
        status: ProviderOrderStatusWire.accepted,
        providerState: 'preparing',
        subState: ProviderSubState.preparing,
        price: 120,
        createdAt: now.subtract(const Duration(minutes: 35)),
        items: const [
          ProviderOrderSliceLineItem(
            name: 'Margherita pizza',
            quantity: 1,
            lineTotalEgp: 120,
          ),
        ],
      ),
      build(
        id: 'mock_order_ready',
        status: ProviderOrderStatusWire.readyForPickup,
        providerState: 'ready_for_pickup',
        subState: ProviderSubState.readyForPickup,
        price: 95,
        createdAt: now.subtract(const Duration(hours: 1)),
        items: const [
          ProviderOrderSliceLineItem(
            name: 'Beef burger',
            quantity: 1,
            lineTotalEgp: 95,
          ),
        ],
      ),
    ];
  }

  static List<ProviderHomeServiceRequest> requestsFor(String providerId) {
    final now = DateTime.now();
    return [
      ProviderHomeServiceRequest(
        id: 'mock_hs_pending',
        userId: 'mock-user-1',
        providerId: providerId,
        categoryId: 'hs_cleaning',
        categoryTitle: 'Home cleaning',
        status: 'pending',
        createdAt: now.subtract(const Duration(minutes: 20)),
        customerName: 'Omar Hassan',
        customerPhone: '01009876543',
        addressFormatted: 'Nasr City, Cairo',
        addressLat: 30.06,
        addressLng: 31.33,
        note: 'Need deep clean for 3 rooms.',
        preferredTimeRaw: 'morning',
        clientPriceEgp: 350,
      ),
      ProviderHomeServiceRequest(
        id: 'mock_hs_accepted',
        userId: 'mock-user-2',
        providerId: providerId,
        categoryId: 'hs_ac',
        categoryTitle: 'AC maintenance',
        status: 'accepted',
        createdAt: now.subtract(const Duration(hours: 5)),
        customerName: 'Mona Ali',
        customerPhone: '01005551234',
        addressFormatted: 'Maadi, Cairo',
        addressLat: 29.96,
        addressLng: 31.25,
        note: 'Split unit not cooling.',
        quotedPriceEgp: 280,
        scheduledAt: now.add(const Duration(days: 1, hours: 2)),
        preferredTimeRaw: 'evening',
      ),
      ProviderHomeServiceRequest(
        id: 'mock_hs_completed',
        userId: 'mock-user-3',
        providerId: providerId,
        categoryId: 'hs_plumbing',
        categoryTitle: 'Plumbing',
        status: 'completed',
        createdAt: now.subtract(const Duration(days: 2)),
        completedAt: now.subtract(const Duration(days: 1)),
        customerName: 'Youssef Nabil',
        addressFormatted: 'Heliopolis, Cairo',
        quotedPriceEgp: 200,
        scheduledAt: now.subtract(const Duration(days: 1, hours: 3)),
      ),
    ];
  }

  static List<ToukhNotification> notifications() {
    final now = DateTime.now();
    return [
      ToukhNotification(
        id: 'mock_n1',
        title: 'New order',
        description: 'Order #mock_order_incoming is waiting for your response.',
        createdAt: now.subtract(const Duration(minutes: 8)),
        opened: false,
        type: ToukhOrderNotificationTypes.orderPlaced,
        orderId: 'mock_order_incoming',
        category: 'order',
      ),
      ToukhNotification(
        id: 'mock_n2',
        title: 'Home-service request',
        description: 'Omar Hassan requested home cleaning.',
        createdAt: now.subtract(const Duration(minutes: 25)),
        opened: false,
        category: 'home_service',
      ),
      ToukhNotification(
        id: 'mock_n3',
        title: 'Reminder',
        description: 'AC maintenance visit is scheduled for tomorrow evening.',
        createdAt: now.subtract(const Duration(hours: 3)),
        opened: true,
        openedAt: now.subtract(const Duration(hours: 2)),
        category: 'reminder',
      ),
    ];
  }

  static List<ProviderGalleryItem> gallery() {
    final now = DateTime.now();
    return [
      for (var i = 1; i <= 4; i++)
        ProviderGalleryItem(
          id: 'mock_gallery_$i',
          url: 'https://picsum.photos/seed/toukh-provider-g$i/600/600',
          fileId: 'mock_file_$i',
          fileName: 'work_$i.jpg',
          createdAt: now.subtract(Duration(days: i)),
        ),
    ];
  }
}
