import 'package:flutter/material.dart';
import '../../models/models.dart';

class WorkoutCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback? onTap;
  final VoidCallback? onStart;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const WorkoutCard({
    super.key,
    required this.workout,
    this.onTap,
    this.onStart,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and menu
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workout.name ?? 'Untitled Workout',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (workout.hasDescription) ...[
                          const SizedBox(height: 4),
                          Text(
                            workout.description!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Delete', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Workout stats
              Row(
                children: [
                  _buildStatChip(
                    icon: Icons.timer_outlined,
                    label: workout.formattedDuration,
                    theme: theme,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    icon: Icons.fitness_center,
                    label: 'Exercises', // TODO: Get actual exercise count
                    theme: theme,
                  ),
                  const SizedBox(width: 8),
                  if (workout.hasRating) ...[
                    _buildStatChip(
                      icon: Icons.star,
                      label: '${workout.rating}/5',
                      theme: theme,
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Status and actions
              Row(
                children: [
                  // Status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(theme).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(theme).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(),
                          size: 16,
                          color: _getStatusColor(theme),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusText(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _getStatusColor(theme),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Action buttons
                  if (workout.canResume) ...[
                    TextButton.icon(
                      onPressed: onStart,
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Resume'),
                    ),
                  ] else ...[
                    TextButton.icon(
                      onPressed: onStart,
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Start'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ThemeData theme) {
    if (workout.isInProgress) {
      return theme.colorScheme.primary;
    } else if (workout.isFinished) {
      return Colors.green;
    } else if (workout.isPaused) {
      return Colors.orange;
    } else {
      return theme.colorScheme.onSurfaceVariant;
    }
  }

  IconData _getStatusIcon() {
    if (workout.isInProgress) {
      return Icons.play_circle;
    } else if (workout.isFinished) {
      return Icons.check_circle;
    } else if (workout.isPaused) {
      return Icons.pause_circle;
    } else {
      return Icons.radio_button_unchecked;
    }
  }

  String _getStatusText() {
    if (workout.isInProgress) {
      return 'In Progress';
    } else if (workout.isFinished) {
      return 'Completed';
    } else if (workout.isPaused) {
      return 'Paused';
    } else {
      return 'Ready';
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        onEdit?.call();
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }
}