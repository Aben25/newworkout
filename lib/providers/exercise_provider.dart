import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../models/models.dart';
import '../services/services.dart';

final logger = Logger();

// Exercise Service Provider
final exerciseServiceProvider = Provider<ExerciseService>((ref) {
  return ExerciseService.instance;
});

// Search Service Provider
final searchServiceProvider = Provider<SearchService>((ref) {
  return SearchService.instance;
});

// Recommendation Service Provider
final recommendationServiceProvider = Provider<RecommendationService>((ref) {
  return RecommendationService.instance;
});

// Workout Service Provider
final workoutServiceProvider = Provider<WorkoutService>((ref) {
  return WorkoutService.instance;
});

// Supabase Service Provider
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService.instance;
});



// All Exercises Provider
final allExercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  final exerciseService = ref.read(exerciseServiceProvider);
  try {
    return await exerciseService.getExercises();
  } catch (e, stackTrace) {
    logger.e('Failed to load all exercises', error: e, stackTrace: stackTrace);
    rethrow;
  }
});

// Alias for backward compatibility
final exercisesProvider = allExercisesProvider;

// Exercise by ID Provider
final exerciseByIdProvider = FutureProvider.family<Exercise?, String>((ref, exerciseId) async {
  final exerciseService = ref.read(exerciseServiceProvider);
  try {
    return await exerciseService.getExerciseById(exerciseId);
  } catch (e, stackTrace) {
    logger.e('Failed to load exercise: $exerciseId', error: e, stackTrace: stackTrace);
    return null;
  }
});

// Exercises by IDs Provider
final exercisesByIdsProvider = FutureProvider.family<List<Exercise>, List<String>>((ref, exerciseIds) async {
  final exerciseService = ref.read(exerciseServiceProvider);
  try {
    return await exerciseService.getExercisesByIds(exerciseIds);
  } catch (e, stackTrace) {
    logger.e('Failed to load exercises by IDs', error: e, stackTrace: stackTrace);
    return [];
  }
});

// Muscle Groups Provider
final muscleGroupsProvider = FutureProvider<List<String>>((ref) async {
  final exerciseService = ref.read(exerciseServiceProvider);
  try {
    return await exerciseService.getMuscleGroups();
  } catch (e, stackTrace) {
    logger.e('Failed to load muscle groups', error: e, stackTrace: stackTrace);
    return [];
  }
});

// Equipment Types Provider
final equipmentTypesProvider = FutureProvider<List<String>>((ref) async {
  final exerciseService = ref.read(exerciseServiceProvider);
  try {
    return await exerciseService.getEquipmentTypes();
  } catch (e, stackTrace) {
    logger.e('Failed to load equipment types', error: e, stackTrace: stackTrace);
    return [];
  }
});

// Exercise Categories Provider
final exerciseCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final exerciseService = ref.read(exerciseServiceProvider);
  try {
    return await exerciseService.getCategories();
  } catch (e, stackTrace) {
    logger.e('Failed to load exercise categories', error: e, stackTrace: stackTrace);
    return [];
  }
});

// Filtered Exercises Provider
final filteredExercisesProvider = FutureProvider.family<List<Exercise>, ExerciseFilters>((ref, filters) async {
  final exerciseService = ref.read(exerciseServiceProvider);
  try {
    return await exerciseService.getExercises(
      muscleGroup: filters.muscleGroup,
      equipment: filters.equipment,
      category: filters.category,
      searchQuery: filters.searchQuery,
      limit: filters.limit,
      offset: filters.offset,
    );
  } catch (e, stackTrace) {
    logger.e('Failed to load filtered exercises', error: e, stackTrace: stackTrace);
    return [];
  }
});

// Exercise Search Provider
final exerciseSearchProvider = FutureProvider.family<SearchResults<Exercise>, SearchQuery>((ref, searchQuery) async {
  final searchService = ref.read(searchServiceProvider);
  try {
    return await searchService.searchExercises(
      query: searchQuery.query,
      muscleGroups: searchQuery.muscleGroups,
      equipmentTypes: searchQuery.equipmentTypes,
      categories: searchQuery.categories,
      difficulty: searchQuery.difficulty,
      hasVideo: searchQuery.hasVideo,
      limit: searchQuery.limit,
      offset: searchQuery.offset,
    );
  } catch (e, stackTrace) {
    logger.e('Failed to search exercises', error: e, stackTrace: stackTrace);
    return SearchResults<Exercise>(
      query: searchQuery.query,
      results: [],
      totalCount: 0,
      limit: searchQuery.limit,
      offset: searchQuery.offset,
      searchTime: Duration.zero,
      isFromCache: false,
      error: e.toString(),
    );
  }
});

// Search Suggestions Provider
final searchSuggestionsProvider = FutureProvider.family<List<String>, String>((ref, query) async {
  final searchService = ref.read(searchServiceProvider);
  try {
    return await searchService.getSearchSuggestions(query);
  } catch (e, stackTrace) {
    logger.e('Failed to get search suggestions', error: e, stackTrace: stackTrace);
    return [];
  }
});

// Personalized Exercise Recommendations Provider
final personalizedExerciseRecommendationsProvider = FutureProvider.family<List<Exercise>, RecommendationFilters>((ref, filters) async {
  final recommendationService = ref.read(recommendationServiceProvider);
  try {
    return await recommendationService.getPersonalizedExerciseRecommendations(
      limit: filters.limit,
      excludeExerciseIds: filters.excludeExerciseIds,
      focusMuscleGroup: filters.focusMuscleGroup,
    );
  } catch (e, stackTrace) {
    logger.e('Failed to get personalized exercise recommendations', error: e, stackTrace: stackTrace);
    return [];
  }
});

// Workout Recommendations Provider
final workoutRecommendationsProvider = FutureProvider.family<List<WorkoutRecommendation>, int>((ref, limit) async {
  final recommendationService = ref.read(recommendationServiceProvider);
  try {
    return await recommendationService.getWorkoutRecommendations(limit: limit);
  } catch (e, stackTrace) {
    logger.e('Failed to get workout recommendations', error: e, stackTrace: stackTrace);
    return [];
  }
});

// Exercise Alternatives Provider
final exerciseAlternativesProvider = FutureProvider.family<List<Exercise>, String>((ref, exerciseId) async {
  final recommendationService = ref.read(recommendationServiceProvider);
  try {
    return await recommendationService.getExerciseAlternatives(exerciseId);
  } catch (e, stackTrace) {
    logger.e('Failed to get exercise alternatives', error: e, stackTrace: stackTrace);
    return [];
  }
});

// Exercise Progression Provider
final exerciseProgressionProvider = FutureProvider.family<ExerciseProgression, String>((ref, exerciseId) async {
  final recommendationService = ref.read(recommendationServiceProvider);
  try {
    return await recommendationService.getExerciseProgression(exerciseId);
  } catch (e, stackTrace) {
    logger.e('Failed to get exercise progression', error: e, stackTrace: stackTrace);
    return ExerciseProgression(current: null, easier: [], harder: []);
  }
});

// History-based Recommendations Provider
final historyBasedRecommendationsProvider = FutureProvider.family<List<Exercise>, int>((ref, limit) async {
  final recommendationService = ref.read(recommendationServiceProvider);
  try {
    return await recommendationService.getHistoryBasedRecommendations(limit: limit);
  } catch (e, stackTrace) {
    logger.e('Failed to get history-based recommendations', error: e, stackTrace: stackTrace);
    return [];
  }
});

// Recent Searches Provider
final recentSearchesProvider = Provider<List<String>>((ref) {
  final searchService = ref.read(searchServiceProvider);
  return searchService.getRecentSearches();
});

// Popular Searches Provider
final popularSearchesProvider = Provider<List<String>>((ref) {
  final searchService = ref.read(searchServiceProvider);
  return searchService.getPopularSearches();
});

// Search Analytics Provider
final searchAnalyticsProvider = Provider<SearchAnalytics>((ref) {
  final searchService = ref.read(searchServiceProvider);
  return searchService.getSearchAnalytics();
});

// State Notifier for Exercise Search
class ExerciseSearchNotifier extends StateNotifier<AsyncValue<SearchResults<Exercise>>> {
  ExerciseSearchNotifier(this._searchService) : super(const AsyncValue.loading());

  final SearchService _searchService;
  String _currentQuery = '';
  SearchFilters? _currentFilters;

  String get currentQuery => _currentQuery;
  SearchFilters? get currentFilters => _currentFilters;

  Future<void> search({
    required String query,
    List<String>? muscleGroups,
    List<String>? equipmentTypes,
    List<String>? categories,
    String? difficulty,
    bool? hasVideo,
    int limit = 50,
    int offset = 0,
  }) async {
    if (query == _currentQuery && offset == 0) {
      // Same query, don't reload unless it's a new search
      return;
    }

    _currentQuery = query;
    _currentFilters = SearchFilters(
      muscleGroups: muscleGroups,
      equipmentTypes: equipmentTypes,
      categories: categories,
      difficulty: difficulty,
      hasVideo: hasVideo,
    );

    state = const AsyncValue.loading();

    try {
      final results = await _searchService.searchExercises(
        query: query,
        muscleGroups: muscleGroups,
        equipmentTypes: equipmentTypes,
        categories: categories,
        difficulty: difficulty,
        hasVideo: hasVideo,
        limit: limit,
        offset: offset,
      );

      state = AsyncValue.data(results);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! AsyncData<SearchResults<Exercise>>) return;

    final currentResults = currentState.value;
    if (!currentResults.hasMoreResults) return;

    try {
      final newResults = await _searchService.searchExercises(
        query: _currentQuery,
        muscleGroups: _currentFilters?.muscleGroups,
        equipmentTypes: _currentFilters?.equipmentTypes,
        categories: _currentFilters?.categories,
        difficulty: _currentFilters?.difficulty,
        hasVideo: _currentFilters?.hasVideo,
        limit: currentResults.limit,
        offset: currentResults.offset + currentResults.results.length,
      );

      // Merge results
      final mergedResults = SearchResults<Exercise>(
        query: currentResults.query,
        results: [...currentResults.results, ...newResults.results],
        totalCount: newResults.totalCount,
        limit: currentResults.limit,
        offset: currentResults.offset,
        searchTime: newResults.searchTime,
        isFromCache: newResults.isFromCache,
        appliedFilters: currentResults.appliedFilters,
      );

      state = AsyncValue.data(mergedResults);
    } catch (e, stackTrace) {
      // Keep current state but log error
      logger.e('Failed to load more search results', error: e, stackTrace: stackTrace);
    }
  }

  void clearSearch() {
    _currentQuery = '';
    _currentFilters = null;
    state = const AsyncValue.loading();
  }
}

// Exercise Search State Provider
final exerciseSearchNotifierProvider = StateNotifierProvider<ExerciseSearchNotifier, AsyncValue<SearchResults<Exercise>>>((ref) {
  final searchService = ref.read(searchServiceProvider);
  return ExerciseSearchNotifier(searchService);
});

// Helper classes for provider parameters
class ExerciseFilters {
  final String? muscleGroup;
  final String? equipment;
  final String? category;
  final String? searchQuery;
  final int? limit;
  final int? offset;

  const ExerciseFilters({
    this.muscleGroup,
    this.equipment,
    this.category,
    this.searchQuery,
    this.limit,
    this.offset,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseFilters &&
          runtimeType == other.runtimeType &&
          muscleGroup == other.muscleGroup &&
          equipment == other.equipment &&
          category == other.category &&
          searchQuery == other.searchQuery &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode =>
      muscleGroup.hashCode ^
      equipment.hashCode ^
      category.hashCode ^
      searchQuery.hashCode ^
      limit.hashCode ^
      offset.hashCode;
}

class SearchQuery {
  final String query;
  final List<String>? muscleGroups;
  final List<String>? equipmentTypes;
  final List<String>? categories;
  final String? difficulty;
  final bool? hasVideo;
  final int limit;
  final int offset;

  const SearchQuery({
    required this.query,
    this.muscleGroups,
    this.equipmentTypes,
    this.categories,
    this.difficulty,
    this.hasVideo,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchQuery &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          _listEquals(muscleGroups, other.muscleGroups) &&
          _listEquals(equipmentTypes, other.equipmentTypes) &&
          _listEquals(categories, other.categories) &&
          difficulty == other.difficulty &&
          hasVideo == other.hasVideo &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode =>
      query.hashCode ^
      Object.hashAll(muscleGroups ?? []) ^
      Object.hashAll(equipmentTypes ?? []) ^
      Object.hashAll(categories ?? []) ^
      difficulty.hashCode ^
      hasVideo.hashCode ^
      limit.hashCode ^
      offset.hashCode;

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}

class RecommendationFilters {
  final int limit;
  final List<String>? excludeExerciseIds;
  final String? focusMuscleGroup;

  const RecommendationFilters({
    this.limit = 20,
    this.excludeExerciseIds,
    this.focusMuscleGroup,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecommendationFilters &&
          runtimeType == other.runtimeType &&
          limit == other.limit &&
          _listEquals(excludeExerciseIds, other.excludeExerciseIds) &&
          focusMuscleGroup == other.focusMuscleGroup;

  @override
  int get hashCode =>
      limit.hashCode ^
      Object.hashAll(excludeExerciseIds ?? []) ^
      focusMuscleGroup.hashCode;

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}