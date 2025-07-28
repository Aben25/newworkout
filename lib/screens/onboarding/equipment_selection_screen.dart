import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/onboarding_provider.dart';
import '../../models/onboarding_state.dart';

class EquipmentSelectionScreen extends ConsumerStatefulWidget {
  const EquipmentSelectionScreen({super.key});

  @override
  ConsumerState<EquipmentSelectionScreen> createState() => _EquipmentSelectionScreenState();
}

class _EquipmentSelectionScreenState extends ConsumerState<EquipmentSelectionScreen>
    with TickerProviderStateMixin {
  List<String> _selectedEquipment = [];
  List<String> _selectedEnvironments = [];
  String _searchQuery = '';
  String _selectedCategory = 'all';
  late AnimationController _animationController;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _availableEquipment = [
    {
      'id': 'none',
      'title': 'No Equipment',
      'description': 'Bodyweight exercises only',
      'icon': Icons.accessibility_new,
      'category': 'bodyweight',
      'color': Colors.green,
    },
    {
      'id': 'dumbbells',
      'title': 'Dumbbells',
      'description': 'Adjustable or fixed weights',
      'icon': Icons.fitness_center,
      'category': 'weights',
      'color': Colors.blue,
    },
    {
      'id': 'barbell',
      'title': 'Barbell',
      'description': 'Olympic or standard barbell',
      'icon': Icons.sports_gymnastics,
      'category': 'weights',
      'color': Colors.blue,
    },
    {
      'id': 'resistance_bands',
      'title': 'Resistance Bands',
      'description': 'Loop bands or tube bands',
      'icon': Icons.linear_scale,
      'category': 'accessories',
      'color': Colors.orange,
    },
    {
      'id': 'kettlebells',
      'title': 'Kettlebells',
      'description': 'Various weights available',
      'icon': Icons.sports_handball,
      'category': 'weights',
      'color': Colors.blue,
    },
    {
      'id': 'pull_up_bar',
      'title': 'Pull-up Bar',
      'description': 'Doorway or wall-mounted',
      'icon': Icons.horizontal_rule,
      'category': 'accessories',
      'color': Colors.orange,
    },
    {
      'id': 'bench',
      'title': 'Bench',
      'description': 'Adjustable or flat bench',
      'icon': Icons.weekend,
      'category': 'accessories',
      'color': Colors.orange,
    },
    {
      'id': 'cable_machine',
      'title': 'Cable Machine',
      'description': 'Pulley system with weights',
      'icon': Icons.cable,
      'category': 'machines',
      'color': Colors.purple,
    },
    {
      'id': 'cardio_equipment',
      'title': 'Cardio Equipment',
      'description': 'Treadmill, bike, elliptical',
      'icon': Icons.directions_run,
      'category': 'cardio',
      'color': Colors.red,
    },
    {
      'id': 'smith_machine',
      'title': 'Smith Machine',
      'description': 'Guided barbell system',
      'icon': Icons.view_column,
      'category': 'machines',
      'color': Colors.purple,
    },
    {
      'id': 'medicine_ball',
      'title': 'Medicine Ball',
      'description': 'Weighted ball for exercises',
      'icon': Icons.sports_basketball,
      'category': 'accessories',
      'color': Colors.orange,
    },
    {
      'id': 'foam_roller',
      'title': 'Foam Roller',
      'description': 'Recovery and mobility tool',
      'icon': Icons.straighten,
      'category': 'recovery',
      'color': Colors.teal,
    },
  ];

  final List<Map<String, dynamic>> _workoutEnvironments = [
    {
      'id': 'home',
      'title': 'Home',
      'description': 'Workout at home',
      'icon': Icons.home,
      'color': Colors.green,
    },
    {
      'id': 'gym',
      'title': 'Gym',
      'description': 'Commercial gym or fitness center',
      'icon': Icons.fitness_center,
      'color': Colors.blue,
    },
    {
      'id': 'outdoor',
      'title': 'Outdoor',
      'description': 'Parks, trails, or outdoor spaces',
      'icon': Icons.park,
      'color': Colors.orange,
    },
  ];

  final List<Map<String, dynamic>> _equipmentCategories = [
    {'id': 'all', 'title': 'All', 'icon': Icons.apps},
    {'id': 'bodyweight', 'title': 'Bodyweight', 'icon': Icons.accessibility_new},
    {'id': 'weights', 'title': 'Weights', 'icon': Icons.fitness_center},
    {'id': 'accessories', 'title': 'Accessories', 'icon': Icons.sports_gymnastics},
    {'id': 'machines', 'title': 'Machines', 'icon': Icons.precision_manufacturing},
    {'id': 'cardio', 'title': 'Cardio', 'icon': Icons.directions_run},
    {'id': 'recovery', 'title': 'Recovery', 'icon': Icons.spa},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadExistingData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadExistingData() {
    final onboardingState = ref.read(onboardingProvider);
    final stepData = onboardingState.stepData;
    
    if (stepData['equipment'] != null) {
      _selectedEquipment = List<String>.from(stepData['equipment']);
    }
    if (stepData['workoutEnvironment'] != null) {
      _selectedEnvironments = List<String>.from(stepData['workoutEnvironment']);
    }
  }

  void _saveData() {
    final onboardingNotifier = ref.read(onboardingProvider.notifier);
    onboardingNotifier.updateMultipleStepData({
      'equipment': _selectedEquipment,
      'workoutEnvironment': _selectedEnvironments,
    });
  }

  void _toggleEquipment(String equipmentId) {
    setState(() {
      if (equipmentId == 'none') {
        // If selecting "No Equipment", clear all other selections
        if (_selectedEquipment.contains('none')) {
          _selectedEquipment.remove('none');
        } else {
          _selectedEquipment.clear();
          _selectedEquipment.add('none');
        }
      } else {
        // If selecting other equipment, remove "No Equipment"
        _selectedEquipment.remove('none');
        if (_selectedEquipment.contains(equipmentId)) {
          _selectedEquipment.remove(equipmentId);
        } else {
          _selectedEquipment.add(equipmentId);
        }
      }
    });
    _saveData();
  }

  void _toggleEnvironment(String environmentId) {
    setState(() {
      if (_selectedEnvironments.contains(environmentId)) {
        _selectedEnvironments.remove(environmentId);
      } else {
        _selectedEnvironments.add(environmentId);
      }
    });
    _saveData();
    _animationController.forward().then((_) => _animationController.reset());
  }

  List<Map<String, dynamic>> _getFilteredEquipment() {
    return _availableEquipment.where((equipment) {
      final matchesSearch = equipment['title']
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase()) ||
          equipment['description']
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
      
      final matchesCategory = _selectedCategory == 'all' || 
          equipment['category'] == _selectedCategory;
      
      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<String> _getRecommendedEquipment() {
    final recommendations = <String>[];
    
    // Recommend based on selected environments
    if (_selectedEnvironments.contains('home')) {
      recommendations.addAll(['dumbbells', 'resistance_bands', 'none']);
    }
    if (_selectedEnvironments.contains('gym')) {
      recommendations.addAll(['barbell', 'cable_machine', 'bench']);
    }
    if (_selectedEnvironments.contains('outdoor')) {
      recommendations.addAll(['none', 'resistance_bands']);
    }
    
    return recommendations.toSet().toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            OnboardingStep.equipment.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            OnboardingStep.equipment.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Workout Environment Section
                  _buildSectionHeader(
                    'Where do you prefer to workout?',
                    'Select your preferred workout locations',
                    Icons.location_on,
                    theme,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildEnvironmentCards(theme),
                  
                  const SizedBox(height: 32),
                  
                  // Equipment Section
                  _buildSectionHeader(
                    'What equipment do you have access to?',
                    'Select all equipment you can use for workouts',
                    Icons.fitness_center,
                    theme,
                  ),
                  const SizedBox(height: 16),
                  
                  // Search bar
                  _buildSearchBar(theme),
                  const SizedBox(height: 16),
                  
                  // Category filters
                  _buildCategoryFilters(theme),
                  const SizedBox(height: 16),
                  
                  // Recommendations section
                  if (_selectedEnvironments.isNotEmpty) ...[
                    _buildRecommendationsSection(theme),
                    const SizedBox(height: 16),
                  ],
                  
                  // Equipment grid
                  _buildEquipmentGrid(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentCards(ThemeData theme) {
    return Row(
      children: _workoutEnvironments.map((environment) {
        final isSelected = _selectedEnvironments.contains(environment['id']);
        
        return Expanded(
          child: GestureDetector(
            onTap: () => _toggleEnvironment(environment['id']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? environment['color'].withValues(alpha: 0.2)
                    : theme.colorScheme.surface,
                border: Border.all(
                  color: isSelected
                      ? environment['color']
                      : theme.colorScheme.outline.withValues(alpha: 0.5),
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: environment['color'].withValues(alpha: 0.2),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Icon(
                    environment['icon'],
                    size: 32,
                    color: isSelected
                        ? environment['color']
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    environment['title'],
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? environment['color']
                          : theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    environment['description'],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? environment['color'].withValues(alpha: 0.8)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isSelected) ...[
                    const SizedBox(height: 8),
                    Icon(
                      Icons.check_circle,
                      size: 20,
                      color: environment['color'],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search equipment...',
        prefixIcon: Icon(
          Icons.search,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
    );
  }

  Widget _buildCategoryFilters(ThemeData theme) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _equipmentCategories.length,
        itemBuilder: (context, index) {
          final category = _equipmentCategories[index];
          final isSelected = _selectedCategory == category['id'];
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category['id'];
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surface,
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.5),
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      category['icon'],
                      size: 16,
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      category['title'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommendationsSection(ThemeData theme) {
    final recommendations = _getRecommendedEquipment();
    
    if (recommendations.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Recommended for your environments',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recommendations.map((equipmentId) {
              final equipment = _availableEquipment.firstWhere(
                (e) => e['id'] == equipmentId,
                orElse: () => {},
              );
              if (equipment.isEmpty) return const SizedBox.shrink();
              
              final isSelected = _selectedEquipment.contains(equipmentId);
              
              return GestureDetector(
                onTap: () => _toggleEquipment(equipmentId),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.2)
                        : theme.colorScheme.surface,
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        equipment['icon'],
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        equipment['title'],
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.check,
                          size: 12,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentGrid(ThemeData theme) {
    final filteredEquipment = _getFilteredEquipment();
    
    if (filteredEquipment.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No equipment found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or category filter',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: filteredEquipment.length,
      itemBuilder: (context, index) {
        final equipment = filteredEquipment[index];
        final isSelected = _selectedEquipment.contains(equipment['id']);
        final isRecommended = _getRecommendedEquipment().contains(equipment['id']);

        return GestureDetector(
          onTap: () => _toggleEquipment(equipment['id']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: isSelected
                  ? equipment['color'].withValues(alpha: 0.2)
                  : theme.colorScheme.surface,
              border: Border.all(
                color: isSelected
                    ? equipment['color']
                    : theme.colorScheme.outline.withValues(alpha: 0.5),
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: equipment['color'].withValues(alpha: 0.2),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                // Recommended badge
                if (isRecommended && !isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.star,
                        size: 12,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                
                // Main content
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        equipment['icon'],
                        size: 32,
                        color: isSelected
                            ? equipment['color']
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        equipment['title'],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? equipment['color']
                              : theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        equipment['description'],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? equipment['color'].withValues(alpha: 0.8)
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isSelected) ...[
                        const SizedBox(height: 8),
                        Icon(
                          Icons.check_circle,
                          size: 20,
                          color: equipment['color'],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}