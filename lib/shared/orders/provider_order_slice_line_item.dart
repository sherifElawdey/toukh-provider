import 'package:equatable/equatable.dart';

class ProviderOrderSliceLineItem extends Equatable {
  const ProviderOrderSliceLineItem({
    this.itemId,
    this.requestItemId,
    required this.name,
    required this.quantity,
    required this.lineTotalEgp,
    this.quantityText,
    this.description,
    this.imageUrl,
    this.serviceType,
  });

  final String? itemId;
  final String? requestItemId;
  final String name;
  final int quantity;
  final double lineTotalEgp;
  final String? quantityText;
  final String? description;
  final String? imageUrl;
  final String? serviceType;

  bool get isExplore => serviceType == 'explore';

  String get displayQuantity => quantityText?.trim().isNotEmpty == true
      ? quantityText!.trim()
      : '$quantity';

  factory ProviderOrderSliceLineItem.fromMap(Map<String, dynamic> m) {
    final name = _string(m['title']) ??
        _string(m['name']) ??
        _string(m['itemName']) ??
        _string(m['nameDescription']) ??
        '';
    final qty = _int(m['quantity']) ?? 1;
    final unit = _double(m['unitPrice']) ?? 0;
    final line = _double(m['lineTotalEgp']) ??
        _double(m['lineTotal']) ??
        _double(m['priceEgp']) ??
        (unit > 0 ? unit * qty : 0);
    return ProviderOrderSliceLineItem(
      itemId: _string(m['itemId']) ?? _string(m['menuItemId']),
      requestItemId: _string(m['requestItemId']) ?? _string(m['id']),
      name: name,
      quantity: qty,
      lineTotalEgp: line,
      quantityText: _string(m['quantityText']),
      description: _string(m['description']) ?? _string(m['nameDescription']),
      imageUrl: _string(m['imageUrl']),
      serviceType: _string(m['serviceType']),
    );
  }

  Map<String, dynamic> toMap() => {
        if (itemId != null) 'itemId': itemId,
        if (requestItemId != null) 'requestItemId': requestItemId,
        'title': name,
        'quantity': quantity,
        'lineTotalEgp': lineTotalEgp,
        if (quantityText != null) 'quantityText': quantityText,
        if (description != null) 'description': description,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (serviceType != null) 'serviceType': serviceType,
      };

  static String? _string(dynamic v) {
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return null;
  }

  static int? _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  static double? _double(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', ''));
    return null;
  }

  @override
  List<Object?> get props => [
        itemId,
        requestItemId,
        name,
        quantity,
        lineTotalEgp,
        quantityText,
        description,
        imageUrl,
        serviceType,
      ];
}
