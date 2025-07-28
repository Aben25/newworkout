import 'package:logger/logger.dart';
import '../models/models.dart';
import '../constants/app_constants.dart';
import 'supabase_service.dart';
import 'offline_cache_service.dart';

class ExerciseService {
  static ExerciseService? _instance;
  static ExerciseService get instance => _instance ??= ExerciseService._();
  
  ExerciseService._();
  
  final Logger _logger = Logger();
  final SupabaseService _supabaseService = SupabaseService.instance;
  final OfflineCacheService _cacheService = OfflineCacheService.instance;
  
  // Cache for exercises to avoid repeated API calls
  List<Exercise>? _exerciseCache;
  DateTime? _lastCacheUpdate;
  static const Duration _cacheExpiry = Duration(hours: 24);

  /// Get all exercises with optional filtering
  Future<List<Exercise>> getExercises({
    String? muscleGroup,
    String? equipment,
    String? category,
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    try {
      // Check if we can use cached data
      if (_canUseCachedData() && _exerciseCache != null) {
        return _filterExercises(
          _exerciseCache!,
          muscleGroup: muscleGroup,
          equipment: equipment,
          category: category,
          searchQuery: searchQuery,
          limit: limit,
          offset: offset,
        );
      }

      // Build query with filters
      dynamic queryBuilder = _supabaseService.client
          .from(AppConstants.exercisesTable)
          .select();

      // Apply filters
      if (muscleGroup != null) {
        queryBuilder = queryBuilder.or('primary_muscle.eq.$muscleGroup,secondary_muscle.eq.$muscleGroup');
      }
      
      if (equipment != null) {
        queryBuilder = queryBuilder.eq('equipment', equipment);
      }
      
      if (category != null) {
        queryBuilder = queryBuilder.eq('category', category);
      }

      // Apply search query using full-text search
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchTerm = searchQuery.toLowerCase();
        queryBuilder = queryBuilder.or(
          'name.ilike.%$searchTerm%,'
          'description.ilike.%$searchTerm%,'
          'instructions.ilike.%$searchTerm%,'
          'primary_muscle.ilike.%$searchTerm%,'
          'secondary_muscle.ilike.%$searchTerm%'
        );
      }

      // Apply pagination
      if (limit != null) {
        queryBuilder = queryBuilder.limit(limit);
      }
      
      if (offset != null) {
        queryBuilder = queryBuilder.range(offset, offset + (limit ?? AppConstants.defaultPageSize) - 1);
      }

      // Order by name for consistent results and execute
      final response = await queryBuilder.order('name');
      final exercises = (response as List)
          .map((json) => Exercise.fromJson(json))
          .toList();

      // Update cache if this was a full fetch (no filters)
      if (muscleGroup == null && equipment == null && category == null && 
          searchQuery == null && limit == null && offset == null) {
        _exerciseCache = exercises;
        _lastCacheUpdate = DateTime.now();
        
        // Cache offline for better performance
        await _cacheExercisesOffline(exercises);
      }

      _logger.i('Fetched ${exercises.length} exercises from database');
      return exercises;
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to fetch exercises from database',
        error: e,
        stackTrace: stackTrace,
      );
      
      // Try to get from offline cache as fallback
      final cachedExercises = _getCachedExercisesOffline();
      if (cachedExercises.isNotEmpty) {
        _logger.i('Using ${cachedExercises.length} cached exercises as fallback');
        return _filterExercises(
          cachedExercises,
          muscleGroup: muscleGroup,
          equipment: equipment,
          category: category,
          searchQuery: searchQuery,
          limit: limit,
          offset: offset,
        );
      }
      
      rethrow;
    }
  }

  /// Get a specific exercise by ID
  Future<Exercise?> getExerciseById(String exerciseId) async {
    try {
      // Check cache first
      if (_exerciseCache != null) {
        final cachedExercise = _exerciseCache!
            .where((exercise) => exercise.id == exerciseId)
            .firstOrNull;
        if (cachedExercise != null) {
          return cachedExercise;
        }
      }

      final response = await _supabaseService.client
          .from(AppConstants.exercisesTable)
          .select()
          .eq('id', exerciseId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return Exercise.fromJson(response);
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to fetch exercise by ID: $exerciseId',
        error: e,
        stackTrace: stackTrace,
      );
      
      // Try offline cache
      final cachedExercises = _getCachedExercisesOffline();
      return cachedExercises
          .where((exercise) => exercise.id == exerciseId)
          .firstOrNull;
    }
  }

  /// Get exercises by multiple IDs
  Future<List<Exercise>> getExercisesByIds(List<String> exerciseIds) async {
    try {
      if (exerciseIds.isEmpty) return [];

      // Check cache first
      if (_exerciseCache != null) {
        final cachedExercises = _exerciseCache!
            .where((exercise) => exerciseIds.contains(exercise.id))
            .toList();
        if (cachedExercises.length == exerciseIds.length) {
          return cachedExercises;
        }
      }

      final response = await _supabaseService.client
          .from(AppConstants.exercisesTable)
          .select()
          .inFilter('id', exerciseIds);

      return (response as List)
          .map((json) => Exercise.fromJson(json))
          .toList();
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to fetch exercises by IDs',
        error: e,
        stackTrace: stackTrace,
      );
      
      // Try offline cache
      final cachedExercises = _getCachedExercisesOffline();
      return cachedExercises
          .where((exercise) => exerciseIds.contains(exercise.id))
          .toList();
    }
  }

  /// Search exercises with advanced full-text search
  Future<List<Exercise>> searchExercises(
    String query, {
    List<String>? muscleGroups,
    List<String>? equipmentTypes,
    List<String>? categories,
    int limit = 50,
  }) async {
    try {
      if (query.trim().isEmpty) {
        return getExercises(limit: limit);
      }

      var dbQuery = _supabaseService.client
          .from(AppConstants.exercisesTable)
          .select();

      // Full-text search across multiple fields
      final searchTerm = query.toLowerCase().trim();
      dbQuery = dbQuery.or(
        'name.ilike.%$searchTerm%,'
        'description.ilike.%$searchTerm%,'
        'instructions.ilike.%$searchTerm%,'
        'primary_muscle.ilike.%$searchTerm%,'
        'secondary_muscle.ilike.%$searchTerm%,'
        'equipment.ilike.%$searchTerm%,'
        'category.ilike.%$searchTerm%'
      );

      // Apply additional filters
      if (muscleGroups != null && muscleGroups.isNotEmpty) {
        final muscleFilter = muscleGroups
            .map((muscle) => 'primary_muscle.eq.$muscle,secondary_muscle.eq.$muscle')
            .join(',');
        dbQuery = dbQuery.or(muscleFilter);
      }

      if (equipmentTypes != null && equipmentTypes.isNotEmpty) {
        dbQuery = dbQuery.inFilter('equipment', equipmentTypes);
      }

      if (categories != null && categories.isNotEmpty) {
        dbQuery = dbQuery.inFilter('category', categories);
      }

      final response = await dbQuery.limit(limit).order('name');
      final exercises = (response as List)
          .map((json) => Exercise.fromJson(json))
          .toList();

      _logger.i('Found ${exercises.length} exercises matching search: "$query"');
      return exercises;
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to search exercises',
        error: e,
        stackTrace: stackTrace,
      );
      
      // Fallback to local search in cached data
      final cachedExercises = _getCachedExercisesOffline();
      return _searchInExercises(cachedExercises, query, limit: limit);
    }
  }

  /// Get recommended exercises based on user preferences
  Future<List<Exercise>> getRecommendedExercises({
    required List<String> userEquipment,
    List<String>? preferredMuscleGroups,
    List<String>? excludedExercises,
    String? fitnessLevel,
    int limit = 20,
  }) async {
    try {
      var query = _supabaseService.client
          .from(AppConstants.exercisesTable)
          .select();

      // Filter by available equipment
      if (userEquipment.isNotEmpty) {
        query = query.inFilter('equipment', [...userEquipment, 'bodyweight', 'none']);
      }

      // Exclude specific exercises
      if (excludedExercises != null && excludedExercises.isNotEmpty) {
        query = query.not('id', 'in', '(${excludedExercises.join(',')})');
      }

      // Prefer certain muscle groups if specified
      if (preferredMuscleGroups != null && preferredMuscleGroups.isNotEmpty) {
        final muscleFilter = preferredMuscleGroups
            .map((muscle) => 'primary_muscle.eq.$muscle,secondary_muscle.eq.$muscle')
            .join(',');
        query = query.or(muscleFilter);
      }

      final response = await query.limit(limit * 2); // Get more to allow for filtering
      var exercises = (response as List)
          .map((json) => Exercise.fromJson(json))
          .toList();

      // Apply fitness level filtering and scoring
      exercises = _scoreAndFilterByFitnessLevel(exercises, fitnessLevel);
      
      // Shuffle for variety and take the limit
      exercises.shuffle();
      exercises = exercises.take(limit).toList();

      _logger.i('Generated ${exercises.length} recommended exercises');
      return exercises;
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to get recommended exercises',
        error: e,
        stackTrace: stackTrace,
      );
      
      // Fallback to cached recommendations
      final cachedExercises = _getCachedExercisesOffline();
      return _getRecommendationsFromCache(
        cachedExercises,
        userEquipment,
        preferredMuscleGroups,
        excludedExercises,
        limit,
      );
    }
  }

  /// Get unique muscle groups from all exercises
  Future<List<String>> getMuscleGroups() async {
    try {
      final exercises = await getExercises();
      final muscleGroups = <String>{};
      
      for (final exercise in exercises) {
        if (exercise.primaryMuscle != null) {
          muscleGroups.add(exercise.primaryMuscle!);
        }
        if (exercise.secondaryMuscle != null) {
          muscleGroups.add(exercise.secondaryMuscle!);
        }
      }
      
      final sortedMuscleGroups = muscleGroups.toList()..sort();
      return sortedMuscleGroups;
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to get muscle groups',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Get unique equipment types from all exercises
  Future<List<String>> getEquipmentTypes() async {
    try {
      final exercises = await getExercises();
      final equipmentTypes = exercises
          .where((exercise) => exercise.equipment != null)
          .map((exercise) => exercise.equipment!)
          .toSet()
          .toList()
        ..sort();
      
      return equipmentTypes;
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to get equipment types',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Get unique categories from all exercises
  Future<List<String>> getCategories() async {
    try {
      final exercises = await getExercises();
      final categories = exercises
          .where((exercise) => exercise.category != null)
          .map((exercise) => exercise.category!)
          .toSet()
          .toList()
        ..sort();
      
      return categories;
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to get categories',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Preload and cache all exercises for offline use
  Future<void> preloadExercises() async {
    try {
      _logger.i('Starting exercise preload...');
      final exercises = await getExercises();
      await _cacheExercisesOffline(exercises);
      _logger.i('Successfully preloaded ${exercises.length} exercises');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to preload exercises',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Clear exercise cache
  void clearCache() {
    _exerciseCache = null;
    _lastCacheUpdate = null;
    _logger.i('Exercise cache cleared');
  }

  // Private helper methods

  bool _canUseCachedData() {
    return _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!) < _cacheExpiry;
  }

  List<Exercise> _filterExercises(
    List<Exercise> exercises, {
    String? muscleGroup,
    String? equipment,
    String? category,
    String? searchQuery,
    int? limit,
    int? offset,
  }) {
    var filtered = exercises.where((exercise) {
      // Muscle group filter
      if (muscleGroup != null) {
        if (exercise.primaryMuscle != muscleGroup && 
            exercise.secondaryMuscle != muscleGroup) {
          return false;
        }
      }
      
      // Equipment filter
      if (equipment != null && exercise.equipment != equipment) {
        return false;
      }
      
      // Category filter
      if (category != null && exercise.category != category) {
        return false;
      }
      
      // Search query filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        if (!exercise.matchesSearch(searchQuery)) {
          return false;
        }
      }
      
      return true;
    }).toList();

    // Apply pagination
    if (offset != null) {
      filtered = filtered.skip(offset).toList();
    }
    
    if (limit != null) {
      filtered = filtered.take(limit).toList();
    }

    return filtered;
  }

  List<Exercise> _searchInExercises(List<Exercise> exercises, String query, {int limit = 50}) {
    final results = exercises
        .where((exercise) => exercise.matchesSearch(query))
        .take(limit)
        .toList();
    
    // Sort by relevance (name matches first, then description, etc.)
    results.sort((a, b) {
      final queryLower = query.toLowerCase();
      final aNameMatch = a.name.toLowerCase().contains(queryLower);
      final bNameMatch = b.name.toLowerCase().contains(queryLower);
      
      if (aNameMatch && !bNameMatch) return -1;
      if (!aNameMatch && bNameMatch) return 1;
      
      return a.name.compareTo(b.name);
    });
    
    return results;
  }

  List<Exercise> _scoreAndFilterByFitnessLevel(List<Exercise> exercises, String? fitnessLevel) {
    if (fitnessLevel == null) return exercises;
    
    // Simple scoring based on fitness level
    // This could be enhanced with more sophisticated algorithms
    return exercises.where((exercise) {
      switch (fitnessLevel.toLowerCase()) {
        case 'beginner':
          // Prefer bodyweight and basic exercises
          return exercise.equipment == 'bodyweight' || 
                 exercise.equipment == 'none' ||
                 exercise.category?.toLowerCase().contains('basic') == true;
        case 'intermediate':
          // Allow most exercises except advanced ones
          return exercise.category?.toLowerCase().contains('advanced') != true;
        case 'advanced':
          // Allow all exercises
          return true;
        default:
          return true;
      }
    }).toList();
  }

  List<Exercise> _getRecommendationsFromCache(
    List<Exercise> cachedExercises,
    List<String> userEquipment,
    List<String>? preferredMuscleGroups,
    List<String>? excludedExercises,
    int limit,
  ) {
    var filtered = cachedExercises.where((exercise) {
      // Equipment filter
      if (userEquipment.isNotEmpty) {
        final hasEquipment = userEquipment.contains(exercise.equipment) ||
                           exercise.equipment == 'bodyweight' ||
                           exercise.equipment == 'none';
        if (!hasEquipment) return false;
      }
      
      // Exclude specific exercises
      if (excludedExercises != null && excludedExercises.contains(exercise.id)) {
        return false;
      }
      
      return true;
    }).toList();

    // Prefer certain muscle groups
    if (preferredMuscleGroups != null && preferredMuscleGroups.isNotEmpty) {
      filtered.sort((a, b) {
        final aPreferred = preferredMuscleGroups.contains(a.primaryMuscle) ||
                          preferredMuscleGroups.contains(a.secondaryMuscle);
        final bPreferred = preferredMuscleGroups.contains(b.primaryMuscle) ||
                          preferredMuscleGroups.contains(b.secondaryMuscle);
        
        if (aPreferred && !bPreferred) return -1;
        if (!aPreferred && bPreferred) return 1;
        return 0;
      });
    }

    filtered.shuffle();
    return filtered.take(limit).toList();
  }

  Future<void> _cacheExercisesOffline(List<Exercise> exercises) async {
    try {
      await _cacheService.cacheExercises(exercises);
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to cache exercises offline',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  List<Exercise> _getCachedExercisesOffline() {
    try {
      return _cacheService.getCachedExercises();
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to get cached exercises',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }
}