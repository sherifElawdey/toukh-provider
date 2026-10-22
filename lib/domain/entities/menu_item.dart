import 'package:equatable/equatable.dart';
import 'package:toukh_ui/toukh_ui.dart';

class MenuItemSize extends Equatable {
  const MenuItemSize({
    required this.label,
    required this.priceEgp,
    this.unitKey,
    this.packCount,
  });

  final String label;
  final double priceEgp;

  /// [GroceryUnitSize.key] for catalog sizes, so customers see the size in
  /// their own language.
  final String? unitKey;

  /// Pieces in a pack / carton sale option ("Pack of 6").
  final int? packCount;

  Map<String, dynamic> toMap() => {
    'label': label,
    'priceEgp': priceEgp,
    if (unitKey != null) 'unitKey': unitKey,
    if (packCount != null) 'packCount': packCount,
  };

  static MenuItemSize fromMap(Map<String, dynamic> m) => MenuItemSize(
    label: m['label'] as String? ?? '',
    priceEgp: (m['priceEgp'] as num?)?.toDouble() ?? 0,
    unitKey: m['unitKey'] as String?,
    packCount: (m['packCount'] as num?)?.toInt(),
  );

  @override
  List<Object?> get props => [label, priceEgp, unitKey, packCount];
}

class MenuItemEntity extends Equatable {
  const MenuItemEntity({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.category,
    required this.sizes,
    this.isAvailable = true,
    this.offerType = MenuItemOfferType.none,
    this.discountPercent,
    this.offerPriceEgp,
    this.catalogProductId,
    this.catalog,
    this.nameAr,
    this.nameEn,
    this.maxOrderQty,
    this.salesTerms,
  });

  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? category;
  final List<MenuItemSize> sizes;
  final bool isAvailable;
  final MenuItemOfferType offerType;
  final double? discountPercent;
  final double? offerPriceEgp;

  /// `groceryCatalog/{id}` this item was picked from. Customers always see the
  /// catalog's names and image, and the item hides when the catalog product is
  /// switched off or deleted.
  final String? catalogProductId;

  /// [MenuCatalogKinds] of [catalogProductId]; `null` = produce (older items).
  final String? catalog;
  final String? nameAr;
  final String? nameEn;

  /// Most a customer may order per order, across all sizes (`null` = no limit).
  final int? maxOrderQty;

  /// Store's conditions shown to customers ("sold by carton only", …).
  final String? salesTerms;

  bool get isFromCatalog =>
      catalogProductId != null && catalogProductId!.isNotEmpty;

  bool get isFromSupermarketCatalog =>
      isFromCatalog && catalog == MenuCatalogKinds.supermarket;

  bool get isFromProduceCatalog => isFromCatalog && !isFromSupermarketCatalog;

  MenuItemEntity copyWith({
    String? name,
    String? description,
    String? imageUrl,
    bool clearImage = false,
    String? category,
    List<MenuItemSize>? sizes,
    bool? isAvailable,
  }) {
    return MenuItemEntity(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: clearImage ? null : (imageUrl ?? this.imageUrl),
      category: category ?? this.category,
      sizes: sizes ?? this.sizes,
      isAvailable: isAvailable ?? this.isAvailable,
      offerType: offerType,
      discountPercent: discountPercent,
      offerPriceEgp: offerPriceEgp,
      catalogProductId: catalogProductId,
      catalog: catalog,
      nameAr: nameAr,
      nameEn: nameEn,
      maxOrderQty: maxOrderQty,
      salesTerms: salesTerms,
    );
  }

  bool get hasOffer =>
      offerType != MenuItemOfferType.none &&
      (offerType == MenuItemOfferType.percent
          ? (discountPercent ?? 0) > 0
          : (offerPriceEgp ?? 0) > 0);

  double effectivePriceFor(MenuItemSize size) => menuItemEffectivePrice(
    sizePriceEgp: size.priceEgp,
    offerType: offerType,
    discountPercent: discountPercent,
    offerPriceEgp: offerPriceEgp,
  );

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'name': name,
    if (description != null) 'description': description,
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (category != null) 'category': category,
    'sizes': sizes.map((e) => e.toMap()).toList(),
    'isAvailable': isAvailable,
    'offerType': offerType.wireValue,
    if (discountPercent != null) 'discountPercent': discountPercent,
    if (offerPriceEgp != null) 'offerPriceEgp': offerPriceEgp,
    if (catalogProductId != null) 'catalogProductId': catalogProductId,
    if (catalog != null) 'catalog': catalog,
    if (nameAr != null) 'nameAr': nameAr,
    if (nameEn != null) 'nameEn': nameEn,
    'maxOrderQty': maxOrderQty,
    'salesTerms': salesTerms,
  };

  static MenuItemEntity fromFirestore(Map<String, dynamic> m) {
    final sizesRaw = m['sizes'] as List<dynamic>? ?? [];
    final available = m['isAvailable'] ?? m['available'] ?? m['active'];
    return MenuItemEntity(
      id: m['id'] as String? ?? '',
      name: m['name'] as String? ?? '',
      description: m['description'] as String?,
      imageUrl: m['imageUrl'] as String?,
      category: m['category'] as String?,
      sizes: sizesRaw
          .map((e) => MenuItemSize.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      isAvailable: available is bool ? available : true,
      offerType: MenuItemOfferType.tryParse(m['offerType'] as String?),
      discountPercent: (m['discountPercent'] as num?)?.toDouble(),
      offerPriceEgp: (m['offerPriceEgp'] as num?)?.toDouble(),
      catalogProductId: m['catalogProductId'] as String?,
      catalog: m['catalog'] as String?,
      nameAr: m['nameAr'] as String?,
      nameEn: m['nameEn'] as String?,
      maxOrderQty: (m['maxOrderQty'] as num?)?.toInt(),
      salesTerms: m['salesTerms'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    imageUrl,
    category,
    sizes,
    isAvailable,
    offerType,
    discountPercent,
    offerPriceEgp,
    catalogProductId,
    catalog,
    nameAr,
    nameEn,
    maxOrderQty,
    salesTerms,
  ];
}
