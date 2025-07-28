import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../models/auth_state.dart';

/// Widget that guards routes requiring authentication
class AuthGuard extends ConsumerWidget {
  const AuthGuard({
    super.key,
    required this.child,
    this.redirectTo = '/welcome',
    this.showLoadingIndicator = true,
  });

  final Widget child;
  final String redirectTo;
  final bool showLoadingIndicator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return switch (authState.status) {
      AuthStatus.initial || AuthStatus.loading => showLoadingIndicator
          ? const _LoadingScreen()
          : child,
      AuthStatus.authenticated => child,
      AuthStatus.unauthenticated => _UnauthenticatedScreen(redirectTo: redirectTo),
      AuthStatus.error => _ErrorScreen(
          error: authState.errorMessage ?? 'Authentication error',
          onRetry: () => context.go('/'),
        ),
    };
  }
}

/// Loading screen shown while authentication state is being determined
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Loading...',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Screen shown when user is not authenticated
class _UnauthenticatedScreen extends StatelessWidget {
  const _UnauthenticatedScreen({required this.redirectTo});

  final String redirectTo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Authentication Required',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'You need to sign in to access this feature. Create an account or sign in to continue.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => context.go(redirectTo),
                  icon: const Icon(Icons.login),
                  label: const Text('Sign In'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.home),
                  label: const Text('Go Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Screen shown when there's an authentication error
class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({
    required this.error,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Authentication Error',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                error,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Convenience widget for protecting routes that require authentication
class ProtectedRoute extends ConsumerWidget {
  const ProtectedRoute({
    super.key,
    required this.child,
    this.redirectTo = '/welcome',
  });

  final Widget child;
  final String redirectTo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuthGuard(
      redirectTo: redirectTo,
      child: child,
    );
  }
}

/// Mixin for widgets that need to check authentication status
mixin AuthenticationMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// Check if user is authenticated and redirect if not
  void requireAuthentication({String redirectTo = '/welcome'}) {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go(redirectTo);
        }
      });
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => ref.read(authProvider).isAuthenticated;

  /// Get current user
  get currentUser => ref.read(authProvider).user;

  /// Get user profile
  get userProfile => ref.read(authProvider).profile;
}