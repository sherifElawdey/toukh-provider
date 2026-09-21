import 'package:toukh_provider/shared/firestore/toukh_firestore_collections.dart';
import 'toukh_home_service_notification_types.dart';
import 'toukh_notification.dart';
import 'toukh_notification_category.dart';
import 'toukh_notification_routes.dart';

/// Shared templates for home service request notifications.
abstract final class ToukhHomeServiceNotificationTemplates {
  ToukhHomeServiceNotificationTemplates._();

  static const _kCollection = ToukhFirestoreCollections.homeServiceRequests;
  static const _maxNotePreviewLines = 2;

  static String providerNewRequestNotificationId(String requestId) =>
      'home_service_request_$requestId';

  static String customerQuoteNotificationId(String requestId) =>
      'home_service_quote_$requestId';

  static String customerOnMyWayNotificationId(String requestId) =>
      'home_service_on_my_way_$requestId';

  static String providerAcceptedNotificationId(String requestId) =>
      'home_service_accepted_$requestId';

  static String homeServiceRequestsCollection() => _kCollection;

  static ToukhNotificationTemplate buildProviderNewRequestTemplate({
    required Map<String, dynamic> request,
    required String providerId,
    required String requestId,
    String? customerPhotoUrl,
  }) {
    final customerName =
        _string(request['customerName']) ?? _string(request['userName']) ?? 'عميل';
    final categoryTitle = _string(request['categoryTitle']) ?? 'خدمة منزلية';
    final note = _string(request['note']);
    final description = _formatDescription(categoryTitle: categoryTitle, note: note);
    final imageUrl = _string(request['customerPhotoUrl']) ?? customerPhotoUrl;
    final userId = _string(request['userId']);
    final status = _string(request['status']) ?? 'pending';

    return ToukhNotificationTemplate(
      title: 'طلب جديد · $customerName',
      description: description,
      imageUrl: imageUrl,
      type: ToukhHomeServiceNotificationTypes.homeServiceRequestPlaced,
      category: ToukhNotificationCategory.homeService,
      rootRoute: ToukhNotificationRoutes.providerHomeServiceRequestDetail(requestId),
      payload: {
        'requestId': requestId,
        'providerId': providerId,
        'userId': userId,
        'customerName': customerName,
        'categoryTitle': categoryTitle,
        if (note != null) 'note': note,
        'status': status,
      },
    );
  }

  static ToukhNotification notificationFromProviderRequest({
    required String notificationId,
    required Map<String, dynamic> request,
    required String providerId,
    required String requestId,
    String? customerPhotoUrl,
  }) {
    final template = buildProviderNewRequestTemplate(
      request: request,
      providerId: providerId,
      requestId: requestId,
      customerPhotoUrl: customerPhotoUrl,
    );
    return ToukhNotification(
      id: notificationId,
      title: template.title,
      description: template.description,
      imageUrl: template.imageUrl,
      type: template.type,
      category: template.category,
      rootRoute: template.rootRoute,
      payload: template.payload,
    );
  }

  static ToukhNotificationTemplate buildCustomerQuoteTemplate({
    required Map<String, dynamic> request,
    required String requestId,
    String? providerImageUrl,
  }) {
    final providerName = _string(request['providerName']) ?? 'مقدم الخدمة';
    final quotedPrice = _toDouble(request['quotedPriceEgp']);
    final categoryTitle = _string(request['categoryTitle']) ?? 'خدمة منزلية';

    final lines = <String>[categoryTitle];
    if (quotedPrice != null) {
      lines.add('السعر: ${quotedPrice.round()} جنيه');
    }
    final scheduledRaw = request['scheduledAt'];
    if (scheduledRaw is DateTime) {
      lines.add('الزيارة: ${scheduledRaw.toLocal()}');
    }

    return ToukhNotificationTemplate(
      title: 'عرض سعر من $providerName',
      description: lines.join('\n'),
      imageUrl: providerImageUrl ?? _string(request['providerImageUrl']),
      type: ToukhHomeServiceNotificationTypes.homeServiceQuoteReceived,
      category: ToukhNotificationCategory.homeService,
      rootRoute: ToukhNotificationRoutes.consumerHomeServiceRequestDetail,
      payload: {
        'requestId': requestId,
        'providerId': _string(request['providerId']),
        'providerName': providerName,
        if (quotedPrice != null) 'quotedPriceEgp': quotedPrice,
        'categoryTitle': categoryTitle,
      },
    );
  }

  /// Immediate FCM/inbox alert when the customer accepts a quote.
  ///
  /// Includes [visitDate] so the provider app can schedule a local reminder.
  static ToukhNotificationTemplate buildProviderAcceptedTemplate({
    required Map<String, dynamic> request,
    required String requestId,
  }) {
    final customerName =
        _string(request['customerName']) ?? _string(request['userName']) ?? 'عميل';
    final categoryTitle = _string(request['categoryTitle']) ?? 'خدمة منزلية';
    final visitDate = _visitDate(request);

    return ToukhNotificationTemplate(
      title: 'تم قبول العرض · $customerName',
      description: visitDate != null
          ? '$categoryTitle · زيارة ${visitDate.toLocal()}'
          : 'تم قبول $categoryTitle',
      imageUrl: _string(request['customerPhotoUrl']),
      type: ToukhHomeServiceNotificationTypes.homeServiceRequestAccepted,
      category: ToukhNotificationCategory.homeService,
      rootRoute: ToukhNotificationRoutes.providerHomeServiceRequestDetail(requestId),
      orderId: requestId,
      payload: {
        'requestId': requestId,
        'orderId': requestId,
        'providerId': _string(request['providerId']),
        'userId': _string(request['userId']),
        'customerName': customerName,
        'categoryTitle': categoryTitle,
        'status': 'accepted',
        if (visitDate != null) 'visitDate': visitDate.toUtc().toIso8601String(),
        if (visitDate != null)
          'scheduledAt': visitDate.toUtc().toIso8601String(),
      },
    );
  }

  static ToukhNotificationTemplate buildCustomerOnMyWayTemplate({
    required Map<String, dynamic> request,
    required String requestId,
    String? providerImageUrl,
  }) {
    final providerName = _string(request['providerName']) ?? 'مقدم الخدمة';
    final categoryTitle = _string(request['categoryTitle']) ?? 'خدمة منزلية';

    final lines = <String>[categoryTitle, '$providerName في الطريق'];
    final scheduledRaw = request['scheduledAt'];
    if (scheduledRaw is DateTime) {
      lines.add('الزيارة: ${scheduledRaw.toLocal()}');
    }

    return ToukhNotificationTemplate(
      title: '$providerName في الطريق',
      description: lines.join('\n'),
      imageUrl: providerImageUrl ?? _string(request['providerImageUrl']),
      type: ToukhHomeServiceNotificationTypes.homeServiceProviderEnRoute,
      category: ToukhNotificationCategory.homeService,
      rootRoute: ToukhNotificationRoutes.consumerHomeServiceRequestDetail,
      payload: {
        'requestId': requestId,
        'providerId': _string(request['providerId']),
        'providerName': providerName,
        'categoryTitle': categoryTitle,
      },
    );
  }

  static String _formatDescription({
    required String categoryTitle,
    String? note,
  }) {
    final lines = <String>[categoryTitle];
    if (note != null && note.isNotEmpty) {
      final noteLines = note.split('\n').where((l) => l.trim().isNotEmpty);
      lines.addAll(noteLines.take(_maxNotePreviewLines));
    }
    return lines.join('\n');
  }

  static String? _string(dynamic v) {
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return null;
  }

  static double? _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String && v.trim().isNotEmpty) {
      return double.tryParse(v.trim());
    }
    return null;
  }

  static DateTime? _visitDate(Map<String, dynamic> request) {
    final scheduled = request['scheduledAt'] ?? request['visitDate'];
    if (scheduled is DateTime) return scheduled.toUtc();
    if (scheduled is String && scheduled.trim().isNotEmpty) {
      return DateTime.tryParse(scheduled.trim())?.toUtc();
    }
    return null;
  }
}
