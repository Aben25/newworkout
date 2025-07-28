import 'package:flutter/material.dart';

class WorkoutStatsCard extends StatelessWidget {
  final int estimatedDuration;
  final int totalExercises;
  final int totalSets;
  final bool hasVideoContent;

  const WorkoutStatsCard({
    super.key,
    required this.estimatedDuration,
    required this.totalExercises,
    required this.totalSets,
    required this.hasVideoContent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workout Overview',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.timer_outlined,
                    label: 'Duration',
                    value: '$estimatedDuration min',
                    color: Colors.blue,
                    theme: theme,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.fitness_center,
                    label: 'Exercises',
                    value: totalExercises.toString(),
                    color: Colors.green,
                    theme: theme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.repeat,
                    label: 'Total Sets',
                    value: totalSets.toString(),
                    color: Colors.orange,
                    theme: theme,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: hasVideoContent ? Icons.play_circle : Icons.description,
                    label: 'Content',
                    value: hasVideoContent ? 'Video' : 'Text',
                    color: hasVideoContent ? Colors.purple : Colors.grey,
                    theme: theme,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
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
}