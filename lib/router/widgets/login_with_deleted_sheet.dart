import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toukh_provider/domain/entities/provider_account_status.dart';
import 'package:toukh_provider/features/account_status/presentation/deleted_account_sheet.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/auth/presentation/login_screen.dart';

class LoginWithDeletedSheet extends StatefulWidget {
  const LoginWithDeletedSheet({super.key});

  @override
  State<LoginWithDeletedSheet> createState() => _LoginWithDeletedSheetState();
}

class _LoginWithDeletedSheetState extends State<LoginWithDeletedSheet> {
  bool _sheetShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthCubit>().state;
    if (auth is Authenticated &&
        auth.profile.status == ProviderAccountStatus.deleted &&
        !_sheetShown) {
      _sheetShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) DeletedAccountSheet.show(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (p, c) =>
          c is Authenticated &&
          c.profile.status == ProviderAccountStatus.deleted &&
          !_sheetShown,
      listener: (context, state) {
        _sheetShown = true;
        DeletedAccountSheet.show(context);
      },
      child: const LoginScreen(),
    );
  }
}
