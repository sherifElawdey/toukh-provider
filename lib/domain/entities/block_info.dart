import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class BlockInfo extends Equatable {
  const BlockInfo({
    required this.reason,
    required this.blockedAt,
    this.expiresAt,
  });

  final String reason;
  final DateTime blockedAt;
  final DateTime? expiresAt;

  bool get isIndefinite => expiresAt == null;

  Duration? remaining(DateTime now) {
    final exp = expiresAt;
    if (exp == null) return null;
    final diff = exp.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  Map<String, dynamic> toFirestore() => {
        'reason': reason,
        'blockedAt': Timestamp.fromDate(blockedAt),
        if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
      };

  static BlockInfo? fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return null;
    final reason = data['reason'] as String?;
    final blockedAtTs = data['blockedAt'];
    final blockedAt = blockedAtTs is Timestamp
        ? blockedAtTs.toDate()
        : (blockedAtTs is DateTime ? blockedAtTs : null);
    if (reason == null || blockedAt == null) return null;
    final expiresTs = data['expiresAt'];
    final expiresAt = expiresTs is Timestamp
        ? expiresTs.toDate()
        : (expiresTs is DateTime ? expiresTs : null);
    return BlockInfo(
      reason: reason,
      blockedAt: blockedAt,
      expiresAt: expiresAt,
    );
  }

  @override
  List<Object?> get props => [reason, blockedAt, expiresAt];
}
