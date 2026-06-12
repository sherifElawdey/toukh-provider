import 'package:equatable/equatable.dart';

class ProviderDriverLinkRequest extends Equatable {
  const ProviderDriverLinkRequest({
    required this.uid,
    required this.displayName,
    required this.phone,
    required this.vehicleType,
    this.profilePhotoUrl,
    required this.status,
    this.submittedAt,
  });

  final String uid;
  final String displayName;
  final String phone;
  final String vehicleType;
  final String? profilePhotoUrl;
  final String status;
  final DateTime? submittedAt;

  @override
  List<Object?> get props => [
        uid,
        displayName,
        phone,
        vehicleType,
        profilePhotoUrl,
        status,
        submittedAt,
      ];
}
