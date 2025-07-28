import 'package:flutter/material.dart';

enum DifficultyIndicatorSize { small, medium, large }

class DifficultyIndicator extends StatelessWidget {
  final String difficulty;
  final DifficultyIndicatorSize size;

  const DifficultyIndicator({
    super.key,
    required this.difficulty,
    this.size = DifficultyIndicatorSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final difficultyLevel = _getDifficultyLevel(difficulty);
    final color = _getDifficultyColor(difficultyLevel);
    
    final double dotSize = switch (size) {
      DifficultyIndicatorSize.small => 6,
      DifficultyIndicatorSize.medium => 8,
      DifficultyIndicatorSize.large => 10,
    };
    
    final double spacing = switch (size) {
      DifficultyIndicatorSize.small => 3,
      DifficultyIndicatorSize.medium => 4,
      DifficultyIndicatorSize.large => 5,
    };

    final textStyle = switch (size) {
      DifficultyIndicatorSize.small => theme.textTheme.bodySmall,
      DifficultyIndicatorSize.medium => theme.textTheme.bodyMedium,
      DifficultyIndicatorSize.large => theme.textTheme.bodyLarge,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Difficulty dots
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final isActive = index < difficultyLevel;
            return Container(
              margin: EdgeInsets.only(right: index < 2 ? spacing : 0),
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? color : color.withOpacity(0.3),
              ),
            );
          }),
        ),
        
        SizedBox(width: spacing * 2),
        
        // Difficulty text
        Text(
          difficulty,
          style: textStyle?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  int _getDifficultyLevel(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
      case 'easy':
        return 1;
      case 'intermediate':
      case 'medium':
        return 2;
      case 'advanced':
      case 'hard':
      case 'expert':
        return 3;
      default:
        return 2; // Default to intermediate
    }
  }

  Color _getDifficultyColor(int level) {
    switch (level) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}