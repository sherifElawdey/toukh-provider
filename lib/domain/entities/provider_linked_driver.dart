import 'package:equatable/equatable.dart';

class ProviderLinkedDriver extends Equatable {
  const ProviderLinkedDriver({
    required this.uid,
    required this.displayName,
    required this.phone,
    required this.vehicleType,
    this.profilePhotoUrl,
    required this.status,
    required this.online,
    this.enabledByProvider = true,
    this.activeOrderId,
    this.activeDeliveryTaskId,
    this.activeRideId,
  });

  final String uid;
  final String displayName;
  final String phone;
  final String vehicleType;
  final String? profilePhotoUrl;
  final String status;
  final bool online;
  final bool enabledByProvider;
  final String? activeOrderId;
  final String? activeDeliveryTaskId;
  final String? activeRideId;

  /// True when the driver already holds an active delivery or ride.
  bool get isBusy =>
      (activeOrderId != null && activeOrderId!.isNotEmpty) ||
      (activeDeliveryTaskId != null && activeDeliveryTaskId!.isNotEmpty) ||
      (activeRideId != null && activeRideId!.isNotEmpty);

  @override
  List<Object?> get props => [
        uid,
        displayName,
        phone,
        vehicleType,
        profilePhotoUrl,
        status,
        online,
        enabledByProvider,
        activeOrderId,
        activeDeliveryTaskId,
        activeRideId,
      ];
}
