import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:toukh_provider/core/utils/phone_e164.dart';

/// Form fields of the delivery company sign-up. The location step reuses
/// [RegistrationCubit] through the shared map screen.
class DeliveryCompanyRegistrationDraft extends Equatable {
  const DeliveryCompanyRegistrationDraft({
    this.companyName = '',
    this.managerName = '',
    this.phoneNational = '',
    this.password = '',
  });

  final String companyName;
  final String managerName;
  final String phoneNational;
  final String password;

  /// `+20…` once [phoneNational] holds a full Egyptian mobile number.
  String? get phoneE164 {
    final raw = phoneNational.replaceAll(RegExp(r'\D'), '');
    final ten = raw.length >= 10 ? raw.substring(raw.length - 10) : raw;
    if (ten.length != 10) return null;
    final e164 = egyptMobileE164(ten);
    return e164.isEmpty ? null : e164;
  }

  bool get isComplete =>
      companyName.trim().isNotEmpty &&
      managerName.trim().isNotEmpty &&
      phoneE164 != null &&
      password.length >= 6;

  @override
  List<Object?> get props => [
    companyName,
    managerName,
    phoneNational,
    password,
  ];
}

class DeliveryCompanyRegistrationCubit
    extends Cubit<DeliveryCompanyRegistrationDraft> {
  DeliveryCompanyRegistrationCubit()
    : super(const DeliveryCompanyRegistrationDraft());

  void setDetails({
    required String companyName,
    required String managerName,
    required String phoneNational,
    required String password,
  }) {
    emit(
      DeliveryCompanyRegistrationDraft(
        companyName: companyName.trim(),
        managerName: managerName.trim(),
        phoneNational: phoneNational,
        password: password,
      ),
    );
  }
}

/// Everything [AuthCubit.registerDeliveryCompany] needs.
class DeliveryCompanyRegistrationData {
  const DeliveryCompanyRegistrationData({
    required this.companyName,
    required this.managerName,
    required this.phone,
    required this.password,
    required this.lat,
    required this.lng,
    required this.formattedAddress,
    this.city,
  });

  final String companyName;
  final String managerName;

  /// E.164.
  final String phone;
  final String password;
  final double lat;
  final double lng;
  final String formattedAddress;
  final String? city;
}
