import 'toukh_notification.dart';
import 'toukh_notification_category.dart';
import 'toukh_notification_routes.dart';
import 'toukh_order_notification_types.dart';

/// Statuses that notify the order owner (customer).
abstract final class ToukhCustomerNotifyStatuses {
  ToukhCustomerNotifyStatuses._();

  static const all = {
    'accepted',
    'preparing',
    'cancelled',
    'courier_requested',
    'courier_assigned',
    'ready_for_pickup',
    'out_for_delivery',
    'picked_up',
    'delivered',
    'completed',
  };
}

abstract final class ToukhOrderNotificationTemplates {
  ToukhOrderNotificationTemplates._();

  static const _maxBodyLines = 3;

  static String? resolveCustomerId(Map<String, dynamic> order) {
    final id = order['customerId'] ?? order['clientId'];
    if (id is! String || id.trim().isEmpty) return null;
    return id.trim();
  }

  static ToukhNotificationTemplate buildProviderNewOrderTemplate({
    required Map<String, dynamic> order,
    required String providerId,
    required String orderId,
    String? customerPhotoUrl,
  }) {
    final customerName =
        _string(order['customerName']) ?? _string(order['clientName']) ?? 'عميل';
    final totals = _orderTotalsAndItems(order);
    final itemsBlock = _formatOrderLinesBlock(
      orderPrice: totals.orderPrice,
      deliveryPrice: totals.deliveryPrice,
      totalEgp: totals.totalEgp,
      mappedItems: totals.mappedItems,
    );

    final imageUrl = _string(order['customerPhotoUrl']) ?? customerPhotoUrl;

    return ToukhNotificationTemplate(
      title: 'طلب جديد · $customerName',
      description: itemsBlock,
      imageUrl: imageUrl,
      type: ToukhOrderNotificationTypes.orderPlaced,
      orderId: orderId,
      category: ToukhNotificationCategory.order,
      rootRoute: ToukhNotificationRoutes.providerOrderDetail(orderId),
      payload: {
        'orderId': orderId,
        'providerId': providerId,
        'masterOrderId': order['masterOrderId'],
        'customerId': resolveCustomerId(order),
        'customerName': customerName,
        'orderPriceEgp': totals.orderPrice,
        'deliveryPriceEgp': totals.deliveryPrice,
        'totalEgp': totals.totalEgp,
        'items': totals.mappedItems,
        'orderStatus': 'placed',
      },
    );
  }

  static ToukhNotificationTemplate buildCustomerOrderPlacedTemplate({
    required Map<String, dynamic> order,
    required String providerId,
    required String orderId,
    String? providerImageUrl,
  }) {
    final masterOrderId = _string(order['masterOrderId']);
    final customerRoute = masterOrderId != null
        ? ToukhNotificationRoutes.consumerOrderDetail(masterOrderId)
        : ToukhNotificationRoutes.consumerOrders;
    final totals = _orderTotalsAndItems(order);
    final itemsBlock = _formatOrderLinesBlock(
      orderPrice: totals.orderPrice,
      deliveryPrice: totals.deliveryPrice,
      totalEgp: totals.totalEgp,
      mappedItems: totals.mappedItems,
    );

    return ToukhNotificationTemplate(
      title: 'تم تقديم الطلب',
      description: _formatDescriptionWithHeadline(
        'تم إرسال طلبك إلى المتجر.',
        itemsBlock,
      ),
      imageUrl: providerImageUrl,
      type: ToukhOrderNotificationTypes.orderPlaced,
      orderId: orderId,
      category: ToukhNotificationCategory.order,
      rootRoute: customerRoute,
      payload: {
        'orderId': orderId,
        'providerId': providerId,
        'masterOrderId': masterOrderId,
        'orderStatus': 'placed',
        'orderPriceEgp': totals.orderPrice,
        'deliveryPriceEgp': totals.deliveryPrice,
        'totalEgp': totals.totalEgp,
        'items': totals.mappedItems,
      },
    );
  }

  static ToukhNotificationTemplate? buildCustomerStatusTemplate({
    required Map<String, dynamic> order,
    required String providerId,
    required String orderId,
    required String nextStatus,
    String? providerImageUrl,
  }) {
    if (!ToukhCustomerNotifyStatuses.all.contains(nextStatus)) return null;

    final copy = _statusCopy[nextStatus];
    if (copy == null) return null;

    final masterOrderId = _string(order['masterOrderId']);
    final customerRoute = masterOrderId != null
        ? ToukhNotificationRoutes.consumerOrderDetail(masterOrderId)
        : ToukhNotificationRoutes.consumerOrders;
    final totals = _orderTotalsAndItems(order);
    final itemsBlock = _formatOrderLinesBlock(
      orderPrice: totals.orderPrice,
      deliveryPrice: totals.deliveryPrice,
      totalEgp: totals.totalEgp,
      mappedItems: totals.mappedItems,
    );

    final payload = <String, dynamic>{
      'orderId': orderId,
      'providerId': providerId,
      'masterOrderId': masterOrderId,
      'orderStatus': nextStatus,
      'orderPriceEgp': totals.orderPrice,
      'deliveryPriceEgp': totals.deliveryPrice,
      'totalEgp': totals.totalEgp,
      'items': totals.mappedItems,
    };
    if (nextStatus == 'courier_assigned') {
      final driverId = _string(order['driverId']);
      if (driverId != null) payload['driverId'] = driverId;
    }

    return ToukhNotificationTemplate(
      title: copy.title,
      description: _formatDescriptionWithHeadline(copy.headline, itemsBlock),
      imageUrl: providerImageUrl,
      type: copy.type,
      orderId: orderId,
      category: ToukhNotificationCategory.order,
      rootRoute: customerRoute,
      payload: payload,
    );
  }

  static ToukhNotification notificationFromProviderOrder({
    required String notificationId,
    required Map<String, dynamic> order,
    required String providerId,
    required String orderId,
    String? customerPhotoUrl,
  }) {
    final template = buildProviderNewOrderTemplate(
      order: order,
      providerId: providerId,
      orderId: orderId,
      customerPhotoUrl: customerPhotoUrl,
    );
    return ToukhNotification(
      id: notificationId,
      title: template.title,
      description: template.description,
      imageUrl: template.imageUrl,
      type: template.type,
      orderId: template.orderId,
      category: template.category,
      rootRoute: template.rootRoute,
      payload: template.payload,
    );
  }

  static const _statusCopy = {
    'accepted': _StatusCopy(
      title: 'تمت الموافقة على الطلب',
      headline: 'قبل المتجر طلبك وجاري تجهيزه.',
      type: ToukhOrderNotificationTypes.orderAccepted,
    ),
    'preparing': _StatusCopy(
      title: 'تمت الموافقة على الطلب',
      headline: 'قبل المتجر طلبك وجاري تجهيزه.',
      type: ToukhOrderNotificationTypes.orderAccepted,
    ),
    'cancelled': _StatusCopy(
      title: 'تم إلغاء الطلب',
      headline: 'لم يتمكن المتجر من تنفيذ طلبك.',
      type: ToukhOrderNotificationTypes.orderCancelled,
    ),
    'courier_requested': _StatusCopy(
      title: 'تم طلب التوصيل',
      headline: 'المتجر يرتب مندوب توصيل لطلبك.',
      type: ToukhOrderNotificationTypes.courierRequested,
    ),
    'courier_assigned': _StatusCopy(
      title: 'تم تعيين مندوب توصيل',
      headline: 'مندوب التوصيل في الطريق لاستلام طلبك.',
      type: ToukhOrderNotificationTypes.courierAssigned,
    ),
    'ready_for_pickup': _StatusCopy(
      title: 'جاهز للاستلام',
      headline: 'طلبك جاهز وبانتظار مندوب التوصيل.',
      type: ToukhOrderNotificationTypes.readyForPickup,
    ),
    'out_for_delivery': _StatusCopy(
      title: 'في الطريق',
      headline: 'طلبك في الطريق إليك.',
      type: ToukhOrderNotificationTypes.outForDelivery,
    ),
    'picked_up': _StatusCopy(
      title: 'تم استلام الطلب',
      headline: 'تم استلام طلبك وهو في الطريق إليك.',
      type: ToukhOrderNotificationTypes.pickupCompleted,
    ),
    'delivered': _StatusCopy(
      title: 'تم التوصيل',
      headline: 'تم توصيل طلبك. بالهنا والشفا!',
      type: ToukhOrderNotificationTypes.delivered,
    ),
    'completed': _StatusCopy(
      title: 'تم التوصيل',
      headline: 'تم إكمال طلبك.',
      type: ToukhOrderNotificationTypes.delivered,
    ),
  };

  static _OrderTotals _orderTotalsAndItems(Map<String, dynamic> order) {
    final orderPrice = _toNumber(order['orderPrice']);
    final deliveryPrice = _toNumber(order['deliveryPrice']);
    final totalEgp =
        _toNumber(order['totalEgp']) != 0 ? _toNumber(order['totalEgp']) : orderPrice + deliveryPrice;
    final itemsRaw = order['items'];
    final items = itemsRaw is List ? itemsRaw : const [];
    final mappedItems = items
        .whereType<Map>()
        .map((e) => _mapOrderItem(Map<String, dynamic>.from(e)))
        .toList();
    return _OrderTotals(
      orderPrice: orderPrice,
      deliveryPrice: deliveryPrice,
      totalEgp: totalEgp,
      mappedItems: mappedItems,
    );
  }

  static Map<String, dynamic> _mapOrderItem(Map<String, dynamic> item) {
    final name = _string(item['title']) ??
        _string(item['name']) ??
        _string(item['itemName']) ??
        'منتج';
    final quantity = (_toInt(item['quantity']) ?? 1).clamp(1, 999999);
    final unitPrice = _toNumber(item['unitPrice']);
    final lineTotal = _toNumber(item['lineTotalEgp']) != 0
        ? _toNumber(item['lineTotalEgp'])
        : _toNumber(item['lineTotal']) != 0
            ? _toNumber(item['lineTotal'])
            : _toNumber(item['priceEgp']) != 0
                ? _toNumber(item['priceEgp'])
                : unitPrice * quantity;
    return {
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'lineTotalEgp': lineTotal,
    };
  }

  static String _formatOrderLinesBlock({
    required double orderPrice,
    required double deliveryPrice,
    required double totalEgp,
    required List<Map<String, dynamic>> mappedItems,
  }) {
    final lines = mappedItems.map((i) {
      final qty = i['quantity'] as int? ?? 1;
      final name = i['name'] as String? ?? 'منتج';
      final lineTotal = (i['lineTotalEgp'] as num?)?.toDouble() ?? 0;
      return '$qty× $name — ${lineTotal.round()} جنيه';
    }).toList();

    final shown = lines.take(_maxBodyLines).toList();
    if (lines.length > _maxBodyLines) {
      shown.add('+${lines.length - _maxBodyLines} أخرى');
    }
    if (deliveryPrice > 0) {
      shown.add('التوصيل: ${deliveryPrice.round()} جنيه');
    }
    shown.add('الإجمالي: ${totalEgp.round()} جنيه');
    return shown.join('\n');
  }

  static String _formatDescriptionWithHeadline(String headline, String itemsBlock) {
    if (itemsBlock.isEmpty) return headline;
    return '$headline\n$itemsBlock';
  }

  static String? _string(dynamic v) {
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return null;
  }

  static double _toNumber(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String && v.trim().isNotEmpty) {
      return double.tryParse(v.trim()) ?? 0;
    }
    return 0;
  }

  static int? _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String && v.trim().isNotEmpty) return int.tryParse(v.trim());
    return null;
  }
}

class _StatusCopy {
  const _StatusCopy({
    required this.title,
    required this.headline,
    required this.type,
  });

  final String title;
  final String headline;
  final String type;
}

class _OrderTotals {
  const _OrderTotals({
    required this.orderPrice,
    required this.deliveryPrice,
    required this.totalEgp,
    required this.mappedItems,
  });

  final double orderPrice;
  final double deliveryPrice;
  final double totalEgp;
  final List<Map<String, dynamic>> mappedItems;
}
