import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

final class AuthFailure extends AuthState {
  const AuthFailure({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
