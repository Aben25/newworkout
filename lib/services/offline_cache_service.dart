import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/models.dart';

/// Service for managing offline caching of workout data with encryption
class OfflineCacheService {
  static OfflineCacheService? _instance;
  static OfflineCacheService get instance => _instance ??= OfflineCacheService._();
  
  OfflineCacheService._();
  
  final Logger _logger = Logger();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Box getters
  Box<UserProfile> get _profileBox => Hive.box<UserProfile>('user_profiles');
  Box<Exercise> get _exerciseBox => Hive.box<Exercise>('exercises');
  Box<ExerciseFavorite> get _favoritesBox => Hive.box<ExerciseFavorite>('exercise_favorites');
  Box<ExerciseCollection> get _collectionsBox => Hive.box<ExerciseCollection>('exercise_collections');
  Box<WorkoutExercise> get _workoutExerciseBox => Hive.box<WorkoutExercise>('workout_exercises');
  Box<CompletedSet> get _completedSetBox => Hive.box<CompletedSet>('completed_sets');
  Box<CompletedWorkout> get _completedWorkoutBox => Hive.box<CompletedWorkout>('completed_workouts');
  Box<WorkoutLog> get _workoutLogBox => Hive.box<WorkoutLog>('workout_logs');
  Box<WorkoutSetLog> get _workoutSetLogBox => Hive.box<WorkoutSetLog>('workout_set_logs');
  Box<Workout> get _workoutBox => Hive.box<Workout>('workouts');
  Box<AnalyticsData> get _analyticsBox => Hive.box<AnalyticsData>('analytics_data');
  Box get _syncQueueBox => Hive.box('sync_queue');
  
  // New offline cache boxes
  Box<OfflineWorkout> get _offlineWorkoutBox => Hive.box<OfflineWorkout>('offline_workouts');
  Box<OfflineExerciseCache> get _offlineExerciseCacheBox => Hive.box<OfflineExerciseCache>('offline_exercise_cache');
  Box<SyncQueueItem> get _syncQueueItemBox => Hive.box<SyncQueueItem>('sync_queue_items');
  Box<ConnectivityStatus> get _connectivityBox => Hive.box<ConnectivityStatus>('connectivity_status');
  Box<OfflineSyncStats> get _syncStatsBox => Hive.box<OfflineSyncStats>('sync_stats');

  // User Profile Operations
  Future<void> cacheUserProfile(UserProfile profile) async {
    try {
      await _profileBox.put(profile.id, profile);
      _logger.d('Cached user profile: ${profile.id}');
    } catch (e, stackTrace) {
      _logger.e('Failed to cache user profile', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  UserProfile? getCachedUserProfile(String userId) {
    try {
      return _profileBox.get(userId);
    } catch (e, stackTrace) {
      _logger.e('Failed to get cached user profile', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  // Exercise Operations
  Future<void> cacheExercises(List<Exercise> exercises) async {
    try {
      final exerciseMap = {for (var exercise in exercises) exercise.id: exercise};
      await _exerciseBox.putAll(exerciseMap);
      _logger.d('Cached ${exercises.length} exercises');
    } catch (e, stackTrace) {
      _logger.e('Failed to cache exercises', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  List<Exercise> getCachedExercises() {
    try {
      return _exerciseBox.values.toList();
    } catch (e, stackTrace) {
      _logger.e('Failed to get cached exercises', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  Exercise? getCachedExercise(String exerciseId) {
    try {
      return _exerciseBox.get(exerciseId);
    } catch (e, stackTrace) {
      _logger.e('Failed to get cached exercise', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  List<Exercise> searchCachedExercises({
    String? query,
    String? muscleGroup,
    String? equipment,
    String? category,
  }) {
    try {
      var exercises = getCachedExercises();

      if (query != null && query.isNotEmpty) {
        exercises = exercises.where((exercise) => exercise.matchesSearch(query)).toList();
      }

      if (muscleGroup != null || equipment != null || category != null) {
        exercises = exercises.where((exercise) => exercise.matchesFilter(
          muscleGroup: muscleGroup,
          equipmentType: equipment,
          categoryFilter: category,
        )).toList();
      }

      return exercises;
    } catch (e, stackTrace) {
      _logger.e('Failed to search cached exercises', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  // Workout Operations
  Future<void> cacheWorkout(Workout workout) async {
    try {
      await _workoutBox.put(workout.id, workout);
      _logger.d('Cached workout: ${workout.id}');
    } catch (e, stackTrace) {
      _logger.e('Failed to cache workout', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Workout? getCachedWorkout(String workoutId) {
    try {
      return _workoutBox.get(workoutId);
    } catch (e, stackTrace) {
      _logger.e('Failed to get cached workout', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  List<Workout> getCachedWorkouts({String? userId}) {
    try {
      var workouts = _workoutBox.values.toList();
      
      if (userId != null) {
        workouts = workouts.where((workout) => workout.userId == userId).toList();
      }
      
      // Sort by most recent first
      workouts.sort((a, b) => b.compareTo(a));
      
      return workouts;
    } catch (e, stackTrace) {
      _logger.e('Failed to get cached workouts', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  List<Workout> getActiveWorkouts({String? userId}) {
    try {
      return getCachedWorkouts(userId: userId)
          .where((workout) => workout.isActive)
          .toList();
    } catch (e, stackTrace) {
      _logger.e('Failed to get active workouts', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  // Workout Exercise Operations
  Future<void> cacheWorkoutExercises(List<WorkoutExercise> exercises) async {
    try {
      final exerciseMap = {for (var exercise in exercises) exercise.id: exercise};
      await _workoutExerciseBox.putAll(exerciseMap);
      _logger.d('Cached ${exercises.length} workout exercises');
    } catch (e, stackTrace) {
      _logger.e('Failed to cache workout exercises', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  List<WorkoutExercise> getCachedWorkoutExercises(String workoutId) {
    try {
      return _workoutExerciseBox.values
          .where((exercise) => exercise.workoutId == workoutId)
          .toList()
        ..sort((a, b) => a.effectiveOrder.compareTo(b.effectiveOrder));
    } catch (e, stackTrace) {
      _logger.e('Failed to get cached workout exercises', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  // Completed Set Operations
  Future<void> cacheCompletedSet(CompletedSet completedSet) async {
    try {
      await _completedSetBox.put(completedSet.id, completedSet);
      _logger.d('Cached completed set: ${completedSet.id}');
    } catch (e, stackTrace) {
      _logger.e('Failed to cache completed set', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  List<CompletedSet> getCachedCompletedSets({
    String? workoutId,
    String? workoutExerciseId,
  }) {
    try {
      var sets = _completedSetBox.values.toList();
      
      if (workoutId != null) {
        sets = sets.where((set) => set.workoutId == workoutId).toList();
      }
      
      if (workoutExerciseId != null) {
        sets = sets.where((set) => set.workoutExerciseId == workoutExerciseId).toList();
      }
      
      // Sort by set order
      sets.sort((a, b) => (a.performedSetOrder ?? 0).compareTo(b.performedSetOrder ?? 0));
      
      return sets;
    } catch (e, stackTrace) {
      _logger.e('Failed to get cached completed sets', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  // Workout Log Operations
  Future<void> cacheWorkoutLog(WorkoutLog log) async {
    try {
      await _workoutLogBox.put(log.id, log);
      _logger.d('Cached workout log: ${log.id}');
    } catch (e, stackTrace) {
      _logger.e('Failed to cache workout log', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  List<WorkoutLog> getCachedWorkoutLogs({String? userId}) {
    try {
      var logs = _workoutLogBox.values.toList();
      
      if (userId != null) {
        logs = logs.where((log) => log.userId == userId).toList();
      }
      
      // Sort by most recent first
      logs.sort((a, b) => b.compareTo(a));
      
      return logs;
    } catch (e, stackTrace) {
      _logger.e('Failed to get cached workout logs', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  List<WorkoutLog> getRecentWorkoutLogs({String? userId, int limit = 10}) {
    try {
      return getCachedWorkoutLogs(userId: userId).take(limit).toList();
    } catch (e, stackTrace) {
      _logger.e('Failed to get recent workout logs', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  // Exercise Favorites Operations
  Future<void> cacheFavorites(List<ExerciseFavorite> favorites) async {
    try {
      final favoriteMap = {for (var favorite in favorites) favorite.id: favorite};
      await _favoritesBox.putAll(favoriteMap);
      _logger.d('Cached ${favorites.length} exercise favorites');
    } catch (e, stackTrace) {
      _logger.e('Failed to cache favorites', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  List<ExerciseFavorite> getCachedFavorites({String? userId}) {
    try {
      var favorites = _favoritesBox.values.toList();
      
      if (userId != null) {
        favorites = favorites.where((favorite) => favorite.userId == userId).toList();
      }
      
      // Sort by most recent first
      favorites.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return favorites;
    } catch (e, stackTrace) {
      _logger.e('Failed to get cached favorites', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  Future<void> addPendingFavorite(ExerciseFavorite favorite) async {
    try {
      await _favoritesBox.put(favorite.id, favorite);
      await addToSyncQueue('add_favorite', favorite.toJson());
      _logger.d('Added pending favorite: ${favorite.exerciseId}');
    } catch (e, stackTrace) {
      _logger.e('Failed to add pending favorite', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> addPendingFavoriteRemoval(String favoriteId) async {
    try {
      await _favoritesBox.delete(favoriteId);
      await addToSyncQueue('remove_favorite', {'id': favoriteId});
      _logger.d('Added pending favorite removal: $favoriteId');
    } catch (e, stackTrace) {
      _logger.e('Failed to add pending favorite removal', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Exercise Collections Operations
  Future<void> cacheCollections(List<ExerciseCollection> collections) async {
    try {
      final collectionMap = {for (var collection in collections) collection.id: collection};
      await _collectionsBox.putAll(collectionMap);
      _logger.d('Cached ${collections.length} exercise collections');
    } catch (e, stackTrace) {
      _logger.e('Failed to cache collections', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  List<ExerciseCollection> getCachedCollections({String? userId}) {
    try {
      var collections = _collectionsBox.values.toList();
      
      if (userId != null) {
        collections = collections.where((collection) => collection.userId == userId).toList();
      }
      
      // Sort by most recently updated first
      collections.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      return collections;
    } catch (e, stackTrace) {
      _logger.e('Failed to get cached collections', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  Future<void> addPendingCollection(ExerciseCollection collection) async {
    try {
      await _collectionsBox.put(collection.id, collection);
      await addToSyncQueue('add_collection', collection.toJson());
      _logger.d('Added pending collection: ${collection.name}');
    } catch (e, stackTrace) {
      _logger.e('Failed to add pending collection', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> addPendingCollectionUpdate(ExerciseCollection collection) async {
    try {
      await _collectionsBox.put(collection.id, collection);
      await addToSyncQueue('update_collection', collection.toJson());
      _logger.d('Added pending collection update: ${collection.name}');
    } catch (e, stackTrace) {
      _logger.e('Failed to add pending collection update', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> addPendingCollectionDeletion(String collectionId) async {
    try {
      await _collectionsBox.delete(collectionId);
      await addToSyncQueue('delete_collection', {'id': collectionId});
      _logger.d('Added pending collection deletion: $collectionId');
    } catch (e, stackTrace) {
      _logger.e('Failed to add pending collection deletion', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Completed Workout Operations
  Future<void> cacheCompletedWorkout(CompletedWorkout completedWorkout) async {
    try {
      await _completedWorkoutBox.put(completedWorkout.id, completedWorkout);
      _logger.d('Cached completed workout: ${completedWorkout.id}');
    } catch (e, stackTrace) {
      _logger.e('Failed to cache completed workout', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  List<CompletedWorkout> getCachedCompletedWorkouts({String? userId}) {
    try {
      var completedWorkouts = _completedWorkoutBox.values.toList();
      
      if (userId != null) {
        completedWorkouts = completedWorkouts.where((workout) => workout.userId == userId).toList();
      }
      
      // Sort by most recent first
      completedWorkouts.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      
      return completedWorkouts;
    } catch (e, stackTrace) {
      _logger.e('Failed to get cached completed workouts', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  CompletedWorkout? getCachedCompletedWorkout(String completedWorkoutId) {
    try {
      return _completedWorkoutBox.get(completedWorkoutId);
    } catch (e, stackTrace) {
      _logger.e('Failed to get cached completed workout', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  // Sync Queue Operations
  Future<void> addToSyncQueue(String type, Map<String, dynamic> data) async {
    try {
      final queueItem = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': type,
        'data': data,
        'created_at': DateTime.now().toIso8601String(),
        'retry_count': 0,
      };
      
      await _syncQueueBox.add(queueItem);
      _logger.d('Added item to sync queue: $type');
    } catch (e, stackTrace) {
      _logger.e('Failed to add item to sync queue', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  List<Map<String, dynamic>> getSyncQueue() {
    try {
      return _syncQueueBox.values.cast<Map<String, dynamic>>().toList();
    } catch (e, stackTrace) {
      _logger.e('Failed to get sync queue', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  Future<void> clearSyncQueue() async {
    try {
      await _syncQueueBox.clear();
      _logger.d('Cleared sync queue');
    } catch (e, stackTrace) {
      _logger.e('Failed to clear sync queue', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Analytics and Statistics
  Map<String, dynamic> getCacheStatistics() {
    try {
      return {
        'user_profiles': _profileBox.length,
        'exercises': _exerciseBox.length,
        'exercise_favorites': _favoritesBox.length,
        'exercise_collections': _collectionsBox.length,
        'workout_exercises': _workoutExerciseBox.length,
        'completed_sets': _completedSetBox.length,
        'completed_workouts': _completedWorkoutBox.length,
        'workout_logs': _workoutLogBox.length,
        'workout_set_logs': _workoutSetLogBox.length,
        'workouts': _workoutBox.length,
        'analytics_data': _analyticsBox.length,
        'sync_queue_items': _syncQueueBox.length,
        'total_cached_items': _profileBox.length + 
                             _exerciseBox.length + 
                             _favoritesBox.length +
                             _collectionsBox.length +
                             _workoutExerciseBox.length + 
                             _completedSetBox.length + 
                             _completedWorkoutBox.length +
                             _workoutLogBox.length + 
                             _workoutSetLogBox.length +
                             _workoutBox.length +
                             _analyticsBox.length,
        'has_offline_data': hasOfflineData(),
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e, stackTrace) {
      _logger.e('Failed to get cache statistics', error: e, stackTrace: stackTrace);
      return {'error': e.toString()};
    }
  }

  bool hasOfflineData() {
    try {
      return _exerciseBox.isNotEmpty || 
             _workoutBox.isNotEmpty || 
             _workoutLogBox.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Workout Set Log Operations
  Future<void> cacheWorkoutSetLog(WorkoutSetLog setLog) async {
    try {
      await _workoutSetLogBox.put(setLog.id, setLog);
      _logger.d('Cached workout set log: ${setLog.id}');
    } catch (e, stackTrace) {
      _logger.e('Failed to cache workout set log', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  List<WorkoutSetLog> getCachedWorkoutSetLogs({String? workoutLogId, String? exerciseId}) {
    try {
      var setLogs = _workoutSetLogBox.values.toList();
      
      if (workoutLogId != null) {
        setLogs = setLogs.where((log) => log.workoutLogId == workoutLogId).toList();
      }
      
      if (exerciseId != null) {
        setLogs = setLogs.where((log) => log.exerciseId == exerciseId).toList();
      }
      
      // Sort by completion time
      setLogs.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      
      return setLogs;
    } catch (e, stackTrace) {
      _logger.e('Failed to get cached workout set logs', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  // Analytics Operations
  Future<void> cacheAnalytics(AnalyticsData analyticsData) async {
    try {
      await _analyticsBox.put(analyticsData.userId, analyticsData);
      _logger.d('Cached analytics data for user: ${analyticsData.userId}');
    } catch (e, stackTrace) {
      _logger.e('Failed to cache analytics data', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  AnalyticsData? getCachedAnalytics(String userId) {
    try {
      return _analyticsBox.get(userId);
    } catch (e, stackTrace) {
      _logger.e('Failed to get cached analytics', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  Future<void> clearAnalyticsCache(String userId) async {
    try {
      await _analyticsBox.delete(userId);
      _logger.d('Cleared analytics cache for user: $userId');
    } catch (e, stackTrace) {
      _logger.e('Failed to clear analytics cache', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Cleanup Operations
  Future<void> clearUserCache(String userId) async {
    try {
      // Clear user-specific data
      await _profileBox.delete(userId);
      
      // Clear user workouts
      final userWorkouts = _workoutBox.values
          .where((workout) => workout.userId == userId)
          .toList();
      for (final workout in userWorkouts) {
        await _workoutBox.delete(workout.id);
      }
      
      // Clear user workout logs
      final userLogs = _workoutLogBox.values
          .where((log) => log.userId == userId)
          .toList();
      for (final log in userLogs) {
        await _workoutLogBox.delete(log.id);
      }
      
      // Clear analytics cache
      await _analyticsBox.delete(userId);
      
      _logger.d('Cleared cache for user: $userId');
    } catch (e, stackTrace) {
      _logger.e('Failed to clear user cache', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> clearAllCache() async {
    try {
      await Future.wait([
        _profileBox.clear(),
        _favoritesBox.clear(),
        _collectionsBox.clear(),
        _workoutExerciseBox.clear(),
        _completedSetBox.clear(),
        _completedWorkoutBox.clear(),
        _workoutLogBox.clear(),
        _workoutSetLogBox.clear(),
        _workoutBox.clear(),
        _analyticsBox.clear(),
        _syncQueueBox.clear(),
      ]);
      
      _logger.d('Cleared all cache data');
    } catch (e, stackTrace) {
      _logger.e('Failed to clear all cache', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> compactCache() async {
    try {
      await Future.wait([
        _profileBox.compact(),
        _exerciseBox.compact(),
        _favoritesBox.compact(),
        _collectionsBox.compact(),
        _workoutExerciseBox.compact(),
        _completedSetBox.compact(),
        _completedWorkoutBox.compact(),
        _workoutLogBox.compact(),
        _workoutSetLogBox.compact(),
        _workoutBox.compact(),
        _analyticsBox.compact(),
        _syncQueueBox.compact(),
        _offlineWorkoutBox.compact(),
        _offlineExerciseCacheBox.compact(),
        _syncQueueItemBox.compact(),
        _connectivityBox.compact(),
        _syncStatsBox.compact(),
      ]);
      
      _logger.d('Compacted cache storage');
    } catch (e, stackTrace) {
      _logger.e('Failed to compact cache', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Enhanced Offline Workout Operations
  Future<void> cacheOfflineWorkout(OfflineWorkout offlineWorkout) async {
    try {
      await _offlineWorkoutBox.put(offlineWorkout.workout.id, offlineWorkout);
      _logger.d('Cached offline workout: ${offlineWorkout.workout.id}');
    } catch (e, stackTrace) {
      _logger.e('Failed to cache offline workout', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  OfflineWorkout? getCachedOfflineWorkout(String workoutId) {
    try {
      final cached = _offlineWorkoutBox.get(workoutId);
      if (cached != null && !cached.isValid) {
        // Remove expired cache
        _offlineWorkoutBox.delete(workoutId);
        return null;
      }
      return cached;
    } catch (e, stackTrace) {
      _logger.e('Failed to get cached offline workout', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  List<OfflineWorkout> getCachedOfflineWorkouts({bool includeExpired = false}) {
    try {
      var workouts = _offlineWorkoutBox.values.toList();
      
      if (!includeExpired) {
        workouts = workouts.where((workout) => workout.isValid).toList();
        
        // Clean up expired workouts
        final expiredIds = _offlineWorkoutBox.values
            .where((workout) => !workout.isValid)
            .map((workout) => workout.workout.id)
            .toList();
        
        for (final id in expiredIds) {
          _offlineWorkoutBox.delete(id);
        }
      }
      
      return workouts;
    } catch (e, stackTrace) {
      _logger.e('Failed to get cached offline workouts', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  // Enhanced Exercise Cache Operations
  Future<void> cacheOfflineExercises(OfflineExerciseCache exerciseCache) async {
    try {
      await _offlineExerciseCacheBox.put('exercises', exerciseCache);
      _logger.d('Cached ${exerciseCache.exercises.length} exercises with expiration');
    } catch (e, stackTrace) {
      _logger.e('Failed to cache offline exercises', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  OfflineExerciseCache? getCachedOfflineExercises() {
    try {
      final cached = _offlineExerciseCacheBox.get('exercises');
      if (cached != null && cached.isExpired) {
        // Remove expired cache
        _offlineExerciseCacheBox.delete('exercises');
        return null;
      }
      return cached;
    } catch (e, stackTrace) {
      _logger.e('Failed to get cached offline exercises', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  List<Exercise> getValidCachedExercises() {
    try {
      final cached = getCachedOfflineExercises();
      return cached?.exercises ?? getCachedExercises();
    } catch (e, stackTrace) {
      _logger.e('Failed to get valid cached exercises', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  // Enhanced Sync Queue Operations
  Future<void> addSyncQueueItem(SyncQueueItem item) async {
    try {
      await _syncQueueItemBox.put(item.id, item);
      _logger.d('Added sync queue item: ${item.type.name} (${item.id})');
    } catch (e, stackTrace) {
      _logger.e('Failed to add sync queue item', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> updateSyncQueueItem(SyncQueueItem item) async {
    try {
      await _syncQueueItemBox.put(item.id, item);
      _logger.d('Updated sync queue item: ${item.type.name} (${item.id})');
    } catch (e, stackTrace) {
      _logger.e('Failed to update sync queue item', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> removeSyncQueueItem(String itemId) async {
    try {
      await _syncQueueItemBox.delete(itemId);
      _logger.d('Removed sync queue item: $itemId');
    } catch (e, stackTrace) {
      _logger.e('Failed to remove sync queue item', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  List<SyncQueueItem> getSyncQueueItems() {
    try {
      return _syncQueueItemBox.values.toList();
    } catch (e, stackTrace) {
      _logger.e('Failed to get sync queue items', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  Future<void> clearSyncQueueItems() async {
    try {
      await _syncQueueItemBox.clear();
      _logger.d('Cleared sync queue items');
    } catch (e, stackTrace) {
      _logger.e('Failed to clear sync queue items', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Connectivity Status Operations
  Future<void> cacheConnectivityStatus(ConnectivityStatus status) async {
    try {
      await _connectivityBox.put('current', status);
      
      // Also store in history (keep last 50 entries)
      final historyKey = 'history_${DateTime.now().millisecondsSinceEpoch}';
      await _connectivityBox.put(historyKey, status);
      
      // Clean up old history entries
      final allKeys = _connectivityBox.keys.where((key) => key.toString().startsWith('history_')).toList();
      if (allKeys.length > 50) {
        allKeys.sort();
        final keysToRemove = allKeys.take(allKeys.length - 50);
        for (final key in keysToRemove) {
          await _connectivityBox.delete(key);
        }
      }
      
      _logger.d('Cached connectivity status: ${status.connectionType}');
    } catch (e, stackTrace) {
      _logger.e('Failed to cache connectivity status', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  ConnectivityStatus? getCurrentConnectivityStatus() {
    try {
      return _connectivityBox.get('current');
    } catch (e, stackTrace) {
      _logger.e('Failed to get current connectivity status', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  List<ConnectivityStatus> getConnectivityHistory({int limit = 10}) {
    try {
      final historyKeys = _connectivityBox.keys
          .where((key) => key.toString().startsWith('history_'))
          .toList();
      
      historyKeys.sort((a, b) => b.toString().compareTo(a.toString()));
      
      final limitedKeys = historyKeys.take(limit);
      
      return limitedKeys
          .map((key) => _connectivityBox.get(key))
          .where((status) => status != null)
          .cast<ConnectivityStatus>()
          .toList();
    } catch (e, stackTrace) {
      _logger.e('Failed to get connectivity history', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  // Sync Statistics Operations
  Future<void> cacheSyncStats(OfflineSyncStats stats) async {
    try {
      await _syncStatsBox.put('current', stats);
      _logger.d('Cached sync statistics');
    } catch (e, stackTrace) {
      _logger.e('Failed to cache sync stats', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  OfflineSyncStats? getCachedSyncStats() {
    try {
      return _syncStatsBox.get('current');
    } catch (e, stackTrace) {
      _logger.e('Failed to get cached sync stats', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  // Secure Storage Operations for Sensitive Data
  Future<void> storeSecureData(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
      _logger.d('Stored secure data with key: $key');
    } catch (e, stackTrace) {
      _logger.e('Failed to store secure data', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<String?> getSecureData(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e, stackTrace) {
      _logger.e('Failed to get secure data', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  Future<void> deleteSecureData(String key) async {
    try {
      await _secureStorage.delete(key: key);
      _logger.d('Deleted secure data with key: $key');
    } catch (e, stackTrace) {
      _logger.e('Failed to delete secure data', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> clearAllSecureData() async {
    try {
      await _secureStorage.deleteAll();
      _logger.d('Cleared all secure data');
    } catch (e, stackTrace) {
      _logger.e('Failed to clear all secure data', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Cache Expiration Management
  Future<void> cleanExpiredCache() async {
    try {
      int cleanedCount = 0;
      
      // Clean expired offline workouts
      final expiredWorkoutIds = _offlineWorkoutBox.values
          .where((workout) => !workout.isValid)
          .map((workout) => workout.workout.id)
          .toList();
      
      for (final id in expiredWorkoutIds) {
        await _offlineWorkoutBox.delete(id);
        cleanedCount++;
      }
      
      // Clean expired exercise cache
      final exerciseCache = _offlineExerciseCacheBox.get('exercises');
      if (exerciseCache != null && exerciseCache.isExpired) {
        await _offlineExerciseCacheBox.delete('exercises');
        cleanedCount++;
      }
      
      _logger.d('Cleaned $cleanedCount expired cache entries');
    } catch (e, stackTrace) {
      _logger.e('Failed to clean expired cache', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Enhanced Cache Statistics
  Map<String, dynamic> getEnhancedCacheStatistics() {
    try {
      final baseStats = getCacheStatistics();
      
      // Add new cache statistics
      baseStats['offline_workouts'] = _offlineWorkoutBox.length;
      baseStats['offline_exercise_cache'] = _offlineExerciseCacheBox.length;
      baseStats['sync_queue_items'] = _syncQueueItemBox.length;
      baseStats['connectivity_history'] = _connectivityBox.length;
      baseStats['sync_stats'] = _syncStatsBox.length;
      
      // Update total count
      baseStats['total_cached_items'] = baseStats['total_cached_items'] + 
                                       _offlineWorkoutBox.length + 
                                       _offlineExerciseCacheBox.length + 
                                       _syncQueueItemBox.length + 
                                       _connectivityBox.length + 
                                       _syncStatsBox.length;
      
      // Add cache health information
      final offlineWorkouts = _offlineWorkoutBox.values.toList();
      final validWorkouts = offlineWorkouts.where((w) => w.isValid).length;
      final expiredWorkouts = offlineWorkouts.length - validWorkouts;
      
      baseStats['cache_health'] = {
        'valid_offline_workouts': validWorkouts,
        'expired_offline_workouts': expiredWorkouts,
        'exercise_cache_valid': getCachedOfflineExercises()?.isValid ?? false,
        'pending_sync_items': getSyncQueueItems().where((item) => item.shouldRetry).length,
        'failed_sync_items': getSyncQueueItems().where((item) => !item.shouldRetry && item.retryCount > 0).length,
      };
      
      return baseStats;
    } catch (e, stackTrace) {
      _logger.e('Failed to get enhanced cache statistics', error: e, stackTrace: stackTrace);
      return {'error': e.toString()};
    }
  }
}