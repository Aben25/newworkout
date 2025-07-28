import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Filter widget for workout history with advanced filtering options
class WorkoutHistoryFilters extends ConsumerStatefulWidget {
  final DateTimeRange? currentDateFilter;
  final String? currentStatusFilter;
  final int? currentRatingFilter;
  final String? currentExerciseFilter;
  final Function({
    DateTimeRange? dateRange,
    String? status,
    int? rating,
    String? exercise,
  }) onFiltersApplied;
  final VoidCallback onFiltersCleared;

  const WorkoutHistoryFilters({
    super.key,
    this.currentDateFilter,
    this.currentStatusFilter,
    this.currentRatingFilter,
    this.currentExerciseFilter,
    required this.onFiltersApplied,
    required this.onFiltersCleared,
  });

  @override
  ConsumerState<WorkoutHistoryFilters> createState() => _WorkoutHistoryFiltersState();
}

class _WorkoutHistoryFiltersState extends ConsumerState<WorkoutHistoryFilters> {
  DateTimeRange? _selectedDateRange;
  String? _selectedStatus;
  int? _selectedRating;
  String? _selectedExercise;
  
  final List<String> _statusOptions = [
    'completed',
    'in_progress',
    'cancelled',
    'paused',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDateRange = widget.currentDateFilter;
    _selectedStatus = widget.currentStatusFilter;
    _selectedRating = widget.currentRatingFilter;
    _selectedExercise = widget.currentExerciseFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Workouts',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Date range filter
          _buildDateRangeFilter(),
          const SizedBox(height: 24),

          // Status filter
          _buildStatusFilter(),
          const SizedBox(height: 24),

          // Rating filter
          _buildRatingFilter(),
          const SizedBox(height: 24),

          // Exercise filter
          _buildExerciseFilter(),
          const SizedBox(height: 32),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearAllFilters,
                  child: const Text('Clear All'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: _applyFilters,
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDateRange,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.date_range,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedDateRange != null
                        ? '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}'
                        : 'Select date range',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: _selectedDateRange != null
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (_selectedDateRange != null)
                  IconButton(
                    onPressed: () => setState(() => _selectedDateRange = null),
                    icon: const Icon(Icons.clear),
                    iconSize: 20,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Quick date range options
        Wrap(
          spacing: 8,
          children: [
            _buildQuickDateChip('Last 7 days', 7),
            _buildQuickDateChip('Last 30 days', 30),
            _buildQuickDateChip('Last 90 days', 90),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickDateChip(String label, int days) {
    return FilterChip(
      label: Text(label),
      selected: _selectedDateRange != null &&
          _selectedDateRange!.start.isAtSameMomentAs(
            DateTime.now().subtract(Duration(days: days)),
          ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedDateRange = DateTimeRange(
              start: DateTime.now().subtract(Duration(days: days)),
              end: DateTime.now(),
            );
          });
        }
      },
    );
  }

  Widget _buildStatusFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Workout Status',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _statusOptions.map((status) {
            return FilterChip(
              label: Text(_formatStatusLabel(status)),
              selected: _selectedStatus == status,
              onSelected: (selected) {
                setState(() {
                  _selectedStatus = selected ? status : null;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRatingFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Minimum Rating',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(5, (index) {
            final rating = index + 1;
            return FilterChip(
              label: Text('$rating⭐+'),
              selected: _selectedRating == rating,
              onSelected: (selected) {
                setState(() {
                  _selectedRating = selected ? rating : null;
                });
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildExerciseFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exercise',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectExercise,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.fitness_center,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedExercise ?? 'Select exercise',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: _selectedExercise != null
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (_selectedExercise != null)
                  IconButton(
                    onPressed: () => setState(() => _selectedExercise = null),
                    icon: const Icon(Icons.clear),
                    iconSize: 20,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  Future<void> _selectExercise() async {
    // This would show a dialog to select from available exercises
    // For now, we'll use a simple text input
    final TextEditingController controller = TextEditingController(
      text: _selectedExercise ?? '',
    );

    final String? result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Exercise'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter exercise name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Select'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _selectedExercise = result;
      });
    }
  }

  void _clearAllFilters() {
    setState(() {
      _selectedDateRange = null;
      _selectedStatus = null;
      _selectedRating = null;
      _selectedExercise = null;
    });
  }

  void _applyFilters() {
    widget.onFiltersApplied(
      dateRange: _selectedDateRange,
      status: _selectedStatus,
      rating: _selectedRating,
      exercise: _selectedExercise,
    );
    Navigator.of(context).pop();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatStatusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'in_progress':
        return 'In Progress';
      case 'cancelled':
        return 'Cancelled';
      case 'paused':
        return 'Paused';
      default:
        return status;
    }
  }
}