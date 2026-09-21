import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mt;
import 'package:toukh_provider/shared/firestore/toukh_firestore_collections.dart';
import 'package:toukh_provider/shared/geofence/lat_lng_point.dart';
import 'package:toukh_provider/shared/geofence/service_area.dart';

/// Downloads, caches, and queries polygon service areas.
///
/// Point-in-polygon runs only when callers explicitly ask (address/provider
/// location create or edit). Browse flows should use stored `serviceAreaId`.
class GeofenceService {
  GeofenceService({FirebaseFirestore? firestore})
      : _fs = firestore ?? FirebaseFirestore.instance;

  static const String collectionName = ToukhFirestoreCollections.serviceAreas;

  final FirebaseFirestore _fs;

  List<ServiceArea> _cache = const [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  final _controller = StreamController<List<ServiceArea>>.broadcast();
  bool _started = false;
  Completer<void>? _ready;

  CollectionReference<Map<String, dynamic>> get _col =>
      _fs.collection(collectionName);

  /// Cached areas (enabled + disabled). Prefer [enabledAreas] for matching.
  List<ServiceArea> get cachedAreas => List.unmodifiable(_cache);

  /// Enabled areas with a valid polygon (3+ vertices).
  List<ServiceArea> get enabledAreas => _cache
      .where((a) => a.enabled && a.hasValidPolygon)
      .toList(growable: false);

  Stream<List<ServiceArea>> get watchAreas {
    _ensureListening();
    return _controller.stream;
  }

  Stream<List<ServiceArea>> get watchEnabledAreas =>
      watchAreas.map((all) => all
          .where((a) => a.enabled && a.hasValidPolygon)
          .toList(growable: false));

  /// Starts the Firestore listener and waits for the first snapshot.
  Future<void> ensureLoaded() async {
    _ensureListening();
    final pending = _ready;
    if (pending != null) await pending.future;
  }

  void _ensureListening() {
    if (_started) return;
    _started = true;
    _ready = Completer<void>();
    _sub = _col.snapshots().listen(
      (snap) {
        _cache = snap.docs
            .map((d) => ServiceArea.fromFirestore(d.id, d.data()))
            .toList(growable: false);
        if (!_controller.isClosed) {
          _controller.add(_cache);
        }
        final ready = _ready;
        if (ready != null && !ready.isCompleted) {
          ready.complete();
        }
      },
      onError: (Object e, StackTrace st) {
        final ready = _ready;
        if (ready != null && !ready.isCompleted) {
          ready.completeError(e, st);
        }
        if (!_controller.isClosed) {
          _controller.addError(e, st);
        }
      },
    );
  }

  ServiceArea? areaById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final a in _cache) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Returns the first enabled service area whose polygon contains [lat]/[lng].
  Future<ServiceArea?> findContaining({
    required double lat,
    required double lng,
  }) async {
    await ensureLoaded();
    return findContainingSync(lat: lat, lng: lng);
  }

  /// Sync PIP against the current cache (call [ensureLoaded] first if needed).
  ServiceArea? findContainingSync({
    required double lat,
    required double lng,
  }) {
    final point = mt.LatLng(lat, lng);
    for (final area in enabledAreas) {
      if (containsPoint(point: point, polygon: area.polygon)) {
        return area;
      }
    }
    return null;
  }

  /// Point-in-polygon using maps_toolkit (ray casting).
  static bool containsPoint({
    required mt.LatLng point,
    required List<LatLngPoint> polygon,
  }) {
    if (polygon.length < 3) return false;
    final path = polygon
        .map((p) => mt.LatLng(p.lat, p.lng))
        .toList(growable: false);
    return mt.PolygonUtil.containsLocation(point, path, false);
  }

  static bool containsLatLng({
    required double lat,
    required double lng,
    required List<LatLngPoint> polygon,
  }) {
    return containsPoint(point: mt.LatLng(lat, lng), polygon: polygon);
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _started = false;
    _ready = null;
    await _controller.close();
  }
}
