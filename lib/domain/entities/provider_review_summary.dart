import 'package:equatable/equatable.dart';

class ProviderReviewSummary extends Equatable {
  const ProviderReviewSummary({
    required this.id,
    required this.rating,
    this.comment,
    this.authorName,
    this.createdAt,
  });

  final String id;
  final int rating;
  final String? comment;
  final String? authorName;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, rating, comment, authorName, createdAt];
}
