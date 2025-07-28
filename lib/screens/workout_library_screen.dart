import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/recommendation_service.dart';
import '../services/workout_service.dart';
import '../widgets/workout/workout_card.dart';
import '../widgets/workout/workout_filter_sheet.dart';
import '../providers/workout_provider.dart';
import '../widgets/workout/workout_recommendation_card.dart';


class WorkoutLibraryScreen extends ConsumerStatefulWidget {
  const WorkoutLibraryScreen({super.key});

  @override
  ConsumerState<WorkoutLibraryScreen> createState() => _WorkoutLibraryScreenState();
}

class _WorkoutLibraryScreenState extends ConsumerState<WorkoutLibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  // Filter state
  WorkoutFilters _filters = const WorkoutFilters();
  String _searchQuery = '';
  
  // Data state
  List<WorkoutRecommendation> _recommendations = [];
  List<Workout> _userWorkouts = [];
  bool _isLoadingRecommendations = true;
  bool _isLoadingUserWorkouts = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadRecommendations(),
      _loadUserWorkouts(),
    ]);
  }

  Future<void> _loadRecommendations() async {
    try {
      setState(() {
        _isLoadingRecommendations = true;
        _error = null;
      });

      final recommendations = await RecommendationService.instance
          .getWorkoutRecommendations(limit: 20);

      if (mounted) {
        setState(() {
          _recommendations = recommendations;
          _isLoadingRecommendations = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingRecommendations = false;
        });
      }
    }
  }

  Future<void> _loadUserWorkouts() async {
    try {
      setState(() {
        _isLoadingUserWorkouts = true;
        _error = null;
      });

      final authState = ref.read(authProvider);
      if (!authState.isAuthenticated) return;

      final workouts = await WorkoutService.instance.getWorkoutTemplates(
        userId: authState.user?.id,
      );

      if (mounted) {
        setState(() {
          _userWorkouts = workouts;
          _isLoadingUserWorkouts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingUserWorkouts = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WorkoutFilterSheet(
        currentFilters: _filters,
        onFiltersChanged: (filters) {
          setState(() {
            _filters = filters;
          });
          _loadUserWorkouts(); // Reload with new filters
        },
      ),
    );
  }

  List<WorkoutRecommendation> get _filteredRecommendations {
    var filtered = _recommendations;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((rec) =>
          rec.name.toLowerCase().contains(_searchQuery) ||
          rec.description.toLowerCase().contains(_searchQuery) ||
          rec.goal.toLowerCase().contains(_searchQuery)).toList();
    }

    return filtered;
  }

  List<Workout> get _filteredUserWorkouts {
    var filtered = _userWorkouts;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((workout) =>
          (workout.name?.toLowerCase().contains(_searchQuery) ?? false) ||
          (workout.description?.toLowerCase().contains(_searchQuery) ?? false)).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: theme.colorScheme.onSurface,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Workout Library',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(100),
              child: Column(
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: 'Search workouts...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: _showFilterSheet,
                          icon: const Icon(Icons.tune),
                          style: IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Tab bar
                  TabBar(
                    controller: _tabController,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                    indicatorColor: theme.colorScheme.primary,
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(text: 'Recommended'),
                      Tab(text: 'My Workouts'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildRecommendationsTab(),
            _buildUserWorkoutsTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateWorkoutDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Create Workout'),
      ),
    );
  }

  Widget _buildRecommendationsTab() {
    if (_isLoadingRecommendations) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _buildErrorWidget(_error!, _loadRecommendations);
    }

    final filteredRecommendations = _filteredRecommendations;

    if (filteredRecommendations.isEmpty) {
      return _buildEmptyState(
        icon: Icons.fitness_center,
        title: 'No Recommendations Found',
        subtitle: _searchQuery.isNotEmpty
            ? 'Try adjusting your search terms'
            : 'Complete your profile to get personalized recommendations',
        actionLabel: 'Update Profile',
        onAction: () => context.push('/profile'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecommendations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredRecommendations.length,
        itemBuilder: (context, index) {
          final recommendation = filteredRecommendations[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: WorkoutRecommendationCard(
              recommendation: recommendation,
              onTap: () => _showWorkoutRecommendationDetail(recommendation),
              onStart: () => _startWorkoutFromRecommendation(recommendation),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserWorkoutsTab() {
    if (_isLoadingUserWorkouts) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _buildErrorWidget(_error!, _loadUserWorkouts);
    }

    final filteredWorkouts = _filteredUserWorkouts;

    if (filteredWorkouts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.add_circle_outline,
        title: 'No Workouts Yet',
        subtitle: _searchQuery.isNotEmpty
            ? 'No workouts match your search'
            : 'Create your first custom workout to get started',
        actionLabel: 'Create Workout',
        onAction: _showCreateWorkoutDialog,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUserWorkouts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredWorkouts.length,
        itemBuilder: (context, index) {
          final workout = filteredWorkouts[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: WorkoutCard(
              workout: workout,
              onTap: () => _showWorkoutDetail(workout),
              onStart: () => _startWorkout(workout),
              onEdit: () => _editWorkout(workout),
              onDelete: () => _deleteWorkout(workout),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget(String error, VoidCallback onRetry) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }

  void _showWorkoutRecommendationDetail(WorkoutRecommendation recommendation) {
    context.push('/workout-recommendation/${recommendation.name}', extra: recommendation);
  }

  void _showWorkoutDetail(Workout workout) {
    context.push('/workout/${workout.id}');
  }

  void _startWorkoutFromRecommendation(WorkoutRecommendation recommendation) {
    // TODO: Implement starting workout from recommendation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting ${recommendation.name}...'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _showWorkoutRecommendationDetail(recommendation),
        ),
      ),
    );
  }

  void _startWorkout(Workout workout) {
    // TODO: Implement starting workout
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting ${workout.name ?? 'workout'}...'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _showWorkoutDetail(workout),
        ),
      ),
    );
  }

  void _editWorkout(Workout workout) {
    // TODO: Implement workout editing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editing ${workout.name ?? 'workout'}...'),
      ),
    );
  }

  void _deleteWorkout(Workout workout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workout'),
        content: Text('Are you sure you want to delete "${workout.name ?? 'this workout'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await WorkoutService.instance.deleteWorkout(workout.id);
                _loadUserWorkouts(); // Refresh the list
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Workout deleted')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete workout: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCreateWorkoutDialog() {
    context.push('/workout-builder');
  }
}