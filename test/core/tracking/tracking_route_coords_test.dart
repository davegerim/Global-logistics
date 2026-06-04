import 'package:flutter_test/flutter_test.dart';
import 'package:global_logistics_app/core/tracking/tracking_route_coords.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('flattenRecords', () {
    test('unwraps nested points container', () {
      final flat = TrackingRouteCoords.flattenRecords({
        'points': [
          {'latitude': 9.0, 'longitude': 38.0},
          {'latitude': 9.1, 'longitude': 38.1},
          {'latitude': 9.2, 'longitude': 38.2},
        ],
      });
      expect(flat.length, 3);
    });

    test('keeps flat list of tracking rows', () {
      final flat = TrackingRouteCoords.flattenRecords([
        {'latitude': 9.0, 'longitude': 38.0, 'recordedAt': '2026-01-01T10:00:00Z'},
        {'latitude': 9.05, 'longitude': 38.05, 'recordedAt': '2026-01-01T10:15:00Z'},
        {'latitude': 9.1, 'longitude': 38.1, 'recordedAt': '2026-01-01T10:30:00Z'},
      ]);
      expect(flat.length, 3);
    });
  });

  group('toPolyline', () {
    test('sorts by recordedAt so path follows history', () {
      final line = TrackingRouteCoords.toPolyline([
        {'latitude': 9.2, 'longitude': 38.2, 'recordedAt': '2026-01-01T10:30:00Z'},
        {'latitude': 9.0, 'longitude': 38.0, 'recordedAt': '2026-01-01T10:00:00Z'},
        {'latitude': 9.1, 'longitude': 38.1, 'recordedAt': '2026-01-01T10:15:00Z'},
      ]);
      expect(line.length, 3);
      expect(line.first, const LatLng(9.0, 38.0));
      expect(line.last, const LatLng(9.2, 38.2));
    });

    test('converts Web Mercator meters to WGS84 for all pings', () {
      // Addis Ababa area: lon ~38.76°, lat ~8.98°
      const x = 4314300.0;
      const y = 999000.0;
      final line = TrackingRouteCoords.toPolyline([
        {'latitude': y, 'longitude': x, 'recordedAt': '2026-01-01T10:00:00Z'},
        {'latitude': y + 5000, 'longitude': x + 8000, 'recordedAt': '2026-01-01T10:15:00Z'},
        {'latitude': y + 12000, 'longitude': x + 15000, 'recordedAt': '2026-01-01T10:30:00Z'},
      ]);
      expect(line.length, 3);
      expect(line[0].latitude, closeTo(8.98, 0.05));
      expect(line[0].longitude, closeTo(38.76, 0.05));
      expect(line[1].latitude, isNot(line[0].latitude));
      expect(line[1].longitude, isNot(line[0].longitude));
    });

    test('reads GeoJSON coordinate pairs', () {
      final line = TrackingRouteCoords.toPolyline([
        {
          'coordinates': [38.0, 9.0],
          'recordedAt': '2026-01-01T10:00:00Z',
        },
        {
          'coordinates': [38.1, 9.1],
          'recordedAt': '2026-01-01T10:15:00Z',
        },
      ]);
      expect(line.length, 2);
      expect(line.first, const LatLng(9.0, 38.0));
    });

    test('prefers nested path history over parent summary coordinate', () {
      final line = TrackingRouteCoords.toPolyline([
        {
          'latitude': 11.0,
          'longitude': 37.0,
          'path': [
            {'latitude': 11.58, 'longitude': 37.35},
            {'latitude': 11.585, 'longitude': 37.37},
            {'latitude': 11.59, 'longitude': 37.388},
          ],
        },
      ]);
      expect(line.length, 3);
      expect(line.first.latitude, closeTo(11.58, 0.01));
      expect(line.last.latitude, closeTo(11.59, 0.01));
    });

    test('uses four distinct flat pings in API order when recordedAt is null', () {
      final line = TrackingRouteCoords.toPolyline([
        {'latitude': 11.50, 'longitude': 37.30, 'recordedAt': null},
        {'latitude': 11.56, 'longitude': 37.34, 'recordedAt': null},
        {'latitude': 11.585, 'longitude': 37.37, 'recordedAt': null},
        {'latitude': 11.5948858, 'longitude': 37.3882318, 'recordedAt': null},
      ]);
      expect(line.length, 4);
      expect(line.first.latitude, closeTo(11.50, 0.01));
      expect(line.last.latitude, closeTo(11.5948858, 0.0001));
    });

    test('drops consecutive duplicate pings but keeps bends', () {
      final line = TrackingRouteCoords.toPolyline([
        {'latitude': 11.50, 'longitude': 37.30},
        {'latitude': 11.56, 'longitude': 37.34},
        {'latitude': 11.5948858, 'longitude': 37.3882318},
        {'latitude': 11.5948858, 'longitude': 37.3882318},
      ]);
      expect(line.length, 3);
    });
  });
}
