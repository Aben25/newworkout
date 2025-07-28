import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/analytics_provider.dart';

/// Widget showing detailed set-by-set breakdown for a workout
class WorkoutSetBreakdown extends ConsumerWidget {
  final String workoutLogId;

  const WorkoutSetBreakdown({
    super.key,
    required this.workoutLogId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutAnalysisAsync = ref.watch(workoutAnalysisProvider(workoutLogId));
    
    return workoutAnalysisAsync.when(
      data: (analysis) => _buildRealBreakdown(context, analysis),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => _buildErrorState(context, error),
    );
  }

  Widget _buildPlaceholderBreakdown(BuildContext context) {
    // Placeholder data for demonstration
    final exercises = [
      {
        'name': 'Bench Press',
        'sets': [
          {'reps': 10, 'weight': 80.0},
          {'reps': 8, 'weight': 85.0},
          {'reps': 6, 'weight': 90.0},
        ],
      },
      {
        'name': 'Squats',
        'sets': [
          {'reps': 12, 'weight': 100.0},
          {'reps': 10, 'weight': 105.0},
          {'reps': 8, 'weight': 110.0},
        ],
      },
      {
        'name': 'Deadlifts',
        'sets': [
          {'reps': 8, 'weight': 120.0},
          {'reps': 6, 'weight': 125.0},
          {'reps': 5, 'weight': 130.0},
        ],
      },
    ];

    return Column(
      children: exercises.map((exercise) {
        return _buildExerciseBreakdown(
          context,
          exercise['name'] as String,
          exercise['sets'] as List<Map<String, dynamic>>,
        );
      }).toList(),
    );
  }

  Widget _buildExerciseBreakdown(
    BuildContext context,
    String exerciseName,
    List<Map<String, dynamic>> sets,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise name and summary
          Row(
            children: [
              Expanded(
                child: Text(
                  exerciseName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${sets.length} sets',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Sets breakdown
          ...sets.asMap().entries.map((entry) {
            final setIndex = entry.key;
            final setData = entry.value;
            return _buildSetRow(
              context,
              setIndex + 1,
              setData['reps'] as int,
              setData['weight'] as double,
            );
          }),
          
          const SizedBox(height: 8),
          
          // Exercise summary
          _buildExerciseSummary(context, sets),
        ],
      ),
    );
  }

  Widget _buildSetRow(BuildContext context, int setNumber, int reps, double weight) {
    final volume = reps * weight;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          // Set number
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '$setNumber',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Reps
          Expanded(
            flex: 2,
            child: Text(
              '$reps reps',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          
          // Weight
          Expanded(
            flex: 2,
            child: Text(
              '${weight.toStringAsFixed(1)}kg',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          
          // Volume
          Expanded(
            flex: 2,
            child: Text(
              '${volume.toStringAsFixed(0)}kg',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseSummary(BuildContext context, List<Map<String, dynamic>> sets) {
    final totalReps = sets.fold<int>(0, (sum, set) => sum + (set['reps'] as int));
    final totalVolume = sets.fold<double>(0, (sum, set) => 
        sum + ((set['reps'] as int) * (set['weight'] as double)));
    final maxWeight = sets.fold<double>(0, (max, set) => 
        (set['weight'] as double) > max ? (set['weight'] as double) : max);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            context,
            'Total Reps',
            '$totalReps',
            Icons.repeat,
          ),
          _buildSummaryItem(
            context,
            'Max Weight',
            '${maxWeight.toStringAsFixed(1)}kg',
            Icons.fitness_center,
          ),
          _buildSummaryItem(
            context,
            'Total Volume',
            '${totalVolume.toStringAsFixed(0)}kg',
            Icons.trending_up,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildRealBreakdown(BuildContext context, Map<String, dynamic> analysis) {
    final exerciseBreakdown = analysis['exercise_breakdown'] as Map<String, dynamic>? ?? {};
    
    if (exerciseBreakdown.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: exerciseBreakdown.entries.map((entry) {
        final exerciseData = entry.value as Map<String, dynamic>;
        final exerciseName = exerciseData['exercise_name'] as String;
        final setLogs = exerciseData['sets'] as List<dynamic>;
        
        final sets = setLogs.map((setLog) => {
          'reps': setLog.repsCompleted,
          'weight': setLog.weight ?? 0.0,
        }).toList();

        return _buildExerciseBreakdown(context, exerciseName, sets);
      }).toList(),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 32,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 8),
          Text(
            'Failed to load workout details',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.fitness_center,
            size: 32,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'No exercise data available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}