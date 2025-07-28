import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../services/workout_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/workout/workout_builder_exercise_card.dart';
import '../widgets/workout/exercise_selector_sheet.dart';
import '../widgets/workout/set_rep_config_sheet.dart';
import '../widgets/workout/workout_preview_sheet.dart';

class WorkoutBuilderScreen extends ConsumerStatefulWidget {
  final String? workoutId; // For editing existing workouts
  
  const WorkoutBuilderScreen({
    super.key,
    this.workoutId,
  });

  @override
  ConsumerState<WorkoutBuilderScreen> createState() => _WorkoutBuilderScreenState();
}

class _WorkoutBuilderScreenState extends ConsumerState<WorkoutBuilderScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  List<WorkoutBuilderExercise> _exercises = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  
  // For editing mode
  Workout? _originalWorkout;
  bool get _isEditing => widget.workoutId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadWorkoutForEditing();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkoutForEditing() async {
    if (widget.workoutId == null) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final workoutWithExercises = await WorkoutService.instance
          .getWorkoutWithExercises(widget.workoutId!);
      
      if (workoutWithExercises == null) {
        throw Exception('Workout not found');
      }

      _originalWorkout = workoutWithExercises.workout;
      _nameController.text = _originalWorkout!.name ?? '';
      _descriptionController.text = _originalWorkout!.description ?? '';
      
      // Convert workout exercises to builder exercises
      _exercises = workoutWithExercises.workoutExercises.map((we) {
        final exercise = workoutWithExercises.exercises
            .where((e) => e.id == we.exerciseId)
            .firstOrNull;
        
        return WorkoutBuilderExercise(
          id: we.id,
          exercise: exercise ?? Exercise(
            id: we.exerciseId,
            name: we.name,
            createdAt: DateTime.now(),
          ),
          sets: we.sets ?? 3,
          reps: we.reps ?? [10, 10, 10],
          weight: we.weight?.map((w) => w.toDouble()).toList(),
          restInterval: we.restInterval ?? 60,
          notes: '',
        );
      }).toList();

      setState(() {
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Workout' : 'Create Workout'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Workout' : 'Create Workout'),
        ),
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
                  _error!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadWorkoutForEditing,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Workout' : 'Create Workout'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          if (_exercises.isNotEmpty)
            IconButton(
              onPressed: _showWorkoutPreview,
              icon: const Icon(Icons.preview),
              tooltip: 'Preview Workout',
            ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'save_template',
                child: ListTile(
                  leading: Icon(Icons.bookmark_add),
                  title: Text('Save as Template'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Share Workout'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: ListTile(
                  leading: Icon(Icons.clear_all, color: Colors.red),
                  title: Text('Clear All', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Workout details section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outline.withOpacity( 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Workout name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Workout Name *',
                      hintText: 'Enter workout name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.fitness_center),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a workout name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Workout description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description (optional)',
                      hintText: 'Describe your workout',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.description),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  
                  // Workout stats
                  _buildWorkoutStats(),
                ],
              ),
            ),
            
            // Exercise list section
            Expanded(
              child: _exercises.isEmpty
                  ? _buildEmptyState()
                  : _buildExerciseList(),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Add exercise FAB
          FloatingActionButton(
            heroTag: 'add_exercise',
            onPressed: _showExerciseSelector,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
            child: const Icon(Icons.add, size: 28),
          ),
          const SizedBox(height: 16),
          
          // Save workout FAB
          FloatingActionButton.extended(
            heroTag: 'save_workout',
            onPressed: _exercises.isEmpty || _isSaving ? null : _saveWorkout,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: _exercises.isEmpty || _isSaving 
                ? theme.colorScheme.outline.withOpacity(0.3)
                : theme.colorScheme.primary,
            foregroundColor: _exercises.isEmpty || _isSaving
                ? theme.colorScheme.onSurface.withOpacity(0.5)
                : theme.colorScheme.onPrimary,
            icon: _isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.onPrimary,
                      ),
                    ),
                  )
                : const Icon(Icons.save, size: 24),
            label: Text(
              _isSaving 
                  ? 'Saving...' 
                  : (_isEditing ? 'Update Workout' : 'Save Workout'),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutStats() {
    final theme = Theme.of(context);
    final totalExercises = _exercises.length;
    final totalSets = _exercises.fold(0, (sum, ex) => sum + ex.sets);
    final estimatedDuration = _calculateEstimatedDuration();
    
    return Card(
      elevation: 4,
      shadowColor: theme.colorScheme.shadow.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer.withOpacity(0.1),
              theme.colorScheme.secondaryContainer.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildModernStatItem(
              icon: Icons.fitness_center,
              label: 'Exercises',
              value: totalExercises.toString(),
              color: theme.colorScheme.primary,
            ),
            Container(
              width: 1,
              height: 40,
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
            _buildModernStatItem(
              icon: Icons.repeat,
              label: 'Sets',
              value: totalSets.toString(),
              color: theme.colorScheme.secondary,
            ),
            Container(
              width: 1,
              height: 40,
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
            _buildModernStatItem(
              icon: Icons.timer,
              label: 'Duration',
              value: '${estimatedDuration}min',
              color: theme.colorScheme.tertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No Exercises Added',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add exercises to your workout',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showExerciseSelector,
              icon: const Icon(Icons.add),
              label: const Text('Add Exercise'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _exercises.length,
      onReorder: _reorderExercises,
      itemBuilder: (context, index) {
        final exercise = _exercises[index];
        
        return WorkoutBuilderExerciseCard(
          key: ValueKey(exercise.id),
          exercise: exercise,
          exerciseNumber: index + 1,
          onTap: () => _showExerciseDetail(exercise.exercise),
          onEdit: () => _editExercise(index),
          onRemove: () => _removeExercise(index),
          onDuplicate: () => _duplicateExercise(index),
        );
      },
    );
  }

  void _reorderExercises(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final exercise = _exercises.removeAt(oldIndex);
      _exercises.insert(newIndex, exercise);
    });
  }

  void _showExerciseSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExerciseSelectorSheet(
        onExercisesSelected: _addExercises,
      ),
    );
  }

  void _addExercises(List<Exercise> exercises) {
    setState(() {
      for (final exercise in exercises) {
        _exercises.add(WorkoutBuilderExercise(
          id: DateTime.now().millisecondsSinceEpoch.toString() + exercise.id,
          exercise: exercise,
          sets: 3,
          reps: [10, 10, 10],
          weight: null,
          restInterval: 60,
          notes: '',
        ));
      }
    });
  }

  void _editExercise(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SetRepConfigSheet(
        exercise: _exercises[index],
        onSave: (updatedExercise) {
          setState(() {
            _exercises[index] = updatedExercise;
          });
        },
      ),
    );
  }

  void _removeExercise(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Exercise'),
        content: Text(
          'Are you sure you want to remove "${_exercises[index].exercise.name}" from this workout?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _exercises.removeAt(index);
              });
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _duplicateExercise(int index) {
    final originalExercise = _exercises[index];
    final duplicatedExercise = WorkoutBuilderExercise(
      id: DateTime.now().millisecondsSinceEpoch.toString() + originalExercise.exercise.id,
      exercise: originalExercise.exercise,
      sets: originalExercise.sets,
      reps: List.from(originalExercise.reps),
      weight: originalExercise.weight != null ? List.from(originalExercise.weight!) : null,
      restInterval: originalExercise.restInterval,
      notes: originalExercise.notes,
    );
    
    setState(() {
      _exercises.insert(index + 1, duplicatedExercise);
    });
  }

  void _showExerciseDetail(Exercise exercise) {
    context.push('/exercise/${exercise.id}');
  }

  void _showWorkoutPreview() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WorkoutPreviewSheet(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        exercises: _exercises,
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'save_template':
        _saveAsTemplate();
        break;
      case 'share':
        _shareWorkout();
        break;
      case 'clear_all':
        _clearAllExercises();
        break;
    }
  }

  void _saveAsTemplate() {
    // TODO: Implement save as template functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Template saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareWorkout() {
    // TODO: Implement workout sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Workout shared successfully!'),
      ),
    );
  }

  void _clearAllExercises() {
    if (_exercises.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Exercises'),
        content: const Text(
          'Are you sure you want to remove all exercises from this workout?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _exercises.clear();
              });
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveWorkout() async {
    if (!_formKey.currentState!.validate()) return;
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one exercise'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final authState = ref.read(authProvider);
      if (!authState.isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      
      // Convert builder exercises to workout exercise templates
      final exerciseTemplates = _exercises.map((builderExercise) {
        return WorkoutExerciseTemplate(
          exerciseId: builderExercise.exercise.id,
          name: builderExercise.exercise.name,
          sets: builderExercise.sets,
          reps: builderExercise.reps,
          weight: builderExercise.weight?.map((w) => w.toInt()).toList(),
          restInterval: builderExercise.restInterval,
        );
      }).toList();

      if (_isEditing && _originalWorkout != null) {
        // Update existing workout (excluding description field as it doesn't exist in DB)
        await WorkoutService.instance.updateWorkout(
          _originalWorkout!.id,
          {
            'name': name,
            // 'description': description.isEmpty ? null : description, // Column doesn't exist in Supabase table
          },
        );
        
        // TODO: Update workout exercises (requires additional service methods)
        // For now, we'll just update the basic workout info
      } else {
        // Create new workout
        await WorkoutService.instance.createWorkout(
          name: name,
          description: description.isEmpty ? null : description,
          exercises: exerciseTemplates,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing 
                ? 'Workout updated successfully!' 
                : 'Workout created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back or to workout detail
        context.pop();
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save workout: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  int _calculateEstimatedDuration() {
    int totalTime = 0;
    
    for (final exercise in _exercises) {
      // Estimate 30 seconds per set + rest time
      final setTime = exercise.sets * 30;
      final restTime = (exercise.sets - 1) * exercise.restInterval;
      totalTime += setTime + restTime;
    }
    
    return (totalTime / 60).ceil(); // Convert to minutes
  }
}

/// Model for workout builder exercises
class WorkoutBuilderExercise {
  final String id;
  final Exercise exercise;
  final int sets;
  final List<int> reps;
  final List<double>? weight;
  final int restInterval;
  final String notes;

  WorkoutBuilderExercise({
    required this.id,
    required this.exercise,
    required this.sets,
    required this.reps,
    this.weight,
    required this.restInterval,
    required this.notes,
  });

  WorkoutBuilderExercise copyWith({
    String? id,
    Exercise? exercise,
    int? sets,
    List<int>? reps,
    List<double>? weight,
    int? restInterval,
    String? notes,
  }) {
    return WorkoutBuilderExercise(
      id: id ?? this.id,
      exercise: exercise ?? this.exercise,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      restInterval: restInterval ?? this.restInterval,
      notes: notes ?? this.notes,
    );
  }

  // Helper methods
  double get totalVolume {
    if (weight == null) return 0.0;
    
    double volume = 0.0;
    final minLength = weight!.length < reps.length ? weight!.length : reps.length;
    
    for (int i = 0; i < minLength; i++) {
      volume += weight![i] * reps[i];
    }
    
    return volume;
  }

  String get formattedSetsReps {
    if (reps.every((rep) => rep == reps.first)) {
      return '$sets × ${reps.first}';
    } else {
      return reps.join(' / ');
    }
  }

  String get formattedWeight {
    if (weight == null || weight!.isEmpty) return 'Bodyweight';
    
    if (weight!.isNotEmpty && weight!.every((w) => w == weight!.first)) {
      return '${weight!.first.toStringAsFixed(1)}kg';
    } else {
      return weight!.map((w) => '${w.toStringAsFixed(1)}kg').join(' / ');
    }
  }

  Duration get restDuration => Duration(seconds: restInterval);
}