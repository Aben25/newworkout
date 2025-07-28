import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import '../models/exercise.dart';
import '../providers/exercise_provider.dart';
import '../services/exercise_favorites_service.dart';

class ExerciseDetailScreen extends ConsumerStatefulWidget {
  final String exerciseId;

  const ExerciseDetailScreen({
    super.key,
    required this.exerciseId,
  });

  @override
  ConsumerState<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends ConsumerState<ExerciseDetailScreen>
    with TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  late AnimationController _favoriteAnimationController;
  late Animation<double> _favoriteAnimation;
  bool _isFavorite = false;
  bool _isLoadingFavorite = false;
  bool _isVideoPlaying = false;
  final bool _showVideoControls = true;
  bool _useVerticalVideo = true;

  @override
  void initState() {
    super.initState();
    _favoriteAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _favoriteAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _favoriteAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _favoriteAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo(Exercise exercise) async {
    final videoUrl = _useVerticalVideo && exercise.verticalVideo != null
        ? exercise.verticalVideo!
        : exercise.videoUrl;
    
    if (videoUrl == null) return;

    try {
      _videoController?.dispose();
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Handle video initialization error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load video'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _checkFavoriteStatus(Exercise exercise) async {
    try {
      final favoritesService = ExerciseFavoritesService.instance;
      final isFavorite = await favoritesService.isFavorite(exercise.id);
      if (mounted) {
        setState(() {
          _isFavorite = isFavorite;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _toggleFavorite(Exercise exercise) async {
    if (_isLoadingFavorite) return;
    
    setState(() {
      _isLoadingFavorite = true;
    });

    try {
      final favoritesService = ExerciseFavoritesService.instance;
      
      if (_isFavorite) {
        final success = await favoritesService.removeFromFavorites(exercise.id);
        if (success && mounted) {
          setState(() {
            _isFavorite = false;
          });
          _showSnackBar('Removed from favorites');
        }
      } else {
        final favorite = await favoritesService.addToFavorites(exercise.id);
        if (favorite != null && mounted) {
          setState(() {
            _isFavorite = true;
          });
          _favoriteAnimationController.forward().then((_) {
            _favoriteAnimationController.reverse();
          });
          _showSnackBar('Added to favorites');
        }
      }
    } catch (e) {
      _showSnackBar('Failed to update favorites');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFavorite = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleVideoPlayback() {
    if (_videoController == null) return;
    
    setState(() {
      if (_isVideoPlaying) {
        _videoController!.pause();
        _isVideoPlaying = false;
      } else {
        _videoController!.play();
        _isVideoPlaying = true;
      }
    });
  }

  void _shareExercise(Exercise exercise) {
    Share.share(
      'Check out this exercise: ${exercise.name}\n\n'
      '${exercise.description ?? ''}\n\n'
      'Shared from Modern Workout Tracker',
      subject: 'Exercise: ${exercise.name}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final exerciseAsync = ref.watch(exerciseByIdProvider(widget.exerciseId));
    
    return exerciseAsync.when(
      data: (exercise) {
        if (exercise == null) {
          return _buildNotFoundScreen();
        }
        
        // Initialize video and check favorite status when exercise loads
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initializeVideo(exercise);
          _checkFavoriteStatus(exercise);
        });
        
        return _buildExerciseDetail(exercise);
      },
      loading: () => _buildLoadingScreen(),
      error: (error, stack) => _buildErrorScreen(error.toString()),
    );
  }

  Widget _buildExerciseDetail(Exercise exercise) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(exercise),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVideoSection(exercise),
                _buildExerciseInfo(exercise),
                _buildInstructions(exercise),
                _buildMuscleInfo(exercise),
                _buildEquipmentInfo(exercise),
                _buildAlternatives(exercise),
                const SizedBox(height: 100), // Space for FAB
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButtons(exercise),
    );
  }

  Widget _buildSliverAppBar(Exercise exercise) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          exercise.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3,
                color: Colors.black54,
              ),
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (exercise.hasVideo)
              CachedNetworkImage(
                imageUrl: _useVerticalVideo && exercise.verticalVideo != null
                    ? exercise.verticalVideo!
                    : exercise.videoUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => _buildPlaceholderBackground(exercise),
              )
            else
              _buildPlaceholderBackground(exercise),
            
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        AnimatedBuilder(
          animation: _favoriteAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _favoriteAnimation.value,
              child: IconButton(
                onPressed: _isLoadingFavorite ? null : () => _toggleFavorite(exercise),
                icon: _isLoadingFavorite
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : Colors.white,
                      ),
                tooltip: _isFavorite ? 'Remove from favorites' : 'Add to favorites',
              ),
            );
          },
        ),
        IconButton(
          onPressed: () => _shareExercise(exercise),
          icon: const Icon(Icons.share, color: Colors.white),
          tooltip: 'Share exercise',
        ),
      ],
    );
  }

  Widget _buildPlaceholderBackground(Exercise exercise) {
    return Container(
      color: Theme.of(context).colorScheme.primary,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 80,
              color: Colors.white.withOpacity(0.8),
            ),
            const SizedBox(height: 16),
            Text(
              exercise.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoSection(Exercise exercise) {
    if (!exercise.hasVideo) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: _useVerticalVideo ? 9 / 16 : 16 / 9,
          child: Stack(
            children: [
              if (_videoController != null && _videoController!.value.isInitialized)
                VideoPlayer(_videoController!)
              else
                Container(
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              
              // Video controls overlay
              if (_showVideoControls)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Play/pause button
                      Center(
                        child: GestureDetector(
                          onTap: _toggleVideoPlayback,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isVideoPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                      
                      // Video format toggle
                      if (exercise.videoUrl != null && exercise.verticalVideo != null)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _useVerticalVideo = !_useVerticalVideo;
                              });
                              _initializeVideo(exercise);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _useVerticalVideo
                                        ? Icons.stay_current_portrait
                                        : Icons.stay_current_landscape,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _useVerticalVideo ? 'Vertical' : 'Horizontal',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseInfo(Exercise exercise) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exercise.name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (exercise.description != null) ...[
            Text(
              exercise.description!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
          ],
          _buildInfoChips(exercise),
        ],
      ),
    );
  }

  Widget _buildInfoChips(Exercise exercise) {
    final chips = <Widget>[];
    
    if (exercise.primaryMuscle != null) {
      chips.add(_buildInfoChip(
        icon: Icons.accessibility_new,
        label: exercise.primaryMuscle!,
        color: Theme.of(context).colorScheme.primary,
      ));
    }
    
    if (exercise.equipment != null) {
      chips.add(_buildInfoChip(
        icon: Icons.fitness_center,
        label: exercise.equipment!,
        color: Theme.of(context).colorScheme.secondary,
      ));
    }
    
    if (exercise.category != null) {
      chips.add(_buildInfoChip(
        icon: Icons.category,
        label: exercise.category!,
        color: Theme.of(context).colorScheme.tertiary,
      ));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions(Exercise exercise) {
    if (exercise.instructions == null || exercise.instructions!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.list_alt,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Instructions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            exercise.instructions!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleInfo(Exercise exercise) {
    final muscles = <String>[];
    if (exercise.primaryMuscle != null) muscles.add(exercise.primaryMuscle!);
    if (exercise.secondaryMuscle != null) muscles.add(exercise.secondaryMuscle!);
    
    if (muscles.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.accessibility_new,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                'Target Muscles',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: muscles.map((muscle) {
              final isPrimary = muscle == exercise.primaryMuscle;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isPrimary
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  muscle,
                  style: TextStyle(
                    color: isPrimary
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentInfo(Exercise exercise) {
    if (exercise.equipment == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.fitness_center,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Equipment Needed',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  exercise.equipment!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternatives(Exercise exercise) {
    // This would show alternative exercises
    // For now, we'll show a placeholder
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.swap_horiz,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Similar Exercises',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Alternative exercises will be shown here based on muscle groups and equipment.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButtons(Exercise exercise) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: 'add_to_workout',
          onPressed: () => _addToWorkout(exercise),
          tooltip: 'Add to workout',
          child: const Icon(Icons.add),
        ),
        const SizedBox(height: 16),
        FloatingActionButton.extended(
          heroTag: 'start_exercise',
          onPressed: () => _startExercise(exercise),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Exercise'),
        ),
      ],
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Failed to load exercise',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.refresh(exerciseByIdProvider(widget.exerciseId)),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotFoundScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Exercise Not Found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 80,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 24),
              Text(
                'Exercise not found',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'The exercise you\'re looking for doesn\'t exist or has been removed.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addToWorkout(Exercise exercise) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add to Workout',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Create New Workout'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to workout creation
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('Add to Existing Workout'),
              onTap: () {
                Navigator.pop(context);
                // Show workout selection
              },
            ),
            ListTile(
              leading: const Icon(Icons.collections_bookmark),
              title: const Text('Add to Collection'),
              onTap: () {
                Navigator.pop(context);
                // Show collection selection
              },
            ),
          ],
        ),
      ),
    );
  }

  void _startExercise(Exercise exercise) {
    // Navigate to exercise execution screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Exercise'),
        content: Text('Start performing ${exercise.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to exercise execution
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }
}