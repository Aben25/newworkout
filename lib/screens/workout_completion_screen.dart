import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../screens/workout_summary_screen.dart';
import '../widgets/workout/set_progress_tracker_widget.dart';
import '../widgets/workout/rest_period_analysis_widget.dart';
import '../utils/app_theme.dart';

/// Comprehensive workout completion screen with detailed analytics
/// Shows performance analysis, progression tracking, and recommendations
class WorkoutCompletionScreen extends ConsumerStatefulWidget {
  final WorkoutSessionCompleted completedSession;

  const WorkoutCompletionScreen({
    super.key,
    required this.completedSession,
  });

  @override
  ConsumerState<WorkoutCompletionScreen> createState() => _WorkoutCompletionScreenState();
}

class _WorkoutCompletionScreenState extends ConsumerState<WorkoutCompletionScreen>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late AnimationController _contentController;
  late Animation<double> _celebrationAnimation;
  late Animation<double> _contentAnimation;

  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startCelebration();
  }

  void _initializeAnimations() {
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _celebrationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    ));

    _contentAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _startCelebration() {
    HapticFeedback.heavyImpact();
    _celebrationController.forward();
    
    Future.delayed(const Duration(milliseconds: 500), () {
      _contentController.forward();
    });
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _contentController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Celebration header
            _buildCelebrationHeader(),
            
            // Content pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildSummaryPage(),
                  _buildAnalyticsPage(),
                  _buildProgressionPage(),
                ],
              ),
            ),
            
            // Page indicator and navigation
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildCelebrationHeader() {
    final session = widget.completedSession;
    
    return AnimatedBuilder(
      animation: _celebrationAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _celebrationAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Celebration icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.successColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.successColor.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Completion message
                Text(
                  'Workout Complete!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successColor,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  session.workout.name ?? 'Great workout',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Quick stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickStat(
                      'Duration',
                      _formatDuration(session.totalDuration),
                      Icons.timer,
                    ),
                    _buildQuickStat(
                      'Sets',
                      '${session.totalSetsCompleted}',
                      Icons.fitness_center,
                    ),
                    _buildQuickStat(
                      'Volume',
                      '${session.totalVolumeLifted.toStringAsFixed(0)}kg',
                      Icons.scale,
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

  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildSummaryPage() {
    final session = widget.completedSession;
    
    return AnimatedBuilder(
      animation: _contentAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _contentAnimation.value)),
          child: Opacity(
            opacity: _contentAnimation.value,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Workout summary card
                  _buildSummaryCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Exercise breakdown
                  _buildExerciseBreakdown(),
                  
                  const SizedBox(height: 16),
                  
                  // Rating and notes
                  _buildRatingAndNotes(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard() {
    final session = widget.completedSession;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workout Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Summary metrics
            Row(
              children: [
                Expanded(
                  child: _buildSummaryMetric(
                    'Total Time',
                    _formatDuration(session.totalDuration),
                    Icons.access_time,
                    AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildSummaryMetric(
                    'Exercises',
                    '${session.exercisesCompleted}',
                    Icons.list,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildSummaryMetric(
                    'Total Sets',
                    '${session.totalSetsCompleted}',
                    Icons.fitness_center,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildSummaryMetric(
                    'Total Reps',
                    '${session.totalRepsCompleted}',
                    Icons.repeat,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Completion percentage
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Completion',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: session.completionPercentage / 100,
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          session.isFullyCompleted ? AppTheme.successColor : Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${session.completionPercentage.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: session.isFullyCompleted ? AppTheme.successColor : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildExerciseBreakdown() {
    final session = widget.completedSession;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exercise Breakdown',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Exercise list
            ...session.exerciseLogs.asMap().entries.map((entry) {
              final index = entry.key;
              final exerciseLog = entry.value;
              final exercise = session.exercises.firstWhere(
                (e) => e.id == exerciseLog.exerciseId,
                orElse: () => Exercise(
                  id: exerciseLog.exerciseId,
                  name: 'Unknown Exercise',
                  createdAt: DateTime.now(),
                ),
              );
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildExerciseItem(exercise, exerciseLog, index),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseItem(Exercise exercise, ExerciseLogSession exerciseLog, int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Exercise number
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Exercise details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${exerciseLog.completedSets} sets • ${exerciseLog.totalReps} reps • ${exerciseLog.totalVolume.toStringAsFixed(0)}kg',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          
          // Difficulty indicator
          if (exerciseLog.averageDifficultyRating != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getDifficultyColor(exerciseLog.averageDifficultyRating!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getDifficultyLabel(exerciseLog.averageDifficultyRating!),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingAndNotes() {
    final session = widget.completedSession;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Feedback',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Rating
            if (session.rating != null) ...[
              Row(
                children: [
                  Text(
                    'Rating: ',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  ...List.generate(5, (index) {
                    return Icon(
                      index < session.rating! ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 20,
                    );
                  }),
                  const SizedBox(width: 8),
                  Text(
                    '${session.rating}/5',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
            ],
            
            // Notes
            if (session.notes?.isNotEmpty == true) ...[
              Text(
                'Notes:',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  session.notes!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Analytics',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Progress trackers for each exercise
          ...widget.completedSession.exerciseLogs.asMap().entries.map((entry) {
            final exerciseLog = entry.value;
            final exercise = widget.completedSession.exercises.firstWhere(
              (e) => e.id == exerciseLog.exerciseId,
              orElse: () => Exercise(
                id: exerciseLog.exerciseId,
                name: 'Unknown Exercise',
                createdAt: DateTime.now(),
              ),
            );
            
            // Find corresponding workout exercise
            final workoutExercise = widget.completedSession.workoutExercises.firstWhere(
              (we) => we.exerciseId == exercise.id,
              orElse: () => WorkoutExercise(
                id: 'unknown',
                workoutId: widget.completedSession.workout.id,
                exerciseId: exercise.id,
                name: exercise.name,
                createdAt: DateTime.now(),
              ),
            );
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SetProgressTrackerWidget(
                workoutExercise: workoutExercise,
                exercise: exercise,
                completedSets: exerciseLog.sets,
                showDetailedAnalysis: true,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProgressionPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rest Period Analysis',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Rest period analysis for each exercise
          ...widget.completedSession.exerciseLogs.map((exerciseLog) {
            final exercise = widget.completedSession.exercises.firstWhere(
              (e) => e.id == exerciseLog.exerciseId,
              orElse: () => Exercise(
                id: exerciseLog.exerciseId,
                name: 'Unknown Exercise',
                createdAt: DateTime.now(),
              ),
            );
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: RestPeriodAnalysisWidget(
                exerciseId: exercise.id,
                userId: 'current_user', // This should come from auth
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Page indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              );
            }),
          ),
          
          const SizedBox(height: 16),
          
          // Navigation buttons
          Row(
            children: [
              if (_currentPage > 0) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: const Text('Previous'),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              
              Expanded(
                child: ElevatedButton(
                  onPressed: _currentPage < 2
                      ? () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : () {
                          // Navigate to comprehensive workout summary screen
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => WorkoutSummaryScreen(
                                completedSession: widget.completedSession,
                              ),
                            ),
                          );
                        },
                  child: Text(_currentPage < 2 ? 'Next' : 'View Summary'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  Color _getDifficultyColor(double difficulty) {
    if (difficulty <= 2.0) return Colors.green;
    if (difficulty <= 3.0) return Colors.orange;
    return Colors.red;
  }

  String _getDifficultyLabel(double difficulty) {
    if (difficulty <= 1.5) return 'Easy';
    if (difficulty <= 2.5) return 'Moderate';
    if (difficulty <= 3.5) return 'Hard';
    return 'Very Hard';
  }
}