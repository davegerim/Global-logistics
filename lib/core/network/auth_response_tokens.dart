/// Extracts access / refresh token strings from auth JSON (camelCase, snake_case,
/// optional `data` wrapper, common nested `tokens` / `auth` / `session` maps).
String? readAccessTokenFromBody(Map<String, dynamic>? root) {
  if (root == null) return null;
  const keys = ['accessToken', 'access_token', 'token', 'jwt', 'access'];
  for (final m in _authMapsToScan(root)) {
    for (final key in keys) {
      final s = _nonEmptyString(m[key]);
      if (s != null) return s;
    }
  }
  return null;
}

String? readRefreshTokenFromBody(Map<String, dynamic>? root) {
  if (root == null) return null;
  const keys = ['refreshToken', 'refresh_token', 'refresh'];
  for (final m in _authMapsToScan(root)) {
    for (final key in keys) {
      final s = _nonEmptyString(m[key]);
      if (s != null) return s;
    }
  }
  return null;
}

/// Root, one-level `data`, and common nested credential objects.
Iterable<Map<String, dynamic>> _authMapsToScan(Map<String, dynamic> root) sync* {
  yield root;
  final data = root['data'];
  if (data is Map<String, dynamic>) {
    yield data;
    for (final key in ['tokens', 'result', 'auth', 'session', 'authentication']) {
      final inner = data[key];
      if (inner is Map<String, dynamic>) yield inner;
    }
  }
  for (final key in ['tokens', 'result', 'auth', 'session', 'authentication']) {
    final v = root[key];
    if (v is Map<String, dynamic>) yield v;
  }
}

String? _nonEmptyString(Object? v) {
  if (v is String && v.trim().isNotEmpty) return v;
  return null;
}
