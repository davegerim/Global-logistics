/// Extracts access / refresh token strings from auth JSON (camelCase, snake_case,
/// optional one-level `data` wrapper).
String? readAccessTokenFromBody(Map<String, dynamic>? root) {
  if (root == null) return null;
  final nested = root['data'];
  final maps = <Map<String, dynamic>>[root];
  if (nested is Map<String, dynamic>) maps.add(nested);
  const keys = ['accessToken', 'access_token', 'token'];
  for (final m in maps) {
    for (final key in keys) {
      final s = _nonEmptyString(m[key]);
      if (s != null) return s;
    }
  }
  return null;
}

String? readRefreshTokenFromBody(Map<String, dynamic>? root) {
  if (root == null) return null;
  final nested = root['data'];
  final maps = <Map<String, dynamic>>[root];
  if (nested is Map<String, dynamic>) maps.add(nested);
  const keys = ['refreshToken', 'refresh_token'];
  for (final m in maps) {
    for (final key in keys) {
      final s = _nonEmptyString(m[key]);
      if (s != null) return s;
    }
  }
  return null;
}

String? _nonEmptyString(Object? v) {
  if (v is String && v.trim().isNotEmpty) return v;
  return null;
}
