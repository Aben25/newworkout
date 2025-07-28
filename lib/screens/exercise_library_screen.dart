import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/exercise.dart';
import '../providers/exercise_provider.dart';
import '../widgets/exercise/exercise_search_widget.dart';
import '../widgets/exercise/exercise_filter_chips.dart';
import '../widgets/exercise/exercise_card.dart';


class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  List<String> _selectedMuscleGroups = [];
  List<String> _selectedEquipmentTypes = [];
  List<String> _selectedCategories = [];
  bool _isGridView = true;
  bool _showFilters = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Implement infinite scrolling if needed
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      // Load more exercises
      _loadMoreExercises();
    }
  }

  void _loadMoreExercises() {
    // This would be implemented to load more exercises
    // For now, we'll keep it simple
  }

  bool get _hasActiveFilters =>
      _selectedMuscleGroups.isNotEmpty ||
      _selectedEquipmentTypes.isNotEmpty ||
      _selectedCategories.isNotEmpty ||
      _searchQuery.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchSection(),
          if (_showFilters) _buildFiltersSection(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllExercisesTab(),
                _buildFavoritesTab(),
                _buildCollectionsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Exercise Library'),
      actions: [
        IconButton(
          icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
          onPressed: () => setState(() => _isGridView = !_isGridView),
          tooltip: _isGridView ? 'List view' : 'Grid view',
        ),
        IconButton(
          icon: Icon(
            Icons.filter_list,
            color: _hasActiveFilters
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          onPressed: () => setState(() => _showFilters = !_showFilters),
          tooltip: 'Filters',
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'search',
              child: ListTile(
                leading: Icon(Icons.search),
                title: Text('Advanced Search'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'sort',
              child: ListTile(
                leading: Icon(Icons.sort),
                title: Text('Sort Options'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'refresh',
              child: ListTile(
                leading: Icon(Icons.refresh),
                title: Text('Refresh'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ExerciseSearchWidget(
        onSearchChanged: (query) => setState(() => _searchQuery = query),
        onSearchSubmitted: (query) {
          // Handle search submission
          _performSearch(query);
        },
        initialQuery: _searchQuery,
        hintText: 'Search exercises by name, muscle, or equipment...',
      ),
    );
  }

  Widget _buildFiltersSection() {
    return ExerciseFilterChips(
      selectedMuscleGroups: _selectedMuscleGroups,
      selectedEquipmentTypes: _selectedEquipmentTypes,
      selectedCategories: _selectedCategories,
      onMuscleGroupsChanged: (groups) => setState(() => _selectedMuscleGroups = groups),
      onEquipmentTypesChanged: (equipment) => setState(() => _selectedEquipmentTypes = equipment),
      onCategoriesChanged: (categories) => setState(() => _selectedCategories = categories),
      onClearFilters: _clearAllFilters,
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(
            icon: Icon(Icons.fitness_center),
            text: 'All Exercises',
          ),
          Tab(
            icon: Icon(Icons.favorite),
            text: 'Favorites',
          ),
          Tab(
            icon: Icon(Icons.collections_bookmark),
            text: 'Collections',
          ),
        ],
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        indicatorColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildAllExercisesTab() {
    if (_hasActiveFilters) {
      return _buildFilteredExercises();
    }
    
    final exercisesAsync = ref.watch(allExercisesProvider);
    
    return exercisesAsync.when(
      data: (exercises) => _buildExercisesList(exercises),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorWidget(error.toString()),
    );
  }

  Widget _buildFilteredExercises() {
    final filters = ExerciseFilters(
      searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      muscleGroup: _selectedMuscleGroups.isNotEmpty ? _selectedMuscleGroups.first : null,
      equipment: _selectedEquipmentTypes.isNotEmpty ? _selectedEquipmentTypes.first : null,
      category: _selectedCategories.isNotEmpty ? _selectedCategories.first : null,
      limit: 50,
    );
    
    final filteredExercisesAsync = ref.watch(filteredExercisesProvider(filters));
    
    return filteredExercisesAsync.when(
      data: (exercises) {
        if (exercises.isEmpty) {
          return _buildEmptyState(
            icon: Icons.search_off,
            title: 'No exercises found',
            subtitle: 'Try adjusting your search or filters',
            action: TextButton(
              onPressed: _clearAllFilters,
              child: const Text('Clear Filters'),
            ),
          );
        }
        return _buildExercisesList(exercises);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorWidget(error.toString()),
    );
  }

  Widget _buildFavoritesTab() {
    // This would use a favorites provider
    return _buildEmptyState(
      icon: Icons.favorite_border,
      title: 'No favorites yet',
      subtitle: 'Tap the heart icon on exercises to add them to your favorites',
    );
  }

  Widget _buildCollectionsTab() {
    // This would use a collections provider
    return _buildEmptyState(
      icon: Icons.collections_bookmark_outlined,
      title: 'No collections yet',
      subtitle: 'Create collections to organize your favorite exercises',
      action: ElevatedButton.icon(
        onPressed: _createNewCollection,
        icon: const Icon(Icons.add),
        label: const Text('Create Collection'),
      ),
    );
  }

  Widget _buildExercisesList(List<Exercise> exercises) {
    if (exercises.isEmpty) {
      return _buildEmptyState(
        icon: Icons.fitness_center,
        title: 'No exercises available',
        subtitle: 'Check your internet connection and try again',
        action: TextButton(
          onPressed: () => ref.refresh(allExercisesProvider),
          child: const Text('Retry'),
        ),
      );
    }

    if (_isGridView) {
      return _buildGridView(exercises);
    } else {
      return _buildListView(exercises);
    }
  }

  Widget _buildGridView(List<Exercise> exercises) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return ExerciseCard(
          exercise: exercise,
          onTap: () => _navigateToExerciseDetail(exercise),
          showFavoriteButton: true,
          isCompact: false,
        );
      },
    );
  }

  Widget _buildListView(List<Exercise> exercises) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return ExerciseCard(
          exercise: exercise,
          onTap: () => _navigateToExerciseDetail(exercise),
          showFavoriteButton: true,
          isCompact: true,
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
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
              'Something went wrong',
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
              onPressed: () => ref.refresh(allExercisesProvider),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'search':
        _showAdvancedSearch();
        break;
      case 'sort':
        _showSortOptions();
        break;
      case 'refresh':
        ref.refresh(allExercisesProvider);
        break;
    }
  }

  void _showAdvancedSearch() {
    showSearch(
      context: context,
      delegate: ExerciseSearchDelegate(),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort by',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('Name (A-Z)'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.accessibility_new),
              title: const Text('Muscle Group'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.fitness_center),
              title: const Text('Equipment'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Most Popular'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _clearAllFilters() {
    setState(() {
      _searchQuery = '';
      _selectedMuscleGroups.clear();
      _selectedEquipmentTypes.clear();
      _selectedCategories.clear();
    });
  }

  void _navigateToExerciseDetail(Exercise exercise) {
    context.push('/exercise/${exercise.id}');
  }

  void _createNewCollection() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Collection'),
        content: const TextField(
          decoration: InputDecoration(
            labelText: 'Collection Name',
            hintText: 'Enter a name for your collection',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Create collection logic
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}