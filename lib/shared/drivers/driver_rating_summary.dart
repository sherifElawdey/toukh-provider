import 'package:equatable/equatable.dart';

import '../orders/toukh_firestore_timestamps.dart';

/// One review under `drivers/{driverId}/Ratings/{id}`.
class DriverRatingSummary extends Equatable {
  const DriverRatingSummary({
    required this.id,
    required this.rating,
    this.authorName,
    this.comment,
    this.createdAt,
  });

  final String id;
  final int rating;
  final String? authorName;
  final String? comment;
  final DateTime? createdAt;

  factory DriverRatingSummary.fromMap(String id, Map<String, dynamic> data) {
    return DriverRatingSummary(
      id: id,
      rating: (data['rating'] as num?)?.round() ?? 0,
      authorName: (data['authorName'] as String?)?.trim(),
      comment: (data['comment'] as String?)?.trim(),
      createdAt: ToukhFirestoreTimestamps.toDateTime(data['createdAt']),
    );
  }

  @override
  List<Object?> get props => [id, rating, authorName, comment, createdAt];
}
