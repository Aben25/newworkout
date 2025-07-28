import 'package:flutter/material.dart';
import 'chip_size.dart';

class MuscleGroupChips extends StatelessWidget {
  final List<String> muscleGroups;
  final ChipSize size;
  final bool showIcons;
  final int? maxChips;
  final VoidCallback? onShowMore;

  const MuscleGroupChips({
    super.key,
    required this.muscleGroups,
    this.size = ChipSize.medium,
    this.showIcons = true,
    this.maxChips,
    this.onShowMore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayMuscles = maxChips != null && muscleGroups.length > maxChips!
        ? muscleGroups.take(maxChips!).toList()
        : muscleGroups;
    
    final remainingCount = maxChips != null && muscleGroups.length > maxChips!
        ? muscleGroups.length - maxChips!
        : 0;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...displayMuscles.map((muscle) => _buildMuscleChip(muscle, theme)),
        if (remainingCount > 0)
          _buildMoreChip(remainingCount, theme),
      ],
    );
  }

  Widget _buildMuscleChip(String muscleGroup, ThemeData theme) {
    final icon = _getMuscleIcon(muscleGroup);
    final displayName = _getDisplayName(muscleGroup);
    final color = _getMuscleColor(muscleGroup);
    
    final double padding = switch (size) {
      ChipSize.small => 8,
      ChipSize.medium => 12,
      ChipSize.large => 16,
    };

    final textStyle = switch (size) {
      ChipSize.small => theme.textTheme.bodySmall,
      ChipSize.medium => theme.textTheme.bodyMedium,
      ChipSize.large => theme.textTheme.bodyLarge,
    };

    final double iconSize = switch (size) {
      ChipSize.small => 14,
      ChipSize.medium => 16,
      ChipSize.large => 18,
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: padding * 0.6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcons && icon != null) ...[
            Icon(
              icon,
              size: iconSize,
              color: color,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            displayName,
            style: textStyle?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreChip(int count, ThemeData theme) {
    final double padding = switch (size) {
      ChipSize.small => 8,
      ChipSize.medium => 12,
      ChipSize.large => 16,
    };

    final textStyle = switch (size) {
      ChipSize.small => theme.textTheme.bodySmall,
      ChipSize.medium => theme.textTheme.bodyMedium,
      ChipSize.large => theme.textTheme.bodyLarge,
    };

    return GestureDetector(
      onTap: onShowMore,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: padding,
          vertical: padding * 0.6,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.5),
            style: BorderStyle.solid,
          ),
        ),
        child: Text(
          '+$count more',
          style: textStyle?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  IconData? _getMuscleIcon(String muscleGroup) {
    switch (muscleGroup.toLowerCase()) {
      case 'chest':
      case 'pectorals':
        return Icons.favorite;
      case 'back':
      case 'lats':
      case 'latissimus dorsi':
        return Icons.view_column;
      case 'shoulders':
      case 'deltoids':
        return Icons.expand;
      case 'arms':
      case 'biceps':
      case 'triceps':
        return Icons.fitness_center;
      case 'legs':
      case 'quadriceps':
      case 'hamstrings':
      case 'glutes':
        return Icons.directions_walk;
      case 'core':
      case 'abs':
      case 'abdominals':
        return Icons.center_focus_strong;
      case 'calves':
        return Icons.height;
      case 'forearms':
        return Icons.pan_tool;
      case 'full body':
        return Icons.accessibility_new;
      case 'cardio':
        return Icons.favorite_border;
      default:
        return Icons.fitness_center;
    }
  }

  Color _getMuscleColor(String muscleGroup) {
    switch (muscleGroup.toLowerCase()) {
      case 'chest':
      case 'pectorals':
        return Colors.red;
      case 'back':
      case 'lats':
      case 'latissimus dorsi':
        return Colors.blue;
      case 'shoulders':
      case 'deltoids':
        return Colors.orange;
      case 'arms':
      case 'biceps':
      case 'triceps':
        return Colors.purple;
      case 'legs':
      case 'quadriceps':
      case 'hamstrings':
      case 'glutes':
        return Colors.green;
      case 'core':
      case 'abs':
      case 'abdominals':
        return Colors.amber;
      case 'calves':
        return Colors.teal;
      case 'forearms':
        return Colors.indigo;
      case 'full body':
        return Colors.deepPurple;
      case 'cardio':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  String _getDisplayName(String muscleGroup) {
    // Convert to title case and handle special cases
    switch (muscleGroup.toLowerCase()) {
      case 'lats':
        return 'Lats';
      case 'abs':
        return 'Abs';
      case 'full body':
        return 'Full Body';
      default:
        // Convert to title case
        return muscleGroup
            .split(' ')
            .map((word) => word.isEmpty 
                ? word 
                : word[0].toUpperCase() + word.substring(1).toLowerCase())
            .join(' ');
    }
  }
}

