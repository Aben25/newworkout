import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';

/// Exercise timer widget with circular progress, visual countdown, and audio cues
/// Provides comprehensive rest timer functionality with skip and add time options
class ExerciseTimerWidget extends StatefulWidget {
  final int timeRemaining;
  final bool isActive;
  final VoidCallback? onSkip;
  final Function(int seconds)? onAddTime;
  final int? totalTime;

  const ExerciseTimerWidget({
    super.key,
    required this.timeRemaining,
    required this.isActive,
    this.onSkip,
    this.onAddTime,
    this.totalTime,
  });

  @override
  State<ExerciseTimerWidget> createState() => _ExerciseTimerWidgetState();
}

class _ExerciseTimerWidgetState extends State<ExerciseTimerWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    if (widget.isActive) {
      _pulseController.repeat(reverse: true);
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(ExerciseTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _pulseController.repeat(reverse: true);
        _rotationController.repeat();
      } else {
        _pulseController.stop();
        _rotationController.stop();
      }
    }

    // Haptic feedback for last 10 seconds
    if (widget.timeRemaining <= 10 && widget.timeRemaining > 0 && 
        oldWidget.timeRemaining != widget.timeRemaining) {
      HapticFeedback.lightImpact();
    }

    // Strong haptic feedback when timer completes
    if (widget.timeRemaining == 0 && oldWidget.timeRemaining > 0) {
      HapticFeedback.heavyImpact();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.totalTime != null && widget.totalTime! > 0
        ? (widget.totalTime! - widget.timeRemaining) / widget.totalTime!
        : 0.0;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Rest Timer',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Circular timer
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: widget.isActive ? _pulseAnimation.value : 1.0,
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background circle
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          ),
                        ),
                        
                        // Progress circle
                        AnimatedBuilder(
                          animation: _rotationController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: widget.isActive ? _rotationAnimation.value : 0,
                              child: SizedBox(
                                width: 120,
                                height: 120,
                                child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 8,
                                  backgroundColor: Colors.transparent,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getTimerColor(widget.timeRemaining),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        
                        // Time text
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatTime(widget.timeRemaining),
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _getTimerColor(widget.timeRemaining),
                              ),
                            ),
                            if (widget.isActive)
                              Text(
                                'remaining',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Timer controls
            if (widget.isActive) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Add 30 seconds
                  _buildTimerButton(
                    context,
                    icon: Icons.add,
                    label: '+30s',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      widget.onAddTime?.call(30);
                    },
                  ),
                  
                  // Skip rest
                  _buildTimerButton(
                    context,
                    icon: Icons.skip_next,
                    label: 'Skip',
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      widget.onSkip?.call();
                    },
                    isPrimary: true,
                  ),
                  
                  // Add 60 seconds
                  _buildTimerButton(
                    context,
                    icon: Icons.add,
                    label: '+60s',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      widget.onAddTime?.call(60);
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimerButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return Column(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            backgroundColor: isPrimary
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            foregroundColor: isPrimary
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _getTimerColor(int timeRemaining) {
    if (timeRemaining <= 10) {
      return AppTheme.errorColor;
    } else if (timeRemaining <= 30) {
      return AppTheme.warningColor;
    } else {
      return AppTheme.successColor;
    }
  }
}

/// Set logger widget for logging reps, weights, and performance with input validation
/// Provides comprehensive set tracking with difficulty rating and notes
class SetLoggerWidget extends StatefulWidget {
  final WorkoutExercise workoutExercise;
  final Exercise exercise;
  final int currentSet;
  final List<CompletedSetLog> completedSets;
  final Function(int reps, double weight, String? difficultyRating, String? notes) onSetCompleted;

  const SetLoggerWidget({
    super.key,
    required this.workoutExercise,
    required this.exercise,
    required this.currentSet,
    required this.completedSets,
    required this.onSetCompleted,
  });

  @override
  State<SetLoggerWidget> createState() => _SetLoggerWidgetState();
}

class _SetLoggerWidgetState extends State<SetLoggerWidget>
    with TickerProviderStateMixin {
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  late TextEditingController _notesController;
  
  String? _selectedDifficulty;
  bool _isLogging = false;
  
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  final List<String> _difficultyOptions = [
    'very_easy',
    'easy',
    'moderate',
    'hard',
    'very_hard',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAnimations();
    _loadPreviousSetData();
  }

  void _initializeControllers() {
    _repsController = TextEditingController();
    _weightController = TextEditingController();
    _notesController = TextEditingController();
  }

  void _initializeAnimations() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
  }

  void _loadPreviousSetData() {
    // Load suggested values from previous set or workout exercise configuration
    if (widget.completedSets.isNotEmpty) {
      final lastSet = widget.completedSets.last;
      _repsController.text = lastSet.reps.toString();
      _weightController.text = lastSet.weight.toString();
    } else {
      // Load from workout exercise configuration
      if (widget.workoutExercise.reps?.isNotEmpty == true) {
        _repsController.text = widget.workoutExercise.reps!.first.toString();
      }
      if (widget.workoutExercise.weight?.isNotEmpty == true) {
        _weightController.text = widget.workoutExercise.weight!.first.toString();
      }
    }
  }

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value * 10 * math.sin(_shakeAnimation.value * math.pi * 8), 0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Set header
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          '${widget.currentSet}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Set ${widget.currentSet} of ${widget.workoutExercise.effectiveSets}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Log your performance',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Input fields
                  Row(
                    children: [
                      // Reps input
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reps',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _repsController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: '0',
                                prefixIcon: Icon(Icons.repeat),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                final reps = int.tryParse(value);
                                if (reps == null || reps <= 0) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Weight input
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Weight (kg)',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _weightController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                hintText: '0.0',
                                prefixIcon: Icon(Icons.fitness_center),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                final weight = double.tryParse(value);
                                if (weight == null || weight < 0) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Difficulty rating
                  Text(
                    'Difficulty Rating',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _difficultyOptions.map((difficulty) {
                      final isSelected = _selectedDifficulty == difficulty;
                      return FilterChip(
                        label: Text(_formatDifficulty(difficulty)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedDifficulty = selected ? difficulty : null;
                          });
                          if (selected) {
                            HapticFeedback.selectionClick();
                          }
                        },
                        backgroundColor: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        selectedColor: Theme.of(context).colorScheme.primaryContainer,
                        checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Notes input
                  Text(
                    'Notes (optional)',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Add notes about this set...',
                      prefixIcon: Icon(Icons.note),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Action buttons
                  Row(
                    children: [
                      // Quick increment/decrement buttons
                      Expanded(
                        child: Row(
                          children: [
                            _buildQuickButton(
                              context,
                              icon: Icons.remove,
                              onPressed: () => _adjustReps(-1),
                              tooltip: 'Decrease reps',
                            ),
                            const SizedBox(width: 8),
                            _buildQuickButton(
                              context,
                              icon: Icons.add,
                              onPressed: () => _adjustReps(1),
                              tooltip: 'Increase reps',
                            ),
                            const SizedBox(width: 16),
                            _buildQuickButton(
                              context,
                              icon: Icons.remove,
                              onPressed: () => _adjustWeight(-2.5),
                              tooltip: 'Decrease weight',
                            ),
                            const SizedBox(width: 8),
                            _buildQuickButton(
                              context,
                              icon: Icons.add,
                              onPressed: () => _adjustWeight(2.5),
                              tooltip: 'Increase weight',
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Complete set button
                      ElevatedButton.icon(
                        onPressed: _isLogging ? null : _completeSet,
                        icon: _isLogging
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check),
                        label: Text(_isLogging ? 'Logging...' : 'Complete Set'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                  
                  // Previous sets display
                  if (widget.completedSets.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Previous Sets',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.completedSets.length,
                        itemBuilder: (context, index) {
                          final set = widget.completedSets[index];
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Set ${set.setNumber}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${set.reps} × ${set.weight}kg',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        style: IconButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          minimumSize: const Size(32, 32),
          padding: const EdgeInsets.all(4),
        ),
      ),
    );
  }

  void _adjustReps(int delta) {
    final currentReps = int.tryParse(_repsController.text) ?? 0;
    final newReps = (currentReps + delta).clamp(0, 999);
    _repsController.text = newReps.toString();
    HapticFeedback.lightImpact();
  }

  void _adjustWeight(double delta) {
    final currentWeight = double.tryParse(_weightController.text) ?? 0.0;
    final newWeight = (currentWeight + delta).clamp(0.0, 999.9);
    _weightController.text = newWeight.toStringAsFixed(1);
    HapticFeedback.lightImpact();
  }

  void _completeSet() async {
    // Validate inputs
    final reps = int.tryParse(_repsController.text);
    final weight = double.tryParse(_weightController.text);

    if (reps == null || reps <= 0) {
      _shakeController.forward().then((_) => _shakeController.reset());
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid reps')),
      );
      return;
    }

    if (weight == null || weight < 0) {
      _shakeController.forward().then((_) => _shakeController.reset());
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid weight')),
      );
      return;
    }

    setState(() {
      _isLogging = true;
    });

    try {
      // Complete the set
      widget.onSetCompleted(
        reps,
        weight,
        _selectedDifficulty,
        _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      // Success feedback
      HapticFeedback.heavyImpact();
      
      // Clear notes for next set
      _notesController.clear();
      _selectedDifficulty = null;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Set ${widget.currentSet} completed!'),
          backgroundColor: AppTheme.successColor,
          duration: const Duration(seconds: 1),
        ),
      );

    } catch (e) {
      // Error feedback
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging set: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLogging = false;
        });
      }
    }
  }

  String _formatDifficulty(String difficulty) {
    switch (difficulty) {
      case 'very_easy':
        return 'Very Easy';
      case 'easy':
        return 'Easy';
      case 'moderate':
        return 'Moderate';
      case 'hard':
        return 'Hard';
      case 'very_hard':
        return 'Very Hard';
      default:
        return difficulty;
    }
  }
}

/// Workout navigation controls with gesture support and haptic feedback
/// Provides previous, next, pause, skip controls with visual feedback
class WorkoutNavigationControls extends StatelessWidget {
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPause;
  final VoidCallback onComplete;
  final bool isLastExercise;

  const WorkoutNavigationControls({
    super.key,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    required this.onPause,
    required this.onComplete,
    required this.isLastExercise,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Previous exercise
        Expanded(
          child: OutlinedButton.icon(
            onPressed: canGoPrevious ? () {
              HapticFeedback.lightImpact();
              onPrevious();
            } : null,
            icon: const Icon(Icons.skip_previous),
            label: const Text('Previous'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Pause button
        OutlinedButton.icon(
          onPressed: () {
            HapticFeedback.mediumImpact();
            onPause();
          },
          icon: const Icon(Icons.pause),
          label: const Text('Pause'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Next exercise or complete
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              if (isLastExercise) {
                onComplete();
              } else {
                onNext();
              }
            },
            icon: Icon(isLastExercise ? Icons.check : Icons.skip_next),
            label: Text(isLastExercise ? 'Complete' : 'Next'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: isLastExercise 
                  ? AppTheme.successColor 
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Workout timer widget for displaying elapsed workout time
/// Shows formatted time with active/inactive states
class WorkoutTimerWidget extends StatelessWidget {
  final Duration elapsedTime;
  final bool isActive;

  const WorkoutTimerWidget({
    super.key,
    required this.elapsedTime,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive 
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.timer : Icons.timer_off,
            size: 16,
            color: isActive
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
          Text(
            _formatDuration(elapsedTime),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isActive
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m ${seconds}s';
    }
  }
}