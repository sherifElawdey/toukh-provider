import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toukh_provider/domain/repositories/provider_gallery_repository.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/portfolio/presentation/widgets/portfolio_add_placeholder.dart';
import 'package:toukh_provider/features/portfolio/presentation/widgets/portfolio_image_tile.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  static const int kMaxPhotos = 5;

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final _files = <File>[];
  final _picker = ImagePicker();

  Future<void> _add() async {
    if (_files.length >= PortfolioScreen.kMaxPhotos) return;
    final r = await _picker.pickImage(source: ImageSource.gallery);
    if (r == null) return;
    setState(() => _files.add(File(r.path)));
  }

  Future<void> _save() async {
    final authState = context.read<AuthCubit>().state;
    final hasExisting = authState is Authenticated &&
        (authState.profile.portfolioImageUrls?.isNotEmpty ?? false);

    if (!hasExisting && _files.isEmpty) {
      AppSnack.show(
        context,
        message: AppStrings.Registration.portfolioMinOne.tr,
        state: AppSnackState.warning,
        icon: Icons.photo_library_outlined,
      );
      return;
    }
    await context.withAppLoading(() async {
      await context.read<AuthCubit>().submitRegistrationPortfolio(_files);
    });
    if (!mounted) return;
    final s = context.read<AuthCubit>().state;
    if (s is AuthFailure) {
      AppSnack.show(
        context,
        message: s.message,
        state: AppSnackState.error,
        icon: Icons.error_outline_rounded,
      );
      await context.read<AuthCubit>().dismissFailure();
      return;
    }
    setState(() => _files.clear());
    AppSnack.show(
      context,
      message: AppStrings.Common.success.tr,
      state: AppSnackState.success,
      icon: Icons.check_circle_outline_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final authState = context.watch<AuthCubit>().state;
    if (authState is! Authenticated) {
      return const SizedBox.shrink();
    }

    final galleryRepo = getIt<ProviderGalleryRepository>();

    return Scaffold(
      appBar: AppBar(
        title: CustomText(AppStrings.Registration.portfolioTitle),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: AppSizes.screenPadding.copyWith(
              top: AppSizes.spaceSm,
              bottom: AppSizes.spaceMd,
            ),
            child: CustomText(
              AppStrings.Registration.portfolioHint,
              style: TextStyle(
                fontSize: AppSizes.fontBody,
                height: 1.45,
                color: scheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ProviderGalleryItem>>(
              stream: galleryRepo.watchGallery(authState.profile.uid),
              builder: (context, snapshot) {
                final existing = snapshot.data ?? const [];
                final totalCount = existing.length + _files.length;
                final showAddSlot =
                    totalCount < PortfolioScreen.kMaxPhotos;
                final gridCount =
                    existing.length + _files.length + (showAddSlot ? 1 : 0);

                return GridView.builder(
                  padding: AppSizes.screenPadding.copyWith(top: 0),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSizes.spaceSm,
                    mainAxisSpacing: AppSizes.spaceSm,
                    childAspectRatio: 1,
                  ),
                  itemCount: gridCount,
                  itemBuilder: (context, i) {
                    if (i < existing.length) {
                      final item = existing[i];
                      return PortfolioImageTile(
                        url: item.url,
                        onRemove: () => galleryRepo.deleteImage(
                          providerId: authState.profile.uid,
                          item: item,
                        ),
                      );
                    }
                    final localIndex = i - existing.length;
                    if (localIndex < _files.length) {
                      return PortfolioImageTile(
                        file: _files[localIndex],
                        onRemove: () =>
                            setState(() => _files.removeAt(localIndex)),
                      );
                    }
                    return PortfolioAddPlaceholder(
                      currentCount: totalCount,
                      maxCount: PortfolioScreen.kMaxPhotos,
                      scheme: scheme,
                      onTap: _add,
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: AppSizes.screenPadding.copyWith(top: AppSizes.spaceSm),
            child: AppFilledButton(
              text: AppStrings.Common.save,
              onTap: _save,
            ),
          ),
        ],
      ),
    );
  }
}
