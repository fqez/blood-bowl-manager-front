import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: AppConfig.connectTimeout,
    receiveTimeout: AppConfig.receiveTimeout,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  dio.interceptors.add(AuthInterceptor(ref));
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    error: true,
  ));

  return dio;
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

class AuthInterceptor extends Interceptor {
  final Ref ref;

  AuthInterceptor(this.ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip auth header for login/register endpoints
    if (options.path.contains('/auth/login') ||
        options.path.contains('/auth/register')) {
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
    if (err.response?.statusCode == 401) {
      // Try to refresh the token
      final storage = ref.read(secureStorageProvider);
      final refreshToken = await storage.read(key: AppConfig.refreshTokenKey);

      if (refreshToken != null) {
        try {
          final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
          final response = await dio.post('/auth/refresh', data: {
            'refresh_token': refreshToken,
          });

          final newAccessToken = response.data['access_token'];
          await storage.write(key: AppConfig.accessTokenKey, value: newAccessToken);

          // Retry the original request
          err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          final retryResponse = await dio.fetch(err.requestOptions);

          return handler.resolve(retryResponse);
        } catch (e) {
          // Refresh failed, clear tokens and propagate error
          await storage.delete(key: AppConfig.accessTokenKey);
          await storage.delete(key: AppConfig.refreshTokenKey);
        }
      }
    }

    return handler.next(err);
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
          message = detail.map((err) => err['msg'] ?? err.toString()).join(', ');
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
