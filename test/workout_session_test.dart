import 'package:flutter_test/flutter_test.dart';

import 'package:modern_workout_tracker/models/models.dart';
import 'package:modern_workout_tracker/services/workout_session_service.dart';

void main() {
  group('WorkoutSessionState', () {
    test('should create idle state correctly', () {
      const state = WorkoutSessionState.idle();
      expect(state, isA<WorkoutSessionIdle>());
    });

    test('should create loading state correctly', () {
      const state = WorkoutSessionState.loading();
      expect(state, isA<WorkoutSessionLoading>());
    });

    test('should create active state correctly', () {
      final workout = Workout(
        id: 'test-workout-id',
        userId: 'test-user-id',
        name: 'Test Workout',
        isActive: true,
        sessionOrder: 1,
        startTime: DateTime.now(),
      );

      final workoutExercise = WorkoutExercise(
        id: 'test-exercise-id',
        workoutId: 'test-workout-id',
        exerciseId: 'exercise-1',
        name: 'Push-ups',
        sets: 3,
        restInterval: 60,
      );

      final exercise = Exercise(
        id: 'exercise-1',
        name: 'Push-ups',
        createdAt: DateTime.now(),
      );

      final state = WorkoutSessionState.active(
        workout: workout,
        workoutExercises: [workoutExercise],
        exercises: [exercise],
        currentExerciseIndex: 0,
        currentSet: 1,
        completedSets: const [],
        exerciseLogs: const [],
        startTime: DateTime.now(),
        lastSyncTime: DateTime.now(),
        isRestTimerActive: false,
        restTimeRemaining: 0,
      );

      expect(state, isA<WorkoutSessionActive>());
      
      final activeState = state as WorkoutSessionActive;
      expect(activeState.workout.id, equals('test-workout-id'));
      expect(activeState.currentExerciseIndex, equals(0));
      expect(activeState.currentSet, equals(1));
      expect(activeState.completedSets, isEmpty);
      expect(activeState.exerciseLogs, isEmpty);
      expect(activeState.isRestTimerActive, isFalse);
      expect(activeState.restTimeRemaining, equals(0));
    });

    test('should handle when pattern matching correctly', () {
      const idleState = WorkoutSessionState.idle();
      const loadingState = WorkoutSessionState.loading();
      const errorState = WorkoutSessionState.error('Test error');

      final idleResult = idleState.when(
        idle: () => 'idle',
        loading: () => 'loading',
        active: (_, __, ___, ____, _____, ______, _______, ________, _________, __________, ___________) => 'active',
        paused: (_, __, ___, ____, _____, ______, _______, ________, _________) => 'paused',
        completed: (_, __, ___, ____, _____, ______, _______, ________, _________) => 'completed',
        error: (message) => 'error: $message',
      );

      final loadingResult = loadingState.when(
        idle: () => 'idle',
        loading: () => 'loading',
        active: (_, __, ___, ____, _____, ______, _______, ________, _________, __________, ___________) => 'active',
        paused: (_, __, ___, ____, _____, ______, _______, ________, _________) => 'paused',
        completed: (_, __, ___, ____, _____, ______, _______, ________, _________) => 'completed',
        error: (message) => 'error: $message',
      );

      final errorResult = errorState.when(
        idle: () => 'idle',
        loading: () => 'loading',
        active: (_, __, ___, ____, _____, ______, _______, ________, _________, __________, ___________) => 'active',
        paused: (_, __, ___, ____, _____, ______, _______, ________, _________) => 'paused',
        completed: (_, __, ___, ____, _____, ______, _______, ________, _________) => 'completed',
        error: (message) => 'error: $message',
      );

      expect(idleResult, equals('idle'));
      expect(loadingResult, equals('loading'));
      expect(errorResult, equals('error: Test error'));
    });
  });

  group('CompletedSetLog', () {
    test('should create completed set log correctly', () {
      final timestamp = DateTime.now();
      final setLog = CompletedSetLog(
        workoutExerciseId: 'we-1',
        exerciseId: 'ex-1',
        exerciseIndex: 0,
        setNumber: 1,
        reps: 10,
        weight: 50.0,
        notes: 'Good form',
        difficultyRating: 'moderate',
        timestamp: timestamp,
      );

      expect(setLog.workoutExerciseId, equals('we-1'));
      expect(setLog.exerciseId, equals('ex-1'));
      expect(setLog.exerciseIndex, equals(0));
      expect(setLog.setNumber, equals(1));
      expect(setLog.reps, equals(10));
      expect(setLog.weight, equals(50.0));
      expect(setLog.notes, equals('Good form'));
      expect(setLog.difficultyRating, equals('moderate'));
      expect(setLog.timestamp, equals(timestamp));
    });

    test('should calculate volume correctly', () {
      final setLog = CompletedSetLog(
        workoutExerciseId: 'we-1',
        exerciseId: 'ex-1',
        exerciseIndex: 0,
        setNumber: 1,
        reps: 10,
        weight: 50.0,
        timestamp: DateTime.now(),
      );

      expect(setLog.volume, equals(500.0));
    });

    test('should format weight correctly', () {
      final weightedSetLog = CompletedSetLog(
        workoutExerciseId: 'we-1',
        exerciseId: 'ex-1',
        exerciseIndex: 0,
        setNumber: 1,
        reps: 10,
        weight: 50.0,
        timestamp: DateTime.now(),
      );

      final bodyweightSetLog = CompletedSetLog(
        workoutExerciseId: 'we-1',
        exerciseId: 'ex-1',
        exerciseIndex: 0,
        setNumber: 1,
        reps: 10,
        weight: 0.0,
        timestamp: DateTime.now(),
      );

      expect(weightedSetLog.formattedWeight, equals('50.0kg'));
      expect(bodyweightSetLog.formattedWeight, equals('Bodyweight'));
    });

    test('should format reps correctly', () {
      final setLog = CompletedSetLog(
        workoutExerciseId: 'we-1',
        exerciseId: 'ex-1',
        exerciseIndex: 0,
        setNumber: 1,
        reps: 10,
        weight: 50.0,
        timestamp: DateTime.now(),
      );

      expect(setLog.formattedReps, equals('10 reps'));
    });

    test('should get difficulty rating value correctly', () {
      final easySetLog = CompletedSetLog(
        workoutExerciseId: 'we-1',
        exerciseId: 'ex-1',
        exerciseIndex: 0,
        setNumber: 1,
        reps: 10,
        weight: 50.0,
        difficultyRating: 'easy',
        timestamp: DateTime.now(),
      );

      final moderateSetLog = CompletedSetLog(
        workoutExerciseId: 'we-1',
        exerciseId: 'ex-1',
        exerciseIndex: 0,
        setNumber: 1,
        reps: 10,
        weight: 50.0,
        difficultyRating: 'moderate',
        timestamp: DateTime.now(),
      );

      final hardSetLog = CompletedSetLog(
        workoutExerciseId: 'we-1',
        exerciseId: 'ex-1',
        exerciseIndex: 0,
        setNumber: 1,
        reps: 10,
        weight: 50.0,
        difficultyRating: 'hard',
        timestamp: DateTime.now(),
      );

      expect(easySetLog.difficultyRatingValue, equals(2.0));
      expect(moderateSetLog.difficultyRatingValue, equals(3.0));
      expect(hardSetLog.difficultyRatingValue, equals(4.0));
    });
  });

  group('ExerciseLogSession', () {
    test('should create exercise log session correctly', () {
      final setLog = CompletedSetLog(
        workoutExerciseId: 'we-1',
        exerciseId: 'ex-1',
        exerciseIndex: 0,
        setNumber: 1,
        reps: 10,
        weight: 50.0,
        timestamp: DateTime.now(),
      );

      final startTime = DateTime.now().subtract(Duration(minutes: 5));
      final endTime = DateTime.now();

      final exerciseLog = ExerciseLogSession(
        exerciseId: 'ex-1',
        sets: [setLog],
        notes: 'Good exercise',
        difficultyRating: 'moderate',
        startTime: startTime,
        endTime: endTime,
      );

      expect(exerciseLog.exerciseId, equals('ex-1'));
      expect(exerciseLog.sets.length, equals(1));
      expect(exerciseLog.notes, equals('Good exercise'));
      expect(exerciseLog.difficultyRating, equals('moderate'));
      expect(exerciseLog.startTime, equals(startTime));
      expect(exerciseLog.endTime, equals(endTime));
    });

    test('should calculate total reps correctly', () {
      final setLog1 = CompletedSetLog(
        workoutExerciseId: 'we-1',
        exerciseId: 'ex-1',
        exerciseIndex: 0,
        setNumber: 1,
        reps: 10,
        weight: 50.0,
        timestamp: DateTime.now(),
      );

      final setLog2 = CompletedSetLog(
        workoutExerciseId: 'we-1',
        exerciseId: 'ex-1',
        exerciseIndex: 0,
        setNumber: 2,
        reps: 8,
        weight: 55.0,
        timestamp: DateTime.now(),
      );

      final exerciseLog = ExerciseLogSession(
        exerciseId: 'ex-1',
        sets: [setLog1, setLog2],
      );

      expect(exerciseLog.totalReps, equals(18));
    });

    test('should calculate total volume correctly', () {
      final setLog1 = CompletedSetLog(
        workoutExerciseId: 'we-1',
        exerciseId: 'ex-1',
        exerciseIndex: 0,
        setNumber: 1,
        reps: 10,
        weight: 50.0,
        timestamp: DateTime.now(),
      );

      final setLog2 = CompletedSetLog(
        workoutExerciseId: 'we-1',
        exerciseId: 'ex-1',
        exerciseIndex: 0,
        setNumber: 2,
        reps: 8,
        weight: 55.0,
        timestamp: DateTime.now(),
      );

      final exerciseLog = ExerciseLogSession(
        exerciseId: 'ex-1',
        sets: [setLog1, setLog2],
      );

      expect(exerciseLog.totalVolume, equals(940.0)); // (10 * 50) + (8 * 55)
    });

    test('should check completion status correctly', () {
      final setLog = CompletedSetLog(
        workoutExerciseId: 'we-1',
        exerciseId: 'ex-1',
        exerciseIndex: 0,
        setNumber: 1,
        reps: 10,
        weight: 50.0,
        timestamp: DateTime.now(),
      );

      final exerciseLogWithSets = ExerciseLogSession(
        exerciseId: 'ex-1',
        sets: [setLog],
      );

      final exerciseLogEmpty = ExerciseLogSession(
        exerciseId: 'ex-1',
        sets: [],
      );

      expect(exerciseLogWithSets.isComplete, isTrue);
      expect(exerciseLogWithSets.hasStarted, isTrue);
      expect(exerciseLogEmpty.isComplete, isFalse);
      expect(exerciseLogEmpty.hasStarted, isFalse);
    });
  });

  group('WorkoutSessionService', () {
    late WorkoutSessionService service;

    setUp(() {
      service = WorkoutSessionService.instance;
    });

    test('should estimate calories burned correctly', () {
      // Arrange
      final duration = Duration(minutes: 45);
      final completedSets = [
        CompletedSetLog(
          workoutExerciseId: 'we-1',
          exerciseId: 'ex-1',
          exerciseIndex: 0,
          setNumber: 1,
          reps: 10,
          weight: 50.0,
          timestamp: DateTime.now(),
        ),
        CompletedSetLog(
          workoutExerciseId: 'we-1',
          exerciseId: 'ex-1',
          exerciseIndex: 0,
          setNumber: 2,
          reps: 8,
          weight: 55.0,
          timestamp: DateTime.now(),
        ),
      ];

      // Act
      final calories = service.estimateCaloriesBurned(
        duration: duration,
        completedSets: completedSets,
        userWeight: 70.0,
      );

      // Assert
      expect(calories, greaterThan(0));
      expect(calories, lessThanOrEqualTo(1000)); // Within reasonable bounds
    });

    test('should create workout summary correctly', () {
      // Arrange
      final duration = Duration(minutes: 30);
      final completedSets = [
        CompletedSetLog(
          workoutExerciseId: 'we-1',
          exerciseId: 'ex-1',
          exerciseIndex: 0,
          setNumber: 1,
          reps: 10,
          weight: 50.0,
          timestamp: DateTime.now(),
        ),
      ];
      final exerciseLogs = [
        ExerciseLogSession(
          exerciseId: 'ex-1',
          sets: completedSets,
          startTime: DateTime.now().subtract(Duration(minutes: 30)),
          endTime: DateTime.now(),
        ),
      ];
      final exercises = [
        Exercise(
          id: 'ex-1',
          name: 'Bench Press',
          createdAt: DateTime.now(),
        ),
      ];

      // Act
      final summary = service.createWorkoutSummary(
        duration: duration,
        completedSets: completedSets,
        exerciseLogs: exerciseLogs,
        exercises: exercises,
      );

      // Assert
      expect(summary['duration_minutes'], equals(30));
      expect(summary['total_sets'], equals(1));
      expect(summary['total_reps'], equals(10));
      expect(summary['total_volume_kg'], equals(500.0));
      expect(summary['exercises_completed'], equals(1));
      expect(summary['exercise_breakdown'], isA<Map>());
      expect(summary['exercise_breakdown']['ex-1']['name'], equals('Bench Press'));
    });
  });
}