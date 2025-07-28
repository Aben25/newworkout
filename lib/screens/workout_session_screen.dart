import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/workout_session_provider.dart';
import '../widgets/workout/workout_session_widgets.dart';
import '../widgets/workout/enhanced_set_logger_widget.dart';
import '../widgets/workout/set_progress_tracker_widget.dart';
import '../utils/app_theme.dart';

/// Main workout execution interface with current exercise display and progress indicators
/// Implements comprehensive workout session management with timer integration
/// Supports gesture controls, haptic feedback, and real-time progress tracking
class WorkoutSessionScreen extends ConsumerStatefulWidget {
  final String workoutId;
  final bool isResuming;

  const WorkoutSessionScreen({
    super.key,
    required this.workoutId,
    this.isResuming = false,
  });

  @override
  ConsumerState<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends ConsumerState<WorkoutSessionScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final PageController _pageController = PageController();
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeSession();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _slideController.forward();
    _fadeController.forward();
  }

  void _initializeSession() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sessionNotifier = ref.read(workoutSessionNotifierProvider.notifier);
      if (widget.isResuming) {
        sessionNotifier.resumeSession(widget.workoutId);
      } else {
        sessionNotifier.startSession(widget.workoutId);
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(workoutSessionNotifierProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: sessionState.when(
        idle: () => _buildLoadingState(),
        loading: () => _buildLoadingState(),
        active: (
          workout,
          workoutExercises,
          exercises,
          currentExerciseIndex,
          currentSet,
          completedSets,
          exerciseLogs,
          startTime,
          lastSyncTime,
          isRestTimerActive,
          restTimeRemaining,
        ) => _buildActiveSession(
          sessionState as WorkoutSessionActive,
          context,
        ),
        paused: (
          workout,
          workoutExercises,
          exercises,
          currentExerciseIndex,
          currentSet,
          completedSets,
          exerciseLogs,
          startTime,
          pausedAt,
        ) => _buildPausedSession(
          sessionState as WorkoutSessionPaused,
          context,
        ),
        completed: (
          workout,
          workoutExercises,
          exercises,
          completedSets,
          exerciseLogs,
          startTime,
          endTime,
          rating,
          notes,
        ) => _buildCompletedSession(
          sessionState as WorkoutSessionCompleted,
          context,
        ),
        error: (message) => _buildErrorState(message, context),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Preparing your workout...',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSession(WorkoutSessionActive sessionState, BuildContext context) {
    return SafeArea(
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Header with workout info and controls
              _buildSessionHeader(sessionState, context),
              
              // Progress indicators
              _buildProgressSection(sessionState, context),
              
              // Main exercise content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onExerciseChanged,
                  itemCount: sessionState.workoutExercises.length,
                  itemBuilder: (context, index) {
                    final workoutExercise = sessionState.workoutExercises[index];
                    final exercise = sessionState.exercises
                        .where((e) => e.id == workoutExercise.exerciseId)
                        .firstOrNull;
                    
                    if (exercise == null) return const SizedBox.shrink();
                    
                    return _buildExerciseContent(
                      sessionState,
                      workoutExercise,
                      exercise,
                      index,
                      context,
                    );
                  },
                ),
              ),
              
              // Bottom controls and timer
              _buildBottomControls(sessionState, context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionHeader(WorkoutSessionActive sessionState, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => _showPauseDialog(context),
                icon: const Icon(Icons.pause),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sessionState.workout.name ?? 'Workout',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Exercise ${sessionState.currentExerciseIndex + 1} of ${sessionState.workoutExercises.length}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              WorkoutTimerWidget(
                elapsedTime: sessionState.elapsedTime,
                isActive: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(WorkoutSessionActive sessionState, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Overall workout progress
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Workout Progress',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: sessionState.progressPercentage,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${(sessionState.progressPercentage * 100).round()}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Exercise progress
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Exercise',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: sessionState.exerciseProgressPercentage,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${sessionState.remainingSetsForCurrentExercise} sets left',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseContent(
    WorkoutSessionActive sessionState,
    WorkoutExercise workoutExercise,
    Exercise exercise,
    int exerciseIndex,
    BuildContext context,
  ) {
    final isCurrentExercise = exerciseIndex == sessionState.currentExerciseIndex;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Exercise info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          exercise.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (exercise.primaryMuscle != null)
                        Chip(
                          label: Text(exercise.primaryMuscle!),
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  if (exercise.instructions != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      exercise.instructions!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildExerciseInfoChip(
                        context,
                        Icons.fitness_center,
                        '${workoutExercise.effectiveSets} sets',
                      ),
                      const SizedBox(width: 8),
                      if (workoutExercise.reps?.isNotEmpty == true)
                        _buildExerciseInfoChip(
                          context,
                          Icons.repeat,
                          '${workoutExercise.reps!.first} reps',
                        ),
                      const SizedBox(width: 8),
                      if (workoutExercise.restInterval != null)
                        _buildExerciseInfoChip(
                          context,
                          Icons.timer,
                          '${workoutExercise.restInterval}s rest',
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Enhanced set logger with comprehensive tracking (only for current exercise)
          if (isCurrentExercise) ...[
            Expanded(
              child: Column(
                children: [
                  // Set progress tracker
                  SetProgressTrackerWidget(
                    workoutExercise: workoutExercise,
                    exercise: exercise,
                    completedSets: sessionState.completedSets
                        .where((set) => set.exerciseIndex == exerciseIndex)
                        .toList(),
                    showDetailedAnalysis: false, // Compact view during workout
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Enhanced set logger
                  Expanded(
                    child: EnhancedSetLoggerWidget(
                      workoutExercise: workoutExercise,
                      exercise: exercise,
                      currentSet: sessionState.currentSet,
                      completedSets: sessionState.completedSets
                          .where((set) => set.exerciseIndex == exerciseIndex)
                          .toList(),
                      onSetCompleted: _onSetCompleted,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Show completed sets for other exercises
            Expanded(
              child: _buildCompletedSetsView(
                sessionState.completedSets
                    .where((set) => set.exerciseIndex == exerciseIndex)
                    .toList(),
                context,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExerciseInfoChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedSetsView(List<CompletedSetLog> completedSets, BuildContext context) {
    if (completedSets.isEmpty) {
      return Center(
        child: Text(
          'No sets completed yet',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: completedSets.length,
      itemBuilder: (context, index) {
        final set = completedSets[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.successColor,
              child: Text(
                '${set.setNumber}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text('${set.reps} reps'),
            subtitle: set.weight > 0 ? Text('${set.weight}kg') : null,
            trailing: set.difficultyRating != null
                ? Chip(
                    label: Text(set.difficultyRating!),
                    backgroundColor: _getDifficultyColor(set.difficultyRating!),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildBottomControls(WorkoutSessionActive sessionState, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Rest timer (if active)
          if (sessionState.isRestTimerActive) ...[
            ExerciseTimerWidget(
              timeRemaining: sessionState.restTimeRemaining,
              isActive: sessionState.isRestTimerActive,
              onSkip: () => ref.read(workoutSessionNotifierProvider.notifier).skipRest(),
              onAddTime: (seconds) => ref.read(workoutSessionNotifierProvider.notifier).addRestTime(seconds),
            ),
            const SizedBox(height: 16),
          ],
          
          // Navigation controls
          WorkoutNavigationControls(
            canGoPrevious: sessionState.currentExerciseIndex > 0,
            canGoNext: sessionState.currentExerciseIndex < sessionState.workoutExercises.length - 1,
            onPrevious: _previousExercise,
            onNext: _nextExercise,
            onPause: () => _showPauseDialog(context),
            onComplete: () => _showCompleteDialog(context),
            isLastExercise: sessionState.currentExerciseIndex >= sessionState.workoutExercises.length - 1,
          ),
        ],
      ),
    );
  }

  Widget _buildPausedSession(WorkoutSessionPaused sessionState, BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.pause_circle_filled,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Workout Paused',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Elapsed time: ${_formatDuration(sessionState.elapsedTime)}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text(
                'Progress: ${(sessionState.progressPercentage * 100).round()}%',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => ref.read(workoutSessionNotifierProvider.notifier).resumeSession(widget.workoutId),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Resume'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showCancelDialog(context),
                    icon: const Icon(Icons.stop),
                    label: const Text('End Workout'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedSession(WorkoutSessionCompleted sessionState, BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                size: 64,
                color: AppTheme.successColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Workout Complete!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Duration: ${_formatDuration(sessionState.totalDuration)}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text(
                'Sets completed: ${sessionState.totalSetsCompleted}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Event handlers
  void _onExerciseChanged(int index) {
    if (_isNavigating) return;
    
    final sessionNotifier = ref.read(workoutSessionNotifierProvider.notifier);
    final currentState = ref.read(workoutSessionNotifierProvider);
    
    if (currentState is WorkoutSessionActive) {
      if (index > currentState.currentExerciseIndex) {
        sessionNotifier.nextExercise();
      } else if (index < currentState.currentExerciseIndex) {
        sessionNotifier.previousExercise();
      }
    }
  }

  void _onSetCompleted(int reps, double weight, String? difficultyRating, String? notes) {
    HapticFeedback.lightImpact();
    
    ref.read(workoutSessionNotifierProvider.notifier).logSet(
      reps: reps,
      weight: weight,
      difficultyRating: difficultyRating,
      notes: notes,
    );
  }

  void _nextExercise() {
    _isNavigating = true;
    ref.read(workoutSessionNotifierProvider.notifier).nextExercise();
    
    final currentState = ref.read(workoutSessionNotifierProvider);
    if (currentState is WorkoutSessionActive) {
      _pageController.animateToPage(
        currentState.currentExerciseIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ).then((_) => _isNavigating = false);
    }
  }

  void _previousExercise() {
    _isNavigating = true;
    ref.read(workoutSessionNotifierProvider.notifier).previousExercise();
    
    final currentState = ref.read(workoutSessionNotifierProvider);
    if (currentState is WorkoutSessionActive) {
      _pageController.animateToPage(
        currentState.currentExerciseIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ).then((_) => _isNavigating = false);
    }
  }

  void _showPauseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pause Workout'),
        content: const Text('Are you sure you want to pause your workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(workoutSessionNotifierProvider.notifier).pauseSession();
            },
            child: const Text('Pause'),
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Workout'),
        content: const Text('Are you ready to finish your workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(workoutSessionNotifierProvider.notifier).completeSession();
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Workout'),
        content: const Text('Are you sure you want to end this workout? Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(workoutSessionNotifierProvider.notifier).cancelSession();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('End Workout'),
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
      return '${hours}h ${minutes}m ${seconds}s';
    } else {
      return '${minutes}m ${seconds}s';
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'very_easy':
        return Colors.green.shade100;
      case 'easy':
        return Colors.lightGreen.shade100;
      case 'moderate':
        return Colors.orange.shade100;
      case 'hard':
        return Colors.red.shade100;
      case 'very_hard':
        return Colors.red.shade200;
      default:
        return Colors.grey.shade100;
    }
  }
}