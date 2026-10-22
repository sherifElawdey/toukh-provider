import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/domain/repositories/auth_repository.dart';
import 'package:toukh_provider/domain/repositories/provider_menu_repository.dart';
import 'package:toukh_provider/core/storage/media_upload_service.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/menu/presentation/cubit/menu_builder_cubit.dart';
import 'package:toukh_provider/features/menu/presentation/widgets/menu_builder_seeder.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class MenuBuilderScreen extends StatelessWidget {
  const MenuBuilderScreen({super.key, this.registration = false});

  /// Sign-up step: adds "Sign out" and "Continue" (to under review) so the
  /// provider finishes the whole menu before submitting.
  final bool registration;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => MenuBuilderCubit(
        authCubit: ctx.read<AuthCubit>(),
        authRepository: getIt<AuthRepository>(),
        mediaUploadService: getIt<MediaUploadService>(),
        menuRepository: getIt<ProviderMenuRepository>(),
      ),
      child: registration
          ? const _RegistrationMenuScaffold()
          : const SafeArea(top: true, child: MenuBuilderSeeder()),
    );
  }
}

class _RegistrationMenuScaffold extends StatelessWidget {
  const _RegistrationMenuScaffold();

  Future<void> _continue(BuildContext context) async {
    final auth = context.read<AuthCubit>();
    final cubit = context.read<MenuBuilderCubit>();
    try {
      // Marks the menu step complete; the router then opens under review.
      await context.withAppLoading(cubit.saveMenu);
    } on MenuSaveMinimumItemsException {
      if (!context.mounted) return;
      AppSnack.show(
        context,
        message: AppStrings.Registration.menuMinimumItems.tr,
        state: AppSnackState.warning,
        icon: ToukhIcons.menu,
      );
      return;
    } catch (e) {
      if (!context.mounted) return;
      AppSnack.show(
        context,
        message: e.toString(),
        state: AppSnackState.error,
        icon: ToukhIcons.error,
      );
      return;
    }
    final s = auth.state;
    if (s is AuthFailure && context.mounted) {
      AppSnack.show(
        context,
        message: s.message,
        state: AppSnackState.error,
        icon: ToukhIcons.error,
      );
      await auth.dismissFailure();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 120,
        leading: Align(
          alignment: AlignmentDirectional.centerStart,
          child: AppTextButton(
            text: AppStrings.Settings.signOut,
            icon: ToukhIcons.logout,
            size: AppButtonSize.small,
            onTap: () => context.read<AuthCubit>().signOut(),
          ),
        ),
        actions: [
          AppTextButton(
            text: AppStrings.Common.continueLabel,
            size: AppButtonSize.small,
            onTap: () => _continue(context),
          ),
          const SizedBox(width: AppSizes.spaceSm),
        ],
      ),
      body: const MenuBuilderSeeder(),
    );
  }
}
