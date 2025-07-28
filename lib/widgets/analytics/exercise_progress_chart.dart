import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/models.dart';
import '../../providers/analytics_provider.dart';

/// Chart showing exercise-specific progress using workout_set_logs grouped by exercise_id
class ExerciseProgressChart extends ConsumerStatefulWidget {
  const ExerciseProgressChart({super.key});

  @override
  ConsumerState<ExerciseProgressChart> createState() => _ExerciseProgressChartState();
}

class _ExerciseProgressChartState extends ConsumerState<ExerciseProgressChart> {
  String? _selectedExercise;
  final List<String> _metricTypes = ['Weight', 'Reps', 'Volume'];
  String _selectedMetric = 'Weight';

  @override
  Widget build(BuildContext context) {
    final progressAnalytics = ref.watch(progressAnalyticsProvider);
    
    if (progressAnalytics == null) {
      return _buildLoadingState();
    }

    final exerciseProgress = progressAnalytics.exerciseProgress;
    if (exerciseProgress.isEmpty) {
      return _buildEmptyState();
    }

    // Set default exercise if none selected
    _selectedExercise ??= exerciseProgress.first.exerciseId;

    final selectedExerciseData = exerciseProgress.firstWhere(
      (exercise) => exercise.exerciseId == _selectedExercise,
      orElse: () => exerciseProgress.first,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with controls
            _buildHeader(exerciseProgress),
            const SizedBox(height: 16),
            
            // Exercise stats summary
            _buildExerciseStats(selectedExerciseData),
            const SizedBox(height: 16),
            
            // Progress chart
            SizedBox(
              height: 300,
              child: _buildProgressChart(selectedExerciseData),
            ),
            
            const SizedBox(height: 16),
            
            // Recent performance
            _buildRecentPerformance(selectedExerciseData),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Card(
      child: Container(
        height: 400,
        padding: const EdgeInsets.all(16.0),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Container(
        height: 400,
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fitness_center,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No exercise progress data',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Complete workouts to see exercise-specific progress',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(List<ExerciseProgressData> exercises) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Exercise Progress',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildExerciseDropdown(exercises),
          ],
        ),
        const SizedBox(height: 8),
        
        // Metric selector
        Row(
          children: [
            Text(
              'Metric: ',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            ..._metricTypes.map((metric) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(metric),
                  selected: _selectedMetric == metric,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedMetric = metric;
                      });
                    }
                  },
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildExerciseDropdown(List<ExerciseProgressData> exercises) {
    return DropdownButton<String>(
      value: _selectedExercise,
      items: exercises.map((exercise) {
        return DropdownMenuItem<String>(
          value: exercise.exerciseId,
          child: Text(
            exercise.exerciseName,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedExercise = newValue;
          });
        }
      },
      underline: Container(),
      icon: const Icon(Icons.arrow_drop_down),
    );
  }

  Widget _buildExerciseStats(ExerciseProgressData exerciseData) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Max Weight',
            '${exerciseData.maxWeight.toStringAsFixed(1)}kg',
            Icons.fitness_center,
            Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Max Reps',
            '${exerciseData.maxReps}',
            Icons.repeat,
            Theme.of(context).colorScheme.secondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Total Volume',
            '${exerciseData.totalVolume.toStringAsFixed(0)}kg',
            Icons.trending_up,
            Theme.of(context).colorScheme.tertiary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Total Sets',
            '${exerciseData.totalSets}',
            Icons.format_list_numbered,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChart(ExerciseProgressData exerciseData) {
    final progressHistory = exerciseData.progressHistory;
    
    if (progressHistory.isEmpty) {
      return Center(
        child: Text(
          'No progress history available',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // Create line chart data based on selected metric
    final spots = <FlSpot>[];
    
    for (int i = 0; i < progressHistory.length; i++) {
      final dataPoint = progressHistory[i];
      double value;
      
      switch (_selectedMetric) {
        case 'Weight':
          value = dataPoint.weight;
          break;
        case 'Reps':
          value = dataPoint.reps.toDouble();
          break;
        case 'Volume':
          value = dataPoint.volume;
          break;
        default:
          value = dataPoint.weight;
      }
      
      spots.add(FlSpot(i.toDouble(), value));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: _getInterval(spots),
          verticalInterval: (progressHistory.length / 5).ceil().toDouble(),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (progressHistory.length / 5).ceil().toDouble(),
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < progressHistory.length) {
                  final date = progressHistory[index].date;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      '${date.month}/${date.day}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _getInterval(spots),
              reservedSize: 42,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  _formatYAxisLabel(value),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.left,
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        minX: 0,
        maxX: (progressHistory.length - 1).toDouble(),
        minY: 0,
        maxY: _getMaxValue(spots) * 1.1,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: _getMetricColor(),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: _getMetricColor(),
                  strokeWidth: 2,
                  strokeColor: Theme.of(context).colorScheme.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: _getMetricColor().withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Theme.of(context).colorScheme.inverseSurface,
            tooltipRoundedRadius: 8,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final index = barSpot.x.toInt();
                if (index >= 0 && index < progressHistory.length) {
                  final dataPoint = progressHistory[index];
                  return LineTooltipItem(
                    '${_formatTooltipValue(barSpot.y)}\n${dataPoint.date.month}/${dataPoint.date.day}/${dataPoint.date.year}',
                    TextStyle(
                      color: Theme.of(context).colorScheme.onInverseSurface,
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
    );
  }

  Widget _buildRecentPerformance(ExerciseProgressData exerciseData) {
    final recentSessions = exerciseData.progressHistory.take(5).toList();
    
    if (recentSessions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Performance',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Header row
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Date',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Weight',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Reps',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Volume',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Data rows
              ...recentSessions.map((session) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${session.date.month}/${session.date.day}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${session.weight.toStringAsFixed(1)}kg',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${session.reps}',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${session.volume.toStringAsFixed(0)}kg',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Color _getMetricColor() {
    switch (_selectedMetric) {
      case 'Weight':
        return Theme.of(context).colorScheme.primary;
      case 'Reps':
        return Theme.of(context).colorScheme.secondary;
      case 'Volume':
        return Theme.of(context).colorScheme.tertiary;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  double _getInterval(List<FlSpot> spots) {
    if (spots.isEmpty) return 10;
    final maxValue = _getMaxValue(spots);
    return maxValue / 5;
  }

  double _getMaxValue(List<FlSpot> spots) {
    if (spots.isEmpty) return 100;
    return spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
  }

  String _formatYAxisLabel(double value) {
    switch (_selectedMetric) {
      case 'Weight':
        return '${value.toInt()}kg';
      case 'Reps':
        return '${value.toInt()}';
      case 'Volume':
        return '${(value / 1000).toStringAsFixed(0)}k';
      default:
        return '${value.toInt()}';
    }
  }

  String _formatTooltipValue(double value) {
    switch (_selectedMetric) {
      case 'Weight':
        return '${value.toStringAsFixed(1)}kg';
      case 'Reps':
        return '${value.toInt()} reps';
      case 'Volume':
        return '${value.toStringAsFixed(0)}kg volume';
      default:
        return value.toStringAsFixed(1);
    }
  }
}