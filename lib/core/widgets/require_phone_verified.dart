import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';

/// Blocks menu/portfolio until the provider has verified their phone.
class RequirePhoneVerified extends StatefulWidget {
  const RequirePhoneVerified({super.key, required this.child});

  final Widget child;

  @override
  State<RequirePhoneVerified> createState() => _RequirePhoneVerifiedState();
}

class _RequirePhoneVerifiedState extends State<RequirePhoneVerified> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _enforce());
  }

  void _enforce() {
    if (!mounted) return;
    final auth = context.read<AuthCubit>().state;
    if (auth is Authenticated && !auth.profile.phoneVerified) {
      context.go(AppRoutes.accountVerifyPhone);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (prev, next) =>
          next is Authenticated && !next.profile.phoneVerified,
      listener: (context, state) {
        context.go(AppRoutes.accountVerifyPhone);
      },
      child: widget.child,
    );
  }
}
