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

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Simple header matching Figma
            Text(
              'What\'s your fitness level?',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Help us create workouts that match your experience',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),

            // Cardio fitness level
            _buildSimpleFitnessSection(
              title: 'Cardio Fitness',
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
            
            const SizedBox(height: 32),
            
            // Weightlifting fitness level
            _buildSimpleFitnessSection(
              title: 'Strength Training',
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
            
            // Extra bottom padding to prevent overflow
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleFitnessSection({
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
        Row(
          children: [
            Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Current level display
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: currentLevel['color'].withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: currentLevel['color'].withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                currentDescription['icon'],
                color: currentLevel['color'],
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentDescription['text'],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
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
        ),
        
        const SizedBox(height: 16),
        
        // Simple slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            activeTrackColor: theme.colorScheme.primary,
            thumbColor: theme.colorScheme.primary,
            overlayColor: theme.colorScheme.primary.withOpacity(0.2),
          ),
          child: Slider(
            value: value,
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: onChanged,
            inactiveColor: theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
        
        // Simple level labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _levelDescriptions.map((level) {
              return Text(
                level['title'],
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

}