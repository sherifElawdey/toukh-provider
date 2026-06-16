import 'package:toukh_provider/domain/entities/order_history_stats.dart';

abstract class ProviderOrderHistoryRepository {
  Future<OrderHistoryStats> fetchStats(
    String providerId, {
    DateTime? from,
    DateTime? to,
  });

  Future<OrderHistoryPage> fetchPage(
    String providerId, {
    int pageSize = 20,
    DateTime? from,
    DateTime? to,
    Object? startAfter,
  });
}
