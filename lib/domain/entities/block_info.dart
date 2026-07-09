import 'package:equatable/equatable.dart';
import 'package:toukh_ui/toukh_ui.dart';

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
        'blockedAt': ToukhFirestoreTimestamps.fromDateTime(blockedAt),
        if (expiresAt != null)
          'expiresAt': ToukhFirestoreTimestamps.fromDateTime(expiresAt!),
      };

  static BlockInfo? fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return null;
    final reason = data['reason'] as String?;
    final blockedAt = ToukhFirestoreTimestamps.toDateTime(data['blockedAt']);
    if (reason == null || blockedAt == null) return null;
    return BlockInfo(
      reason: reason,
      blockedAt: blockedAt,
      expiresAt: ToukhFirestoreTimestamps.toDateTime(data['expiresAt']),
    );
  }

  @override
  List<Object?> get props => [reason, blockedAt, expiresAt];
}
