import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../providers/workout_provider.dart';
import '../services/workout_service.dart';
import '../widgets/workout/exercise_preview_card.dart';
import '../widgets/workout/workout_stats_card.dart';
import '../widgets/workout/difficulty_indicator.dart';
import '../widgets/workout/equipment_chips.dart';
import '../widgets/workout/muscle_group_chips.dart';


class WorkoutDetailScreen extends ConsumerStatefulWidget {
  final String workoutId;

  const WorkoutDetailScreen({
    super.key,
    required this.workoutId,
  });

  @override
  ConsumerState<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends ConsumerState<WorkoutDetailScreen> {
  bool _isStarting = false;



  Widget _buildWorkoutDetail(WorkoutWithExercises workoutWithExercises) {
    final theme = Theme.of(context);
    final workout = workoutWithExercises.workout;
    final exercises = workoutWithExercises.exercises;
    final workoutExercises = workoutWithExercises.workoutExercises;

    return CustomScrollView(
      slivers: [
        // App Bar with workout name and actions
        SliverAppBar(
          expandedHeight: 200,
          floating: false,
          pinned: true,
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              workout.name ?? 'Workout',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: const Offset(0, 1),
                    blurRadius: 3,
                    color: Colors.black.withOpacity(0.3),
                  ),
                ],
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.8),
                    theme.colorScheme.primary.withOpacity(0.4),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Background pattern
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.1,
                      child: Image.asset(
                        'assets/images/workout_pattern.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(),
                      ),
                    ),
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            IconButton(
              onPressed: () => _shareWorkout(workout),
              icon: const Icon(Icons.share),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, workout),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Edit Workout'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'duplicate',
                  child: ListTile(
                    leading: Icon(Icons.copy),
                    title: Text('Duplicate'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Workout overview section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                if (workout.hasDescription) ...[
                  Text(
                    workout.description!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Workout stats
                WorkoutStatsCard(
                  estimatedDuration: workoutWithExercises.estimatedDuration,
                  totalExercises: workoutWithExercises.totalExercises,
                  totalSets: workoutWithExercises.totalSets,
                  hasVideoContent: workoutWithExercises.hasVideoContent,
                ),
                const SizedBox(height: 16),

                // Difficulty indicator
                Row(
                  children: [
                    Text(
                      'Difficulty:',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    DifficultyIndicator(
                      difficulty: _calculateDifficulty(workoutWithExercises),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Targeted muscle groups
                if (workoutWithExercises.targetedMuscleGroups.isNotEmpty) ...[
                  Text(
                    'Targeted Muscles',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  MuscleGroupChips(
                    muscleGroups: workoutWithExercises.targetedMuscleGroups,
                  ),
                  const SizedBox(height: 16),
                ],

                // Required equipment
                if (workoutWithExercises.requiredEquipment.isNotEmpty) ...[
                  Text(
                    'Required Equipment',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  EquipmentChips(
                    equipment: workoutWithExercises.requiredEquipment,
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),

        // Exercise list header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Exercises (${exercises.length})',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _previewAllExercises(exercises),
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Preview All'),
                ),
              ],
            ),
          ),
        ),

        // Exercise list
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final workoutExercise = workoutExercises[index];
              final exercise = exercises.firstWhere(
                (e) => e.id == workoutExercise.exerciseId,
                orElse: () => Exercise(
                  id: workoutExercise.exerciseId,
                  name: workoutExercise.name,
                  createdAt: DateTime.now(),
                ),
              );

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ExercisePreviewCard(
                  exercise: exercise,
                  workoutExercise: workoutExercise,
                  exerciseNumber: index + 1,
                  onTap: () => _showExerciseDetail(exercise),
                  onPreview: () => _previewExercise(exercise),
                ),
              );
            },
            childCount: workoutExercises.length,
          ),
        ),

        // Bottom padding for FAB
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(String error) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Workout Details')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load workout',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.refresh(workoutWithExercisesProvider(widget.workoutId)),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotFoundWidget() {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Workout Details')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Workout Not Found',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The workout you\'re looking for doesn\'t exist or has been deleted.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _calculateDifficulty(WorkoutWithExercises workoutWithExercises) {
    // Simple difficulty calculation based on exercise count and equipment
    final exerciseCount = workoutWithExercises.totalExercises;
    final hasAdvancedEquipment = workoutWithExercises.requiredEquipment
        .any((eq) => ['barbell', 'cable machine', 'olympic rings'].contains(eq.toLowerCase()));
    
    if (exerciseCount <= 4 && !hasAdvancedEquipment) {
      return 'Beginner';
    } else if (exerciseCount <= 8) {
      return 'Intermediate';
    } else {
      return 'Advanced';
    }
  }

  void _shareWorkout(Workout workout) {
    // TODO: Implement workout sharing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing ${workout.name ?? 'workout'}...'),
      ),
    );
  }

  void _handleMenuAction(String action, Workout workout) {
    switch (action) {
      case 'edit':
        _editWorkout(workout);
        break;
      case 'duplicate':
        _duplicateWorkout(workout);
        break;
      case 'delete':
        _deleteWorkout(workout);
        break;
    }
  }

  void _editWorkout(Workout workout) {
    context.push('/workout-builder/${workout.id}');
  }

  void _duplicateWorkout(Workout workout) {
    // TODO: Implement workout duplication
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Duplicating ${workout.name ?? 'workout'}...'),
      ),
    );
  }

  void _deleteWorkout(Workout workout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workout'),
        content: Text('Are you sure you want to delete "${workout.name ?? 'this workout'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await WorkoutService.instance.deleteWorkout(workout.id);
                if (mounted) {
                  context.pop(); // Go back to previous screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Workout deleted')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete workout: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showExerciseDetail(Exercise exercise) {
    context.push('/exercise/${exercise.id}');
  }

  void _previewExercise(Exercise exercise) {
    // TODO: Show exercise preview modal
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(exercise.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (exercise.description != null) ...[
              Text(exercise.description!),
              const SizedBox(height: 8),
            ],
            if (exercise.primaryMuscle != null) ...[
              Text('Primary: ${exercise.primaryMuscle}'),
              const SizedBox(height: 4),
            ],
            if (exercise.equipment != null) ...[
              Text('Equipment: ${exercise.equipment}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showExerciseDetail(exercise);
            },
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }

  void _previewAllExercises(List<Exercise> exercises) {
    // TODO: Show exercise preview carousel
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Previewing ${exercises.length} exercises...'),
      ),
    );
  }

  Future<void> _startWorkout() async {
    if (_isStarting) return;

    setState(() {
      _isStarting = true;
    });

    try {
      final workoutNotifier = ref.read(workoutNotifierProvider.notifier);
      await workoutNotifier.startWorkout(widget.workoutId);

      if (mounted) {
        // TODO: Navigate to workout session screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout started!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start workout: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isStarting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutWithExercisesAsync = ref.watch(
      workoutWithExercisesProvider(widget.workoutId),
    );

    return Scaffold(
      body: workoutWithExercisesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _buildErrorWidget(error.toString()),
        data: (workoutWithExercises) {
          if (workoutWithExercises == null) {
            return _buildNotFoundWidget();
          }
          return _buildWorkoutDetail(workoutWithExercises);
        },
      ),
      floatingActionButton: workoutWithExercisesAsync.when(
        loading: () => null,
        error: (_, __) => null,
        data: (workoutWithExercises) {
          if (workoutWithExercises == null) return null;
          
          return FloatingActionButton.extended(
            onPressed: _isStarting ? null : _startWorkout,
            icon: _isStarting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(_isStarting ? 'Starting...' : 'Start Workout'),
          );
        },
      ),
    );
  }


}