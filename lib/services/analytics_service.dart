import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/models.dart';
import '../constants/app_constants.dart';
import 'supabase_service.dart';
import 'offline_cache_service.dart';

/// Comprehensive analytics service for progress tracking and performance analysis
class AnalyticsService {
  static AnalyticsService? _instance;
  static AnalyticsService get instance => _instance ??= AnalyticsService._();
  
  AnalyticsService._();
  
  final Logger _logger = Logger();
  final SupabaseService _supabaseService = SupabaseService.instance;
  final OfflineCacheService _cacheService = OfflineCacheService.instance;

  /// Get comprehensive analytics data for a user
  Future<AnalyticsData> getAnalyticsData({String? userId}) async {
    try {
      final currentUserId = userId ?? _supabaseService.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Check cache first
      final cachedAnalytics = _cacheService.getCachedAnalytics(currentUserId);
      if (cachedAnalytics != null && !cachedAnalytics.isStale) {
        _logger.i('Using cached analytics data');
        return cachedAnalytics;
      }

      _logger.i('Calculating fresh analytics data');

      // Create sample analytics data for now
      final analyticsData = AnalyticsData(
        userId: currentUserId,
        calculatedAt: DateTime.now(),
        workoutFrequency: WorkoutFrequencyAnalytics(
          totalWorkouts: 25,
          workoutsThisWeek: 3,
          workoutsThisMonth: 12,
          averageWorkoutsPerWeek: 3.5,
          currentStreak: 5,
          longestStreak: 14,
          consistencyScore: 0.8,
          dailyWorkouts: [],
        ),
        volume: VolumeAnalytics(
          totalVolumeLifetime: 15000.0,
          totalVolumeThisWeek: 1200.0,
          totalVolumeThisMonth: 5000.0,
          averageVolumePerWorkout: 600.0,
          averageVolumePerWeek: 1200.0,
          weeklyVolume: [],
          exerciseVolume: [],
        ),
        progress: ProgressAnalytics(
          totalSets: 150,
          totalReps: 2500,
          totalExercisesCompleted: 75,
          averageWorkoutDuration: 45.0,
          averageWorkoutRating: 4.2,
          totalCaloriesBurned: 8500,
          exerciseProgress: [],
        ),
        personalRecords: [],
        milestones: [],
        trends: TrendAnalytics(
          volumeTrend: 0.15,
          frequencyTrend: 0.08,
          durationTrend: -0.05,
          ratingTrend: 0.12,
          volumeTrendData: [],
          frequencyTrendData: [],
        ),
      );

      // Cache the results
      await _cacheService.cacheAnalytics(analyticsData);

      _logger.i('Analytics calculation completed');
      return analyticsData;
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to get analytics data',
        error: e,
        stackTrace: stackTrace,
      );
      
      // Try to return cached data even if stale
      final cachedAnalytics = _cacheService.getCachedAnalytics(userId ?? '');
      if (cachedAnalytics != null) {
        _logger.w('Using stale cached analytics data as fallback');
        return cachedAnalytics;
      }
      
      rethrow;
    }
  }

  /// Get filtered workout logs with advanced filtering
  Future<List<WorkoutLog>> getFilteredWorkoutLogs({
    String? userId,
    dynamic dateFilter,
    dynamic statusFilter,
    dynamic ratingFilter,
    dynamic exerciseFilter,
  }) async {
    try {
      final currentUserId = userId ?? _supabaseService.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // For now, return sample data
      final sampleWorkouts = <WorkoutLog>[];
      final now = DateTime.now();
      
      for (int i = 0; i < 10; i++) {
        final workoutDate = now.subtract(Duration(days: i * 3));
        sampleWorkouts.add(WorkoutLog(
          id: 'workout_$i',
          userId: currentUserId,
          workoutId: 'workout_template_$i',
          completedAt: workoutDate,
          startedAt: workoutDate.subtract(const Duration(minutes: 45)),
          endedAt: workoutDate,
          duration: 45,
          durationSeconds: 2700,
          rating: 3 + (i % 3),
          notes: i % 3 == 0 ? 'Great workout today!' : null,
          status: 'completed',
          createdAt: workoutDate,
        ));
      }

      // Apply filters
      var filteredWorkouts = sampleWorkouts;

      if (dateFilter != null) {
        filteredWorkouts = filteredWorkouts.where((workout) {
          final workoutDate = workout.completedAt ?? workout.createdAt;
          return workoutDate.isAfter(dateFilter.start) && 
                 workoutDate.isBefore(dateFilter.end);
        }).toList();
      }

      if (statusFilter != null) {
        filteredWorkouts = filteredWorkouts.where((workout) => 
            workout.status == statusFilter).toList();
      }

      if (ratingFilter != null) {
        filteredWorkouts = filteredWorkouts.where((workout) => 
            workout.rating != null && workout.rating! >= ratingFilter).toList();
      }

      return filteredWorkouts;
    } catch (e) {
      _logger.e('Failed to get filtered workout logs: $e');
      return [];
    }
  }

  /// Get detailed workout analysis combining data from multiple tables
  Future<Map<String, dynamic>> getWorkoutAnalysis(String workoutLogId) async {
    try {
      // Return sample analysis data
      return {
        'workout_log': {
          'id': workoutLogId,
          'duration_minutes': 45,
          'rating': 4,
          'status': 'completed',
        },
        'summary': {
          'total_volume': 1250.0,
          'total_sets': 12,
          'total_reps': 156,
          'unique_exercises': 5,
          'duration_minutes': 45,
          'rating': 4,
          'status': 'completed',
        },
        'exercise_breakdown': {
          'exercise_1': {
            'volume': 300.0,
            'sets': 3,
            'reps': 30,
            'max_weight': 80.0,
            'avg_weight': 75.0,
            'set_details': [
              {
                'set_number': 1,
                'reps': 10,
                'weight': 70.0,
                'volume': 700.0,
                'completed_at': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
              },
              {
                'set_number': 2,
                'reps': 10,
                'weight': 75.0,
                'volume': 750.0,
                'completed_at': DateTime.now().subtract(const Duration(minutes: 25)).toIso8601String(),
              },
              {
                'set_number': 3,
                'reps': 10,
                'weight': 80.0,
                'volume': 800.0,
                'completed_at': DateTime.now().subtract(const Duration(minutes: 20)).toIso8601String(),
              },
            ],
          },
          'exercise_2': {
            'volume': 400.0,
            'sets': 3,
            'reps': 36,
            'max_weight': 100.0,
            'avg_weight': 95.0,
            'set_details': [
              {
                'set_number': 1,
                'reps': 12,
                'weight': 90.0,
                'volume': 1080.0,
                'completed_at': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
              },
              {
                'set_number': 2,
                'reps': 12,
                'weight': 95.0,
                'volume': 1140.0,
                'completed_at': DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String(),
              },
              {
                'set_number': 3,
                'reps': 12,
                'weight': 100.0,
                'volume': 1200.0,
                'completed_at': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
              },
            ],
          },
        },
        'completed_sets': [],
        'workout_set_logs': [],
      };
    } catch (e) {
      _logger.e('Failed to get workout analysis: $e');
      rethrow;
    }
  }

  /// Compare two workouts and return performance differences
  Future<Map<String, dynamic>> compareWorkouts(String workoutId1, String workoutId2) async {
    try {
      final workout1Analysis = await getWorkoutAnalysis(workoutId1);
      final workout2Analysis = await getWorkoutAnalysis(workoutId2);

      final summary1 = workout1Analysis['summary'] as Map<String, dynamic>;
      final summary2 = workout2Analysis['summary'] as Map<String, dynamic>;

      // Calculate differences
      final volumeDiff = (summary2['total_volume'] as double) - (summary1['total_volume'] as double);
      final setsDiff = (summary2['total_sets'] as int) - (summary1['total_sets'] as int);
      final repsDiff = (summary2['total_reps'] as int) - (summary1['total_reps'] as int);
      final durationDiff = (summary2['duration_minutes'] as int) - (summary1['duration_minutes'] as int);
      final ratingDiff = ((summary2['rating'] as int?) ?? 0) - ((summary1['rating'] as int?) ?? 0);

      return {
        'workout1': workout1Analysis,
        'workout2': workout2Analysis,
        'comparison': {
          'volume_difference': volumeDiff,
          'sets_difference': setsDiff,
          'reps_difference': repsDiff,
          'duration_difference': durationDiff,
          'rating_difference': ratingDiff,
          'volume_improvement_percent': summary1['total_volume'] > 0 
              ? (volumeDiff / (summary1['total_volume'] as double)) * 100 
              : 0.0,
          'performance_summary': _generatePerformanceSummary(volumeDiff, setsDiff, repsDiff, durationDiff, ratingDiff),
        },
      };
    } catch (e) {
      _logger.e('Failed to compare workouts: $e');
      rethrow;
    }
  }

  /// Get body measurement tracking data from profile history
  Future<Map<String, dynamic>> getBodyMeasurementData({
    String? userId,
    int? limitDays,
  }) async {
    try {
      final currentUserId = userId ?? _supabaseService.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Return sample data for now
      return {
        'current_weight': 75.0,
        'current_height': 175.0,
        'weight_unit': 'kg',
        'height_unit': 'cm',
        'bmi': 24.5,
        'weight_history': [],
        'measurement_history': [],
      };
    } catch (e) {
      _logger.e('Failed to get body measurement data: $e');
      return {};
    }
  }

  /// Refresh analytics data (force recalculation)
  Future<AnalyticsData> refreshAnalytics({String? userId}) async {
    final currentUserId = userId ?? _supabaseService.currentUser?.id;
    if (currentUserId != null) {
      await _cacheService.clearAnalyticsCache(currentUserId);
    }
    return await getAnalyticsData(userId: userId);
  }

  /// Clear analytics cache
  Future<void> clearAnalyticsCache({String? userId}) async {
    final currentUserId = userId ?? _supabaseService.currentUser?.id;
    if (currentUserId != null) {
      await _cacheService.clearAnalyticsCache(currentUserId);
    }
  }

  /// Generate performance summary for workout comparison
  String _generatePerformanceSummary(double volumeDiff, int setsDiff, int repsDiff, int durationDiff, int ratingDiff) {
    final improvements = <String>[];
    final declines = <String>[];

    if (volumeDiff > 0) improvements.add('volume (+${volumeDiff.toStringAsFixed(1)}kg)');
    else if (volumeDiff < 0) declines.add('volume (${volumeDiff.toStringAsFixed(1)}kg)');

    if (setsDiff > 0) improvements.add('sets (+$setsDiff)');
    else if (setsDiff < 0) declines.add('sets ($setsDiff)');

    if (repsDiff > 0) improvements.add('reps (+$repsDiff)');
    else if (repsDiff < 0) declines.add('reps ($repsDiff)');

    if (durationDiff > 0) improvements.add('duration (+${durationDiff}min)');
    else if (durationDiff < 0) declines.add('duration (${durationDiff}min)');

    if (ratingDiff > 0) improvements.add('rating (+$ratingDiff⭐)');
    else if (ratingDiff < 0) declines.add('rating ($ratingDiff⭐)');

    if (improvements.isEmpty && declines.isEmpty) {
      return 'Performance remained consistent between workouts';
    }

    String summary = '';
    if (improvements.isNotEmpty) {
      summary += 'Improved: ${improvements.join(', ')}';
    }
    if (declines.isNotEmpty) {
      if (summary.isNotEmpty) summary += '. ';
      summary += 'Declined: ${declines.join(', ')}';
    }

    return summary;
  }
}