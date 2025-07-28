import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/completed_workout.dart';
import '../../models/achievement.dart';
import '../../services/workout_completion_service.dart';

/// Social sharing widget for workout summaries and achievement data
class SocialShareWidget extends StatefulWidget {
  final CompletedWorkout completedWorkout;
  final List<UserAchievement> unlockedAchievements;

  const SocialShareWidget({
    super.key,
    required this.completedWorkout,
    required this.unlockedAchievements,
  });

  @override
  State<SocialShareWidget> createState() => _SocialShareWidgetState();
}

class _SocialShareWidgetState extends State<SocialShareWidget> {
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Share preview card
        _buildSharePreviewCard(),
        
        const SizedBox(height: 16),
        
        // Share options
        _buildShareOptions(),
        
        const SizedBox(height: 16),
        
        // Achievement highlights
        if (widget.unlockedAchievements.isNotEmpty)
          _buildAchievementHighlights(),
      ],
    );
  }

  Widget _buildSharePreviewCard() {
    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity( 0.1),
              Theme.of(context).colorScheme.primary.withOpacity( 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.share,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Share Your Success',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Workout summary preview
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity( 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Workout completion message
                    Row(
                      children: [
                        Text(
                          '💪 Just completed an amazing workout!',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Key metrics
                    _buildMetricRow('⏱️', 'Duration', widget.completedWorkout.formattedDuration),
                    _buildMetricRow('🔥', 'Calories', '${widget.completedWorkout.caloriesBurned} cal'),
                    _buildMetricRow('🏋️', 'Sets & Reps', '${widget.completedWorkout.totalSets} sets, ${widget.completedWorkout.totalReps} reps'),
                    _buildMetricRow('📊', 'Total Volume', widget.completedWorkout.formattedVolume),
                    
                    // Rating
                    if (widget.completedWorkout.hasRating) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            widget.completedWorkout.formattedRating,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                    
                    // Achievements
                    if (widget.unlockedAchievements.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('🏆 '),
                          Expanded(
                            child: Text(
                              _getAchievementText(),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 12),
                    
                    // Hashtags
                    Text(
                      '#WorkoutComplete #FitnessJourney #ModernWorkoutTracker',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
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

  Widget _buildMetricRow(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(emoji),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share Options',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Share buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSharing ? null : _shareWorkout,
                    icon: _isSharing 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.share),
                    label: Text(_isSharing ? 'Sharing...' : 'Share Workout'),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                OutlinedButton.icon(
                  onPressed: _copyToClipboard,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy'),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Quick share options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickShareButton(
                  'Text Only',
                  Icons.text_fields,
                  () => _shareWorkout(textOnly: true),
                ),
                _buildQuickShareButton(
                  'With Stats',
                  Icons.analytics,
                  () => _shareWorkout(includeStats: true),
                ),
                _buildQuickShareButton(
                  'Achievements',
                  Icons.emoji_events,
                  () => _shareWorkout(achievementsOnly: true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickShareButton(String label, IconData icon, VoidCallback onPressed) {
    return Column(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAchievementHighlights() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Achievement Highlights',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            ...widget.unlockedAchievements.take(3).map((userAchievement) {
              final achievement = PredefinedAchievements.getAchievementById(userAchievement.achievementId);
              if (achievement == null) return const SizedBox.shrink();
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(achievement.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        achievement.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getRarityColor(achievement.rarity),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        achievement.rarity.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            
            if (widget.unlockedAchievements.length > 3) ...[
              Text(
                '+ ${widget.unlockedAchievements.length - 3} more achievements',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity( 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getAchievementText() {
    if (widget.unlockedAchievements.isEmpty) return '';
    
    final achievementNames = widget.unlockedAchievements
        .map((ua) => PredefinedAchievements.getAchievementById(ua.achievementId)?.name)
        .where((name) => name != null)
        .cast<String>()
        .toList();
    
    if (achievementNames.length == 1) {
      return achievementNames.first;
    } else if (achievementNames.length == 2) {
      return '${achievementNames[0]} & ${achievementNames[1]}';
    } else {
      return '${achievementNames[0]} & ${achievementNames.length - 1} more';
    }
  }

  String _generateShareText({
    bool textOnly = false,
    bool includeStats = false,
    bool achievementsOnly = false,
  }) {
    final workoutCompletionService = WorkoutCompletionService.instance;
    final shareableData = workoutCompletionService.createShareableWorkoutSummary(widget.completedWorkout);
    
    if (achievementsOnly && widget.unlockedAchievements.isNotEmpty) {
      final achievementText = _getAchievementText();
      return 'Just unlocked new achievements! 🏆\n'
          '$achievementText\n'
          '#WorkoutComplete #Achievement #ModernWorkoutTracker';
    }
    
    if (textOnly) {
      return 'Just completed an amazing workout! 💪\n'
          '${widget.completedWorkout.formattedDuration} of pure dedication!\n'
          '#WorkoutComplete #FitnessJourney #ModernWorkoutTracker';
    }
    
    String shareText = shareableData['share_text'] as String;
    
    if (includeStats) {
      shareText += '\n\n📈 Detailed Stats:\n'
          '• Intensity: ${widget.completedWorkout.workoutIntensity}/10\n'
          '• Calories/min: ${widget.completedWorkout.caloriesPerMinute.toStringAsFixed(1)}\n'
          '• Muscle groups: ${widget.completedWorkout.muscleGroupDistribution?.length ?? 0}';
    }
    
    return shareText;
  }

  Future<void> _shareWorkout({
    bool textOnly = false,
    bool includeStats = false,
    bool achievementsOnly = false,
  }) async {
    setState(() {
      _isSharing = true;
    });

    try {
      final shareText = _generateShareText(
        textOnly: textOnly,
        includeStats: includeStats,
        achievementsOnly: achievementsOnly,
      );

      await Share.share(
        shareText,
        subject: 'My Workout Summary',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout shared successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share workout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSharing = false;
      });
    }
  }

  Future<void> _copyToClipboard() async {
    try {
      final shareText = _generateShareText();
      await Clipboard.setData(ClipboardData(text: shareText));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Copied to clipboard!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getRarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return Colors.grey;
      case AchievementRarity.uncommon:
        return Colors.green;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
      case AchievementRarity.legendary:
        return Colors.orange;
    }
  }
}