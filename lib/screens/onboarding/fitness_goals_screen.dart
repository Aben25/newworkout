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
      'id': 'lose_weight',
      'title': 'Lose Weight',
      'description': 'Burn calories and reduce body fat',
      'icon': Icons.trending_down,
      'color': Colors.orange,
      'recommendations': ['cardio', 'hiit', 'circuit_training'],
    },
    {
      'id': 'build_muscle',
      'title': 'Build Muscle',
      'description': 'Increase muscle mass and strength',
      'icon': Icons.fitness_center,
      'color': Colors.red,
      'recommendations': ['strength_training', 'progressive_overload', 'compound_movements'],
    },
    {
      'id': 'improve_endurance',
      'title': 'Improve Endurance',
      'description': 'Enhance cardiovascular fitness',
      'icon': Icons.directions_run,
      'color': Colors.blue,
      'recommendations': ['running', 'cycling', 'swimming', 'interval_training'],
    },
    {
      'id': 'increase_strength',
      'title': 'Increase Strength',
      'description': 'Build power and lift heavier',
      'icon': Icons.sports_gymnastics,
      'color': Colors.purple,
      'recommendations': ['powerlifting', 'heavy_compound_lifts', 'low_rep_training'],
    },
    {
      'id': 'improve_flexibility',
      'title': 'Improve Flexibility',
      'description': 'Enhance mobility and range of motion',
      'icon': Icons.self_improvement,
      'color': Colors.green,
      'recommendations': ['yoga', 'stretching', 'mobility_work', 'pilates'],
    },
    {
      'id': 'general_fitness',
      'title': 'General Fitness',
      'description': 'Overall health and wellness',
      'icon': Icons.favorite,
      'color': Colors.pink,
      'recommendations': ['balanced_training', 'variety_workouts', 'functional_fitness'],
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

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            OnboardingStep.fitnessGoals.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            OnboardingStep.fitnessGoals.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select all that apply, then drag to prioritize',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),

          Expanded(
            child: Column(
              children: [
                // Goal selection grid
                Expanded(
                  flex: 2,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: _availableGoals.length,
                    itemBuilder: (context, index) {
                      final goal = _availableGoals[index];
                      final isSelected = _selectedGoals.contains(goal['id']);

                      return _buildEnhancedGoalCard(goal, isSelected, theme);
                    },
                  ),
                ),

                // Priority reordering section
                if (_selectedGoals.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.reorder,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Priority Order',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Drag to reorder by priority (most important first)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 120,
                          child: ReorderableListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _goalsOrder.length,
                            onReorder: _reorderGoals,
                            itemBuilder: (context, index) {
                              final goalId = _goalsOrder[index];
                              final goal = _getGoalById(goalId);
                              if (goal == null) return const SizedBox.shrink();

                              return Container(
                                key: ValueKey(goalId),
                                width: 100,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.primary,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '${index + 1}',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: theme.colorScheme.onPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Icon(
                                      goal['icon'],
                                      size: 24,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      goal['title'],
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onPrimaryContainer,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Recommendations section
                if (_selectedGoals.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildRecommendationsSection(theme),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedGoalCard(Map<String, dynamic> goal, bool isSelected, ThemeData theme) {
    return GestureDetector(
      onTap: () => _toggleGoal(goal['id']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        transform: Matrix4.identity()..scale(isSelected ? 1.02 : 1.0),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surface,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with color animation
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? goal['color'].withValues(alpha: 0.2)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  goal['icon'],
                  size: 32,
                  color: isSelected
                      ? goal['color']
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              
              // Title
              Text(
                goal['title'],
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              
              // Description
              Text(
                goal['description'],
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                      : theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Selection indicator with animation
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isSelected
                    ? Container(
                        key: const ValueKey('selected'),
                        margin: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: goal['color'],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Selected',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: goal['color'],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(
                        key: ValueKey('unselected'),
                        height: 24,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection(ThemeData theme) {
    final personalizedRecs = _getPersonalizedRecommendations();
    final workoutTypes = personalizedRecs['workoutTypes'] as List<String>;
    
    if (workoutTypes.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
            theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced header with animation
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.8),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.psychology_outlined,
                  color: theme.colorScheme.onPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI-Powered Recommendations',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Personalized for your goals',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Training Focus
          _buildRecommendationCard(
            theme,
            'Training Focus',
            Icons.center_focus_strong,
            personalizedRecs['focus'] as String,
            theme.colorScheme.primary,
          ),
          
          const SizedBox(height: 16),
          
          // Workout Details Grid
          Row(
            children: [
              Expanded(
                child: _buildRecommendationCard(
                  theme,
                  'Frequency',
                  Icons.calendar_today,
                  personalizedRecs['frequency'] as String,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRecommendationCard(
                  theme,
                  'Duration',
                  Icons.timer,
                  personalizedRecs['duration'] as String,
                  Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildRecommendationCard(
            theme,
            'Intensity',
            Icons.trending_up,
            personalizedRecs['intensity'] as String,
            Colors.orange,
          ),
          
          const SizedBox(height: 20),
          
          // Workout Types Section
          Text(
            'Recommended Workout Types',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: workoutTypes.asMap().entries.map((entry) {
              final index = entry.key;
              final workoutType = entry.value;
              final colors = [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
                theme.colorScheme.tertiary,
                Colors.deepPurple,
                Colors.teal,
                Colors.indigo,
              ];
              final color = colors[index % colors.length];
              
              return AnimatedContainer(
                duration: Duration(milliseconds: 300 + (index * 100)),
                curve: Curves.easeOutBack,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.2),
                      color.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: color.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      workoutType,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // Algorithm note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recommendations are generated using advanced algorithms based on your goal priorities and fitness science.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(
    ThemeData theme,
    String title,
    IconData icon,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}