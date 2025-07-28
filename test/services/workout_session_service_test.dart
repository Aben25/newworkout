import 'package:flutter_test/flutter_test.dart';
import 'package:modern_workout_tracker/services/workout_session_service.dart';
import 'package:modern_workout_tracker/models/models.dart';

void main() {
  group('WorkoutSessionService', () {
    late WorkoutSessionService service;

    setUp(() {
      service = WorkoutSessionService.instance;
    });

    test('should be a singleton', () {
      final service1 = WorkoutSessionService.instance;
      final service2 = WorkoutSessionService.instance;
      expect(service1, same(service2));
    });

    test('should estimate calories burned', () {
      final completedSets = [
        CompletedSetLog(
          workoutExerciseId: 'test-1',
          exerciseId: 'exercise-1',
          exerciseIndex: 0,
          setNumber: 1,
          reps: 10,
          weight: 50.0,
          timestamp: DateTime.now(),
        ),
        CompletedSetLog(
          workoutExerciseId: 'test-1',
          exerciseId: 'exercise-1',
          exerciseIndex: 0,
          setNumber: 2,
          reps: 8,
          weight: 55.0,
          timestamp: DateTime.now(),
        ),
      ];

      final calories = service.estimateCaloriesBurned(
        duration: const Duration(minutes: 30),
        completedSets: completedSets,
        userWeight: 70.0,
      );

      expect(calories, greaterThan(0));
      expect(calories, lessThan(1000));
    });

    test('should create workout summary', () {
      final completedSets = [
        CompletedSetLog(
          workoutExerciseId: 'test-1',
          exerciseId: 'exercise-1',
          exerciseIndex: 0,
          setNumber: 1,
          reps: 10,
          weight: 50.0,
          timestamp: DateTime.now(),
        ),
      ];

      final exerciseLogs = [
        ExerciseLogSession(
          exerciseId: 'exercise-1',
          sets: completedSets,
          startTime: DateTime.now().subtract(const Duration(minutes: 10)),
          endTime: DateTime.now(),
        ),
      ];

      final exercises = [
        Exercise(
          id: 'exercise-1',
          name: 'Test Exercise',
          createdAt: DateTime.now(),
        ),
      ];

      final summary = service.createWorkoutSummary(
        duration: const Duration(minutes: 30),
        completedSets: completedSets,
        exerciseLogs: exerciseLogs,
        exercises: exercises,
      );

      expect(summary['duration_minutes'], equals(30));
      expect(summary['total_sets'], equals(1));
      expect(summary['total_reps'], equals(10));
      expect(summary['exercises_completed'], equals(1));
      expect(summary['exercise_breakdown'], isA<Map<String, dynamic>>());
    });
  });
}