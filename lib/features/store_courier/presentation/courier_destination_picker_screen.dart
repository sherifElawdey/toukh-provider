import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/features/store_courier/data/store_courier_repository.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Full-screen map: search a place or move the map under the pin, then
/// confirm. Pops a [CourierDestination].
class CourierDestinationPickerScreen extends StatefulWidget {
  const CourierDestinationPickerScreen({super.key, required this.start});

  /// Where the map opens (the last pick, else the store).
  final LatLng start;

  static Future<CourierDestination?> open(
    BuildContext context, {
    required LatLng start,
  }) {
    return Navigator.of(context).push<CourierDestination>(
      MaterialPageRoute(
        builder: (_) => CourierDestinationPickerScreen(start: start),
      ),
    );
  }

  @override
  State<CourierDestinationPickerScreen> createState() =>
      _CourierDestinationPickerScreenState();
}

class _CourierDestinationPickerScreenState
    extends State<CourierDestinationPickerScreen> {
  GoogleMapController? _map;
  late LatLng _target = widget.start;
  String _address = '';
  bool _resolving = false;
  int _lookupGen = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_lookup(_target));
  }

  Future<void> _lookup(LatLng point) async {
    final gen = ++_lookupGen;
    setState(() => _resolving = true);
    String line = '';
    try {
      final address = await ToukhArabicAddress.resolve(
        point.latitude,
        point.longitude,
      );
      line = address?.formattedAddress ?? '';
    } catch (_) {}
    if (!mounted || gen != _lookupGen) return;
    setState(() {
      _address = line;
      _resolving = false;
    });
  }

  Future<void> _moveTo(LatLng point) async {
    _target = point;
    await _map?.animateCamera(CameraUpdate.newLatLngZoom(point, 16));
    await _lookup(point);
  }

  void _confirm() {
    final p = _target;
    Navigator.of(context).pop(
      CourierDestination(
        lat: p.latitude,
        lng: p.longitude,
        formattedAddress: _address.trim().isNotEmpty
            ? _address.trim()
            : '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: CustomText(AppStrings.StoreCourier.pickTitle),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          ToukhGoogleMap(
            debugScreenName: 'store_courier_destination',
            initialCameraPosition: CameraPosition(target: widget.start, zoom: 15),
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (c) => _map = c,
            onCameraMove: (pos) => _target = pos.target,
            onCameraIdle: () => unawaited(_lookup(_target)),
          ),
          // The pin's tip marks the map center.
          IgnorePointer(
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, -24),
                child: Icon(
                  ToukhIcons.location,
                  size: 48,
                  color: ToukhMapColors.destination,
                ),
              ),
            ),
          ),
          Positioned(
            left: AppSizes.spaceMd,
            right: AppSizes.spaceMd,
            top: AppSizes.spaceMd,
            child: _PlaceSearchField(
              near: () => _target,
              onPicked: (p) => unawaited(_moveTo(p)),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              color: scheme.surface,
              elevation: 8,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSizes.radiusLg),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.spaceLg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(ToukhIcons.location, color: ToukhMapColors.destination),
                          const SizedBox(width: AppSizes.spaceSm),
                          Expanded(
                            child: _resolving && _address.isEmpty
                                ? const LinearProgressIndicator()
                                : CustomText(
                                    _address.isEmpty
                                        ? AppStrings.StoreCourier.pickHint.tr
                                        : _address,
                                    maxLines: 2,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.spaceMd),
                      AppFilledButton(
                        text: AppStrings.StoreCourier.pickConfirm.tr,
                        onTap: _confirm,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Place suggestions from the `searchPlaces` function, biased to [near].
class _PlaceSearchField extends StatefulWidget {
  const _PlaceSearchField({required this.near, required this.onPicked});

  final LatLng Function() near;
  final ValueChanged<LatLng> onPicked;

  @override
  State<_PlaceSearchField> createState() => _PlaceSearchFieldState();
}

class _PlaceSearchFieldState extends State<_PlaceSearchField> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<({String placeId, String label})> _results = const [];
  bool _searching = false;
  int _queryToken = 0;

  FirebaseFunctions get _functions => getIt<FirebaseFunctions>();

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => unawaited(_search(value)),
    );
  }

  Future<void> _search(String input) async {
    final query = input.trim();
    final token = ++_queryToken;
    if (query.length < 2) {
      if (mounted) setState(() => _results = const []);
      return;
    }
    setState(() => _searching = true);
    try {
      final near = widget.near();
      final result = await _functions.httpsCallable('searchPlaces').call({
        'input': query,
        'lat': near.latitude,
        'lng': near.longitude,
      });
      final raw = result.data is Map ? result.data['results'] : null;
      final next = <({String placeId, String label})>[];
      if (raw is List) {
        for (final item in raw) {
          if (item is! Map) continue;
          final id = '${item['placeId'] ?? ''}'.trim();
          final label = '${item['label'] ?? ''}'.trim();
          if (id.isEmpty || label.isEmpty) continue;
          next.add((placeId: id, label: label));
        }
      }
      if (mounted && token == _queryToken) setState(() => _results = next);
    } catch (_) {
      if (mounted && token == _queryToken) setState(() => _results = const []);
    } finally {
      if (mounted && token == _queryToken) setState(() => _searching = false);
    }
  }

  Future<void> _select(({String placeId, String label}) place) async {
    _queryToken++;
    FocusScope.of(context).unfocus();
    setState(() {
      _results = const [];
      _searching = false;
      _controller.text = place.label;
    });
    try {
      final result = await _functions
          .httpsCallable('searchPlaces')
          .call({'placeId': place.placeId});
      final data = result.data;
      if (data is! Map || !mounted) return;
      final lat = (data['lat'] as num?)?.toDouble();
      final lng = (data['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return;
      widget.onPicked(LatLng(lat, lng));
    } catch (_) {
      if (!mounted) return;
      AppSnack.show(
        context,
        message: AppStrings.Common.unknownError.tr,
        state: AppSnackState.error,
      );
    }
  }

  void _clear() {
    _debounce?.cancel();
    _queryToken++;
    setState(() {
      _controller.clear();
      _results = const [];
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          elevation: 4,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          color: scheme.surface,
          child: TextField(
            controller: _controller,
            onChanged: _onChanged,
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            onSubmitted: (_) {
              if (_results.isNotEmpty) unawaited(_select(_results.first));
            },
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: AppStrings.StoreCourier.searchHint.tr,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _clear,
                    ),
              filled: true,
              fillColor: scheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        if (_results.isNotEmpty) ...[
          const SizedBox(height: 4),
          Material(
            elevation: 4,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            color: scheme.surface,
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final place in _results)
                  ListTile(
                    dense: true,
                    leading: Icon(ToukhIcons.location, size: 20),
                    title: Text(
                      place.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => unawaited(_select(place)),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
