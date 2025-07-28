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

      // Fetch all required data
      final completedWorkouts = await _getCompletedWorkouts(currentUserId);
      final completedSets = await _getCompletedSets(currentUserId);
      final workoutLogs = await _getWorkoutLogs(currentUserId);
      final workoutSetLogs = await _getWorkoutSetLogs(currentUserId);

      // Calculate analytics
      final workoutFrequency = await _calculateWorkoutFrequency(workoutLogs);
      final volume = await _calculateVolumeAnalytics(completedSets, workoutSetLogs);
      final progress = await _calculateProgressAnalytics(completedWorkouts, completedSets);
      final personalRecords = await _detectPersonalRecords(workoutSetLogs, completedSets);
      final milestones = await _detectMilestones(workoutLogs, completedWorkouts, personalRecords);
      final trends = await _calculateTrendAnalytics(workoutLogs, completedWorkouts, workoutSetLogs);

      final analyticsData = AnalyticsData(
        userId: currentUserId,
        calculatedAt: DateTime.now(),
        workoutFrequency: workoutFrequency,
        volume: volume,
        progress: progress,
        personalRecords: personalRecords,
        milestones: milestones,
        trends: trends,
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

  /// Calculate workout frequency and consistency analytics
  Future<WorkoutFrequencyAnalytics> _calculateWorkoutFrequency(List<WorkoutLog> workoutLogs) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);
    
    // Filter completed workouts
    final completedWorkouts = workoutLogs.where((log) => log.isCompleted).toList();
    
    // Calculate basic counts
    final totalWorkouts = completedWorkouts.length;
    final workoutsThisWeek = completedWorkouts
        .where((log) => (log.completedAt ?? log.createdAt).isAfter(weekStart))
        .length;
    final workoutsThisMonth = completedWorkouts
        .where((log) => (log.completedAt ?? log.createdAt).isAfter(monthStart))
        .length;

    // Calculate average workouts per week
    final firstWorkout = completedWorkouts.isNotEmpty 
        ? completedWorkouts.map((log) => log.completedAt ?? log.createdAt).reduce((a, b) => a.isBefore(b) ? a : b)
        : now;
    final weeksSinceFirst = now.difference(firstWorkout).inDays / 7;
    final averageWorkoutsPerWeek = weeksSinceFirst > 0 ? totalWorkouts / weeksSinceFirst : 0.0;

    // Calculate streaks
    final streaks = _calculateWorkoutStreaks(completedWorkouts);
    final currentStreak = streaks['current'] ?? 0;
    final longestStreak = streaks['longest'] ?? 0;

    // Calculate consistency score (0-1)
    final consistencyScore = _calculateConsistencyScore(completedWorkouts);

    // Generate daily workout counts for the last 30 days
    final dailyWorkouts = _generateDailyWorkoutCounts(completedWorkouts, 30);

    return WorkoutFrequencyAnalytics(
      totalWorkouts: totalWorkouts,
      workoutsThisWeek: workoutsThisWeek,
      workoutsThisMonth: workoutsThisMonth,
      averageWorkoutsPerWeek: averageWorkoutsPerWeek,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      consistencyScore: consistencyScore,
      dailyWorkouts: dailyWorkouts,
    );
  }

  /// Calculate volume tracking analytics
  Future<VolumeAnalytics> _calculateVolumeAnalytics(
    List<CompletedSet> completedSets,
    List<WorkoutSetLog> workoutSetLogs,
  ) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    // Combine volume data from both sources
    final allVolumeSets = <VolumeDataPoint>[];
    
    // Add completed sets
    for (final set in completedSets) {
      if (set.hasWeight && set.performedReps != null) {
        allVolumeSets.add(VolumeDataPoint(
          date: set.createdAt,
          volume: set.volume,
          exerciseId: set.workoutExerciseId ?? '',
        ));
      }
    }
    
    // Add workout set logs
    for (final setLog in workoutSetLogs) {
      if (setLog.hasWeight) {
        allVolumeSets.add(VolumeDataPoint(
          date: setLog.completedAt,
          volume: setLog.volume,
          exerciseId: setLog.exerciseId,
        ));
      }
    }

    // Calculate totals
    final totalVolumeLifetime = allVolumeSets.fold(0.0, (sum, set) => sum + set.volume);
    final totalVolumeThisWeek = allVolumeSets
        .where((set) => set.date.isAfter(weekStart))
        .fold(0.0, (sum, set) => sum + set.volume);
    final totalVolumeThisMonth = allVolumeSets
        .where((set) => set.date.isAfter(monthStart))
        .fold(0.0, (sum, set) => sum + set.volume);

    // Calculate averages
    final workoutDates = allVolumeSets.map((set) => set.date).toSet();
    final averageVolumePerWorkout = workoutDates.isNotEmpty 
        ? totalVolumeLifetime / workoutDates.length 
        : 0.0;

    final firstWorkout = allVolumeSets.isNotEmpty 
        ? allVolumeSets.map((set) => set.date).reduce((a, b) => a.isBefore(b) ? a : b)
        : now;
    final weeksSinceFirst = now.difference(firstWorkout).inDays / 7;
    final averageVolumePerWeek = weeksSinceFirst > 0 ? totalVolumeLifetime / weeksSinceFirst : 0.0;

    // Generate weekly volume data
    final weeklyVolume = _generateWeeklyVolumeData(allVolumeSets, 12);

    // Generate exercise volume data
    final exerciseVolume = await _generateExerciseVolumeData(allVolumeSets);

    return VolumeAnalytics(
      totalVolumeLifetime: totalVolumeLifetime,
      totalVolumeThisWeek: totalVolumeThisWeek,
      totalVolumeThisMonth: totalVolumeThisMonth,
      averageVolumePerWorkout: averageVolumePerWorkout,
      averageVolumePerWeek: averageVolumePerWeek,
      weeklyVolume: weeklyVolume,
      exerciseVolume: exerciseVolume,
    );
  }

  /// Calculate progress analytics
  Future<ProgressAnalytics> _calculateProgressAnalytics(
    List<CompletedWorkout> completedWorkouts,
    List<CompletedSet> completedSets,
  ) async {
    // Calculate totals
    final totalSets = completedSets.length;
    final totalReps = completedSets.fold(0, (sum, set) => sum + (set.performedReps ?? 0));
    final totalExercisesCompleted = completedWorkouts.fold(0, (sum, workout) => sum + workout.exercisesCompleted);

    // Calculate averages
    final averageWorkoutDuration = completedWorkouts.isNotEmpty
        ? completedWorkouts.fold(0.0, (sum, workout) => sum + workout.duration) / completedWorkouts.length
        : 0.0;

    final ratingsWorkouts = completedWorkouts.where((workout) => workout.hasRating).toList();
    final averageWorkoutRating = ratingsWorkouts.isNotEmpty
        ? ratingsWorkouts.fold(0.0, (sum, workout) => sum + workout.rating!) / ratingsWorkouts.length
        : 0.0;

    final totalCaloriesBurned = completedWorkouts.fold(0, (sum, workout) => sum + workout.caloriesBurned);

    // Generate exercise progress data
    final exerciseProgress = await _generateExerciseProgressData(completedSets);

    return ProgressAnalytics(
      totalSets: totalSets,
      totalReps: totalReps,
      totalExercisesCompleted: totalExercisesCompleted,
      averageWorkoutDuration: averageWorkoutDuration,
      averageWorkoutRating: averageWorkoutRating,
      totalCaloriesBurned: totalCaloriesBurned,
      exerciseProgress: exerciseProgress,
    );
  }

  /// Detect personal records
  Future<List<PersonalRecord>> _detectPersonalRecords(
    List<WorkoutSetLog> workoutSetLogs,
    List<CompletedSet> completedSets,
  ) async {
    final personalRecords = <PersonalRecord>[];
    final exerciseRecords = <String, Map<PersonalRecordType, PersonalRecord>>{};

    // Process workout set logs
    for (final setLog in workoutSetLogs) {
      await _processSetForPersonalRecords(
        exerciseRecords,
        setLog.exerciseId,
        setLog.weight ?? 0,
        setLog.repsCompleted,
        setLog.volume,
        setLog.completedAt,
        setLog.workoutLogId,
      );
    }

    // Process completed sets
    for (final set in completedSets) {
      if (set.workoutExerciseId != null) {
        await _processSetForPersonalRecords(
          exerciseRecords,
          set.workoutExerciseId!,
          (set.performedWeight ?? 0).toDouble(),
          set.performedReps ?? 0,
          set.volume,
          set.createdAt,
          set.workoutId ?? '',
        );
      }
    }

    // Flatten records
    for (final exerciseRecords in exerciseRecords.values) {
      personalRecords.addAll(exerciseRecords.values);
    }

    // Sort by achievement date (most recent first)
    personalRecords.sort((a, b) => b.achievedAt.compareTo(a.achievedAt));

    return personalRecords;
  }

  /// Detect milestones based on workout patterns and achievements
  Future<List<Milestone>> _detectMilestones(
    List<WorkoutLog> workoutLogs,
    List<CompletedWorkout> completedWorkouts,
    List<PersonalRecord> personalRecords,
  ) async {
    final milestones = <Milestone>[];
    final completedWorkoutLogs = workoutLogs.where((log) => log.isCompleted).toList();

    // Workout count milestones
    final workoutCounts = [10, 25, 50, 100, 250, 500, 1000];
    for (final count in workoutCounts) {
      if (completedWorkoutLogs.length >= count) {
        final milestone = completedWorkoutLogs.length == count 
            ? completedWorkoutLogs[count - 1]
            : completedWorkoutLogs.firstWhere((log) => completedWorkoutLogs.indexOf(log) == count - 1);
        
        milestones.add(Milestone(
          id: 'workout_count_$count',
          type: MilestoneType.workoutCount,
          title: '$count Workouts Completed',
          description: 'Completed $count total workouts',
          achievedAt: milestone.completedAt ?? milestone.createdAt,
          metadata: {'count': count},
        ));
      }
    }

    // Streak milestones
    final streaks = _calculateWorkoutStreaks(completedWorkoutLogs);
    final longestStreak = streaks['longest'] ?? 0;
    final streakMilestones = [7, 14, 30, 60, 100];
    for (final streakCount in streakMilestones) {
      if (longestStreak >= streakCount) {
        milestones.add(Milestone(
          id: 'streak_$streakCount',
          type: MilestoneType.streak,
          title: '$streakCount Day Streak',
          description: 'Maintained a $streakCount day workout streak',
          achievedAt: DateTime.now().subtract(Duration(days: longestStreak - streakCount)),
          metadata: {'streak_days': streakCount},
        ));
      }
    }

    // Volume milestones
    final totalVolume = completedWorkouts.fold(0.0, (sum, workout) => sum + workout.totalVolume);
    final volumeMilestones = [1000, 5000, 10000, 25000, 50000, 100000]; // kg
    for (final volume in volumeMilestones) {
      if (totalVolume >= volume) {
        milestones.add(Milestone(
          id: 'volume_$volume',
          type: MilestoneType.volume,
          title: '${volume}kg Total Volume',
          description: 'Lifted a total of ${volume}kg across all workouts',
          achievedAt: DateTime.now(), // Would need more precise calculation
          metadata: {'volume_kg': volume},
        ));
      }
    }

    // Personal record milestones
    final recentPRs = personalRecords.where((pr) => 
        DateTime.now().difference(pr.achievedAt).inDays <= 30
    ).toList();
    
    if (recentPRs.isNotEmpty) {
      milestones.add(Milestone(
        id: 'recent_prs_${recentPRs.length}',
        type: MilestoneType.personalRecord,
        title: '${recentPRs.length} Recent PRs',
        description: 'Set ${recentPRs.length} personal records in the last 30 days',
        achievedAt: recentPRs.first.achievedAt,
        metadata: {'pr_count': recentPRs.length},
      ));
    }

    // Sort by achievement date (most recent first)
    milestones.sort((a, b) => b.achievedAt.compareTo(a.achievedAt));

    return milestones;
  }

  /// Calculate trend analytics
  Future<TrendAnalytics> _calculateTrendAnalytics(
    List<WorkoutLog> workoutLogs,
    List<CompletedWorkout> completedWorkouts,
    List<WorkoutSetLog> workoutSetLogs,
  ) async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final sixtyDaysAgo = now.subtract(const Duration(days: 60));

    // Calculate volume trend
    final recentVolume = _calculateVolumeForPeriod(workoutSetLogs, thirtyDaysAgo, now);
    final previousVolume = _calculateVolumeForPeriod(workoutSetLogs, sixtyDaysAgo, thirtyDaysAgo);
    final volumeTrend = previousVolume > 0 ? (recentVolume - previousVolume) / previousVolume : 0.0;

    // Calculate frequency trend
    final recentFrequency = workoutLogs.where((log) => 
        log.isCompleted && (log.completedAt ?? log.createdAt).isAfter(thirtyDaysAgo)
    ).length.toDouble();
    final previousFrequency = workoutLogs.where((log) => 
        log.isCompleted && 
        (log.completedAt ?? log.createdAt).isAfter(sixtyDaysAgo) &&
        (log.completedAt ?? log.createdAt).isBefore(thirtyDaysAgo)
    ).length.toDouble();
    final frequencyTrend = previousFrequency > 0 ? (recentFrequency - previousFrequency) / previousFrequency : 0.0;

    // Calculate duration trend
    final recentWorkouts = completedWorkouts.where((workout) => 
        workout.completedAt.isAfter(thirtyDaysAgo)
    ).toList();
    final previousWorkouts = completedWorkouts.where((workout) => 
        workout.completedAt.isAfter(sixtyDaysAgo) && workout.completedAt.isBefore(thirtyDaysAgo)
    ).toList();
    
    final recentAvgDuration = recentWorkouts.isNotEmpty 
        ? recentWorkouts.fold(0.0, (sum, w) => sum + w.duration) / recentWorkouts.length
        : 0.0;
    final previousAvgDuration = previousWorkouts.isNotEmpty 
        ? previousWorkouts.fold(0.0, (sum, w) => sum + w.duration) / previousWorkouts.length
        : 0.0;
    final durationTrend = previousAvgDuration > 0 ? (recentAvgDuration - previousAvgDuration) / previousAvgDuration : 0.0;

    // Calculate rating trend
    final recentRatedWorkouts = recentWorkouts.where((w) => w.hasRating).toList();
    final previousRatedWorkouts = previousWorkouts.where((w) => w.hasRating).toList();
    
    final recentAvgRating = recentRatedWorkouts.isNotEmpty 
        ? recentRatedWorkouts.fold(0.0, (sum, w) => sum + w.rating!) / recentRatedWorkouts.length
        : 0.0;
    final previousAvgRating = previousRatedWorkouts.isNotEmpty 
        ? previousRatedWorkouts.fold(0.0, (sum, w) => sum + w.rating!) / previousRatedWorkouts.length
        : 0.0;
    final ratingTrend = previousAvgRating > 0 ? (recentAvgRating - previousAvgRating) / previousAvgRating : 0.0;

    // Generate trend data points
    final volumeTrendData = _generateVolumeTrendData(workoutSetLogs, 12);
    final frequencyTrendData = _generateFrequencyTrendData(workoutLogs, 12);

    return TrendAnalytics(
      volumeTrend: volumeTrend,
      frequencyTrend: frequencyTrend,
      durationTrend: durationTrend,
      ratingTrend: ratingTrend,
      volumeTrendData: volumeTrendData,
      frequencyTrendData: frequencyTrendData,
    );
  }

  // Helper methods for data fetching
  Future<List<CompletedWorkout>> _getCompletedWorkouts(String userId) async {
    try {
      final response = await _supabaseService.client
          .from(AppConstants.completedWorkoutsTable)
          .select()
          .eq('user_id', userId)
          .order('completed_at', ascending: false);

      return (response as List)
          .map((json) => CompletedWorkout.fromJson(json))
          .toList();
    } catch (e) {
      _logger.w('Failed to fetch completed workouts: $e');
      return [];
    }
  }

  Future<List<CompletedSet>> _getCompletedSets(String userId) async {
    try {
      final response = await _supabaseService.client
          .from(AppConstants.completedSetsTable)
          .select()
          .eq('workout_id', userId) // Assuming workout_id links to user workouts
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => CompletedSet.fromJson(json))
          .toList();
    } catch (e) {
      _logger.w('Failed to fetch completed sets: $e');
      return [];
    }
  }

  Future<List<WorkoutLog>> _getWorkoutLogs(String userId) async {
    try {
      final response = await _supabaseService.client
          .from(AppConstants.workoutLogsTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => WorkoutLog.fromJson(json))
          .toList();
    } catch (e) {
      _logger.w('Failed to fetch workout logs: $e');
      return [];
    }
  }

  Future<List<WorkoutSetLog>> _getWorkoutSetLogs(String userId) async {
    try {
      // Join with workout_logs to filter by user
      final response = await _supabaseService.client
          .from(AppConstants.workoutSetLogsTable)
          .select('''
            *,
            workout_logs!inner(user_id)
          ''')
          .eq('workout_logs.user_id', userId)
          .order('completed_at', ascending: false);

      return (response as List)
          .map((json) => WorkoutSetLog.fromJson(json))
          .toList();
    } catch (e) {
      _logger.w('Failed to fetch workout set logs: $e');
      return [];
    }
  }

  /// Get filtered workout logs with advanced filtering
  Future<List<WorkoutLog>> getFilteredWorkoutLogs({
    String? userId,
    DateTimeRange? dateFilter,
    String? statusFilter,
    int? ratingFilter,
    String? exerciseFilter,
  }) async {
    try {
      final currentUserId = userId ?? _supabaseService.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      var query = _supabaseService.client
          .from(AppConstants.workoutLogsTable)
          .select('''
            *,
            workouts!inner(
              id,
              workout_exercises(
                exercise_id,
                exercises(name)
              )
            )
          ''')
          .eq('user_id', currentUserId);

      // Apply date filter
      if (dateFilter != null) {
        query = query
            .gte('created_at', dateFilter.start.toIso8601String())
            .lte('created_at', dateFilter.end.toIso8601String());
      }

      // Apply status filter
      if (statusFilter != null) {
        query = query.eq('status', statusFilter);
      }

      // Apply rating filter (minimum rating)
      if (ratingFilter != null) {
        query = query.gte('rating', ratingFilter);
      }

      final response = await query.order('created_at', ascending: false);
      var workoutLogs = (response as List)
          .map((json) => WorkoutLog.fromJson(json))
          .toList();

      // Apply exercise filter (client-side for now)
      if (exerciseFilter != null && exerciseFilter.isNotEmpty) {
        workoutLogs = workoutLogs.where((log) {
          // This would need to be enhanced to check actual exercises in the workout
          return true; // Placeholder - would need to implement exercise filtering
        }).toList();
      }

      return workoutLogs;
    } catch (e) {
      _logger.e('Failed to get filtered workout logs: $e');
      return [];
    }
  }

  /// Get detailed workout analysis combining data from multiple tables
  Future<Map<String, dynamic>> getWorkoutAnalysis(String workoutLogId) async {
    try {
      // Get workout log details
      final workoutLogResponse = await _supabaseService.client
          .from(AppConstants.workoutLogsTable)
          .select('''
            *,
            workouts!inner(
              id,
              name,
              workout_exercises(
                *,
                exercises(*)
              )
            )
          ''')
          .eq('id', workoutLogId)
          .single();

      final workoutLog = WorkoutLog.fromJson(workoutLogResponse);

      // Get completed sets for this workout
      final completedSetsResponse = await _supabaseService.client
          .from(AppConstants.completedSetsTable)
          .select()
          .eq('workout_id', workoutLog.workoutId ?? '');

      final completedSets = (completedSetsResponse as List)
          .map((json) => CompletedSet.fromJson(json))
          .toList();

      // Get workout set logs for this workout
      final workoutSetLogsResponse = await _supabaseService.client
          .from(AppConstants.workoutSetLogsTable)
          .select('''
            *,
            exercises(name, primary_muscle, secondary_muscle)
          ''')
          .eq('workout_log_id', workoutLogId);

      final workoutSetLogs = (workoutSetLogsResponse as List)
          .map((json) => WorkoutSetLog.fromJson(json))
          .toList();

      // Calculate analysis metrics
      final totalVolume = workoutSetLogs.fold(0.0, (sum, set) => sum + set.volume);
      final totalSets = workoutSetLogs.length;
      final totalReps = workoutSetLogs.fold(0, (sum, set) => sum + set.repsCompleted);
      final uniqueExercises = workoutSetLogs.map((set) => set.exerciseId).toSet().length;

      // Group sets by exercise for detailed breakdown
      final exerciseBreakdown = <String, List<WorkoutSetLog>>{};
      for (final setLog in workoutSetLogs) {
        exerciseBreakdown.putIfAbsent(setLog.exerciseId, () => []).add(setLog);
      }

      // Calculate exercise-specific metrics
      final exerciseMetrics = exerciseBreakdown.map((exerciseId, sets) {
        final exerciseVolume = sets.fold(0.0, (sum, set) => sum + set.volume);
        final exerciseSets = sets.length;
        final exerciseReps = sets.fold(0, (sum, set) => sum + set.repsCompleted);
        final maxWeight = sets.map((set) => set.weight ?? 0).reduce((a, b) => a > b ? a : b);
        final avgWeight = sets.where((set) => set.weight != null).isNotEmpty
            ? sets.where((set) => set.weight != null).map((set) => set.weight!).reduce((a, b) => a + b) / sets.where((set) => set.weight != null).length
            : 0.0;

        return MapEntry(exerciseId, {
          'volume': exerciseVolume,
          'sets': exerciseSets,
          'reps': exerciseReps,
          'max_weight': maxWeight,
          'avg_weight': avgWeight,
          'set_details': sets.map((set) => {
            'set_number': set.setNumber,
            'reps': set.repsCompleted,
            'weight': set.weight,
            'volume': set.volume,
            'completed_at': set.completedAt.toIso8601String(),
          }).toList(),
        });
      });

      return {
        'workout_log': workoutLog.toJson(),
        'summary': {
          'total_volume': totalVolume,
          'total_sets': totalSets,
          'total_reps': totalReps,
          'unique_exercises': uniqueExercises,
          'duration_minutes': workoutLog.durationInMinutes ?? 0,
          'rating': workoutLog.rating,
          'status': workoutLog.status,
        },
        'exercise_breakdown': exerciseMetrics,
        'completed_sets': completedSets.map((set) => set.toJson()).toList(),
        'workout_set_logs': workoutSetLogs.map((log) => log.toJson()).toList(),
      };
    } catch (e) {
      _logger.e('Failed to get workout analysis: $e');
      rethrow;
    }
  }

  /// Get strength progression data for specific exercises
  Future<Map<String, List<ProgressDataPoint>>> getStrengthProgressionData({
    String? userId,
    List<String>? exerciseIds,
    int? limitDays,
  }) async {
    try {
      final currentUserId = userId ?? _supabaseService.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      var query = _supabaseService.client
          .from(AppConstants.workoutSetLogsTable)
          .select('''
            *,
            workout_logs!inner(user_id),
            exercises(name)
          ''')
          .eq('workout_logs.user_id', currentUserId)
          .not('weight', 'is', null);

      if (exerciseIds != null && exerciseIds.isNotEmpty) {
        query = query.in_('exercise_id', exerciseIds);
      }

      if (limitDays != null) {
        final cutoffDate = DateTime.now().subtract(Duration(days: limitDays));
        query = query.gte('completed_at', cutoffDate.toIso8601String());
      }

      final response = await query.order('completed_at', ascending: true);
      final workoutSetLogs = (response as List)
          .map((json) => WorkoutSetLog.fromJson(json))
          .toList();

      // Group by exercise and create progression data
      final progressionData = <String, List<ProgressDataPoint>>{};
      
      for (final setLog in workoutSetLogs) {
        progressionData.putIfAbsent(setLog.exerciseId, () => []).add(
          ProgressDataPoint(
            date: setLog.completedAt,
            weight: setLog.weight ?? 0,
            reps: setLog.repsCompleted,
            volume: setLog.volume,
          ),
        );
      }

      return progressionData;
    } catch (e) {
      _logger.e('Failed to get strength progression data: $e');
      return {};
    }
  }

  /// Get volume tracking data over time
  Future<List<WeeklyVolumeData>> getVolumeTrackingData({
    String? userId,
    int? limitWeeks,
  }) async {
    try {
      final currentUserId = userId ?? _supabaseService.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final weeks = limitWeeks ?? 12;
      final cutoffDate = DateTime.now().subtract(Duration(days: weeks * 7));

      final response = await _supabaseService.client
          .from(AppConstants.workoutSetLogsTable)
          .select('''
            *,
            workout_logs!inner(user_id)
          ''')
          .eq('workout_logs.user_id', currentUserId)
          .gte('completed_at', cutoffDate.toIso8601String())
          .order('completed_at', ascending: true);

      final workoutSetLogs = (response as List)
          .map((json) => WorkoutSetLog.fromJson(json))
          .toList();

      return _generateWeeklyVolumeData(
        workoutSetLogs.map((log) => VolumeDataPoint(
          date: log.completedAt,
          volume: log.volume,
          exerciseId: log.exerciseId,
        )).toList(),
        weeks,
      );
    } catch (e) {
      _logger.e('Failed to get volume tracking data: $e');
      return [];
    }
  }

  /// Get exercise-specific progress tracking data
  Future<List<ExerciseProgressData>> getExerciseProgressData({
    String? userId,
    List<String>? exerciseIds,
  }) async {
    try {
      final currentUserId = userId ?? _supabaseService.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      var query = _supabaseService.client
          .from(AppConstants.workoutSetLogsTable)
          .select('''
            *,
            workout_logs!inner(user_id),
            exercises(name)
          ''')
          .eq('workout_logs.user_id', currentUserId);

      if (exerciseIds != null && exerciseIds.isNotEmpty) {
        query = query.in_('exercise_id', exerciseIds);
      }

      final response = await query.order('completed_at', ascending: true);
      final workoutSetLogs = (response as List)
          .map((json) => WorkoutSetLog.fromJson(json))
          .toList();

      // Group by exercise
      final exerciseGroups = <String, List<WorkoutSetLog>>{};
      for (final setLog in workoutSetLogs) {
        exerciseGroups.putIfAbsent(setLog.exerciseId, () => []).add(setLog);
      }

      // Generate progress data for each exercise
      final exerciseProgressList = <ExerciseProgressData>[];
      for (final entry in exerciseGroups.entries) {
        final exerciseId = entry.key;
        final sets = entry.value;
        
        if (sets.isEmpty) continue;

        final maxWeight = sets.where((set) => set.weight != null).isNotEmpty
            ? sets.where((set) => set.weight != null).map((set) => set.weight!).reduce((a, b) => a > b ? a : b)
            : 0.0;
        final maxReps = sets.map((set) => set.repsCompleted).reduce((a, b) => a > b ? a : b);
        final totalVolume = sets.fold(0.0, (sum, set) => sum + set.volume);
        final totalSets = sets.length;

        final progressHistory = sets.map((set) => ProgressDataPoint(
          date: set.completedAt,
          weight: set.weight ?? 0,
          reps: set.repsCompleted,
          volume: set.volume,
        )).toList();

        exerciseProgressList.add(ExerciseProgressData(
          exerciseId: exerciseId,
          exerciseName: 'Exercise $exerciseId', // Would need to fetch actual name
          maxWeight: maxWeight,
          maxReps: maxReps,
          totalVolume: totalVolume,
          totalSets: totalSets,
          progressHistory: progressHistory,
        ));
      }

      return exerciseProgressList;
    } catch (e) {
      _logger.e('Failed to get exercise progress data: $e');
      return [];
    }
  }

  /// Get workout rating trends and feedback analysis
  Future<Map<String, dynamic>> getWorkoutRatingTrends({
    String? userId,
    int? limitDays,
  }) async {
    try {
      final currentUserId = userId ?? _supabaseService.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      var query = _supabaseService.client
          .from(AppConstants.workoutLogsTable)
          .select()
          .eq('user_id', currentUserId)
          .not('rating', 'is', null);

      if (limitDays != null) {
        final cutoffDate = DateTime.now().subtract(Duration(days: limitDays));
        query = query.gte('created_at', cutoffDate.toIso8601String());
      }

      final response = await query.order('created_at', ascending: true);
      final workoutLogs = (response as List)
          .map((json) => WorkoutLog.fromJson(json))
          .toList();

      // Calculate rating statistics
      final ratings = workoutLogs.map((log) => log.rating!).toList();
      final averageRating = ratings.isNotEmpty 
          ? ratings.reduce((a, b) => a + b) / ratings.length 
          : 0.0;

      // Rating distribution
      final ratingDistribution = <int, int>{};
      for (int i = 1; i <= 5; i++) {
        ratingDistribution[i] = ratings.where((rating) => rating == i).length;
      }

      // Rating trend over time (weekly averages)
      final weeklyRatings = <DateTime, List<int>>{};
      for (final log in workoutLogs) {
        final weekStart = _getWeekStart(log.completedAt ?? log.createdAt);
        weeklyRatings.putIfAbsent(weekStart, () => []).add(log.rating!);
      }

      final ratingTrendData = weeklyRatings.entries.map((entry) {
        final weekStart = entry.key;
        final weekRatings = entry.value;
        final weekAverage = weekRatings.reduce((a, b) => a + b) / weekRatings.length;
        
        return TrendDataPoint(
          date: weekStart,
          value: weekAverage,
        );
      }).toList()..sort((a, b) => a.date.compareTo(b.date));

      return {
        'average_rating': averageRating,
        'total_rated_workouts': workoutLogs.length,
        'rating_distribution': ratingDistribution,
        'rating_trend_data': ratingTrendData.map((point) => point.toJson()).toList(),
        'recent_ratings': workoutLogs.take(10).map((log) => {
          'date': (log.completedAt ?? log.createdAt).toIso8601String(),
          'rating': log.rating,
          'notes': log.notes,
        }).toList(),
      };
    } catch (e) {
      _logger.e('Failed to get workout rating trends: $e');
      return {};
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

      // For now, we'll get the current profile data
      // In a full implementation, you'd want to track profile changes over time
      final response = await _supabaseService.client
          .from(AppConstants.profilesTable)
          .select()
          .eq('id', currentUserId)
          .single();

      final profile = UserProfile.fromJson(response);

      // This is a simplified implementation
      // In reality, you'd want to track weight/height changes over time
      return {
        'current_weight': profile.weight,
        'current_height': profile.height,
        'weight_unit': profile.weightUnit,
        'height_unit': profile.heightUnit,
        'bmi': profile.weight != null && profile.height != null
            ? _calculateBMI(profile.weight!, profile.height!, profile.weightUnit, profile.heightUnit)
            : null,
        'weight_history': [], // Would need to implement weight tracking
        'measurement_history': [], // Would need to implement measurement tracking
      };
    } catch (e) {
      _logger.e('Failed to get body measurement data: $e');
      return {};
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

  // Helper methods for calculations
  Map<String, int> _calculateWorkoutStreaks(List<WorkoutLog> workoutLogs) {
    if (workoutLogs.isEmpty) return {'current': 0, 'longest': 0};

    // Sort by date
    final sortedLogs = workoutLogs.toList()
      ..sort((a, b) => (a.completedAt ?? a.createdAt).compareTo(b.completedAt ?? b.createdAt));

    var currentStreak = 0;
    var longestStreak = 0;
    var tempStreak = 1;
    
    DateTime? lastWorkoutDate;

    for (final log in sortedLogs) {
      final workoutDate = log.completedAt ?? log.createdAt;
      final dayOnly = DateTime(workoutDate.year, workoutDate.month, workoutDate.day);

      if (lastWorkoutDate != null) {
        final daysDifference = dayOnly.difference(lastWorkoutDate).inDays;
        
        if (daysDifference == 1) {
          tempStreak++;
        } else if (daysDifference > 1) {
          longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;
          tempStreak = 1;
        }
      }

      lastWorkoutDate = dayOnly;
    }

    longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;

    // Calculate current streak
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (lastWorkoutDate != null) {
      final daysSinceLastWorkout = today.difference(lastWorkoutDate).inDays;
      if (daysSinceLastWorkout <= 1) {
        currentStreak = tempStreak;
      }
    }

    return {'current': currentStreak, 'longest': longestStreak};
  }

  double _calculateConsistencyScore(List<WorkoutLog> workoutLogs) {
    if (workoutLogs.isEmpty) return 0.0;

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    final recentWorkouts = workoutLogs.where((log) => 
        (log.completedAt ?? log.createdAt).isAfter(thirtyDaysAgo)
    ).length;

    // Ideal would be ~4 workouts per week over 30 days = ~17 workouts
    const idealWorkouts = 17;
    return (recentWorkouts / idealWorkouts).clamp(0.0, 1.0);
  }

  List<DailyWorkoutCount> _generateDailyWorkoutCounts(List<WorkoutLog> workoutLogs, int days) {
    final now = DateTime.now();
    final dailyCounts = <DateTime, int>{};

    // Initialize all days with 0
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final dayOnly = DateTime(date.year, date.month, date.day);
      dailyCounts[dayOnly] = 0;
    }

    // Count workouts per day
    for (final log in workoutLogs) {
      final workoutDate = log.completedAt ?? log.createdAt;
      final dayOnly = DateTime(workoutDate.year, workoutDate.month, workoutDate.day);
      
      if (dailyCounts.containsKey(dayOnly)) {
        dailyCounts[dayOnly] = dailyCounts[dayOnly]! + 1;
      }
    }

    return dailyCounts.entries
        .map((entry) => DailyWorkoutCount(date: entry.key, count: entry.value))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<WeeklyVolumeData> _generateWeeklyVolumeData(List<VolumeDataPoint> volumeData, int weeks) {
    final now = DateTime.now();
    final weeklyVolume = <DateTime, double>{};

    // Initialize weeks
    for (int i = 0; i < weeks; i++) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1 + (i * 7)));
      final weekStartDay = DateTime(weekStart.year, weekStart.month, weekStart.day);
      weeklyVolume[weekStartDay] = 0.0;
    }

    // Aggregate volume by week
    for (final dataPoint in volumeData) {
      final weekStart = dataPoint.date.subtract(Duration(days: dataPoint.date.weekday - 1));
      final weekStartDay = DateTime(weekStart.year, weekStart.month, weekStart.day);
      
      if (weeklyVolume.containsKey(weekStartDay)) {
        weeklyVolume[weekStartDay] = weeklyVolume[weekStartDay]! + dataPoint.volume;
      }
    }

    return weeklyVolume.entries
        .map((entry) => WeeklyVolumeData(weekStart: entry.key, volume: entry.value))
        .toList()
      ..sort((a, b) => a.weekStart.compareTo(b.weekStart));
  }

  Future<List<ExerciseVolumeData>> _generateExerciseVolumeData(List<VolumeDataPoint> volumeData) async {
    final exerciseVolume = <String, ExerciseVolumeData>{};

    for (final dataPoint in volumeData) {
      if (exerciseVolume.containsKey(dataPoint.exerciseId)) {
        final existing = exerciseVolume[dataPoint.exerciseId]!;
        exerciseVolume[dataPoint.exerciseId] = ExerciseVolumeData(
          exerciseId: existing.exerciseId,
          exerciseName: existing.exerciseName,
          totalVolume: existing.totalVolume + dataPoint.volume,
          totalSets: existing.totalSets + 1,
        );
      } else {
        // Would need to fetch exercise name from database
        exerciseVolume[dataPoint.exerciseId] = ExerciseVolumeData(
          exerciseId: dataPoint.exerciseId,
          exerciseName: 'Exercise ${dataPoint.exerciseId}', // Placeholder
          totalVolume: dataPoint.volume,
          totalSets: 1,
        );
      }
    }

    return exerciseVolume.values.toList()
      ..sort((a, b) => b.totalVolume.compareTo(a.totalVolume));
  }

  Future<List<ExerciseProgressData>> _generateExerciseProgressData(List<CompletedSet> completedSets) async {
    final exerciseProgress = <String, ExerciseProgressData>{};

    for (final set in completedSets) {
      if (set.workoutExerciseId == null) continue;

      final exerciseId = set.workoutExerciseId!;
      
      if (exerciseProgress.containsKey(exerciseId)) {
        final existing = exerciseProgress[exerciseId]!;
        final newProgressHistory = List<ProgressDataPoint>.from(existing.progressHistory);
        
        newProgressHistory.add(ProgressDataPoint(
          date: set.createdAt,
          weight: (set.performedWeight ?? 0).toDouble(),
          reps: set.performedReps ?? 0,
          volume: set.volume,
        ));

        exerciseProgress[exerciseId] = ExerciseProgressData(
          exerciseId: existing.exerciseId,
          exerciseName: existing.exerciseName,
          maxWeight: [existing.maxWeight, (set.performedWeight ?? 0).toDouble()].reduce((a, b) => a > b ? a : b),
          maxReps: [existing.maxReps, set.performedReps ?? 0].reduce((a, b) => a > b ? a : b),
          totalVolume: existing.totalVolume + set.volume,
          totalSets: existing.totalSets + 1,
          progressHistory: newProgressHistory,
        );
      } else {
        exerciseProgress[exerciseId] = ExerciseProgressData(
          exerciseId: exerciseId,
          exerciseName: 'Exercise $exerciseId', // Placeholder
          maxWeight: (set.performedWeight ?? 0).toDouble(),
          maxReps: set.performedReps ?? 0,
          totalVolume: set.volume,
          totalSets: 1,
          progressHistory: [
            ProgressDataPoint(
              date: set.createdAt,
              weight: (set.performedWeight ?? 0).toDouble(),
              reps: set.performedReps ?? 0,
              volume: set.volume,
            ),
          ],
        );
      }
    }

    return exerciseProgress.values.toList()
      ..sort((a, b) => b.totalVolume.compareTo(a.totalVolume));
  }

  Future<void> _processSetForPersonalRecords(
    Map<String, Map<PersonalRecordType, PersonalRecord>> exerciseRecords,
    String exerciseId,
    double weight,
    int reps,
    double volume,
    DateTime achievedAt,
    String workoutLogId,
  ) async {
    if (!exerciseRecords.containsKey(exerciseId)) {
      exerciseRecords[exerciseId] = {};
    }

    final records = exerciseRecords[exerciseId]!;

    // Check max weight
    if (weight > 0) {
      final currentMaxWeight = records[PersonalRecordType.maxWeight];
      if (currentMaxWeight == null || weight > currentMaxWeight.value) {
        records[PersonalRecordType.maxWeight] = PersonalRecord(
          exerciseId: exerciseId,
          exerciseName: 'Exercise $exerciseId', // Placeholder
          type: PersonalRecordType.maxWeight,
          value: weight,
          achievedAt: achievedAt,
          workoutLogId: workoutLogId,
        );
      }
    }

    // Check max reps
    if (reps > 0) {
      final currentMaxReps = records[PersonalRecordType.maxReps];
      if (currentMaxReps == null || reps > currentMaxReps.value) {
        records[PersonalRecordType.maxReps] = PersonalRecord(
          exerciseId: exerciseId,
          exerciseName: 'Exercise $exerciseId', // Placeholder
          type: PersonalRecordType.maxReps,
          value: reps.toDouble(),
          achievedAt: achievedAt,
          workoutLogId: workoutLogId,
        );
      }
    }

    // Check max volume
    if (volume > 0) {
      final currentMaxVolume = records[PersonalRecordType.maxVolume];
      if (currentMaxVolume == null || volume > currentMaxVolume.value) {
        records[PersonalRecordType.maxVolume] = PersonalRecord(
          exerciseId: exerciseId,
          exerciseName: 'Exercise $exerciseId', // Placeholder
          type: PersonalRecordType.maxVolume,
          value: volume,
          achievedAt: achievedAt,
          workoutLogId: workoutLogId,
        );
      }
    }
  }

  double _calculateVolumeForPeriod(List<WorkoutSetLog> setLogs, DateTime start, DateTime end) {
    return setLogs
        .where((log) => log.completedAt.isAfter(start) && log.completedAt.isBefore(end))
        .fold(0.0, (sum, log) => sum + log.volume);
  }

  List<TrendDataPoint> _generateVolumeTrendData(List<WorkoutSetLog> setLogs, int weeks) {
    final now = DateTime.now();
    final weeklyData = <DateTime, double>{};

    for (int i = 0; i < weeks; i++) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1 + (i * 7)));
      final weekStartDay = DateTime(weekStart.year, weekStart.month, weekStart.day);
      weeklyData[weekStartDay] = 0.0;
    }

    for (final setLog in setLogs) {
      final weekStart = setLog.completedAt.subtract(Duration(days: setLog.completedAt.weekday - 1));
      final weekStartDay = DateTime(weekStart.year, weekStart.month, weekStart.day);
      
      if (weeklyData.containsKey(weekStartDay)) {
        weeklyData[weekStartDay] = weeklyData[weekStartDay]! + setLog.volume;
      }
    }

    return weeklyData.entries
        .map((entry) => TrendDataPoint(date: entry.key, value: entry.value))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<TrendDataPoint> _generateFrequencyTrendData(List<WorkoutLog> workoutLogs, int weeks) {
    final now = DateTime.now();
    final weeklyData = <DateTime, double>{};

    for (int i = 0; i < weeks; i++) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1 + (i * 7)));
      final weekStartDay = DateTime(weekStart.year, weekStart.month, weekStart.day);
      weeklyData[weekStartDay] = 0.0;
    }

    final completedLogs = workoutLogs.where((log) => log.isCompleted).toList();
    
    for (final log in completedLogs) {
      final logDate = log.completedAt ?? log.createdAt;
      final weekStart = logDate.subtract(Duration(days: logDate.weekday - 1));
      final weekStartDay = DateTime(weekStart.year, weekStart.month, weekStart.day);
      
      if (weeklyData.containsKey(weekStartDay)) {
        weeklyData[weekStartDay] = weeklyData[weekStartDay]! + 1.0;
      }
    }

    return weeklyData.entries
        .map((entry) => TrendDataPoint(date: entry.key, value: entry.value))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Refresh analytics data by clearing cache and recalculating
  Future<AnalyticsData> refreshAnalytics({String? userId}) async {
    try {
      final currentUserId = userId ?? _supabaseService.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Clear cache first
      await clearAnalyticsCache(userId: currentUserId);
      
      // Get fresh analytics data
      return await getAnalyticsData(userId: currentUserId);
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to refresh analytics data',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Clear analytics cache for a user
  Future<void> clearAnalyticsCache({String? userId}) async {
    try {
      final currentUserId = userId ?? _supabaseService.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _cacheService.clearAnalyticsCache(currentUserId);
      _logger.i('Analytics cache cleared for user: $currentUserId');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to clear analytics cache',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get filtered workout logs with advanced filtering
  Future<List<WorkoutLog>> getFilteredWorkoutLogs({
    String? userId,
    DateTimeRange? dateFilter,
    String? statusFilter,
    int? ratingFilter,
    String? exerciseFilter,
  }) async {
    try {
      final currentUserId = userId ?? _supabaseService.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      var query = _supabaseService.client
          .from(AppConstants.workoutLogsTable)
          .select()
          .eq('user_id', currentUserId);

      // Apply date filter
      if (dateFilter != null) {
        query = query
            .gte('created_at', dateFilter.start.toIso8601String())
            .lte('created_at', dateFilter.end.toIso8601String());
      }

      // Apply status filter
      if (statusFilter != null) {
        query = query.eq('status', statusFilter);
      }

      // Apply rating filter
      if (ratingFilter != null) {
        query = query.gte('rating', ratingFilter);
      }

      final response = await query.order('created_at', ascending: false);
      var workoutLogs = (response as List)
          .map((json) => WorkoutLog.fromJson(json))
          .toList();

      // Apply exercise filter (requires joining with workout data)
      if (exerciseFilter != null) {
        workoutLogs = await _filterByExercise(workoutLogs, exerciseFilter);
      }

      return workoutLogs;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to get filtered workout logs',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Filter workout logs by exercise name
  Future<List<WorkoutLog>> _filterByExercise(List<WorkoutLog> workoutLogs, String exerciseName) async {
    try {
      final filteredLogs = <WorkoutLog>[];
      
      for (final log in workoutLogs) {
        // Get workout set logs for this workout
        final setLogs = await _supabaseService.client
            .from(AppConstants.workoutSetLogsTable)
            .select('''
              *,
              exercises!inner(name)
            ''')
            .eq('workout_log_id', log.id);

        // Check if any exercise matches the filter
        final hasMatchingExercise = (setLogs as List).any((setLog) {
          final exerciseName = setLog['exercises']['name'] as String?;
          return exerciseName?.toLowerCase().contains(exerciseName.toLowerCase()) ?? false;
        });

        if (hasMatchingExercise) {
          filteredLogs.add(log);
        }
      }

      return filteredLogs;
    } catch (e) {
      _logger.w('Failed to filter by exercise: $e');
      return workoutLogs; // Return unfiltered if filtering fails
    }
  }

  /// Get detailed workout analysis for a specific workout
  Future<Map<String, dynamic>> getWorkoutAnalysis(String workoutLogId) async {
    try {
      // Get workout log
      final workoutLogResponse = await _supabaseService.client
          .from(AppConstants.workoutLogsTable)
          .select()
          .eq('id', workoutLogId)
          .single();

      final workoutLog = WorkoutLog.fromJson(workoutLogResponse);

      // Get workout set logs
      final setLogsResponse = await _supabaseService.client
          .from(AppConstants.workoutSetLogsTable)
          .select('''
            *,
            exercises(name, primary_muscle, secondary_muscle)
          ''')
          .eq('workout_log_id', workoutLogId)
          .order('completed_at');

      final setLogs = (setLogsResponse as List)
          .map((json) => WorkoutSetLog.fromJson(json))
          .toList();

      // Calculate analysis
      final totalVolume = setLogs.fold(0.0, (sum, set) => sum + set.volume);
      final totalSets = setLogs.length;
      final totalReps = setLogs.fold(0, (sum, set) => sum + set.repsCompleted);
      final uniqueExercises = setLogs.map((set) => set.exerciseId).toSet().length;

      // Group by exercise
      final exerciseBreakdown = <String, Map<String, dynamic>>{};
      for (final setLog in setLogs) {
        final exerciseId = setLog.exerciseId;
        if (!exerciseBreakdown.containsKey(exerciseId)) {
          exerciseBreakdown[exerciseId] = {
            'exercise_name': 'Exercise $exerciseId', // Would get from joined data
            'sets': <WorkoutSetLog>[],
            'total_volume': 0.0,
            'total_reps': 0,
            'max_weight': 0.0,
          };
        }
        
        final exercise = exerciseBreakdown[exerciseId]!;
        (exercise['sets'] as List<WorkoutSetLog>).add(setLog);
        exercise['total_volume'] = (exercise['total_volume'] as double) + setLog.volume;
        exercise['total_reps'] = (exercise['total_reps'] as int) + setLog.repsCompleted;
        exercise['max_weight'] = [exercise['max_weight'] as double, setLog.weight ?? 0.0]
            .reduce((a, b) => a > b ? a : b);
      }

      return {
        'workout_log': workoutLog,
        'set_logs': setLogs,
        'summary': {
          'total_volume': totalVolume,
          'total_sets': totalSets,
          'total_reps': totalReps,
          'unique_exercises': uniqueExercises,
          'duration_minutes': workoutLog.durationSeconds != null 
              ? (workoutLog.durationSeconds! / 60).round()
              : 0,
        },
        'exercise_breakdown': exerciseBreakdown,
      };
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to get workout analysis',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

/// Helper class for volume data processing
class VolumeDataPoint {
  final DateTime date;
  final double volume;
  final String exerciseId;

  VolumeDataPoint({
    required this.date,
    required this.volume,
    required this.exerciseId,
  });
}
  
// Helper methods for calculations and data processing

  /// Calculate BMI from weight and height
  double _calculateBMI(double weight, double height, String weightUnit, String heightUnit) {
    // Convert to metric if needed
    double weightKg = weightUnit == 'lbs' ? weight * 0.453592 : weight;
    double heightM = heightUnit == 'ft' ? height * 0.3048 : height / 100; // Assuming cm to m conversion
    
    return weightKg / (heightM * heightM);
  }

  /// Get the start of the week for a given date
  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
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

  /// Calculate volume for a specific time period
  double _calculateVolumeForPeriod(List<WorkoutSetLog> workoutSetLogs, DateTime start, DateTime end) {
    return workoutSetLogs
        .where((log) => log.completedAt.isAfter(start) && log.completedAt.isBefore(end))
        .fold(0.0, (sum, log) => sum + log.volume);
  }

  /// Generate volume trend data points
  List<TrendDataPoint> _generateVolumeTrendData(List<WorkoutSetLog> workoutSetLogs, int weeks) {
    final now = DateTime.now();
    final trendData = <TrendDataPoint>[];

    for (int i = weeks - 1; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: (i + 1) * 7));
      final weekEnd = now.subtract(Duration(days: i * 7));
      
      final weekVolume = _calculateVolumeForPeriod(workoutSetLogs, weekStart, weekEnd);
      
      trendData.add(TrendDataPoint(
        date: weekStart,
        value: weekVolume,
      ));
    }

    return trendData;
  }

  /// Generate frequency trend data points
  List<TrendDataPoint> _generateFrequencyTrendData(List<WorkoutLog> workoutLogs, int weeks) {
    final now = DateTime.now();
    final trendData = <TrendDataPoint>[];

    for (int i = weeks - 1; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: (i + 1) * 7));
      final weekEnd = now.subtract(Duration(days: i * 7));
      
      final weekWorkouts = workoutLogs
          .where((log) => log.isCompleted)
          .where((log) {
            final date = log.completedAt ?? log.createdAt;
            return date.isAfter(weekStart) && date.isBefore(weekEnd);
          })
          .length
          .toDouble();
      
      trendData.add(TrendDataPoint(
        date: weekStart,
        value: weekWorkouts,
      ));
    }

    return trendData;
  }

  /// Calculate workout streaks
  Map<String, int> _calculateWorkoutStreaks(List<WorkoutLog> completedWorkouts) {
    if (completedWorkouts.isEmpty) {
      return {'current': 0, 'longest': 0};
    }

    // Sort by date
    final sortedWorkouts = completedWorkouts.toList()
      ..sort((a, b) => (a.completedAt ?? a.createdAt).compareTo(b.completedAt ?? b.createdAt));

    // Group by date
    final workoutDates = <DateTime>{};
    for (final workout in sortedWorkouts) {
      final date = workout.completedAt ?? workout.createdAt;
      workoutDates.add(DateTime(date.year, date.month, date.day));
    }

    final sortedDates = workoutDates.toList()..sort();

    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 1;

    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    // Calculate current streak
    if (sortedDates.isNotEmpty) {
      final lastWorkoutDate = sortedDates.last;
      final todayDate = DateTime(today.year, today.month, today.day);
      final yesterdayDate = DateTime(yesterday.year, yesterday.month, yesterday.day);

      if (lastWorkoutDate.isAtSameMomentAs(todayDate) || lastWorkoutDate.isAtSameMomentAs(yesterdayDate)) {
        currentStreak = 1;
        
        // Count backwards
        for (int i = sortedDates.length - 2; i >= 0; i--) {
          final currentDate = sortedDates[i];
          final nextDate = sortedDates[i + 1];
          
          if (nextDate.difference(currentDate).inDays == 1) {
            currentStreak++;
          } else {
            break;
          }
        }
      }
    }

    // Calculate longest streak
    for (int i = 1; i < sortedDates.length; i++) {
      if (sortedDates[i].difference(sortedDates[i - 1]).inDays == 1) {
        tempStreak++;
      } else {
        longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;
        tempStreak = 1;
      }
    }
    longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;

    return {'current': currentStreak, 'longest': longestStreak};
  }

  /// Calculate consistency score based on workout patterns
  double _calculateConsistencyScore(List<WorkoutLog> completedWorkouts) {
    if (completedWorkouts.isEmpty) return 0.0;

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    final recentWorkouts = completedWorkouts
        .where((log) => (log.completedAt ?? log.createdAt).isAfter(thirtyDaysAgo))
        .toList();

    if (recentWorkouts.isEmpty) return 0.0;

    // Calculate expected workouts (assuming 3-4 per week)
    const expectedWorkoutsPerWeek = 3.5;
    final expectedWorkouts = (30 / 7) * expectedWorkoutsPerWeek;
    
    final actualWorkouts = recentWorkouts.length;
    final consistencyScore = (actualWorkouts / expectedWorkouts).clamp(0.0, 1.0);

    return consistencyScore;
  }

  /// Generate daily workout counts for a given period
  List<DailyWorkoutCount> _generateDailyWorkoutCounts(List<WorkoutLog> completedWorkouts, int days) {
    final now = DateTime.now();
    final dailyCounts = <DailyWorkoutCount>[];

    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateOnly = DateTime(date.year, date.month, date.day);
      
      final count = completedWorkouts
          .where((log) {
            final workoutDate = log.completedAt ?? log.createdAt;
            final workoutDateOnly = DateTime(workoutDate.year, workoutDate.month, workoutDate.day);
            return workoutDateOnly.isAtSameMomentAs(dateOnly);
          })
          .length;

      dailyCounts.add(DailyWorkoutCount(
        date: dateOnly,
        count: count,
      ));
    }

    return dailyCounts;
  }

  /// Generate weekly volume data
  List<WeeklyVolumeData> _generateWeeklyVolumeData(List<VolumeDataPoint> volumeData, int weeks) {
    final now = DateTime.now();
    final weeklyData = <WeeklyVolumeData>[];

    for (int i = weeks - 1; i >= 0; i--) {
      final weekStart = _getWeekStart(now.subtract(Duration(days: i * 7)));
      final weekEnd = weekStart.add(const Duration(days: 7));
      
      final weekVolume = volumeData
          .where((point) => point.date.isAfter(weekStart) && point.date.isBefore(weekEnd))
          .fold(0.0, (sum, point) => sum + point.volume);

      weeklyData.add(WeeklyVolumeData(
        weekStart: weekStart,
        volume: weekVolume,
      ));
    }

    return weeklyData;
  }

  /// Generate exercise volume data
  Future<List<ExerciseVolumeData>> _generateExerciseVolumeData(List<VolumeDataPoint> volumeData) async {
    final exerciseVolumes = <String, double>{};
    final exerciseSets = <String, int>{};

    for (final point in volumeData) {
      exerciseVolumes[point.exerciseId] = (exerciseVolumes[point.exerciseId] ?? 0) + point.volume;
      exerciseSets[point.exerciseId] = (exerciseSets[point.exerciseId] ?? 0) + 1;
    }

    final exerciseVolumeData = <ExerciseVolumeData>[];
    for (final exerciseId in exerciseVolumes.keys) {
      // In a real implementation, you'd fetch the exercise name from the database
      exerciseVolumeData.add(ExerciseVolumeData(
        exerciseId: exerciseId,
        exerciseName: 'Exercise $exerciseId', // Placeholder
        totalVolume: exerciseVolumes[exerciseId]!,
        totalSets: exerciseSets[exerciseId]!,
      ));
    }

    // Sort by total volume (descending)
    exerciseVolumeData.sort((a, b) => b.totalVolume.compareTo(a.totalVolume));

    return exerciseVolumeData;
  }

  /// Generate exercise progress data
  Future<List<ExerciseProgressData>> _generateExerciseProgressData(List<CompletedSet> completedSets) async {
    final exerciseGroups = <String, List<CompletedSet>>{};
    
    for (final set in completedSets) {
      if (set.workoutExerciseId != null) {
        exerciseGroups.putIfAbsent(set.workoutExerciseId!, () => []).add(set);
      }
    }

    final exerciseProgressList = <ExerciseProgressData>[];
    for (final entry in exerciseGroups.entries) {
      final exerciseId = entry.key;
      final sets = entry.value;
      
      if (sets.isEmpty) continue;

      final maxWeight = sets.where((set) => set.hasWeight).isNotEmpty
          ? sets.where((set) => set.hasWeight).map((set) => set.performedWeight!.toDouble()).reduce((a, b) => a > b ? a : b)
          : 0.0;
      final maxReps = sets.where((set) => set.performedReps != null).isNotEmpty
          ? sets.where((set) => set.performedReps != null).map((set) => set.performedReps!).reduce((a, b) => a > b ? a : b)
          : 0;
      final totalVolume = sets.fold(0.0, (sum, set) => sum + set.volume);
      final totalSets = sets.length;

      final progressHistory = sets.map((set) => ProgressDataPoint(
        date: set.createdAt,
        weight: set.hasWeight ? set.performedWeight!.toDouble() : 0,
        reps: set.performedReps ?? 0,
        volume: set.volume,
      )).toList()..sort((a, b) => a.date.compareTo(b.date));

      exerciseProgressList.add(ExerciseProgressData(
        exerciseId: exerciseId,
        exerciseName: 'Exercise $exerciseId', // Placeholder
        maxWeight: maxWeight,
        maxReps: maxReps,
        totalVolume: totalVolume,
        totalSets: totalSets,
        progressHistory: progressHistory,
      ));
    }

    return exerciseProgressList;
  }

  /// Process a set for personal record detection
  Future<void> _processSetForPersonalRecords(
    Map<String, Map<PersonalRecordType, PersonalRecord>> exerciseRecords,
    String exerciseId,
    double weight,
    int reps,
    double volume,
    DateTime achievedAt,
    String workoutLogId,
  ) async {
    exerciseRecords.putIfAbsent(exerciseId, () => {});
    final records = exerciseRecords[exerciseId]!;

    // Check max weight PR
    if (weight > 0) {
      final currentMaxWeight = records[PersonalRecordType.maxWeight];
      if (currentMaxWeight == null || weight > currentMaxWeight.value) {
        records[PersonalRecordType.maxWeight] = PersonalRecord(
          exerciseId: exerciseId,
          exerciseName: 'Exercise $exerciseId', // Placeholder
          type: PersonalRecordType.maxWeight,
          value: weight,
          achievedAt: achievedAt,
          workoutLogId: workoutLogId,
        );
      }
    }

    // Check max reps PR
    if (reps > 0) {
      final currentMaxReps = records[PersonalRecordType.maxReps];
      if (currentMaxReps == null || reps > currentMaxReps.value) {
        records[PersonalRecordType.maxReps] = PersonalRecord(
          exerciseId: exerciseId,
          exerciseName: 'Exercise $exerciseId', // Placeholder
          type: PersonalRecordType.maxReps,
          value: reps.toDouble(),
          achievedAt: achievedAt,
          workoutLogId: workoutLogId,
        );
      }
    }

    // Check max volume PR
    if (volume > 0) {
      final currentMaxVolume = records[PersonalRecordType.maxVolume];
      if (currentMaxVolume == null || volume > currentMaxVolume.value) {
        records[PersonalRecordType.maxVolume] = PersonalRecord(
          exerciseId: exerciseId,
          exerciseName: 'Exercise $exerciseId', // Placeholder
          type: PersonalRecordType.maxVolume,
          value: volume,
          achievedAt: achievedAt,
          workoutLogId: workoutLogId,
        );
      }
    }
  }
}

/// Helper class for volume data points
class VolumeDataPoint {
  final DateTime date;
  final double volume;
  final String exerciseId;

  VolumeDataPoint({
    required this.date,
    required this.volume,
    required this.exerciseId,
  });
}}
