import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/set_logging_service.dart';
import '../../utils/app_theme.dart';

/// Rest period analysis widget for optimization
/// Provides insights into rest time patterns and recommendations
class RestPeriodAnalysisWidget extends StatefulWidget {
  final String exerciseId;
  final String userId;
  final RestPeriodAnalysis? analysis;
  final Function(int seconds)? onRestTimeSelected;

  const RestPeriodAnalysisWidget({
    super.key,
    required this.exerciseId,
    required this.userId,
    this.analysis,
    this.onRestTimeSelected,
  });

  @override
  State<RestPeriodAnalysisWidget> createState() => _RestPeriodAnalysisWidgetState();
}

class _RestPeriodAnalysisWidgetState extends State<RestPeriodAnalysisWidget>
    with TickerProviderStateMixin {
  late AnimationController _chartController;
  late AnimationController _recommendationController;
  late Animation<double> _chartAnimation;
  late Animation<double> _recommendationAnimation;

  RestPeriodAnalysis? _analysis;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _analysis = widget.analysis;
    
    if (_analysis == null) {
      _loadAnalysis();
    } else {
      _startAnimations();
    }
  }

  void _initializeAnimations() {
    _chartController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _recommendationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _chartAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _chartController,
      curve: Curves.easeOutCubic,
    ));

    _recommendationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _recommendationController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    _chartController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _recommendationController.forward();
    });
  }

  void _loadAnalysis() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final setLoggingService = SetLoggingService.instance;
      final analysis = await setLoggingService.getRestPeriodAnalysis(
        exerciseId: widget.exerciseId,
        userId: widget.userId,
      );

      if (mounted) {
        setState(() {
          _analysis = analysis;
          _isLoading = false;
        });
        _startAnimations();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _chartController.dispose();
    _recommendationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_analysis == null) {
      return _buildErrorWidget();
    }

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
            
            // Rest time metrics
            _buildRestTimeMetrics(),
            
            const SizedBox(height: 16),
            
            // Rest time visualization
            _buildRestTimeVisualization(),
            
            const SizedBox(height: 16),
            
            // Recommendations
            _buildRecommendations(),
            
            const SizedBox(height: 16),
            
            // Quick rest time selectors
            _buildQuickSelectors(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Analyzing rest periods...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load rest period analysis',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAnalysis,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.timer,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rest Period Analysis',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Optimize your recovery time',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity( 0.7),
                ),
              ),
            ],
          ),
        ),
        // Refresh button
        IconButton(
          onPressed: _loadAnalysis,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh analysis',
        ),
      ],
    );
  }

  Widget _buildRestTimeMetrics() {
    final analysis = _analysis!;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              'Average Rest',
              _formatTime(analysis.averageRestTime),
              Icons.access_time,
              AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricCard(
              'Optimal Rest',
              _formatTime(analysis.optimalRestTime),
              Icons.my_location,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricCard(
              'Consistency',
              _getConsistencyRating(analysis.restTimeVariability),
              Icons.trending_flat,
              _getConsistencyColor(analysis.restTimeVariability),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
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

  Widget _buildRestTimeVisualization() {
    final analysis = _analysis!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rest Time Distribution',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        SizedBox(
          height: 120,
          child: AnimatedBuilder(
            animation: _chartAnimation,
            builder: (context, child) {
              return _buildRestTimeChart();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRestTimeChart() {
    final analysis = _analysis!;
    
    // Create data points for visualization
    final dataPoints = [
      RestTimeDataPoint(30, 0.1, 'Too Short'),
      RestTimeDataPoint(60, 0.3, 'Standard'),
      RestTimeDataPoint(analysis.averageRestTime, 0.8, 'Your Average'),
      RestTimeDataPoint(analysis.optimalRestTime, 1.0, 'Optimal'),
      RestTimeDataPoint(120, 0.6, 'Extended'),
      RestTimeDataPoint(180, 0.2, 'Long'),
    ];

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatTime(value.toInt()),
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
              interval: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${(value * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: dataPoints.map((point) => FlSpot(
              point.time.toDouble(),
              point.performance * _chartAnimation.value,
            )).toList(),
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final point = dataPoints[index];
                Color color = Theme.of(context).colorScheme.primary;
                
                if (point.time == analysis.optimalRestTime) {
                  color = Colors.green;
                } else if (point.time == analysis.averageRestTime) {
                  color = Colors.orange;
                }
                
                return FlDotCirclePainter(
                  radius: 4,
                  color: color,
                  strokeColor: Colors.white,
                  strokeWidth: 2,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).colorScheme.primary.withOpacity( 0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final point = dataPoints[spot.spotIndex];
                return LineTooltipItem(
                  '${point.label}\n${_formatTime(point.time)}\n${(point.performance * 100).toInt()}% effectiveness',
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    final analysis = _analysis!;
    
    return AnimatedBuilder(
      animation: _recommendationAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _recommendationAnimation.value,
          child: Container(
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
                      Icons.lightbulb,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recommendations',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                ...analysis.recommendations.map((recommendation) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          recommendation,
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
      },
    );
  }

  Widget _buildQuickSelectors() {
    final analysis = _analysis!;
    final quickTimes = [30, 60, 90, 120, analysis.optimalRestTime];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Rest Time Selection',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: quickTimes.toSet().map((time) {
            final isOptimal = time == analysis.optimalRestTime;
            final isAverage = time == analysis.averageRestTime;
            
            return ActionChip(
              label: Text(_formatTime(time)),
              onPressed: () => widget.onRestTimeSelected?.call(time),
              backgroundColor: isOptimal
                  ? Colors.green.withOpacity( 0.2)
                  : isAverage
                      ? Colors.orange.withOpacity( 0.2)
                      : null,
              side: BorderSide(
                color: isOptimal
                    ? Colors.green
                    : isAverage
                        ? Colors.orange
                        : Colors.transparent,
              ),
              avatar: isOptimal
                  ? const Icon(Icons.star, size: 16, color: Colors.green)
                  : isAverage
                      ? const Icon(Icons.access_time, size: 16, color: Colors.orange)
                      : null,
            );
          }).toList(),
        ),
      ],
    );
  }

  // Helper methods

  String _formatTime(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      if (remainingSeconds == 0) {
        return '${minutes}m';
      } else {
        return '${minutes}m ${remainingSeconds}s';
      }
    }
  }

  String _getConsistencyRating(double variability) {
    if (variability < 15) return 'Excellent';
    if (variability < 30) return 'Good';
    if (variability < 45) return 'Fair';
    return 'Poor';
  }

  Color _getConsistencyColor(double variability) {
    if (variability < 15) return Colors.green;
    if (variability < 30) return Colors.lightGreen;
    if (variability < 45) return Colors.orange;
    return Colors.red;
  }
}

// Helper class for rest time data points
class RestTimeDataPoint {
  final int time;
  final double performance;
  final String label;

  const RestTimeDataPoint(this.time, this.performance, this.label);
}