import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/menu/presentation/menu_builder_screen.dart';
import 'package:toukh_provider/features/portfolio/presentation/portfolio_screen.dart';

class MenuOrGalleryTabScreen extends StatelessWidget {
  const MenuOrGalleryTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is Authenticated && state.profile.isRestaurantShop) {
          return const MenuBuilderScreen();
        }
        return const PortfolioScreen();
      },
    );
  }
}
