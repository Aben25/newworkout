import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/analytics_provider.dart';
import 'workout_history_item.dart';

/// Timeline view of workout history with expandable details
class WorkoutHistoryTimeline extends ConsumerStatefulWidget {
  final DateTimeRange? dateFilter;
  final String? statusFilter;
  final int? ratingFilter;
  final String? exerciseFilter;

  const WorkoutHistoryTimeline({
    super.key,
    this.dateFilter,
    this.statusFilter,
    this.ratingFilter,
    this.exerciseFilter,
  });

  @override
  ConsumerState<WorkoutHistoryTimeline> createState() => _WorkoutHistoryTimelineState();
}

class _WorkoutHistoryTimelineState extends ConsumerState<WorkoutHistoryTimeline> {
  final ScrollController _scrollController = ScrollController();
  final Set<String> _expandedItems = <String>{};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Create filter parameters
    final filters = WorkoutLogFilters(
      dateFilter: widget.dateFilter,
      statusFilter: widget.statusFilter,
      ratingFilter: widget.ratingFilter,
      exerciseFilter: widget.exerciseFilter,
    );

    return Consumer(
      builder: (context, ref, child) {
        // Get filtered workout logs using the provider
        final workoutLogsAsync = ref.watch(filteredWorkoutLogsProvider(filters));
        
        return workoutLogsAsync.when(
          data: (workoutLogs) {
            if (workoutLogs.isEmpty) {
              return _buildEmptyState();
            }

            // Group workouts by date
            final groupedWorkouts = _groupWorkoutsByDate(workoutLogs);

            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: groupedWorkouts.length,
              itemBuilder: (context, index) {
                final entry = groupedWorkouts.entries.elementAt(index);
                final date = entry.key;
                final workouts = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date header
                    _buildDateHeader(date, workouts.length),
                    const SizedBox(height: 8),
                    
                    // Workouts for this date
                    ...workouts.map((workout) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: WorkoutHistoryItem(
                        workoutLog: workout,
                        isExpanded: _expandedItems.contains(workout.id),
                        onToggleExpanded: () => _toggleExpanded(workout.id),
                      ),
                    )),
                    
                    const SizedBox(height: 16),
                  ],
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
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
                  'Failed to load workout history',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(filteredWorkoutLogsProvider(filters)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No workout history found',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.dateFilter != null || 
              widget.statusFilter != null || 
              widget.ratingFilter != null || 
              widget.exerciseFilter != null
                  ? 'Try adjusting your filters to see more results'
                  : 'Start working out to see your history here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(DateTime date, int workoutCount) {
    final isToday = _isToday(date);
    final isYesterday = _isYesterday(date);
    
    String dateText;
    if (isToday) {
      dateText = 'Today';
    } else if (isYesterday) {
      dateText = 'Yesterday';
    } else {
      dateText = _formatDate(date);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            dateText,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$workoutCount',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }



  Map<DateTime, List<WorkoutLog>> _groupWorkoutsByDate(List<WorkoutLog> workouts) {
    final Map<DateTime, List<WorkoutLog>> grouped = {};
    
    for (final workout in workouts) {
      final date = workout.completedAt ?? workout.startedAt ?? workout.createdAt;
      final dateOnly = DateTime(date.year, date.month, date.day);
      
      if (grouped.containsKey(dateOnly)) {
        grouped[dateOnly]!.add(workout);
      } else {
        grouped[dateOnly] = [workout];
      }
    }
    
    // Sort by date (most recent first)
    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    
    return Map.fromEntries(sortedEntries);
  }

  void _toggleExpanded(String workoutId) {
    setState(() {
      if (_expandedItems.contains(workoutId)) {
        _expandedItems.remove(workoutId);
      } else {
        _expandedItems.add(workoutId);
      }
    });
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && 
           date.month == yesterday.month && 
           date.day == yesterday.day;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference < 7) {
      // Show day of week for recent dates
      const weekdays = [
        'Monday', 'Tuesday', 'Wednesday', 'Thursday', 
        'Friday', 'Saturday', 'Sunday'
      ];
      return weekdays[date.weekday - 1];
    } else {
      // Show full date for older dates
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}';
    }
  }
}