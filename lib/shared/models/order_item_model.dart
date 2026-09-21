import 'package:equatable/equatable.dart';

/// Single line on an [OrderModel]. Pure model with map-based (de)serialization
/// so apps can map it to Firestore / REST in their own data layers.
class OrderItemModel extends Equatable {
  const OrderItemModel({
    required this.id,
    required this.title,
    required this.count,
    required this.unitPrice,
    double? price,
    this.imageUrl,
    this.note,
    this.size,
    this.extras = const [],
    this.storeName,
    this.storeAddress,
    this.itemRequirements,
    this.categoryId,
    this.itemId,
  }) : _explicitPrice = price;

  /// Stable line id (e.g. cart line hash, server-side line id).
  final String id;

  final String title;
  final int count;
  final double unitPrice;

  /// Optional override for the line total. When omitted, [price] returns
  /// `unitPrice * count`.
  final double? _explicitPrice;

  final String? imageUrl;
  final String? note;

  /// Selected size variant (e.g. "Small", "Large", "500g"). Optional.
  final String? size;

  /// Selected add-ons / modifiers. Empty when none.
  final List<String> extras;

  /// Optional override for which store the item must be sourced from.
  final String? storeName;
  final String? storeAddress;

  /// Free-text instructions specific to this item (e.g. "no onions").
  final String? itemRequirements;

  /// Backend references — useful when the same physical item exists across
  /// multiple service providers / catalogs.
  final String? categoryId;
  final String? itemId;

  /// Line total. Falls back to `unitPrice * count` when no explicit price was
  /// provided at construction time.
  double get price => _explicitPrice ?? unitPrice * count;

  OrderItemModel copyWith({
    String? id,
    String? title,
    int? count,
    double? unitPrice,
    double? price,
    String? imageUrl,
    String? note,
    String? size,
    List<String>? extras,
    String? storeName,
    String? storeAddress,
    String? itemRequirements,
    String? categoryId,
    String? itemId,
  }) {
    return OrderItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      count: count ?? this.count,
      unitPrice: unitPrice ?? this.unitPrice,
      price: price ?? _explicitPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      note: note ?? this.note,
      size: size ?? this.size,
      extras: extras ?? this.extras,
      storeName: storeName ?? this.storeName,
      storeAddress: storeAddress ?? this.storeAddress,
      itemRequirements: itemRequirements ?? this.itemRequirements,
      categoryId: categoryId ?? this.categoryId,
      itemId: itemId ?? this.itemId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'count': count,
      'unitPrice': unitPrice,
      'price': price,
      if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
      if (note != null && note!.isNotEmpty) 'note': note,
      if (size != null && size!.isNotEmpty) 'size': size,
      if (extras.isNotEmpty) 'extras': List<String>.from(extras),
      if (storeName != null && storeName!.isNotEmpty) 'storeName': storeName,
      if (storeAddress != null && storeAddress!.isNotEmpty)
        'storeAddress': storeAddress,
      if (itemRequirements != null && itemRequirements!.isNotEmpty)
        'itemRequirements': itemRequirements,
      if (categoryId != null && categoryId!.isNotEmpty)
        'categoryId': categoryId,
      if (itemId != null && itemId!.isNotEmpty) 'itemId': itemId,
    };
  }

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      id: _string(map['id']) ?? '',
      title: _string(map['title']) ?? '',
      count: _int(map['count']) ?? 0,
      unitPrice: _double(map['unitPrice']) ?? 0,
      price: _double(map['price']),
      imageUrl: _string(map['imageUrl']),
      note: _string(map['note']),
      size: _string(map['size']),
      extras: _stringList(map['extras']),
      storeName: _string(map['storeName']),
      storeAddress: _string(map['storeAddress']),
      itemRequirements: _string(map['itemRequirements']),
      categoryId: _string(map['categoryId']),
      itemId: _string(map['itemId']),
    );
  }

  static String? _string(dynamic value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }

  static int? _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _double(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', ''));
    return null;
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }

  @override
  List<Object?> get props => [
        id,
        title,
        count,
        unitPrice,
        _explicitPrice,
        imageUrl,
        note,
        size,
        extras,
        storeName,
        storeAddress,
        itemRequirements,
        categoryId,
        itemId,
      ];
}
