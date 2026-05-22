import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppConfig {
  AppConfig._();

  static Map<String, String> _env = const {};
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    final envFile = await _resolveEnvFile();
    final raw = await rootBundle.loadString(envFile);
    _env = _parseEnv(raw);
    _loaded = true;
  }

  static String get apiBaseUrl {
    _assertLoaded();
    final value = _env['API_BASE_URL']?.trim();
    if (value == null || value.isEmpty) {
      throw StateError('API_BASE_URL is missing from the selected env file.');
    }
    return value;
  }

  static String get environmentName {
    _assertLoaded();
    return _env['APP_ENV']?.trim().isNotEmpty == true
        ? _env['APP_ENV']!.trim()
        : (kReleaseMode ? 'production' : 'development');
  }

  static Future<String> _resolveEnvFile() async {
    const appEnv = String.fromEnvironment('APP_ENV');
    if (appEnv.isNotEmpty) {
      final explicit = 'assets/env/$appEnv.env';
      if (await _assetExists(explicit)) return explicit;
    }

    if (!kReleaseMode && await _assetExists('assets/env/local.env')) {
      return 'assets/env/local.env';
    }

    return kReleaseMode
        ? 'assets/env/production.env'
        : 'assets/env/development.env';
  }

  static Future<bool> _assetExists(String path) async {
    try {
      await rootBundle.loadString(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Map<String, String> _parseEnv(String raw) {
    final values = <String, String>{};
    for (final line in raw.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final separator = trimmed.indexOf('=');
      if (separator <= 0) continue;
      final key = trimmed.substring(0, separator).trim();
      final value = trimmed.substring(separator + 1).trim();
      values[key] = value;
    }
    return values;
  }

  static void _assertLoaded() {
    if (_loaded) return;
    throw StateError('AppConfig.load() must be called before reading config.');
  }

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
