# Analytics Service Documentation

## Overview

The Analytics Service provides comprehensive fitness tracking and performance analysis capabilities for the Modern Workout Tracker app. It leverages data from multiple tracking tables to generate insights about workout frequency, volume progression, personal records, and milestones.

## Architecture

### Core Components

1. **AnalyticsService**: Main service class that orchestrates data collection and analysis
2. **Analytics Data Models**: Structured data models for different types of analytics
3. **Analytics Provider**: Riverpod providers for state management and reactive UI updates
4. **Offline Caching**: Hive-based caching for offline analytics viewing

### Data Sources

The analytics system pulls data from the following database tables:

- `completed_workouts`: Historical workout completion records
- `completed_sets`: Detailed set-by-set performance logging
- `workout_logs`: Comprehensive workout session logs
- `workout_set_logs`: Individual set performance records

## Features

### 1. Workout Frequency Analytics

Tracks workout consistency and patterns:

- **Total Workouts**: Lifetime workout count
- **Current Streak**: Consecutive days with workouts
- **Longest Streak**: Best streak achievement
- **Consistency Score**: 0-1 score based on regularity
- **Weekly/Monthly Counts**: Recent activity levels
- **Daily Workout Heatmap**: Visual representation of workout frequency

```dart
final workoutFrequency = await analyticsService.getAnalyticsData();
print('Current streak: ${workoutFrequency.workoutFrequency.currentStreak} days');
```

### 2. Volume Analytics

Monitors strength progression through volume tracking:

- **Total Volume**: Lifetime volume lifted (sets × reps × weight)
- **Weekly/Monthly Volume**: Recent volume trends
- **Average Volume per Workout**: Performance consistency
- **Exercise-Specific Volume**: Per-exercise breakdown
- **Volume Trends**: 12-week progression analysis

```dart
final volume = analyticsData.volume;
print('Total volume: ${volume.totalVolumeLifetime}kg');
print('This week: ${volume.totalVolumeThisWeek}kg');
```

### 3. Personal Records Detection

Automatically identifies and tracks personal bests:

- **Max Weight**: Heaviest weight lifted per exercise
- **Max Reps**: Most reps completed per exercise
- **Max Volume**: Highest single-set volume
- **Best Time**: Fastest completion times (where applicable)

```dart
final personalRecords = analyticsData.personalRecords;
for (final pr in personalRecords) {
  print('${pr.exerciseName}: ${pr.formattedValue} (${pr.type})');
}
```

### 4. Milestone System

Recognizes significant achievements:

- **Workout Count Milestones**: 10, 25, 50, 100, 250, 500, 1000 workouts
- **Streak Milestones**: 7, 14, 30, 60, 100 day streaks
- **Volume Milestones**: 1k, 5k, 10k, 25k, 50k, 100k kg total volume
- **Personal Record Milestones**: Multiple PRs in timeframes

```dart
final milestones = analyticsData.milestones;
final recentMilestones = milestones
    .where((m) => DateTime.now().difference(m.achievedAt).inDays <= 30)
    .toList();
```

### 5. Trend Analysis

Identifies performance trends over time:

- **Volume Trend**: Increasing/decreasing volume patterns
- **Frequency Trend**: Workout frequency changes
- **Duration Trend**: Average workout length changes
- **Rating Trend**: Workout satisfaction trends

```dart
final trends = analyticsData.trends;
if (trends.volumeTrend > 0.05) {
  print('Volume is trending upward!');
}
```

## Usage

### Basic Analytics Loading

```dart
// Using the service directly
final analyticsService = AnalyticsService.instance;
final analyticsData = await analyticsService.getAnalyticsData();

// Using Riverpod providers
class AnalyticsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsNotifierProvider);
    
    return analyticsAsync.when(
      data: (data) => AnalyticsView(data: data),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => ErrorWidget(error),
    );
  }
}
```

### Refreshing Analytics

```dart
// Force refresh (clears cache and recalculates)
await analyticsService.refreshAnalytics();

// Using provider
ref.read(analyticsNotifierProvider.notifier).refreshAnalytics();
```

### Accessing Specific Analytics

```dart
// Using providers for specific data
final kpis = ref.watch(keyPerformanceIndicatorsProvider);
final consistency = ref.watch(consistencyMetricsProvider);
final achievements = ref.watch(achievementSummaryProvider);
```

## Data Models

### AnalyticsData

Main container for all analytics information:

```dart
class AnalyticsData {
  final String userId;
  final DateTime calculatedAt;
  final WorkoutFrequencyAnalytics workoutFrequency;
  final VolumeAnalytics volume;
  final ProgressAnalytics progress;
  final List<PersonalRecord> personalRecords;
  final List<Milestone> milestones;
  final TrendAnalytics trends;
  
  bool get isStale => DateTime.now().difference(calculatedAt).inHours > 1;
}
```

### WorkoutFrequencyAnalytics

Workout consistency and frequency metrics:

```dart
class WorkoutFrequencyAnalytics {
  final int totalWorkouts;
  final int workoutsThisWeek;
  final int workoutsThisMonth;
  final double averageWorkoutsPerWeek;
  final int currentStreak;
  final int longestStreak;
  final double consistencyScore; // 0.0 to 1.0
  final List<DailyWorkoutCount> dailyWorkouts;
}
```

### VolumeAnalytics

Volume tracking and progression metrics:

```dart
class VolumeAnalytics {
  final double totalVolumeLifetime;
  final double totalVolumeThisWeek;
  final double totalVolumeThisMonth;
  final double averageVolumePerWorkout;
  final double averageVolumePerWeek;
  final List<WeeklyVolumeData> weeklyVolume;
  final List<ExerciseVolumeData> exerciseVolume;
}
```

### PersonalRecord

Individual personal record achievements:

```dart
class PersonalRecord {
  final String exerciseId;
  final String exerciseName;
  final PersonalRecordType type; // maxWeight, maxReps, maxVolume, bestTime
  final double value;
  final DateTime achievedAt;
  final String workoutLogId;
  
  String get formattedValue; // Automatically formats based on type
}
```

## Caching Strategy

### Cache Lifecycle

1. **Fresh Calculation**: Analytics calculated from database on first request
2. **Cache Storage**: Results stored in Hive for offline access
3. **Cache Validation**: Data considered stale after 1 hour
4. **Automatic Refresh**: Stale data triggers background recalculation
5. **Offline Fallback**: Cached data used when offline

### Cache Management

```dart
// Clear cache for fresh calculation
await analyticsService.clearAnalyticsCache();

// Check if data is stale
final isStale = analyticsData.isStale;

// Force refresh
final freshData = await analyticsService.refreshAnalytics();
```

## Performance Considerations

### Optimization Strategies

1. **Incremental Calculation**: Only recalculate when new data is available
2. **Background Processing**: Heavy calculations performed off main thread
3. **Selective Loading**: Load only required analytics sections
4. **Efficient Queries**: Optimized database queries with proper indexing
5. **Smart Caching**: Cache results to minimize repeated calculations

### Memory Management

- Analytics data is automatically garbage collected when not in use
- Large datasets are processed in chunks to prevent memory spikes
- Hive boxes are compacted regularly to optimize storage

## Error Handling

### Common Error Scenarios

1. **No Data Available**: Graceful handling of empty datasets
2. **Network Failures**: Fallback to cached data
3. **Database Errors**: Retry mechanisms with exponential backoff
4. **Calculation Errors**: Safe defaults and error recovery

### Error Recovery

```dart
try {
  final analytics = await analyticsService.getAnalyticsData();
} catch (e) {
  // Fallback to cached data
  final cachedAnalytics = await cacheService.getCachedAnalytics(userId);
  if (cachedAnalytics != null) {
    return cachedAnalytics;
  }
  // Show error state
  throw AnalyticsException('Failed to load analytics: $e');
}
```

## Testing

### Unit Tests

The analytics service includes comprehensive unit tests covering:

- Data model creation and validation
- Calculation accuracy
- Edge case handling
- Error scenarios
- Cache behavior

### Integration Tests

Integration tests verify:

- Database query performance
- End-to-end analytics calculation
- Provider state management
- UI component integration

### Running Tests

```bash
# Run analytics service tests
flutter test test/services/analytics_service_test.dart

# Run all analytics-related tests
flutter test test/ --name="analytics"
```

## Future Enhancements

### Planned Features

1. **Predictive Analytics**: ML-based workout recommendations
2. **Comparative Analytics**: Compare with similar users
3. **Goal Tracking**: Progress toward specific fitness goals
4. **Advanced Visualizations**: Interactive charts and graphs
5. **Export Capabilities**: PDF reports and data export

### Performance Improvements

1. **Real-time Updates**: WebSocket-based live analytics
2. **Incremental Sync**: Only sync changed data
3. **Advanced Caching**: Multi-level cache hierarchy
4. **Background Sync**: Automatic data synchronization

## API Reference

### AnalyticsService Methods

```dart
// Get comprehensive analytics data
Future<AnalyticsData> getAnalyticsData({String? userId});

// Force refresh analytics
Future<AnalyticsData> refreshAnalytics({String? userId});

// Clear analytics cache
Future<void> clearAnalyticsCache({String? userId});
```

### Provider References

```dart
// Main analytics provider
final analyticsNotifierProvider;

// Specific analytics providers
final workoutFrequencyAnalyticsProvider;
final volumeAnalyticsProvider;
final progressAnalyticsProvider;
final personalRecordsProvider;
final milestonesProvider;
final trendAnalyticsProvider;

// Computed providers
final keyPerformanceIndicatorsProvider;
final consistencyMetricsProvider;
final achievementSummaryProvider;
```

## Troubleshooting

### Common Issues

1. **Slow Analytics Loading**: Check database query performance
2. **Stale Data**: Verify cache invalidation logic
3. **Missing Data**: Ensure proper data logging in workout sessions
4. **Memory Issues**: Monitor analytics data size and cleanup

### Debug Tools

```dart
// Enable debug logging
Logger.level = Level.debug;

// Check cache statistics
final stats = await cacheService.getCacheStatistics();
print('Analytics cache size: ${stats['analytics_data']}');

// Verify data freshness
final isStale = analyticsData.isStale;
print('Data is ${isStale ? 'stale' : 'fresh'}');
```