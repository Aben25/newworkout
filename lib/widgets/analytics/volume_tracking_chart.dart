import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/models.dart';
import '../../providers/analytics_provider.dart';

/// Chart showing total workout volume over time
class VolumeTrackingChart extends ConsumerStatefulWidget {
  const VolumeTrackingChart({super.key});

  @override
  ConsumerState<VolumeTrackingChart> createState() => _VolumeTrackingChartState();
}

class _VolumeTrackingChartState extends ConsumerState<VolumeTrackingChart> {
  final List<String> _chartTypes = ['Weekly', 'Monthly'];
  String _selectedChartType = 'Weekly';

  @override
  Widget build(BuildContext context) {
    final volumeAnalytics = ref.watch(volumeAnalyticsProvider);
    
    if (volumeAnalytics == null) {
      return _buildLoadingState();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with chart type selector
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Volume Tracking',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildChartTypeSelector(),
              ],
            ),
            const SizedBox(height: 16),
            
            // Volume summary cards
            _buildVolumeSummary(volumeAnalytics),
            const SizedBox(height: 16),
            
            // Chart
            SizedBox(
              height: 300,
              child: _selectedChartType == 'Weekly'
                  ? _buildWeeklyVolumeChart(volumeAnalytics.weeklyVolume)
                  : _buildMonthlyVolumeChart(volumeAnalytics.weeklyVolume),
            ),
            
            const SizedBox(height: 16),
            
            // Top exercises by volume
            _buildTopExercises(volumeAnalytics.exerciseVolume),
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

  Widget _buildChartTypeSelector() {
    return SegmentedButton<String>(
      segments: _chartTypes.map((type) {
        return ButtonSegment<String>(
          value: type,
          label: Text(type),
        );
      }).toList(),
      selected: {_selectedChartType},
      onSelectionChanged: (Set<String> newSelection) {
        setState(() {
          _selectedChartType = newSelection.first;
        });
      },
    );
  }

  Widget _buildVolumeSummary(VolumeAnalytics volumeAnalytics) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'This Week',
            '${volumeAnalytics.totalVolumeThisWeek.toStringAsFixed(0)}kg',
            Icons.calendar_today,
            Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            'This Month',
            '${volumeAnalytics.totalVolumeThisMonth.toStringAsFixed(0)}kg',
            Icons.calendar_month,
            Theme.of(context).colorScheme.secondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            'All Time',
            '${volumeAnalytics.totalVolumeLifetime.toStringAsFixed(0)}kg',
            Icons.trending_up,
            Theme.of(context).colorScheme.tertiary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            'Avg/Workout',
            '${volumeAnalytics.averageVolumePerWorkout.toStringAsFixed(0)}kg',
            Icons.fitness_center,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
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

  Widget _buildWeeklyVolumeChart(List<WeeklyVolumeData> weeklyData) {
    if (weeklyData.isEmpty) {
      return _buildEmptyChart('No weekly volume data available');
    }

    final barGroups = weeklyData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data.volume,
            color: Theme.of(context).colorScheme.primary,
            width: 16,
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
        maxY: _getMaxVolume(weeklyData) * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Theme.of(context).colorScheme.inverseSurface,
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (groupIndex < weeklyData.length) {
                final data = weeklyData[groupIndex];
                return BarTooltipItem(
                  '${data.volume.toStringAsFixed(0)}kg\nWeek of ${data.weekStart.month}/${data.weekStart.day}',
                  TextStyle(
                    color: Theme.of(context).colorScheme.onInverseSurface,
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
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < weeklyData.length) {
                  final date = weeklyData[index].weekStart;
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
              reservedSize: 40,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  '${(value / 1000).toStringAsFixed(0)}k',
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: false,
        ),
        barGroups: barGroups,
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          horizontalInterval: _getMaxVolume(weeklyData) / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
      ),
    );
  }

  Widget _buildMonthlyVolumeChart(List<WeeklyVolumeData> weeklyData) {
    // Group weekly data into monthly data
    final monthlyData = _groupWeeklyDataByMonth(weeklyData);
    
    if (monthlyData.isEmpty) {
      return _buildEmptyChart('No monthly volume data available');
    }

    final lineSpots = monthlyData.asMap().entries.map((entry) {
      final index = entry.key;
      final volume = entry.value['volume'] as double;
      return FlSpot(index.toDouble(), volume);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _getMaxMonthlyVolume(monthlyData) / 5,
          getDrawingHorizontalLine: (value) {
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
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < monthlyData.length) {
                  final date = monthlyData[index]['date'] as DateTime;
                  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      months[date.month - 1],
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
              reservedSize: 40,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  '${(value / 1000).toStringAsFixed(0)}k',
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (monthlyData.length - 1).toDouble(),
        minY: 0,
        maxY: _getMaxMonthlyVolume(monthlyData) * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: lineSpots,
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
                if (index >= 0 && index < monthlyData.length) {
                  final data = monthlyData[index];
                  final date = data['date'] as DateTime;
                  final volume = data['volume'] as double;
                  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                  return LineTooltipItem(
                    '${volume.toStringAsFixed(0)}kg\n${months[date.month - 1]} ${date.year}',
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

  Widget _buildEmptyChart(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTopExercises(List<ExerciseVolumeData> exerciseVolume) {
    final topExercises = exerciseVolume.take(5).toList();
    
    if (topExercises.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Exercises by Volume',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...topExercises.asMap().entries.map((entry) {
          final index = entry.key;
          final exercise = entry.value;
          final percentage = exerciseVolume.isNotEmpty 
              ? (exercise.totalVolume / exerciseVolume.first.totalVolume) * 100
              : 0.0;
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _getExerciseColor(index),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.exerciseName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${exercise.totalSets} sets',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${exercise.totalVolume.toStringAsFixed(0)}kg',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  double _getMaxVolume(List<WeeklyVolumeData> data) {
    if (data.isEmpty) return 1000;
    return data.map((d) => d.volume).reduce((a, b) => a > b ? a : b);
  }

  double _getMaxMonthlyVolume(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 1000;
    return data.map((d) => d['volume'] as double).reduce((a, b) => a > b ? a : b);
  }

  List<Map<String, dynamic>> _groupWeeklyDataByMonth(List<WeeklyVolumeData> weeklyData) {
    final Map<String, double> monthlyVolume = {};
    
    for (final week in weeklyData) {
      final monthKey = '${week.weekStart.year}-${week.weekStart.month}';
      monthlyVolume[monthKey] = (monthlyVolume[monthKey] ?? 0) + week.volume;
    }
    
    return monthlyVolume.entries.map((entry) {
      final parts = entry.key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      
      return {
        'date': DateTime(year, month),
        'volume': entry.value,
      };
    }).toList()
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
  }

  Color _getExerciseColor(int index) {
    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
      Colors.orange,
      Colors.purple,
    ];
    return colors[index % colors.length];
  }
}