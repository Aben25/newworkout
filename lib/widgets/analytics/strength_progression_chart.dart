import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/models.dart';
import '../../providers/analytics_provider.dart';

/// Chart showing strength progression using historical weight data from completed_sets
class StrengthProgressionChart extends ConsumerStatefulWidget {
  const StrengthProgressionChart({super.key});

  @override
  ConsumerState<StrengthProgressionChart> createState() => _StrengthProgressionChartState();
}

class _StrengthProgressionChartState extends ConsumerState<StrengthProgressionChart> {
  String? _selectedExercise;
  final List<String> _timeRanges = ['1M', '3M', '6M', '1Y', 'All'];
  String _selectedTimeRange = '3M';

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
            // Header with exercise selector
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Strength Progression',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildExerciseDropdown(exerciseProgress),
              ],
            ),
            const SizedBox(height: 8),
            
            // Time range selector
            _buildTimeRangeSelector(),
            const SizedBox(height: 16),
            
            // Chart
            SizedBox(
              height: 300,
              child: _buildProgressChart(selectedExerciseData),
            ),
            
            const SizedBox(height: 16),
            
            // Progress summary
            _buildProgressSummary(selectedExerciseData),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Card(
      child: Container(
        height: 300,
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
        height: 300,
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.trending_up,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No strength data available',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Complete workouts with weights to see your progress',
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

  Widget _buildTimeRangeSelector() {
    return Row(
      children: _timeRanges.map((range) {
        final isSelected = range == _selectedTimeRange;
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: FilterChip(
            label: Text(range),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedTimeRange = range;
                });
              }
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProgressChart(ExerciseProgressData exerciseData) {
    final filteredData = _filterDataByTimeRange(exerciseData.progressHistory);
    
    if (filteredData.isEmpty) {
      return Center(
        child: Text(
          'No data for selected time range',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // Create line chart data
    final weightSpots = <FlSpot>[];
    final volumeSpots = <FlSpot>[];
    
    for (int i = 0; i < filteredData.length; i++) {
      final dataPoint = filteredData[i];
      weightSpots.add(FlSpot(i.toDouble(), dataPoint.weight));
      volumeSpots.add(FlSpot(i.toDouble(), dataPoint.volume / 10)); // Scale volume for visibility
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 10,
          verticalInterval: 1,
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
              interval: (filteredData.length / 5).ceil().toDouble(),
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < filteredData.length) {
                  final date = filteredData[index].date;
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
              interval: 20,
              reservedSize: 42,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  '${value.toInt()}kg',
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
        maxX: (filteredData.length - 1).toDouble(),
        minY: 0,
        maxY: _getMaxWeight(filteredData) * 1.1,
        lineBarsData: [
          // Weight progression line
          LineChartBarData(
            spots: weightSpots,
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
                  strokeColor: Theme.of(context).colorScheme.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                if (index >= 0 && index < filteredData.length) {
                  final dataPoint = filteredData[index];
                  return LineTooltipItem(
                    '${dataPoint.weight.toStringAsFixed(1)}kg\n${dataPoint.reps} reps\n${dataPoint.date.month}/${dataPoint.date.day}',
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

  Widget _buildProgressSummary(ExerciseProgressData exerciseData) {
    final filteredData = _filterDataByTimeRange(exerciseData.progressHistory);
    
    if (filteredData.isEmpty) {
      return const SizedBox.shrink();
    }

    final firstWeight = filteredData.first.weight;
    final lastWeight = filteredData.last.weight;
    final weightIncrease = lastWeight - firstWeight;
    final percentIncrease = firstWeight > 0 ? (weightIncrease / firstWeight) * 100 : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            'Max Weight',
            '${exerciseData.maxWeight.toStringAsFixed(1)}kg',
            Icons.fitness_center,
          ),
          _buildSummaryItem(
            'Progress',
            '${weightIncrease >= 0 ? '+' : ''}${weightIncrease.toStringAsFixed(1)}kg',
            weightIncrease >= 0 ? Icons.trending_up : Icons.trending_down,
            color: weightIncrease >= 0 ? Colors.green : Colors.red,
          ),
          _buildSummaryItem(
            'Improvement',
            '${percentIncrease >= 0 ? '+' : ''}${percentIncrease.toStringAsFixed(1)}%',
            Icons.percent,
            color: percentIncrease >= 0 ? Colors.green : Colors.red,
          ),
          _buildSummaryItem(
            'Total Sets',
            '${exerciseData.totalSets}',
            Icons.repeat,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: color ?? Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  List<ProgressDataPoint> _filterDataByTimeRange(List<ProgressDataPoint> data) {
    final now = DateTime.now();
    DateTime cutoffDate;

    switch (_selectedTimeRange) {
      case '1M':
        cutoffDate = now.subtract(const Duration(days: 30));
        break;
      case '3M':
        cutoffDate = now.subtract(const Duration(days: 90));
        break;
      case '6M':
        cutoffDate = now.subtract(const Duration(days: 180));
        break;
      case '1Y':
        cutoffDate = now.subtract(const Duration(days: 365));
        break;
      case 'All':
      default:
        return data;
    }

    return data.where((point) => point.date.isAfter(cutoffDate)).toList();
  }

  double _getMaxWeight(List<ProgressDataPoint> data) {
    if (data.isEmpty) return 100;
    return data.map((point) => point.weight).reduce((a, b) => a > b ? a : b);
  }
}