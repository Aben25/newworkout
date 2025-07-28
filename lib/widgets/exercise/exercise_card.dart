import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/exercise.dart';

import '../../services/exercise_favorites_service.dart';

class ExerciseCard extends ConsumerStatefulWidget {
  final Exercise exercise;
  final VoidCallback? onTap;
  final bool showFavoriteButton;
  final bool isCompact;

  const ExerciseCard({
    super.key,
    required this.exercise,
    this.onTap,
    this.showFavoriteButton = true,
    this.isCompact = false,
  });

  @override
  ConsumerState<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends ConsumerState<ExerciseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _favoriteAnimationController;
  late Animation<double> _favoriteAnimation;
  bool _isFavorite = false;
  bool _isLoadingFavorite = false;

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
    
    _checkFavoriteStatus();
  }

  @override
  void dispose() {
    _favoriteAnimationController.dispose();
    super.dispose();
  }

  Future<void> _checkFavoriteStatus() async {
    if (!widget.showFavoriteButton) return;
    
    try {
      final favoritesService = ExerciseFavoritesService.instance;
      final isFavorite = await favoritesService.isFavorite(widget.exercise.id);
      if (mounted) {
        setState(() {
          _isFavorite = isFavorite;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoadingFavorite) return;
    
    setState(() {
      _isLoadingFavorite = true;
    });

    try {
      final favoritesService = ExerciseFavoritesService.instance;
      
      if (_isFavorite) {
        final success = await favoritesService.removeFromFavorites(widget.exercise.id);
        if (success && mounted) {
          setState(() {
            _isFavorite = false;
          });
          _showSnackBar('Removed from favorites');
        }
      } else {
        final favorite = await favoritesService.addToFavorites(widget.exercise.id);
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

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      return _buildCompactCard();
    }
    return _buildFullCard();
  }

  Widget _buildFullCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExerciseImage(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildExerciseHeader(),
                  const SizedBox(height: 8),
                  _buildExerciseDetails(),
                  if (widget.exercise.description != null) ...[
                    const SizedBox(height: 8),
                    _buildExerciseDescription(),
                  ],
                  const SizedBox(height: 12),
                  _buildExerciseTags(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildCompactImage(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildExerciseHeader(),
                    const SizedBox(height: 4),
                    _buildCompactDetails(),
                  ],
                ),
              ),
              if (widget.showFavoriteButton) _buildFavoriteButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseImage() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Stack(
        children: [
          if (widget.exercise.videoUrl != null || widget.exercise.verticalVideo != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: widget.exercise.verticalVideo ?? widget.exercise.videoUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => _buildPlaceholderImage(),
              ),
            )
          else
            _buildPlaceholderImage(),
          
          // Video indicator
          if (widget.exercise.hasVideo)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_circle_outline,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Video',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Favorite button
          if (widget.showFavoriteButton)
            Positioned(
              top: 12,
              right: 12,
              child: _buildFavoriteButton(),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: widget.exercise.hasVideo
          ? Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: widget.exercise.verticalVideo ?? widget.exercise.videoUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _buildCompactPlaceholder(),
                    errorWidget: (context, url, error) => _buildCompactPlaceholder(),
                  ),
                ),
                const Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            )
          : _buildCompactPlaceholder(),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 200,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            widget.exercise.name,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Icon(
        Icons.fitness_center,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 24,
      ),
    );
  }

  Widget _buildExerciseHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.exercise.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!widget.isCompact && widget.showFavoriteButton)
          _buildFavoriteButton(),
      ],
    );
  }

  Widget _buildExerciseDetails() {
    return Row(
      children: [
        if (widget.exercise.primaryMuscle != null) ...[
          Icon(
            Icons.accessibility_new,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            widget.exercise.primaryMuscle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        if (widget.exercise.equipment != null) ...[
          if (widget.exercise.primaryMuscle != null) const SizedBox(width: 16),
          Icon(
            Icons.fitness_center,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 4),
          Text(
            widget.exercise.equipment!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompactDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.exercise.primaryMuscle != null)
          Text(
            widget.exercise.primaryMuscle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        if (widget.exercise.equipment != null)
          Text(
            widget.exercise.equipment!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
      ],
    );
  }

  Widget _buildExerciseDescription() {
    return Text(
      widget.exercise.description!,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildExerciseTags() {
    final tags = <String>[];
    
    if (widget.exercise.category != null) {
      tags.add(widget.exercise.category!);
    }
    
    if (widget.exercise.secondaryMuscle != null) {
      tags.add(widget.exercise.secondaryMuscle!);
    }

    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: tags.take(3).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            tag,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              fontSize: 11,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFavoriteButton() {
    return AnimatedBuilder(
      animation: _favoriteAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _favoriteAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _isLoadingFavorite ? null : _toggleFavorite,
              icon: _isLoadingFavorite
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    )
                  : Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite
                          ? Colors.red
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              tooltip: _isFavorite ? 'Remove from favorites' : 'Add to favorites',
            ),
          ),
        );
      },
    );
  }
}