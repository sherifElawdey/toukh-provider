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
  });

  final String uid;
  final String displayName;
  final String phone;
  final String vehicleType;
  final String? profilePhotoUrl;
  final String status;
  final bool online;
  final bool enabledByProvider;

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
      ];
}
