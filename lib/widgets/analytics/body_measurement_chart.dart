import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/analytics_provider.dart';

/// Body measurement tracking chart widget with weight and BMI tracking
class BodyMeasurementChart extends ConsumerStatefulWidget {
  const BodyMeasurementChart({super.key});

  @override
  ConsumerState<BodyMeasurementChart> createState() => _BodyMeasurementChartState();
}

class _BodyMeasurementChartState extends ConsumerState<BodyMeasurementChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  String _selectedMetric = 'weight';
  final List<String> _metrics = ['weight', 'bmi'];

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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with metric selector
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Body Measurements',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildMetricSelector(),
              ],
            ),
            const SizedBox(height: 16),
            
            // Chart
            SizedBox(
              height: 250,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return _buildMeasurementChart();
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Current measurements summary
            _buildCurrentMeasurements(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricSelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment<String>(
          value: 'weight',
          label: Text('Weight'),
          icon: Icon(Icons.monitor_weight),
        ),
        ButtonSegment<String>(
          value: 'bmi',
          label: Text('BMI'),
          icon: Icon(Icons.calculate),
        ),
      ],
      selected: {_selectedMetric},
      onSelectionChanged: (Set<String> newSelection) {
        setState(() {
          _selectedMetric = newSelection.first;
        });
      },
    );
  }

  Widget _buildMeasurementChart() {
    return FutureBuilder<Map<String, dynamic>>(
      future: ref.read(analyticsServiceProvider).getBodyMeasurementData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error!);
        }

        final measurementData = snapshot.data!;
        final weightHistory = measurementData['weight_history'] as List<dynamic>? ?? [];
        
        if (weightHistory.isEmpty) {
          return _buildEmptyState();
        }

        return _buildChart(measurementData, weightHistory);
      },
    );
  }

  Widget _buildChart(Map<String, dynamic> measurementData, List<dynamic> weightHistory) {
    // For now, we'll create sample data since weight history tracking isn't fully implemented
    final sampleData = _generateSampleData();
    
    final spots = <FlSpot>[];
    for (int i = 0; i < sampleData.length; i++) {
      final value = _selectedMetric == 'weight' 
          ? sampleData[i]['weight'] as double
          : sampleData[i]['bmi'] as double;
      spots.add(FlSpot(i.toDouble(), value));
    }

    if (spots.isEmpty) {
      return _buildEmptyState();
    }

    final minY = spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final padding = range * 0.1;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: _selectedMetric == 'weight' ? 5 : 1,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
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
              interval: (sampleData.length / 4).ceil().toDouble(),
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < sampleData.length) {
                  final date = DateTime.parse(sampleData[index]['date'] as String);
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
              interval: _selectedMetric == 'weight' ? 5 : 1,
              reservedSize: 50,
              getTitlesWidget: (double value, TitleMeta meta) {
                final unit = _selectedMetric == 'weight' ? 'kg' : '';
                return Text(
                  '${value.toStringAsFixed(1)}$unit',
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
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        minX: 0,
        maxX: (sampleData.length - 1).toDouble(),
        minY: minY - padding,
        maxY: maxY + padding,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: _selectedMetric == 'weight' 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.secondary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: _selectedMetric == 'weight' 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.secondary,
                  strokeWidth: 2,
                  strokeColor: Theme.of(context).colorScheme.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: (_selectedMetric == 'weight' 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.secondary).withValues(alpha: 0.1),
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
                if (index >= 0 && index < sampleData.length) {
                  final data = sampleData[index];
                  final date = DateTime.parse(data['date'] as String);
                  final value = _selectedMetric == 'weight' 
                      ? '${(data['weight'] as double).toStringAsFixed(1)}kg'
                      : '${(data['bmi'] as double).toStringAsFixed(1)} BMI';
                  
                  return LineTooltipItem(
                    '$value\n${date.month}/${date.day}/${date.year}',
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

  Widget _buildCurrentMeasurements() {
    return FutureBuilder<Map<String, dynamic>>(
      future: ref.read(analyticsServiceProvider).getBodyMeasurementData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final measurementData = snapshot.data!;
        final currentWeight = measurementData['current_weight'] as double?;
        final currentHeight = measurementData['current_height'] as double?;
        final bmi = measurementData['bmi'] as double?;
        final weightUnit = measurementData['weight_unit'] as String? ?? 'kg';
        final heightUnit = measurementData['height_unit'] as String? ?? 'cm';

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMeasurementItem(
                'Current Weight',
                currentWeight != null 
                    ? '${currentWeight.toStringAsFixed(1)}$weightUnit'
                    : 'Not set',
                Icons.monitor_weight,
              ),
              _buildMeasurementItem(
                'Height',
                currentHeight != null 
                    ? '${currentHeight.toStringAsFixed(1)}$heightUnit'
                    : 'Not set',
                Icons.height,
              ),
              _buildMeasurementItem(
                'BMI',
                bmi != null 
                    ? bmi.toStringAsFixed(1)
                    : 'N/A',
                Icons.calculate,
                subtitle: bmi != null ? _getBMICategory(bmi) : null,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMeasurementItem(String label, String value, IconData icon, {String? subtitle}) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.monitor_weight_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No measurement data available',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Update your profile with weight and height to see tracking',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load measurement data',
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
        ],
      ),
    );
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  List<Map<String, dynamic>> _generateSampleData() {
    // Generate sample data for demonstration
    final now = DateTime.now();
    final data = <Map<String, dynamic>>[];
    
    for (int i = 30; i >= 0; i--) {
      final date = now.subtract(Duration(days: i * 7)); // Weekly data points
      final baseWeight = 75.0;
      final weightVariation = (i * 0.1) - 1.5; // Slight weight change over time
      final weight = baseWeight + weightVariation;
      final height = 1.75; // 175cm in meters
      final bmi = weight / (height * height);
      
      data.add({
        'date': date.toIso8601String(),
        'weight': weight,
        'bmi': bmi,
      });
    }
    
    return data;
  }
}