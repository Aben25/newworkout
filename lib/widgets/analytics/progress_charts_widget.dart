import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/analytics_provider.dart';
import '../../models/models.dart';

/// Interactive progress charts with animations and touch interactions
class ProgressChartsWidget extends ConsumerStatefulWidget {
  const ProgressChartsWidget({super.key});

  @override
  ConsumerState<ProgressChartsWidget> createState() => _ProgressChartsWidgetState();
}

class _ProgressChartsWidgetState extends ConsumerState<ProgressChartsWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _selectedChartIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
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
    final volumeAnalytics = ref.watch(volumeAnalyticsProvider);
    final trendAnalytics = ref.watch(trendAnalyticsProvider);
    final progressAnalytics = ref.watch(progressAnalyticsProvider);

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
                    'Progress Charts',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Volume')),
                      ButtonSegment(value: 1, label: Text('Trends')),
                      ButtonSegment(value: 2, label: Text('Exercise')),
                    ],
                    selected: {_selectedChartIndex},
                    onSelectionChanged: (Set<int> selection) {
                      setState(() {
                        _selectedChartIndex = selection.first;
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
              height: 300,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return _buildSelectedChart(
                    volumeAnalytics,
                    trendAnalytics,
                    progressAnalytics,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedChart(
    VolumeAnalytics? volumeAnalytics,
    TrendAnalytics? trendAnalytics,
    ProgressAnalytics? progressAnalytics,
  ) {
    switch (_selectedChartIndex) {
      case 0:
        return _buildVolumeChart(volumeAnalytics);
      case 1:
        return _buildTrendChart(trendAnalytics);
      case 2:
        return _buildExerciseChart(progressAnalytics);
      default:
        return _buildVolumeChart(volumeAnalytics);
    }
  }

  Widget _buildVolumeChart(VolumeAnalytics? volumeAnalytics) {
    if (volumeAnalytics == null || volumeAnalytics.weeklyVolume.isEmpty) {
      return _buildEmptyChart('No volume data available');
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
              .reduce((a, b) => a > b ? a : b) / 5,
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
              interval: volumeAnalytics.weeklyVolume
                  .map((e) => e.volume)
                  .reduce((a, b) => a > b ? a : b) / 4,
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
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
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
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity( 0.3),
                  Theme.of(context).colorScheme.primary.withOpacity( 0.1),
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
                    'Week ${data.weekStart.month}/${data.weekStart.day}\n${data.volume.toStringAsFixed(1)}kg',
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

  Widget _buildTrendChart(TrendAnalytics? trendAnalytics) {
    if (trendAnalytics == null || trendAnalytics.volumeTrendData.isEmpty) {
      return _buildEmptyChart('No trend data available');
    }

    final volumeSpots = trendAnalytics.volumeTrendData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value * _animation.value);
    }).toList();

    final frequencySpots = trendAnalytics.frequencyTrendData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value * _animation.value);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
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
              interval: 2,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < trendAnalytics.volumeTrendData.length) {
                  final date = trendAnalytics.volumeTrendData[index].date;
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
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    value.toStringAsFixed(0),
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
        lineBarsData: [
          // Volume trend line
          LineChartBarData(
            spots: volumeSpots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
          ),
          // Frequency trend line
          LineChartBarData(
            spots: frequencySpots,
            isCurved: true,
            color: Theme.of(context).colorScheme.secondary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final index = barSpot.x.toInt();
                final isVolume = barSpot.barIndex == 0;
                final data = isVolume 
                    ? trendAnalytics.volumeTrendData[index]
                    : trendAnalytics.frequencyTrendData[index];
                
                return LineTooltipItem(
                  '${isVolume ? 'Volume' : 'Frequency'}\n${data.value.toStringAsFixed(1)}',
                  TextStyle(
                    color: isVolume 
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseChart(ProgressAnalytics? progressAnalytics) {
    if (progressAnalytics == null || progressAnalytics.exerciseProgress.isEmpty) {
      return _buildEmptyChart('No exercise data available');
    }

    final topExercises = progressAnalytics.exerciseProgress.take(5).toList();
    final barGroups = topExercises.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.totalVolume * _animation.value,
            color: Theme.of(context).colorScheme.primary,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: topExercises.isNotEmpty 
            ? topExercises.first.totalVolume * 1.2
            : 100,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (groupIndex < topExercises.length) {
                final exercise = topExercises[groupIndex];
                return BarTooltipItem(
                  '${exercise.exerciseName}\n${exercise.totalVolume.toStringAsFixed(1)}kg',
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
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < topExercises.length) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      topExercises[index].exerciseName.length > 10
                          ? '${topExercises[index].exerciseName.substring(0, 10)}...'
                          : topExercises[index].exerciseName,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
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
        barGroups: barGroups,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: topExercises.isNotEmpty 
              ? topExercises.first.totalVolume / 5
              : 20,
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

  Widget _buildEmptyChart(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
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
}