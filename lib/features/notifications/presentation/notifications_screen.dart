import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:toukh_provider/core/notifications/notification_labels.dart';
import 'package:toukh_provider/core/notifications/notification_navigation.dart';
import 'package:toukh_provider/features/notifications/cubit/notifications_cubit.dart';
import 'package:toukh_provider/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:toukh_provider/features/onboarding/presentation/widgets/permission_required_sheet.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _permissionChecked = false;
  bool _allowed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_ensureNotificationPermission());
    });
  }

  Future<void> _ensureNotificationPermission() async {
    final cubit = context.read<OnboardingCubit>();
    final granted = await cubit.isNotificationGranted();
    if (!mounted) return;
    if (granted) {
      setState(() {
        _permissionChecked = true;
        _allowed = true;
      });
      return;
    }

    final permanentlyDenied = await Permission.notification.isPermanentlyDenied;
    if (!mounted) return;
    final enable = await PermissionRequiredSheet.showForNotifications(
      context,
      permanentlyDenied: permanentlyDenied,
    );
    if (!mounted) return;

    if (!enable) {
      context.pop();
      return;
    }

    if (permanentlyDenied) {
      await cubit.openSystemSettings();
      if (mounted) context.pop();
      return;
    }

    await cubit.requestNotificationPermission();
    if (!mounted) return;
    final nowGranted = await cubit.isNotificationGranted();
    if (!mounted) return;
    if (!nowGranted) {
      context.pop();
      return;
    }
    setState(() {
      _permissionChecked = true;
      _allowed = true;
    });
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: CustomText(AppStrings.Notifications.inboxClearAll.tr),
        content: CustomText(AppStrings.Notifications.inboxClearAllConfirm.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: CustomText(AppStrings.Common.cancel.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: CustomText(AppStrings.Notifications.inboxClearAll.tr),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<NotificationsCubit>().clearAll();
    }
  }

  Future<void> _refresh(BuildContext context) async {
    context.read<NotificationsCubit>().refresh();
    await Future<void>.delayed(const Duration(milliseconds: 450));
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionChecked || !_allowed) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(ToukhIcons.back),
            onPressed: () => context.pop(),
          ),
          title: CustomText(
            AppStrings.Notifications.inboxTitle.tr,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: AppSizes.fontTitle,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(ToukhIcons.back),
          onPressed: () => context.pop(),
        ),
        title: CustomText(
          AppStrings.Notifications.inboxTitle.tr,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: AppSizes.fontTitle,
          ),
        ),
        actions: [
          BlocBuilder<NotificationsCubit, NotificationsState>(
            buildWhen: (prev, next) =>
                prev.showUnreadOnly != next.showUnreadOnly ||
                prev.items.isNotEmpty != next.items.isNotEmpty,
            builder: (context, state) {
              if (state.items.isEmpty) return const SizedBox.shrink();
              return ToukhNotificationInboxMenuButton(
                showUnreadOnly: state.showUnreadOnly,
                markAllReadLabel: AppStrings.Notifications.inboxMarkAllRead.tr,
                clearAllLabel: AppStrings.Notifications.inboxClearAll.tr,
                showUnreadOnlyLabel:
                    AppStrings.Notifications.inboxShowUnreadOnly.tr,
                onMarkAllRead: () =>
                    context.read<NotificationsCubit>().markAllRead(),
                onClearAll: () => _confirmClearAll(context),
                onToggleUnreadOnly: () =>
                    context.read<NotificationsCubit>().toggleUnreadOnly(),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          if (state.loading && state.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.items.isEmpty) {
            return ToukhRefresh(
              onRefresh: () => _refresh(context),
              child: _EmptyInbox(
                title: AppStrings.Notifications.inboxEmptyTitle.tr,
                subtitle: AppStrings.Notifications.inboxEmptySubtitle.tr,
              ),
            );
          }
          final items = state.visibleItems;
          if (items.isEmpty) {
            return ToukhRefresh(
              onRefresh: () => _refresh(context),
              child: _EmptyInbox(
                title: AppStrings.Notifications.inboxNoUnread.tr,
                subtitle: AppStrings.Notifications.inboxEmptySubtitle.tr,
              ),
            );
          }
          return ToukhRefresh(
            onRefresh: () => _refresh(context),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSizes.screenPadding.copyWith(
                top: AppSizes.spaceMd,
                bottom: AppSizes.space2xl,
              ),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                final cubit = context.read<NotificationsCubit>();
                return ToukhNotificationListTile(
                  notification: item,
                  statusChipLabel: NotificationLabels.statusChipLabel(item),
                  categoryLabel: NotificationLabels.categoryLabel(item),
                  onTap: () async {
                    await cubit.markOpened(item);
                    await handleProviderNotificationTap(item);
                  },
                  onDelete: () => cubit.deleteNotification(item),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
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
                const SizedBox(height: AppSizes.spaceLg),
                CustomText(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSizes.spaceSm),
                CustomText(
                  subtitle,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
