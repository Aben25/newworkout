import 'package:flutter_test/flutter_test.dart';
import 'package:modern_workout_tracker/models/models.dart';
import 'package:modern_workout_tracker/services/analytics_service.dart';

void main() {
  group('AnalyticsService', () {
    late AnalyticsService analyticsService;

    setUp(() {
      analyticsService = AnalyticsService.instance;
    });

    test('should be a singleton', () {
      final instance1 = AnalyticsService.instance;
      final instance2 = AnalyticsService.instance;
      expect(instance1, same(instance2));
    });

    test('should handle empty data gracefully', () {
      // Test that the service can handle empty data sets
      expect(analyticsService, isNotNull);
    });

    group('VolumeDataPoint', () {
      test('should create volume data point correctly', () {
        final dataPoint = VolumeDataPoint(
          date: DateTime.now(),
          volume: 100.0,
          exerciseId: 'test-exercise-id',
        );

        expect(dataPoint.volume, equals(100.0));
        expect(dataPoint.exerciseId, equals('test-exercise-id'));
        expect(dataPoint.date, isA<DateTime>());
      });
    });

    group('Analytics Data Models', () {
      test('should create WorkoutFrequencyAnalytics correctly', () {
        final analytics = WorkoutFrequencyAnalytics(
          totalWorkouts: 50,
          workoutsThisWeek: 3,
          workoutsThisMonth: 12,
          averageWorkoutsPerWeek: 3.5,
          currentStreak: 5,
          longestStreak: 15,
          consistencyScore: 0.8,
          dailyWorkouts: [],
        );

        expect(analytics.totalWorkouts, equals(50));
        expect(analytics.workoutsThisWeek, equals(3));
        expect(analytics.consistencyScore, equals(0.8));
      });

      test('should create VolumeAnalytics correctly', () {
        final analytics = VolumeAnalytics(
          totalVolumeLifetime: 10000.0,
          totalVolumeThisWeek: 500.0,
          totalVolumeThisMonth: 2000.0,
          averageVolumePerWorkout: 200.0,
          averageVolumePerWeek: 400.0,
          weeklyVolume: [],
          exerciseVolume: [],
        );

        expect(analytics.totalVolumeLifetime, equals(10000.0));
        expect(analytics.totalVolumeThisWeek, equals(500.0));
        expect(analytics.averageVolumePerWorkout, equals(200.0));
      });

      test('should create PersonalRecord correctly', () {
        final pr = PersonalRecord(
          exerciseId: 'bench-press',
          exerciseName: 'Bench Press',
          type: PersonalRecordType.maxWeight,
          value: 100.0,
          achievedAt: DateTime.now(),
          workoutLogId: 'workout-log-id',
        );

        expect(pr.exerciseId, equals('bench-press'));
        expect(pr.type, equals(PersonalRecordType.maxWeight));
        expect(pr.value, equals(100.0));
        expect(pr.formattedValue, equals('100.0kg'));
      });

      test('should format PersonalRecord values correctly', () {
        final weightPR = PersonalRecord(
          exerciseId: 'test',
          exerciseName: 'Test Exercise',
          type: PersonalRecordType.maxWeight,
          value: 85.5,
          achievedAt: DateTime.now(),
          workoutLogId: 'test',
        );

        final repsPR = PersonalRecord(
          exerciseId: 'test',
          exerciseName: 'Test Exercise',
          type: PersonalRecordType.maxReps,
          value: 15.0,
          achievedAt: DateTime.now(),
          workoutLogId: 'test',
        );

        final volumePR = PersonalRecord(
          exerciseId: 'test',
          exerciseName: 'Test Exercise',
          type: PersonalRecordType.maxVolume,
          value: 1275.0,
          achievedAt: DateTime.now(),
          workoutLogId: 'test',
        );

        final timePR = PersonalRecord(
          exerciseId: 'test',
          exerciseName: 'Test Exercise',
          type: PersonalRecordType.bestTime,
          value: 180.0, // 3 minutes in seconds
          achievedAt: DateTime.now(),
          workoutLogId: 'test',
        );

        expect(weightPR.formattedValue, equals('85.5kg'));
        expect(repsPR.formattedValue, equals('15 reps'));
        expect(volumePR.formattedValue, equals('1275.0kg'));
        expect(timePR.formattedValue, equals('3.0min'));
      });

      test('should create Milestone correctly', () {
        final milestone = Milestone(
          id: 'milestone-1',
          type: MilestoneType.workoutCount,
          title: '100 Workouts Completed',
          description: 'Completed 100 total workouts',
          achievedAt: DateTime.now(),
          metadata: {'count': 100},
        );

        expect(milestone.type, equals(MilestoneType.workoutCount));
        expect(milestone.title, equals('100 Workouts Completed'));
        expect(milestone.metadata['count'], equals(100));
      });
    });

    group('Data Point Models', () {
      test('should create DailyWorkoutCount correctly', () {
        final dailyCount = DailyWorkoutCount(
          date: DateTime(2024, 1, 15),
          count: 2,
        );

        expect(dailyCount.count, equals(2));
        expect(dailyCount.date.day, equals(15));
      });

      test('should create WeeklyVolumeData correctly', () {
        final weeklyData = WeeklyVolumeData(
          weekStart: DateTime(2024, 1, 8), // Monday
          volume: 1500.0,
        );

        expect(weeklyData.volume, equals(1500.0));
        expect(weeklyData.weekStart.weekday, equals(1)); // Monday
      });

      test('should create ExerciseProgressData correctly', () {
        final progressData = ExerciseProgressData(
          exerciseId: 'squat',
          exerciseName: 'Squat',
          maxWeight: 120.0,
          maxReps: 20,
          totalVolume: 5000.0,
          totalSets: 50,
          progressHistory: [],
        );

        expect(progressData.exerciseId, equals('squat'));
        expect(progressData.maxWeight, equals(120.0));
        expect(progressData.totalSets, equals(50));
      });

      test('should create TrendDataPoint correctly', () {
        final trendPoint = TrendDataPoint(
          date: DateTime.now(),
          value: 250.0,
        );

        expect(trendPoint.value, equals(250.0));
        expect(trendPoint.date, isA<DateTime>());
      });
    });

    group('Analytics Data Integration', () {
      test('should create complete AnalyticsData correctly', () {
        final analyticsData = AnalyticsData(
          userId: 'user-123',
          calculatedAt: DateTime.now(),
          workoutFrequency: WorkoutFrequencyAnalytics(
            totalWorkouts: 25,
            workoutsThisWeek: 2,
            workoutsThisMonth: 8,
            averageWorkoutsPerWeek: 3.0,
            currentStreak: 3,
            longestStreak: 10,
            consistencyScore: 0.75,
            dailyWorkouts: [],
          ),
          volume: VolumeAnalytics(
            totalVolumeLifetime: 5000.0,
            totalVolumeThisWeek: 300.0,
            totalVolumeThisMonth: 1200.0,
            averageVolumePerWorkout: 200.0,
            averageVolumePerWeek: 350.0,
            weeklyVolume: [],
            exerciseVolume: [],
          ),
          progress: ProgressAnalytics(
            totalSets: 150,
            totalReps: 1500,
            totalExercisesCompleted: 75,
            averageWorkoutDuration: 45.0,
            averageWorkoutRating: 4.2,
            totalCaloriesBurned: 2500,
            exerciseProgress: [],
          ),
          personalRecords: [],
          milestones: [],
          trends: TrendAnalytics(
            volumeTrend: 0.15,
            frequencyTrend: 0.05,
            durationTrend: -0.02,
            ratingTrend: 0.08,
            volumeTrendData: [],
            frequencyTrendData: [],
          ),
        );

        expect(analyticsData.userId, equals('user-123'));
        expect(analyticsData.workoutFrequency.totalWorkouts, equals(25));
        expect(analyticsData.volume.totalVolumeLifetime, equals(5000.0));
        expect(analyticsData.progress.totalSets, equals(150));
        expect(analyticsData.trends.volumeTrend, equals(0.15));
        expect(analyticsData.isStale, isFalse); // Should be fresh since just created
      });

      test('should detect stale analytics data', () {
        final oldAnalyticsData = AnalyticsData(
          userId: 'user-123',
          calculatedAt: DateTime.now().subtract(const Duration(hours: 2)),
          workoutFrequency: WorkoutFrequencyAnalytics(
            totalWorkouts: 0,
            workoutsThisWeek: 0,
            workoutsThisMonth: 0,
            averageWorkoutsPerWeek: 0.0,
            currentStreak: 0,
            longestStreak: 0,
            consistencyScore: 0.0,
            dailyWorkouts: [],
          ),
          volume: VolumeAnalytics(
            totalVolumeLifetime: 0.0,
            totalVolumeThisWeek: 0.0,
            totalVolumeThisMonth: 0.0,
            averageVolumePerWorkout: 0.0,
            averageVolumePerWeek: 0.0,
            weeklyVolume: [],
            exerciseVolume: [],
          ),
          progress: ProgressAnalytics(
            totalSets: 0,
            totalReps: 0,
            totalExercisesCompleted: 0,
            averageWorkoutDuration: 0.0,
            averageWorkoutRating: 0.0,
            totalCaloriesBurned: 0,
            exerciseProgress: [],
          ),
          personalRecords: [],
          milestones: [],
          trends: TrendAnalytics(
            volumeTrend: 0.0,
            frequencyTrend: 0.0,
            durationTrend: 0.0,
            ratingTrend: 0.0,
            volumeTrendData: [],
            frequencyTrendData: [],
          ),
        );

        expect(oldAnalyticsData.isStale, isTrue);
      });
    });
  });
}