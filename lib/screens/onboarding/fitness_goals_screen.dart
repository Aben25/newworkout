import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/onboarding_provider.dart';
import '../../models/onboarding_state.dart';

class FitnessGoalsScreen extends ConsumerStatefulWidget {
  const FitnessGoalsScreen({super.key});

  @override
  ConsumerState<FitnessGoalsScreen> createState() => _FitnessGoalsScreenState();
}

class _FitnessGoalsScreenState extends ConsumerState<FitnessGoalsScreen>
    with TickerProviderStateMixin {
  List<String> _selectedGoals = [];
  List<String> _goalsOrder = [];
  late AnimationController _animationController;
  late AnimationController _reorderAnimationController;
  
  final List<Map<String, dynamic>> _availableGoals = [
    {
      'id': 'training_sport',
      'title': 'Training for a specific sport',
      'description': 'Sport-specific fitness and performance',
      'icon': Icons.sports,
      'color': Colors.purple,
      'recommendations': ['sport_specific', 'agility', 'functional_training'],
    },
    {
      'id': 'increase_strength',
      'title': 'Increase strength',
      'description': 'Build power and lift heavier weights',
      'icon': Icons.fitness_center,
      'color': Colors.red,
      'recommendations': ['strength_training', 'progressive_overload', 'compound_movements'],
    },
    {
      'id': 'increase_stamina',
      'title': 'Increase stamina',
      'description': 'Boost cardiovascular endurance and stamina',
      'icon': Icons.directions_run,
      'color': Colors.blue,
      'recommendations': ['cardio', 'interval_training', 'endurance'],
    },
    {
      'id': 'optimize_health',
      'title': 'Optimize Health and Fitness',
      'description': 'Overall wellness and general fitness',
      'icon': Icons.favorite,
      'color': Colors.green,
      'recommendations': ['balanced_training', 'wellness', 'general_fitness'],
    },
    {
      'id': 'build_muscle',
      'title': 'Build muscle mass and size',
      'description': 'Increase muscle mass and hypertrophy',
      'icon': Icons.sports_gymnastics,
      'color': Colors.purple,
      'recommendations': ['hypertrophy', 'progressive_overload', 'high_volume'],
    },
    {
      'id': 'weight_loss',
      'title': 'Weight loss',
      'description': 'Burn calories and reduce body fat',
      'icon': Icons.trending_down,
      'color': Colors.orange,
      'recommendations': ['cardio', 'hiit', 'calorie_deficit'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _reorderAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _loadExistingData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _reorderAnimationController.dispose();
    super.dispose();
  }

  void _loadExistingData() {
    final onboardingState = ref.read(onboardingProvider);
    final stepData = onboardingState.stepData;
    
    if (stepData['fitnessGoals'] != null) {
      _selectedGoals = List<String>.from(stepData['fitnessGoals']);
    }
    if (stepData['fitnessGoalsOrder'] != null) {
      _goalsOrder = List<String>.from(stepData['fitnessGoalsOrder']);
    } else {
      _goalsOrder = List<String>.from(_selectedGoals);
    }
  }

  void _saveData() {
    final onboardingNotifier = ref.read(onboardingProvider.notifier);
    onboardingNotifier.updateMultipleStepData({
      'fitnessGoals': _selectedGoals,
      'fitnessGoalsOrder': _goalsOrder,
    });
  }

  void _toggleGoal(String goalId) {
    setState(() {
      if (_selectedGoals.contains(goalId)) {
        _selectedGoals.remove(goalId);
        _goalsOrder.remove(goalId);
      } else {
        _selectedGoals.add(goalId);
        _goalsOrder.add(goalId);
        // Trigger animation for new selection
        _animationController.forward().then((_) {
          _animationController.reset();
        });
      }
    });
    _saveData();
  }

  void _reorderGoals(int oldIndex, int newIndex) {
    _reorderAnimationController.forward().then((_) {
      _reorderAnimationController.reset();
    });
    
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _goalsOrder.removeAt(oldIndex);
      _goalsOrder.insert(newIndex, item);
    });
    _saveData();
  }



  // Enhanced recommendation engine with personalized suggestions
  Map<String, dynamic> _getPersonalizedRecommendations() {
    if (_selectedGoals.isEmpty) {
      return {
        'workoutTypes': <String>[],
        'frequency': 'Not determined',
        'duration': 'Not determined',
        'intensity': 'Not determined',
        'focus': 'Not determined',
      };
    }

    final goalPriorities = <String, int>{};
    for (int i = 0; i < _goalsOrder.length; i++) {
      goalPriorities[_goalsOrder[i]] = _goalsOrder.length - i; // Higher number = higher priority
    }

    // Algorithm-based recommendations
    final workoutTypes = <String>[];
    String frequency = '3-4 times per week';
    String duration = '45-60 minutes';
    String intensity = 'Moderate';
    String focus = 'Balanced';

    // Weight loss focused recommendations
    if (_selectedGoals.contains('lose_weight')) {
      final priority = goalPriorities['lose_weight'] ?? 0;
      if (priority > 3) {
        workoutTypes.addAll(['HIIT', 'Cardio', 'Circuit Training', 'Metabolic Conditioning']);
        frequency = '5-6 times per week';
        duration = '30-45 minutes';
        intensity = 'High';
        focus = 'Fat Burning';
      } else {
        workoutTypes.addAll(['Cardio', 'Circuit Training']);
      }
    }

    // Muscle building focused recommendations
    if (_selectedGoals.contains('build_muscle')) {
      final priority = goalPriorities['build_muscle'] ?? 0;
      if (priority > 3) {
        workoutTypes.addAll(['Strength Training', 'Progressive Overload', 'Compound Movements', 'Hypertrophy']);
        frequency = '4-5 times per week';
        duration = '60-75 minutes';
        intensity = 'High';
        focus = 'Muscle Growth';
      } else {
        workoutTypes.addAll(['Strength Training', 'Compound Movements']);
      }
    }

    // Endurance focused recommendations
    if (_selectedGoals.contains('improve_endurance')) {
      final priority = goalPriorities['improve_endurance'] ?? 0;
      if (priority > 3) {
        workoutTypes.addAll(['Running', 'Cycling', 'Swimming', 'Interval Training', 'Aerobic Base Building']);
        frequency = '5-6 times per week';
        duration = '45-90 minutes';
        intensity = 'Moderate to High';
        focus = 'Cardiovascular Fitness';
      } else {
        workoutTypes.addAll(['Running', 'Cycling', 'Interval Training']);
      }
    }

    // Strength focused recommendations
    if (_selectedGoals.contains('increase_strength')) {
      final priority = goalPriorities['increase_strength'] ?? 0;
      if (priority > 3) {
        workoutTypes.addAll(['Powerlifting', 'Heavy Compound Lifts', 'Low Rep Training', 'Progressive Overload']);
        frequency = '3-4 times per week';
        duration = '60-90 minutes';
        intensity = 'Very High';
        focus = 'Maximum Strength';
      } else {
        workoutTypes.addAll(['Powerlifting', 'Heavy Compound Lifts']);
      }
    }

    // Flexibility focused recommendations
    if (_selectedGoals.contains('improve_flexibility')) {
      final priority = goalPriorities['improve_flexibility'] ?? 0;
      if (priority > 2) {
        workoutTypes.addAll(['Yoga', 'Stretching', 'Mobility Work', 'Pilates', 'Dynamic Warm-ups']);
        if (!_selectedGoals.any((goal) => ['lose_weight', 'build_muscle', 'increase_strength'].contains(goal))) {
          frequency = '4-5 times per week';
          duration = '30-60 minutes';
          intensity = 'Low to Moderate';
          focus = 'Mobility & Flexibility';
        }
      } else {
        workoutTypes.addAll(['Yoga', 'Stretching']);
      }
    }

    // General fitness recommendations
    if (_selectedGoals.contains('general_fitness')) {
      workoutTypes.addAll(['Balanced Training', 'Variety Workouts', 'Functional Fitness', 'Full Body Workouts']);
      if (_selectedGoals.length == 1) {
        frequency = '3-4 times per week';
        duration = '45-60 minutes';
        intensity = 'Moderate';
        focus = 'Overall Health';
      }
    }

    // Adjust recommendations based on goal combinations
    if (_selectedGoals.contains('lose_weight') && _selectedGoals.contains('build_muscle')) {
      workoutTypes.addAll(['Body Recomposition', 'Strength + Cardio']);
      focus = 'Body Recomposition';
    }

    if (_selectedGoals.contains('increase_strength') && _selectedGoals.contains('improve_endurance')) {
      workoutTypes.addAll(['Hybrid Training', 'CrossFit Style']);
      focus = 'Strength Endurance';
    }

    return {
      'workoutTypes': workoutTypes.toSet().toList(),
      'frequency': frequency,
      'duration': duration,
      'intensity': intensity,
      'focus': focus,
    };
  }

  Map<String, dynamic>? _getGoalById(String id) {
    try {
      return _availableGoals.firstWhere((goal) => goal['id'] == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Simple header matching Figma
            Text(
              'What are your fitness goals?',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select all that apply to help us personalize your workouts',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),

            // Simple goal selection grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: _availableGoals.length,
              itemBuilder: (context, index) {
                final goal = _availableGoals[index];
                final isSelected = _selectedGoals.contains(goal['id']);

                return _buildSimpleGoalCard(goal, isSelected, theme);
              },
            ),
            
            // Extra bottom padding to prevent overflow
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleGoalCard(Map<String, dynamic> goal, bool isSelected, ThemeData theme) {
    return GestureDetector(
      onTap: () => _toggleGoal(goal['id']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surface,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                goal['icon'],
                size: 32,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                goal['title'],
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (isSelected) ...[
                const SizedBox(height: 8),
                Icon(
                  Icons.check_circle,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

}