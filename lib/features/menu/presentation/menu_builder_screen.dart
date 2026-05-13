import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/domain/repositories/auth_repository.dart';
import 'package:toukh_provider/core/storage/media_upload_service.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/menu/presentation/cubit/menu_builder_cubit.dart';
import 'package:toukh_provider/features/menu/presentation/widgets/menu_builder_seeder.dart';

class MenuBuilderScreen extends StatelessWidget {
  const MenuBuilderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => MenuBuilderCubit(
        authCubit: ctx.read<AuthCubit>(),
        authRepository: getIt<AuthRepository>(),
        mediaUploadService: getIt<MediaUploadService>(),
      ),
      child: const MenuBuilderSeeder(),
    );
  }
}
