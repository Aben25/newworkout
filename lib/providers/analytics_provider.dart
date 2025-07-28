import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/services.dart';

part 'analytics_provider.g.dart';

/// Provider for analytics service
@riverpod
AnalyticsService analyticsService(Ref ref) {
  return AnalyticsService.instance;
}

/// Provider for analytics data
@riverpod
class AnalyticsNotifier extends _$AnalyticsNotifier {
  @override
  Future<AnalyticsData?> build() async {
    return null;
  }

  /// Load analytics data for the current user
  Future<void> loadAnalytics({String? userId}) async {
    state = const AsyncValue.loading();
    
    try {
      final analyticsService = ref.read(analyticsServiceProvider);
      final analyticsData = await analyticsService.getAnalyticsData(userId: userId);
      state = AsyncValue.data(analyticsData);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Refresh analytics data
  Future<void> refreshAnalytics({String? userId}) async {
    state = const AsyncValue.loading();
    
    try {
      final analyticsService = ref.read(analyticsServiceProvider);
      final analyticsData = await analyticsService.refreshAnalytics(userId: userId);
      state = AsyncValue.data(analyticsData);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Clear analytics cache
  Future<void> clearCache({String? userId}) async {
    try {
      final analyticsService = ref.read(analyticsServiceProvider);
      await analyticsService.clearAnalyticsCache(userId: userId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Provider for workout frequency analytics
@riverpod
WorkoutFrequencyAnalytics? workoutFrequencyAnalytics(Ref ref) {
  final analyticsData = ref.watch(analyticsNotifierProvider).value;
  return analyticsData?.workoutFrequency;
}

/// Provider for volume analytics
@riverpod
VolumeAnalytics? volumeAnalytics(Ref ref) {
  final analyticsData = ref.watch(analyticsNotifierProvider).value;
  return analyticsData?.volume;
}

/// Provider for progress analytics
@riverpod
ProgressAnalytics? progressAnalytics(Ref ref) {
  final analyticsData = ref.watch(analyticsNotifierProvider).value;
  return analyticsData?.progress;
}

/// Provider for personal records
@riverpod
List<PersonalRecord> personalRecords(Ref ref) {
  final analyticsData = ref.watch(analyticsNotifierProvider).value;
  return analyticsData?.personalRecords ?? [];
}

/// Provider for milestones
@riverpod
List<Milestone> milestones(Ref ref) {
  final analyticsData = ref.watch(analyticsNotifierProvider).value;
  return analyticsData?.milestones ?? [];
}

/// Provider for trend analytics
@riverpod
TrendAnalytics? trendAnalytics(Ref ref) {
  final analyticsData = ref.watch(analyticsNotifierProvider).value;
  return analyticsData?.trends;
}

/// Provider for recent personal records (last 30 days)
@riverpod
List<PersonalRecord> recentPersonalRecords(Ref ref) {
  final personalRecords = ref.watch(personalRecordsProvider);
  final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
  
  return personalRecords
      .where((pr) => pr.achievedAt.isAfter(thirtyDaysAgo))
      .toList();
}

/// Provider for recent milestones (last 30 days)
@riverpod
List<Milestone> recentMilestones(Ref ref) {
  final milestones = ref.watch(milestonesProvider);
  final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
  
  return milestones
      .where((milestone) => milestone.achievedAt.isAfter(thirtyDaysAgo))
      .toList();
}

/// Provider for analytics loading state
@riverpod
bool isAnalyticsLoading(Ref ref) {
  return ref.watch(analyticsNotifierProvider).isLoading;
}

/// Provider for analytics error state
@riverpod
Object? analyticsError(Ref ref) {
  final asyncValue = ref.watch(analyticsNotifierProvider);
  return asyncValue.hasError ? asyncValue.error : null;
}

/// Provider for analytics data freshness
@riverpod
bool isAnalyticsStale(Ref ref) {
  final analyticsData = ref.watch(analyticsNotifierProvider).value;
  return analyticsData?.isStale ?? true;
}

/// Provider for key performance indicators
@riverpod
Map<String, dynamic> keyPerformanceIndicators(Ref ref) {
  final workoutFrequency = ref.watch(workoutFrequencyAnalyticsProvider);
  final volume = ref.watch(volumeAnalyticsProvider);
  final progress = ref.watch(progressAnalyticsProvider);
  final personalRecords = ref.watch(personalRecordsProvider);
  final milestones = ref.watch(milestonesProvider);

  return {
    'total_workouts': workoutFrequency?.totalWorkouts ?? 0,
    'current_streak': workoutFrequency?.currentStreak ?? 0,
    'total_volume': volume?.totalVolumeLifetime ?? 0.0,
    'average_rating': progress?.averageWorkoutRating ?? 0.0,
    'personal_records': personalRecords.length,
    'milestones_achieved': milestones.length,
    'consistency_score': workoutFrequency?.consistencyScore ?? 0.0,
    'workouts_this_week': workoutFrequency?.workoutsThisWeek ?? 0,
    'volume_this_week': volume?.totalVolumeThisWeek ?? 0.0,
  };
}

/// Provider for workout consistency metrics
@riverpod
Map<String, dynamic> consistencyMetrics(Ref ref) {
  final workoutFrequency = ref.watch(workoutFrequencyAnalyticsProvider);
  
  if (workoutFrequency == null) {
    return {
      'consistency_score': 0.0,
      'current_streak': 0,
      'longest_streak': 0,
      'average_per_week': 0.0,
      'status': 'No data available',
    };
  }

  String getConsistencyStatus(double score) {
    if (score >= 0.8) return 'Excellent';
    if (score >= 0.6) return 'Good';
    if (score >= 0.4) return 'Fair';
    if (score >= 0.2) return 'Needs Improvement';
    return 'Poor';
  }

  return {
    'consistency_score': workoutFrequency.consistencyScore,
    'current_streak': workoutFrequency.currentStreak,
    'longest_streak': workoutFrequency.longestStreak,
    'average_per_week': workoutFrequency.averageWorkoutsPerWeek,
    'status': getConsistencyStatus(workoutFrequency.consistencyScore),
  };
}

/// Provider for strength progression metrics
@riverpod
Map<String, dynamic> strengthProgressionMetrics(Ref ref) {
  final progress = ref.watch(progressAnalyticsProvider);
  final trends = ref.watch(trendAnalyticsProvider);
  
  if (progress == null || trends == null) {
    return {
      'total_volume': 0.0,
      'volume_trend': 0.0,
      'total_sets': 0,
      'total_reps': 0,
      'trend_direction': 'stable',
    };
  }

  String getTrendDirection(double trend) {
    if (trend > 0.05) return 'increasing';
    if (trend < -0.05) return 'decreasing';
    return 'stable';
  }

  return {
    'total_volume': progress.totalSets * 100, // Approximate volume calculation
    'volume_trend': trends.volumeTrend,
    'total_sets': progress.totalSets,
    'total_reps': progress.totalReps,
    'trend_direction': getTrendDirection(trends.volumeTrend),
  };
}

/// Provider for achievement summary
@riverpod
Map<String, dynamic> achievementSummary(Ref ref) {
  final personalRecords = ref.watch(personalRecordsProvider);
  final milestones = ref.watch(milestonesProvider);
  final recentPRs = ref.watch(recentPersonalRecordsProvider);
  final recentMilestones = ref.watch(recentMilestonesProvider);

  // Group personal records by type
  final prsByType = <PersonalRecordType, int>{};
  for (final pr in personalRecords) {
    prsByType[pr.type] = (prsByType[pr.type] ?? 0) + 1;
  }

  // Group milestones by type
  final milestonesByType = <MilestoneType, int>{};
  for (final milestone in milestones) {
    milestonesByType[milestone.type] = (milestonesByType[milestone.type] ?? 0) + 1;
  }

  return {
    'total_personal_records': personalRecords.length,
    'total_milestones': milestones.length,
    'recent_personal_records': recentPRs.length,
    'recent_milestones': recentMilestones.length,
    'personal_records_by_type': prsByType.map((key, value) => MapEntry(key.toString(), value)),
    'milestones_by_type': milestonesByType.map((key, value) => MapEntry(key.toString(), value)),
    'has_recent_achievements': recentPRs.isNotEmpty || recentMilestones.isNotEmpty,
  };
}

/// Filter parameters for workout logs
class WorkoutLogFilters {
  final DateTimeRange? dateFilter;
  final String? statusFilter;
  final int? ratingFilter;
  final String? exerciseFilter;
  final String? userId;

  const WorkoutLogFilters({
    this.dateFilter,
    this.statusFilter,
    this.ratingFilter,
    this.exerciseFilter,
    this.userId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutLogFilters &&
          runtimeType == other.runtimeType &&
          dateFilter == other.dateFilter &&
          statusFilter == other.statusFilter &&
          ratingFilter == other.ratingFilter &&
          exerciseFilter == other.exerciseFilter &&
          userId == other.userId;

  @override
  int get hashCode =>
      dateFilter.hashCode ^
      statusFilter.hashCode ^
      ratingFilter.hashCode ^
      exerciseFilter.hashCode ^
      userId.hashCode;
}

/// Provider for filtered workout logs
@riverpod
Future<List<WorkoutLog>> filteredWorkoutLogs(Ref ref, WorkoutLogFilters filters) async {
  final analyticsService = ref.watch(analyticsServiceProvider);
  
  return await analyticsService.getFilteredWorkoutLogs(
    userId: filters.userId,
    dateFilter: filters.dateFilter,
    statusFilter: filters.statusFilter,
    ratingFilter: filters.ratingFilter,
    exerciseFilter: filters.exerciseFilter,
  );
}

/// Provider for workout analysis
@riverpod
Future<Map<String, dynamic>> workoutAnalysis(Ref ref, String workoutLogId) async {
  final analyticsService = ref.watch(analyticsServiceProvider);
  return await analyticsService.getWorkoutAnalysis(workoutLogId);
}