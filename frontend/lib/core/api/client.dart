import 'package:dio/dio.dart';

import '../constants.dart';
import '../timezone_service.dart';

/// Turns a [DioException] into a short, user-friendly message (no raw "cannot be solved by the library").
String userMessageFromDioException(DioException e) {
  final data = e.response?.data;
  if (data is Map) {
    final detail = data['detail'];
    if (detail is String) return detail;
    if (detail is List && detail.isNotEmpty) {
      final parts = <String>[];
      for (final item in detail) {
        if (item is Map && item['msg'] != null) parts.add(item['msg'].toString());
      }
      if (parts.isNotEmpty) return parts.join(' ');
    }
    if (e.response?.statusCode != null) {
      return 'Server error (${e.response!.statusCode}). Try again.';
    }
  }
  // No response: connection error, timeout, or wrong URL (e.g. device using localhost).
  switch (e.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.unknown:
      return "Can't reach server. First load can take up to 1 min (free hosting). Try again—check internet.";
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return "Server took too long (may be waking up). Wait a moment and try again.";
    default:
      break;
  }
  final msg = e.message ?? e.type.toString();
  if (msg.isEmpty) return "Network error. Check internet or try again.";
  if (msg.contains('cannot be solved by the library') || msg.contains('connection failed')) {
    return "Can't reach server. First load can take up to 1 min (free hosting). Try again—check internet.";
  }
  return msg;
}

/// Global Dio instance with base URL and X-Timezone header.
Dio createApiClient({String? authToken}) {
  // Render free tier cold-starts can take 50–90s; use longer timeouts for mobile.
  final dio = Dio(BaseOptions(
    baseUrl: kApiBaseUrl,
    connectTimeout: const Duration(seconds: 90),
    receiveTimeout: const Duration(seconds: 90),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'X-Timezone': TimezoneService.instance.deviceTimezone,
    },
  ));

  if (authToken != null && authToken.isNotEmpty) {
    dio.options.headers['Authorization'] = 'Bearer $authToken';
  }

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      // Ensure X-Timezone is always current (e.g. after app resume)
      options.headers['X-Timezone'] = TimezoneService.instance.deviceTimezone;
      handler.next(options);
    },
  ));

  return dio;
}
