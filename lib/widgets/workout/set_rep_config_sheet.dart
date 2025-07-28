import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../screens/workout_builder_screen.dart';

class SetRepConfigSheet extends StatefulWidget {
  final WorkoutBuilderExercise exercise;
  final Function(WorkoutBuilderExercise) onSave;

  const SetRepConfigSheet({
    super.key,
    required this.exercise,
    required this.onSave,
  });

  @override
  State<SetRepConfigSheet> createState() => _SetRepConfigSheetState();
}

class _SetRepConfigSheetState extends State<SetRepConfigSheet> {
  late int _sets;
  late List<int> _reps;
  late List<double> _weight;
  late int _restInterval;
  late String _notes;
  
  final List<TextEditingController> _repsControllers = [];
  final List<TextEditingController> _weightControllers = [];
  final TextEditingController _restController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  bool _useUniformReps = true;
  bool _useUniformWeight = true;
  bool _hasWeight = false;
  
  // Weight suggestions based on user history (mock data for now)
  List<double> _weightSuggestions = [];

  @override
  void initState() {
    super.initState();
    _initializeValues();
    _loadWeightSuggestions();
  }

  void _initializeValues() {
    _sets = widget.exercise.sets;
    _reps = List.from(widget.exercise.reps);
    _weight = widget.exercise.weight != null 
        ? List.from(widget.exercise.weight!) 
        : List.filled(_sets, 0.0);
    _restInterval = widget.exercise.restInterval;
    _notes = widget.exercise.notes;
    
    _hasWeight = widget.exercise.weight != null;
    _useUniformReps = _reps.every((rep) => rep == _reps.first);
    _useUniformWeight = _weight.every((w) => w == _weight.first);
    
    _restController.text = _restInterval.toString();
    _notesController.text = _notes;
    
    _updateControllers();
  }

  void _updateControllers() {
    // Clear existing controllers
    for (final controller in _repsControllers) {
      controller.dispose();
    }
    for (final controller in _weightControllers) {
      controller.dispose();
    }
    _repsControllers.clear();
    _weightControllers.clear();
    
    // Create new controllers
    for (int i = 0; i < _sets; i++) {
      final repsController = TextEditingController(
        text: i < _reps.length ? _reps[i].toString() : '10',
      );
      final weightController = TextEditingController(
        text: i < _weight.length ? _weight[i].toStringAsFixed(1) : '0.0',
      );
      
      _repsControllers.add(repsController);
      _weightControllers.add(weightController);
    }
    
    // Ensure lists are the right size
    while (_reps.length < _sets) {
      _reps.add(10);
    }
    while (_weight.length < _sets) {
      _weight.add(0.0);
    }
    
    if (_reps.length > _sets) {
      _reps = _reps.take(_sets).toList();
    }
    if (_weight.length > _sets) {
      _weight = _weight.take(_sets).toList();
    }
  }

  Future<void> _loadWeightSuggestions() async {
    try {
      // TODO: Load actual weight suggestions from user history
      // For now, provide some mock suggestions
      _weightSuggestions = [5.0, 10.0, 15.0, 20.0, 25.0];
    } catch (e) {
      _weightSuggestions = [];
    }
  }

  @override
  void dispose() {
    for (final controller in _repsControllers) {
      controller.dispose();
    }
    for (final controller in _weightControllers) {
      controller.dispose();
    }
    _restController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    
    return Container(
      height: mediaQuery.size.height * 0.9,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configure Exercise',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.exercise.exercise.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sets configuration
                  _buildSetsSection(),
                  const SizedBox(height: 24),
                  
                  // Reps configuration
                  _buildRepsSection(),
                  const SizedBox(height: 24),
                  
                  // Weight configuration
                  _buildWeightSection(),
                  const SizedBox(height: 24),
                  
                  // Rest interval
                  _buildRestSection(),
                  const SizedBox(height: 24),
                  
                  // Notes
                  _buildNotesSection(),
                ],
              ),
            ),
          ),
          
          // Bottom action bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _saveConfiguration,
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetsSection() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Number of Sets',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            IconButton(
              onPressed: _sets > 1 ? () => _updateSets(_sets - 1) : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Container(
              width: 60,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _sets.toString(),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: _sets < 10 ? () => _updateSets(_sets + 1) : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
            const Spacer(),
            Text(
              'Max: 10 sets',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRepsSection() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Repetitions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Switch(
              value: _useUniformReps,
              onChanged: (value) {
                setState(() {
                  _useUniformReps = value;
                  if (value) {
                    // Set all reps to the first value
                    final firstRep = _reps.isNotEmpty ? _reps.first : 10;
                    _reps = List.filled(_sets, firstRep);
                    _updateControllers();
                  }
                });
              },
            ),
            Text(
              'Same for all',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (_useUniformReps) ...[
          // Single rep input for all sets
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _reps.isNotEmpty ? _reps.first.toString() : '10',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Reps per set',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    final reps = int.tryParse(value) ?? 10;
                    setState(() {
                      _reps = List.filled(_sets, reps);
                    });
                  },
                ),
              ),
            ],
          ),
        ] else ...[
          // Individual rep inputs for each set
          ...List.generate(_sets, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      'Set ${index + 1}:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _repsControllers[index],
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Reps',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onChanged: (value) {
                        final reps = int.tryParse(value) ?? 10;
                        if (index < _reps.length) {
                          _reps[index] = reps;
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildWeightSection() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Weight (kg)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Switch(
              value: _hasWeight,
              onChanged: (value) {
                setState(() {
                  _hasWeight = value;
                  if (!value) {
                    _weight = List.filled(_sets, 0.0);
                  }
                });
              },
            ),
            Text(
              'Use weight',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        
        if (_hasWeight) ...[
          const SizedBox(height: 12),
          
          // Weight suggestions
          if (_weightSuggestions.isNotEmpty) ...[
            Text(
              'Suggestions based on your history:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _weightSuggestions.map((weight) {
                return ActionChip(
                  label: Text('${weight.toStringAsFixed(1)}kg'),
                  onPressed: () => _applyWeightToAll(weight),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          
          Row(
            children: [
              Switch(
                value: _useUniformWeight,
                onChanged: (value) {
                  setState(() {
                    _useUniformWeight = value;
                    if (value) {
                      // Set all weights to the first value
                      final firstWeight = _weight.isNotEmpty ? _weight.first : 0.0;
                      _weight = List.filled(_sets, firstWeight);
                      _updateControllers();
                    }
                  });
                },
              ),
              Text(
                'Same weight for all sets',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (_useUniformWeight) ...[
            // Single weight input for all sets
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _weight.isNotEmpty ? _weight.first.toStringAsFixed(1) : '0.0',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Weight per set (kg)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      final weight = double.tryParse(value) ?? 0.0;
                      setState(() {
                        _weight = List.filled(_sets, weight);
                      });
                    },
                  ),
                ),
              ],
            ),
          ] else ...[
            // Individual weight inputs for each set
            ...List.generate(_sets, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(
                        'Set ${index + 1}:',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _weightControllers[index],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Weight (kg)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (value) {
                          final weight = double.tryParse(value) ?? 0.0;
                          if (index < _weight.length) {
                            _weight[index] = weight;
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ] else ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This exercise will be performed with bodyweight only',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRestSection() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rest Between Sets',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _restController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Rest time (seconds)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixText: 'sec',
                ),
                onChanged: (value) {
                  _restInterval = int.tryParse(value) ?? 60;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [30, 45, 60, 90, 120, 180].map((seconds) {
            return ActionChip(
              label: Text('${seconds}s'),
              onPressed: () {
                setState(() {
                  _restInterval = seconds;
                  _restController.text = seconds.toString();
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes (Optional)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Add any notes about form, technique, or modifications...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: (value) {
            _notes = value;
          },
        ),
      ],
    );
  }

  void _updateSets(int newSets) {
    setState(() {
      _sets = newSets;
      _updateControllers();
    });
  }

  void _applyWeightToAll(double weight) {
    setState(() {
      _weight = List.filled(_sets, weight);
      _useUniformWeight = true;
      _updateControllers();
    });
  }

  void _saveConfiguration() {
    // Validate inputs
    final updatedExercise = widget.exercise.copyWith(
      sets: _sets,
      reps: _reps,
      weight: _hasWeight ? _weight : null,
      restInterval: _restInterval,
      notes: _notes,
    );
    
    widget.onSave(updatedExercise);
    Navigator.of(context).pop();
  }
}