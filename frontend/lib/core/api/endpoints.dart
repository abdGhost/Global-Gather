/// API path constants (no base URL).
class Endpoints {
  Endpoints._();

  static const String authRegister = '/api/auth/register';
  static const String authLogin = '/api/auth/login';
  static const String authMe = '/api/auth/me';
  static const String authMeTimezone = '/api/auth/me';

  static const String eventsTrending = '/api/events/trending';
  static const String eventsSearch = '/api/events/search';
  static const String eventsNearby = '/api/events/nearby';
  static const String eventsCreate = '/api/events';
  static String eventDetail(String id) => '/api/events/$id';
  static String eventChat(String id) => '/ws/chat/$id';
}
