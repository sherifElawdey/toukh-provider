import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toukh_provider/domain/entities/provider_driver_link_request.dart';
import 'package:toukh_provider/domain/entities/provider_linked_driver.dart';
import 'package:toukh_ui/toukh_ui.dart';

abstract final class ProviderDriverMapper {
  ProviderDriverMapper._();

  static ProviderLinkedDriver linkedDriverFromFirestore(
    String uid,
    Map<String, dynamic> data,
  ) {
    return ProviderLinkedDriver(
      uid: uid,
      displayName: _displayName(data),
      phone: _string(data['phone']) ?? '',
      vehicleType: _vehicleLabel(data['vehicleType']),
      profilePhotoUrl: _string(data['profilePhotoUrl']),
      status: _string(data['status']) ?? 'pending',
      online: data['online'] as bool? ?? false,
    );
  }

  static ProviderDriverLinkRequest linkRequestFromFirestore(
    String uid,
    Map<String, dynamic> data,
  ) {
    return ProviderDriverLinkRequest(
      uid: uid,
      displayName: _displayName(data),
      phone: _string(data['phone']) ?? '',
      vehicleType: _vehicleLabel(data['vehicleType']),
      profilePhotoUrl: _string(data['profilePhotoUrl']),
      status: _string(data['status']) ?? 'pending',
      submittedAt: _date(data['submittedAt']),
    );
  }

  static String _displayName(Map<String, dynamic> data) {
    final first = _string(data['firstName']) ?? '';
    final last = _string(data['lastName']) ?? '';
    final combined = '$first $last'.trim();
    if (combined.isNotEmpty) return combined;
    return _string(data['name']) ?? _string(data['displayName']) ?? '—';
  }

  static String _vehicleLabel(dynamic raw) {
    final v = _string(raw);
    switch (v) {
      case 'motorcycle':
        return 'motorcycle';
      case 'bicycle':
        return 'bicycle';
      case 'tuk_tuk':
      case 'tuktuk':
      case 'tuk-tuk':
        return 'tuk_tuk';
      default:
        return v ?? 'motorcycle';
    }
  }

  static DateTime? _date(dynamic v) => ToukhFirestoreTimestamps.toDateTime(v);

  static String? _string(dynamic v) {
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return null;
  }
}
