import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toukh_provider/domain/entities/provider_dashboard_order.dart';
import 'package:toukh_provider/domain/entities/provider_fulfillment_mode.dart';
import 'package:toukh_provider/domain/entities/provider_order.dart';
import 'package:toukh_provider/domain/entities/provider_order_status_wire.dart';
import 'package:toukh_ui/toukh_ui.dart';

abstract final class ProviderOrderMapper {
  ProviderOrderMapper._();

  static ProviderOrder fromFirestore(String id, Map<String, dynamic> data) {
    final itemsRaw = data['items'] as List<dynamic>? ?? [];
    final items = itemsRaw
        .map((e) => _mapLine(Map<String, dynamic>.from(e as Map)))
        .whereType<ProviderOrderLineItem>()
        .toList();

    final orderPrice = _double(data['orderPrice']) ??
        _double(data['subtotalEgp']) ??
        _sumItems(items);
    final deliveryPrice = _double(data['deliveryPrice']);
    final total = _double(data['totalEgp']) ??
        _double(data['amountEgp']) ??
        _double(data['total']) ??
        (orderPrice + (deliveryPrice ?? 0));

    return ProviderOrder(
      id: id,
      statusWire: ProviderOrderStatusWire.normalize(data['status'] as String?),
      fulfillmentMode: ProviderFulfillmentMode.fromWire(
        data['fulfillmentMode'] as String?,
      ),
      customerId: _string(data['customerId']) ?? _string(data['clientId']),
      customerName:
          _string(data['customerName']) ?? _string(data['clientName']),
      customerPhone: _string(data['customerPhone']) ?? _string(data['clientPhone']),
      customerFcmToken: _string(data['customerFcmToken']),
      storeLocation: _location(data['storeLocation']),
      deliveryAddress: _location(data['deliveryAddress']) ??
          _location(data['deliveryLocation']),
      orderPrice: orderPrice,
      deliveryPrice: deliveryPrice,
      totalEgp: total,
      note: _string(data['note']),
      driverId: _string(data['driverId']),
      driverName: _string(data['driverName']),
      driverPhotoUrl: _string(data['driverPhotoUrl']),
      deliveryRequestId: _string(data['deliveryRequestId']),
      createdAt: _date(data['createdAt']),
      acceptedAt: _date(data['acceptedAt']),
      readyForPickupAt: _date(data['readyForPickupAt']),
      dispatchedAt: _date(data['dispatchedAt']),
      deliveredAt: _date(data['deliveredAt']) ?? _date(data['completedAt']),
      cancelledAt: _date(data['cancelledAt']),
      cancelReason: _string(data['cancelReason']),
      items: items,
      courierLateWarningAt: _date(data['courierLateWarningAt']),
      masterOrderId: _string(data['masterOrderId']),
      isAggregated: data['isAggregated'] == true,
      providerState: _string(data['providerState']),
      masterProviderCount: _int(data['masterProviderCount']) ?? 1,
    );
  }

  static Map<String, dynamic> storeLocationToFirestore(Location loc) => {
        'lat': loc.lat,
        'lng': loc.lng,
        if (loc.label != null) 'label': loc.label,
        if (loc.formattedAddress != null)
          'formattedAddress': loc.formattedAddress,
      };

  static ProviderOrderLineItem? _mapLine(Map<String, dynamic> m) {
    final name =
        _string(m['title']) ?? _string(m['name']) ?? _string(m['itemName']);
    if (name == null || name.isEmpty) return null;
    final qty = _int(m['quantity']) ?? 1;
    final unitPrice = _double(m['unitPrice']) ?? 0.0;
    final line = _double(m['lineTotalEgp']) ??
        _double(m['lineTotal']) ??
        _double(m['priceEgp']) ??
        (unitPrice > 0 ? unitPrice * qty : 0.0);
    return ProviderOrderLineItem(
      itemId: _string(m['itemId']) ?? _string(m['menuItemId']),
      name: name,
      quantity: qty,
      lineTotalEgp: line,
    );
  }

  static Location? _location(dynamic v) {
    if (v is! Map) return null;
    final m = Map<String, dynamic>.from(v);
    final lat = _double(m['lat']);
    final lng = _double(m['lng']);
    if (lat == null || lng == null) return null;
    return Location(
      lat: lat,
      lng: lng,
      label: _string(m['label']),
      formattedAddress: _string(m['formattedAddress']),
    );
  }

  static double _sumItems(List<ProviderOrderLineItem> items) {
    return items.fold(0.0, (a, b) => a + b.lineTotalEgp);
  }

  static DateTime? _date(dynamic v) {
    if (v is Timestamp) return v.toDate();
    return null;
  }

  static double? _double(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', ''));
    return null;
  }

  static int? _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  static String? _string(dynamic v) {
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return null;
  }
}
