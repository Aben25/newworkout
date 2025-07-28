import 'package:logger/logger.dart';
import '../models/models.dart';
import 'exercise_service.dart';
import 'offline_cache_service.dart';

/// Service for advanced search functionality across exercises and workouts
class SearchService {
  static SearchService? _instance;
  static SearchService get instance => _instance ??= SearchService._();
  
  SearchService._();
  
  final Logger _logger = Logger();
  final ExerciseService _exerciseService = ExerciseService.instance;
  final OfflineCacheService _cacheService = OfflineCacheService.instance;

  // Search history and suggestions
  final List<String> _recentSearches = [];
  final Map<String, List<String>> _searchSuggestions = {};
  static const int _maxRecentSearches = 10;

  /// Perform comprehensive exercise search with advanced filtering
  Future<SearchResults<Exercise>> searchExercises({
    required String query,
    List<String>? muscleGroups,
    List<String>? equipmentTypes,
    List<String>? categories,
    String? difficulty,
    bool? hasVideo,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final startTime = DateTime.now();
      
      // Add to recent searches if not empty
      if (query.trim().isNotEmpty) {
        _addToRecentSearches(query.trim());
      }

      List<Exercise> results;
      bool isFromCache = false;

      try {
        // Try database search first
        results = await _exerciseService.searchExercises(
          query,
          muscleGroups: muscleGroups,
          equipmentTypes: equipmentTypes,
          categories: categories,
          limit: limit + offset, // Get more for offset handling
        );
      } catch (e) {
        // Fallback to cached search
        _logger.w('Database search failed, using cached data: $e');
        results = await _searchCachedExercises(
          query: query,
          muscleGroups: muscleGroups,
          equipmentTypes: equipmentTypes,
          categories: categories,
          difficulty: difficulty,
          hasVideo: hasVideo,
        );
        isFromCache = true;
      }

      // Apply additional filters not handled by database
      results = _applyAdditionalFilters(
        results,
        difficulty: difficulty,
        hasVideo: hasVideo,
      );

      // Apply pagination
      final totalResults = results.length;
      if (offset > 0) {
        results = results.skip(offset).toList();
      }
      if (results.length > limit) {
        results = results.take(limit).toList();
      }

      // Calculate search metrics
      final searchTime = DateTime.now().difference(startTime);
      
      // Generate search suggestions for future use
      if (query.trim().isNotEmpty && results.isNotEmpty) {
        _generateSearchSuggestions(query, results);
      }

      final searchResults = SearchResults<Exercise>(
        query: query,
        results: results,
        totalCount: totalResults,
        limit: limit,
        offset: offset,
        searchTime: searchTime,
        isFromCache: isFromCache,
        appliedFilters: SearchFilters(
          muscleGroups: muscleGroups,
          equipmentTypes: equipmentTypes,
          categories: categories,
          difficulty: difficulty,
          hasVideo: hasVideo,
        ),
      );

      _logger.i(
        'Search completed: "$query" - ${results.length}/$totalResults results in ${searchTime.inMilliseconds}ms'
      );

      return searchResults;
      
    } catch (e, stackTrace) {
      _logger.e(
        'Search failed for query: "$query"',
        error: e,
        stackTrace: stackTrace,
      );
      
      return SearchResults<Exercise>(
        query: query,
        results: [],
        totalCount: 0,
        limit: limit,
        offset: offset,
        searchTime: Duration.zero,
        isFromCache: false,
        error: e.toString(),
      );
    }
  }

  /// Get search suggestions based on query
  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      if (query.trim().isEmpty) {
        return _recentSearches.reversed.toList();
      }

      final suggestions = <String>[];
      final queryLower = query.toLowerCase();

      // Add matching recent searches
      final matchingRecent = _recentSearches
          .where((search) => search.toLowerCase().contains(queryLower))
          .toList();
      suggestions.addAll(matchingRecent);

      // Add cached suggestions
      final cachedSuggestions = _searchSuggestions[queryLower] ?? [];
      suggestions.addAll(cachedSuggestions);

      // Add exercise name suggestions
      final exercises = await _exerciseService.getExercises(limit: 100);
      final exerciseNameSuggestions = exercises
          .where((exercise) => exercise.name.toLowerCase().contains(queryLower))
          .map((exercise) => exercise.name)
          .take(5)
          .toList();
      suggestions.addAll(exerciseNameSuggestions);

      // Add muscle group suggestions
      final muscleGroups = await _exerciseService.getMuscleGroups();
      final muscleGroupSuggestions = muscleGroups
          .where((muscle) => muscle.toLowerCase().contains(queryLower))
          .take(3)
          .toList();
      suggestions.addAll(muscleGroupSuggestions);

      // Remove duplicates and limit results
      final uniqueSuggestions = suggestions.toSet().toList();
      return uniqueSuggestions.take(10).toList();
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to get search suggestions for: "$query"',
        error: e,
        stackTrace: stackTrace,
      );
      return _recentSearches.reversed.take(5).toList();
    }
  }

  /// Get popular search terms
  List<String> getPopularSearches() {
    // This could be enhanced with analytics data
    return [
      'chest',
      'legs',
      'back',
      'shoulders',
      'arms',
      'core',
      'cardio',
      'bodyweight',
      'dumbbells',
      'beginner',
    ];
  }

  /// Get recent searches
  List<String> getRecentSearches() {
    return _recentSearches.reversed.toList();
  }

  /// Clear recent searches
  void clearRecentSearches() {
    _recentSearches.clear();
    _logger.d('Cleared recent searches');
  }

  /// Advanced search with natural language processing
  Future<SearchResults<Exercise>> naturalLanguageSearch(String query) async {
    try {
      // Parse natural language query
      final parsedQuery = _parseNaturalLanguageQuery(query);
      
      return await searchExercises(
        query: parsedQuery.searchTerm,
        muscleGroups: parsedQuery.muscleGroups,
        equipmentTypes: parsedQuery.equipmentTypes,
        categories: parsedQuery.categories,
        difficulty: parsedQuery.difficulty,
        hasVideo: parsedQuery.hasVideo,
      );
      
    } catch (e, stackTrace) {
      _logger.e(
        'Natural language search failed for: "$query"',
        error: e,
        stackTrace: stackTrace,
      );
      
      // Fallback to regular search
      return await searchExercises(query: query);
    }
  }

  /// Search exercises by muscle group with smart matching
  Future<List<Exercise>> searchByMuscleGroup(
    String muscleGroup, {
    int limit = 20,
  }) async {
    try {
      // Get exercises for the specific muscle group
      var exercises = await _exerciseService.getExercises(
        muscleGroup: muscleGroup,
        limit: limit * 2, // Get more for variety
      );

      // If not enough results, try related muscle groups
      if (exercises.length < limit) {
        final relatedMuscleGroups = _getRelatedMuscleGroups(muscleGroup);
        
        for (final relatedMuscle in relatedMuscleGroups) {
          if (exercises.length >= limit) break;
          
          final additionalExercises = await _exerciseService.getExercises(
            muscleGroup: relatedMuscle,
            limit: limit - exercises.length,
          );
          
          // Add exercises not already in the list
          for (final exercise in additionalExercises) {
            if (!exercises.any((e) => e.id == exercise.id)) {
              exercises.add(exercise);
            }
          }
        }
      }

      // Shuffle for variety and limit results
      exercises.shuffle();
      return exercises.take(limit).toList();
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to search by muscle group: $muscleGroup',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Get search analytics and insights
  SearchAnalytics getSearchAnalytics() {
    final totalSearches = _recentSearches.length;
    final uniqueSearches = _recentSearches.toSet().length;
    
    // Calculate most common search terms
    final searchFrequency = <String, int>{};
    for (final search in _recentSearches) {
      searchFrequency[search] = (searchFrequency[search] ?? 0) + 1;
    }
    
    final mostCommonSearches = searchFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SearchAnalytics(
      totalSearches: totalSearches,
      uniqueSearches: uniqueSearches,
      mostCommonSearches: mostCommonSearches.take(5).toList(),
      recentSearches: _recentSearches.reversed.take(10).toList(),
    );
  }

  // Private helper methods

  Future<List<Exercise>> _searchCachedExercises({
    required String query,
    List<String>? muscleGroups,
    List<String>? equipmentTypes,
    List<String>? categories,
    String? difficulty,
    bool? hasVideo,
  }) async {
    try {
      var cachedExercises = _cacheService.getCachedExercises();
      
      // Apply text search
      if (query.trim().isNotEmpty) {
        cachedExercises = cachedExercises
            .where((exercise) => exercise.matchesSearch(query))
            .toList();
      }

      // Apply muscle group filter
      if (muscleGroups != null && muscleGroups.isNotEmpty) {
        cachedExercises = cachedExercises
            .where((exercise) => muscleGroups.any((muscle) => 
                exercise.muscleGroups.contains(muscle)))
            .toList();
      }

      // Apply equipment filter
      if (equipmentTypes != null && equipmentTypes.isNotEmpty) {
        cachedExercises = cachedExercises
            .where((exercise) => equipmentTypes.contains(exercise.equipment))
            .toList();
      }

      // Apply category filter
      if (categories != null && categories.isNotEmpty) {
        cachedExercises = cachedExercises
            .where((exercise) => categories.contains(exercise.category))
            .toList();
      }

      return cachedExercises;
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to search cached exercises',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  List<Exercise> _applyAdditionalFilters(
    List<Exercise> exercises, {
    String? difficulty,
    bool? hasVideo,
  }) {
    var filtered = exercises;

    // Apply difficulty filter
    if (difficulty != null) {
      filtered = filtered.where((exercise) {
        return _matchesDifficulty(exercise, difficulty);
      }).toList();
    }

    // Apply video filter
    if (hasVideo != null) {
      filtered = filtered.where((exercise) {
        return exercise.hasVideo == hasVideo;
      }).toList();
    }

    return filtered;
  }

  bool _matchesDifficulty(Exercise exercise, String difficulty) {
    // Simplified difficulty matching based on equipment and category
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return exercise.equipment == 'bodyweight' || 
               exercise.equipment == 'none' ||
               exercise.category?.toLowerCase().contains('basic') == true;
      case 'intermediate':
        return exercise.category?.toLowerCase().contains('advanced') != true;
      case 'advanced':
        return exercise.category?.toLowerCase().contains('advanced') == true ||
               exercise.equipment == 'barbell' ||
               exercise.equipment == 'cable machine';
      default:
        return true;
    }
  }

  void _addToRecentSearches(String query) {
    // Remove if already exists
    _recentSearches.remove(query);
    
    // Add to beginning
    _recentSearches.insert(0, query);
    
    // Limit size
    if (_recentSearches.length > _maxRecentSearches) {
      _recentSearches.removeLast();
    }
  }

  void _generateSearchSuggestions(String query, List<Exercise> results) {
    final queryLower = query.toLowerCase();
    final suggestions = <String>{};

    // Add exercise names from results
    for (final exercise in results.take(5)) {
      suggestions.add(exercise.name);
      
      // Add muscle groups
      suggestions.addAll(exercise.muscleGroups);
      
      // Add equipment
      if (exercise.equipment != null) {
        suggestions.add(exercise.equipment!);
      }
    }

    _searchSuggestions[queryLower] = suggestions.toList();
  }

  ParsedQuery _parseNaturalLanguageQuery(String query) {
    final queryLower = query.toLowerCase();
    
    // Extract muscle groups
    final muscleGroups = <String>[];
    final muscleKeywords = {
      'chest': ['chest', 'pecs', 'pectoral'],
      'back': ['back', 'lats', 'latissimus', 'rhomboids'],
      'shoulders': ['shoulders', 'delts', 'deltoids'],
      'arms': ['arms', 'biceps', 'triceps'],
      'legs': ['legs', 'quads', 'hamstrings', 'calves', 'glutes'],
      'core': ['core', 'abs', 'abdominals'],
    };

    for (final entry in muscleKeywords.entries) {
      if (entry.value.any((keyword) => queryLower.contains(keyword))) {
        muscleGroups.add(entry.key);
      }
    }

    // Extract equipment
    final equipmentTypes = <String>[];
    final equipmentKeywords = {
      'dumbbells': ['dumbbells', 'dumbbell', 'weights'],
      'barbell': ['barbell', 'bar'],
      'bodyweight': ['bodyweight', 'no equipment', 'home'],
      'resistance bands': ['bands', 'resistance bands'],
    };

    for (final entry in equipmentKeywords.entries) {
      if (entry.value.any((keyword) => queryLower.contains(keyword))) {
        equipmentTypes.add(entry.key);
      }
    }

    // Extract difficulty
    String? difficulty;
    if (queryLower.contains('beginner') || queryLower.contains('easy')) {
      difficulty = 'beginner';
    } else if (queryLower.contains('advanced') || queryLower.contains('hard')) {
      difficulty = 'advanced';
    } else if (queryLower.contains('intermediate')) {
      difficulty = 'intermediate';
    }

    // Extract video preference
    bool? hasVideo;
    if (queryLower.contains('video') || queryLower.contains('demonstration')) {
      hasVideo = true;
    }

    // Clean search term (remove parsed keywords)
    var searchTerm = query;
    final allKeywords = [
      ...muscleKeywords.values.expand((list) => list),
      ...equipmentKeywords.values.expand((list) => list),
      'beginner', 'intermediate', 'advanced', 'easy', 'hard',
      'video', 'demonstration',
    ];

    for (final keyword in allKeywords) {
      searchTerm = searchTerm.replaceAll(RegExp(keyword, caseSensitive: false), '');
    }
    
    searchTerm = searchTerm.trim().replaceAll(RegExp(r'\s+'), ' ');

    return ParsedQuery(
      searchTerm: searchTerm,
      muscleGroups: muscleGroups.isEmpty ? null : muscleGroups,
      equipmentTypes: equipmentTypes.isEmpty ? null : equipmentTypes,
      difficulty: difficulty,
      hasVideo: hasVideo,
    );
  }

  List<String> _getRelatedMuscleGroups(String muscleGroup) {
    final relatedGroups = <String, List<String>>{
      'chest': ['shoulders', 'arms'],
      'back': ['shoulders', 'arms'],
      'shoulders': ['chest', 'back', 'arms'],
      'arms': ['chest', 'back', 'shoulders'],
      'legs': ['glutes', 'core'],
      'core': ['back'],
    };

    return relatedGroups[muscleGroup.toLowerCase()] ?? [];
  }
}

/// Search results container
class SearchResults<T> {
  final String query;
  final List<T> results;
  final int totalCount;
  final int limit;
  final int offset;
  final Duration searchTime;
  final bool isFromCache;
  final SearchFilters? appliedFilters;
  final String? error;

  SearchResults({
    required this.query,
    required this.results,
    required this.totalCount,
    required this.limit,
    required this.offset,
    required this.searchTime,
    required this.isFromCache,
    this.appliedFilters,
    this.error,
  });

  bool get hasResults => results.isNotEmpty;
  bool get hasError => error != null;
  bool get hasMoreResults => totalCount > (offset + results.length);
  int get currentPage => (offset / limit).floor() + 1;
  int get totalPages => (totalCount / limit).ceil();
}

/// Search filters applied to results
class SearchFilters {
  final List<String>? muscleGroups;
  final List<String>? equipmentTypes;
  final List<String>? categories;
  final String? difficulty;
  final bool? hasVideo;

  SearchFilters({
    this.muscleGroups,
    this.equipmentTypes,
    this.categories,
    this.difficulty,
    this.hasVideo,
  });

  bool get hasFilters => 
      muscleGroups != null ||
      equipmentTypes != null ||
      categories != null ||
      difficulty != null ||
      hasVideo != null;

  int get activeFilterCount {
    int count = 0;
    if (muscleGroups != null && muscleGroups!.isNotEmpty) count++;
    if (equipmentTypes != null && equipmentTypes!.isNotEmpty) count++;
    if (categories != null && categories!.isNotEmpty) count++;
    if (difficulty != null) count++;
    if (hasVideo != null) count++;
    return count;
  }
}

/// Parsed natural language query
class ParsedQuery {
  final String searchTerm;
  final List<String>? muscleGroups;
  final List<String>? equipmentTypes;
  final List<String>? categories;
  final String? difficulty;
  final bool? hasVideo;

  ParsedQuery({
    required this.searchTerm,
    this.muscleGroups,
    this.equipmentTypes,
    this.categories,
    this.difficulty,
    this.hasVideo,
  });
}

/// Search analytics data
class SearchAnalytics {
  final int totalSearches;
  final int uniqueSearches;
  final List<MapEntry<String, int>> mostCommonSearches;
  final List<String> recentSearches;

  SearchAnalytics({
    required this.totalSearches,
    required this.uniqueSearches,
    required this.mostCommonSearches,
    required this.recentSearches,
  });

  double get searchVariety => 
      totalSearches > 0 ? uniqueSearches / totalSearches : 0.0;
}