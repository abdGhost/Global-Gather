import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/client.dart';
import 'auth_providers.dart';

/// API client configured with base URL, timezone header, and optional auth.
final apiClientProvider = Provider<Dio>((ref) {
  final token = ref.watch(authTokenProvider);
  return createApiClient(authToken: token);
});
