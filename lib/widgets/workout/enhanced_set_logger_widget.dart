import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../services/set_logging_service.dart';
import '../../utils/app_theme.dart';

/// Enhanced set logger widget with comprehensive performance tracking
/// Implements dual logging, progression tracking, and visual progress indicators
class EnhancedSetLoggerWidget extends ConsumerStatefulWidget {
  final WorkoutExercise workoutExercise;
  final Exercise exercise;
  final int currentSet;
  final List<CompletedSetLog> completedSets;
  final Function(int reps, double weight, String? difficultyRating, String? notes) onSetCompleted;

  const EnhancedSetLoggerWidget({
    super.key,
    required this.workoutExercise,
    required this.exercise,
    required this.currentSet,
    required this.completedSets,
    required this.onSetCompleted,
  });

  @override
  ConsumerState<EnhancedSetLoggerWidget> createState() => _EnhancedSetLoggerWidgetState();
}

class _EnhancedSetLoggerWidgetState extends ConsumerState<EnhancedSetLoggerWidget>
    with TickerProviderStateMixin {
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  late TextEditingController _notesController;
  
  String? _selectedDifficulty;
  bool _isLogging = false;
  PerformanceComparison? _performanceComparison;
  WeightProgressionSuggestion? _progressionSuggestion;
  
  late AnimationController _shakeController;
  late AnimationController _progressController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _progressAnimation;

  final List<DifficultyRating> _difficultyOptions = [
    DifficultyRating('very_easy', 'Very Easy', '😊', Colors.green),
    DifficultyRating('easy', 'Easy', '🙂', Colors.lightGreen),
    DifficultyRating('moderate', 'Moderate', '😐', Colors.orange),
    DifficultyRating('hard', 'Hard', '😤', Colors.deepOrange),
    DifficultyRating('very_hard', 'Very Hard', '🥵', Colors.red),
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAnimations();
    _loadPreviousSetData();
    _loadPerformanceData();
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
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
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

  void _loadPerformanceData() async {
    final setLoggingService = ref.read(setLoggingServiceProvider);
    
    try {
      // Load performance comparison data
      final comparison = await setLoggingService.getPerformanceComparison(
        widget.workoutExercise.id,
      );
      
      // Load weight progression suggestion
      final currentWeight = int.tryParse(_weightController.text) ?? 0;
      final recentDifficulties = widget.completedSets
          .where((set) => set.difficultyRating != null)
          .map((set) => set.difficultyRating!)
          .toList();
      
      final suggestion = await setLoggingService.getWeightProgressionSuggestion(
        exerciseId: widget.exercise.id,
        userId: 'current_user', // This should come from auth
        currentWeight: currentWeight,
        recentDifficultyRatings: recentDifficulties,
      );

      if (mounted) {
        setState(() {
          _performanceComparison = comparison;
          _progressionSuggestion = suggestion;
        });
        
        // Animate progress indicators
        _progressController.forward();
      }
    } catch (e) {
      // Handle error silently - performance data is optional
    }
  }

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    _shakeController.dispose();
    _progressController.dispose();
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
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Set header with progress
                  _buildSetHeader(),
                  
                  const SizedBox(height: 16),
                  
                  // Performance comparison indicators
                  if (_performanceComparison != null) ...[
                    _buildPerformanceComparison(),
                    const SizedBox(height: 16),
                  ],
                  
                  // Input fields with progression suggestions
                  _buildInputFields(),
                  
                  const SizedBox(height: 16),
                  
                  // Enhanced difficulty rating with visual feedback
                  _buildDifficultyRating(),
                  
                  const SizedBox(height: 16),
                  
                  // Notes input
                  _buildNotesInput(),
                  
                  const SizedBox(height: 20),
                  
                  // Action buttons with progression suggestions
                  _buildActionButtons(),
                  
                  // Previous sets with performance indicators
                  if (widget.completedSets.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildPreviousSetsDisplay(),
                  ],
                  
                  // Weight progression suggestion
                  if (_progressionSuggestion != null) ...[
                    const SizedBox(height: 16),
                    _buildProgressionSuggestion(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSetHeader() {
    final progress = widget.currentSet / widget.workoutExercise.effectiveSets;
    
    return Row(
      children: [
        // Animated set indicator
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    value: progress * _progressAnimation.value,
                    strokeWidth: 4,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    '${widget.currentSet}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        
        const SizedBox(width: 16),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set ${widget.currentSet} of ${widget.workoutExercise.effectiveSets}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.exercise.name,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              // Progress indicator
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceComparison() {
    final comparison = _performanceComparison!;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Performance vs Last Session',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Performance indicators
          Row(
            children: [
              Expanded(
                child: _buildComparisonIndicator(
                  'Improvement',
                  '${comparison.improvementPercentage.toStringAsFixed(1)}%',
                  comparison.improvementPercentage >= 0 ? Colors.green : Colors.red,
                  comparison.improvementPercentage >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildComparisonIndicator(
                  'Previous Best',
                  comparison.previousReps.isNotEmpty 
                      ? '${comparison.previousReps.reduce((a, b) => a > b ? a : b)} reps'
                      : 'N/A',
                  Theme.of(context).colorScheme.primary,
                  Icons.history,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonIndicator(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
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

  Widget _buildInputFields() {
    return Row(
      children: [
        // Reps input with target indicator
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Reps',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.workoutExercise.reps?.isNotEmpty == true) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Target: ${widget.workoutExercise.reps![widget.currentSet - 1]}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _repsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '0',
                  prefixIcon: const Icon(Icons.repeat),
                  suffixIcon: _buildQuickAdjustButtons(
                    onDecrease: () => _adjustReps(-1),
                    onIncrease: () => _adjustReps(1),
                  ),
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
        
        // Weight input with progression suggestion
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Weight (kg)',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_progressionSuggestion != null && 
                      _progressionSuggestion!.progressionType != ProgressionType.maintain) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getProgressionColor(_progressionSuggestion!.progressionType),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${_progressionSuggestion!.suggestedWeight}kg',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: '0.0',
                  prefixIcon: const Icon(Icons.fitness_center),
                  suffixIcon: _buildQuickAdjustButtons(
                    onDecrease: () => _adjustWeight(-2.5),
                    onIncrease: () => _adjustWeight(2.5),
                  ),
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
    );
  }

  Widget _buildQuickAdjustButtons({
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onDecrease,
          icon: const Icon(Icons.remove, size: 16),
          style: IconButton.styleFrom(
            minimumSize: const Size(24, 24),
            padding: EdgeInsets.zero,
          ),
        ),
        IconButton(
          onPressed: onIncrease,
          icon: const Icon(Icons.add, size: 16),
          style: IconButton.styleFrom(
            minimumSize: const Size(24, 24),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyRating() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How did this set feel?',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        // Enhanced difficulty rating with visual feedback
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _difficultyOptions.map((difficulty) {
            final isSelected = _selectedDifficulty == difficulty.value;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedDifficulty = isSelected ? null : difficulty.value;
                  });
                  if (!isSelected) {
                    HapticFeedback.selectionClick();
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? difficulty.color.withValues(alpha: 0.2)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? difficulty.color
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        difficulty.emoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        difficulty.label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? difficulty.color : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNotesInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            hintText: 'How did this set feel? Any observations...',
            prefixIcon: Icon(Icons.note),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Quick adjustment buttons
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
        
        // Complete set button with enhanced feedback
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: ElevatedButton.icon(
            onPressed: _isLogging ? null : _completeSet,
            icon: _isLogging
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle),
            label: Text(_isLogging ? 'Logging...' : 'Complete Set'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
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
          minimumSize: const Size(36, 36),
          padding: const EdgeInsets.all(6),
        ),
      ),
    );
  }

  Widget _buildPreviousSetsDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Previous Sets',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.completedSets.length,
            itemBuilder: (context, index) {
              final set = widget.completedSets[index];
              final isPersonalRecord = _isPersonalRecord(set);
              
              return Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isPersonalRecord
                      ? AppTheme.successColor.withValues(alpha: 0.1)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: isPersonalRecord
                      ? Border.all(color: AppTheme.successColor, width: 2)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Set ${set.setNumber}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isPersonalRecord) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.star,
                            size: 12,
                            color: AppTheme.successColor,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${set.reps} × ${set.weight}kg',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (set.difficultyRating != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _getDifficultyEmoji(set.difficultyRating!),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProgressionSuggestion() {
    final suggestion = _progressionSuggestion!;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getProgressionColor(suggestion.progressionType).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getProgressionColor(suggestion.progressionType),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getProgressionIcon(suggestion.progressionType),
                size: 16,
                color: _getProgressionColor(suggestion.progressionType),
              ),
              const SizedBox(width: 8),
              Text(
                'Progression Suggestion',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _getProgressionColor(suggestion.progressionType),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            suggestion.reasoning,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (suggestion.progressionType != ProgressionType.maintain) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Suggested: ${suggestion.suggestedWeight}kg',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${(suggestion.confidence * 100).round()}% confidence)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ],
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
      // Complete the set with enhanced logging
      widget.onSetCompleted(
        reps,
        weight,
        _selectedDifficulty,
        _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      // Success feedback with enhanced haptics
      HapticFeedback.heavyImpact();
      
      // Clear notes and difficulty for next set
      _notesController.clear();
      _selectedDifficulty = null;

      // Show enhanced success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Set ${widget.currentSet} completed! $reps × ${weight}kg'),
            ],
          ),
          backgroundColor: AppTheme.successColor,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Reload performance data for next set
      _loadPerformanceData();

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

  bool _isPersonalRecord(CompletedSetLog set) {
    // Simple PR detection - in a real app this would compare with historical data
    final volume = set.reps * set.weight;
    final maxVolume = widget.completedSets
        .where((s) => s.setNumber < set.setNumber)
        .fold<double>(0, (max, s) => math.max(max, s.reps * s.weight));
    
    return volume > maxVolume;
  }

  String _getDifficultyEmoji(String difficulty) {
    return _difficultyOptions
        .firstWhere((d) => d.value == difficulty, orElse: () => _difficultyOptions[2])
        .emoji;
  }

  Color _getProgressionColor(ProgressionType type) {
    switch (type) {
      case ProgressionType.increase:
        return Colors.green;
      case ProgressionType.decrease:
        return Colors.orange;
      case ProgressionType.maintain:
        return Colors.blue;
    }
  }

  IconData _getProgressionIcon(ProgressionType type) {
    switch (type) {
      case ProgressionType.increase:
        return Icons.trending_up;
      case ProgressionType.decrease:
        return Icons.trending_down;
      case ProgressionType.maintain:
        return Icons.trending_flat;
    }
  }
}

// Helper class for difficulty ratings
class DifficultyRating {
  final String value;
  final String label;
  final String emoji;
  final Color color;

  const DifficultyRating(this.value, this.label, this.emoji, this.color);
}