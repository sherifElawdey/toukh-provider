import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toukh_provider/core/constants/app_constants.dart';
import 'package:toukh_provider/data/mappers/provider_review_mapper.dart';
import 'package:toukh_provider/domain/entities/provider_review_summary.dart';
import 'package:toukh_provider/domain/repositories/provider_reviews_repository.dart';

class FirestoreProviderReviewsRepository implements ProviderReviewsRepository {
  FirestoreProviderReviewsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const _reviews = 'reviews';
  static const _reviewLimit = 60;

  CollectionReference<Map<String, dynamic>> _reviewsCol(String providerId) =>
      _firestore.collection(AppConstants.providersCollection).doc(providerId).collection(_reviews);

  @override
  Stream<List<ProviderReviewSummary>> watchReviews(String providerId) {
    return _reviewsCol(providerId)
        .orderBy('createdAt', descending: true)
        .limit(_reviewLimit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ProviderReviewMapper.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }
}
