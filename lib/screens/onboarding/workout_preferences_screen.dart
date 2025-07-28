import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/onboarding_provider.dart';
import '../../models/onboarding_state.dart';

class WorkoutPreferencesScreen extends ConsumerStatefulWidget {
  const WorkoutPreferencesScreen({super.key});

  @override
  ConsumerState<WorkoutPreferencesScreen> createState() => _WorkoutPreferencesScreenState();
}

class _WorkoutPreferencesScreenState extends ConsumerState<WorkoutPreferencesScreen>
    with TickerProviderStateMixin {
  List<String> _selectedDays = [];
  String? _selectedDuration;
  String? _selectedFrequency;
  String? _selectedFlexibility;
  TimeOfDay? _preferredStartTime;
  TimeOfDay? _preferredEndTime;
  late AnimationController _animationController;

  final List<Map<String, dynamic>> _weekDays = [
    {'id': 'monday', 'title': 'Mon', 'fullTitle': 'Monday', 'icon': Icons.calendar_today},
    {'id': 'tuesday', 'title': 'Tue', 'fullTitle': 'Tuesday', 'icon': Icons.calendar_today},
    {'id': 'wednesday', 'title': 'Wed', 'fullTitle': 'Wednesday', 'icon': Icons.calendar_today},
    {'id': 'thursday', 'title': 'Thu', 'fullTitle': 'Thursday', 'icon': Icons.calendar_today},
    {'id': 'friday', 'title': 'Fri', 'fullTitle': 'Friday', 'icon': Icons.calendar_today},
    {'id': 'saturday', 'title': 'Sat', 'fullTitle': 'Saturday', 'icon': Icons.weekend},
    {'id': 'sunday', 'title': 'Sun', 'fullTitle': 'Sunday', 'icon': Icons.weekend},
  ];

  final List<Map<String, dynamic>> _durations = [
    {'id': '15-30', 'title': '15-30 minutes', 'description': 'Quick sessions', 'icon': Icons.timer, 'color': Colors.green},
    {'id': '30-45', 'title': '30-45 minutes', 'description': 'Moderate sessions', 'icon': Icons.schedule, 'color': Colors.blue},
    {'id': '45-60', 'title': '45-60 minutes', 'description': 'Standard sessions', 'icon': Icons.access_time, 'color': Colors.orange},
    {'id': '60+', 'title': '60+ minutes', 'description': 'Extended sessions', 'icon': Icons.hourglass_full, 'color': Colors.red},
  ];

  final List<Map<String, dynamic>> _frequencies = [
    {'id': '2-3', 'title': '2-3 times per week', 'description': 'Light activity', 'icon': Icons.looks_two, 'color': Colors.green},
    {'id': '3-4', 'title': '3-4 times per week', 'description': 'Moderate activity', 'icon': Icons.looks_3, 'color': Colors.blue},
    {'id': '4-5', 'title': '4-5 times per week', 'description': 'High activity', 'icon': Icons.looks_4, 'color': Colors.orange},
    {'id': '6-7', 'title': '6-7 times per week', 'description': 'Very high activity', 'icon': Icons.looks_6, 'color': Colors.red},
  ];

  final List<Map<String, dynamic>> _flexibilityOptions = [
    {'id': 'strict', 'title': 'Strict Schedule', 'description': 'Same days and times', 'icon': Icons.schedule, 'color': Colors.red},
    {'id': 'flexible', 'title': 'Flexible', 'description': 'Can adjust as needed', 'icon': Icons.swap_horiz, 'color': Colors.blue},
    {'id': 'very_flexible', 'title': 'Very Flexible', 'description': 'Workout when possible', 'icon': Icons.all_inclusive, 'color': Colors.green},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadExistingData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadExistingData() {
    final onboardingState = ref.read(onboardingProvider);
    final stepData = onboardingState.stepData;
    
    if (stepData['workoutDays'] != null) {
      _selectedDays = List<String>.from(stepData['workoutDays']);
    }
    _selectedDuration = stepData['workoutDuration']?.toString();
    _selectedFrequency = stepData['workoutFrequency']?.toString();
    _selectedFlexibility = stepData['scheduleFlexibility']?.toString();
  }

  void _saveData() {
    final onboardingNotifier = ref.read(onboardingProvider.notifier);
    onboardingNotifier.updateMultipleStepData({
      'workoutDays': _selectedDays,
      'workoutDuration': _selectedDuration,
      'workoutFrequency': _selectedFrequency,
      'scheduleFlexibility': _selectedFlexibility,
      'preferredStartTime': _preferredStartTime?.format(context),
      'preferredEndTime': _preferredEndTime?.format(context),
    });
  }

  void _toggleDay(String dayId) {
    setState(() {
      if (_selectedDays.contains(dayId)) {
        _selectedDays.remove(dayId);
      } else {
        _selectedDays.add(dayId);
      }
    });
    _saveData();
    _animationController.forward().then((_) => _animationController.reset());
  }

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime 
          ? (_preferredStartTime ?? const TimeOfDay(hour: 7, minute: 0))
          : (_preferredEndTime ?? const TimeOfDay(hour: 19, minute: 0)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).colorScheme.surface,
              hourMinuteTextColor: Theme.of(context).colorScheme.onSurface,
              dayPeriodTextColor: Theme.of(context).colorScheme.onSurface,
              dialHandColor: Theme.of(context).colorScheme.primary,
              dialBackgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _preferredStartTime = picked;
        } else {
          _preferredEndTime = picked;
        }
      });
      _saveData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            OnboardingStep.preferences.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            OnboardingStep.preferences.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Workout Days Section
                  _buildSectionTitle('Which days do you prefer to workout?', Icons.calendar_today),
                  const SizedBox(height: 16),
                  
                  _buildEnhancedDaySelector(theme),
                  
                  const SizedBox(height: 32),
                  
                  // Preferred Time Section
                  if (_selectedDays.isNotEmpty) ...[
                    _buildSectionTitle('What time do you prefer to workout?', Icons.access_time),
                    const SizedBox(height: 16),
                    _buildTimeSelector(theme),
                    const SizedBox(height: 32),
                  ],
                  
                  // Workout Duration Section
                  _buildSectionTitle('How long do you want to workout?', Icons.timer),
                  const SizedBox(height: 16),
                  
                  _buildEnhancedSelectionGrid(_durations, _selectedDuration, (id) {
                    setState(() {
                      _selectedDuration = id;
                    });
                    _saveData();
                  }, theme),
                  
                  const SizedBox(height: 32),
                  
                  // Workout Frequency Section
                  _buildSectionTitle('How often do you want to workout?', Icons.repeat),
                  const SizedBox(height: 16),
                  
                  _buildEnhancedSelectionGrid(_frequencies, _selectedFrequency, (id) {
                    setState(() {
                      _selectedFrequency = id;
                    });
                    _saveData();
                  }, theme),
                  
                  const SizedBox(height: 32),
                  
                  // Schedule Flexibility Section
                  _buildSectionTitle('How flexible is your schedule?', Icons.tune),
                  const SizedBox(height: 16),
                  
                  _buildEnhancedSelectionGrid(_flexibilityOptions, _selectedFlexibility, (id) {
                    setState(() {
                      _selectedFlexibility = id;
                    });
                    _saveData();
                  }, theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }



  Widget _buildEnhancedDaySelector(ThemeData theme) {
    return Column(
      children: [
        // Days grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.8,
          ),
          itemCount: _weekDays.length,
          itemBuilder: (context, index) {
            final day = _weekDays[index];
            final isSelected = _selectedDays.contains(day['id']);
            final isWeekend = day['id'] == 'saturday' || day['id'] == 'sunday';
            
            return GestureDetector(
              onTap: () => _toggleDay(day['id']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surface,
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.5),
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      day['icon'],
                      size: 16,
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : (isWeekend ? Colors.orange : theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      day['title'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        size: 12,
                        color: theme.colorScheme.onPrimary,
                      )
                    else
                      const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        ),
        
        // Selected days summary
        if (_selectedDays.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_available,
                  color: theme.colorScheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_selectedDays.length} day${_selectedDays.length == 1 ? '' : 's'} selected: ${_selectedDays.map((id) => _weekDays.firstWhere((d) => d['id'] == id, orElse: () => {'title': id})['title']).join(', ')}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
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

  Widget _buildTimeSelector(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _selectTime(true),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _preferredStartTime != null
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : theme.colorScheme.surface,
                border: Border.all(
                  color: _preferredStartTime != null
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.5),
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.wb_sunny,
                    color: _preferredStartTime != null
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start Time',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _preferredStartTime?.format(context) ?? 'Select',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: _preferredStartTime != null
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () => _selectTime(false),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _preferredEndTime != null
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : theme.colorScheme.surface,
                border: Border.all(
                  color: _preferredEndTime != null
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.5),
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.nightlight_round,
                    color: _preferredEndTime != null
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'End Time',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _preferredEndTime?.format(context) ?? 'Select',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: _preferredEndTime != null
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedSelectionGrid(
    List<Map<String, dynamic>> options,
    String? selectedId,
    Function(String) onSelect,
    ThemeData theme,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final isSelected = selectedId == option['id'];
        
        return GestureDetector(
          onTap: () => onSelect(option['id']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? option['color'].withValues(alpha: 0.2)
                  : theme.colorScheme.surface,
              border: Border.all(
                color: isSelected
                    ? option['color']
                    : theme.colorScheme.outline.withValues(alpha: 0.5),
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: option['color'].withValues(alpha: 0.2),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  option['icon'],
                  size: 28,
                  color: isSelected
                      ? option['color']
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  option['title'],
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? option['color']
                        : theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  option['description'],
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? option['color'].withValues(alpha: 0.8)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isSelected) ...[
                  const SizedBox(height: 8),
                  Icon(
                    Icons.check_circle,
                    size: 20,
                    color: option['color'],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}