import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import '../models/exercise_favorite.dart';
import '../models/exercise_collection.dart';
import '../models/exercise.dart';
import 'supabase_service.dart';
import 'offline_cache_service.dart';
import 'auth_service.dart';
import 'exercise_service.dart';

class ExerciseFavoritesService {
  static ExerciseFavoritesService? _instance;
  static ExerciseFavoritesService get instance => _instance ??= ExerciseFavoritesService._();
  
  ExerciseFavoritesService._();
  
  final Logger _logger = Logger();
  final SupabaseService _supabaseService = SupabaseService.instance;
  final OfflineCacheService _cacheService = OfflineCacheService.instance;
  final AuthService _authService = AuthService.instance;
  final Uuid _uuid = const Uuid();

  // Local cache for favorites and collections
  List<ExerciseFavorite>? _favoritesCache;
  List<ExerciseCollection>? _collectionsCache;
  DateTime? _lastFavoritesUpdate;
  DateTime? _lastCollectionsUpdate;
  static const Duration _cacheExpiry = Duration(minutes: 30);

  /// Get all favorite exercises for the current user
  Future<List<ExerciseFavorite>> getFavorites() async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check cache first
      if (_canUseFavoritesCache()) {
        return _favoritesCache!;
      }

      // Try to fetch from database
      try {
        final response = await _supabaseService.client
            .from('exercise_favorites')
            .select()
            .eq('user_id', user.id)
            .order('created_at', ascending: false);

        final favorites = (response as List)
            .map((json) => ExerciseFavorite.fromJson(json))
            .toList();

        _favoritesCache = favorites;
        _lastFavoritesUpdate = DateTime.now();
        
        // Cache offline
        await _cacheFavoritesOffline(favorites);
        
        return favorites;
      } catch (e) {
        _logger.w('Failed to fetch favorites from database, using cache: $e');
        return _getCachedFavoritesOffline();
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to get favorites', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Check if an exercise is favorited
  Future<bool> isFavorite(String exerciseId) async {
    try {
      final favorites = await getFavorites();
      return favorites.any((fav) => fav.exerciseId == exerciseId);
    } catch (e) {
      _logger.e('Failed to check if exercise is favorite: $exerciseId', error: e);
      return false;
    }
  }

  /// Add an exercise to favorites
  Future<ExerciseFavorite?> addToFavorites(String exerciseId, {String? notes}) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if already favorited
      if (await isFavorite(exerciseId)) {
        _logger.i('Exercise already in favorites: $exerciseId');
        return null;
      }

      final favorite = ExerciseFavorite(
        id: _uuid.v4(),
        userId: user.id,
        exerciseId: exerciseId,
        createdAt: DateTime.now(),
        notes: notes,
      );

      try {
        // Try to save to database
        await _supabaseService.client
            .from('exercise_favorites')
            .insert(favorite.toJson());

        // Update local cache
        _favoritesCache?.insert(0, favorite);
        
        _logger.i('Added exercise to favorites: $exerciseId');
        return favorite;
      } catch (e) {
        _logger.w('Failed to save favorite to database, caching locally: $e');
        
        // Cache locally for later sync
        await _cacheService.addPendingFavorite(favorite);
        
        // Update local cache
        _favoritesCache?.insert(0, favorite);
        
        return favorite;
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to add to favorites: $exerciseId', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Remove an exercise from favorites
  Future<bool> removeFromFavorites(String exerciseId) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final favorites = await getFavorites();
      final favorite = favorites.where((fav) => fav.exerciseId == exerciseId).firstOrNull;
      
      if (favorite == null) {
        _logger.i('Exercise not in favorites: $exerciseId');
        return false;
      }

      try {
        // Try to remove from database
        await _supabaseService.client
            .from('exercise_favorites')
            .delete()
            .eq('id', favorite.id);

        // Update local cache
        _favoritesCache?.removeWhere((fav) => fav.exerciseId == exerciseId);
        
        _logger.i('Removed exercise from favorites: $exerciseId');
        return true;
      } catch (e) {
        _logger.w('Failed to remove favorite from database, caching removal: $e');
        
        // Cache removal for later sync
        await _cacheService.addPendingFavoriteRemoval(favorite.id);
        
        // Update local cache
        _favoritesCache?.removeWhere((fav) => fav.exerciseId == exerciseId);
        
        return true;
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to remove from favorites: $exerciseId', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get all exercise collections for the current user
  Future<List<ExerciseCollection>> getCollections() async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check cache first
      if (_canUseCollectionsCache()) {
        return _collectionsCache!;
      }

      // Try to fetch from database
      try {
        final response = await _supabaseService.client
            .from('exercise_collections')
            .select()
            .eq('user_id', user.id)
            .order('updated_at', ascending: false);

        final collections = (response as List)
            .map((json) => ExerciseCollection.fromJson(json))
            .toList();

        _collectionsCache = collections;
        _lastCollectionsUpdate = DateTime.now();
        
        // Cache offline
        await _cacheCollectionsOffline(collections);
        
        return collections;
      } catch (e) {
        _logger.w('Failed to fetch collections from database, using cache: $e');
        return _getCachedCollectionsOffline();
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to get collections', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Create a new exercise collection
  Future<ExerciseCollection?> createCollection({
    required String name,
    String? description,
    List<String>? initialExerciseIds,
    bool isPublic = false,
    String? color,
    String? icon,
  }) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final collection = ExerciseCollection(
        id: _uuid.v4(),
        userId: user.id,
        name: name,
        description: description,
        exerciseIds: initialExerciseIds ?? [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPublic: isPublic,
        color: color,
        icon: icon,
      );

      try {
        // Try to save to database
        await _supabaseService.client
            .from('exercise_collections')
            .insert(collection.toJson());

        // Update local cache
        _collectionsCache?.insert(0, collection);
        
        _logger.i('Created exercise collection: ${collection.name}');
        return collection;
      } catch (e) {
        _logger.w('Failed to save collection to database, caching locally: $e');
        
        // Cache locally for later sync
        await _cacheService.addPendingCollection(collection);
        
        // Update local cache
        _collectionsCache?.insert(0, collection);
        
        return collection;
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to create collection: $name', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Update an exercise collection
  Future<ExerciseCollection?> updateCollection(
    String collectionId, {
    String? name,
    String? description,
    List<String>? exerciseIds,
    bool? isPublic,
    String? color,
    String? icon,
  }) async {
    try {
      final collections = await getCollections();
      final collection = collections.where((c) => c.id == collectionId).firstOrNull;
      
      if (collection == null) {
        throw Exception('Collection not found: $collectionId');
      }

      final updatedCollection = collection.copyWith(
        name: name,
        description: description,
        exerciseIds: exerciseIds,
        updatedAt: DateTime.now(),
        isPublic: isPublic,
        color: color,
        icon: icon,
      );

      try {
        // Try to update in database
        await _supabaseService.client
            .from('exercise_collections')
            .update(updatedCollection.toJson())
            .eq('id', collectionId);

        // Update local cache
        final index = _collectionsCache?.indexWhere((c) => c.id == collectionId) ?? -1;
        if (index >= 0) {
          _collectionsCache![index] = updatedCollection;
        }
        
        _logger.i('Updated exercise collection: $collectionId');
        return updatedCollection;
      } catch (e) {
        _logger.w('Failed to update collection in database, caching locally: $e');
        
        // Cache locally for later sync
        await _cacheService.addPendingCollectionUpdate(updatedCollection);
        
        // Update local cache
        final index = _collectionsCache?.indexWhere((c) => c.id == collectionId) ?? -1;
        if (index >= 0) {
          _collectionsCache![index] = updatedCollection;
        }
        
        return updatedCollection;
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to update collection: $collectionId', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Delete an exercise collection
  Future<bool> deleteCollection(String collectionId) async {
    try {
      try {
        // Try to delete from database
        await _supabaseService.client
            .from('exercise_collections')
            .delete()
            .eq('id', collectionId);

        // Update local cache
        _collectionsCache?.removeWhere((c) => c.id == collectionId);
        
        _logger.i('Deleted exercise collection: $collectionId');
        return true;
      } catch (e) {
        _logger.w('Failed to delete collection from database, caching deletion: $e');
        
        // Cache deletion for later sync
        await _cacheService.addPendingCollectionDeletion(collectionId);
        
        // Update local cache
        _collectionsCache?.removeWhere((c) => c.id == collectionId);
        
        return true;
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to delete collection: $collectionId', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Add exercise to collection
  Future<bool> addExerciseToCollection(String collectionId, String exerciseId) async {
    try {
      final collections = await getCollections();
      final collection = collections.where((c) => c.id == collectionId).firstOrNull;
      
      if (collection == null) {
        throw Exception('Collection not found: $collectionId');
      }

      if (collection.containsExercise(exerciseId)) {
        _logger.i('Exercise already in collection: $exerciseId');
        return false;
      }

      final updatedExerciseIds = [...collection.exerciseIds, exerciseId];
      final updatedCollection = await updateCollection(
        collectionId,
        exerciseIds: updatedExerciseIds,
      );

      return updatedCollection != null;
    } catch (e, stackTrace) {
      _logger.e('Failed to add exercise to collection: $collectionId, $exerciseId', 
                error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Remove exercise from collection
  Future<bool> removeExerciseFromCollection(String collectionId, String exerciseId) async {
    try {
      final collections = await getCollections();
      final collection = collections.where((c) => c.id == collectionId).firstOrNull;
      
      if (collection == null) {
        throw Exception('Collection not found: $collectionId');
      }

      if (!collection.containsExercise(exerciseId)) {
        _logger.i('Exercise not in collection: $exerciseId');
        return false;
      }

      final updatedExerciseIds = collection.exerciseIds
          .where((id) => id != exerciseId)
          .toList();
      
      final updatedCollection = await updateCollection(
        collectionId,
        exerciseIds: updatedExerciseIds,
      );

      return updatedCollection != null;
    } catch (e, stackTrace) {
      _logger.e('Failed to remove exercise from collection: $collectionId, $exerciseId', 
                error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get exercises in a collection
  Future<List<Exercise>> getCollectionExercises(String collectionId) async {
    try {
      final collections = await getCollections();
      final collection = collections.where((c) => c.id == collectionId).firstOrNull;
      
      if (collection == null) {
        throw Exception('Collection not found: $collectionId');
      }

      if (collection.exerciseIds.isEmpty) {
        return [];
      }

      // Get exercises by IDs
      final exerciseService = ExerciseService.instance;
      return await exerciseService.getExercisesByIds(collection.exerciseIds);
    } catch (e, stackTrace) {
      _logger.e('Failed to get collection exercises: $collectionId', 
                error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Clear all caches
  void clearCache() {
    _favoritesCache = null;
    _collectionsCache = null;
    _lastFavoritesUpdate = null;
    _lastCollectionsUpdate = null;
    _logger.i('Exercise favorites cache cleared');
  }

  // Private helper methods

  bool _canUseFavoritesCache() {
    return _favoritesCache != null &&
        _lastFavoritesUpdate != null &&
        DateTime.now().difference(_lastFavoritesUpdate!) < _cacheExpiry;
  }

  bool _canUseCollectionsCache() {
    return _collectionsCache != null &&
        _lastCollectionsUpdate != null &&
        DateTime.now().difference(_lastCollectionsUpdate!) < _cacheExpiry;
  }

  Future<void> _cacheFavoritesOffline(List<ExerciseFavorite> favorites) async {
    try {
      await _cacheService.cacheFavorites(favorites);
    } catch (e, stackTrace) {
      _logger.e('Failed to cache favorites offline', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _cacheCollectionsOffline(List<ExerciseCollection> collections) async {
    try {
      await _cacheService.cacheCollections(collections);
    } catch (e, stackTrace) {
      _logger.e('Failed to cache collections offline', error: e, stackTrace: stackTrace);
    }
  }

  List<ExerciseFavorite> _getCachedFavoritesOffline() {
    try {
      return _cacheService.getCachedFavorites();
    } catch (e, stackTrace) {
      _logger.e('Failed to get cached favorites', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  List<ExerciseCollection> _getCachedCollectionsOffline() {
    try {
      return _cacheService.getCachedCollections();
    } catch (e, stackTrace) {
      _logger.e('Failed to get cached collections', error: e, stackTrace: stackTrace);
      return [];
    }
  }
}