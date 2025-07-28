import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/analytics_provider.dart';

/// Widget for comparing workout sessions with detailed performance analysis
class WorkoutComparisonWidget extends ConsumerStatefulWidget {
  final List<WorkoutLog> workouts;
  final Function(WorkoutLog) onSelected;

  const WorkoutComparisonWidget({
    super.key,
    required this.workouts,
    required this.onSelected,
  });

  @override
  ConsumerState<WorkoutComparisonWidget> createState() => _WorkoutComparisonWidgetState();
}

class _WorkoutComparisonWidgetState extends ConsumerState<WorkoutComparisonWidget> {
  WorkoutLog? _selectedWorkout1;
  WorkoutLog? _selectedWorkout2;
  bool _showComparison = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Workout Comparison',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (_selectedWorkout1 != null && _selectedWorkout2 != null)
                  IconButton(
                    onPressed: _clearSelection,
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear selection',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (widget.workouts.isEmpty)
              _buildEmptyState()
            else if (!_showComparison)
              _buildWorkoutSelection()
            else
              _buildComparisonView(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.compare_arrows,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No workouts to compare',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete some workouts to see comparisons here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select two workouts to compare',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        
        // Selection indicators
        Row(
          children: [
            Expanded(
              child: _buildSelectionCard(
                context,
                'First Workout',
                _selectedWorkout1,
                1,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSelectionCard(
                context,
                'Second Workout',
                _selectedWorkout2,
                2,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Workout list
        SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: widget.workouts.length,
            itemBuilder: (context, index) {
              final workout = widget.workouts[index];
              final isSelected1 = _selectedWorkout1?.id == workout.id;
              final isSelected2 = _selectedWorkout2?.id == workout.id;
              final isSelected = isSelected1 || isSelected2;
              
              return Card(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSelected1 
                        ? Colors.blue 
                        : isSelected2 
                            ? Colors.green 
                            : Theme.of(context).colorScheme.primary,
                    child: Text(
                      isSelected1 ? '1' : isSelected2 ? '2' : '${index + 1}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text('Workout ${workout.id.substring(0, 8)}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout.completedAt != null 
                            ? 'Completed: ${_formatDate(workout.completedAt!)}'
                            : 'Status: ${workout.statusDisplayName}',
                      ),
                      Row(
                        children: [
                          Text('${workout.formattedDuration}'),
                          if (workout.hasRating) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.star, size: 14, color: Colors.amber),
                            Text(' ${workout.rating}'),
                          ],
                        ],
                      ),
                    ],
                  ),
                  trailing: isSelected 
                      ? Icon(
                          Icons.check_circle,
                          color: isSelected1 ? Colors.blue : Colors.green,
                        )
                      : null,
                  onTap: () => _selectWorkout(workout),
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Compare button
        if (_selectedWorkout1 != null && _selectedWorkout2 != null)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _showComparisonResults,
              icon: const Icon(Icons.compare_arrows),
              label: const Text('Compare Workouts'),
            ),
          ),
      ],
    );
  }

  Widget _buildSelectionCard(BuildContext context, String title, WorkoutLog? workout, int number) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: workout != null 
              ? (number == 1 ? Colors.blue : Colors.green)
              : Theme.of(context).colorScheme.outline,
        ),
        borderRadius: BorderRadius.circular(8),
        color: workout != null 
            ? (number == 1 ? Colors.blue : Colors.green).withValues(alpha: 0.1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: number == 1 ? Colors.blue : Colors.green,
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (workout != null) ...[
            Text(
              'Workout ${workout.id.substring(0, 8)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _formatDate(workout.completedAt ?? workout.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ] else
            Text(
              'Tap a workout to select',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildComparisonView() {
    if (_selectedWorkout1 == null || _selectedWorkout2 == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: ref.read(analyticsServiceProvider).compareWorkouts(
        _selectedWorkout1!.id,
        _selectedWorkout2!.id,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildComparisonError(snapshot.error!);
        }

        final comparisonData = snapshot.data!;
        return _buildComparisonResults(comparisonData);
      },
    );
  }

  Widget _buildComparisonResults(Map<String, dynamic> comparisonData) {
    final comparison = comparisonData['comparison'] as Map<String, dynamic>;
    final workout1 = comparisonData['workout1'] as Map<String, dynamic>;
    final workout2 = comparisonData['workout2'] as Map<String, dynamic>;
    
    final summary1 = workout1['summary'] as Map<String, dynamic>;
    final summary2 = workout2['summary'] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with back button
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() => _showComparison = false),
              icon: const Icon(Icons.arrow_back),
            ),
            Expanded(
              child: Text(
                'Comparison Results',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Performance summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Performance Summary',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                comparison['performance_summary'] as String,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Detailed comparison metrics
        _buildComparisonMetrics(summary1, summary2, comparison),
        
        const SizedBox(height: 16),
        
        // Workout details side by side
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildWorkoutSummaryCard(
                context,
                'Workout 1',
                _selectedWorkout1!,
                summary1,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildWorkoutSummaryCard(
                context,
                'Workout 2',
                _selectedWorkout2!,
                summary2,
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComparisonMetrics(
    Map<String, dynamic> summary1,
    Map<String, dynamic> summary2,
    Map<String, dynamic> comparison,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Metric Comparison',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildMetricComparison(
              'Volume',
              '${(summary1['total_volume'] as double).toStringAsFixed(1)}kg',
              '${(summary2['total_volume'] as double).toStringAsFixed(1)}kg',
              comparison['volume_difference'] as double,
              'kg',
            ),
            
            _buildMetricComparison(
              'Sets',
              '${summary1['total_sets']}',
              '${summary2['total_sets']}',
              (comparison['sets_difference'] as int).toDouble(),
              '',
            ),
            
            _buildMetricComparison(
              'Reps',
              '${summary1['total_reps']}',
              '${summary2['total_reps']}',
              (comparison['reps_difference'] as int).toDouble(),
              '',
            ),
            
            _buildMetricComparison(
              'Duration',
              '${summary1['duration_minutes']}min',
              '${summary2['duration_minutes']}min',
              (comparison['duration_difference'] as int).toDouble(),
              'min',
            ),
            
            _buildMetricComparison(
              'Rating',
              '${summary1['rating'] ?? 'N/A'}⭐',
              '${summary2['rating'] ?? 'N/A'}⭐',
              (comparison['rating_difference'] as int).toDouble(),
              '⭐',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricComparison(
    String metric,
    String value1,
    String value2,
    double difference,
    String unit,
  ) {
    final isImprovement = difference > 0;
    final isNeutral = difference.abs() < 0.01;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              metric,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(value1, style: Theme.of(context).textTheme.bodySmall),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(value2, style: Theme.of(context).textTheme.bodySmall),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isNeutral 
                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                  : isImprovement 
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isNeutral)
                  Icon(
                    isImprovement ? Icons.trending_up : Icons.trending_down,
                    size: 12,
                    color: isImprovement ? Colors.green : Colors.red,
                  ),
                const SizedBox(width: 2),
                Text(
                  isNeutral 
                      ? '0$unit'
                      : '${isImprovement ? '+' : ''}${difference.toStringAsFixed(difference.abs() < 1 ? 1 : 0)}$unit',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isNeutral 
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : isImprovement 
                            ? Colors.green 
                            : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutSummaryCard(
    BuildContext context,
    String title,
    WorkoutLog workout,
    Map<String, dynamic> summary,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: accentColor),
        borderRadius: BorderRadius.circular(8),
        color: accentColor.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 8,
                backgroundColor: accentColor,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Workout ${workout.id.substring(0, 8)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            _formatDate(workout.completedAt ?? workout.createdAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          _buildSummaryStats(context, summary),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(BuildContext context, Map<String, dynamic> summary) {
    return Column(
      children: [
        _buildStatRow('Volume', '${(summary['total_volume'] as double).toStringAsFixed(1)}kg'),
        _buildStatRow('Sets', '${summary['total_sets']}'),
        _buildStatRow('Reps', '${summary['total_reps']}'),
        _buildStatRow('Duration', '${summary['duration_minutes']}min'),
        _buildStatRow('Rating', '${summary['rating'] ?? 'N/A'}⭐'),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonError(Object error) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to compare workouts',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => setState(() => _showComparison = false),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  void _selectWorkout(WorkoutLog workout) {
    setState(() {
      if (_selectedWorkout1 == null) {
        _selectedWorkout1 = workout;
      } else if (_selectedWorkout2 == null && workout.id != _selectedWorkout1!.id) {
        _selectedWorkout2 = workout;
      } else if (workout.id == _selectedWorkout1!.id) {
        _selectedWorkout1 = null;
      } else if (workout.id == _selectedWorkout2?.id) {
        _selectedWorkout2 = null;
      } else {
        // Replace the first selection if both are already selected
        _selectedWorkout1 = workout;
        _selectedWorkout2 = null;
      }
    });
  }

  void _showComparisonResults() {
    setState(() {
      _showComparison = true;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedWorkout1 = null;
      _selectedWorkout2 = null;
      _showComparison = false;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}