import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toukh_provider/domain/entities/delivery_company.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';

/// Shell tab content for the signed-in account: [company] for delivery
/// companies, [provider] for shops. Rebuilds when the company doc changes
/// (the router only refreshes on status changes).
class CompanyAccountSwitch extends StatelessWidget {
  const CompanyAccountSwitch({
    super.key,
    required this.company,
    required this.provider,
  });

  final Widget Function(BuildContext context, DeliveryCompany company) company;
  final WidgetBuilder provider;

  @override
  Widget build(BuildContext context) {
    final current = context.select<AuthCubit, DeliveryCompany?>(
      (c) => switch (c.state) {
        AuthenticatedCompany(:final company) => company,
        _ => null,
      },
    );
    return current == null ? provider(context) : company(context, current);
  }
}
