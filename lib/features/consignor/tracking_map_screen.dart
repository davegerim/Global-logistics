import 'package:global_logistics_app/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/errors/user_facing_error.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/core/providers/shipments_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'dart:async';

/// Uses `GET /tracking/{assignment-id}` for live route points.
class TrackingMapScreen extends ConsumerStatefulWidget {
  const TrackingMapScreen({super.key, required this.shipmentId});

  final String shipmentId;

  @override
  ConsumerState<TrackingMapScreen> createState() => _TrackingMapScreenState();
}

class _TrackingMapScreenState extends ConsumerState<TrackingMapScreen> {
  static const LatLng _defaultCenter = LatLng(9.03, 38.74);

  final MapController _mapController = MapController();
  List<dynamic> _points = const [];
  Map<String, dynamic>? _latest;
  String? _error;
  String? _loadedForAssignment;
  Timer? _refreshTimer;
  bool _isLoading = false;
  bool _mapReady = false;
  LatLng? _pendingCenter;

  Future<void> _openExternalMap({
    required double lat,
    required double lon,
  }) async {
    final query = Uri.encodeComponent('$lat,$lon');
    final google = 'https://www.google.com/maps/search/?api=1&query=$query';
    final ok = await launchUrlString(
      google,
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.couldNotOpenMapApp)));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final assignment = GoRouterState.of(
      context,
    ).uri.queryParameters['assignment'];
    if (assignment != null &&
        assignment.isNotEmpty &&
        assignment != _loadedForAssignment) {
      _refreshTimer?.cancel();
      _loadedForAssignment = assignment;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _load(assignment);
        if (!mounted) return;
        _refreshTimer = Timer.periodic(
          const Duration(seconds: 20),
          (_) => _load(assignment),
        );
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load(String assignmentId) async {
    if (_isLoading) return;
    _isLoading = true;
    try {
      final api = ref.read(backendApiProvider);
      final route = await api.trackingRoute(assignmentId);
      final latest = _extractLatestPoint(route);
      if (mounted) {
        setState(() {
          _points = route;
          _latest = latest;
          _error = null;
        });
        final center = _toLatLng(latest);
        if (center != null) {
          if (_mapReady) {
            _mapController.move(center, 14);
          } else {
            _pendingCenter = center;
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = userFacingMessage(e));
    } finally {
      _isLoading = false;
    }
  } 

  Map<String, dynamic>? _extractLatestPoint(List<dynamic> points) {
    for (var i = points.length - 1; i >= 0; i--) {
      final item = points[i];
      if (item is! Map) continue;
      final p = item.cast<String, dynamic>();
      if (_toLatLng(p) != null) return p;
    }
    return null;
  }

  double? _readCoord(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
    }
    return null;
  }

  /// Only accepts WGS84 degrees. Some API rows include projected coordinates
  /// (e.g. Web Mercator ~1e7) which must not be passed to [LatLng] or polylines crash.
  LatLng? _toLatLng(Map<String, dynamic>? point) {
    if (point == null) return null;
    final lat = _readCoord(point, ['latitude', 'lat']);
    final lon = _readCoord(point, ['longitude', 'lng', 'lon']);
    if (lat == null || lon == null) return null;
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return null;
    return LatLng(lat, lon);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(shipmentDetailProvider(widget.shipmentId));
    final assignment = GoRouterState.of(
      context,
    ).uri.queryParameters['assignment'];

    return Scaffold(
      body: async.when(
        data: (s) {
          if (s == null) {
            return Center(child: Text(context.l10n.shipmentNotFound));
          }
          final progress = s.progress01 ?? 0.55;
          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _toLatLng(_latest) ?? _defaultCenter,
                  initialZoom: 12,
                  onMapReady: () {
                    _mapReady = true;
                    final center = _pendingCenter;
                    if (center != null) {
                      _pendingCenter = null;
                      _mapController.move(center, 14);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName:
                        'com.globallogistics.global_logistics_app',
                  ),
                  if (_toLatLng(_latest) != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _toLatLng(_latest)!,
                          width: 34,
                          height: 34,
                          child: const Icon(
                            Icons.local_shipping_rounded,
                            color: AppColors.primary,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Material(
                        color: AppColors.surface,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        elevation: 0,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => context.pop(),
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Tooltip(
                        message: assignment == null
                            ? 'Add assignment in the URL to load tracking'
                            : 'Status: viewing live route and driver position for this shipment',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(99),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.straighten,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                assignment == null
                                    ? 'No assignment id'
                                    : 'Tracking',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              DraggableScrollableSheet(
                initialChildSize: 0.42,
                minChildSize: 0.28,
                maxChildSize: 0.78,
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 24,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(22),
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          s.displayId,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        if (assignment != null)
                          Text(
                            'Tracking points: ${_points.length}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (_error != null)
                          Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        if (_latest != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Latest: lat ${_latest!['latitude']} lon ${_latest!['longitude']} @ ${_latest!['recordedAt']}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 10),
                          FilledButton.icon(
                            onPressed: () {
                              final lat = (_latest!['latitude'] as num?)
                                  ?.toDouble();
                              final lon = (_latest!['longitude'] as num?)
                                  ?.toDouble();
                              if (lat == null || lon == null) return;
                              _openExternalMap(lat: lat, lon: lon);
                            },
                            icon: const Icon(Icons.location_searching_rounded),
                            label: Text(context.l10n.openLiveLocationInMaps),
                          ),
                        ],
                        if (_points.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              LatLng? start;
                              for (final item in _points) {
                                if (item is! Map) continue;
                                start = _toLatLng(item.cast<String, dynamic>());
                                if (start != null) break;
                              }
                              if (start == null) return;
                              _openExternalMap(
                                lat: start.latitude,
                                lon: start.longitude,
                              );
                            },
                            icon: const Icon(Icons.alt_route_rounded),
                            label: Text(context.l10n.openRouteStartInMaps),
                          ),
                        ],
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0, 1),
                            minHeight: 10,
                            backgroundColor: AppColors.surfaceMuted,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(body: Center(child: Text(userFacingMessage(e)))),
      ),
    );
  }
}
