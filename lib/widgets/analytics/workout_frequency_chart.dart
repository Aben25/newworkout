import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/analytics_provider.dart';
import '../../models/models.dart';

/// Workout frequency chart with interactive elements
class WorkoutFrequencyChart extends ConsumerStatefulWidget {
  const WorkoutFrequencyChart({super.key});

  @override
  ConsumerState<WorkoutFrequencyChart> createState() => _WorkoutFrequencyChartState();
}

class _WorkoutFrequencyChartState extends ConsumerState<WorkoutFrequencyChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _selectedPeriod = 0; // 0: Daily, 1: Weekly

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workoutFrequency = ref.watch(workoutFrequencyAnalyticsProvider);
    final volumeAnalytics = ref.watch(volumeAnalyticsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Workout Frequency',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Daily')),
                      ButtonSegment(value: 1, label: Text('Weekly')),
                    ],
                    selected: {_selectedPeriod},
                    onSelectionChanged: (Set<int> selection) {
                      setState(() {
                        _selectedPeriod = selection.first;
                      });
                      _animationController.reset();
                      _animationController.forward();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return _selectedPeriod == 0
                      ? _buildDailyChart(workoutFrequency)
                      : _buildWeeklyChart(volumeAnalytics);
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildFrequencyStats(workoutFrequency),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyChart(WorkoutFrequencyAnalytics? workoutFrequency) {
    if (workoutFrequency == null || workoutFrequency.dailyWorkouts.isEmpty) {
      return _buildEmptyChart('No daily workout data available');
    }

    final barGroups = workoutFrequency.dailyWorkouts.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data.count.toDouble() * _animation.value,
            color: _getIntensityColor(data.count),
            width: 12,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(2),
              topRight: Radius.circular(2),
            ),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: workoutFrequency.dailyWorkouts
            .map((e) => e.count)
            .reduce((a, b) => a > b ? a : b)
            .toDouble() + 1,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (groupIndex < workoutFrequency.dailyWorkouts.length) {
                final data = workoutFrequency.dailyWorkouts[groupIndex];
                return BarTooltipItem(
                  '${_formatDate(data.date)}\n${data.count} workout${data.count != 1 ? 's' : ''}',
                  TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }
              return null;
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 5,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < workoutFrequency.dailyWorkouts.length) {
                  final date = workoutFrequency.dailyWorkouts[index].date;
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
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    value.toInt().toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity( 0.3),
          ),
        ),
        barGroups: barGroups,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.outline.withOpacity( 0.2),
              strokeWidth: 1,
            );
          },
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(VolumeAnalytics? volumeAnalytics) {
    if (volumeAnalytics == null || volumeAnalytics.weeklyVolume.isEmpty) {
      return _buildEmptyChart('No weekly data available');
    }

    final spots = volumeAnalytics.weeklyVolume.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.volume * _animation.value);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: volumeAnalytics.weeklyVolume
              .map((e) => e.volume)
              .reduce((a, b) => a > b ? a : b) / 4,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.outline.withOpacity( 0.2),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.outline.withOpacity( 0.2),
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
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < volumeAnalytics.weeklyVolume.length) {
                  final date = volumeAnalytics.weeklyVolume[index].weekStart;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      'W${_getWeekNumber(date)}',
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
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    '${value.toInt()}kg',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity( 0.3),
          ),
        ),
        minX: 0,
        maxX: (volumeAnalytics.weeklyVolume.length - 1).toDouble(),
        minY: 0,
        maxY: volumeAnalytics.weeklyVolume
            .map((e) => e.volume)
            .reduce((a, b) => a > b ? a : b) * 1.1,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.tertiary,
                Theme.of(context).colorScheme.primary,
              ],
            ),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 5,
                  color: Theme.of(context).colorScheme.primary,
                  strokeWidth: 2,
                  strokeColor: Theme.of(context).colorScheme.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity( 0.3),
                  Theme.of(context).colorScheme.primary.withOpacity( 0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final index = barSpot.x.toInt();
                if (index >= 0 && index < volumeAnalytics.weeklyVolume.length) {
                  final data = volumeAnalytics.weeklyVolume[index];
                  return LineTooltipItem(
                    'Week ${_getWeekNumber(data.weekStart)}\n${data.volume.toStringAsFixed(1)}kg total',
                    TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
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

  Widget _buildFrequencyStats(WorkoutFrequencyAnalytics? workoutFrequency) {
    if (workoutFrequency == null) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(
          child: _buildStatItem(
            'This Week',
            '${workoutFrequency.workoutsThisWeek}',
            Icons.calendar_today,
            Theme.of(context).colorScheme.primary,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            'Average/Week',
            workoutFrequency.averageWorkoutsPerWeek.toStringAsFixed(1),
            Icons.trending_up,
            Theme.of(context).colorScheme.secondary,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            'Current Streak',
            '${workoutFrequency.currentStreak}',
            Icons.local_fire_department,
            Colors.orange,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            'Best Streak',
            '${workoutFrequency.longestStreak}',
            Icons.emoji_events,
            Colors.amber,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildEmptyChart(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getIntensityColor(int count) {
    if (count == 0) return Theme.of(context).colorScheme.surfaceContainerHighest;
    if (count == 1) return Theme.of(context).colorScheme.primary.withOpacity( 0.3);
    if (count == 2) return Theme.of(context).colorScheme.primary.withOpacity( 0.6);
    return Theme.of(context).colorScheme.primary;
  }

  String _formatDate(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[date.weekday - 1]} ${date.month}/${date.day}';
  }

  int _getWeekNumber(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }
}