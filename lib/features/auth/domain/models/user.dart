import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String email,
    required String username,
    String? fullname,
    String? avatar,
    @Default([]) List<String> teamIds,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) =>
      _$UserFromJson(_normalizeUserJson(json));
}

@freezed
class AuthState with _$AuthState {
  const AuthState._();

  const factory AuthState({
    User? user,
    String? accessToken,
    String? refreshToken,
    @Default(false) bool isLoading,
    String? error,
  }) = _AuthState;

  bool get isAuthenticated => user != null && accessToken != null;
}

@freezed
class LoginRequest with _$LoginRequest {
  const factory LoginRequest({
    required String email,
    required String password,
  }) = _LoginRequest;

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
}

@freezed
class RegisterRequest with _$RegisterRequest {
  const factory RegisterRequest({
    required String email,
    required String password,
    required String coachName,
  }) = _RegisterRequest;

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(_normalizeRegisterRequestJson(json));
}

@freezed
class TokenResponse with _$TokenResponse {
  const factory TokenResponse({
    required String accessToken,
    required String refreshToken,
    required String tokenType,
  }) = _TokenResponse;

  factory TokenResponse.fromJson(Map<String, dynamic> json) =>
      _$TokenResponseFromJson(_normalizeTokenResponseJson(json));
}

Map<String, dynamic> _normalizeUserJson(Map<String, dynamic> json) =>
    _withAliases(json, {
      'id': ['user_id'],
      'teamIds': ['team_ids'],
    });

Map<String, dynamic> _normalizeRegisterRequestJson(Map<String, dynamic> json) =>
    _withAliases(json, {
      'coachName': ['coach_name'],
    });

Map<String, dynamic> _normalizeTokenResponseJson(Map<String, dynamic> json) =>
    _withAliases(json, {
      'accessToken': ['access_token'],
      'refreshToken': ['refresh_token'],
      'tokenType': ['token_type'],
    });

Map<String, dynamic> _withAliases(
  Map<String, dynamic> json,
  Map<String, List<String>> aliases,
) {
  final normalized = {...json};
  for (final MapEntry(:key, :value) in aliases.entries) {
    normalized[key] ??= _firstValue(json, value);
  }
  return normalized;
}

Object? _firstValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key)) return json[key];
  }
  return null;
}
