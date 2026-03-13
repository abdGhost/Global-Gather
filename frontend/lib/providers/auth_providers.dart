import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the current auth token (JWT) if the user is logged in.
final authTokenProvider = StateProvider<String?>((ref) => null);

