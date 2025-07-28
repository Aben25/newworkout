import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/onboarding_provider.dart';
import '../../models/onboarding_state.dart';

class FitnessLevelScreen extends ConsumerStatefulWidget {
  const FitnessLevelScreen({super.key});

  @override
  ConsumerState<FitnessLevelScreen> createState() => _FitnessLevelScreenState();
}

class _FitnessLevelScreenState extends ConsumerState<FitnessLevelScreen>
    with TickerProviderStateMixin {
  double _cardioLevel = 1;
  double _weightliftingLevel = 1;
  late AnimationController _levelAnimationController;
  late AnimationController _summaryAnimationController;

  final List<Map<String, dynamic>> _levelDescriptions = [
    {
      'title': 'Beginner',
      'color': Colors.green,
      'icon': Icons.emoji_people,
    },
    {
      'title': 'Novice',
      'color': Colors.lightGreen,
      'icon': Icons.directions_walk,
    },
    {
      'title': 'Intermediate',
      'color': Colors.orange,
      'icon': Icons.directions_run,
    },
    {
      'title': 'Advanced',
      'color': Colors.deepOrange,
      'icon': Icons.sports_gymnastics,
    },
    {
      'title': 'Expert',
      'color': Colors.red,
      'icon': Icons.military_tech,
    },
  ];

  final List<Map<String, dynamic>> _cardioDescriptions = [
    {
      'text': 'I rarely do cardio exercise',
      'detail': 'Less than 1 session per week',
      'icon': Icons.airline_seat_recline_extra,
      'guidance': 'Perfect starting point! We\'ll begin with gentle, low-impact activities to build your cardiovascular base safely.',
      'examples': ['Walking', 'Light stretching', 'Beginner yoga'],
      'heartRate': '50-60% max HR',
      'duration': '10-20 minutes',
    },
    {
      'text': 'I do light cardio occasionally',
      'detail': '1-2 light sessions per week',
      'icon': Icons.directions_walk,
      'guidance': 'Great foundation! You\'re ready to increase frequency and add variety to your cardio routine.',
      'examples': ['Brisk walking', 'Light cycling', 'Swimming'],
      'heartRate': '60-70% max HR',
      'duration': '20-30 minutes',
    },
    {
      'text': 'I do moderate cardio regularly',
      'detail': '3-4 moderate sessions per week',
      'icon': Icons.directions_run,
      'guidance': 'Excellent consistency! You can handle more challenging workouts and interval training.',
      'examples': ['Jogging', 'Cycling', 'Dance fitness', 'HIIT'],
      'heartRate': '70-80% max HR',
      'duration': '30-45 minutes',
    },
    {
      'text': 'I do intense cardio frequently',
      'detail': '5+ intense sessions per week',
      'icon': Icons.speed,
      'guidance': 'Impressive dedication! You\'re ready for advanced training methods and performance optimization.',
      'examples': ['Running', 'Spin classes', 'CrossFit', 'Sports'],
      'heartRate': '80-90% max HR',
      'duration': '45-60 minutes',
    },
    {
      'text': 'I\'m a cardio enthusiast',
      'detail': 'Daily high-intensity training',
      'icon': Icons.flash_on,
      'guidance': 'Elite level! Focus on periodization, recovery, and sport-specific training for peak performance.',
      'examples': ['Marathon training', 'Triathlon', 'Competitive sports'],
      'heartRate': '85-95% max HR',
      'duration': '60+ minutes',
    },
  ];

  final List<Map<String, dynamic>> _weightliftingDescriptions = [
    {
      'text': 'I\'ve never lifted weights',
      'detail': 'Complete beginner',
      'icon': Icons.help_outline,
      'guidance': 'Welcome to strength training! We\'ll start with bodyweight exercises and light weights to teach proper form.',
      'examples': ['Bodyweight squats', 'Push-ups', 'Light dumbbells'],
      'intensity': 'Very Light',
      'focus': 'Form & Technique',
    },
    {
      'text': 'I\'ve done some basic lifting',
      'detail': 'Occasional light weights',
      'icon': Icons.fitness_center,
      'guidance': 'Time to build consistency! We\'ll establish a routine with fundamental compound movements.',
      'examples': ['Goblet squats', 'Dumbbell press', 'Assisted pull-ups'],
      'intensity': 'Light to Moderate',
      'focus': 'Building Habits',
    },
    {
      'text': 'I lift weights regularly',
      'detail': '2-3 sessions per week',
      'icon': Icons.sports_gymnastics,
      'guidance': 'Solid foundation! Ready for progressive overload and more complex movement patterns.',
      'examples': ['Barbell squats', 'Bench press', 'Deadlifts', 'Rows'],
      'intensity': 'Moderate',
      'focus': 'Progressive Overload',
    },
    {
      'text': 'I\'m experienced with lifting',
      'detail': '4+ sessions per week',
      'icon': Icons.sports_kabaddi,
      'guidance': 'Strong dedication! You can handle advanced techniques and specialized training programs.',
      'examples': ['Olympic lifts', 'Advanced variations', 'Periodization'],
      'intensity': 'High',
      'focus': 'Specialization',
    },
    {
      'text': 'I\'m an advanced lifter',
      'detail': 'Daily training with heavy weights',
      'icon': Icons.military_tech,
      'guidance': 'Elite strength! Focus on competition prep, advanced periodization, and injury prevention.',
      'examples': ['Powerlifting', 'Olympic lifting', 'Strongman'],
      'intensity': 'Very High',
      'focus': 'Peak Performance',
    },
  ];

  @override
  void initState() {
    super.initState();
    _levelAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _summaryAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _loadExistingData();
  }

  @override
  void dispose() {
    _levelAnimationController.dispose();
    _summaryAnimationController.dispose();
    super.dispose();
  }

  void _loadExistingData() {
    final onboardingState = ref.read(onboardingProvider);
    final stepData = onboardingState.stepData;
    
    _cardioLevel = (stepData['cardioFitnessLevel'] ?? 1).toDouble();
    _weightliftingLevel = (stepData['weightliftingFitnessLevel'] ?? 1).toDouble();
  }

  void _saveData() {
    final onboardingNotifier = ref.read(onboardingProvider.notifier);
    onboardingNotifier.updateMultipleStepData({
      'cardioFitnessLevel': _cardioLevel.round(),
      'weightliftingFitnessLevel': _weightliftingLevel.round(),
      'fitnessExperience': _getFitnessExperience(),
    });
    
    // Trigger summary animation
    _summaryAnimationController.forward().then((_) {
      _summaryAnimationController.reset();
    });
  }

  String _getFitnessExperience() {
    final avgLevel = (_cardioLevel + _weightliftingLevel) / 2;
    if (avgLevel <= 1.5) return 'beginner';
    if (avgLevel <= 2.5) return 'novice';
    if (avgLevel <= 3.5) return 'intermediate';
    if (avgLevel <= 4.5) return 'advanced';
    return 'expert';
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
            OnboardingStep.fitnessLevel.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            OnboardingStep.fitnessLevel.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Cardio fitness level
                  _buildFitnessLevelSection(
                    title: 'Cardio Fitness Level',
                    icon: Icons.directions_run,
                    value: _cardioLevel,
                    descriptions: _cardioDescriptions,
                    onChanged: (value) {
                      setState(() {
                        _cardioLevel = value;
                      });
                      _saveData();
                    },
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Weightlifting fitness level
                  _buildFitnessLevelSection(
                    title: 'Weightlifting Experience',
                    icon: Icons.fitness_center,
                    value: _weightliftingLevel,
                    descriptions: _weightliftingDescriptions,
                    onChanged: (value) {
                      setState(() {
                        _weightliftingLevel = value;
                      });
                      _saveData();
                    },
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Enhanced overall fitness summary
                  _buildEnhancedFitnessSummary(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFitnessLevelSection({
    required String title,
    required IconData icon,
    required double value,
    required List<Map<String, dynamic>> descriptions,
    required ValueChanged<double> onChanged,
  }) {
    final theme = Theme.of(context);
    final currentIndex = (value - 1).round();
    final currentLevel = _levelDescriptions[currentIndex];
    final currentDescription = descriptions[currentIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select your current level',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Enhanced level indicator with detailed guidance
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                currentLevel['color'].withValues(alpha: 0.15),
                currentLevel['color'].withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: currentLevel['color'].withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: currentLevel['color'].withValues(alpha: 0.2),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Enhanced level header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: currentLevel['color'].withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: currentLevel['color'].withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      currentLevel['icon'],
                      size: 24,
                      color: currentLevel['color'],
                    ),
                    const SizedBox(width: 12),
                    Text(
                      currentLevel['title'],
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: currentLevel['color'],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Current level description
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          currentDescription['icon'],
                          size: 20,
                          color: currentLevel['color'],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentDescription['text'],
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentDescription['detail'],
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    if (currentDescription['guidance'] != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: currentLevel['color'].withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 16,
                              color: currentLevel['color'],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                currentDescription['guidance'],
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Enhanced details grid
              if (currentDescription['examples'] != null || 
                  currentDescription['heartRate'] != null ||
                  currentDescription['intensity'] != null) ...[
                Row(
                  children: [
                    if (currentDescription['examples'] != null)
                      Expanded(
                        child: _buildDetailCard(
                          theme,
                          'Examples',
                          Icons.fitness_center,
                          (currentDescription['examples'] as List<String>).join(', '),
                          currentLevel['color'],
                        ),
                      ),
                    if (currentDescription['examples'] != null && 
                        (currentDescription['heartRate'] != null || currentDescription['intensity'] != null))
                      const SizedBox(width: 12),
                    if (currentDescription['heartRate'] != null)
                      Expanded(
                        child: _buildDetailCard(
                          theme,
                          'Target HR',
                          Icons.favorite,
                          currentDescription['heartRate'],
                          Colors.red,
                        ),
                      )
                    else if (currentDescription['intensity'] != null)
                      Expanded(
                        child: _buildDetailCard(
                          theme,
                          'Intensity',
                          Icons.trending_up,
                          currentDescription['intensity'],
                          Colors.orange,
                        ),
                      ),
                  ],
                ),
                
                if (currentDescription['duration'] != null || currentDescription['focus'] != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (currentDescription['duration'] != null)
                        Expanded(
                          child: _buildDetailCard(
                            theme,
                            'Duration',
                            Icons.timer,
                            currentDescription['duration'],
                            Colors.blue,
                          ),
                        ),
                      if (currentDescription['duration'] != null && currentDescription['focus'] != null)
                        const SizedBox(width: 12),
                      if (currentDescription['focus'] != null)
                        Expanded(
                          child: _buildDetailCard(
                            theme,
                            'Focus',
                            Icons.center_focus_strong,
                            currentDescription['focus'],
                            Colors.purple,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Enhanced slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 12,
            thumbShape: RoundSliderThumbShape(
              enabledThumbRadius: 16,
              elevation: 4,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
            activeTrackColor: currentLevel['color'],
            thumbColor: currentLevel['color'],
            overlayColor: currentLevel['color'].withValues(alpha: 0.2),
          ),
          child: Slider(
            value: value,
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: (newValue) {
              _levelAnimationController.forward().then((_) {
                _levelAnimationController.reset();
              });
              onChanged(newValue);
            },
            inactiveColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
        
        // Enhanced level labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _levelDescriptions.asMap().entries.map((entry) {
              final index = entry.key;
              final level = entry.value;
              final isActive = index == currentIndex;
              
              return Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isActive 
                          ? level['color'].withValues(alpha: 0.2)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      level['icon'],
                      size: 16,
                      color: isActive
                          ? level['color']
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    level['title'],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isActive
                          ? level['color']
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedFitnessSummary(ThemeData theme) {
    final experienceLevel = _getFitnessExperience();
    final levelIndex = experienceLevel == 'beginner' ? 0 :
                      experienceLevel == 'novice' ? 1 :
                      experienceLevel == 'intermediate' ? 2 :
                      experienceLevel == 'advanced' ? 3 : 4;
    final currentLevel = _levelDescriptions[levelIndex];
    
    return AnimatedBuilder(
      animation: _summaryAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_summaryAnimationController.value * 0.05),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  currentLevel['color'].withValues(alpha: 0.2),
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: currentLevel['color'].withValues(alpha: 0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: currentLevel['color'].withValues(alpha: 0.2),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assessment,
                      size: 28,
                      color: currentLevel['color'],
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Overall Fitness Level',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Level display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: currentLevel['color'].withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: currentLevel['color'].withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        currentLevel['icon'],
                        size: 24,
                        color: currentLevel['color'],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currentLevel['title'],
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: currentLevel['color'],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Level breakdown
                Row(
                  children: [
                    Expanded(
                      child: _buildLevelBreakdown(
                        'Cardio',
                        Icons.directions_run,
                        _cardioLevel,
                        theme,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildLevelBreakdown(
                        'Strength',
                        Icons.fitness_center,
                        _weightliftingLevel,
                        theme,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailCard(
    ThemeData theme,
    String title,
    IconData icon,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLevelBreakdown(String title, IconData icon, double level, ThemeData theme) {
    final levelIndex = (level - 1).round();
    final levelData = _levelDescriptions[levelIndex];
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: levelData['color'].withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: levelData['color'],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            levelData['title'],
            style: theme.textTheme.bodySmall?.copyWith(
              color: levelData['color'],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}