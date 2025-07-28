import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/exercise_provider.dart';

class ExerciseFilterChips extends ConsumerStatefulWidget {
  final List<String> selectedMuscleGroups;
  final List<String> selectedEquipmentTypes;
  final List<String> selectedCategories;
  final Function(List<String>) onMuscleGroupsChanged;
  final Function(List<String>) onEquipmentTypesChanged;
  final Function(List<String>) onCategoriesChanged;
  final Function()? onClearFilters;

  const ExerciseFilterChips({
    super.key,
    required this.selectedMuscleGroups,
    required this.selectedEquipmentTypes,
    required this.selectedCategories,
    required this.onMuscleGroupsChanged,
    required this.onEquipmentTypesChanged,
    required this.onCategoriesChanged,
    this.onClearFilters,
  });

  @override
  ConsumerState<ExerciseFilterChips> createState() => _ExerciseFilterChipsState();
}

class _ExerciseFilterChipsState extends ConsumerState<ExerciseFilterChips>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      widget.selectedMuscleGroups.isNotEmpty ||
      widget.selectedEquipmentTypes.isNotEmpty ||
      widget.selectedCategories.isNotEmpty;

  int get _activeFilterCount =>
      widget.selectedMuscleGroups.length +
      widget.selectedEquipmentTypes.length +
      widget.selectedCategories.length;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterHeader(),
          if (_isExpanded) _buildFilterTabs(),
          if (_hasActiveFilters && !_isExpanded) _buildActiveFiltersPreview(),
        ],
      ),
    );
  }

  Widget _buildFilterHeader() {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.filter_list,
              color: _hasActiveFilters
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _hasActiveFilters
                    ? 'Filters ($_activeFilterCount active)'
                    : 'Filter exercises',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _hasActiveFilters
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  fontWeight: _hasActiveFilters ? FontWeight.w600 : null,
                ),
              ),
            ),
            if (_hasActiveFilters && !_isExpanded)
              TextButton(
                onPressed: widget.onClearFilters,
                child: const Text('Clear'),
              ),
            Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFiltersPreview() {
    final allActiveFilters = [
      ...widget.selectedMuscleGroups,
      ...widget.selectedEquipmentTypes,
      ...widget.selectedCategories,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: allActiveFilters.take(3).map((filter) {
          return Chip(
            label: Text(
              filter,
              style: const TextStyle(fontSize: 12),
            ),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            labelStyle: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () => _removeFilter(filter),
          );
        }).toList()
          ..addAll(allActiveFilters.length > 3
              ? [
                  Chip(
                    label: Text(
                      '+${allActiveFilters.length - 3} more',
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  )
                ]
              : []),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Muscles'),
            Tab(text: 'Equipment'),
            Tab(text: 'Categories'),
          ],
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: Theme.of(context).colorScheme.primary,
        ),
        SizedBox(
          height: 200,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMuscleGroupFilters(),
              _buildEquipmentFilters(),
              _buildCategoryFilters(),
            ],
          ),
        ),
        if (_hasActiveFilters)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_activeFilterCount filters active',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                TextButton(
                  onPressed: widget.onClearFilters,
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMuscleGroupFilters() {
    final muscleGroupsAsync = ref.watch(muscleGroupsProvider);
    
    return muscleGroupsAsync.when(
      data: (muscleGroups) => _buildFilterChipsList(
        items: muscleGroups,
        selectedItems: widget.selectedMuscleGroups,
        onSelectionChanged: widget.onMuscleGroupsChanged,
        emptyMessage: 'No muscle groups available',
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading muscle groups: $error'),
      ),
    );
  }

  Widget _buildEquipmentFilters() {
    final equipmentTypesAsync = ref.watch(equipmentTypesProvider);
    
    return equipmentTypesAsync.when(
      data: (equipmentTypes) => _buildFilterChipsList(
        items: equipmentTypes,
        selectedItems: widget.selectedEquipmentTypes,
        onSelectionChanged: widget.onEquipmentTypesChanged,
        emptyMessage: 'No equipment types available',
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading equipment types: $error'),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final categoriesAsync = ref.watch(exerciseCategoriesProvider);
    
    return categoriesAsync.when(
      data: (categories) => _buildFilterChipsList(
        items: categories,
        selectedItems: widget.selectedCategories,
        onSelectionChanged: widget.onCategoriesChanged,
        emptyMessage: 'No categories available',
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading categories: $error'),
      ),
    );
  }

  Widget _buildFilterChipsList({
    required List<String> items,
    required List<String> selectedItems,
    required Function(List<String>) onSelectionChanged,
    required String emptyMessage,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((item) {
          final isSelected = selectedItems.contains(item);
          
          return FilterChip(
            label: Text(
              item,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            onSelected: (selected) {
              final newSelection = List<String>.from(selectedItems);
              if (selected) {
                newSelection.add(item);
              } else {
                newSelection.remove(item);
              }
              onSelectionChanged(newSelection);
            },
            backgroundColor: Theme.of(context).colorScheme.surface,
            selectedColor: Theme.of(context).colorScheme.primary,
            checkmarkColor: Theme.of(context).colorScheme.onPrimary,
            side: BorderSide(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withOpacity(0.5),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _removeFilter(String filter) {
    if (widget.selectedMuscleGroups.contains(filter)) {
      final newSelection = List<String>.from(widget.selectedMuscleGroups);
      newSelection.remove(filter);
      widget.onMuscleGroupsChanged(newSelection);
    } else if (widget.selectedEquipmentTypes.contains(filter)) {
      final newSelection = List<String>.from(widget.selectedEquipmentTypes);
      newSelection.remove(filter);
      widget.onEquipmentTypesChanged(newSelection);
    } else if (widget.selectedCategories.contains(filter)) {
      final newSelection = List<String>.from(widget.selectedCategories);
      newSelection.remove(filter);
      widget.onCategoriesChanged(newSelection);
    }
  }
}

class QuickFilterChips extends ConsumerWidget {
  final List<String> selectedFilters;
  final Function(String) onFilterToggled;
  final Function()? onClearFilters;

  const QuickFilterChips({
    super.key,
    required this.selectedFilters,
    required this.onFilterToggled,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quickFilters = [
      'chest',
      'back',
      'legs',
      'shoulders',
      'arms',
      'core',
      'bodyweight',
      'dumbbells',
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: quickFilters.length,
              itemBuilder: (context, index) {
                final filter = quickFilters[index];
                final isSelected = selectedFilters.contains(filter);
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      filter.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) => onFilterToggled(filter),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    selectedColor: Theme.of(context).colorScheme.primary,
                    side: BorderSide(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline.withOpacity(0.5),
                    ),
                  ),
                );
              },
            ),
          ),
          if (selectedFilters.isNotEmpty)
            IconButton(
              onPressed: onClearFilters,
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear filters',
            ),
        ],
      ),
    );
  }
}