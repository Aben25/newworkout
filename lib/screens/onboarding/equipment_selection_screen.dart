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

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Simple header matching Figma
            Text(
              'What equipment do you have?',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select all the equipment you have access to',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),

            // Simple equipment grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: _availableEquipment.length,
              itemBuilder: (context, index) {
                final equipment = _availableEquipment[index];
                final isSelected = _selectedEquipment.contains(equipment['id']);

                return _buildSimpleEquipmentCard(equipment, isSelected, theme);
              },
            ),
            
            // Extra bottom padding to prevent overflow
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleEquipmentCard(Map<String, dynamic> equipment, bool isSelected, ThemeData theme) {
    return GestureDetector(
      onTap: () => _toggleEquipment(equipment['id']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surface,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                equipment['icon'],
                size: 32,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                equipment['title'],
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
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
                  color: theme.colorScheme.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

}