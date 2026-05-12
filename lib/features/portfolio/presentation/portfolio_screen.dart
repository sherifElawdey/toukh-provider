import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toukh_provider/core/widgets/toukh_service_logo.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final _files = <File>[];
  final _picker = ImagePicker();

  Future<void> _add() async {
    if (_files.length >= 5) return;
    final r = await _picker.pickImage(source: ImageSource.gallery);
    if (r == null) return;
    setState(() => _files.add(File(r.path)));
  }

  Future<void> _save() async {
    if (_files.isEmpty) {
      AppSnack.show(
        context,
        message: 'Add at least one photo',
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
    return Scaffold(
      appBar: AppBar(
        title: CustomText(AppStrings.Registration.portfolioTitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: AppSizes.screenPadding.copyWith(bottom: AppSizes.spaceSm),
            child: Center(
              child: ToukhServiceLogo(
                size: 56,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: AppSizes.screenPadding,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _files.length,
              itemBuilder: (context, i) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      child: Image.file(_files[i], fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                        ),
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () =>
                            setState(() => _files.removeAt(i)),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: AppSizes.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: _files.length >= 5 ? null : _add,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: CustomText(
                    '${_files.length}/5',
                  ),
                ),
                FilledButton(
                  onPressed: _save,
                  child: CustomText(AppStrings.Common.save),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
