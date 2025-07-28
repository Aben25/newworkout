class AppConstants {
  // App Information
  static const String appName = 'Modern Workout Tracker';
  static const String appVersion = '1.0.0';
  
  // Supabase Configuration
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://xtazgqpcaujwwaswzeoh.supabase.co',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh0YXpncXBjYXVqd3dhc3d6ZW9oIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzE4MTA5MDUsImV4cCI6MjA0NzM4NjkwNX0.nFutcV81_Na8L-wwxFRpYg7RhqmjMrYspP2LyKbE_q0',
  );
  
  // Environment
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );
  
  // Local Storage Keys
  static const String userProfileBox = 'user_profile';
  static const String workoutCacheBox = 'workout_cache';
  static const String syncQueueBox = 'sync_queue';
  static const String settingsBox = 'settings';
  
  // Shared Preferences Keys
  static const String onboardingCompletedKey = 'onboarding_completed';
  static const String themePreferenceKey = 'theme_preference';
  static const String unitSystemKey = 'unit_system';
  
  // API Endpoints
  static const String profilesTable = 'profiles';
  static const String workoutsTable = 'workouts';
  static const String exercisesTable = 'exercises';
  static const String workoutExercisesTable = 'workout_exercises';
  static const String completedSetsTable = 'completed_sets';
  static const String workoutLogsTable = 'workout_logs';
  static const String completedWorkoutsTable = 'completed_workouts';
  static const String workoutSetLogsTable = 'workout_set_logs';
  static const String userAchievementsTable = 'user_achievements';
  static const String achievementsTable = 'achievements';
  
  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration syncTimeout = Duration(seconds: 60);
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Validation
  static const int minPasswordLength = 8;
  static const int maxNameLength = 50;
  static const int maxNotesLength = 500;
  
  // Workout Constants
  static const int defaultRestTime = 60; // seconds
  static const int maxSetsPerExercise = 10;
  static const int maxExercisesPerWorkout = 20;
}