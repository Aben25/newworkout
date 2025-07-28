import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../models/models.dart';
import '../constants/app_constants.dart';
import 'supabase_service.dart';
import 'offline_cache_service.dart';

/// Comprehensive set logging service for dual logging system
/// Implements completed_sets for detailed tracking and workout_set_logs for historical analysis
/// Provides performance comparison, progression tracking, and adaptive programming features
class SetLoggingService {
  static SetLoggingService? _instance;
  static SetLoggingService get instance => _instance ??= SetLoggingService._();
  
  SetLoggingService._();
  
  final Logger _logger = Logger();
  final SupabaseService _supabaseService = SupabaseService.instance;
  final OfflineCacheService _cacheService = OfflineCacheService.instance;

  /// Log completed set with dual logging system
  /// Stores in both completed_sets for detailed tracking and prepares for workout_set_logs
  Future<CompletedSet> logCompletedSet({
    required String workoutId,
    required String workoutExerciseId,
    required int performedSetOrder,
    required int performedReps,
    required int performedWeight,
    String? setFeedbackDifficulty,
    String? notes,
  }) async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();
      
      // Create completed set data for detailed tracking
      final completedSetData = {
        'workout_id': workoutId,
        'workout_exercise_id': workoutExerciseId,
        'performed_set_order': performedSetOrder,
        'performed_reps': performedReps,
        'performed_weight': performedWeight,
        'set_feedback_difficulty': setFeedbackDifficulty,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      // Insert into completed_sets table
      final response = await _supabaseService.client
          .from(AppConstants.completedSetsTable)
          .insert(completedSetData)
          .select()
          .single();

      final completedSet = CompletedSet.fromJson(response);

      // Cache for offline access
      await _cacheService.cacheCompletedSet(completedSet);

      // Update workout exercise with progression tracking
      await _updateWorkoutExerciseProgression(
        workoutExerciseId,
        performedReps,
        performedWeight,
        performedSetOrder,
      );

      _logger.i('Logged completed set: $performedReps reps @ ${performedWeight}kg');
      return completedSet;
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to log completed set',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Create workout set logs for historical analysis
  /// Called when workout is completed to create historical records
  Future<void> createWorkoutSetLogs({
    required String workoutLogId,
    required List<CompletedSetLog> completedSets,
  }) async {
    try {
      if (completedSets.isEmpty) return;

      final workoutSetLogsData = completedSets.map((setLog) => {
        'workout_log_id': workoutLogId,
        'exercise_id': setLog.exerciseId,
        'set_number': setLog.setNumber,
        'reps_completed': setLog.reps,
        'weight': setLog.weight,
        'completed_at': setLog.timestamp.toIso8601String(),
        'created_at': setLog.timestamp.toIso8601String(),
      }).toList();

      await _supabaseService.client
          .from(AppConstants.workoutSetLogsTable)
          .insert(workoutSetLogsData);

      _logger.i('Created ${workoutSetLogsData.length} workout set logs for historical analysis');
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to create workout set logs',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Update workout exercise with progression tracking using reps_old arrays
  Future<void> _updateWorkoutExerciseProgression(
    String workoutExerciseId,
    int performedReps,
    int performedWeight,
    int setOrder,
  ) async {
    try {
      // Get current workout exercise data
      final response = await _supabaseService.client
          .from(AppConstants.workoutExercisesTable)
          .select('reps, weight, reps_old')
          .eq('id', workoutExerciseId)
          .single();

      final currentReps = List<int>.from(response['reps'] ?? []);
      final currentWeight = List<int>.from(response['weight'] ?? []);
      final repsOld = List<int>.from(response['reps_old'] ?? []);

      // Store current reps in reps_old for progression tracking
      final updatedRepsOld = List<int>.from(repsOld);
      if (setOrder <= currentReps.length) {
        // Ensure reps_old has enough elements
        while (updatedRepsOld.length < setOrder) {
          updatedRepsOld.add(0);
        }
        updatedRepsOld[setOrder - 1] = currentReps.length >= setOrder 
            ? currentReps[setOrder - 1] 
            : 0;
      }

      // Update current performance
      final updatedReps = List<int>.from(currentReps);
      final updatedWeight = List<int>.from(currentWeight);

      // Ensure arrays have enough elements
      while (updatedReps.length < setOrder) {
        updatedReps.add(0);
      }
      while (updatedWeight.length < setOrder) {
        updatedWeight.add(0);
      }

      updatedReps[setOrder - 1] = performedReps;
      updatedWeight[setOrder - 1] = performedWeight;

      // Update workout exercise with progression data
      await _supabaseService.client
          .from(AppConstants.workoutExercisesTable)
          .update({
            'reps': updatedReps,
            'weight': updatedWeight,
            'reps_old': updatedRepsOld,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', workoutExerciseId);

      _logger.d('Updated workout exercise progression for set $setOrder');
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to update workout exercise progression',
        error: e,
        stackTrace: stackTrace,
      );
      // Don't rethrow as this is not critical for set logging
    }
  }

  /// Get performance comparison data using reps_old arrays
  Future<PerformanceComparison> getPerformanceComparison(
    String workoutExerciseId,
  ) async {
    try {
      final response = await _supabaseService.client
          .from(AppConstants.workoutExercisesTable)
          .select('reps, weight, reps_old')
          .eq('id', workoutExerciseId)
          .single();

      final currentReps = List<int>.from(response['reps'] ?? []);
      final currentWeight = List<int>.from(response['weight'] ?? []);
      final previousReps = List<int>.from(response['reps_old'] ?? []);

      return PerformanceComparison(
        currentReps: currentReps,
        currentWeight: currentWeight,
        previousReps: previousReps,
        improvementPercentage: _calculateImprovementPercentage(
          currentReps,
          currentWeight,
          previousReps,
        ),
      );
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to get performance comparison',
        error: e,
        stackTrace: stackTrace,
      );
      
      // Return empty comparison on error
      return const PerformanceComparison(
        currentReps: [],
        currentWeight: [],
        previousReps: [],
        improvementPercentage: 0.0,
      );
    }
  }

  /// Calculate improvement percentage based on volume progression
  double _calculateImprovementPercentage(
    List<int> currentReps,
    List<int> currentWeight,
    List<int> previousReps,
  ) {
    if (currentReps.isEmpty || currentWeight.isEmpty || previousReps.isEmpty) {
      return 0.0;
    }

    // Calculate current total volume
    double currentVolume = 0.0;
    for (int i = 0; i < currentReps.length && i < currentWeight.length; i++) {
      currentVolume += currentReps[i] * currentWeight[i];
    }

    // Calculate previous total volume (assuming same weight pattern)
    double previousVolume = 0.0;
    for (int i = 0; i < previousReps.length && i < currentWeight.length; i++) {
      previousVolume += previousReps[i] * currentWeight[i];
    }

    if (previousVolume == 0) return 0.0;

    return ((currentVolume - previousVolume) / previousVolume * 100);
  }

  /// Get weight progression suggestions using historical data
  Future<WeightProgressionSuggestion> getWeightProgressionSuggestion({
    required String exerciseId,
    required String userId,
    required int currentWeight,
    required List<String> recentDifficultyRatings,
  }) async {
    try {
      // Get historical performance data
      final historicalData = await _getHistoricalPerformanceData(exerciseId, userId);
      
      // Analyze difficulty ratings
      final averageDifficulty = _calculateAverageDifficulty(recentDifficultyRatings);
      
      // Calculate progression suggestion
      final suggestion = _calculateWeightProgression(
        currentWeight,
        averageDifficulty,
        historicalData,
      );

      return suggestion;
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to get weight progression suggestion',
        error: e,
        stackTrace: stackTrace,
      );
      
      // Return conservative suggestion on error
      return WeightProgressionSuggestion(
        suggestedWeight: currentWeight,
        progressionType: ProgressionType.maintain,
        confidence: 0.0,
        reasoning: 'Unable to analyze progression data',
      );
    }
  }

  /// Get historical performance data for progression analysis
  Future<List<HistoricalPerformanceData>> _getHistoricalPerformanceData(
    String exerciseId,
    String userId,
  ) async {
    try {
      // Query workout_set_logs for historical data
      final response = await _supabaseService.client
          .from(AppConstants.workoutSetLogsTable)
          .select('''
            reps_completed,
            weight,
            completed_at,
            workout_log_id,
            workout_logs!inner(user_id)
          ''')
          .eq('exercise_id', exerciseId)
          .eq('workout_logs.user_id', userId)
          .order('completed_at', ascending: false)
          .limit(50); // Last 50 sets for analysis

      return (response as List).map((data) => HistoricalPerformanceData(
        reps: data['reps_completed'] ?? 0,
        weight: (data['weight'] ?? 0).toDouble(),
        completedAt: DateTime.parse(data['completed_at']),
      )).toList();
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to get historical performance data',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Calculate average difficulty from recent ratings
  double _calculateAverageDifficulty(List<String> difficultyRatings) {
    if (difficultyRatings.isEmpty) return 3.0; // Default to moderate

    final numericRatings = difficultyRatings
        .map((rating) => _difficultyToNumeric(rating))
        .where((rating) => rating != null)
        .cast<double>()
        .toList();

    if (numericRatings.isEmpty) return 3.0;

    return numericRatings.reduce((a, b) => a + b) / numericRatings.length;
  }

  /// Convert difficulty rating to numeric value
  double? _difficultyToNumeric(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'very_easy':
        return 1.0;
      case 'easy':
        return 2.0;
      case 'moderate':
        return 3.0;
      case 'hard':
        return 4.0;
      case 'very_hard':
        return 5.0;
      default:
        return double.tryParse(difficulty);
    }
  }

  /// Calculate weight progression based on difficulty and historical data
  WeightProgressionSuggestion _calculateWeightProgression(
    int currentWeight,
    double averageDifficulty,
    List<HistoricalPerformanceData> historicalData,
  ) {
    // Analyze recent trend
    final recentTrend = _analyzeRecentTrend(historicalData);
    
    // Base progression on difficulty
    ProgressionType progressionType;
    double weightChange = 0.0;
    double confidence = 0.8;
    String reasoning = '';

    if (averageDifficulty <= 2.0) {
      // Too easy - increase weight
      progressionType = ProgressionType.increase;
      weightChange = _calculateWeightIncrease(currentWeight, recentTrend);
      reasoning = 'Recent sets rated as easy - time to progress';
    } else if (averageDifficulty >= 4.0) {
      // Too hard - decrease weight
      progressionType = ProgressionType.decrease;
      weightChange = _calculateWeightDecrease(currentWeight, recentTrend);
      reasoning = 'Recent sets rated as hard - consider reducing weight';
    } else {
      // Moderate difficulty - maintain or slight increase
      if (recentTrend == TrendDirection.improving) {
        progressionType = ProgressionType.increase;
        weightChange = _calculateConservativeIncrease(currentWeight);
        reasoning = 'Consistent performance - ready for small increase';
      } else {
        progressionType = ProgressionType.maintain;
        reasoning = 'Current weight is appropriate';
      }
    }

    final suggestedWeight = (currentWeight + weightChange).round().clamp(0, 999);

    return WeightProgressionSuggestion(
      suggestedWeight: suggestedWeight,
      progressionType: progressionType,
      confidence: confidence,
      reasoning: reasoning,
    );
  }

  /// Analyze recent performance trend
  TrendDirection _analyzeRecentTrend(List<HistoricalPerformanceData> data) {
    if (data.length < 3) return TrendDirection.stable;

    // Calculate volume trend over last few sessions
    final recentSessions = data.take(6).toList();
    double totalVolumeChange = 0.0;
    int comparisons = 0;

    for (int i = 0; i < recentSessions.length - 1; i++) {
      final current = recentSessions[i];
      final previous = recentSessions[i + 1];
      
      final currentVolume = current.reps * current.weight;
      final previousVolume = previous.reps * previous.weight;
      
      if (previousVolume > 0) {
        totalVolumeChange += (currentVolume - previousVolume) / previousVolume;
        comparisons++;
      }
    }

    if (comparisons == 0) return TrendDirection.stable;

    final averageChange = totalVolumeChange / comparisons;

    if (averageChange > 0.05) return TrendDirection.improving;
    if (averageChange < -0.05) return TrendDirection.declining;
    return TrendDirection.stable;
  }

  /// Calculate weight increase amount
  double _calculateWeightIncrease(int currentWeight, TrendDirection trend) {
    double baseIncrease = currentWeight * 0.025; // 2.5% increase
    
    // Adjust based on trend
    switch (trend) {
      case TrendDirection.improving:
        baseIncrease *= 1.2; // Slightly more aggressive
        break;
      case TrendDirection.declining:
        baseIncrease *= 0.8; // More conservative
        break;
      case TrendDirection.stable:
        break; // Use base increase
    }

    // Round to nearest 2.5kg for practical loading
    return (baseIncrease / 2.5).round() * 2.5;
  }

  /// Calculate weight decrease amount
  double _calculateWeightDecrease(int currentWeight, TrendDirection trend) {
    double baseDecrease = currentWeight * 0.05; // 5% decrease
    
    // Adjust based on trend
    switch (trend) {
      case TrendDirection.declining:
        baseDecrease *= 1.3; // More significant decrease
        break;
      case TrendDirection.improving:
        baseDecrease *= 0.7; // Less decrease
        break;
      case TrendDirection.stable:
        break; // Use base decrease
    }

    // Round to nearest 2.5kg
    return -((baseDecrease / 2.5).round() * 2.5);
  }

  /// Calculate conservative weight increase
  double _calculateConservativeIncrease(int currentWeight) {
    // Very small increase for moderate difficulty
    double increase = currentWeight * 0.0125; // 1.25% increase
    return (increase / 2.5).round() * 2.5;
  }

  /// Get rest period analysis for optimization
  Future<RestPeriodAnalysis> getRestPeriodAnalysis({
    required String exerciseId,
    required String userId,
  }) async {
    try {
      // Get recent completed sets with timestamps
      final response = await _supabaseService.client
          .from(AppConstants.completedSetsTable)
          .select('''
            performed_reps,
            performed_weight,
            set_feedback_difficulty,
            created_at,
            workout_exercise_id,
            workout_exercises!inner(exercise_id),
            workouts!inner(user_id)
          ''')
          .eq('workout_exercises.exercise_id', exerciseId)
          .eq('workouts.user_id', userId)
          .order('created_at', ascending: false)
          .limit(30);

      final sets = response as List;
      if (sets.length < 2) {
        return const RestPeriodAnalysis(
          averageRestTime: 60,
          optimalRestTime: 60,
          restTimeVariability: 0.0,
          recommendations: ['Insufficient data for analysis'],
        );
      }

      // Calculate rest periods between sets
      final restPeriods = <int>[];
      for (int i = 0; i < sets.length - 1; i++) {
        final current = DateTime.parse(sets[i]['created_at']);
        final previous = DateTime.parse(sets[i + 1]['created_at']);
        final restTime = current.difference(previous).inSeconds;
        
        // Only consider reasonable rest times (30 seconds to 10 minutes)
        if (restTime >= 30 && restTime <= 600) {
          restPeriods.add(restTime);
        }
      }

      if (restPeriods.isEmpty) {
        return const RestPeriodAnalysis(
          averageRestTime: 60,
          optimalRestTime: 60,
          restTimeVariability: 0.0,
          recommendations: ['Unable to analyze rest periods'],
        );
      }

      // Calculate statistics
      final averageRest = restPeriods.reduce((a, b) => a + b) / restPeriods.length;
      final variance = _calculateVariance(restPeriods, averageRest);
      final standardDeviation = math.sqrt(variance);
      
      // Analyze performance correlation with rest time
      final optimalRest = _findOptimalRestTime(sets, restPeriods);
      
      // Generate recommendations
      final recommendations = _generateRestRecommendations(
        averageRest,
        optimalRest,
        standardDeviation,
      );

      return RestPeriodAnalysis(
        averageRestTime: averageRest.round(),
        optimalRestTime: optimalRest.round(),
        restTimeVariability: standardDeviation,
        recommendations: recommendations,
      );
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to get rest period analysis',
        error: e,
        stackTrace: stackTrace,
      );
      
      return const RestPeriodAnalysis(
        averageRestTime: 60,
        optimalRestTime: 60,
        restTimeVariability: 0.0,
        recommendations: ['Analysis unavailable'],
      );
    }
  }

  /// Calculate variance for rest time analysis
  double _calculateVariance(List<int> values, double mean) {
    if (values.isEmpty) return 0.0;
    
    double sumSquaredDifferences = 0.0;
    for (final value in values) {
      final difference = value - mean;
      sumSquaredDifferences += difference * difference;
    }
    
    return sumSquaredDifferences / values.length;
  }

  /// Find optimal rest time based on performance correlation
  double _findOptimalRestTime(List<dynamic> sets, List<int> restPeriods) {
    if (sets.length < 2 || restPeriods.isEmpty) return 60.0;

    // Create rest time buckets and analyze performance
    final buckets = <int, List<double>>{};
    
    for (int i = 0; i < restPeriods.length && i + 1 < sets.length; i++) {
      final restTime = restPeriods[i];
      final bucket = (restTime / 30).round() * 30; // 30-second buckets
      
      final reps = sets[i + 1]['performed_reps'] ?? 0;
      final weight = sets[i + 1]['performed_weight'] ?? 0;
      final volume = reps * weight.toDouble();
      
      buckets.putIfAbsent(bucket, () => []).add(volume);
    }

    // Find bucket with highest average performance
    double bestRest = 60.0;
    double bestPerformance = 0.0;
    
    buckets.forEach((restTime, volumes) {
      if (volumes.length >= 2) { // Need at least 2 data points
        final avgVolume = volumes.reduce((a, b) => a + b) / volumes.length;
        if (avgVolume > bestPerformance) {
          bestPerformance = avgVolume;
          bestRest = restTime.toDouble();
        }
      }
    });

    return bestRest;
  }

  /// Generate rest period recommendations
  List<String> _generateRestRecommendations(
    double averageRest,
    double optimalRest,
    double variability,
  ) {
    final recommendations = <String>[];

    // Consistency recommendations
    if (variability > 30) {
      recommendations.add('Try to be more consistent with rest times');
    }

    // Optimal rest time recommendations
    final difference = optimalRest - averageRest;
    if (difference.abs() > 15) {
      if (difference > 0) {
        recommendations.add('Consider resting ${difference.round()} seconds longer for better performance');
      } else {
        recommendations.add('You might be resting too long - try reducing by ${(-difference).round()} seconds');
      }
    }

    // General recommendations based on rest time
    if (averageRest < 45) {
      recommendations.add('Rest periods seem short - consider 60-90 seconds for strength exercises');
    } else if (averageRest > 180) {
      recommendations.add('Rest periods are quite long - try to keep under 3 minutes for efficiency');
    }

    if (recommendations.isEmpty) {
      recommendations.add('Your rest periods look good - keep it up!');
    }

    return recommendations;
  }

  /// Get set feedback difficulty statistics for adaptive programming
  Future<DifficultyAnalysis> getDifficultyAnalysis({
    required String exerciseId,
    required String userId,
    int? lastNSessions,
  }) async {
    try {
      final limit = lastNSessions != null ? lastNSessions * 10 : 50; // Estimate sets per session
      
      final response = await _supabaseService.client
          .from(AppConstants.completedSetsTable)
          .select('''
            set_feedback_difficulty,
            performed_reps,
            performed_weight,
            created_at,
            workout_exercises!inner(exercise_id),
            workouts!inner(user_id)
          ''')
          .eq('workout_exercises.exercise_id', exerciseId)
          .eq('workouts.user_id', userId)
          .not('set_feedback_difficulty', 'is', null)
          .order('created_at', ascending: false)
          .limit(limit);

      final sets = response as List;
      if (sets.isEmpty) {
        return const DifficultyAnalysis(
          averageDifficulty: 3.0,
          difficultyTrend: TrendDirection.stable,
          difficultyDistribution: {},
          recommendations: ['No difficulty ratings available'],
        );
      }

      // Calculate difficulty statistics
      final difficulties = sets
          .map((set) => _difficultyToNumeric(set['set_feedback_difficulty'] ?? ''))
          .where((d) => d != null)
          .cast<double>()
          .toList();

      if (difficulties.isEmpty) {
        return const DifficultyAnalysis(
          averageDifficulty: 3.0,
          difficultyTrend: TrendDirection.stable,
          difficultyDistribution: {},
          recommendations: ['Invalid difficulty ratings'],
        );
      }

      final averageDifficulty = difficulties.reduce((a, b) => a + b) / difficulties.length;
      
      // Calculate distribution
      final distribution = <String, int>{};
      for (final set in sets) {
        final difficulty = set['set_feedback_difficulty'] ?? 'unknown';
        distribution[difficulty] = (distribution[difficulty] ?? 0) + 1;
      }

      // Analyze trend
      final trend = _analyzeDifficultyTrend(difficulties);
      
      // Generate recommendations
      final recommendations = _generateDifficultyRecommendations(
        averageDifficulty,
        trend,
        distribution,
      );

      return DifficultyAnalysis(
        averageDifficulty: averageDifficulty,
        difficultyTrend: trend,
        difficultyDistribution: distribution,
        recommendations: recommendations,
      );
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to get difficulty analysis',
        error: e,
        stackTrace: stackTrace,
      );
      
      return const DifficultyAnalysis(
        averageDifficulty: 3.0,
        difficultyTrend: TrendDirection.stable,
        difficultyDistribution: {},
        recommendations: ['Analysis unavailable'],
      );
    }
  }

  /// Analyze difficulty trend over time
  TrendDirection _analyzeDifficultyTrend(List<double> difficulties) {
    if (difficulties.length < 5) return TrendDirection.stable;

    // Compare recent vs older difficulties
    final recentCount = (difficulties.length * 0.3).round().clamp(3, 10);
    final recent = difficulties.take(recentCount).toList();
    final older = difficulties.skip(recentCount).take(recentCount).toList();

    if (older.isEmpty) return TrendDirection.stable;

    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final olderAvg = older.reduce((a, b) => a + b) / older.length;

    final difference = recentAvg - olderAvg;

    if (difference > 0.3) return TrendDirection.improving; // Getting easier (lower difficulty)
    if (difference < -0.3) return TrendDirection.declining; // Getting harder
    return TrendDirection.stable;
  }

  /// Generate difficulty-based recommendations
  List<String> _generateDifficultyRecommendations(
    double averageDifficulty,
    TrendDirection trend,
    Map<String, int> distribution,
  ) {
    final recommendations = <String>[];

    // Average difficulty recommendations
    if (averageDifficulty < 2.5) {
      recommendations.add('Sets are consistently easy - consider increasing weight or reps');
    } else if (averageDifficulty > 4.0) {
      recommendations.add('Sets are consistently hard - consider reducing weight or reps');
    }

    // Trend recommendations
    switch (trend) {
      case TrendDirection.improving:
        recommendations.add('Difficulty is decreasing over time - you\'re getting stronger!');
        break;
      case TrendDirection.declining:
        recommendations.add('Sets are getting harder - ensure adequate recovery');
        break;
      case TrendDirection.stable:
        recommendations.add('Difficulty is consistent - good progression management');
        break;
    }

    // Distribution recommendations
    final totalSets = distribution.values.fold(0, (a, b) => a + b);
    final veryHardPercent = (distribution['very_hard'] ?? 0) / totalSets * 100;
    final veryEasyPercent = (distribution['very_easy'] ?? 0) / totalSets * 100;

    if (veryHardPercent > 30) {
      recommendations.add('Too many very hard sets - consider reducing intensity');
    }
    if (veryEasyPercent > 30) {
      recommendations.add('Too many very easy sets - time to increase challenge');
    }

    if (recommendations.isEmpty) {
      recommendations.add('Difficulty ratings look balanced - keep up the good work!');
    }

    return recommendations;
  }

  /// Dispose of service resources
  Future<void> dispose() async {
    try {
      _logger.i('SetLoggingService disposed');
    } catch (e) {
      _logger.w('Error disposing SetLoggingService: $e');
    }
  }
}

// Data models for set logging analysis

class PerformanceComparison {
  final List<int> currentReps;
  final List<int> currentWeight;
  final List<int> previousReps;
  final double improvementPercentage;

  const PerformanceComparison({
    required this.currentReps,
    required this.currentWeight,
    required this.previousReps,
    required this.improvementPercentage,
  });
}

class WeightProgressionSuggestion {
  final int suggestedWeight;
  final ProgressionType progressionType;
  final double confidence;
  final String reasoning;

  const WeightProgressionSuggestion({
    required this.suggestedWeight,
    required this.progressionType,
    required this.confidence,
    required this.reasoning,
  });
}

enum ProgressionType {
  increase,
  decrease,
  maintain,
}

class HistoricalPerformanceData {
  final int reps;
  final double weight;
  final DateTime completedAt;

  const HistoricalPerformanceData({
    required this.reps,
    required this.weight,
    required this.completedAt,
  });
}

enum TrendDirection {
  improving,
  declining,
  stable,
}

class RestPeriodAnalysis {
  final int averageRestTime;
  final int optimalRestTime;
  final double restTimeVariability;
  final List<String> recommendations;

  const RestPeriodAnalysis({
    required this.averageRestTime,
    required this.optimalRestTime,
    required this.restTimeVariability,
    required this.recommendations,
  });
}

class DifficultyAnalysis {
  final double averageDifficulty;
  final TrendDirection difficultyTrend;
  final Map<String, int> difficultyDistribution;
  final List<String> recommendations;

  const DifficultyAnalysis({
    required this.averageDifficulty,
    required this.difficultyTrend,
    required this.difficultyDistribution,
    required this.recommendations,
  });
}

// Provider
final setLoggingServiceProvider = Provider<SetLoggingService>((ref) {
  return SetLoggingService.instance;
});