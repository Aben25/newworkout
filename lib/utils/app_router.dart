import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/splash_screen.dart';
import '../screens/home_screen.dart';
import '../screens/welcome_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/onboarding_page_view.dart';
import '../screens/onboarding/onboarding_complete_screen.dart';
import '../screens/exercise_library_screen.dart';
import '../screens/exercise_detail_screen.dart';
import '../screens/workout_library_screen.dart';
import '../screens/workout_detail_screen.dart';
import '../screens/workout_builder_screen.dart';
import '../screens/workout_session_screen.dart';
import '../screens/progress_dashboard_screen.dart';
import '../screens/workout_history_screen.dart';
import '../widgets/auth_guard.dart';
import '../providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';
import '../models/auth_state.dart';

// Router provider with authentication-aware routing
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final shouldShowOnboarding = ref.watch(shouldShowOnboardingProvider);
  
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isAuthLoading = authState.status == AuthStatus.loading || authState.status == AuthStatus.initial;
      
      // Don't redirect while auth is loading
      if (isAuthLoading) return null;
      
      // Define public routes that don't require authentication
      final publicRoutes = ['/', '/welcome', '/login', '/signup', '/onboarding', '/onboarding/complete'];
      final isPublicRoute = publicRoutes.contains(state.matchedLocation);
      
      // Redirect old demo route to welcome
      if (state.matchedLocation == '/auth-demo') {
        return '/welcome';
      }
      
      // If user is authenticated
      if (isAuthenticated) {
        // If trying to access auth screens, redirect based on onboarding status
        if (['/welcome', '/login', '/signup'].contains(state.matchedLocation)) {
          return shouldShowOnboarding ? '/onboarding' : '/home';
        }
        
        // If should show onboarding and not already on onboarding pages
        if (shouldShowOnboarding && !['/onboarding', '/onboarding/complete'].contains(state.matchedLocation)) {
          return '/onboarding';
        }
        
        // If onboarding is complete and trying to access onboarding pages
        if (!shouldShowOnboarding && ['/onboarding', '/onboarding/complete'].contains(state.matchedLocation)) {
          return '/home';
        }
      }
      
      // Allow access to public routes regardless of auth status
      if (isPublicRoute) return null;
      
      // For protected routes, redirect to welcome if not authenticated
      if (!isAuthenticated) {
        return '/welcome';
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingPageView(),
      ),
      GoRoute(
        path: '/onboarding/complete',
        name: 'onboarding-complete',
        builder: (context, state) => const OnboardingCompleteScreen(),
      ),
      // Protected routes - these will require authentication
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => ProtectedRoute(
          redirectTo: '/welcome',
          child: const ProfileScreen(),
        ),
      ),
      GoRoute(
        path: '/exercises',
        name: 'exercises',
        builder: (context, state) => ProtectedRoute(
          redirectTo: '/welcome',
          child: const ExerciseLibraryScreen(),
        ),
      ),
      GoRoute(
        path: '/exercise/:exerciseId',
        name: 'exercise-detail',
        builder: (context, state) {
          final exerciseId = state.pathParameters['exerciseId']!;
          return ProtectedRoute(
            redirectTo: '/welcome',
            child: ExerciseDetailScreen(exerciseId: exerciseId),
          );
        },
      ),
      GoRoute(
        path: '/workouts',
        name: 'workouts',
        builder: (context, state) => ProtectedRoute(
          redirectTo: '/welcome',
          child: const WorkoutLibraryScreen(),
        ),
      ),
      GoRoute(
        path: '/workout/:workoutId',
        name: 'workout-detail',
        builder: (context, state) {
          final workoutId = state.pathParameters['workoutId']!;
          return ProtectedRoute(
            redirectTo: '/welcome',
            child: WorkoutDetailScreen(workoutId: workoutId),
          );
        },
      ),
      GoRoute(
        path: '/workout-builder',
        name: 'workout-builder',
        builder: (context, state) => ProtectedRoute(
          redirectTo: '/welcome',
          child: const WorkoutBuilderScreen(),
        ),
      ),
      GoRoute(
        path: '/workout-builder/:workoutId',
        name: 'workout-builder-edit',
        builder: (context, state) {
          final workoutId = state.pathParameters['workoutId']!;
          return ProtectedRoute(
            redirectTo: '/welcome',
            child: WorkoutBuilderScreen(workoutId: workoutId),
          );
        },
      ),
      GoRoute(
        path: '/workout-session/:workoutId',
        name: 'workout-session',
        builder: (context, state) {
          final workoutId = state.pathParameters['workoutId']!;
          final isResuming = state.uri.queryParameters['resume'] == 'true';
          return ProtectedRoute(
            redirectTo: '/welcome',
            child: WorkoutSessionScreen(
              workoutId: workoutId,
              isResuming: isResuming,
            ),
          );
        },
      ),
      GoRoute(
        path: '/progress',
        name: 'progress',
        builder: (context, state) => ProtectedRoute(
          redirectTo: '/welcome',
          child: const ProgressDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/workout-history',
        name: 'workout-history',
        builder: (context, state) => ProtectedRoute(
          redirectTo: '/welcome',
          child: const WorkoutHistoryScreen(),
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Page not found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'The page "${state.uri}" could not be found.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

// Helper function to build placeholder screens for protected routes
Widget _buildPlaceholderScreen(String title, String description) {
  return Scaffold(
    appBar: AppBar(
      title: Text(title),
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'This feature is coming soon!',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    ),
  );
}