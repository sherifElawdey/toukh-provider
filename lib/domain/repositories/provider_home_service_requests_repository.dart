import 'package:toukh_provider/domain/entities/provider_home_service_request.dart';

abstract class ProviderHomeServiceRequestsRepository {
  Stream<List<ProviderHomeServiceRequest>> watchRequests(String providerId);

  Stream<ProviderHomeServiceRequest?> watchRequest(String requestId);

  Future<void> submitQuote({
    required String requestId,
    required String providerId,
    required double quotedPriceEgp,
    required DateTime scheduledAt,
  });

  Future<void> declineRequest({
    required String requestId,
    required String providerId,
  });

  Future<void> markOnMyWay({
    required String requestId,
    required String providerId,
  });

  Future<void> markCompleted({
    required String requestId,
    required String providerId,
  });
}
