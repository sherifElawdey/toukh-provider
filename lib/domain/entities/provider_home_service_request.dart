import 'package:equatable/equatable.dart';

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
    this.preferredTimeRaw,
    this.note,
    this.noteImageUrl,
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
  final String? preferredTimeRaw;
  final String? note;
  final String? noteImageUrl;
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
        preferredTimeRaw,
        note,
        noteImageUrl,
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
      ];
}
