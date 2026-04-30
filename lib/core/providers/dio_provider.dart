import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_logistics_app/core/config/api_config.dart';
import 'package:global_logistics_app/core/network/auth_interceptor.dart';
import 'package:global_logistics_app/core/network/payload_log_interceptor.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 45),
      receiveTimeout: const Duration(seconds: 45),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );
  dio.interceptors.add(PayloadLogInterceptor());
  dio.interceptors.add(AuthInterceptor(dio: dio));
  return dio;
});
