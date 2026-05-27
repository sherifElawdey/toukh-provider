import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:toukh_provider/domain/repositories/notification_inbox_repository.dart';
import 'package:toukh_ui/toukh_ui.dart';

class NotificationsState extends Equatable {
  const NotificationsState({
    this.loading = true,
    this.items = const [],
    this.errorMessage,
  });

  final bool loading;
  final List<ToukhNotification> items;
  final String? errorMessage;

  List<ToukhNotification> get newestFirst =>
      List<ToukhNotification>.from(items)
        ..sort((a, b) {
          final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bt.compareTo(at);
        });

  static const homePreviewLimit = 5;

  List<ToukhNotification> get homePreview =>
      newestFirst.take(homePreviewLimit).toList();

  @override
  List<Object?> get props => [loading, items, errorMessage];
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
    emit(const NotificationsState(loading: true));
    _sub = _repository.watchInbox(uid).listen(
      (items) => emit(NotificationsState(loading: false, items: items)),
      onError: (e) => emit(
        NotificationsState(loading: false, errorMessage: e.toString()),
      ),
    );
  }

  Future<void> markOpened(ToukhNotification notification) async {
    final uid = _uid;
    if (uid == null || notification.opened) return;
    await _repository.markOpened(uid: uid, notificationId: notification.id);
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
