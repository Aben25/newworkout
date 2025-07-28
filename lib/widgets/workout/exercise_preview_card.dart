import 'package:flutter/material.dart';
import '../../models/models.dart';

class ExercisePreviewCard extends StatelessWidget {
  final Exercise exercise;
  final WorkoutExercise workoutExercise;
  final int exerciseNumber;
  final VoidCallback? onTap;
  final VoidCallback? onPreview;

  const ExercisePreviewCard({
    super.key,
    required this.exercise,
    required this.workoutExercise,
    required this.exerciseNumber,
    this.onTap,
    this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Exercise number
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    exerciseNumber.toString(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Exercise info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (exercise.primaryMuscle != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              exercise.primaryMuscle!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (exercise.equipment != null) ...[
                          Icon(
                            _getEquipmentIcon(exercise.equipment!),
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            exercise.equipment!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Sets and reps info
                    Row(
                      children: [
                        _buildInfoChip(
                          icon: Icons.repeat,
                          text: '${workoutExercise.effectiveSets} sets',
                          theme: theme,
                        ),
                        const SizedBox(width: 8),
                        if (workoutExercise.reps != null && workoutExercise.reps!.isNotEmpty) ...[
                          _buildInfoChip(
                            icon: Icons.fitness_center,
                            text: '${workoutExercise.reps!.first} reps',
                            theme: theme,
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (workoutExercise.restInterval != null) ...[
                          _buildInfoChip(
                            icon: Icons.timer,
                            text: '${workoutExercise.restInterval}s rest',
                            theme: theme,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Action buttons
              Column(
                children: [
                  if (exercise.hasVideo) ...[
                    IconButton(
                      onPressed: onPreview,
                      icon: const Icon(Icons.play_circle_outline),
                      tooltip: 'Preview Exercise',
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.5),
                        foregroundColor: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ] else ...[
                    IconButton(
                      onPressed: onTap,
                      icon: const Icon(Icons.info_outline),
                      tooltip: 'Exercise Info',
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        foregroundColor: theme.colorScheme.onSurfaceVariant,
                      ),
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

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 2),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getEquipmentIcon(String equipment) {
    switch (equipment.toLowerCase()) {
      case 'dumbbells':
      case 'dumbbell':
        return Icons.fitness_center;
      case 'barbell':
        return Icons.fitness_center;
      case 'kettlebell':
        return Icons.sports_gymnastics;
      case 'resistance bands':
      case 'resistance band':
        return Icons.linear_scale;
      case 'pull-up bar':
      case 'pullup bar':
        return Icons.horizontal_rule;
      case 'bench':
        return Icons.weekend;
      case 'cable machine':
        return Icons.settings_input_component;
      case 'bodyweight':
      case 'none':
        return Icons.accessibility;
      default:
        return Icons.fitness_center;
    }
  }
}