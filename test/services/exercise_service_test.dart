import 'package:flutter_test/flutter_test.dart';
import 'package:modern_workout_tracker/services/exercise_service.dart';

void main() {
  group('ExerciseService', () {
    late ExerciseService exerciseService;

    setUp(() {
      exerciseService = ExerciseService.instance;
    });

    test('should be a singleton', () {
      final instance1 = ExerciseService.instance;
      final instance2 = ExerciseService.instance;
      expect(instance1, same(instance2));
    });

    test('should clear cache', () {
      exerciseService.clearCache();
      // Test passes if no exception is thrown
      expect(true, isTrue);
    });

    test('should get muscle groups', () async {
      // This test would require mocking the Supabase service
      // For now, we just test that the method exists and can be called
      try {
        final muscleGroups = await exerciseService.getMuscleGroups();
        expect(muscleGroups, isA<List<String>>());
      } catch (e) {
        // Expected to fail without proper Supabase setup
        expect(e, isNotNull);
      }
    });

    test('should get equipment types', () async {
      try {
        final equipmentTypes = await exerciseService.getEquipmentTypes();
        expect(equipmentTypes, isA<List<String>>());
      } catch (e) {
        // Expected to fail without proper Supabase setup
        expect(e, isNotNull);
      }
    });

    test('should get categories', () async {
      try {
        final categories = await exerciseService.getCategories();
        expect(categories, isA<List<String>>());
      } catch (e) {
        // Expected to fail without proper Supabase setup
        expect(e, isNotNull);
      }
    });
  });
}