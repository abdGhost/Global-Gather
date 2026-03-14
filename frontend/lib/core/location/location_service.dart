import 'package:geolocator/geolocator.dart';

/// Why location could not be obtained (for UI message / opening settings).
enum LocationFailureReason {
  permissionDenied,
  serviceDisabled,
  timeoutOrError,
}

/// Result of requesting location: either a [Position] or a [LocationFailureReason].
class LocationResult {
  const LocationResult._({this.position, this.failureReason});

  final Position? position;
  final LocationFailureReason? failureReason;

  factory LocationResult.success(Position position) =>
      LocationResult._(position: position);

  factory LocationResult.failure(LocationFailureReason reason) =>
      LocationResult._(failureReason: reason);

  bool get isSuccess => position != null;
}

/// Helper for requesting permission and reading the user's current location.
class LocationService {
  LocationService._();

  /// Requests permission (shows the system "Allow location?" dialog),
  /// then fetches the current position. Returns [LocationResult] so the UI
  /// can show the right message or open settings (e.g. when Location is off).
  static Future<LocationResult> requestAndGetCurrentPosition() async {
    // 1. Request app permission first so the user sees the Allow/Deny dialog.
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationResult.failure(LocationFailureReason.permissionDenied);
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return LocationResult.failure(LocationFailureReason.permissionDenied);
    }

    // 2. Check if device location service (GPS) is on.
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationResult.failure(LocationFailureReason.serviceDisabled);
    }

    // 3. Fetch position with timeout so we don't hang.
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        ),
      );
      return LocationResult.success(position);
    } catch (_) {
      return LocationResult.failure(LocationFailureReason.timeoutOrError);
    }
  }

  /// Opens the device location settings so the user can turn Location on.
  static Future<bool> openLocationSettings() =>
      Geolocator.openLocationSettings();
}


