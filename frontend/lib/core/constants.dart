/// API base URL. Build-time override: --dart-define=API_BASE_URL=<url>
/// Default is the live Render API so APK/device works without passing the define.
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://global-events.onrender.com',
);
