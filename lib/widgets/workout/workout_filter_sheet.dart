import 'package:flutter/material.dart';
import '../../providers/workout_provider.dart';

class WorkoutFilterSheet extends StatefulWidget {
  final WorkoutFilters currentFilters;
  final Function(WorkoutFilters) onFiltersChanged;

  const WorkoutFilterSheet({
    super.key,
    required this.currentFilters,
    required this.onFiltersChanged,
  });

  @override
  State<WorkoutFilterSheet> createState() => _WorkoutFilterSheetState();
}

class _WorkoutFilterSheetState extends State<WorkoutFilterSheet> {
  late WorkoutFilters _filters;
  
  // Filter options
  final List<String> _statusOptions = ['All', 'Active', 'Completed', 'Templates'];
  final List<String> _sortOptions = ['Recent', 'Name', 'Duration', 'Rating'];
  final List<int> _limitOptions = [10, 20, 50, 100];

  String _selectedStatus = 'All';
  String _selectedSort = 'Recent';
  int _selectedLimit = 20;

  @override
  void initState() {
    super.initState();
    _filters = widget.currentFilters;
    _initializeFromFilters();
  }

  void _initializeFromFilters() {
    // Set status based on current filters
    if (_filters.isActive == true) {
      _selectedStatus = 'Active';
    } else if (_filters.isCompleted == true) {
      _selectedStatus = 'Completed';
    } else if (_filters.isActive == false && _filters.isCompleted == false) {
      _selectedStatus = 'Templates';
    } else {
      _selectedStatus = 'All';
    }

    // Set limit
    _selectedLimit = _filters.limit ?? 20;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Filter Workouts',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),
          
          // Filter content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status filter
                  _buildFilterSection(
                    title: 'Status',
                    child: _buildStatusFilter(theme),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Sort filter
                  _buildFilterSection(
                    title: 'Sort By',
                    child: _buildSortFilter(theme),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Limit filter
                  _buildFilterSection(
                    title: 'Results Limit',
                    child: _buildLimitFilter(theme),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildStatusFilter(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _statusOptions.map((status) {
        final isSelected = _selectedStatus == status;
        return FilterChip(
          label: Text(status),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedStatus = status;
              });
            }
          },
          backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          selectedColor: theme.colorScheme.primaryContainer,
          checkmarkColor: theme.colorScheme.onPrimaryContainer,
          labelStyle: TextStyle(
            color: isSelected 
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSortFilter(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _sortOptions.map((sort) {
        final isSelected = _selectedSort == sort;
        return FilterChip(
          label: Text(sort),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedSort = sort;
              });
            }
          },
          backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          selectedColor: theme.colorScheme.secondaryContainer,
          checkmarkColor: theme.colorScheme.onSecondaryContainer,
          labelStyle: TextStyle(
            color: isSelected 
                ? theme.colorScheme.onSecondaryContainer
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLimitFilter(ThemeData theme) {
    return DropdownButtonFormField<int>(
      value: _selectedLimit,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: _limitOptions.map((limit) {
        return DropdownMenuItem(
          value: limit,
          child: Text('$limit workouts'),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedLimit = value;
          });
        }
      },
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedStatus = 'All';
      _selectedSort = 'Recent';
      _selectedLimit = 20;
    });
  }

  void _applyFilters() {
    // Convert UI selections to WorkoutFilters
    bool? isActive;
    bool? isCompleted;
    
    switch (_selectedStatus) {
      case 'Active':
        isActive = true;
        break;
      case 'Completed':
        isCompleted = true;
        break;
      case 'Templates':
        isActive = false;
        isCompleted = false;
        break;
      case 'All':
      default:
        // Leave both null for all workouts
        break;
    }

    final newFilters = WorkoutFilters(
      userId: _filters.userId,
      isActive: isActive,
      isCompleted: isCompleted,
      limit: _selectedLimit,
      offset: 0, // Reset offset when applying new filters
    );

    widget.onFiltersChanged(newFilters);
    Navigator.of(context).pop();
  }
}