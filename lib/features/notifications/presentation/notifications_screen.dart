import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/notifications/notification_navigation.dart';
import 'package:toukh_provider/features/notifications/cubit/notifications_cubit.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(ToukhIcons.back),
          onPressed: () => context.pop(),
        ),
        title: CustomText(
          AppStrings.Notifications.title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: AppSizes.fontTitle,
          ),
        ),
      ),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          if (state.loading && state.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = state.newestFirst;
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: AppSizes.screenPadding,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      ToukhIcons.notifications,
                      size: 56,
                      color: scheme.onSurface.withValues(alpha: 0.28),
                    ),
                    SizedBox(height: AppSizes.spaceLg),
                    CustomText(
                      AppStrings.Notifications.emptyTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppSizes.fontTitle,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondColor,
                      ),
                    ),
                    SizedBox(height: AppSizes.spaceSm),
                    CustomText(
                      AppStrings.Notifications.emptySubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppSizes.fontBody,
                        height: 1.45,
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: AppSizes.screenPadding.copyWith(
              top: AppSizes.spaceMd,
              bottom: AppSizes.space2xl,
            ),
            itemCount: items.length,
            separatorBuilder: (_, __) => SizedBox(height: AppSizes.spaceSm),
            itemBuilder: (context, index) {
              final item = items[index];
              return ToukhNotificationListTile(
                notification: item,
                onTap: () async {
                  await context.read<NotificationsCubit>().markOpened(item);
                  await handleProviderNotificationTap(item);
                },
              );
            },
          );
        },
      ),
    );
  }
}
