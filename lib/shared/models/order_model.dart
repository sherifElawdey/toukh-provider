import 'package:equatable/equatable.dart';

import '../orders/toukh_firestore_timestamps.dart';
import 'location.dart';
import 'order_item_model.dart';
import 'order_status.dart';

/// Canonical Order shared by the consumer (toukh) and driver (toukh_delivery)
/// apps. Pure model — uses [DateTime] and [double], no Firebase/Firestore
/// types. Apps map to/from their backends in their own data layers.
class OrderModel extends Equatable {
  const OrderModel({
    required this.id,
    required this.serviceType,
    required this.serviceProviderId,
    this.serviceProviderName,
    required this.clientId,
    required this.clientName,
    this.clientPhone,
    required this.pickupLocation,
    required this.deliveryLocation,
    required this.orderPrice,
    this.deliveryPrice,
    this.note,
    this.status = OrderStatus.placed,
    this.driverId,
    this.driverName,
    this.paymentMethod,
    this.isPaid = false,
    this.cancelReason,
    this.cancelledAt,
    this.createdAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.items = const [],
  });

  final String id;

  /// Free-form service area key (e.g. `restaurants`, `grocery`, `pharmacy`,
  /// `home_service`, `taxi`). Apps may map this to their own enums.
  final String serviceType;

  final String serviceProviderId;
  final String? serviceProviderName;

  final String clientId;
  final String clientName;
  final String? clientPhone;

  final Location pickupLocation;
  final Location deliveryLocation;

  /// Subtotal in EGP for the items (before delivery fee).
  final double orderPrice;

  /// Optional delivery fee in EGP. `null` when free / not yet calculated.
  final double? deliveryPrice;

  final String? note;

  final OrderStatus status;

  final String? driverId;
  final String? driverName;

  /// Free-form payment method tag (e.g. `cash`, `wallet`, `card`).
  final String? paymentMethod;

  final bool isPaid;

  final String? cancelReason;
  final DateTime? cancelledAt;

  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;

  final List<OrderItemModel> items;

  /// Items + delivery fee.
  double get totalPrice => orderPrice + (deliveryPrice ?? 0);

  /// Sum of [OrderItemModel.count] across all [items].
  int get itemsCount => items.fold(0, (a, b) => a + b.count);

  bool get isAccepted => acceptedAt != null;
  bool get isPickedUp => pickedUpAt != null;
  bool get isDelivered => deliveredAt != null;
  bool get isCancelled =>
      status == OrderStatus.cancelled || cancelledAt != null;

  OrderModel copyWith({
    String? id,
    String? serviceType,
    String? serviceProviderId,
    String? serviceProviderName,
    String? clientId,
    String? clientName,
    String? clientPhone,
    Location? pickupLocation,
    Location? deliveryLocation,
    double? orderPrice,
    double? deliveryPrice,
    String? note,
    OrderStatus? status,
    String? driverId,
    String? driverName,
    String? paymentMethod,
    bool? isPaid,
    String? cancelReason,
    DateTime? cancelledAt,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
    List<OrderItemModel>? items,
  }) {
    return OrderModel(
      id: id ?? this.id,
      serviceType: serviceType ?? this.serviceType,
      serviceProviderId: serviceProviderId ?? this.serviceProviderId,
      serviceProviderName: serviceProviderName ?? this.serviceProviderName,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      orderPrice: orderPrice ?? this.orderPrice,
      deliveryPrice: deliveryPrice ?? this.deliveryPrice,
      note: note ?? this.note,
      status: status ?? this.status,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isPaid: isPaid ?? this.isPaid,
      cancelReason: cancelReason ?? this.cancelReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serviceType': serviceType,
      'serviceProviderId': serviceProviderId,
      if (serviceProviderName != null && serviceProviderName!.isNotEmpty)
        'serviceProviderName': serviceProviderName,
      'clientId': clientId,
      'clientName': clientName,
      if (clientPhone != null && clientPhone!.isNotEmpty)
        'clientPhone': clientPhone,
      'pickupLocation': pickupLocation.toMap(),
      'deliveryLocation': deliveryLocation.toMap(),
      'orderPrice': orderPrice,
      if (deliveryPrice != null) 'deliveryPrice': deliveryPrice,
      if (note != null && note!.isNotEmpty) 'note': note,
      'status': status.wireValue,
      if (driverId != null && driverId!.isNotEmpty) 'driverId': driverId,
      if (driverName != null && driverName!.isNotEmpty)
        'driverName': driverName,
      if (paymentMethod != null && paymentMethod!.isNotEmpty)
        'paymentMethod': paymentMethod,
      'isPaid': isPaid,
      if (cancelReason != null && cancelReason!.isNotEmpty)
        'cancelReason': cancelReason,
      if (cancelledAt != null)
        'cancelledAt': ToukhFirestoreTimestamps.fieldFromDateTime(cancelledAt),
      if (createdAt != null)
        'createdAt': ToukhFirestoreTimestamps.fieldFromDateTime(createdAt),
      if (acceptedAt != null)
        'acceptedAt': ToukhFirestoreTimestamps.fieldFromDateTime(acceptedAt),
      if (pickedUpAt != null)
        'pickedUpAt': ToukhFirestoreTimestamps.fieldFromDateTime(pickedUpAt),
      if (deliveredAt != null)
        'deliveredAt': ToukhFirestoreTimestamps.fieldFromDateTime(deliveredAt),
      'items': items.map((e) => e.toMap()).toList(growable: false),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: _string(map['id']) ?? '',
      serviceType: _string(map['serviceType']) ?? '',
      serviceProviderId: _string(map['serviceProviderId']) ?? '',
      serviceProviderName: _string(map['serviceProviderName']),
      clientId: _string(map['clientId']) ?? '',
      clientName: _string(map['clientName']) ?? '',
      clientPhone: _string(map['clientPhone']),
      pickupLocation: _location(map['pickupLocation']),
      deliveryLocation: _location(map['deliveryLocation']),
      orderPrice: _double(map['orderPrice']) ?? 0,
      deliveryPrice: _double(map['deliveryPrice']),
      note: _string(map['note']),
      status: OrderStatus.fromWire(_string(map['status'])),
      driverId: _string(map['driverId']),
      driverName: _string(map['driverName']),
      paymentMethod: _string(map['paymentMethod']),
      isPaid: map['isPaid'] is bool ? map['isPaid'] as bool : false,
      cancelReason: _string(map['cancelReason']),
      cancelledAt: _date(map['cancelledAt']),
      createdAt: _date(map['createdAt']),
      acceptedAt: _date(map['acceptedAt']),
      pickedUpAt: _date(map['pickedUpAt']),
      deliveredAt: _date(map['deliveredAt']),
      items: _items(map['items']),
    );
  }

  static String? _string(dynamic value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }

  static double? _double(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', ''));
    return null;
  }

  /// Lenient datetime parser for Firestore and legacy wire formats.
  static DateTime? _date(dynamic value) =>
      ToukhFirestoreTimestamps.toDateTime(value);

  static Location _location(dynamic value) {
    if (value is Map) {
      return Location.fromMap(Map<String, dynamic>.from(value));
    }
    return const Location(lat: 0, lng: 0);
  }

  static List<OrderItemModel> _items(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => OrderItemModel.fromMap(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    }
    return const [];
  }

  @override
  List<Object?> get props => [
        id,
        serviceType,
        serviceProviderId,
        serviceProviderName,
        clientId,
        clientName,
        clientPhone,
        pickupLocation,
        deliveryLocation,
        orderPrice,
        deliveryPrice,
        note,
        status,
        driverId,
        driverName,
        paymentMethod,
        isPaid,
        cancelReason,
        cancelledAt,
        createdAt,
        acceptedAt,
        pickedUpAt,
        deliveredAt,
        items,
      ];
}
