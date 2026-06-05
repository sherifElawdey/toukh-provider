import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_ui/toukh_ui.dart';

class HomeDashboardEmptyPlaceholder extends StatelessWidget {
  const HomeDashboardEmptyPlaceholder({
    super.key,
    required this.message,
    this.category,
    this.compact = false,
  });

  final String message;
  final ToukhServiceCategory? category;
  final bool compact;

  ToukhServiceCategory _resolveCategory(BuildContext context) {
    if (category != null) return category!;
    final auth = context.read<AuthCubit>().state;
    if (auth is Authenticated) {
      return ToukhServiceCategory.fromProviderServiceType(
            auth.profile.serviceType.wireValue,
          ) ??
          ToukhServiceCategory.restaurants;
    }
    return ToukhServiceCategory.restaurants;
  }

  @override
  Widget build(BuildContext context) {
    return ToukhSectionEmptyState(
      category: _resolveCategory(context),
      message: message,
      illustrationSize: compact ? 72 : 100,
      padding: compact
          ? const EdgeInsets.symmetric(vertical: AppSizes.spaceSm)
          : const EdgeInsets.symmetric(vertical: AppSizes.spaceMd),
    );
  }
}
