import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../constants/app_constants.dart';
import '../models/workout_log.dart';
import '../models/completed_workout.dart';
import '../models/workout.dart';
import '../models/workout_set_log.dart';
import '../models/user_profile.dart';
import '../models/exercise_favorite.dart';
import '../models/exercise_collection.dart';
import '../models/completed_set.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();
  
  SupabaseService._();
  
  final Logger _logger = Logger();
  
  /// Initialize Supabase client
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        anonKey: AppConstants.supabaseAnonKey,
        debug: AppConstants.environment == 'development',
      );
      
      instance._logger.i('Supabase initialized successfully');
    } catch (e, stackTrace) {
      instance._logger.e(
        'Failed to initialize Supabase',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Get Supabase client instance
  SupabaseClient get client => Supabase.instance.client;
  
  /// Get current user
  User? get currentUser => client.auth.currentUser;
  
  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;
  
  /// Get auth stream
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
  
  /// Sign out user
  Future<void> signOut() async {
    try {
      await client.auth.signOut();
      _logger.i('User signed out successfully');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to sign out user',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Get user profile from database
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await client
          .from(AppConstants.profilesTable)
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      return response;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to get user profile',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Update user profile in database
  Future<void> updateUserProfile(dynamic profileOrUserId, [Map<String, dynamic>? data]) async {
    try {
      Map<String, dynamic> profileData;
      String userId;
      
      if (profileOrUserId is UserProfile) {
        // Called with UserProfile object
        final profile = profileOrUserId;
        userId = profile.id;
        profileData = profile.toJson();
      } else if (profileOrUserId is String && data != null) {
        // Called with userId and data map
        userId = profileOrUserId;
        profileData = data;
      } else {
        throw ArgumentError('Invalid arguments: expected UserProfile or (String, Map<String, dynamic>)');
      }
      
      await client
          .from(AppConstants.profilesTable)
          .upsert({
            'id': userId,
            ...profileData,
            'updated_at': DateTime.now().toIso8601String(),
          });
      
      _logger.i('User profile updated successfully');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to update user profile',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Insert workout log
  Future<void> insertWorkoutLog(WorkoutLog workoutLog) async {
    try {
      await client
          .from(AppConstants.workoutLogsTable)
          .insert(workoutLog.toJson());
      
      _logger.i('Workout log inserted successfully');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to insert workout log',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Insert completed workout
  Future<void> insertCompletedWorkout(CompletedWorkout completedWorkout) async {
    try {
      await client
          .from(AppConstants.completedWorkoutsTable)
          .insert(completedWorkout.toJson());
      
      _logger.i('Completed workout inserted successfully');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to insert completed workout',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Insert workout
  Future<void> insertWorkout(Workout workout) async {
    try {
      await client
          .from(AppConstants.workoutsTable)
          .insert(workout.toJson());
      
      _logger.i('Workout inserted successfully');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to insert workout',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Update workout log
  Future<void> updateWorkoutLog(WorkoutLog workoutLog) async {
    try {
      await client
          .from(AppConstants.workoutLogsTable)
          .update(workoutLog.toJson())
          .eq('id', workoutLog.id);
      
      _logger.i('Workout log updated successfully');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to update workout log',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Update completed workout
  Future<void> updateCompletedWorkout(CompletedWorkout completedWorkout) async {
    try {
      await client
          .from(AppConstants.completedWorkoutsTable)
          .update(completedWorkout.toJson())
          .eq('id', completedWorkout.id);
      
      _logger.i('Completed workout updated successfully');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to update completed workout',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Update workout
  Future<void> updateWorkout(Workout workout) async {
    try {
      await client
          .from(AppConstants.workoutsTable)
          .update(workout.toJson())
          .eq('id', workout.id);
      
      _logger.i('Workout updated successfully');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to update workout',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Insert workout set log
  Future<void> insertWorkoutSetLog(WorkoutSetLog setLog) async {
    try {
      await client
          .from(AppConstants.workoutSetLogsTable)
          .insert(setLog.toJson());
      
      _logger.i('Workout set log inserted successfully');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to insert workout set log',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }



  /// Create workout
  Future<void> createWorkout(Workout workout) async {
    try {
      await client
          .from(AppConstants.workoutsTable)
          .insert(workout.toJson());
      
      _logger.i('Workout created successfully');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to create workout',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Add exercise favorite
  Future<void> addExerciseFavorite(ExerciseFavorite favorite) async {
    try {
      await client
          .from('exercise_favorites') // Add this to AppConstants if needed
          .insert(favorite.toJson());
      
      _logger.i('Exercise favorite added successfully');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to add exercise favorite',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Create exercise collection
  Future<void> createExerciseCollection(ExerciseCollection collection) async {
    try {
      await client
          .from('exercise_collections') // Add this to AppConstants if needed
          .insert(collection.toJson());
      
      _logger.i('Exercise collection created successfully');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to create exercise collection',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Insert completed set
  Future<void> insertCompletedSet(CompletedSet completedSet) async {
    try {
      await client
          .from(AppConstants.completedSetsTable)
          .insert(completedSet.toJson());
      
      _logger.i('Completed set inserted successfully');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to insert completed set',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}