import 'package:equatable/equatable.dart';

/// A courier whose `drivers/{uid}.deliveryCompanyId` points at this company.
///
/// [approved] means the company accepted the join request (server-owned
/// `companyApprovedId`); until then the courier shows under requests.
/// [accountStatus] is the platform review status (`pending` until an admin
/// approves the courier's documents).
class CompanyCourier extends Equatable {
  const CompanyCourier({
    required this.uid,
    required this.displayName,
    required this.phone,
    required this.vehicleType,
    this.profilePhotoUrl,
    required this.accountStatus,
    required this.online,
    required this.enabled,
    required this.approved,
    this.activeOrderId,
    this.activeDeliveryTaskId,
    this.activeRideId,
    this.requestedAt,
    this.approvedAt,
  });

  final String uid;
  final String displayName;
  final String phone;
  final String vehicleType;
  final String? profilePhotoUrl;
  final String accountStatus;
  final bool online;
  final bool enabled;
  final bool approved;
  final String? activeOrderId;
  final String? activeDeliveryTaskId;
  final String? activeRideId;
  final DateTime? requestedAt;
  final DateTime? approvedAt;

  bool get isBusy =>
      (activeOrderId?.isNotEmpty ?? false) ||
      (activeDeliveryTaskId?.isNotEmpty ?? false) ||
      (activeRideId?.isNotEmpty ?? false);

  /// Admin has approved the courier's documents.
  bool get isPlatformActive => accountStatus == 'active';

  /// Online and allowed to take jobs right now.
  bool get isAvailable => online && enabled && isPlatformActive;

  @override
  List<Object?> get props => [
    uid,
    displayName,
    phone,
    vehicleType,
    profilePhotoUrl,
    accountStatus,
    online,
    enabled,
    approved,
    activeOrderId,
    activeDeliveryTaskId,
    activeRideId,
    requestedAt,
    approvedAt,
  ];
}
