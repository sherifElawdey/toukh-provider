import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:toukh_provider/core/firebase/app_firebase_errors.dart';
import 'package:toukh_provider/core/notifications/provider_order_alert_controller.dart';
import 'package:toukh_provider/domain/repositories/notification_inbox_repository.dart';
import 'package:toukh_ui/toukh_ui.dart';

class NotificationsState extends Equatable {
  const NotificationsState({
    this.loading = true,
    this.items = const [],
    this.errorMessage,
    this.showUnreadOnly = false,
    this.hasMore = false,
    this.loadingMore = false,
    this.unreadCount = 0,
  });

  final bool loading;
  final List<ToukhNotification> items;
  final String? errorMessage;
  final bool showUnreadOnly;

  /// Older notifications exist beyond the loaded window.
  final bool hasMore;
  final bool loadingMore;

  /// Unread total across the whole inbox (not just the loaded window).
  final int unreadCount;

  List<ToukhNotification> get newestFirst =>
      List<ToukhNotification>.from(items)
        ..sort((a, b) {
          final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bt.compareTo(at);
        });

  List<ToukhNotification> get visibleItems {
    if (!showUnreadOnly) return newestFirst;
    return newestFirst.where((n) => n.isUnread).toList();
  }

  static const homePreviewLimit = 5;

  List<ToukhNotification> get homePreview =>
      newestFirst.take(homePreviewLimit).toList();

  NotificationsState copyWith({
    bool? loading,
    List<ToukhNotification>? items,
    String? errorMessage,
    bool? showUnreadOnly,
    bool? hasMore,
    bool? loadingMore,
    int? unreadCount,
    bool clearError = false,
  }) {
    return NotificationsState(
      loading: loading ?? this.loading,
      items: items ?? this.items,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      showUnreadOnly: showUnreadOnly ?? this.showUnreadOnly,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [loading, items, errorMessage, showUnreadOnly];
}

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repository) : super(const NotificationsState());

  final NotificationInboxRepository _repository;

  StreamSubscription<List<ToukhNotification>>? _sub;
  StreamSubscription<int>? _unreadSub;
  String? _uid;

  /// Rows per load-more step; the live window grows by this much.
  static const _chunk = ToukhPageSizes.mobile;
  int _window = _chunk;

  void _watchUnread(String? uid) {
    _unreadSub?.cancel();
    _unreadSub = null;
    if (uid == null) return;
    _unreadSub = _repository.watchUnreadCount(uid).listen(
      (n) {
        if (!isClosed) emit(state.copyWith(unreadCount: n));
      },
      onError: (_) {},
    );
  }

  void bindUser(String? uid) {
    if (_uid == uid) return;
    _uid = uid;
    _window = _chunk;
    _watchUnread(uid);
    _sub?.cancel();
    if (uid == null) {
      emit(const NotificationsState(loading: false, items: []));
      return;
    }
    _subscribe(uid);
  }

  /// Re-subscribe to the inbox stream and clear any error.
  void refresh() {
    final uid = _uid;
    if (uid == null) return;
    _sub?.cancel();
    _subscribe(uid);
  }

  void _subscribe(String uid) {
    emit(state.copyWith(loading: true, clearError: true));
    var seeded = false;
    final seen = <String>{};
    _sub = _repository.watchInbox(uid, limit: _window).listen(
      (items) {
        emit(
          NotificationsState(
            loading: false,
            items: items,
            showUnreadOnly: state.showUnreadOnly,
            hasMore: items.length >= _window,
            unreadCount: state.unreadCount,
          ),
        );
        if (!kIsWeb) return;
        if (!seeded) {
          seeded = true;
          seen.addAll(items.map((n) => n.id));
          return;
        }
        for (final notification in items) {
          if (notification.id.isEmpty || !seen.add(notification.id)) continue;
          ProviderOrderAlertController.instance.show(
            notification,
            playSound: false,
          );
          ToukhWebAlert.present(notification);
        }
      },
      onError: (e) => emit(state.copyWith(loading: false, loadingMore: false, errorMessage: appFirebaseError(e))),
    );
  }

  /// Grows the live window by one chunk (last row reached / next page).
  Future<void> loadMore() async {
    final uid = _uid;
    if (uid == null || !state.hasMore || state.loadingMore) return;
    _window += _chunk;
    emit(state.copyWith(loadingMore: true));
    await _sub?.cancel();
    _subscribe(uid);
  }

  void toggleUnreadOnly() {
    emit(state.copyWith(showUnreadOnly: !state.showUnreadOnly));
  }

  Future<void> markOpened(ToukhNotification notification) async {
    final uid = _uid;
    if (uid == null || notification.opened) return;
    await _repository.markOpened(uid: uid, notificationId: notification.id);
  }

  Future<void> markAllRead() async {
    final uid = _uid;
    if (uid == null) return;
    await _repository.markAllOpened(uid: uid);
  }

  Future<void> deleteNotification(ToukhNotification notification) async {
    final uid = _uid;
    if (uid == null) return;
    await _repository.deleteNotification(
      uid: uid,
      notificationId: notification.id,
    );
  }

  Future<void> clearAll() async {
    final uid = _uid;
    if (uid == null) return;
    await _repository.clearInbox(uid: uid);
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    _unreadSub?.cancel();
    return super.close();
  }
}
