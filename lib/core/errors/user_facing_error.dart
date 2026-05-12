import 'package:dio/dio.dart';

/// Maximum length for a server-provided message shown in the UI.
const int _kMaxUserMessageLength = 280;

/// Converts API and other failures into short, non-technical copy for SnackBars
/// and inline error states. Full details remain in logs / interceptors.
String userFacingMessage(Object error) {
  if (error is DioException) {
    return _fromDio(error);
  }
  final raw = error.toString().trim();
  if (raw.isEmpty) {
    return 'Something went wrong. Please try again.';
  }
  if (_looksLikeTechnicalDump(raw)) {
    return 'Something went wrong. Please try again.';
  }
  if (raw.startsWith('Exception: ')) {
    final inner = raw.substring('Exception: '.length).trim();
    if (inner.isNotEmpty &&
        inner.length <= _kMaxUserMessageLength &&
        !_looksLikeTechnicalDump(inner)) {
      return _clampPlain(inner);
    }
  }
  if (raw.length <= _kMaxUserMessageLength && !_looksLikeTechnicalDump(raw)) {
    return _clampPlain(raw);
  }
  return 'Something went wrong. Please try again.';
}

bool _looksLikeTechnicalDump(String s) {
  final lower = s.toLowerCase();
  if (lower.contains('dioexception')) return true;
  if (lower.contains('package:') && lower.contains('.dart')) return true;
  if (lower.contains('stacktrace')) return true;
  return false;
}

String _fromDio(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'The request timed out. Check your connection and try again.';
    case DioExceptionType.connectionError:
      return 'Could not reach the server. Check your internet connection.';
    case DioExceptionType.cancel:
      return 'The request was cancelled.';
    case DioExceptionType.badCertificate:
      return 'A secure connection could not be established.';
    case DioExceptionType.unknown:
      final errText = e.error?.toString() ?? '';
      if (errText.contains('SocketException') ||
          (e.message?.contains('SocketException') ?? false)) {
        return 'Could not reach the server. Check your internet connection.';
      }
      break;
    case DioExceptionType.badResponse:
      break;
  }

  final fromBody = _messageFromResponseData(e.response?.data);
  if (fromBody != null && fromBody.isNotEmpty) {
    return _clampPlain(fromBody);
  }

  final status = e.response?.statusCode;
  if (status != null) {
    switch (status) {
      case 400:
        return 'This request could not be processed. Check your input and try again.';
      case 401:
        return 'Sign in failed. Check your phone number and password, then try again.';
      case 403:
        return 'You do not have permission to do this.';
      case 404:
        return 'The requested item was not found.';
      case 409:
        return 'This action conflicts with the current state. Refresh and try again.';
      case 422:
        return 'Some information is invalid. Please check and try again.';
      case 429:
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        if (status >= 500) {
          return 'The server is temporarily unavailable. Please try again later.';
        }
    }
  }

  return 'Something went wrong. Please try again.';
}

String? _messageFromResponseData(dynamic data) {
  if (data == null) return null;
  if (data is String) {
    final t = data.trim();
    if (t.isEmpty) return null;
    if (_isLikelyHtml(t) || t.length > 800) return null;
    return t;
  }
  if (data is Map) {
    for (final key in <String>[
      'message',
      'error',
      'detail',
      'title',
      'description',
    ]) {
      final v = data[key];
      if (v is String) {
        final t = v.trim();
        if (t.isNotEmpty && !_isLikelyHtml(t)) return t;
      }
      if (v is List && v.isNotEmpty) {
        final extracted = _messageFromResponseData(v.first);
        if (extracted != null) return extracted;
      }
    }
    final errors = data['errors'];
    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          final first = value.first;
          if (first is String && first.trim().isNotEmpty) {
            return first.trim();
          }
        }
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }
  }
  if (data is List && data.isNotEmpty) {
    return _messageFromResponseData(data.first);
  }
  return null;
}

bool _isLikelyHtml(String s) {
  final lower = s.toLowerCase();
  return lower.contains('<!doctype') || lower.contains('<html');
}

String _clampPlain(String message) {
  var t = message.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (t.length > _kMaxUserMessageLength) {
    t = '${t.substring(0, _kMaxUserMessageLength - 1).trim()}…';
  }
  if (_looksLikeTechnicalDump(t)) {
    return 'Something went wrong. Please try again.';
  }
  return t;
}
