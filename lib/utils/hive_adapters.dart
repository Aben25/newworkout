import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile.dart';
import '../models/exercise.dart';
import '../models/exercise_favorite.dart';
import '../models/exercise_collection.dart';
import '../models/workout_exercise.dart';
import '../models/completed_set.dart';
import '../models/completed_workout.dart';
import '../models/achievement.dart';
import '../models/workout_log.dart';
import '../models/workout_set_log.dart';
import '../models/workout.dart';
import '../models/workout_session_state.dart';
import '../models/onboarding_state.dart';
import '../models/analytics_data.dart';
import '../models/offline_cache_models.dart';

/// Registers all Hive adapters for offline caching
class HiveAdapters {
  static Future<void> registerAdapters() async {
    // Initialize Hive
    await Hive.initFlutter();
    
    // Register all model adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserProfileAdapter());
    }
    
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ExerciseAdapter());
    }
    
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(WorkoutExerciseAdapter());
    }
    
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(CompletedSetAdapter());
    }
    
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(SetDifficultyAdapter());
    }
    
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(WorkoutLogAdapter());
    }
    
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(WorkoutStatusAdapter());
    }
    
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(WorkoutAdapter());
    }
    
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(WorkoutStateAdapter());
    }
    
    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(ExerciseLogAdapter());
    }
    
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(ExerciseFavoriteAdapter());
    }
    
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(ExerciseCollectionAdapter());
    }
    
    if (!Hive.isAdapterRegistered(31)) {
      Hive.registerAdapter(CompletedSetLogAdapter());
    }
    
    if (!Hive.isAdapterRegistered(32)) {
      Hive.registerAdapter(ExerciseLogSessionAdapter());
    }
    
    if (!Hive.isAdapterRegistered(33)) {
      Hive.registerAdapter(SetLogAdapter());
    }
    
    if (!Hive.isAdapterRegistered(15)) {
      Hive.registerAdapter(CompletedWorkoutAdapter());
    }
    
    if (!Hive.isAdapterRegistered(16)) {
      Hive.registerAdapter(AchievementAdapter());
    }
    
    if (!Hive.isAdapterRegistered(17)) {
      Hive.registerAdapter(UserAchievementAdapter());
    }
    
    if (!Hive.isAdapterRegistered(37)) {
      Hive.registerAdapter(AchievementTypeAdapter());
    }
    
    if (!Hive.isAdapterRegistered(38)) {
      Hive.registerAdapter(AchievementRarityAdapter());
    }
    
    if (!Hive.isAdapterRegistered(34)) {
      Hive.registerAdapter(WorkoutSetLogAdapter());
    }
    
    if (!Hive.isAdapterRegistered(35)) {
      Hive.registerAdapter(AnalyticsDataAdapter());
    }
    
    if (!Hive.isAdapterRegistered(39)) {
      Hive.registerAdapter(WorkoutFrequencyAnalyticsAdapter());
    }
    
    if (!Hive.isAdapterRegistered(40)) {
      Hive.registerAdapter(VolumeAnalyticsAdapter());
    }
    
    if (!Hive.isAdapterRegistered(41)) {
      Hive.registerAdapter(ProgressAnalyticsAdapter());
    }
    
    if (!Hive.isAdapterRegistered(42)) {
      Hive.registerAdapter(PersonalRecordAdapter());
    }
    
    if (!Hive.isAdapterRegistered(43)) {
      Hive.registerAdapter(PersonalRecordTypeAdapter());
    }
    
    if (!Hive.isAdapterRegistered(44)) {
      Hive.registerAdapter(MilestoneAdapter());
    }
    
    if (!Hive.isAdapterRegistered(45)) {
      Hive.registerAdapter(MilestoneTypeAdapter());
    }
    
    if (!Hive.isAdapterRegistered(46)) {
      Hive.registerAdapter(TrendAnalyticsAdapter());
    }
    
    if (!Hive.isAdapterRegistered(47)) {
      Hive.registerAdapter(DailyWorkoutCountAdapter());
    }
    
    if (!Hive.isAdapterRegistered(48)) {
      Hive.registerAdapter(WeeklyVolumeDataAdapter());
    }
    
    if (!Hive.isAdapterRegistered(49)) {
      Hive.registerAdapter(ExerciseVolumeDataAdapter());
    }
    
    if (!Hive.isAdapterRegistered(27)) {
      Hive.registerAdapter(ExerciseProgressDataAdapter());
    }
    
    if (!Hive.isAdapterRegistered(28)) {
      Hive.registerAdapter(ProgressDataPointAdapter());
    }
    
    if (!Hive.isAdapterRegistered(29)) {
      Hive.registerAdapter(TrendDataPointAdapter());
    }
    
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(OnboardingStateAdapter());
    }
    
    // Register offline cache model adapters
    if (!Hive.isAdapterRegistered(50)) {
      Hive.registerAdapter(OfflineWorkoutAdapter());
    }
    
    if (!Hive.isAdapterRegistered(51)) {
      Hive.registerAdapter(SyncQueueItemAdapter());
    }
    
    if (!Hive.isAdapterRegistered(52)) {
      Hive.registerAdapter(SyncTypeAdapter());
    }
    
    if (!Hive.isAdapterRegistered(53)) {
      Hive.registerAdapter(SyncPriorityAdapter());
    }
    
    if (!Hive.isAdapterRegistered(54)) {
      Hive.registerAdapter(OfflineExerciseCacheAdapter());
    }
    
    if (!Hive.isAdapterRegistered(55)) {
      Hive.registerAdapter(ConnectivityStatusAdapter());
    }
    
    if (!Hive.isAdapterRegistered(56)) {
      Hive.registerAdapter(OfflineSyncStatsAdapter());
    }
  }

  /// Opens all required Hive boxes for the application
  static Future<void> openBoxes() async {
    await Future.wait([
      Hive.openBox<UserProfile>('user_profiles'),
      Hive.openBox<Exercise>('exercises'),
      Hive.openBox<ExerciseFavorite>('exercise_favorites'),
      Hive.openBox<ExerciseCollection>('exercise_collections'),
      Hive.openBox<WorkoutExercise>('workout_exercises'),
      Hive.openBox<CompletedSet>('completed_sets'),
      Hive.openBox<CompletedWorkout>('completed_workouts'),
      Hive.openBox<WorkoutLog>('workout_logs'),
      Hive.openBox<WorkoutSetLog>('workout_set_logs'),
      Hive.openBox<AnalyticsData>('analytics_data'),
      Hive.openBox<Workout>('workouts'),
      Hive.openBox('sync_queue'), // For sync operations
      Hive.openBox('app_settings'), // For app settings
      Hive.openBox('offline_cache'), // For general offline caching
      Hive.openBox<OnboardingState>('onboarding_box'), // For onboarding state
      
      // Open offline cache boxes
      Hive.openBox<OfflineWorkout>('offline_workouts'),
      Hive.openBox<OfflineExerciseCache>('offline_exercise_cache'),
      Hive.openBox<SyncQueueItem>('sync_queue_items'),
      Hive.openBox<ConnectivityStatus>('connectivity_status'),
      Hive.openBox<OfflineSyncStats>('sync_stats'),
    ]);
  }

  /// Closes all Hive boxes
  static Future<void> closeBoxes() async {
    await Hive.close();
  }

  /// Clears all cached data (useful for logout or data reset)
  static Future<void> clearAllData() async {
    final boxes = [
      'user_profiles',
      'exercises',
      'exercise_favorites',
      'exercise_collections',
      'workout_exercises',
      'completed_sets',
      'completed_workouts',
      'workout_logs',
      'workout_set_logs',
      'analytics_data',
      'workouts',
      'sync_queue',
      'app_settings',
      'offline_cache',
      'onboarding_box',
      'offline_workouts',
      'offline_exercise_cache',
      'sync_queue_items',
      'connectivity_status',
      'sync_stats',
    ];

    for (final boxName in boxes) {
      try {
        final box = Hive.box(boxName);
        await box.clear();
      } catch (e) {
        // Box might not be open, ignore error
      }
    }
  }

  /// Clears user-specific data (useful for logout)
  static Future<void> clearUserData() async {
    final userBoxes = [
      'user_profiles',
      'exercise_favorites',
      'exercise_collections',
      'workout_exercises',
      'completed_sets',
      'completed_workouts',
      'workout_logs',
      'workout_set_logs',
      'analytics_data',
      'workouts',
      'sync_queue',
      'offline_workouts',
      'sync_queue_items',
      'sync_stats',
    ];

    for (final boxName in userBoxes) {
      try {
        final box = Hive.box(boxName);
        await box.clear();
      } catch (e) {
        // Box might not be open, ignore error
      }
    }
  }

  /// Gets the size of all cached data in bytes
  static Future<int> getCacheSize() async {
    int totalSize = 0;
    
    final boxes = [
      'user_profiles',
      'exercises',
      'exercise_favorites',
      'exercise_collections',
      'workout_exercises',
      'completed_sets',
      'completed_workouts',
      'workout_logs',
      'workout_set_logs',
      'analytics_data',
      'workouts',
      'sync_queue',
      'app_settings',
      'offline_cache',
      'onboarding_box',
      'offline_workouts',
      'offline_exercise_cache',
      'sync_queue_items',
      'connectivity_status',
      'sync_stats',
    ];

    for (final boxName in boxes) {
      try {
        final box = Hive.box(boxName);
        totalSize += box.length;
      } catch (e) {
        // Box might not be open, ignore error
      }
    }

    return totalSize;
  }

  /// Compacts all Hive boxes to optimize storage
  static Future<void> compactBoxes() async {
    final boxes = [
      'user_profiles',
      'exercises',
      'exercise_favorites',
      'exercise_collections',
      'workout_exercises',
      'completed_sets',
      'completed_workouts',
      'workout_logs',
      'workout_set_logs',
      'analytics_data',
      'workouts',
      'sync_queue',
      'app_settings',
      'offline_cache',
      'onboarding_box',
      'offline_workouts',
      'offline_exercise_cache',
      'sync_queue_items',
      'connectivity_status',
      'sync_stats',
    ];

    for (final boxName in boxes) {
      try {
        final box = Hive.box(boxName);
        await box.compact();
      } catch (e) {
        // Box might not be open, ignore error
      }
    }
  }

  /// Checks if offline data is available
  static bool hasOfflineData() {
    try {
      final exerciseBox = Hive.box<Exercise>('exercises');
      final workoutBox = Hive.box<Workout>('workouts');
      final offlineWorkoutBox = Hive.box<OfflineWorkout>('offline_workouts');
      final offlineExerciseBox = Hive.box<OfflineExerciseCache>('offline_exercise_cache');
      
      return exerciseBox.isNotEmpty || 
             workoutBox.isNotEmpty || 
             offlineWorkoutBox.isNotEmpty || 
             offlineExerciseBox.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Gets offline cache statistics
  static Map<String, dynamic> getCacheStats() {
    final stats = <String, dynamic>{};
    
    try {
      stats['user_profiles'] = Hive.box<UserProfile>('user_profiles').length;
      stats['exercises'] = Hive.box<Exercise>('exercises').length;
      stats['exercise_favorites'] = Hive.box<ExerciseFavorite>('exercise_favorites').length;
      stats['exercise_collections'] = Hive.box<ExerciseCollection>('exercise_collections').length;
      stats['workout_exercises'] = Hive.box<WorkoutExercise>('workout_exercises').length;
      stats['completed_sets'] = Hive.box<CompletedSet>('completed_sets').length;
      stats['completed_workouts'] = Hive.box<CompletedWorkout>('completed_workouts').length;
      stats['workout_logs'] = Hive.box<WorkoutLog>('workout_logs').length;
      stats['workout_set_logs'] = Hive.box<WorkoutSetLog>('workout_set_logs').length;
      stats['analytics_data'] = Hive.box<AnalyticsData>('analytics_data').length;
      stats['workouts'] = Hive.box<Workout>('workouts').length;
      stats['sync_queue_items'] = Hive.box('sync_queue').length;
      stats['offline_workouts'] = Hive.box<OfflineWorkout>('offline_workouts').length;
      stats['offline_exercise_cache'] = Hive.box<OfflineExerciseCache>('offline_exercise_cache').length;
      stats['sync_queue_items_new'] = Hive.box<SyncQueueItem>('sync_queue_items').length;
      stats['connectivity_status'] = Hive.box<ConnectivityStatus>('connectivity_status').length;
      stats['sync_stats'] = Hive.box<OfflineSyncStats>('sync_stats').length;
      
      stats['total_items'] = stats.values.fold<int>(0, (sum, count) => sum + (count as int));
      stats['has_offline_data'] = hasOfflineData();
      
    } catch (e) {
      stats['error'] = e.toString();
    }
    
    return stats;
  }
}