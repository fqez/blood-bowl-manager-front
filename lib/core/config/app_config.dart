class AppConfig {
  AppConfig._();

  // API Configuration
  // static const String apiBaseUrl = 'http://localhost:8081';
  static const String apiBaseUrl =
      'https://web-production-9aceb.up.railway.app';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Pagination
  static const int defaultPageSize = 20;

  // Cache
  static const Duration cacheExpiration = Duration(minutes: 5);

  // Token Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'current_user';
}
