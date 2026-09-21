import 'package:equatable/equatable.dart';

import 'driver_assignment.dart';
import 'provider_order_slice.dart';

/// Resolved courier identity for display (slice wins over master assignment).
class AssignedDriverFields extends Equatable {
  const AssignedDriverFields({
    this.driverId,
    this.name,
    this.photoUrl,
    this.phone,
  });

  final String? driverId;
  final String? name;
  final String? photoUrl;
  final String? phone;

  bool get hasDriverId => driverId != null && driverId!.trim().isNotEmpty;

  bool get hasAnyIdentity =>
      hasDriverId ||
      (name != null && name!.trim().isNotEmpty) ||
      (photoUrl != null && photoUrl!.trim().isNotEmpty) ||
      (phone != null && phone!.trim().isNotEmpty);

  AssignedDriverFields copyWith({
    String? driverId,
    String? name,
    String? photoUrl,
    String? phone,
  }) {
    return AssignedDriverFields(
      driverId: driverId ?? this.driverId,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
    );
  }

  /// Merge profile fields from a `drivers/{uid}` doc without overwriting
  /// non-empty assignment values.
  AssignedDriverFields mergeDriverDoc(Map<String, dynamic>? data) {
    if (data == null) return this;
    String? pick(String? current, List<String> keys) {
      if (current != null && current.trim().isNotEmpty) return current;
      for (final k in keys) {
        final v = (data[k] as String?)?.trim();
        if (v != null && v.isNotEmpty) return v;
      }
      return current;
    }

    return AssignedDriverFields(
      driverId: driverId,
      name: pick(name, ['name', 'displayName']),
      photoUrl: pick(photoUrl, ['brandImageUrl', 'photoUrl', 'photoURL']),
      phone: pick(phone, ['phone', 'phoneNumber']),
    );
  }

  static AssignedDriverFields resolve({
    ProviderOrderSlice? slice,
    DriverAssignment? assignment,
    String fallbackName = 'Courier',
  }) {
    final id = (slice?.driverId?.trim().isNotEmpty == true
            ? slice!.driverId!.trim()
            : null) ??
        (assignment?.driverId.trim().isNotEmpty == true
            ? assignment!.driverId.trim()
            : null);

    String? firstNonEmpty(String? a, String? b) {
      final x = a?.trim();
      if (x != null && x.isNotEmpty) return x;
      final y = b?.trim();
      if (y != null && y.isNotEmpty) return y;
      return null;
    }

    final name = firstNonEmpty(slice?.driverName, assignment?.driverName) ??
        (id != null ? fallbackName : null);
    final photo =
        firstNonEmpty(slice?.driverPhotoUrl, assignment?.driverPhotoUrl);
    final phone = firstNonEmpty(slice?.driverPhone, assignment?.driverPhone);

    return AssignedDriverFields(
      driverId: id,
      name: name,
      photoUrl: photo,
      phone: phone,
    );
  }

  static AssignedDriverFields fromAssignment(
    DriverAssignment? assignment, {
    String fallbackName = 'Courier',
  }) {
    return resolve(assignment: assignment, fallbackName: fallbackName);
  }

  @override
  List<Object?> get props => [driverId, name, photoUrl, phone];
}
