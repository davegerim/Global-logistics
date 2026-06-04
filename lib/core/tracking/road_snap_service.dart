import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

/// Snaps GPS tracking pings to actual roads via the free OSRM API,
/// returning a dense polyline that follows road geometry.
abstract final class RoadSnapService {
  static const _baseUrl = 'router.project-osrm.org';

  /// Takes sparse GPS [waypoints] and returns a dense road-following polyline.
  /// Falls back to the original [waypoints] if the service is unavailable.
  static Future<List<LatLng>> snapToRoads(List<LatLng> waypoints) async {
    if (waypoints.length < 2) return waypoints;

    final unique = _deduplicateClose(waypoints);
    if (unique.length < 2) return waypoints;

    try {
      final coords = unique.map((p) => '${p.longitude},${p.latitude}').join(';');
      final uri = Uri.https(_baseUrl, '/route/v1/driving/$coords', {
        'overview': 'full',
        'geometries': 'geojson',
      });

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      try {
        final request = await client.getUrl(uri);
        request.headers.set('User-Agent', 'GlobalLogisticsApp/1.0');
        final response = await request.close();
        if (response.statusCode != 200) return waypoints;

        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;

        if (json['code'] != 'Ok') return waypoints;

        final routes = json['routes'] as List?;
        if (routes == null || routes.isEmpty) return waypoints;

        final geometry = (routes[0] as Map)['geometry'] as Map?;
        if (geometry == null) return waypoints;

        final coordinates = geometry['coordinates'] as List?;
        if (coordinates == null || coordinates.length < 2) return waypoints;

        final result = <LatLng>[];
        for (final coord in coordinates) {
          if (coord is! List || coord.length < 2) continue;
          final lon = (coord[0] as num).toDouble();
          final lat = (coord[1] as num).toDouble();
          if (lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180) {
            result.add(LatLng(lat, lon));
          }
        }
        return result.length >= 2 ? result : waypoints;
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('[ROAD_SNAP] OSRM failed, using straight lines: $e');
      return waypoints;
    }
  }

  /// Removes points that are within ~10m of the previous to avoid
  /// sending redundant waypoints to the routing engine.
  static List<LatLng> _deduplicateClose(List<LatLng> points) {
    if (points.isEmpty) return points;
    final out = <LatLng>[points.first];
    for (var i = 1; i < points.length; i++) {
      final prev = out.last;
      final cur = points[i];
      final dlat = (prev.latitude - cur.latitude).abs();
      final dlon = (prev.longitude - cur.longitude).abs();
      if (dlat < 0.0001 && dlon < 0.0001) continue;
      out.add(cur);
    }
    return out;
  }
}
