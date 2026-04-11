import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:blood_bowl_manager/core/network/api_client.dart';
import 'package:blood_bowl_manager/core/config/app_config.dart';
import 'package:blood_bowl_manager/features/auth/domain/models/user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.watch(dioProvider),
    storage: ref.watch(secureStorageProvider),
  );
});

class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthRepository({
    required Dio dio,
    required FlutterSecureStorage storage,
  })  : _dio = dio,
        _storage = storage;

  Future<TokenResponse> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final tokenResponse = TokenResponse.fromJson(response.data);

      // Store tokens
      await _storage.write(key: AppConfig.accessTokenKey, value: tokenResponse.accessToken);
      await _storage.write(key: AppConfig.refreshTokenKey, value: tokenResponse.refreshToken);

      return tokenResponse;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> register(String email, String password, String username) async {
    try {
      await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'username': username,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<TokenResponse> refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: AppConfig.refreshTokenKey);
      if (refreshToken == null) {
        throw ApiException(message: 'No refresh token available');
      }

      final response = await _dio.post('/auth/refresh', data: {
        'refresh_token': refreshToken,
      });

      final tokenResponse = TokenResponse.fromJson(response.data);

      await _storage.write(key: AppConfig.accessTokenKey, value: tokenResponse.accessToken);
      await _storage.write(key: AppConfig.refreshTokenKey, value: tokenResponse.refreshToken);

      return tokenResponse;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _storage.read(key: AppConfig.refreshTokenKey);
      if (refreshToken != null) {
        await _dio.post('/auth/logout', data: {
          'refresh_token': refreshToken,
        });
      }
    } catch (_) {
      // Ignore logout errors
    } finally {
      await _storage.delete(key: AppConfig.accessTokenKey);
      await _storage.delete(key: AppConfig.refreshTokenKey);
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');
      return User.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return null;
      }
      throw ApiException.fromDioException(e);
    }
  }

  Future<String?> getStoredAccessToken() async {
    return await _storage.read(key: AppConfig.accessTokenKey);
  }

  Future<String?> getStoredRefreshToken() async {
    return await _storage.read(key: AppConfig.refreshTokenKey);
  }
}
