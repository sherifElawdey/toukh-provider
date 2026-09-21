import 'package:equatable/equatable.dart';

import 'pharmacy_request_item.dart';

enum PharmacyRequestKind {
  prescriptionImage,
  medicineList;

  String get wireValue => switch (this) {
        PharmacyRequestKind.prescriptionImage => 'prescription_image',
        PharmacyRequestKind.medicineList => 'medicine_list',
      };

  static PharmacyRequestKind fromWire(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'medicine_list':
        return PharmacyRequestKind.medicineList;
      default:
        return PharmacyRequestKind.prescriptionImage;
    }
  }
}

/// Customer request payload stored on pharmacy-request master orders.
class PharmacyRequestPayload extends Equatable {
  const PharmacyRequestPayload({
    required this.kind,
    this.prescriptionImageUrl,
    this.customerNote,
    this.items = const [],
    this.customerLat,
    this.customerLng,
  });

  final PharmacyRequestKind kind;
  final String? prescriptionImageUrl;
  final String? customerNote;
  final List<PharmacyRequestItem> items;
  final double? customerLat;
  final double? customerLng;

  bool get hasPrescriptionImage =>
      prescriptionImageUrl != null && prescriptionImageUrl!.trim().isNotEmpty;

  bool get hasItems => items.isNotEmpty;

  factory PharmacyRequestPayload.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) {
      return const PharmacyRequestPayload(kind: PharmacyRequestKind.medicineList);
    }
    final itemsRaw = map['items'] as List<dynamic>? ?? [];
    final items = itemsRaw
        .map((e) => PharmacyRequestItem.fromMap(
              Map<String, dynamic>.from(e as Map),
            ))
        .where((e) => e.nameDescription.isNotEmpty)
        .toList();
    return PharmacyRequestPayload(
      kind: PharmacyRequestKind.fromWire(map['kind'] as String?),
      prescriptionImageUrl: map['prescriptionImageUrl'] as String?,
      customerNote: map['customerNote'] as String?,
      items: items,
      customerLat: (map['customerLat'] as num?)?.toDouble(),
      customerLng: (map['customerLng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'kind': kind.wireValue,
        if (prescriptionImageUrl != null)
          'prescriptionImageUrl': prescriptionImageUrl,
        if (customerNote != null && customerNote!.isNotEmpty)
          'customerNote': customerNote,
        'items': items.map((e) => e.toMap()).toList(),
        if (customerLat != null) 'customerLat': customerLat,
        if (customerLng != null) 'customerLng': customerLng,
      };

  @override
  List<Object?> get props => [
        kind,
        prescriptionImageUrl,
        customerNote,
        items,
        customerLat,
        customerLng,
      ];
}
