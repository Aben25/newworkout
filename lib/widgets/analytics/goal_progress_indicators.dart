import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/analytics_provider.dart';

/// Goal progress indicators with animated progress bars and visual feedback
class GoalProgressIndicators extends ConsumerStatefulWidget {
  const GoalProgressIndicators({super.key});

  @override
  ConsumerState<GoalProgressIndicators> createState() => _GoalProgressIndicatorsState();
}

class _GoalProgressIndicatorsState extends ConsumerState<GoalProgressIndicators>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _progressAnimation = CurvedAnimation(
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
    final consistencyMetrics = ref.watch(consistencyMetricsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Goal Progress',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        
        // Weekly workout goal
        _buildGoalCard(
          title: 'Weekly Workouts',
          current: workoutFrequency?.workoutsThisWeek ?? 0,
          target: 4, // Default target of 4 workouts per week
          unit: 'workouts',
          icon: Icons.fitness_center,
          color: Theme.of(context).colorScheme.primary,
        ),
        
        const SizedBox(height: 16),
        
        // Consistency goal
        _buildGoalCard(
          title: 'Consistency Score',
          current: ((consistencyMetrics['consistency_score'] as double) * 100).round(),
          target: 80, // Target 80% consistency
          unit: '%',
          icon: Icons.trending_up,
          color: Theme.of(context).colorScheme.secondary,
          isPercentage: true,
        ),
        
        const SizedBox(height: 16),
        
        // Volume goal
        _buildGoalCard(
          title: 'Weekly Volume',
          current: (volumeAnalytics?.totalVolumeThisWeek ?? 0).round(),
          target: 5000, // Target 5000kg per week
          unit: 'kg',
          icon: Icons.fitness_center,
          color: Theme.of(context).colorScheme.tertiary,
        ),
        
        const SizedBox(height: 16),
        
        // Streak goal
        _buildGoalCard(
          title: 'Current Streak',
          current: workoutFrequency?.currentStreak ?? 0,
          target: 7, // Target 7-day streak
          unit: 'days',
          icon: Icons.local_fire_department,
          color: Colors.orange,
        ),
        
        const SizedBox(height: 24),
        
        // Achievement summary
        _buildAchievementSummary(),
      ],
    );
  }

  Widget _buildGoalCard({
    required String title,
    required int current,
    required int target,
    required String unit,
    required IconData icon,
    required Color color,
    bool isPercentage = false,
  }) {
    final progress = (current / target).clamp(0.0, 1.0);
    final isCompleted = current >= target;
    
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity( 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$current / $target $unit',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity( 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Complete',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Progress bar
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      height: 8,
                      width: MediaQuery.of(context).size.width * 0.8 * progress * _progressAnimation.value,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isCompleted 
                              ? [Colors.green, Colors.lightGreen]
                              : [color, color.withOpacity( 0.7)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Progress percentage
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(progress * 100).toInt()}% complete',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (!isCompleted)
                      Text(
                        '${target - current} $unit to go',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAchievementSummary() {
    final achievementSummary = ref.watch(achievementSummaryProvider);
    final recentPRs = ref.watch(recentPersonalRecordsProvider);
    final recentMilestones = ref.watch(recentMilestonesProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: Colors.amber,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recent Achievements',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (achievementSummary['has_recent_achievements'] as bool) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildAchievementItem(
                      'Personal Records',
                      recentPRs.length,
                      Icons.trending_up,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildAchievementItem(
                      'Milestones',
                      recentMilestones.length,
                      Icons.flag,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Recent achievements list
              if (recentPRs.isNotEmpty) ...[
                Text(
                  'Latest Personal Records:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                ...recentPRs.take(3).map((pr) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${pr.exerciseName}: ${pr.formattedValue}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ] else ...[
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No recent achievements',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'Keep working out to earn achievements!',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementItem(String title, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity( 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity( 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
}