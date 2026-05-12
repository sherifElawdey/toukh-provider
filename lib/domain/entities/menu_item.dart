import 'package:equatable/equatable.dart';

class MenuItemSize extends Equatable {
  const MenuItemSize({required this.label, required this.priceEgp});

  final String label;
  final double priceEgp;

  Map<String, dynamic> toMap() => {
        'label': label,
        'priceEgp': priceEgp,
      };

  static MenuItemSize fromMap(Map<String, dynamic> m) => MenuItemSize(
        label: m['label'] as String? ?? '',
        priceEgp: (m['priceEgp'] as num?)?.toDouble() ?? 0,
      );

  @override
  List<Object?> get props => [label, priceEgp];
}

class MenuItemEntity extends Equatable {
  const MenuItemEntity({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.category,
    required this.sizes,
  });

  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? category;
  final List<MenuItemSize> sizes;

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (category != null) 'category': category,
        'sizes': sizes.map((e) => e.toMap()).toList(),
      };

  static MenuItemEntity fromFirestore(Map<String, dynamic> m) {
    final sizesRaw = m['sizes'] as List<dynamic>? ?? [];
    return MenuItemEntity(
      id: m['id'] as String? ?? '',
      name: m['name'] as String? ?? '',
      description: m['description'] as String?,
      imageUrl: m['imageUrl'] as String?,
      category: m['category'] as String?,
      sizes: sizesRaw
          .map((e) => MenuItemSize.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, name, description, imageUrl, category, sizes];
}
