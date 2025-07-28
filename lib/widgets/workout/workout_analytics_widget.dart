import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/models.dart';

/// Comprehensive workout analytics widget with detailed session analytics
class WorkoutAnalyticsWidget extends StatelessWidget {
  final CompletedWorkout completedWorkout;
  final List<CompletedSetLog> completedSets;
  final List<ExerciseLogSession> exerciseLogs;
  final List<Exercise> exercises;

  const WorkoutAnalyticsWidget({
    super.key,
    required this.completedWorkout,
    required this.completedSets,
    required this.exerciseLogs,
    required this.exercises,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Volume distribution chart
        _buildVolumeDistributionChart(context),
        
        const SizedBox(height: 16),
        
        // Set performance chart
        _buildSetPerformanceChart(context),
        
        const SizedBox(height: 16),
        
        // Muscle group distribution
        _buildMuscleGroupDistribution(context),
        
        const SizedBox(height: 16),
        
        // Performance insights
        _buildPerformanceInsights(context),
      ],
    );
  }

  Widget _buildVolumeDistributionChart(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Volume Distribution by Exercise',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxVolume(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final exerciseLog = exerciseLogs[groupIndex];
                        final exercise = exercises.firstWhere(
                          (e) => e.id == exerciseLog.exerciseId,
                          orElse: () => Exercise(
                            id: exerciseLog.exerciseId,
                            name: 'Unknown',
                            createdAt: DateTime.now(),
                          ),
                        );
                        return BarTooltipItem(
                          '${exercise.name}\n${exerciseLog.totalVolume.toStringAsFixed(1)}kg',
                          const TextStyle(
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
                          final index = value.toInt();
                          if (index >= 0 && index < exerciseLogs.length) {
                            final exerciseLog = exerciseLogs[index];
                            final exercise = exercises.firstWhere(
                              (e) => e.id == exerciseLog.exerciseId,
                              orElse: () => Exercise(
                                id: exerciseLog.exerciseId,
                                name: 'Ex${index + 1}',
                                createdAt: DateTime.now(),
                              ),
                            );
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                exercise.name.length > 8 
                                    ? '${exercise.name.substring(0, 8)}...'
                                    : exercise.name,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}kg',
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: exerciseLogs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final exerciseLog = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: exerciseLog.totalVolume,
                          color: Theme.of(context).colorScheme.primary,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetPerformanceChart(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set Performance Over Time',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < completedSets.length) {
                            return Text(
                              'Set ${index + 1}',
                              style: Theme.of(context).textTheme.bodySmall,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}kg',
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: completedSets.asMap().entries.map((entry) {
                        final index = entry.key;
                        final set = entry.value;
                        return FlSpot(index.toDouble(), set.weight);
                      }).toList(),
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Theme.of(context).colorScheme.primary,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.x.toInt();
                          if (index >= 0 && index < completedSets.length) {
                            final set = completedSets[index];
                            return LineTooltipItem(
                              'Set ${index + 1}\n${set.reps} reps × ${set.weight.toStringAsFixed(1)}kg',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }
                          return null;
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMuscleGroupDistribution(BuildContext context) {
    final muscleGroups = completedWorkout.muscleGroupDistribution ?? {};
    if (muscleGroups.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Muscle Group Distribution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: muscleGroups.entries.map((entry) {
                    final muscleGroup = entry.key;
                    final count = entry.value;
                    final percentage = (count / muscleGroups.values.reduce((a, b) => a + b)) * 100;
                    
                    return PieChartSectionData(
                      color: _getMuscleGroupColor(muscleGroup),
                      value: count.toDouble(),
                      title: '${percentage.toStringAsFixed(0)}%',
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Legend
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: muscleGroups.entries.map((entry) {
                final muscleGroup = entry.key;
                final count = entry.value;
                
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getMuscleGroupColor(muscleGroup),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$muscleGroup ($count)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceInsights(BuildContext context) {
    final insights = _generatePerformanceInsights();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Insights',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            ...insights.map((insight) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    insight['icon'] as IconData,
                    size: 16,
                    color: insight['color'] as Color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      insight['text'] as String,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  double _getMaxVolume() {
    if (exerciseLogs.isEmpty) return 100;
    return exerciseLogs.map((e) => e.totalVolume).reduce((a, b) => a > b ? a : b) * 1.1;
  }

  Color _getMuscleGroupColor(String muscleGroup) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    
    return colors[muscleGroup.hashCode % colors.length];
  }

  List<Map<String, dynamic>> _generatePerformanceInsights() {
    final insights = <Map<String, dynamic>>[];
    
    // Volume analysis
    if (completedWorkout.totalVolume > 1000) {
      insights.add({
        'icon': Icons.trending_up,
        'color': Colors.green,
        'text': 'Excellent volume! You lifted over ${completedWorkout.totalVolume.toStringAsFixed(0)}kg total.',
      });
    }
    
    // Intensity analysis
    if (completedWorkout.workoutIntensity >= 7.0) {
      insights.add({
        'icon': Icons.local_fire_department,
        'color': Colors.red,
        'text': 'High intensity workout! Your intensity score was ${completedWorkout.workoutIntensity}/10.',
      });
    }
    
    // Duration analysis
    if (completedWorkout.duration >= 60) {
      insights.add({
        'icon': Icons.access_time,
        'color': Colors.blue,
        'text': 'Great endurance! You maintained focus for ${completedWorkout.formattedDuration}.',
      });
    }
    
    // Consistency analysis
    final avgDifficulty = _calculateAverageDifficulty();
    if (avgDifficulty >= 3.5) {
      insights.add({
        'icon': Icons.psychology,
        'color': Colors.purple,
        'text': 'You pushed yourself hard! Average difficulty was ${avgDifficulty.toStringAsFixed(1)}/5.',
      });
    }
    
    // Muscle group variety
    final muscleGroups = completedWorkout.muscleGroupDistribution?.length ?? 0;
    if (muscleGroups >= 4) {
      insights.add({
        'icon': Icons.accessibility_new,
        'color': Colors.teal,
        'text': 'Well-rounded workout! You targeted $muscleGroups different muscle groups.',
      });
    }
    
    // Personal records
    final personalRecords = completedWorkout.workoutSummary?['personal_records'] as List?;
    if (personalRecords?.isNotEmpty == true) {
      insights.add({
        'icon': Icons.emoji_events,
        'color': Colors.orange,
        'text': 'New personal records! You set ${personalRecords!.length} PR${personalRecords.length > 1 ? 's' : ''} today.',
      });
    }
    
    // Default insight if none apply
    if (insights.isEmpty) {
      insights.add({
        'icon': Icons.check_circle,
        'color': Colors.green,
        'text': 'Great job completing your workout! Every session counts towards your fitness goals.',
      });
    }
    
    return insights;
  }

  double _calculateAverageDifficulty() {
    final ratingsWithValues = completedSets
        .where((set) => set.difficultyRating != null)
        .map((set) => set.difficultyRatingValue)
        .where((rating) => rating != null)
        .cast<double>()
        .toList();

    if (ratingsWithValues.isEmpty) return 3.0; // Default moderate
    
    return ratingsWithValues.reduce((a, b) => a + b) / ratingsWithValues.length;
  }
}