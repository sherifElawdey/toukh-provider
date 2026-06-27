import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:toukh_provider/core/firebase/app_firebase_errors.dart';
import 'package:toukh_provider/domain/repositories/notification_inbox_repository.dart';
import 'package:toukh_ui/toukh_ui.dart';

class NotificationsState extends Equatable {
  const NotificationsState({
    this.loading = true,
    this.items = const [],
    this.errorMessage,
    this.showUnreadOnly = false,
  });

  final bool loading;
  final List<ToukhNotification> items;
  final String? errorMessage;
  final bool showUnreadOnly;

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
    bool clearError = false,
  }) {
    return NotificationsState(
      loading: loading ?? this.loading,
      items: items ?? this.items,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      showUnreadOnly: showUnreadOnly ?? this.showUnreadOnly,
    );
  }

  @override
  List<Object?> get props => [loading, items, errorMessage, showUnreadOnly];
}

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repository) : super(const NotificationsState());

  final NotificationInboxRepository _repository;

  StreamSubscription<List<ToukhNotification>>? _sub;
  String? _uid;

  void bindUser(String? uid) {
    if (_uid == uid) return;
    _uid = uid;
    _sub?.cancel();
    if (uid == null) {
      emit(const NotificationsState(loading: false, items: []));
      return;
    }
    emit(state.copyWith(loading: true, clearError: true));
    _sub = _repository.watchInbox(uid).listen(
      (items) => emit(
        NotificationsState(
          loading: false,
          items: items,
          showUnreadOnly: state.showUnreadOnly,
        ),
      ),
      onError: (e) => emit(state.copyWith(loading: false, errorMessage: appFirebaseError(e))),
    );
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
    return super.close();
  }
}
