import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/analytics_provider.dart';
import '../widgets/workout/workout_history_filters.dart';
import '../widgets/workout/workout_history_timeline.dart';
import '../widgets/analytics/strength_progression_chart.dart';
import '../widgets/analytics/volume_tracking_chart.dart';
import '../widgets/analytics/exercise_progress_chart.dart';
import '../widgets/analytics/workout_rating_trends_chart.dart';
import '../widgets/analytics/body_measurement_chart.dart';
import '../widgets/workout/workout_comparison_widget.dart';

/// Comprehensive workout history screen with advanced filtering and analytics
class WorkoutHistoryScreen extends ConsumerStatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  ConsumerState<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends ConsumerState<WorkoutHistoryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Filter state
  DateTimeRange? _dateFilter;
  String? _statusFilter;
  int? _ratingFilter;
  String? _exerciseFilter;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsNotifierProvider.notifier).loadAnalytics();
      _loadWorkoutHistory();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadWorkoutHistory() {
    // Load workout logs with current filters
    // This will be handled by the timeline widget
  }

  void _applyFilters({
    DateTimeRange? dateRange,
    String? status,
    int? rating,
    String? exercise,
  }) {
    setState(() {
      _dateFilter = dateRange;
      _statusFilter = status;
      _ratingFilter = rating;
      _exerciseFilter = exercise;
    });
    _loadWorkoutHistory();
  }

  void _clearFilters() {
    setState(() {
      _dateFilter = null;
      _statusFilter = null;
      _ratingFilter = null;
      _exerciseFilter = null;
    });
    _loadWorkoutHistory();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isAnalyticsLoadingProvider);
    final error = ref.watch(analyticsErrorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout History'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFiltersBottomSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(analyticsNotifierProvider.notifier).refreshAnalytics();
              _loadWorkoutHistory();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Timeline', icon: Icon(Icons.timeline)),
            Tab(text: 'Progress', icon: Icon(Icons.trending_up)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
            Tab(text: 'Compare', icon: Icon(Icons.compare_arrows)),
          ],
        ),
      ),
      body: error != null
          ? _buildErrorState(error)
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTimelineTab(isLoading),
                _buildProgressTab(isLoading),
                _buildAnalyticsTab(isLoading),
                _buildCompareTab(isLoading),
              ],
            ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load workout history',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ref.read(analyticsNotifierProvider.notifier).refreshAnalytics();
                _loadWorkoutHistory();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineTab(bool isLoading) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(analyticsNotifierProvider.notifier).refreshAnalytics();
        _loadWorkoutHistory();
      },
      child: Column(
        children: [
          // Active filters display
          if (_hasActiveFilters()) _buildActiveFiltersChips(),
          
          // Timeline view
          Expanded(
            child: WorkoutHistoryTimeline(
              dateFilter: _dateFilter,
              statusFilter: _statusFilter,
              ratingFilter: _ratingFilter,
              exerciseFilter: _exerciseFilter,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTab(bool isLoading) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(analyticsNotifierProvider.notifier).refreshAnalytics();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Strength progression charts
            Text(
              'Strength Progression',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const StrengthProgressionChart(),
            const SizedBox(height: 24),
            
            // Volume tracking
            Text(
              'Volume Tracking',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const VolumeTrackingChart(),
            const SizedBox(height: 24),
            
            // Exercise-specific progress
            Text(
              'Exercise Progress',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const ExerciseProgressChart(),
            const SizedBox(height: 24),
            
            // Body measurements
            Text(
              'Body Measurements',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const BodyMeasurementChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab(bool isLoading) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(analyticsNotifierProvider.notifier).refreshAnalytics();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Workout rating trends
            Text(
              'Workout Rating Trends',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const WorkoutRatingTrendsChart(),
            const SizedBox(height: 24),
            
            // Detailed analytics cards
            _buildAnalyticsCards(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompareTab(bool isLoading) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(analyticsNotifierProvider.notifier).refreshAnalytics();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WorkoutComparisonWidget(
              workouts: const [], // This would be populated with actual workout logs
              onSelected: (workout) {
                // Handle workout selection for comparison
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Selected workout: ${workout.id}')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFiltersChips() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: [
          if (_dateFilter != null)
            FilterChip(
              label: Text(
                '${_dateFilter!.start.day}/${_dateFilter!.start.month} - ${_dateFilter!.end.day}/${_dateFilter!.end.month}',
              ),
              selected: true,
              onSelected: (_) => _applyFilters(dateRange: null),
              onDeleted: () => _applyFilters(dateRange: null),
            ),
          if (_statusFilter != null)
            FilterChip(
              label: Text('Status: $_statusFilter'),
              selected: true,
              onSelected: (_) => _applyFilters(status: null),
              onDeleted: () => _applyFilters(status: null),
            ),
          if (_ratingFilter != null)
            FilterChip(
              label: Text('Rating: $_ratingFilter⭐'),
              selected: true,
              onSelected: (_) => _applyFilters(rating: null),
              onDeleted: () => _applyFilters(rating: null),
            ),
          if (_exerciseFilter != null)
            FilterChip(
              label: Text('Exercise: $_exerciseFilter'),
              selected: true,
              onSelected: (_) => _applyFilters(exercise: null),
              onDeleted: () => _applyFilters(exercise: null),
            ),
          if (_hasActiveFilters())
            ActionChip(
              label: const Text('Clear All'),
              onPressed: _clearFilters,
            ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCards() {
    final analytics = ref.watch(analyticsNotifierProvider).value;
    if (analytics == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Performance summary card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Performance Summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        'Total Workouts',
                        '${analytics.workoutFrequency.totalWorkouts}',
                        Icons.fitness_center,
                      ),
                    ),
                    Expanded(
                      child: _buildMetricTile(
                        'Total Volume',
                        '${analytics.volume.totalVolumeLifetime.toStringAsFixed(0)}kg',
                        Icons.trending_up,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        'Avg Rating',
                        '${analytics.progress.averageWorkoutRating.toStringAsFixed(1)}⭐',
                        Icons.star,
                      ),
                    ),
                    Expanded(
                      child: _buildMetricTile(
                        'Current Streak',
                        '${analytics.workoutFrequency.currentStreak} days',
                        Icons.local_fire_department,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Trends card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Trends',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildTrendTile(
                  'Volume Trend',
                  analytics.trends.volumeTrend,
                  'vs last month',
                ),
                _buildTrendTile(
                  'Frequency Trend',
                  analytics.trends.frequencyTrend,
                  'vs last month',
                ),
                _buildTrendTile(
                  'Duration Trend',
                  analytics.trends.durationTrend,
                  'vs last month',
                ),
                _buildTrendTile(
                  'Rating Trend',
                  analytics.trends.ratingTrend,
                  'vs last month',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTrendTile(String title, double trend, String subtitle) {
    final isPositive = trend > 0;
    final isNeutral = trend.abs() < 0.01;
    
    return ListTile(
      leading: Icon(
        isNeutral 
            ? Icons.trending_flat
            : isPositive 
                ? Icons.trending_up 
                : Icons.trending_down,
        color: isNeutral 
            ? Theme.of(context).colorScheme.onSurfaceVariant
            : isPositive 
                ? Colors.green 
                : Colors.red,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Text(
        isNeutral 
            ? 'No change'
            : '${isPositive ? '+' : ''}${(trend * 100).toStringAsFixed(1)}%',
        style: TextStyle(
          color: isNeutral 
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : isPositive 
                  ? Colors.green 
                  : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  bool _hasActiveFilters() {
    return _dateFilter != null || 
           _statusFilter != null || 
           _ratingFilter != null || 
           _exerciseFilter != null;
  }

  void _showFiltersBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => WorkoutHistoryFilters(
        currentDateFilter: _dateFilter,
        currentStatusFilter: _statusFilter,
        currentRatingFilter: _ratingFilter,
        currentExerciseFilter: _exerciseFilter,
        onFiltersApplied: _applyFilters,
        onFiltersCleared: _clearFilters,
      ),
    );
  }
}