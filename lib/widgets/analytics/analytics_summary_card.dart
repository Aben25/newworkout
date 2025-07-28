import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/analytics_provider.dart';

/// A card widget that displays key analytics metrics
class AnalyticsSummaryCard extends ConsumerWidget {
  const AnalyticsSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpis = ref.watch(keyPerformanceIndicatorsProvider);
    final isLoading = ref.watch(isAnalyticsLoadingProvider);
    final error = ref.watch(analyticsErrorProvider);

    if (isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 8),
              Text(
                'Failed to load analytics',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(analyticsNotifierProvider.notifier).refreshAnalytics();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Analytics Summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    ref.read(analyticsNotifierProvider.notifier).refreshAnalytics();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMetricsGrid(context, kpis),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, Map<String, dynamic> kpis) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        _buildMetricTile(
          context,
          'Total Workouts',
          '${kpis['total_workouts']}',
          Icons.fitness_center,
          Colors.blue,
        ),
        _buildMetricTile(
          context,
          'Current Streak',
          '${kpis['current_streak']} days',
          Icons.local_fire_department,
          Colors.orange,
        ),
        _buildMetricTile(
          context,
          'Total Volume',
          '${(kpis['total_volume'] as double).toStringAsFixed(0)}kg',
          Icons.trending_up,
          Colors.green,
        ),
        _buildMetricTile(
          context,
          'Avg Rating',
          '${(kpis['average_rating'] as double).toStringAsFixed(1)}/5',
          Icons.star,
          Colors.amber,
        ),
        _buildMetricTile(
          context,
          'This Week',
          '${kpis['workouts_this_week']} workouts',
          Icons.calendar_today,
          Colors.purple,
        ),
        _buildMetricTile(
          context,
          'Consistency',
          '${((kpis['consistency_score'] as double) * 100).toStringAsFixed(0)}%',
          Icons.check_circle,
          Colors.teal,
        ),
      ],
    );
  }

  Widget _buildMetricTile(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity( 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity( 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Flexible(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// A widget that displays consistency metrics
class ConsistencyMetricsCard extends ConsumerWidget {
  const ConsistencyMetricsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consistencyMetrics = ref.watch(consistencyMetricsProvider);
    final isLoading = ref.watch(isAnalyticsLoadingProvider);

    if (isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final score = consistencyMetrics['consistency_score'] as double;
    final status = consistencyMetrics['status'] as String;
    final currentStreak = consistencyMetrics['current_streak'] as int;
    final longestStreak = consistencyMetrics['longest_streak'] as int;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workout Consistency',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Consistency Score',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${(score * 100).toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: _getConsistencyColor(score),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getConsistencyColor(score).withOpacity( 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _getConsistencyColor(score),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: score,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(_getConsistencyColor(score)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStreakInfo(
                    context,
                    'Current Streak',
                    '$currentStreak days',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStreakInfo(
                    context,
                    'Longest Streak',
                    '$longestStreak days',
                    Icons.emoji_events,
                    Colors.amber,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakInfo(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity( 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getConsistencyColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.lightGreen;
    if (score >= 0.4) return Colors.orange;
    if (score >= 0.2) return Colors.deepOrange;
    return Colors.red;
  }
}

/// A widget that displays recent achievements
class RecentAchievementsCard extends ConsumerWidget {
  const RecentAchievementsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentPRs = ref.watch(recentPersonalRecordsProvider);
    final recentMilestones = ref.watch(recentMilestonesProvider);
    final isLoading = ref.watch(isAnalyticsLoadingProvider);

    if (isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final hasAchievements = recentPRs.isNotEmpty || recentMilestones.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Achievements',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (!hasAchievements)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No recent achievements',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      'Keep working out to earn achievements!',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  if (recentPRs.isNotEmpty) ...[
                    _buildAchievementSection(
                      context,
                      'Personal Records',
                      recentPRs.length,
                      Icons.trending_up,
                      Colors.green,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (recentMilestones.isNotEmpty) ...[
                    _buildAchievementSection(
                      context,
                      'Milestones',
                      recentMilestones.length,
                      Icons.emoji_events,
                      Colors.amber,
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementSection(
    BuildContext context,
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity( 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity( 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '$count new in the last 30 days',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}