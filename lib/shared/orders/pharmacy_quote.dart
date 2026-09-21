import 'package:equatable/equatable.dart';

/// Pharmacy quote on a provider slice after approval.
class PharmacyQuote extends Equatable {
  const PharmacyQuote({
    this.pharmacistNote,
    this.approvedItemIds = const [],
    this.quotedSubtotalEgp = 0,
    this.quotedDeliveryFeeEgp = 0,
    this.quotedTotalEgp = 0,
  });

  final String? pharmacistNote;
  final List<String> approvedItemIds;
  final double quotedSubtotalEgp;
  final double quotedDeliveryFeeEgp;
  final double quotedTotalEgp;

  factory PharmacyQuote.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return const PharmacyQuote();
    final idsRaw = map['approvedItemIds'] as List<dynamic>? ?? [];
    return PharmacyQuote(
      pharmacistNote: map['pharmacistNote'] as String?,
      approvedItemIds: idsRaw.map((e) => '$e').toList(),
      quotedSubtotalEgp: (map['quotedSubtotalEgp'] as num?)?.toDouble() ?? 0,
      quotedDeliveryFeeEgp:
          (map['quotedDeliveryFeeEgp'] as num?)?.toDouble() ?? 0,
      quotedTotalEgp: (map['quotedTotalEgp'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        if (pharmacistNote != null && pharmacistNote!.isNotEmpty)
          'pharmacistNote': pharmacistNote,
        'approvedItemIds': approvedItemIds,
        'quotedSubtotalEgp': quotedSubtotalEgp,
        'quotedDeliveryFeeEgp': quotedDeliveryFeeEgp,
        'quotedTotalEgp': quotedTotalEgp,
      };

  @override
  List<Object?> get props => [
        pharmacistNote,
        approvedItemIds,
        quotedSubtotalEgp,
        quotedDeliveryFeeEgp,
        quotedTotalEgp,
      ];
}
