import 'package:global_logistics_app/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/errors/user_facing_error.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/core/providers/shipments_provider.dart';
import 'package:global_logistics_app/core/tracking/road_snap_service.dart';
import 'package:global_logistics_app/core/tracking/tracking_route_coords.dart';
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
  List<Map<String, dynamic>> _points = const [];
  List<LatLng> _roadSnappedRoute = const [];
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
      final rawCoords = TrackingRouteCoords.toPolyline(route);
      final snapped = await RoadSnapService.snapToRoads(rawCoords);
      if (mounted) {
        setState(() {
          _points = route;
          _latest = latest;
          _roadSnappedRoute = snapped;
          _error = null;
        });
        final center = TrackingRouteCoords.toLatLng(latest);
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

  Map<String, dynamic>? _extractLatestPoint(List<Map<String, dynamic>> points) {
    final sorted = TrackingRouteCoords.sortByRecordedAt(points);
    for (var i = sorted.length - 1; i >= 0; i--) {
      if (TrackingRouteCoords.toLatLng(sorted[i]) != null) return sorted[i];
    }
    return null;
  }

  List<LatLng> _routeLatLngs() =>
      _roadSnappedRoute.isNotEmpty
          ? _roadSnappedRoute
          : TrackingRouteCoords.toPolyline(_points);

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
          final routeCoords = _routeLatLngs();
          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter:
                      TrackingRouteCoords.toLatLng(_latest) ?? _defaultCenter,
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
                  if (routeCoords.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: routeCoords,
                          color: AppColors.info,
                          strokeWidth: 4,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      if (routeCoords.isNotEmpty)
                        Marker(
                          point: routeCoords.first,
                          width: 28,
                          height: 28,
                          child: const Icon(
                            Icons.trip_origin_rounded,
                            color: AppColors.success,
                            size: 24,
                          ),
                        ),
                      if (TrackingRouteCoords.toLatLng(_latest) != null)
                        Marker(
                          point: TrackingRouteCoords.toLatLng(_latest)!,
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
                                    : context.l10n.trackingLabel,
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
                            '${context.l10n.trackingPoints} ${_points.length}',
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
                            '${context.l10n.latestLocationPrefix}${_latest!['latitude']}${context.l10n.lonPrefix}${_latest!['longitude']}${context.l10n.atPrefix}${_latest!['recordedAt']}',
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
                              for (final item
                                  in TrackingRouteCoords.sortByRecordedAt(
                                    _points,
                                  )) {
                                start = TrackingRouteCoords.toLatLng(item);
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
