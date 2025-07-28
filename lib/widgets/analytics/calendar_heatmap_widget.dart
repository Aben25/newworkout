import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/analytics_provider.dart';
import '../../models/models.dart';

/// Calendar heatmap widget showing workout frequency over time
class CalendarHeatmapWidget extends ConsumerStatefulWidget {
  const CalendarHeatmapWidget({super.key});

  @override
  ConsumerState<CalendarHeatmapWidget> createState() => _CalendarHeatmapWidgetState();
}

class _CalendarHeatmapWidgetState extends ConsumerState<CalendarHeatmapWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workoutFrequency = ref.watch(workoutFrequencyAnalyticsProvider);

    return Column(
      children: [
        _buildMonthSelector(),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return _buildHeatmap(workoutFrequency);
          },
        ),
        const SizedBox(height: 16),
        _buildLegend(),
      ],
    );
  }

  Widget _buildMonthSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
            });
            _animationController.reset();
            _animationController.forward();
          },
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          _getMonthYearString(_selectedMonth),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          onPressed: _selectedMonth.isBefore(DateTime.now()) ? () {
            setState(() {
              _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
            });
            _animationController.reset();
            _animationController.forward();
          } : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _buildHeatmap(WorkoutFrequencyAnalytics? workoutFrequency) {
    if (workoutFrequency == null) {
      return _buildEmptyHeatmap();
    }

    final monthData = _getMonthData(workoutFrequency.dailyWorkouts, _selectedMonth);
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity( 0.2),
        ),
      ),
      child: Column(
        children: [
          _buildWeekdayHeaders(),
          const SizedBox(height: 8),
          _buildCalendarGrid(monthData, daysInMonth, firstWeekday),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders() {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: weekdays.map((day) {
        return Expanded(
          child: Text(
            day,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid(Map<int, int> monthData, int daysInMonth, int firstWeekday) {
    final weeks = <Widget>[];
    var currentWeek = <Widget>[];
    
    // Add empty cells for days before the first day of the month
    for (int i = 1; i < firstWeekday; i++) {
      currentWeek.add(_buildEmptyCell());
    }

    // Add cells for each day of the month
    for (int day = 1; day <= daysInMonth; day++) {
      final workoutCount = monthData[day] ?? 0;
      currentWeek.add(_buildDayCell(day, workoutCount));

      // If we've filled a week (7 days) or reached the end of the month
      if (currentWeek.length == 7 || day == daysInMonth) {
        // Fill remaining cells in the week if necessary
        while (currentWeek.length < 7) {
          currentWeek.add(_buildEmptyCell());
        }
        
        weeks.add(Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.from(currentWeek),
        ));
        currentWeek.clear();
      }
    }

    return Column(
      children: weeks.map((week) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: week,
      )).toList(),
    );
  }

  Widget _buildDayCell(int day, int workoutCount) {
    final isToday = _isToday(DateTime(_selectedMonth.year, _selectedMonth.month, day));
    final intensity = _getIntensity(workoutCount);
    
    return Expanded(
      child: AnimatedScale(
        scale: _animation.value,
        duration: Duration(milliseconds: 100 + (day * 10)),
        child: GestureDetector(
          onTap: () => _showDayDetails(day, workoutCount),
          child: Container(
            height: 28,
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: _getIntensityColor(intensity),
              borderRadius: BorderRadius.circular(4),
              border: isToday ? Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 1.5,
              ) : null,
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: intensity > 0.5 
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCell() {
    return const Expanded(child: SizedBox(height: 28));
  }

  Widget _buildEmptyHeatmap() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity( 0.2),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No workout data available',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Less',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        ...List.generate(5, (index) {
          final intensity = index / 4.0;
          return Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: _getIntensityColor(intensity),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
        const SizedBox(width: 8),
        Text(
          'More',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Map<int, int> _getMonthData(List<DailyWorkoutCount> dailyWorkouts, DateTime month) {
    final monthData = <int, int>{};
    
    for (final dayData in dailyWorkouts) {
      if (dayData.date.year == month.year && dayData.date.month == month.month) {
        monthData[dayData.date.day] = dayData.count;
      }
    }
    
    return monthData;
  }

  double _getIntensity(int workoutCount) {
    if (workoutCount == 0) return 0.0;
    if (workoutCount == 1) return 0.25;
    if (workoutCount == 2) return 0.5;
    if (workoutCount == 3) return 0.75;
    return 1.0;
  }

  Color _getIntensityColor(double intensity) {
    if (intensity == 0.0) {
      return Theme.of(context).colorScheme.surfaceContainerHighest;
    }
    
    return Color.lerp(
      Theme.of(context).colorScheme.primary.withOpacity( 0.2),
      Theme.of(context).colorScheme.primary,
      intensity,
    )!;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  String _getMonthYearString(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _showDayDetails(int day, int workoutCount) {
    final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_formatDateLong(date)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.fitness_center,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '$workoutCount workout${workoutCount != 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
            if (workoutCount > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Great job staying active!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDateLong(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}