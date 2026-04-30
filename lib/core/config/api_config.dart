/// Backend base URL from Swagger `servers[0].url`.
///
/// - Android emulator → host machine: use `http://10.0.2.2:8088/api`
/// - iOS simulator → `http://127.0.0.1:8088/api`
/// - Physical device → your PC LAN IP, e.g. `http://192.168.1.10:8088/api`
///
/// Override at build time: `flutter run --dart-define=API_BASE_URL=http://.../api`
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://global-logistics.duckdns.org/api',
  );
}
