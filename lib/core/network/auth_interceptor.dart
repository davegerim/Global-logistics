import 'package:dio/dio.dart';
import 'package:global_logistics_app/core/config/api_config.dart';
import 'package:global_logistics_app/data/storage/token_cache.dart';
import 'package:global_logistics_app/data/storage/token_storage.dart';

/// Attaches Bearer token and refreshes once on 401 using `/auth/refresh`.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required Dio dio}) : _dio = dio;

  final Dio _dio;
  static Future<String?>? _refreshFuture;

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

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final t = TokenCache.instance.accessToken;
    if (t != null && !_isPublic(options)) {
      options.headers['Authorization'] = 'Bearer $t';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }
    final path = err.requestOptions.uri.path;
    if (path.endsWith('/auth/refresh') || path.endsWith('/auth/login')) {
      handler.next(err);
      return;
    }
    final refresh = TokenCache.instance.refreshToken;
    if (refresh == null) {
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
    _refreshFuture ??= _doRefresh(refresh);
    _refreshFuture!
        .then((newAccess) async {
          _refreshFuture = null;
          if (newAccess == null || newAccess.isEmpty) {
            handler.next(err);
            return;
          }
          try {
            final req = err.requestOptions;
            req.headers['Authorization'] = 'Bearer $newAccess';
            final clone = await _dio.fetch(req);
            handler.resolve(clone);
          } catch (_) {
            handler.next(err);
          }
        })
        .catchError((_) {
          _refreshFuture = null;
          handler.next(err);
        });
  }

  Future<String?> _doRefresh(String refreshToken) async {
    final bare = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    final res = await bare.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    final data = res.data;
    if (data == null) return null;
    final access = data['accessToken'] as String?;
    final nextRefresh = data['refreshToken'] as String? ?? refreshToken;
    if (access != null) {
      await TokenStorage.instance.persistTokens(
        access: access,
        refresh: nextRefresh,
      );
    }
    return access;
  }
}
