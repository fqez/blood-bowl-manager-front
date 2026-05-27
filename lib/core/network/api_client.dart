import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(_jsonBaseOptions());

  dio.interceptors.add(AuthInterceptor(ref));
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    error: true,
  ));

  return dio;
});

BaseOptions _jsonBaseOptions() {
  return BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: AppConfig.connectTimeout,
    receiveTimeout: AppConfig.receiveTimeout,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );
}

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

class AuthInterceptor extends Interceptor {
  final Ref ref;
  Future<String?>? _refreshFuture;

  AuthInterceptor(this.ref);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip auth header for login/register endpoints
    if (_shouldSkipAuth(options)) {
      return handler.next(options);
    }

    final storage = ref.read(secureStorageProvider);
    final accessToken = await storage.read(key: AppConfig.accessTokenKey);

    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final shouldRefresh = err.response?.statusCode == 401 &&
        !_shouldSkipAuth(err.requestOptions) &&
        err.requestOptions.extra['authRetry'] != true;

    if (shouldRefresh) {
      final newAccessToken = await _refreshAccessToken();
      if (newAccessToken != null) {
        try {
          err.requestOptions.extra['authRetry'] = true;
          err.requestOptions.headers['Authorization'] =
              'Bearer $newAccessToken';

          final retryDio = Dio(_jsonBaseOptions());
          final retryResponse = await retryDio.fetch(err.requestOptions);

          return handler.resolve(retryResponse);
        } catch (_) {
          // Let the original 401 flow to the caller.
        }
      }
    }

    return handler.next(err);
  }

  bool _shouldSkipAuth(RequestOptions options) {
    return options.path.contains('/auth/login') ||
        options.path.contains('/auth/register') ||
        options.path.contains('/auth/refresh');
  }

  Future<String?> _refreshAccessToken() {
    _refreshFuture ??= _doRefreshAccessToken().whenComplete(() {
      _refreshFuture = null;
    });
    return _refreshFuture!;
  }

  Future<String?> _doRefreshAccessToken() async {
    final storage = ref.read(secureStorageProvider);
    final refreshToken = await storage.read(key: AppConfig.refreshTokenKey);

    if (refreshToken == null) return null;

    try {
      final dio = Dio(_jsonBaseOptions());
      final response = await dio.post('/auth/refresh', data: {
        'refresh_token': refreshToken,
      });

      final data = response.data;
      if (data is! Map<String, dynamic>) return null;

      final newAccessToken = data['access_token'] as String?;
      final newRefreshToken = data['refresh_token'] as String?;
      if (newAccessToken == null || newRefreshToken == null) return null;

      await storage.write(key: AppConfig.accessTokenKey, value: newAccessToken);
      await storage.write(
          key: AppConfig.refreshTokenKey, value: newRefreshToken);

      return newAccessToken;
    } catch (_) {
      await storage.delete(key: AppConfig.accessTokenKey);
      await storage.delete(key: AppConfig.refreshTokenKey);
      return null;
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  factory ApiException.fromDioException(DioException e) {
    String message = 'Error de conexión';
    int? statusCode = e.response?.statusCode;

    if (e.response?.data != null) {
      if (e.response!.data is Map) {
        final detail = e.response!.data['detail'];
        if (detail is List && detail.isNotEmpty) {
          // FastAPI validation errors
          message =
              detail.map((err) => err['msg'] ?? err.toString()).join(', ');
        } else if (detail is String) {
          message = detail;
        } else {
          message = e.response!.data['message'] ?? 'Error desconocido';
        }
      } else if (e.response!.data is String) {
        message = e.response!.data;
      }
    } else {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          message = 'Tiempo de espera agotado';
          break;
        case DioExceptionType.connectionError:
          message = 'No se puede conectar al servidor';
          break;
        case DioExceptionType.cancel:
          message = 'Operación cancelada';
          break;
        default:
          message = e.message ?? 'Error desconocido';
      }
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      data: e.response?.data,
    );
  }

  @override
  String toString() => message;
}
