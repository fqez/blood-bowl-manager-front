import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user.dart';
import '../repositories/auth_repository.dart';

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AuthState>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.isAuthenticated ?? false;
});

class AuthNotifier extends StateNotifier<AsyncValue<AuthState>> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AsyncValue.loading()) {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      final accessToken = await _repository.getStoredAccessToken();
      final refreshToken = await _repository.getStoredRefreshToken();

      if (accessToken != null) {
        final user = await _repository.getCurrentUser();
        if (user != null) {
          state = AsyncValue.data(AuthState(
            user: user,
            accessToken: accessToken,
            refreshToken: refreshToken,
          ));
          return;
        }
      }

      state = const AsyncValue.data(AuthState());
    } catch (e) {
      state = const AsyncValue.data(AuthState());
    }
  }

  Future<void> login(String email, String password) async {
    state = AsyncValue.data(state.valueOrNull?.copyWith(isLoading: true) ??
        const AuthState(isLoading: true));

    try {
      final tokenResponse = await _repository.login(email, password);
      final user = await _repository.getCurrentUser();

      state = AsyncValue.data(AuthState(
        user: user,
        accessToken: tokenResponse.accessToken,
        refreshToken: tokenResponse.refreshToken,
      ));
    } catch (e) {
      state = AsyncValue.data(AuthState(
        error: e.toString(),
      ));
    }
  }

  Future<void> register(String email, String password, String coachName) async {
    state = AsyncValue.data(state.valueOrNull?.copyWith(isLoading: true) ??
        const AuthState(isLoading: true));

    try {
      await _repository.register(email, password, coachName);
      // After registration, auto-login
      await login(email, password);
    } catch (e) {
      state = AsyncValue.data(AuthState(
        error: e.toString(),
      ));
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncValue.data(AuthState());
  }

  void clearError() {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(error: null));
    }
  }
}
