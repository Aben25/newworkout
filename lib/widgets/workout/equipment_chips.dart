import 'package:flutter/material.dart';
import 'chip_size.dart';

class EquipmentChips extends StatelessWidget {
  final List<String> equipment;
  final ChipSize size;
  final bool showIcons;
  final int? maxChips;
  final VoidCallback? onShowMore;

  const EquipmentChips({
    super.key,
    required this.equipment,
    this.size = ChipSize.medium,
    this.showIcons = true,
    this.maxChips,
    this.onShowMore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayEquipment = maxChips != null && equipment.length > maxChips!
        ? equipment.take(maxChips!).toList()
        : equipment;
    
    final remainingCount = maxChips != null && equipment.length > maxChips!
        ? equipment.length - maxChips!
        : 0;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...displayEquipment.map((eq) => _buildEquipmentChip(eq, theme)),
        if (remainingCount > 0)
          _buildMoreChip(remainingCount, theme),
      ],
    );
  }

  Widget _buildEquipmentChip(String equipment, ThemeData theme) {
    final icon = _getEquipmentIcon(equipment);
    final displayName = _getDisplayName(equipment);
    
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
        color: theme.colorScheme.secondaryContainer.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcons && icon != null) ...[
            Icon(
              icon,
              size: iconSize,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            displayName,
            style: textStyle?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w500,
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

  IconData? _getEquipmentIcon(String equipment) {
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
      case 'treadmill':
        return Icons.directions_run;
      case 'stationary bike':
      case 'bike':
        return Icons.directions_bike;
      case 'yoga mat':
      case 'mat':
        return Icons.crop_landscape;
      case 'bodyweight':
      case 'none':
        return Icons.accessibility;
      case 'medicine ball':
        return Icons.sports_volleyball;
      case 'foam roller':
        return Icons.straighten;
      case 'stability ball':
      case 'exercise ball':
        return Icons.circle;
      default:
        return Icons.fitness_center;
    }
  }

  String _getDisplayName(String equipment) {
    // Convert to title case and handle special cases
    switch (equipment.toLowerCase()) {
      case 'bodyweight':
        return 'Bodyweight';
      case 'none':
        return 'No Equipment';
      case 'pull-up bar':
        return 'Pull-up Bar';
      case 'resistance bands':
        return 'Resistance Bands';
      case 'cable machine':
        return 'Cable Machine';
      case 'stationary bike':
        return 'Stationary Bike';
      case 'yoga mat':
        return 'Yoga Mat';
      case 'medicine ball':
        return 'Medicine Ball';
      case 'foam roller':
        return 'Foam Roller';
      case 'stability ball':
        return 'Stability Ball';
      case 'exercise ball':
        return 'Exercise Ball';
      default:
        // Convert to title case
        return equipment
            .split(' ')
            .map((word) => word.isEmpty 
                ? word 
                : word[0].toUpperCase() + word.substring(1).toLowerCase())
            .join(' ');
    }
  }
}