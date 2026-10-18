/// Helpers for `/drivers/profile` and `/consignors/profile` API payloads.
abstract final class RoleProfileUtils {
  static const _nestedKeys = [
    'driver',
    'driverProfile',
    'driverDetails',
    'consignor',
    'consignorProfile',
    'consignorDetails',
    'vehicle',
    'vehicleProfile',
    'vehicleDetails',
    'profile',
    'data',
  ];

  static dynamic _value(Map<String, dynamic> raw, String key) {
    if (raw.containsKey(key)) return raw[key];
    for (final nest in _nestedKeys) {
      final n = raw[nest];
      if (n is Map<String, dynamic> && n.containsKey(key)) return n[key];
      if (n is Map && n.containsKey(key)) {
        return n[key];
      }
    }
    return null;
  }

  static String? stringField(Map<String, dynamic>? raw, String key) {
    if (raw == null) return null;
    final v = _value(raw, key);
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  /// Reads the first non-empty value among [keys], including nested profile maps.
  static String? firstStringField(
    Map<String, dynamic>? raw,
    List<String> keys,
  ) {
    if (raw == null) return null;
    for (final key in keys) {
      final value = stringField(raw, key);
      if (value != null) return value;
    }
    return null;
  }

  /// Vehicle profile document keys — API returns abbreviated names (`libreDoc`)
  /// while registration sends `libreDocument`.
  static const vehicleLibreDocumentKeys = [
    'libreDoc',
    'libreDocument',
    'libre_document',
    'libre_doc',
    'libriDocument',
    'libri_document',
  ];

  static const vehicleLibreDocumentSecKeys = [
    'libreDocSec',
    'libreDocumentSec',
    'libre_document_sec',
    'libre_doc_sec',
    'libriDocumentSec',
    'libri_document_sec',
  ];

  static const vehicleInsuranceDocumentKeys = [
    'insuranceDoc',
    'insuranceDocument',
    'insurance_document',
  ];

  static bool looksLikeUrl(String? value) {
    if (value == null) return false;
    final t = value.trim().toLowerCase();
    return t.startsWith('http://') || t.startsWith('https://');
  }

  static bool looksLikeImageUrl(String value) {
    if (!looksLikeUrl(value)) return false;
    final path = Uri.tryParse(value.trim())?.path.toLowerCase() ?? '';
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.webp') ||
        path.endsWith('.gif') ||
        path.endsWith('.bmp') ||
        path.endsWith('.heic') ||
        path.endsWith('.heif');
  }

  static bool looksLikePdfUrl(String value) {
    if (!looksLikeUrl(value)) return false;
    final path = Uri.tryParse(value.trim())?.path.toLowerCase() ?? '';
    return path.endsWith('.pdf');
  }

  /// Unwraps common API envelopes and merges nested profile/vehicle maps for lookup.
  static Map<String, dynamic> flattenForFieldLookup(Map<String, dynamic> raw) {
    var current = raw;
    for (final wrap in ['data', 'content', 'result', 'payload']) {
      final inner = current[wrap];
      if (inner is Map<String, dynamic>) {
        current = inner;
        break;
      }
      if (inner is Map) {
        current = Map<String, dynamic>.from(inner);
        break;
      }
    }

    final out = Map<String, dynamic>.from(current);

    void absorb(Map<String, dynamic> source) {
      for (final entry in source.entries) {
        if (entry.key == 'data' ||
            entry.key == 'content' ||
            entry.key == 'result' ||
            entry.key == 'payload' ||
            entry.key == 'vehicles') {
          continue;
        }
        final existing = out[entry.key];
        final existingEmpty =
            existing == null || existing.toString().trim().isEmpty;
        final incoming = entry.value;
        if (existingEmpty &&
            incoming != null &&
            incoming.toString().trim().isNotEmpty) {
          out[entry.key] = incoming;
        }
      }
      for (final nest in _nestedKeys) {
        final nested = source[nest];
        if (nested is Map<String, dynamic>) {
          absorb(nested);
        } else if (nested is Map) {
          absorb(Map<String, dynamic>.from(nested));
        }
      }
    }

    for (final listKey in ['vehicles', 'items']) {
      final list = current[listKey];
      if (list is List && list.isNotEmpty) {
        final first = list.first;
        if (first is Map<String, dynamic>) {
          absorb(first);
        } else if (first is Map) {
          absorb(Map<String, dynamic>.from(first));
        }
      }
    }

    absorb(current);
    return out;
  }

  static double? _parseDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim());
    return null;
  }

  static Map<String, dynamic>? _ratingObject(Map<String, dynamic>? raw) {
    if (raw == null) return null;
    final v = _value(raw, 'rating');
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  static double? rating(Map<String, dynamic>? raw) {
    if (raw == null) return null;
    final ratingMap = _ratingObject(raw);
    if (ratingMap != null) {
      for (final key in ['value', 'average', 'avg', 'rating', 'score']) {
        final d = _parseDouble(ratingMap[key]);
        if (d != null) return d;
      }
    }
    for (final key in [
      'rating',
      'averageRating',
      'avgRating',
      'driverRating',
      'consignorRating',
    ]) {
      final v = _value(raw, key);
      if (v is Map) continue;
      final d = _parseDouble(v);
      if (d != null) return d;
    }
    return null;
  }

  static int? _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  static bool _isReviewCountKey(String key) {
    final k = key.toLowerCase().replaceAll('_', '');
    const exact = {
      'reviewcount',
      'numberofreviews',
      'reviewscount',
      'totalreviews',
      'reviewtotal',
      'noofreviews',
      'feedbackcount',
      'totalreviewcount',
      'countofreviews',
    };
    if (exact.contains(k)) return true;
    return k.contains('review') && k.contains('count');
  }

  static int? _findReviewCountDeep(Map<String, dynamic> map, [int depth = 0]) {
    if (depth > 5) return null;
    for (final entry in map.entries) {
      if (_isReviewCountKey(entry.key)) {
        final n = _parseInt(entry.value);
        if (n != null) return n;
      }
      final child = entry.value;
      if (child is Map<String, dynamic>) {
        final nested = _findReviewCountDeep(child, depth + 1);
        if (nested != null) return nested;
      } else if (child is Map) {
        final nested = _findReviewCountDeep(
          Map<String, dynamic>.from(child),
          depth + 1,
        );
        if (nested != null) return nested;
      }
    }
    return null;
  }

  static int? reviewCount(Map<String, dynamic>? raw) {
    if (raw == null) return null;
    final ratingMap = _ratingObject(raw);
    if (ratingMap != null) {
      for (final key in [
        'reviewCount',
        'numberOfReviews',
        'reviewsCount',
        'totalReviews',
        'reviews',
        'count',
      ]) {
        final v = ratingMap[key];
        final asInt = _parseInt(v);
        if (asInt != null) return asInt;
        if (v is List) return v.length;
      }
    }
    for (final key in [
      'reviewCount',
      'numberOfReviews',
      'reviewsCount',
      'totalReviews',
      'reviewTotal',
      'noOfReviews',
      'feedbackCount',
      'totalReviewCount',
    ]) {
      final n = _parseInt(_value(raw, key));
      if (n != null) return n;
    }
    final reviews = _value(raw, 'reviews');
    final asInt = _parseInt(reviews);
    if (asInt != null) return asInt;
    if (reviews is List) return reviews.length;
    return _findReviewCountDeep(raw);
  }

  static String formatRating(double? value) {
    if (value == null) return '-';
    return value.toStringAsFixed(1);
  }

  static String formatReviewCount(int? count) {
    if (count == null) return '-';
    return count.toString();
  }
}
