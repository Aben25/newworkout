import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_profile.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final User? user;
  final UserProfile? profile;
  final String? errorMessage;
  final bool isLoading;

  const AuthState({
    required this.status,
    this.user,
    this.profile,
    this.errorMessage,
    this.isLoading = false,
  });

  const AuthState.initial()
      : status = AuthStatus.initial,
        user = null,
        profile = null,
        errorMessage = null,
        isLoading = false;

  const AuthState.loading()
      : status = AuthStatus.loading,
        user = null,
        profile = null,
        errorMessage = null,
        isLoading = true;

  const AuthState.authenticated({
    required User user,
    UserProfile? profile,
  })  : status = AuthStatus.authenticated,
        user = user,
        profile = profile,
        errorMessage = null,
        isLoading = false;

  const AuthState.unauthenticated()
      : status = AuthStatus.unauthenticated,
        user = null,
        profile = null,
        errorMessage = null,
        isLoading = false;

  const AuthState.error(String errorMessage)
      : status = AuthStatus.error,
        user = null,
        profile = null,
        errorMessage = errorMessage,
        isLoading = false;

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get hasError => status == AuthStatus.error;
  bool get isInitial => status == AuthStatus.initial;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    UserProfile? profile,
    String? errorMessage,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      profile: profile ?? this.profile,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthState &&
        other.status == status &&
        other.user?.id == user?.id &&
        other.profile?.id == profile?.id &&
        other.errorMessage == errorMessage &&
        other.isLoading == isLoading;
  }

  @override
  int get hashCode {
    return Object.hash(
      status,
      user?.id,
      profile?.id,
      errorMessage,
      isLoading,
    );
  }

  @override
  String toString() {
    return 'AuthState(status: $status, user: ${user?.id}, profile: ${profile?.id}, errorMessage: $errorMessage, isLoading: $isLoading)';
  }
}