import 'package:flutter/material.dart';
import '../../screens/workout_builder_screen.dart';

class WorkoutBuilderExerciseCard extends StatelessWidget {
  final WorkoutBuilderExercise exercise;
  final int exerciseNumber;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final VoidCallback onDuplicate;

  const WorkoutBuilderExerciseCard({
    super.key,
    required this.exercise,
    required this.exerciseNumber,
    required this.onTap,
    required this.onEdit,
    required this.onRemove,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with exercise number, name, and actions
              Row(
                children: [
                  // Drag handle
                  Icon(
                    Icons.drag_handle,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  
                  // Exercise number
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        exerciseNumber.toString(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Exercise name and details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.exercise.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (exercise.exercise.primaryMuscle != null) ...[
                              Icon(
                                Icons.fitness_center,
                                size: 14,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                exercise.exercise.primaryMuscle!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                            if (exercise.exercise.equipment != null) ...[
                              const SizedBox(width: 12),
                              Icon(
                                Icons.build,
                                size: 14,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                exercise.exercise.equipment!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Action menu
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleAction(value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit Sets/Reps'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: ListTile(
                          leading: Icon(Icons.copy),
                          title: Text('Duplicate'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'remove',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Remove', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                    child: Icon(
                      Icons.more_vert,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Exercise configuration
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // Sets and reps
                    Expanded(
                      child: _buildConfigItem(
                        context,
                        icon: Icons.repeat,
                        label: 'Sets × Reps',
                        value: exercise.formattedSetsReps,
                      ),
                    ),
                    
                    Container(
                      width: 1,
                      height: 40,
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                    
                    // Weight
                    Expanded(
                      child: _buildConfigItem(
                        context,
                        icon: Icons.fitness_center,
                        label: 'Weight',
                        value: exercise.formattedWeight,
                      ),
                    ),
                    
                    Container(
                      width: 1,
                      height: 40,
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                    
                    // Rest time
                    Expanded(
                      child: _buildConfigItem(
                        context,
                        icon: Icons.timer,
                        label: 'Rest',
                        value: '${exercise.restInterval}s',
                      ),
                    ),
                  ],
                ),
              ),
              
              // Notes (if any)
              if (exercise.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          exercise.notes,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Volume indicator (if weight is specified)
              if (exercise.weight != null && exercise.totalVolume > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Total Volume: ${exercise.totalVolume.toStringAsFixed(1)}kg',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfigItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _handleAction(String action) {
    switch (action) {
      case 'edit':
        onEdit();
        break;
      case 'duplicate':
        onDuplicate();
        break;
      case 'remove':
        onRemove();
        break;
    }
  }
}