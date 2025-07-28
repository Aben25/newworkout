import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import 'workout_set_breakdown.dart';

/// Individual workout history item with expandable details
class WorkoutHistoryItem extends ConsumerWidget {
  final WorkoutLog workoutLog;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;

  const WorkoutHistoryItem({
    super.key,
    required this.workoutLog,
    required this.isExpanded,
    required this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          // Main workout info
          InkWell(
            onTap: onToggleExpanded,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Header row
                  Row(
                    children: [
                      // Status indicator
                      _buildStatusIndicator(context),
                      const SizedBox(width: 12),
                      
                      // Workout info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getWorkoutTitle(),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getWorkoutSubtitle(),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Rating and expand icon
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (workoutLog.hasRating)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${workoutLog.rating}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          const SizedBox(height: 4),
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Quick stats row
                  Row(
                    children: [
                      _buildQuickStat(
                        context,
                        Icons.schedule,
                        workoutLog.formattedDuration,
                      ),
                      const SizedBox(width: 16),
                      _buildQuickStat(
                        context,
                        Icons.fitness_center,
                        _getExerciseCount(),
                      ),
                      const SizedBox(width: 16),
                      _buildQuickStat(
                        context,
                        Icons.trending_up,
                        _getVolumeInfo(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Expanded details
          if (isExpanded) _buildExpandedDetails(context, ref),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    final status = workoutLog.workoutStatus;
    Color color;
    IconData icon;
    
    switch (status) {
      case WorkoutStatus.completed:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case WorkoutStatus.inProgress:
        color = Colors.orange;
        icon = Icons.play_circle;
        break;
      case WorkoutStatus.cancelled:
        color = Colors.red;
        icon = Icons.cancel;
        break;
      case WorkoutStatus.paused:
        color = Colors.blue;
        icon = Icons.pause_circle;
        break;
      default:
        color = Theme.of(context).colorScheme.onSurfaceVariant;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }

  Widget _buildQuickStat(BuildContext context, IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedDetails(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Detailed stats
          _buildDetailedStats(context),
          
          if (workoutLog.hasNotes) ...[
            const SizedBox(height: 16),
            _buildNotesSection(context),
          ],
          
          const SizedBox(height: 16),
          
          // Set-by-set breakdown
          _buildSetBreakdown(context, ref),
          
          const SizedBox(height: 16),
          
          // Action buttons
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildDetailedStats(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Workout Details',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Duration',
                workoutLog.formattedDuration,
                Icons.schedule,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                context,
                'Status',
                workoutLog.statusDisplayName,
                Icons.info_outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Started',
                _formatTime(workoutLog.startedAt),
                Icons.play_arrow,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                context,
                'Ended',
                _formatTime(workoutLog.endedAt),
                Icons.stop,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
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
        ],
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            workoutLog.notes ?? '',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildSetBreakdown(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exercise Breakdown',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        WorkoutSetBreakdown(workoutLogId: workoutLog.id),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _shareWorkout(context),
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _repeatWorkout(context),
            icon: const Icon(Icons.repeat),
            label: const Text('Repeat'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _viewDetails(context),
            icon: const Icon(Icons.visibility),
            label: const Text('View'),
          ),
        ),
      ],
    );
  }

  String _getWorkoutTitle() {
    // This would typically get the workout name from the workout data
    return 'Workout ${workoutLog.id.substring(0, 8)}';
  }

  String _getWorkoutSubtitle() {
    final date = workoutLog.completedAt ?? workoutLog.startedAt ?? workoutLog.createdAt;
    return _formatDateTime(date);
  }

  String _getExerciseCount() {
    // This would be calculated from the actual workout data
    return '5 exercises'; // Placeholder
  }

  String _getVolumeInfo() {
    // This would be calculated from the actual set data
    return '1.2k kg'; // Placeholder
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$displayHour:$minute $period';
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return _formatDateTime(dateTime);
  }

  void _shareWorkout(BuildContext context) {
    // Implement workout sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }

  void _repeatWorkout(BuildContext context) {
    // Implement repeat workout functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Repeat workout functionality coming soon')),
    );
  }

  void _viewDetails(BuildContext context) {
    // Navigate to detailed workout view
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Detailed view coming soon')),
    );
  }
}