import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:toukh_provider/domain/entities/delivery_company.dart';
import 'package:toukh_provider/domain/entities/provider_profile.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class Unauthenticated extends AuthState {
  const Unauthenticated();
}

final class AuthenticatedNoProfile extends AuthState {
  const AuthenticatedNoProfile({required this.user});

  final User user;

  @override
  List<Object?> get props => [user.uid];
}

final class Authenticated extends AuthState {
  const Authenticated({required this.user, required this.profile});

  final User user;
  final ProviderProfile profile;

  @override
  List<Object?> get props => [user.uid, profile];
}

/// Signed in as a delivery company (`deliveryCompanies/{uid}`), not a shop.
final class AuthenticatedCompany extends AuthState {
  const AuthenticatedCompany({required this.user, required this.company});

  final User user;
  final DeliveryCompany company;

  @override
  List<Object?> get props => [user.uid, company];
}

final class AuthFailure extends AuthState {
  const AuthFailure({required this.message, this.code});

  final String message;

  /// Machine-readable reason (e.g. a [FirebaseAuthException.code]) so screens
  /// can point the user at the field to fix.
  final String? code;

  static const outsideServiceArea = 'outside-service-area';
  static const phoneAlreadyRegistered = 'email-already-in-use';

  @override
  List<Object?> get props => [message, code];
}
