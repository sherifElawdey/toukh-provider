import 'package:equatable/equatable.dart';
import 'package:toukh_provider/core/utils/phone_e164.dart';

/// One public contact number for a provider brand.
class BrandPhone extends Equatable {
  const BrandPhone({required this.number, this.whatsapp = false});

  /// Stored as E.164, for example `+201012345678`.
  final String number;
  final bool whatsapp;

  Map<String, dynamic> toFirestore() => {
    'number': number,
    'whatsapp': whatsapp,
  };

  static BrandPhone? fromFirestore(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final stored = (map['number'] as String?)?.trim() ?? '';
    if (stored.isEmpty) return null;
    return BrandPhone(
      number: phoneE164FromProfileStored(stored) ?? stored,
      whatsapp: map['whatsapp'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [number, whatsapp];
}

/// Public brand contacts. Separate from the login phone and synthetic auth email.
class BrandInfo extends Equatable {
  const BrandInfo({
    this.phones = const [],
    this.website = '',
    this.facebook = '',
    this.instagram = '',
    this.tiktok = '',
    this.email = '',
  });

  final List<BrandPhone> phones;
  final String website;
  final String facebook;
  final String instagram;
  final String tiktok;

  /// Public contact email, not the Firebase auth address.
  final String email;

  bool get isEmpty =>
      phones.isEmpty &&
      website.trim().isEmpty &&
      facebook.trim().isEmpty &&
      instagram.trim().isEmpty &&
      tiktok.trim().isEmpty &&
      email.trim().isEmpty;

  BrandInfo normalized() {
    final kept = <BrandPhone>[];
    for (final phone in phones) {
      final number = phone.number.trim();
      if (number.isEmpty) continue;
      kept.add(BrandPhone(number: number, whatsapp: phone.whatsapp));
      if (kept.length == 2) break;
    }
    return BrandInfo(
      phones: kept,
      website: website.trim(),
      facebook: facebook.trim(),
      instagram: instagram.trim(),
      tiktok: tiktok.trim(),
      email: email.trim().toLowerCase(),
    );
  }

  /// Every key is written so a merge update can clear a previously saved value.
  Map<String, dynamic> toFirestore() {
    final info = normalized();
    return {
      'phones': info.phones.map((phone) => phone.toFirestore()).toList(),
      'website': info.website,
      'facebook': info.facebook,
      'instagram': info.instagram,
      'tiktok': info.tiktok,
      'email': info.email,
    };
  }

  static BrandInfo fromFirestore(dynamic raw) {
    if (raw is! Map) return const BrandInfo();
    final map = Map<String, dynamic>.from(raw);
    final phones = <BrandPhone>[];
    final phonesRaw = map['phones'];
    if (phonesRaw is List) {
      for (final item in phonesRaw) {
        final phone = BrandPhone.fromFirestore(item);
        if (phone == null) continue;
        phones.add(phone);
        if (phones.length == 2) break;
      }
    }
    return BrandInfo(
      phones: phones,
      website: (map['website'] as String?)?.trim() ?? '',
      facebook: (map['facebook'] as String?)?.trim() ?? '',
      instagram: (map['instagram'] as String?)?.trim() ?? '',
      tiktok: (map['tiktok'] as String?)?.trim() ?? '',
      email: (map['email'] as String?)?.trim() ?? '',
    );
  }

  @override
  List<Object?> get props => [
    phones,
    website,
    facebook,
    instagram,
    tiktok,
    email,
  ];
}
