import 'package:equatable/equatable.dart';

/// Minimal cart line used by order splitting (consumer checkout snapshot).
class CartLineForSplit extends Equatable {
  const CartLineForSplit({
    required this.providerId,
    required this.itemId,
    required this.title,
    required this.quantity,
    required this.unitPrice,
    this.serviceType = 'restaurants',
    this.sizeLabel,
    this.providerName,
  });

  final String providerId;
  final String itemId;
  final String title;
  final int quantity;
  final double unitPrice;
  final String serviceType;
  final String? sizeLabel;
  final String? providerName;

  double get lineTotal => unitPrice * quantity;

  Map<String, dynamic> toMap() => {
        'providerId': providerId,
        'itemId': itemId,
        'title': title,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'serviceType': serviceType,
        if (sizeLabel != null) 'sizeLabel': sizeLabel,
        if (providerName != null) 'providerName': providerName,
      };

  factory CartLineForSplit.fromMap(Map<String, dynamic> map) {
    return CartLineForSplit(
      providerId: map['providerId'] as String? ?? map['restaurantId'] as String? ?? '',
      itemId: map['itemId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      quantity: map['quantity'] as int? ?? 1,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
      serviceType: map['serviceType'] as String? ?? 'restaurants',
      sizeLabel: map['sizeLabel'] as String?,
      providerName: map['providerName'] as String? ?? map['restaurantName'] as String?,
    );
  }

  @override
  List<Object?> get props =>
      [providerId, itemId, title, quantity, unitPrice, serviceType, sizeLabel, providerName];
}
