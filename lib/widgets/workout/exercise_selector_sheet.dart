import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/exercise_provider.dart';

class ExerciseSelectorSheet extends ConsumerStatefulWidget {
  final Function(List<Exercise>) onExercisesSelected;

  const ExerciseSelectorSheet({
    super.key,
    required this.onExercisesSelected,
  });

  @override
  ConsumerState<ExerciseSelectorSheet> createState() => _ExerciseSelectorSheetState();
}

class _ExerciseSelectorSheetState extends ConsumerState<ExerciseSelectorSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  final List<Exercise> _selectedExercises = [];
  String _searchQuery = '';
  String? _selectedMuscleGroup;
  String? _selectedEquipment;
  
  // Available filter options
  final List<String> _muscleGroups = [
    'Chest', 'Back', 'Shoulders', 'Arms', 'Legs', 'Core', 'Cardio'
  ];
  
  final List<String> _equipmentTypes = [
    'Bodyweight', 'Dumbbells', 'Barbell', 'Resistance Bands', 'Cable Machine', 'Kettlebell'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
              color: theme.colorScheme.onSurfaceVariant.withOpacity( 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Add Exercises',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_selectedExercises.isNotEmpty)
                  Chip(
                    label: Text('${_selectedExercises.length} selected'),
                    backgroundColor: theme.colorScheme.primary,
                    labelStyle: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity( 0.3),
              ),
            ),
          ),
          
          // Tab bar
          TabBar(
            controller: _tabController,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            indicatorColor: theme.colorScheme.primary,
            tabs: const [
              Tab(text: 'All Exercises'),
              Tab(text: 'By Muscle'),
              Tab(text: 'By Equipment'),
            ],
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllExercisesTab(),
                _buildMuscleGroupTab(),
                _buildEquipmentTab(),
              ],
            ),
          ),
          
          // Bottom action bar
          if (_selectedExercises.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withOpacity( 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedExercises.clear();
                      });
                    },
                    child: const Text('Clear All'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      widget.onExercisesSelected(_selectedExercises);
                      Navigator.of(context).pop();
                    },
                    child: Text('Add ${_selectedExercises.length} Exercise${_selectedExercises.length == 1 ? '' : 's'}'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAllExercisesTab() {
    final exercisesAsync = ref.watch(exercisesProvider);
    
    return exercisesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _buildErrorWidget(error.toString()),
      data: (exercises) {
        final filteredExercises = _filterExercises(exercises);
        
        if (filteredExercises.isEmpty) {
          return _buildEmptyState('No exercises found');
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredExercises.length,
          itemBuilder: (context, index) {
            final exercise = filteredExercises[index];
            final isSelected = _selectedExercises.contains(exercise);
            
            return _buildExerciseCard(exercise, isSelected);
          },
        );
      },
    );
  }

  Widget _buildMuscleGroupTab() {
    return Column(
      children: [
        // Muscle group filter chips
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _muscleGroups.length,
            itemBuilder: (context, index) {
              final muscleGroup = _muscleGroups[index];
              final isSelected = _selectedMuscleGroup == muscleGroup;
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(muscleGroup),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedMuscleGroup = selected ? muscleGroup : null;
                    });
                  },
                ),
              );
            },
          ),
        ),
        
        // Exercise list
        Expanded(
          child: _buildFilteredExerciseList(
            filter: (exercise) => _selectedMuscleGroup == null ||
                exercise.primaryMuscle?.toLowerCase().contains(_selectedMuscleGroup!.toLowerCase()) == true,
          ),
        ),
      ],
    );
  }

  Widget _buildEquipmentTab() {
    return Column(
      children: [
        // Equipment filter chips
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _equipmentTypes.length,
            itemBuilder: (context, index) {
              final equipment = _equipmentTypes[index];
              final isSelected = _selectedEquipment == equipment;
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(equipment),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedEquipment = selected ? equipment : null;
                    });
                  },
                ),
              );
            },
          ),
        ),
        
        // Exercise list
        Expanded(
          child: _buildFilteredExerciseList(
            filter: (exercise) => _selectedEquipment == null ||
                exercise.equipment?.toLowerCase().contains(_selectedEquipment!.toLowerCase()) == true,
          ),
        ),
      ],
    );
  }

  Widget _buildFilteredExerciseList({required bool Function(Exercise) filter}) {
    final exercisesAsync = ref.watch(exercisesProvider);
    
    return exercisesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _buildErrorWidget(error.toString()),
      data: (exercises) {
        final filteredExercises = _filterExercises(exercises, additionalFilter: filter);
        
        if (filteredExercises.isEmpty) {
          return _buildEmptyState('No exercises found for the selected filter');
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredExercises.length,
          itemBuilder: (context, index) {
            final exercise = filteredExercises[index];
            final isSelected = _selectedExercises.contains(exercise);
            
            return _buildExerciseCard(exercise, isSelected);
          },
        );
      },
    );
  }

  Widget _buildExerciseCard(Exercise exercise, bool isSelected) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _toggleExerciseSelection(exercise),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Selection indicator
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: 16,
                        color: theme.colorScheme.onPrimary,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              
              // Exercise info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (exercise.primaryMuscle != null) ...[
                          Icon(
                            Icons.fitness_center,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            exercise.primaryMuscle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (exercise.equipment != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.build,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            exercise.equipment!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Video indicator
              if (exercise.hasVideo)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity( 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.play_circle_outline,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load exercises',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Exercise> _filterExercises(
    List<Exercise> exercises, {
    bool Function(Exercise)? additionalFilter,
  }) {
    return exercises.where((exercise) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final matchesSearch = exercise.name.toLowerCase().contains(_searchQuery) ||
            (exercise.description?.toLowerCase().contains(_searchQuery) ?? false) ||
            (exercise.primaryMuscle?.toLowerCase().contains(_searchQuery) ?? false) ||
            (exercise.equipment?.toLowerCase().contains(_searchQuery) ?? false);
        
        if (!matchesSearch) return false;
      }
      
      // Additional filter
      if (additionalFilter != null && !additionalFilter(exercise)) {
        return false;
      }
      
      return true;
    }).toList();
  }

  void _toggleExerciseSelection(Exercise exercise) {
    setState(() {
      if (_selectedExercises.contains(exercise)) {
        _selectedExercises.remove(exercise);
      } else {
        _selectedExercises.add(exercise);
      }
    });
  }
}