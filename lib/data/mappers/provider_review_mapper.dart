import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toukh_provider/domain/entities/provider_review_summary.dart';
import 'package:toukh_ui/toukh_ui.dart';

abstract final class ProviderReviewMapper {
  ProviderReviewMapper._();

  static ProviderReviewSummary fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final ratingRaw = data['rating'];
    final rating = ratingRaw is int
        ? ratingRaw.clamp(1, 5)
        : (ratingRaw is num ? ratingRaw.round().clamp(1, 5) : 5);

    return ProviderReviewSummary(
      id: id,
      rating: rating,
      comment: _string(data['comment']) ?? _string(data['text']),
      authorName:
          _string(data['authorName']) ?? _string(data['customerName']),
      createdAt: _date(data['createdAt']),
    );
  }

  static DateTime? _date(dynamic v) => ToukhFirestoreTimestamps.toDateTime(v);

  static String? _string(dynamic v) {
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return null;
  }
}
