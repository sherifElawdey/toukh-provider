import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toukh_provider/domain/entities/provider_wallet_transaction.dart';

abstract class ProviderWalletRepository {
  Stream<ProviderWalletSummary> watchWalletSummary(String providerId);

  Stream<List<ProviderWalletTransaction>> watchRecentTransactions(
    String providerId, {
    int limit = 10,
  });

  Future<List<ProviderWalletTransaction>> fetchAppFeeTransactions(
    String providerId, {
    int docLimit = 400,
  });

  /// App fee + customer service fee debits for revenues.
  Future<List<ProviderWalletTransaction>> fetchPlatformFeeTransactions(
    String providerId, {
    int docLimit = 400,
  });

  Future<List<ProviderWalletTransaction>> fetchTransactionsForChart(
    String providerId,
    DateTime periodStart,
    DateTime periodEnd, {
    int docLimit = 400,
  });

  Future<({List<ProviderWalletTransaction> items, DocumentSnapshot? lastDoc})>
      fetchTransactionsPage(
    String providerId, {
    int pageSize = 20,
    DocumentSnapshot? startAfter,
  });
}
