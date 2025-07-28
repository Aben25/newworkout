import 'package:flutter/material.dart';
import '../../services/recommendation_service.dart';
import 'difficulty_indicator.dart';
import 'equipment_chips.dart';
import 'muscle_group_chips.dart';
import 'chip_size.dart';

class WorkoutRecommendationCard extends StatelessWidget {
  final WorkoutRecommendation recommendation;
  final VoidCallback? onTap;
  final VoidCallback? onStart;

  const WorkoutRecommendationCard({
    super.key,
    required this.recommendation,
    this.onTap,
    this.onStart,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient background
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.8),
                    theme.colorScheme.primary.withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          recommendation.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          recommendation.goal.toUpperCase(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recommendation.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  Row(
                    children: [
                      _buildStatItem(
                        icon: Icons.timer_outlined,
                        label: '${recommendation.estimatedDuration} min',
                        theme: theme,
                      ),
                      const SizedBox(width: 16),
                      _buildStatItem(
                        icon: Icons.fitness_center,
                        label: '${recommendation.totalExercises} exercises',
                        theme: theme,
                      ),
                      const Spacer(),
                      DifficultyIndicator(
                        difficulty: recommendation.difficulty,
                        size: DifficultyIndicatorSize.small,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Targeted muscle groups
                  if (recommendation.targetedMuscleGroups.isNotEmpty) ...[
                    Text(
                      'Targets',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    MuscleGroupChips(
                      muscleGroups: recommendation.targetedMuscleGroups.take(4).toList(),
                      size: ChipSize.small,
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Required equipment
                  if (recommendation.requiredEquipment.isNotEmpty) ...[
                    Text(
                      'Equipment',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    EquipmentChips(
                      equipment: recommendation.requiredEquipment.take(3).toList(),
                      size: ChipSize.small,
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    const SizedBox(height: 4),
                  ],
                  
                  // Action buttons
                  Row(
                    children: [
                      // Relevance score indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getRelevanceColor(theme).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getRelevanceColor(theme).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 14,
                              color: _getRelevanceColor(theme),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              (recommendation.relevanceScore / 2).toStringAsFixed(1),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _getRelevanceColor(theme),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Action buttons
                      TextButton(
                        onPressed: onTap,
                        child: const Text('Preview'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: onStart,
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text('Start'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
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
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required ThemeData theme,
  }) {
    return Row(
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
    );
  }

  Color _getRelevanceColor(ThemeData theme) {
    if (recommendation.relevanceScore >= 8) {
      return Colors.green;
    } else if (recommendation.relevanceScore >= 6) {
      return Colors.orange;
    } else {
      return theme.colorScheme.onSurfaceVariant;
    }
  }
}