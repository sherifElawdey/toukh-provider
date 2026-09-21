import 'package:equatable/equatable.dart';

/// In-app + persisted notification template.
class ToukhNotification extends Equatable {
  const ToukhNotification({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.link,
    this.rootRoute = '',
    this.payload = const {},
    this.opened = false,
    this.openedAt,
    this.createdAt,
    this.type,
    this.orderId,
    this.category = 'order',
  });

  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? link;
  final String rootRoute;
  final Map<String, dynamic> payload;
  final bool opened;
  final DateTime? openedAt;
  final DateTime? createdAt;
  final String? type;
  final String? orderId;
  final String category;

  bool get isUnread => !opened;

  ToukhNotification copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? link,
    String? rootRoute,
    Map<String, dynamic>? payload,
    bool? opened,
    DateTime? openedAt,
    DateTime? createdAt,
    String? type,
    String? orderId,
    String? category,
  }) {
    return ToukhNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      link: link ?? this.link,
      rootRoute: rootRoute ?? this.rootRoute,
      payload: payload ?? this.payload,
      opened: opened ?? this.opened,
      openedAt: openedAt ?? this.openedAt,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      orderId: orderId ?? this.orderId,
      category: category ?? this.category,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        imageUrl,
        link,
        rootRoute,
        payload,
        opened,
        openedAt,
        createdAt,
        type,
        orderId,
        category,
      ];
}

/// Input for creating a notification (server or client).
class ToukhNotificationTemplate extends Equatable {
  const ToukhNotificationTemplate({
    required this.title,
    required this.description,
    this.imageUrl,
    this.link,
    this.rootRoute = '',
    this.payload = const {},
    this.type,
    this.orderId,
    this.category = 'order',
  });

  final String title;
  final String description;
  final String? imageUrl;
  final String? link;
  final String rootRoute;
  final Map<String, dynamic> payload;
  final String? type;
  final String? orderId;
  final String category;

  @override
  List<Object?> get props => [
        title,
        description,
        imageUrl,
        link,
        rootRoute,
        payload,
        type,
        orderId,
        category,
      ];
}
