import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/core/providers/shipments_provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// Uses `GET /tracking/{assignment-id}` and `GET /tracking/{assignment-id}/latest`.
class TrackingMapScreen extends ConsumerStatefulWidget {
  const TrackingMapScreen({super.key, required this.shipmentId});

  final String shipmentId;

  @override
  ConsumerState<TrackingMapScreen> createState() => _TrackingMapScreenState();
}

class _TrackingMapScreenState extends ConsumerState<TrackingMapScreen> {
  List<dynamic> _points = const [];
  Map<String, dynamic>? _latest;
  String? _error;
  String? _loadedForAssignment;

  Future<void> _openExternalMap({
    required double lat,
    required double lon,
    required String label,
  }) async {
    final query = Uri.encodeComponent('$lat,$lon ($label)');
    final google = 'https://www.google.com/maps/search/?api=1&query=$query';
    final ok = await launchUrlString(
      google,
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open map app.')));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final assignment = GoRouterState.of(context).uri.queryParameters['assignment'];
    if (assignment != null &&
        assignment.isNotEmpty &&
        assignment != _loadedForAssignment) {
      _loadedForAssignment = assignment;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(assignment));
    }
  }

  Future<void> _load(String assignmentId) async {
    try {
      final api = ref.read(backendApiProvider);
      final route = await api.trackingRoute(assignmentId);
      final latest = await api.trackingLatest(assignmentId);
      if (mounted) {
        setState(() {
          _points = route;
          _latest = latest;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(shipmentDetailProvider(widget.shipmentId));
    final assignment = GoRouterState.of(context).uri.queryParameters['assignment'];

    return Scaffold(
      body: async.when(
        data: (s) {
          if (s == null) {
            return const Center(child: Text('Shipment not found'));
          }
          final progress = s.progress01 ?? 0.55;
          return Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE8F0EE), Color(0xFFF5F7F6)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _RoutePainter(progress: progress),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.surface,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.arrow_back_rounded),
                          onPressed: () => context.pop(),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                          children: [
                            const Icon(Icons.straighten, size: 18, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              assignment == null ? 'No assignment id' : 'Tracking',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ],
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
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                          s.publicId,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        if (assignment != null)
                          Text(
                            'Tracking points: ${_points.length}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (_error != null)
                          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        if (_latest != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Latest: lat ${_latest!['latitude']} lon ${_latest!['longitude']} @ ${_latest!['recordedAt']}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 10),
                          FilledButton.icon(
                            onPressed: () {
                              final lat = (_latest!['latitude'] as num?)?.toDouble();
                              final lon = (_latest!['longitude'] as num?)?.toDouble();
                              if (lat == null || lon == null) return;
                              _openExternalMap(
                                lat: lat,
                                lon: lon,
                                label: 'Driver live location',
                              );
                            },
                            icon: const Icon(Icons.location_searching_rounded),
                            label: const Text('Open live location in Maps'),
                          ),
                        ],
                        if (_points.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              final first = _points.first;
                              if (first is! Map) return;
                              final p = first.cast<String, dynamic>();
                              final lat = (p['latitude'] as num?)?.toDouble();
                              final lon = (p['longitude'] as num?)?.toDouble();
                              if (lat == null || lon == null) return;
                              _openExternalMap(
                                lat: lat,
                                lon: lon,
                                label: 'Route starting point',
                              );
                            },
                            icon: const Icon(Icons.alt_route_rounded),
                            label: const Text('Open route start in Maps'),
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
                        Text(
                          'Full payloads are printed in the debug console (GL_API).',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  _RoutePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.35,
        size.width * 0.85,
        size.height * 0.22,
      );

    final bg = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final fg = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, bg);

    final metrics = path.computeMetrics().first;
    final len = metrics.length * progress.clamp(0, 1);
    final extractPath = metrics.extractPath(0, len);
    canvas.drawPath(extractPath, fg);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
