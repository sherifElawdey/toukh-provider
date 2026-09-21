import 'package:equatable/equatable.dart';

/// One medicine line in a pharmacy broadcast request.
class PharmacyRequestItem extends Equatable {
  const PharmacyRequestItem({
    required this.id,
    required this.quantityText,
    required this.nameDescription,
    this.imageUrl,
  });

  final String id;
  final String quantityText;
  final String nameDescription;
  final String? imageUrl;

  factory PharmacyRequestItem.fromMap(Map<String, dynamic> m) {
    return PharmacyRequestItem(
      id: (m['id'] as String?)?.trim().isNotEmpty == true
          ? m['id'] as String
          : (m['requestItemId'] as String?) ?? '',
      quantityText: (m['quantityText'] as String?)?.trim() ?? '',
      nameDescription: (m['nameDescription'] as String?)?.trim() ??
          (m['title'] as String?)?.trim() ??
          (m['name'] as String?)?.trim() ??
          '',
      imageUrl: m['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'quantityText': quantityText,
        'nameDescription': nameDescription,
        if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
      };

  @override
  List<Object?> get props => [id, quantityText, nameDescription, imageUrl];
}
