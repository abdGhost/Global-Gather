import 'package:shared_preferences/shared_preferences.dart';

/// Persists auth token and onboarding state so refresh keeps user logged in.
class AppStorage {
  AppStorage._();

  static const _keyAuthToken = 'auth_token';
  static const _keyOnboardingCompleted = 'onboarding_completed';

  static Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  static Future<String?> getStoredToken() async {
    final prefs = await _prefs;
    return prefs.getString(_keyAuthToken);
  }

  static Future<void> saveToken(String? token) async {
    final prefs = await _prefs;
    if (token == null || token.isEmpty) {
      await prefs.remove(_keyAuthToken);
    } else {
      await prefs.setString(_keyAuthToken, token);
    }
  }

  static Future<bool> getOnboardingCompleted() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyOnboardingCompleted) ?? false;
  }

  static Future<void> setOnboardingCompleted(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyOnboardingCompleted, value);
  }
}
