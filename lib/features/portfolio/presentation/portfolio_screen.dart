import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
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
    if (_files.isEmpty) {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final showAddSlot = _files.length < PortfolioScreen.kMaxPhotos;
    final gridCount = _files.length + (showAddSlot ? 1 : 0);

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
            child: GridView.builder(
              padding: AppSizes.screenPadding.copyWith(top: 0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSizes.spaceSm,
                mainAxisSpacing: AppSizes.spaceSm,
                childAspectRatio: 1,
              ),
              itemCount: gridCount,
              itemBuilder: (context, i) {
                if (i < _files.length) {
                  return PortfolioImageTile(
                    file: _files[i],
                    onRemove: () => setState(() => _files.removeAt(i)),
                  );
                }
                return PortfolioAddPlaceholder(
                  currentCount: _files.length,
                  maxCount: PortfolioScreen.kMaxPhotos,
                  scheme: scheme,
                  onTap: _add,
                );
              },
            ),
          ),
          Padding(
            padding: AppSizes.screenPadding.copyWith(top: AppSizes.spaceSm),
            child: FilledButton(
              onPressed: _save,
              child: CustomText(AppStrings.Common.save),
            ),
          ),
        ],
      ),
    );
  }
}
