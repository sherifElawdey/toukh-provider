import 'package:cloud_functions/cloud_functions.dart';

class NearbyDriver {
  const NearbyDriver({
    required this.id,
    required this.name,
    required this.distanceMeters,
    this.photoUrl,
  });

  final String id;
  final String name;
  final int distanceMeters;
  final String? photoUrl;
}

class DriverMatchingService {
  DriverMatchingService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<List<NearbyDriver>> listNearby({
    required double lat,
    required double lng,
    int radiusMeters = 1000,
  }) async {
    final callable = _functions.httpsCallable('listNearbyDrivers');
    final result = await callable.call<Map<String, dynamic>>({
      'lat': lat,
      'lng': lng,
      'radiusMeters': radiusMeters,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    final raw = data['drivers'] as List<dynamic>? ?? [];
    return raw.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return NearbyDriver(
        id: m['id'] as String? ?? '',
        name: m['name'] as String? ?? 'Driver',
        distanceMeters: (m['distanceMeters'] as num?)?.round() ?? 0,
        photoUrl: m['photoUrl'] as String?,
      );
    }).toList();
  }
}
