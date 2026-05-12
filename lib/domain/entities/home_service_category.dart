import 'package:equatable/equatable.dart';

/// Row from Firestore `HomeServices` (registration home-service vertical).
class HomeServiceCategory extends Equatable {
  const HomeServiceCategory({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.isActive = true,
  });

  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final bool isActive;

  factory HomeServiceCategory.fromFirestore(
    String docId,
    Map<String, dynamic> data,
  ) {
    final rawId = data['id'] as String?;
    final id = (rawId != null && rawId.trim().isNotEmpty) ? rawId.trim() : docId;
    final rawImage = data['imageUrl'] as String?;
    final imageUrl =
        rawImage != null && rawImage.trim().isNotEmpty ? rawImage.trim() : null;
    return HomeServiceCategory(
      id: id,
      title: (data['title'] as String?)?.trim() ?? '',
      description: (data['description'] as String?)?.trim() ?? '',
      imageUrl: imageUrl,
      isActive: data['isActive'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, title, description, imageUrl, isActive];
}
