import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:toukh_provider/core/widgets/toukh_service_logo.dart';
import 'package:toukh_provider/domain/entities/block_info.dart';
import 'package:toukh_provider/features/account_status/presentation/widgets/blocked_info_card.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/l10n/app_strings.dart';

class BlockedScreen extends StatefulWidget {
  const BlockedScreen({super.key});

  @override
  State<BlockedScreen> createState() => _BlockedScreenState();
}

class _BlockedScreenState extends State<BlockedScreen> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatRemaining(Duration d) {
    if (d <= Duration.zero) return AppStrings.AccountStatus.blockedLifted.tr;
    final days = d.inDays;
    final hours = d.inHours % 24;
    final mins = d.inMinutes % 60;
    final secs = d.inSeconds % 60;
    if (days > 0) {
      return '${days}d ${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      buildWhen: (p, c) => c is Authenticated || c is Unauthenticated,
      builder: (context, state) {
        final BlockInfo? info =
            state is Authenticated ? state.profile.blockInfo : null;
        final dateFormat = DateFormat.yMMMMd().add_jm();
        final remaining = info?.remaining(_now);

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.transparent,
            actions: [
              TextButton(
                onPressed: () => context.read<AuthCubit>().signOut(),
                child: CustomText(AppStrings.AccountStatus.signOut),
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: AppSizes.screenPadding.copyWith(
                top: AppSizes.spaceLg,
                bottom: AppSizes.space2xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: ToukhServiceLogo(
                      size: 64,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  SizedBox(height: AppSizes.spaceMd),
                  Center(
                    child: Container(
                      width: 110,
                      height: 110,
                      margin: const EdgeInsets.symmetric(
                        vertical: AppSizes.spaceLg,
                      ),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.error.withValues(alpha: 0.12),
                      ),
                      child: Icon(
                        Icons.block_rounded,
                        size: 56,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  CustomText(
                    AppStrings.AccountStatus.blockedTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppSizes.fontHeadline,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                  SizedBox(height: AppSizes.space2xl),
                  if (info != null) ...[
                    BlockedInfoCard(
                      label: AppStrings.AccountStatus.blockedReason,
                      value: info.reason,
                      icon: Icons.warning_amber_rounded,
                    ),
                    SizedBox(height: AppSizes.spaceMd),
                    BlockedInfoCard(
                      label: AppStrings.AccountStatus.blockedSince.trParams({
                        'date': dateFormat.format(info.blockedAt),
                      }),
                      value: dateFormat.format(info.blockedAt),
                      showLabelOnly: true,
                      icon: Icons.event_outlined,
                    ),
                    SizedBox(height: AppSizes.spaceMd),
                    BlockedInfoCard(
                      icon: Icons.timer_outlined,
                      showLabelOnly: true,
                      label: info.isIndefinite
                          ? AppStrings.AccountStatus.blockedIndefinite.tr
                          : AppStrings.AccountStatus.blockedTimeRemaining
                              .trParams({
                              'time': _formatRemaining(
                                remaining ?? Duration.zero,
                              ),
                            }),
                      value: '',
                    ),
                  ],
                  const Spacer(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
