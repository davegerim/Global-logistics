import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Logs every request payload and response body to the console (debug mode).
class PayloadLogInterceptor extends Interceptor {
  static const _tag = 'GL_API';

  void _chunkPrint(String message) {
    const max = 900;
    for (var i = 0; i < message.length; i += max) {
      final end = i + max > message.length ? message.length : i + max;
      debugPrint(message.substring(i, end));
    }
  }

  void _log(String title, String body) {
    debugPrint('');
    debugPrint(
      '╔══════════════════════════════════════════════════════════════',
    );
    debugPrint('║ $_tag $title');
    debugPrint(
      '╠══════════════════════════════════════════════════════════════',
    );
    _chunkPrint(body);
    debugPrint(
      '╚══════════════════════════════════════════════════════════════',
    );
    debugPrint('');
  }

  String _tryEncode(dynamic data) {
    if (data == null) return '(empty body)';
    try {
      if (data is String) return data;
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final uri = options.uri;
    final headers = Map<String, dynamic>.from(options.headers);
    // Shorten noisy default headers
    headers.remove('content-length');
    final payload = <String, dynamic>{
      'method': options.method,
      'url': uri.toString(),
      'headers': headers,
      'queryParameters': options.queryParameters,
      'data': options.data,
    };
    _log('REQUEST', _tryEncode(payload));
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final payload = <String, dynamic>{
      'statusCode': response.statusCode,
      'request': response.requestOptions.uri.toString(),
      'data': response.data,
    };
    _log('RESPONSE', _tryEncode(payload));
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final payload = <String, dynamic>{
      'type': err.type.name,
      'message': err.message,
      'request': err.requestOptions.uri.toString(),
      'responseStatus': err.response?.statusCode,
      'responseData': err.response?.data,
    };
    _log('ERROR', _tryEncode(payload));
    handler.next(err);
  }
}
