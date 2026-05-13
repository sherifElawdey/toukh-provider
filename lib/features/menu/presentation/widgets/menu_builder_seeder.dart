import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toukh_provider/features/menu/presentation/cubit/menu_builder_cubit.dart';
import 'package:toukh_provider/features/menu/presentation/widgets/menu_builder_view.dart';

class MenuBuilderSeeder extends StatefulWidget {
  const MenuBuilderSeeder({super.key});

  @override
  State<MenuBuilderSeeder> createState() => _MenuBuilderSeederState();
}

class _MenuBuilderSeederState extends State<MenuBuilderSeeder> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<MenuBuilderCubit>().seedFromAuthOnce();
  }

  @override
  Widget build(BuildContext context) {
    return const MenuBuilderView();
  }
}
