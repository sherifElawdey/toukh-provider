import 'package:equatable/equatable.dart';
import 'package:toukh_provider/domain/entities/provider_home_service_request.dart';
import 'package:toukh_provider/features/home_service_requests/cubit/home_service_schedule_helpers.dart';

enum ProviderHomeServiceRequestsTab { incoming, inProgress, history }

class ProviderHomeServiceRequestsState extends Equatable {
  const ProviderHomeServiceRequestsState({
    this.loading = true,
    this.providerUid,
    this.requests = const [],
    this.errorMessage,
    this.historyFilter = HomeServiceHistoryFilter.all,
  });

  final bool loading;
  final String? providerUid;
  final List<ProviderHomeServiceRequest> requests;
  final String? errorMessage;
  final HomeServiceHistoryFilter historyFilter;

  int get pendingIncomingCount =>
      requests.where((r) => r.isIncoming).length;

  ProviderHomeServiceRequest? get activeOnMyWayRequest =>
      requests.activeOnMyWayRequest;

  bool get hasActiveOnMyWay => requests.hasActiveOnMyWay;

  List<ProviderHomeServiceRequest> forTab(ProviderHomeServiceRequestsTab tab) {
    return switch (tab) {
      ProviderHomeServiceRequestsTab.incoming =>
        requests.where((r) => r.isIncoming).toList(),
      ProviderHomeServiceRequestsTab.inProgress => requests
          .where((r) => r.isInProgress)
          .toList()
          .sortedForInProgressTab(),
      ProviderHomeServiceRequestsTab.history => requests
          .filteredForHistory(historyFilter)
          .sortedForHistoryTab(),
    };
  }

  List<ProviderHomeServiceRequest> acceptedScheduledJobs() =>
      requests.acceptedScheduledJobs();

  List<DateTime> scheduleDayTabs({
    DateTime? anchor,
    int pastDays = schedulePastDays,
    int days = scheduleFutureDays,
  }) =>
      requests.scheduleDayTabs(
        anchor: anchor,
        pastDays: pastDays,
        days: days,
      );

  int scheduleTodayTabIndex({DateTime? anchor, int pastDays = schedulePastDays}) =>
      requests.scheduleTodayTabIndex(anchor: anchor, pastDays: pastDays);

  List<ProviderHomeServiceRequest> jobsForDay(DateTime day) =>
      requests.jobsForDay(day);

  int jobCountForDay(DateTime day) => requests.jobCountForDay(day);

  ProviderHomeServiceRequestsState copyWith({
    bool? loading,
    String? providerUid,
    List<ProviderHomeServiceRequest>? requests,
    String? errorMessage,
    HomeServiceHistoryFilter? historyFilter,
    bool clearError = false,
  }) {
    return ProviderHomeServiceRequestsState(
      loading: loading ?? this.loading,
      providerUid: providerUid ?? this.providerUid,
      requests: requests ?? this.requests,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      historyFilter: historyFilter ?? this.historyFilter,
    );
  }

  @override
  List<Object?> get props =>
      [loading, providerUid, requests, errorMessage, historyFilter];
}
