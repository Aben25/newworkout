import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/models.dart';
import '../../services/set_logging_service.dart';
import '../../utils/app_theme.dart';

/// Comprehensive set progress tracker with visual indicators
/// Shows performed vs planned reps/weights with progression analysis
class SetProgressTrackerWidget extends StatefulWidget {
  final WorkoutExercise workoutExercise;
  final Exercise exercise;
  final List<CompletedSetLog> completedSets;
  final PerformanceComparison? performanceComparison;
  final bool showDetailedAnalysis;

  const SetProgressTrackerWidget({
    super.key,
    required this.workoutExercise,
    required this.exercise,
    required this.completedSets,
    this.performanceComparison,
    this.showDetailedAnalysis = true,
  });

  @override
  State<SetProgressTrackerWidget> createState() => _SetProgressTrackerWidgetState();
}

class _SetProgressTrackerWidgetState extends State<SetProgressTrackerWidget>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _chartController;
  late Animation<double> _progressAnimation;
  late Animation<double> _chartAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _chartController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));

    _chartAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _chartController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    _progressController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _chartController.forward();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            
            const SizedBox(height: 16),
            
            // Set progress overview
            _buildSetProgressOverview(),
            
            const SizedBox(height: 16),
            
            // Performance vs planned chart
            _buildPerformanceChart(),
            
            if (widget.showDetailedAnalysis) ...[
              const SizedBox(height: 16),
              
              // Detailed analysis
              _buildDetailedAnalysis(),
            ],
            
            if (widget.performanceComparison != null) ...[
              const SizedBox(height: 16),
              
              // Performance comparison
              _buildPerformanceComparison(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.analytics,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set Progress Tracking',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.exercise.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity( 0.7),
                ),
              ),
            ],
          ),
        ),
        // Overall progress indicator
        _buildOverallProgressIndicator(),
      ],
    );
  }

  Widget _buildOverallProgressIndicator() {
    final totalPlannedSets = widget.workoutExercise.effectiveSets;
    final completedSets = widget.completedSets.length;
    final progress = totalPlannedSets > 0 ? completedSets / totalPlannedSets : 0.0;

    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                value: progress * _progressAnimation.value,
                strokeWidth: 4,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressColor(progress),
                ),
              ),
            ),
            Text(
              '$completedSets/$totalPlannedSets',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSetProgressOverview() {
    final plannedSets = widget.workoutExercise.effectiveSets;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set-by-Set Progress',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        // Set progress indicators
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: plannedSets,
            itemBuilder: (context, index) {
              final setNumber = index + 1;
              final completedSet = widget.completedSets
                  .where((set) => set.setNumber == setNumber)
                  .firstOrNull;
              
              return AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _progressAnimation.value,
                    child: Container(
                      width: 60,
                      margin: const EdgeInsets.only(right: 8),
                      child: _buildSetIndicator(setNumber, completedSet),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSetIndicator(int setNumber, CompletedSetLog? completedSet) {
    final isCompleted = completedSet != null;
    final plannedReps = widget.workoutExercise.reps?.isNotEmpty == true &&
                       setNumber <= widget.workoutExercise.reps!.length
        ? widget.workoutExercise.reps![setNumber - 1]
        : null;
    final plannedWeight = widget.workoutExercise.weight?.isNotEmpty == true &&
                         setNumber <= widget.workoutExercise.weight!.length
        ? widget.workoutExercise.weight![setNumber - 1]
        : null;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isCompleted
            ? _getSetCompletionColor(completedSet, plannedReps, plannedWeight)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCompleted
              ? _getSetCompletionColor(completedSet, plannedReps, plannedWeight)
              : Theme.of(context).colorScheme.outline.withOpacity( 0.3),
          width: isCompleted ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Set number
          Text(
            '$setNumber',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isCompleted ? Colors.white : null,
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Performance vs planned
          if (isCompleted) ...[
            Text(
              '${completedSet.reps}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '${completedSet.weight}kg',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity( 0.9),
              ),
            ),
          ] else ...[
            if (plannedReps != null) ...[
              Text(
                '$plannedReps',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity( 0.6),
                ),
              ),
            ],
            if (plannedWeight != null) ...[
              Text(
                '${plannedWeight}kg',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity( 0.6),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPerformanceChart() {
    if (widget.completedSets.isEmpty) {
      return _buildEmptyChart();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance vs Target',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        SizedBox(
          height: 200,
          child: AnimatedBuilder(
            animation: _chartAnimation,
            builder: (context, child) {
              return _buildBarChart();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart() {
    final maxSets = math.max(widget.workoutExercise.effectiveSets, widget.completedSets.length);
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxChartValue(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final setNumber = group.x + 1;
              final isReps = rodIndex == 0;
              final value = rod.toY;
              
              return BarTooltipItem(
                'Set $setNumber\n${isReps ? 'Reps' : 'Weight'}: ${value.toStringAsFixed(isReps ? 0 : 1)}${isReps ? '' : 'kg'}',
                TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt() + 1}',
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: _buildBarGroups(),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    final groups = <BarChartGroupData>[];
    final maxSets = math.max(widget.workoutExercise.effectiveSets, widget.completedSets.length);

    for (int i = 0; i < maxSets; i++) {
      final setNumber = i + 1;
      final completedSet = widget.completedSets
          .where((set) => set.setNumber == setNumber)
          .firstOrNull;
      
      final plannedReps = widget.workoutExercise.reps?.isNotEmpty == true &&
                         i < widget.workoutExercise.reps!.length
          ? widget.workoutExercise.reps![i].toDouble()
          : 0.0;
      
      final plannedWeight = widget.workoutExercise.weight?.isNotEmpty == true &&
                           i < widget.workoutExercise.weight!.length
          ? widget.workoutExercise.weight![i].toDouble()
          : 0.0;

      final actualReps = completedSet?.reps.toDouble() ?? 0.0;
      final actualWeight = completedSet?.weight ?? 0.0;

      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            // Reps bars
            BarChartRodData(
              toY: actualReps * _chartAnimation.value,
              color: _getPerformanceColor(actualReps, plannedReps),
              width: 8,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            // Planned reps (background)
            BarChartRodData(
              toY: plannedReps,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              width: 8,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return groups;
  }

  Widget _buildEmptyChart() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity( 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete sets to see progress',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity( 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedAnalysis() {
    if (widget.completedSets.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalVolume = widget.completedSets.fold<double>(
      0.0,
      (sum, set) => sum + (set.reps * set.weight),
    );
    
    final averageReps = widget.completedSets.fold<int>(
      0,
      (sum, set) => sum + set.reps,
    ) / widget.completedSets.length;
    
    final averageWeight = widget.completedSets.fold<double>(
      0.0,
      (sum, set) => sum + set.weight,
    ) / widget.completedSets.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Session Analysis',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildAnalysisMetric(
                  'Total Volume',
                  '${totalVolume.toStringAsFixed(1)}kg',
                  Icons.fitness_center,
                  AppTheme.primaryColor,
                ),
              ),
              Expanded(
                child: _buildAnalysisMetric(
                  'Avg Reps',
                  averageReps.toStringAsFixed(1),
                  Icons.repeat,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildAnalysisMetric(
                  'Avg Weight',
                  '${averageWeight.toStringAsFixed(1)}kg',
                  Icons.scale,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPerformanceComparison() {
    final comparison = widget.performanceComparison!;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity( 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity( 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'vs Previous Session',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildComparisonMetric(
                  'Improvement',
                  '${comparison.improvementPercentage >= 0 ? '+' : ''}${comparison.improvementPercentage.toStringAsFixed(1)}%',
                  comparison.improvementPercentage >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  comparison.improvementPercentage >= 0 ? Colors.green : Colors.red,
                ),
              ),
              Expanded(
                child: _buildComparisonMetric(
                  'Previous Best',
                  comparison.previousReps.isNotEmpty 
                      ? '${comparison.previousReps.reduce((a, b) => a > b ? a : b)} reps'
                      : 'N/A',
                  Icons.history,
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Helper methods

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.7) return Colors.orange;
    return Theme.of(context).colorScheme.primary;
  }

  Color _getSetCompletionColor(CompletedSetLog completedSet, int? plannedReps, int? plannedWeight) {
    if (plannedReps == null && plannedWeight == null) {
      return AppTheme.successColor; // Completed without plan
    }

    bool exceededReps = plannedReps != null && completedSet.reps >= plannedReps;
    bool exceededWeight = plannedWeight != null && completedSet.weight >= plannedWeight;

    if (exceededReps && exceededWeight) {
      return Colors.green; // Exceeded both
    } else if (exceededReps || exceededWeight) {
      return Colors.orange; // Exceeded one
    } else {
      return Colors.red; // Below target
    }
  }

  Color _getPerformanceColor(double actual, double planned) {
    if (planned == 0) return AppTheme.primaryColor;
    
    final ratio = actual / planned;
    if (ratio >= 1.0) return Colors.green;
    if (ratio >= 0.8) return Colors.orange;
    return Colors.red;
  }

  double _getMaxChartValue() {
    double maxValue = 0.0;
    
    // Check completed sets
    for (final set in widget.completedSets) {
      maxValue = math.max(maxValue, set.reps.toDouble());
      maxValue = math.max(maxValue, set.weight);
    }
    
    // Check planned values
    if (widget.workoutExercise.reps?.isNotEmpty == true) {
      for (final reps in widget.workoutExercise.reps!) {
        maxValue = math.max(maxValue, reps.toDouble());
      }
    }
    
    if (widget.workoutExercise.weight?.isNotEmpty == true) {
      for (final weight in widget.workoutExercise.weight!) {
        maxValue = math.max(maxValue, weight.toDouble());
      }
    }
    
    return maxValue * 1.2; // Add 20% padding
  }
}