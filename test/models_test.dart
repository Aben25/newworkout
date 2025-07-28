import 'package:flutter_test/flutter_test.dart';
import 'package:modern_workout_tracker/models/models.dart';

void main() {
  group('Model Tests', () {
    test('UserProfile model creation and serialization', () {
      final profile = UserProfile(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
        age: 25,
        gender: 'male',
        height: 180.0,
        weight: 75.0,
        fitnessGoalsArray: ['weight_loss', 'muscle_gain'],
        equipment: ['dumbbells', 'barbell'],
        workoutDays: ['monday', 'wednesday', 'friday'],
        workoutDurationInt: 60,
        workoutFrequencyInt: 3,
        onboardingCompleted: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(profile.id, 'test-id');
      expect(profile.email, 'test@example.com');
      expect(profile.isBasicInfoComplete, true);
      expect(profile.isFitnessGoalsComplete, true);
      expect(profile.isEquipmentComplete, true);
      expect(profile.isWorkoutPreferencesComplete, true);
      expect(profile.profileCompletionPercentage, 1.0);

      // Test JSON serialization
      final json = profile.toJson();
      expect(json['id'], 'test-id');
      expect(json['email'], 'test@example.com');

      // Test JSON deserialization
      final fromJson = UserProfile.fromJson(json);
      expect(fromJson.id, profile.id);
      expect(fromJson.email, profile.email);
    });

    test('Exercise model creation and validation', () {
      final exercise = Exercise(
        id: 'exercise-1',
        name: 'Push-ups',
        description: 'Classic bodyweight exercise',
        instructions: 'Lower your body until chest touches ground',
        primaryMuscle: 'chest',
        secondaryMuscle: 'triceps',
        equipment: 'bodyweight',
        category: 'strength',
        createdAt: DateTime.now(),
      );

      expect(exercise.id, 'exercise-1');
      expect(exercise.name, 'Push-ups');
      expect(exercise.isComplete, true);
      expect(exercise.hasInstructions, true);
      expect(exercise.muscleGroups, ['chest', 'triceps']);
      expect(exercise.matchesFilter(muscleGroup: 'chest'), true);
      expect(exercise.matchesFilter(muscleGroup: 'legs'), false);
      expect(exercise.matchesSearch('push'), true);
      expect(exercise.matchesSearch('squat'), false);

      // Test JSON serialization
      final json = exercise.toJson();
      final fromJson = Exercise.fromJson(json);
      expect(fromJson.id, exercise.id);
      expect(fromJson.name, exercise.name);
    });

    test('WorkoutExercise model with performance tracking', () {
      final workoutExercise = WorkoutExercise(
        id: 'we-1',
        workoutId: 'workout-1',
        exerciseId: 'exercise-1',
        name: 'Push-ups',
        sets: 3,
        reps: [10, 12, 8],
        weight: [0, 0, 0], // Bodyweight
        repsOld: [8, 10, 6],
        restInterval: 60,
        createdAt: DateTime.now(),
      );

      expect(workoutExercise.isValid, true);
      expect(workoutExercise.hasRepsData, true);
      expect(workoutExercise.hasProgressData, true);
      expect(workoutExercise.effectiveSets, 3);
      expect(workoutExercise.averageReps, 10.0);
      expect(workoutExercise.totalVolume, 0.0); // Bodyweight exercise

      final progress = workoutExercise.getProgressComparison();
      expect(progress['hasProgress'], true);
      expect(progress['currentTotal'], 30);
      expect(progress['previousTotal'], 24);
      expect(progress['improvement'], 6);
      expect(progress['isImprovement'], true);

      // Test JSON serialization
      final json = workoutExercise.toJson();
      final fromJson = WorkoutExercise.fromJson(json);
      expect(fromJson.id, workoutExercise.id);
      expect(fromJson.reps, workoutExercise.reps);
    });

    test('CompletedSet model with difficulty tracking', () {
      final completedSet = CompletedSet(
        id: 1,
        workoutId: 'workout-1',
        workoutExerciseId: 'we-1',
        performedSetOrder: 1,
        performedReps: 12,
        performedWeight: 50,
        setFeedbackDifficulty: 'moderate',
        createdAt: DateTime.now(),
      );

      expect(completedSet.isValid, true);
      expect(completedSet.hasWeight, true);
      expect(completedSet.hasFeedback, true);
      expect(completedSet.volume, 600.0);
      expect(completedSet.difficulty, SetDifficulty.moderate);
      expect(completedSet.formattedWeight, '50kg');
      expect(completedSet.formattedReps, '12 reps');

      // Test JSON serialization
      final json = completedSet.toJson();
      final fromJson = CompletedSet.fromJson(json);
      expect(fromJson.id, completedSet.id);
      expect(fromJson.performedReps, completedSet.performedReps);
    });

    test('WorkoutLog model with status tracking', () {
      final startTime = DateTime.now().subtract(Duration(hours: 1));
      final endTime = DateTime.now();
      
      final workoutLog = WorkoutLog(
        id: 'log-1',
        userId: 'user-1',
        workoutId: 'workout-1',
        startedAt: startTime,
        endedAt: endTime,
        rating: 4,
        notes: 'Great workout!',
        status: 'completed',
        createdAt: startTime,
      );

      expect(workoutLog.isValid, true);
      expect(workoutLog.isCompleted, true);
      expect(workoutLog.hasRating, true);
      expect(workoutLog.hasNotes, true);
      expect(workoutLog.workoutStatus, WorkoutStatus.completed);
      expect(workoutLog.isHighRated, true);
      expect(workoutLog.durationInMinutes, 60);

      // Test JSON serialization
      final json = workoutLog.toJson();
      final fromJson = WorkoutLog.fromJson(json);
      expect(fromJson.id, workoutLog.id);
      expect(fromJson.rating, workoutLog.rating);
    });

    test('Workout model with state management', () {
      final workout = Workout(
        id: 'workout-1',
        userId: 'user-1',
        name: 'Push Day',
        description: 'Upper body push workout',
        startTime: DateTime.now().subtract(Duration(minutes: 30)),
        isActive: true,
        sessionOrder: 1,
        lastState: {
          'current_exercise_index': 1,
          'current_set': 2,
          'completed_exercises': ['exercise-1'],
          'exercise_logs': [],
          'total_exercises': 5,
          'last_updated': DateTime.now().toIso8601String(),
        },
        createdAt: DateTime.now().subtract(Duration(hours: 1)),
      );

      expect(workout.isValid, true);
      expect(workout.hasName, true);
      expect(workout.isInProgress, true);
      expect(workout.hasState, true);
      expect(workout.canResume, true);
      expect(workout.durationInMinutes, 30);

      // Test JSON serialization
      final json = workout.toJson();
      final fromJson = Workout.fromJson(json);
      expect(fromJson.id, workout.id);
      expect(fromJson.name, workout.name);
    });
  });
}