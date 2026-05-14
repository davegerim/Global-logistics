import 'package:dio/dio.dart';
import 'package:global_logistics_app/core/network/jwt_access_expiry.dart';
import 'package:global_logistics_app/core/network/token_refresh_executor.dart';
import 'package:global_logistics_app/data/storage/token_cache.dart';

/// Attaches Bearer token; **proactively** refreshes when JWT `exp` is near;
/// **reactively** refreshes on 401/403 using `/auth/refresh` if proactive did not help.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Single in-flight refresh for proactive + reactive deduplication.
  static Future<String?>? _refreshFuture;

  /// Prevents refresh+retry loops when the server returns a persistent 403/401.
  static const _retryExtraKey = 'gl_auth_refresh_retried';

  static const _publicPathSuffixes = <String>[
    '/auth/login',
    '/auth/register',
    '/auth/otp/send',
    '/auth/otp/verify',
    '/auth/refresh',
    '/auth/forget-password',
    '/auth/reset-password',
  ];

  bool _isPublic(RequestOptions o) {
    final p = o.uri.path;
    for (final s in _publicPathSuffixes) {
      if (p.endsWith(s)) return true;
    }
    return false;
  }

  void _attachBearer(RequestOptions options) {
    final t = TokenCache.instance.accessToken;
    if (t != null && t.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $t';
    }
  }

  /// Shared refresh queue — proactive [onRequest] and reactive [onError] use the same future.
  static Future<String?> _coordinatedRefresh(String refreshToken) {
    _refreshFuture ??= _refreshSingleFlight(refreshToken);
    return _refreshFuture!;
  }

  static Future<String?> _refreshSingleFlight(String refreshToken) async {
    try {
      return await executeTokenRefresh(refreshToken);
    } finally {
      _refreshFuture = null;
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_isPublic(options)) {
      handler.next(options);
      return;
    }
    final access = TokenCache.instance.accessToken;
    if (access == null || access.isEmpty) {
      handler.next(options);
      return;
    }
    if (!isAccessTokenExpiringSoon(access)) {
      options.headers['Authorization'] = 'Bearer $access';
      handler.next(options);
      return;
    }
    final rt = TokenCache.instance.refreshToken;
    if (rt == null || rt.isEmpty) {
      options.headers['Authorization'] = 'Bearer $access';
      handler.next(options);
      return;
    }
    _coordinatedRefresh(rt).then((_) {
      _attachBearer(options);
      handler.next(options);
    }).catchError((_) {
      options.headers['Authorization'] = 'Bearer $access';
      handler.next(options);
    });
  }

  bool _isUnauthorizedOrForbidden(DioException err) {
    final code = err.response?.statusCode;
    return code == 401 || code == 403;
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!_isUnauthorizedOrForbidden(err)) {
      handler.next(err);
      return;
    }
    final req = err.requestOptions;
    if (req.extra[_retryExtraKey] == true) {
      handler.next(err);
      return;
    }
    final path = req.uri.path;
    if (path.endsWith('/auth/refresh') || path.endsWith('/auth/login')) {
      handler.next(err);
      return;
    }
    final refresh = TokenCache.instance.refreshToken;
    if (refresh == null || refresh.isEmpty) {
      handler.next(err);
      return;
    }
    _refreshThenRetry(err, handler, refresh);
  }

  void _refreshThenRetry(
    DioException err,
    ErrorInterceptorHandler handler,
    String refresh,
  ) {
    _coordinatedRefresh(refresh).then((newAccess) async {
      if (newAccess == null || newAccess.isEmpty) {
        handler.next(err);
        return;
      }
      try {
        final req = err.requestOptions;
        req.extra[_retryExtraKey] = true;
        req.headers['Authorization'] = 'Bearer $newAccess';
        final clone = await _dio.fetch(req);
        handler.resolve(clone);
      } catch (_) {
        handler.next(err);
      }
    }).catchError((_) {
      handler.next(err);
    });
  }
}
