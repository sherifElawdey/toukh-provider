import 'package:toukh_provider/core/notifications/notification_router_holder.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/domain/repositories/notification_inbox_repository.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> handleProviderNotificationTap(ToukhNotification notification) async {
  final auth = getIt<AuthCubit>().state;
  final uid = auth is Authenticated ? auth.user.uid : null;
  if (uid != null && notification.id.isNotEmpty) {
    await getIt<NotificationInboxRepository>().markOpened(
      uid: uid,
      notificationId: notification.id,
    );
  }

  if (notification.link != null && notification.link!.isNotEmpty) {
    final uri = Uri.tryParse(notification.link!);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
  }

  final orderId = notification.orderId ?? notification.payload['orderId']?.toString();
  final requestId = notification.payload['requestId']?.toString();
  final route = notification.rootRoute.isNotEmpty
      ? notification.rootRoute
      : (requestId != null && requestId.isNotEmpty
          ? ToukhNotificationRoutes.providerHomeServiceRequestDetail(requestId)
          : (orderId != null && orderId.isNotEmpty
              ? ToukhNotificationRoutes.providerOrderDetail(orderId)
              : AppRoutes.home));

  NotificationRouterHolder.router?.go(route);
}
