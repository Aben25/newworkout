// This is a basic Flutter widget test for Modern Workout Tracker.

import 'package:flutter_test/flutter_test.dart';

import 'package:modern_workout_tracker/constants/app_constants.dart';

void main() {
  group('App Constants Tests', () {
    test('App constants are properly defined', () {
      expect(AppConstants.appName, 'Modern Workout Tracker');
      expect(AppConstants.appVersion, '1.0.0');
      expect(AppConstants.defaultPageSize, 20);
      expect(AppConstants.minPasswordLength, 8);
    });

    test('Storage box names are defined', () {
      expect(AppConstants.userProfileBox, 'user_profile');
      expect(AppConstants.workoutCacheBox, 'workout_cache');
      expect(AppConstants.syncQueueBox, 'sync_queue');
      expect(AppConstants.settingsBox, 'settings');
    });

    test('Table names are defined', () {
      expect(AppConstants.profilesTable, 'profiles');
      expect(AppConstants.workoutsTable, 'workouts');
      expect(AppConstants.exercisesTable, 'exercises');
    });
  });
}
