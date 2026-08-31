import 'package:equatable/equatable.dart';
import 'package:toukh_provider/domain/entities/pre_service_question.dart';

class ProviderHomeServiceRequest extends Equatable {
  const ProviderHomeServiceRequest({
    required this.id,
    required this.userId,
    required this.providerId,
    required this.categoryId,
    required this.categoryTitle,
    required this.status,
    required this.createdAt,
    this.customerName,
    this.providerName,
    this.addressTitle,
    this.addressFormatted,
    this.addressLat,
    this.addressLng,
    this.startAddressTitle,
    this.startAddressFormatted,
    this.startLat,
    this.startLng,
    this.destinationAddressTitle,
    this.destinationAddressFormatted,
    this.destinationLat,
    this.destinationLng,
    this.cargoDescription,
    this.withDriver,
    this.preferredTimeRaw,
    this.preferredDate,
    this.note,
    this.noteImageUrl,
    this.preServiceAnswers = const [],
    this.clientPriceEgp,
    this.quotedPriceEgp,
    this.scheduledAt,
    this.quotedAt,
    this.quoteUsesClientPrice,
    this.customerPhone,
    this.customerPhotoUrl,
    this.onMyWayAt,
    this.completedAt,
    this.cancelledAt,
    this.completionCode,
  });

  final String id;
  final String userId;
  final String? customerName;
  final String providerId;
  final String? providerName;
  final String categoryId;
  final String categoryTitle;
  final String status;
  final DateTime? createdAt;
  final String? addressTitle;
  final String? addressFormatted;
  final double? addressLat;
  final double? addressLng;
  final String? startAddressTitle;
  final String? startAddressFormatted;
  final double? startLat;
  final double? startLng;
  final String? destinationAddressTitle;
  final String? destinationAddressFormatted;
  final double? destinationLat;
  final double? destinationLng;
  final String? cargoDescription;
  final bool? withDriver;
  final String? preferredTimeRaw;
  final DateTime? preferredDate;
  final String? note;
  final String? noteImageUrl;
  final List<PreServiceAnswer> preServiceAnswers;
  final double? clientPriceEgp;
  final double? quotedPriceEgp;
  final DateTime? scheduledAt;
  final DateTime? quotedAt;
  final bool? quoteUsesClientPrice;
  final String? customerPhone;
  final String? customerPhotoUrl;
  final DateTime? onMyWayAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? completionCode;

  static const _terminalStatuses = {
    'completed',
    'cancelled',
    'rejected',
    'declined',
  };

  static const _incomingStatuses = {
    'pending',
    'tendering',
    'quoted',
    'awaiting_customer',
    'awaiting_provider',
  };

  String get statusNormalized => status.trim().toLowerCase();

  bool get isTerminal => _terminalStatuses.contains(statusNormalized);

  bool get isActive => statusNormalized.isNotEmpty && !isTerminal;

  bool get isIncoming => _incomingStatuses.contains(statusNormalized);

  bool get isPending => statusNormalized == 'pending';

  bool get isInProgress =>
      isActive && !isIncoming;

  bool get isAcceptedScheduled =>
      statusNormalized == 'accepted' && scheduledAt != null;

  bool get isCompleted => statusNormalized == 'completed';

  bool get isCancelled => statusNormalized == 'cancelled';

  bool get isDeclined =>
      statusNormalized == 'declined' || statusNormalized == 'rejected';

  /// Client UI id may be `hs_private_car` / `hs_pickup_truck` or bare slug.
  bool get isTripCategory {
    final id = categoryId.trim().toLowerCase();
    final slug = id.startsWith('hs_') ? id.substring(3) : id;
    return slug == 'private_car' || slug == 'pickup_truck';
  }

  DateTime? get closedAt => completedAt ?? cancelledAt ?? createdAt;

  String get preferredTimeLabel {
    return switch (preferredTimeRaw?.trim()) {
      'morning' => 'Morning',
      'evening' => 'Evening',
      'night' => 'At night',
      _ => preferredTimeRaw ?? '',
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        customerName,
        providerId,
        providerName,
        categoryId,
        categoryTitle,
        status,
        createdAt,
        addressTitle,
        addressFormatted,
        addressLat,
        addressLng,
        startAddressTitle,
        startAddressFormatted,
        startLat,
        startLng,
        destinationAddressTitle,
        destinationAddressFormatted,
        destinationLat,
        destinationLng,
        cargoDescription,
        withDriver,
        preferredTimeRaw,
        preferredDate,
        note,
        noteImageUrl,
        preServiceAnswers,
        clientPriceEgp,
        quotedPriceEgp,
        scheduledAt,
        quotedAt,
        quoteUsesClientPrice,
        customerPhone,
        customerPhotoUrl,
        onMyWayAt,
        completedAt,
        cancelledAt,
        completionCode,
      ];
}
