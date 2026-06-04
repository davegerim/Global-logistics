import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Normalizes `GET /tracking/{assignmentId}` payloads into chronological WGS84 points.
abstract final class TrackingRouteCoords {
  static const _containerKeys = [
    'points',
    'trackings',
    'trackingPoints',
    'locations',
    'locationHistory',
    'gpsPoints',
    'route',
    'path',
    'trajectory',
    'history',
    'records',
    'trace',
    'data',
    'content',
    'items',
    'results',
    'elements',
  ];

  static const _nestedMaps = [
    'location',
    'coordinates',
    'coordinate',
    'position',
    'geo',
    'point',
  ];

  static const _timeKeys = [
    'recordedAt',
    'recorded_at',
    'createdAt',
    'created_at',
    'timestamp',
    'time',
    'date',
  ];

  /// Flattens list/map API shapes into individual tracking point maps.
  static List<Map<String, dynamic>> flattenRecords(dynamic raw) {
    final out = <Map<String, dynamic>>[];
    _collect(raw, out);
    return out;
  }

  static void _collect(dynamic raw, List<Map<String, dynamic>> out) {
    if (raw == null) return;
    if (raw is List) {
      if (raw.isNotEmpty && raw.first is! List && raw.first is! Map) {
        final ll = _fromNumberPair(raw);
        if (ll != null) {
          out.add({
            'latitude': ll.latitude,
            'longitude': ll.longitude,
          });
          return;
        }
      }
      for (final item in raw) {
        if (item is List && item.length >= 2 && item.first is num) {
          final ll = _fromNumberPair(item);
          if (ll != null) {
            out.add({
              'latitude': ll.latitude,
              'longitude': ll.longitude,
            });
          }
          continue;
        }
        _collect(item, out);
      }
      return;
    }
    if (raw is Map) {
      final map = raw.cast<String, dynamic>();
      final before = out.length;
      for (final key in _containerKeys) {
        final nested = map[key];
        if (nested != null) _collect(nested, out);
      }
      _collectLineStringCoordinates(map['coordinates'], out);
      if (out.length > before) return;
      if (_isCoordinateLeaf(map)) out.add(map);
    }
  }

  static void _collectLineStringCoordinates(
    dynamic coordinates,
    List<Map<String, dynamic>> out,
  ) {
    if (coordinates is! List || coordinates.isEmpty) return;
    if (coordinates.first is! List) return;
    for (final segment in coordinates) {
      if (segment is! List) continue;
      final ll = _fromNumberPair(segment);
      if (ll == null) continue;
      out.add({
        'latitude': ll.latitude,
        'longitude': ll.longitude,
      });
    }
  }

  static bool _isCoordinateLeaf(Map<String, dynamic> map) {
    return _resolveLatLng(map) != null;
  }

  static List<Map<String, dynamic>> sortByRecordedAt(
    List<Map<String, dynamic>> records,
  ) {
    final indexed = records.asMap().entries.toList();
    indexed.sort((a, b) {
      final ta = _recordedAt(a.value);
      final tb = _recordedAt(b.value);
      if (ta != null && tb != null) return ta.compareTo(tb);
      if (ta != null) return -1;
      if (tb != null) return 1;
      final seqA = _sequence(a.value) ?? a.key;
      final seqB = _sequence(b.value) ?? b.key;
      if (seqA != seqB) return seqA.compareTo(seqB);
      return a.key.compareTo(b.key);
    });
    return indexed.map((e) => e.value).toList();
  }

  static List<LatLng> toPolyline(List<Map<String, dynamic>> records) {
    final coords = <LatLng>[];
    for (final record in sortByRecordedAt(records)) {
      coords.addAll(_coordsFromRecord(record));
    }
    return _withoutConsecutiveDuplicates(coords);
  }

  /// Expands nested `path` / `points` arrays before the parent summary coordinate.
  static List<LatLng> _coordsFromRecord(Map<String, dynamic> record) {
    final nested = <Map<String, dynamic>>[];
    final scratch = <Map<String, dynamic>>[];
    for (final key in _containerKeys) {
      final raw = record[key];
      if (raw == null) continue;
      final before = scratch.length;
      _collect(raw, scratch);
      if (scratch.length > before) {
        nested.addAll(scratch.sublist(before));
      }
    }
    final coordBefore = scratch.length;
    _collectLineStringCoordinates(record['coordinates'], scratch);
    if (scratch.length > coordBefore) {
      nested.addAll(scratch.sublist(coordBefore));
    }

    if (nested.length >= 2) {
      final line = <LatLng>[];
      for (final point in nested) {
        final ll = toLatLng(point);
        if (ll != null) line.add(ll);
      }
      if (line.length >= 2) return line;
    }

    final single = toLatLng(record);
    return single == null ? const [] : [single];
  }

  static List<LatLng> _withoutConsecutiveDuplicates(List<LatLng> coords) {
    if (coords.isEmpty) return coords;
    final out = <LatLng>[coords.first];
    for (var i = 1; i < coords.length; i++) {
      final prev = out.last;
      final cur = coords[i];
      if ((prev.latitude - cur.latitude).abs() < 1e-7 &&
          (prev.longitude - cur.longitude).abs() < 1e-7) {
        continue;
      }
      out.add(cur);
    }
    return out;
  }

  static int? _sequence(Map<String, dynamic> record) {
    for (final key in ['sequence', 'seq', 'index', 'order', 'id']) {
      final v = record[key];
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
    }
    return null;
  }

  static LatLng? toLatLng(Map<String, dynamic>? point) {
    if (point == null) return null;
    return _resolveLatLng(point);
  }

  static LatLng? _resolveLatLng(Map<String, dynamic> point) {
    final direct = _pairFromMap(point, ['latitude', 'lat'], [
      'longitude',
      'lng',
      'lon',
    ]);
    if (direct != null) return direct;

    final current = _pairFromMap(point, [
      'currentLatitude',
      'driverLatitude',
    ], [
      'currentLongitude',
      'driverLongitude',
    ]);
    if (current != null) return current;

    final xy = _pairFromMap(point, ['y', 'northing'], ['x', 'easting', 'lng']);
    if (xy != null) return xy;

    for (final key in _nestedMaps) {
      final nested = point[key];
      if (nested is Map) {
        final ll = _resolveLatLng(nested.cast<String, dynamic>());
        if (ll != null) return ll;
      }
      if (nested is List) {
        final ll = _fromNumberPair(nested);
        if (ll != null) return ll;
      }
    }

    final coordinates = point['coordinates'];
    if (coordinates is List) {
      return _fromNumberPair(coordinates);
    }

    for (final key in ['position', 'gps', 'coords', 'coordinate', 'geo']) {
      final v = point[key];
      if (v is String) {
        final ll = _fromPositionString(v);
        if (ll != null) return ll;
      }
    }
    return null;
  }

  static LatLng? _fromPositionString(String raw) {
    final match = RegExp(
      r'(-?\d+(?:\.\d+)?)\s*[,;\s]\s*(-?\d+(?:\.\d+)?)',
    ).firstMatch(raw.trim());
    if (match == null) return null;
    final first = double.tryParse(match.group(1)!);
    final second = double.tryParse(match.group(2)!);
    if (first == null || second == null) return null;
    return _resolvePair(first, second);
  }

  static LatLng? _pairFromMap(
    Map<String, dynamic> map,
    List<String> latKeys,
    List<String> lonKeys,
  ) {
    final a = _readCoord(map, latKeys);
    final b = _readCoord(map, lonKeys);
    if (a == null || b == null) return null;
    return _resolvePair(a, b);
  }

  static LatLng? _fromNumberPair(List<dynamic> pair) {
    if (pair.length < 2) return null;
    final first = _asDouble(pair[0]);
    final second = _asDouble(pair[1]);
    if (first == null || second == null) return null;
    return _resolvePair(first, second);
  }

  static LatLng? _resolvePair(double first, double second) {
    if (_looksMercatorMeters(first, second) ||
        _looksMercatorMeters(second, first)) {
      // API rows often store Web Mercator easting in `longitude` and northing in `latitude`.
      return _mercatorToWgs84(
        second.abs() >= first.abs() ? second : first,
        second.abs() >= first.abs() ? first : second,
      );
    }
    if (_isLikelyLatLon(first, second)) return LatLng(first, second);
    if (_isLikelyLatLon(second, first)) return LatLng(second, first);
    return null;
  }

  /// Rejects swapped GeoJSON-style [lon, lat] pairs misread as [lat, lon].
  static bool _isLikelyLatLon(double lat, double lon) {
    if (!_isWgs84(lat, lon)) return false;
    if (lat.abs() > 20 && lon.abs() <= 20) return false;
    if (lat.abs() <= 20 && lon.abs() > 20) return true;
    return lat.abs() <= 20 || lat.abs() <= lon.abs();
  }

  static bool _isWgs84(double lat, double lon) =>
      lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180;

  static bool _looksMercatorMeters(double a, double b) =>
      a.abs() > 90 ||
      b.abs() > 180 ||
      (a.abs() > 1000 && b.abs() > 1000);

  static LatLng _mercatorToWgs84(double x, double y) {
    const origin = 20037508.342789244;
    final lon = (x / origin) * 180.0;
    final latRadians = (y / origin) * math.pi;
    final lat =
        180.0 / math.pi * (2 * math.atan(math.exp(latRadians)) - math.pi / 2);
    return LatLng(lat, lon);
  }

  static double? _readCoord(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      final parsed = _asDouble(v);
      if (parsed != null) return parsed;
    }
    return null;
  }

  static double? _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static DateTime? _recordedAt(Map<String, dynamic> m) {
    for (final k in _timeKeys) {
      final v = m[k];
      if (v == null) continue;
      if (v is DateTime) return v.toUtc();
      if (v is num) {
        final ms = v > 1e12 ? v.toInt() : (v * 1000).toInt();
        return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
      }
      if (v is String) {
        final parsed = DateTime.tryParse(v);
        if (parsed != null) return parsed.toUtc();
      }
    }
    return null;
  }
}
