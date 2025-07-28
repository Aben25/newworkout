import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/analytics_provider.dart';
import '../widgets/analytics/analytics_summary_card.dart';
import '../widgets/analytics/progress_charts_widget.dart';
import '../widgets/analytics/workout_frequency_chart.dart';
import '../widgets/analytics/goal_progress_indicators.dart';
import '../widgets/analytics/calendar_heatmap_widget.dart';
import '../widgets/analytics/strength_progression_chart.dart';
import '../widgets/analytics/volume_tracking_chart.dart';
import '../widgets/analytics/exercise_progress_chart.dart';
import '../widgets/analytics/body_measurement_chart.dart';
import '../widgets/analytics/workout_rating_trends_chart.dart';

/// Progress dashboard screen with comprehensive analytics and visualizations
class ProgressDashboardScreen extends ConsumerStatefulWidget {
  const ProgressDashboardScreen({super.key});

  @override
  ConsumerState<ProgressDashboardScreen> createState() => _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends ConsumerState<ProgressDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Load analytics data on screen initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsNotifierProvider.notifier).loadAnalytics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isAnalyticsLoadingProvider);
    final error = ref.watch(analyticsErrorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              context.push('/workout-history');
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(analyticsNotifierProvider.notifier).refreshAnalytics();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Charts', icon: Icon(Icons.analytics)),
            Tab(text: 'Progress', icon: Icon(Icons.trending_up)),
            Tab(text: 'Goals', icon: Icon(Icons.flag)),
          ],
        ),
      ),
      body: error != null
          ? _buildErrorState(error)
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(isLoading),
                _buildChartsTab(isLoading),
                _buildProgressTab(isLoading),
                _buildGoalsTab(isLoading),
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
              'Failed to load progress data',
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
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(bool isLoading) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(analyticsNotifierProvider.notifier).refreshAnalytics();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Key metrics summary
            const AnalyticsSummaryCard(),
            const SizedBox(height: 16),
            
            // Consistency metrics
            const ConsistencyMetricsCard(),
            const SizedBox(height: 16),
            
            // Recent achievements
            const RecentAchievementsCard(),
            const SizedBox(height: 16),
            
            // Workout frequency heatmap
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Workout Frequency',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    const CalendarHeatmapWidget(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsTab(bool isLoading) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(analyticsNotifierProvider.notifier).refreshAnalytics();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Volume tracking chart
            const VolumeTrackingChart(),
            const SizedBox(height: 16),
            
            // Workout frequency chart
            const WorkoutFrequencyChart(),
            const SizedBox(height: 16),
            
            // Workout rating trends
            const WorkoutRatingTrendsChart(),
            const SizedBox(height: 16),
            
            // Body measurement chart
            const BodyMeasurementChart(),
          ],
        ),
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
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Strength progression chart
            const StrengthProgressionChart(),
            const SizedBox(height: 16),
            
            // Exercise progress chart
            const ExerciseProgressChart(),
            const SizedBox(height: 16),
            
            // Interactive progress charts
            const ProgressChartsWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsTab(bool isLoading) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(analyticsNotifierProvider.notifier).refreshAnalytics();
      },
      child: const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Goal progress indicators
            GoalProgressIndicators(),
          ],
        ),
      ),
    );
  }
}