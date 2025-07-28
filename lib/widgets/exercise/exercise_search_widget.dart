import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/exercise_provider.dart';
import '../../services/search_service.dart';

class ExerciseSearchWidget extends ConsumerStatefulWidget {
  final Function(String) onSearchChanged;
  final Function(String)? onSearchSubmitted;
  final String? initialQuery;
  final bool autofocus;
  final String hintText;

  const ExerciseSearchWidget({
    super.key,
    required this.onSearchChanged,
    this.onSearchSubmitted,
    this.initialQuery,
    this.autofocus = false,
    this.hintText = 'Search exercises...',
  });

  @override
  ConsumerState<ExerciseSearchWidget> createState() => _ExerciseSearchWidgetState();
}

class _ExerciseSearchWidgetState extends ConsumerState<ExerciseSearchWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _focusNode = FocusNode();
    _currentQuery = widget.initialQuery ?? '';
    
    _focusNode.addListener(_onFocusChanged);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _showSuggestionsOverlay();
    } else {
      _hideSuggestionsOverlay();
    }
  }

  void _onTextChanged() {
    final query = _controller.text;
    if (query != _currentQuery) {
      _currentQuery = query;
      widget.onSearchChanged(query);
      _updateSuggestions(query);
    }
  }

  Future<void> _updateSuggestions(String query) async {
    try {
      final searchService = SearchService.instance;
      final suggestions = await searchService.getSearchSuggestions(query);
      
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _showSuggestions = suggestions.isNotEmpty && _focusNode.hasFocus;
        });
        
        if (_showSuggestions) {
          _showSuggestionsOverlay();
        } else {
          _hideSuggestionsOverlay();
        }
      }
    } catch (e) {
      // Handle error silently, suggestions are not critical
      if (mounted) {
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
        });
        _hideSuggestionsOverlay();
      }
    }
  }

  void _showSuggestionsOverlay() {
    if (_overlayEntry != null || !_showSuggestions || _suggestions.isEmpty) {
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32, // Account for padding
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60), // Position below the search field
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: _buildSuggestionsList(),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideSuggestionsOverlay() {
    _removeOverlay();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildSuggestionsList() {
    final recentSearches = ref.read(recentSearchesProvider);
    final popularSearches = ref.read(popularSearchesProvider);
    
    // Combine suggestions with recent and popular searches
    final allSuggestions = <String>[];
    
    // Add current suggestions first
    allSuggestions.addAll(_suggestions);
    
    // Add recent searches if query is empty
    if (_currentQuery.isEmpty) {
      allSuggestions.addAll(recentSearches.take(5));
    }
    
    // Add popular searches if we don't have enough suggestions
    if (allSuggestions.length < 8) {
      final remainingSlots = 8 - allSuggestions.length;
      final popularToAdd = popularSearches
          .where((popular) => !allSuggestions.contains(popular))
          .take(remainingSlots);
      allSuggestions.addAll(popularToAdd);
    }

    // Remove duplicates while preserving order
    final uniqueSuggestions = <String>[];
    for (final suggestion in allSuggestions) {
      if (!uniqueSuggestions.contains(suggestion)) {
        uniqueSuggestions.add(suggestion);
      }
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: uniqueSuggestions.length,
      itemBuilder: (context, index) {
        final suggestion = uniqueSuggestions[index];
        final isRecent = recentSearches.contains(suggestion);
        final isPopular = popularSearches.contains(suggestion);
        
        return ListTile(
          dense: true,
          leading: Icon(
            isRecent 
                ? Icons.history 
                : isPopular 
                    ? Icons.trending_up 
                    : Icons.search,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          title: Text(
            suggestion,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          trailing: isRecent
              ? IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => _removeSuggestion(suggestion),
                  tooltip: 'Remove from recent searches',
                )
              : null,
          onTap: () => _selectSuggestion(suggestion),
        );
      },
    );
  }

  void _selectSuggestion(String suggestion) {
    _controller.text = suggestion;
    _currentQuery = suggestion;
    widget.onSearchChanged(suggestion);
    widget.onSearchSubmitted?.call(suggestion);
    _focusNode.unfocus();
    _hideSuggestionsOverlay();
  }

  void _removeSuggestion(String suggestion) {
    final searchService = SearchService.instance;
    // This would need to be implemented in the search service
    // searchService.removeRecentSearch(suggestion);
    _updateSuggestions(_currentQuery);
  }

  void _clearSearch() {
    _controller.clear();
    _currentQuery = '';
    widget.onSearchChanged('');
    _updateSuggestions('');
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _focusNode.hasFocus
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: _focusNode.hasFocus ? 2 : 1,
          ),
        ),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _currentQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
                    tooltip: 'Clear search',
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          onSubmitted: (value) {
            widget.onSearchSubmitted?.call(value);
            _focusNode.unfocus();
          },
          textInputAction: TextInputAction.search,
        ),
      ),
    );
  }
}

class ExerciseSearchDelegate extends SearchDelegate<String> {
  final SearchService _searchService = SearchService.instance;

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildRecentAndPopularSearches(context);
    }
    
    return FutureBuilder<List<String>>(
      future: _searchService.getSearchSuggestions(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final suggestions = snapshot.data ?? [];
        
        return ListView.builder(
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return ListTile(
              leading: const Icon(Icons.search),
              title: Text(suggestion),
              onTap: () {
                query = suggestion;
                showResults(context);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRecentAndPopularSearches(BuildContext context) {
    final recentSearches = _searchService.getRecentSearches();
    final popularSearches = _searchService.getPopularSearches();
    
    return ListView(
      children: [
        if (recentSearches.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Recent Searches',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...recentSearches.take(5).map((search) => ListTile(
            leading: const Icon(Icons.history),
            title: Text(search),
            trailing: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                // Remove from recent searches
                // This would need to be implemented
              },
            ),
            onTap: () {
              query = search;
              showResults(context);
            },
          )),
        ],
        if (popularSearches.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Popular Searches',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...popularSearches.take(8).map((search) => ListTile(
            leading: const Icon(Icons.trending_up),
            title: Text(search),
            onTap: () {
              query = search;
              showResults(context);
            },
          )),
        ],
      ],
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final searchQuery = SearchQuery(query: query);
        final searchResults = ref.watch(exerciseSearchProvider(searchQuery));
        
        return searchResults.when(
          data: (results) {
            if (results.results.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No exercises found',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try adjusting your search terms',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }
            
            return ListView.builder(
              itemCount: results.results.length,
              itemBuilder: (context, index) {
                final exercise = results.results[index];
                return ListTile(
                  title: Text(exercise.name),
                  subtitle: Text(exercise.primaryMuscle ?? ''),
                  onTap: () => close(context, exercise.id),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: $error'),
              ],
            ),
          ),
        );
      },
    );
  }
}