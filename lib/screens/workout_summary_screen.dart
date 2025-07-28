import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/workout_completion_service.dart';
import '../widgets/workout/workout_analytics_widget.dart';
import '../widgets/workout/achievement_celebration_widget.dart';
import '../widgets/workout/social_share_widget.dart';
import '../utils/app_theme.dart';

/// Comprehensive workout summary screen using completed_workouts table for historical tracking
/// Features workout rating system, calorie estimation, user feedback collection, and social sharing
class WorkoutSummaryScreen extends ConsumerStatefulWidget {
  final WorkoutSessionCompleted completedSession;
  final List<UserAchievement>? unlockedAchievements;

  const WorkoutSummaryScreen({
    super.key,
    required this.completedSession,
    this.unlockedAchievements,
  });

  @override
  ConsumerState<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends ConsumerState<WorkoutSummaryScreen>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late AnimationController _contentController;
  late Animation<double> _celebrationAnimation;
  late Animation<double> _contentAnimation;

  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  // Rating and feedback state
  int? _workoutRating;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;
  CompletedWorkout? _completedWorkout;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startCelebration();
    _initializeRatingAndFeedback();
    _completeWorkout();
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

  void _initializeRatingAndFeedback() {
    _workoutRating = widget.completedSession.rating;
    if (widget.completedSession.notes != null) {
      _feedbackController.text = widget.completedSession.notes!;
    }
  }

  /// Complete workout with comprehensive tracking and analytics
  Future<void> _completeWorkout() async {
    try {
      final workoutCompletionService = ref.read(workoutCompletionServiceProvider);
      
      final completedWorkout = await workoutCompletionService.completeWorkout(
        workoutId: widget.completedSession.workout.id,
        duration: widget.completedSession.totalDuration,
        completedSets: widget.completedSession.completedSets,
        exerciseLogs: widget.completedSession.exerciseLogs,
        exercises: widget.completedSession.exercises,
        rating: _workoutRating,
        userFeedback: _feedbackController.text.isNotEmpty ? _feedbackController.text : null,
      );

      setState(() {
        _completedWorkout = completedWorkout;
      });
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save workout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _contentController.dispose();
    _pageController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Celebration header with achievements
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
                  _buildRatingAndFeedbackPage(),
                  _buildAchievementsPage(),
                  _buildSocialSharingPage(),
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
                // Celebration icon with achievements
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.successColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.successColor.withOpacity( 0.3),
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
                    
                    // Achievement badge if any unlocked
                    if (widget.unlockedAchievements?.isNotEmpty == true)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${widget.unlockedAchievements!.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
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
                    color: Theme.of(context).colorScheme.onSurface.withOpacity( 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Quick stats with calories
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickStat(
                      'Duration',
                      _formatDuration(session.totalDuration),
                      Icons.timer,
                    ),
                    _buildQuickStat(
                      'Calories',
                      '${_completedWorkout?.caloriesBurned ?? _estimateCalories()}',
                      Icons.local_fire_department,
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
                  // Comprehensive workout summary card
                  _buildComprehensiveSummaryCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Exercise breakdown with detailed metrics
                  _buildDetailedExerciseBreakdown(),
                  
                  const SizedBox(height: 16),
                  
                  // Performance metrics
                  _buildPerformanceMetrics(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildComprehensiveSummaryCard() {
    final session = widget.completedSession;
    final completedWorkout = _completedWorkout;
    
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
            
            // Enhanced summary metrics
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildSummaryMetric(
                  'Total Time',
                  _formatDuration(session.totalDuration),
                  Icons.access_time,
                  AppTheme.primaryColor,
                ),
                _buildSummaryMetric(
                  'Calories Burned',
                  '${completedWorkout?.caloriesBurned ?? _estimateCalories()}',
                  Icons.local_fire_department,
                  Colors.orange,
                ),
                _buildSummaryMetric(
                  'Total Sets',
                  '${session.totalSetsCompleted}',
                  Icons.fitness_center,
                  Colors.green,
                ),
                _buildSummaryMetric(
                  'Total Reps',
                  '${session.totalRepsCompleted}',
                  Icons.repeat,
                  Colors.blue,
                ),
                _buildSummaryMetric(
                  'Total Volume',
                  '${session.totalVolumeLifted.toStringAsFixed(1)}kg',
                  Icons.scale,
                  Colors.purple,
                ),
                _buildSummaryMetric(
                  'Exercises',
                  '${session.exercisesCompleted}',
                  Icons.list,
                  Colors.teal,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Workout intensity and efficiency
            if (completedWorkout != null) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildIntensityIndicator(
                      'Intensity',
                      completedWorkout.workoutIntensity,
                      Colors.red,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildIntensityIndicator(
                      'Efficiency',
                      completedWorkout.workoutSummary?['workout_efficiency'] ?? 5.0,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryMetric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity( 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity( 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
      ),
    );
  }

  Widget _buildIntensityIndicator(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (value / 10).clamp(0.0, 1.0),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
        const SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(1)}/10',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedExerciseBreakdown() {
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
            
            // Enhanced exercise list with detailed metrics
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
                child: _buildDetailedExerciseItem(exercise, exerciseLog, index),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedExerciseItem(Exercise exercise, ExerciseLogSession exerciseLog, int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
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
                        color: Theme.of(context).colorScheme.onSurface.withOpacity( 0.7),
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
          
          // Set breakdown
          if (exerciseLog.sets.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: exerciseLog.sets.map((set) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity( 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity( 0.3),
                    ),
                  ),
                  child: Text(
                    '${set.reps}×${set.weight.toStringAsFixed(0)}kg',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    final completedWorkout = _completedWorkout;
    if (completedWorkout == null) return const SizedBox.shrink();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Metrics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Metrics grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                _buildMetricTile(
                  'Calories/Min',
                  completedWorkout.caloriesPerMinute.toStringAsFixed(1),
                  Icons.speed,
                ),
                _buildMetricTile(
                  'Volume/Min',
                  '${(completedWorkout.totalVolume / completedWorkout.duration).toStringAsFixed(1)}kg',
                  Icons.trending_up,
                ),
                _buildMetricTile(
                  'Avg Rest',
                  '${completedWorkout.averageRestTime}s',
                  Icons.pause,
                ),
                _buildMetricTile(
                  'Muscle Groups',
                  '${completedWorkout.muscleGroupDistribution?.length ?? 0}',
                  Icons.accessibility_new,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
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
            'Workout Analytics',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Comprehensive analytics widget
          if (_completedWorkout != null)
            WorkoutAnalyticsWidget(
              completedWorkout: _completedWorkout!,
              completedSets: widget.completedSession.completedSets,
              exerciseLogs: widget.completedSession.exerciseLogs,
              exercises: widget.completedSession.exercises,
            ),
        ],
      ),
    );
  }

  Widget _buildRatingAndFeedbackPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rate Your Workout',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Rating system
          _buildRatingSection(),
          
          const SizedBox(height: 24),
          
          // Rich text feedback input
          _buildFeedbackSection(),
          
          const SizedBox(height: 24),
          
          // Submit button
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How was your workout?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Star rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _workoutRating = starIndex;
                    });
                    HapticFeedback.lightImpact();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      _workoutRating != null && starIndex <= _workoutRating!
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 40,
                    ),
                  ),
                );
              }),
            ),
            
            const SizedBox(height: 8),
            
            // Rating description
            if (_workoutRating != null)
              Center(
                child: Text(
                  _getRatingDescription(_workoutRating!),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share your thoughts',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Rich text input for user feedback
            TextField(
              controller: _feedbackController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'How did you feel during the workout? Any notes about your performance, energy levels, or areas for improvement?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitRatingAndFeedback,
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Save Feedback'),
      ),
    );
  }

  Widget _buildAchievementsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Achievements',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Achievement celebration widget
          if (widget.unlockedAchievements?.isNotEmpty == true)
            AchievementCelebrationWidget(
              unlockedAchievements: widget.unlockedAchievements!,
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary.withOpacity( 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No new achievements this time',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Keep pushing yourself to unlock more achievements!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity( 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSocialSharingPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Share Your Success',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Social sharing widget
          if (_completedWorkout != null)
            SocialShareWidget(
              completedWorkout: _completedWorkout!,
              unlockedAchievements: widget.unlockedAchievements ?? [],
            )
          else
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
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
            children: List.generate(5, (index) {
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
                  onPressed: _currentPage < 4
                      ? () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : () {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                  child: Text(_currentPage < 4 ? 'Next' : 'Finish'),
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

  String _getRatingDescription(int rating) {
    switch (rating) {
      case 1:
        return 'Poor - Not feeling it today';
      case 2:
        return 'Fair - Could be better';
      case 3:
        return 'Good - Solid workout';
      case 4:
        return 'Great - Feeling strong!';
      case 5:
        return 'Excellent - Crushed it!';
      default:
        return '';
    }
  }

  int _estimateCalories() {
    // Simple fallback calorie estimation
    return (widget.completedSession.totalDuration.inMinutes * 5.0).round();
  }

  Future<void> _submitRatingAndFeedback() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Update the completed workout if it exists
      if (_completedWorkout != null && (_workoutRating != null || _feedbackController.text.isNotEmpty)) {
        final workoutCompletionService = ref.read(workoutCompletionServiceProvider);
        
        // Re-complete workout with updated rating and feedback
        await workoutCompletionService.completeWorkout(
          workoutId: widget.completedSession.workout.id,
          duration: widget.completedSession.totalDuration,
          completedSets: widget.completedSession.completedSets,
          exerciseLogs: widget.completedSession.exerciseLogs,
          exercises: widget.completedSession.exercises,
          rating: _workoutRating,
          userFeedback: _feedbackController.text.isNotEmpty ? _feedbackController.text : null,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save feedback: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}