import 'package:dio/dio.dart';
import 'package:global_logistics_app/core/config/api_config.dart';
import 'package:global_logistics_app/core/network/auth_response_tokens.dart';
import 'package:global_logistics_app/data/storage/token_storage.dart';

/// Calls `POST /auth/refresh` and persists tokens. Shared by proactive and reactive flows.
Future<String?> executeTokenRefresh(String refreshToken) async {
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
  try {
    final res = await bare.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    final data = res.data;
    final access = readAccessTokenFromBody(data);
    final nextRefresh = readRefreshTokenFromBody(data) ?? refreshToken;
    if (access != null) {
      await TokenStorage.instance.persistTokens(
        access: access,
        refresh: nextRefresh,
      );
    }
    return access;
  } catch (_) {
    return null;
  }
}
