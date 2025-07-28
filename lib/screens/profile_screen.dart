import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import '../widgets/profile/profile_section.dart';
import '../widgets/profile/profile_photo_widget.dart';
import '../widgets/profile/profile_progress_indicator.dart';
import '../widgets/profile/unit_system_toggle.dart';
import '../widgets/profile/multi_select_field.dart';
import '../services/profile_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _isLoading = false;

  // Form controllers for text fields
  final _displayNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _additionalNotesController = TextEditingController();
  final _additionalHealthInfoController = TextEditingController();
  final _mealsPerDayController = TextEditingController();
  final _caloricGoalController = TextEditingController();

  // Form state variables
  String? _selectedGender;
  String _heightUnit = 'cm';
  String _weightUnit = 'kg';
  List<String> _selectedFitnessGoals = [];
  List<String> _selectedEquipment = [];
  List<String> _selectedWorkoutDays = [];
  List<String> _selectedHealthConditions = [];
  List<String> _selectedDietaryRestrictions = [];
  List<String> _selectedPhysicalLimitations = [];
  List<String> _selectedExercisesToAvoid = [];
  List<String> _selectedWorkoutEnvironment = [];
  List<String> _selectedExercisePreferences = [];
  List<String> _selectedDietPreferences = [];
  List<String> _selectedSupplements = [];
  
  int? _cardioFitnessLevel;
  int? _weightliftingFitnessLevel;
  int? _workoutDurationInt;
  int? _workoutFrequencyInt;
  String? _sleepQuality;
  String? _sportActivity;
  String? _specificSportActivity;
  String? _scheduleFlexibility;
  bool _takingSupplements = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    // Initialize form data after the first frame to ensure providers are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeFormData();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _displayNameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _additionalNotesController.dispose();
    _additionalHealthInfoController.dispose();
    _mealsPerDayController.dispose();
    _caloricGoalController.dispose();
    super.dispose();
  }

  void _initializeFormData() {
    final profile = ref.read(userProfileProvider);
    if (profile != null) {
      _displayNameController.text = profile.displayName ?? '';
      _ageController.text = profile.age?.toString() ?? '';
      _heightController.text = profile.height?.toString() ?? '';
      _weightController.text = profile.weight?.toString() ?? '';
      _additionalNotesController.text = profile.additionalNotes ?? '';
      _additionalHealthInfoController.text = profile.additionalHealthInfo ?? '';
      _mealsPerDayController.text = profile.mealsPerDay?.toString() ?? '';
      _caloricGoalController.text = profile.caloricGoal?.toString() ?? '';
      
      _selectedGender = profile.gender;
      _heightUnit = profile.heightUnit.isNotEmpty ? profile.heightUnit : 'cm';
      _weightUnit = profile.weightUnit.isNotEmpty ? profile.weightUnit : 'kg';
      _selectedFitnessGoals = List.from(profile.fitnessGoalsArray ?? []);
      _selectedEquipment = List.from(profile.equipment ?? []);
      _selectedWorkoutDays = List.from(profile.workoutDays ?? []);
      _selectedHealthConditions = List.from(profile.healthConditions ?? []);
      _selectedDietaryRestrictions = List.from(profile.dietaryRestrictions ?? []);
      _selectedPhysicalLimitations = List.from(profile.physicalLimitations ?? []);
      _selectedExercisesToAvoid = List.from(profile.exercisesToAvoid ?? []);
      _selectedWorkoutEnvironment = List.from(profile.workoutEnvironment ?? []);
      _selectedExercisePreferences = List.from(profile.exercisePreferences ?? []);
      _selectedDietPreferences = List.from(profile.dietPreferences ?? []);
      _selectedSupplements = List.from(profile.supplements ?? []);
      
      _cardioFitnessLevel = profile.cardioFitnessLevel;
      _weightliftingFitnessLevel = profile.weightliftingFitnessLevel;
      _workoutDurationInt = profile.workoutDurationInt;
      _workoutFrequencyInt = profile.workoutFrequencyInt;
      _sleepQuality = profile.sleepQuality;
      _sportActivity = profile.sportActivity;
      _specificSportActivity = profile.specificSportActivity;
      _scheduleFlexibility = profile.scheduleFlexibility;
      _takingSupplements = profile.takingSupplements ?? false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final isLoading = ref.watch(isLoadingProvider);
    
    if (profile == null || isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
          else ...[
            TextButton(
              onPressed: _isLoading ? null : _cancelEditing,
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Basic Info'),
            Tab(text: 'Fitness'),
            Tab(text: 'Preferences'),
            Tab(text: 'Health'),
            Tab(text: 'Nutrition'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Profile completion progress
          ProfileProgressIndicator(profile: profile),
          
          // Tab content
          Expanded(
            child: Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBasicInfoTab(profile),
                  _buildFitnessTab(profile),
                  _buildPreferencesTab(profile),
                  _buildHealthTab(profile),
                  _buildNutritionTab(profile),
                  _buildSettingsTab(profile),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoTab(UserProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile photo
          ProfilePhotoWidget(
            profile: profile,
            isEditing: _isEditing,
            onPhotoChanged: _handlePhotoUpload,
          ),
          
          const SizedBox(height: 24),
          
          // Basic information form
          ProfileSection(
            title: 'Personal Information',
            children: [
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  prefixIcon: Icon(Icons.person),
                ),
                enabled: _isEditing,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Display name is required';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  prefixIcon: Icon(Icons.cake),
                  suffixText: 'years',
                ),
                enabled: _isEditing,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Age is required';
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 13 || age > 120) {
                    return 'Please enter a valid age (13-120)';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: Icon(Icons.wc),
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                  DropdownMenuItem(value: 'prefer_not_to_say', child: Text('Prefer not to say')),
                ],
                onChanged: _isEditing ? (value) => setState(() => _selectedGender = value) : null,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select your gender';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _heightController,
                      decoration: const InputDecoration(
                        labelText: 'Height',
                        prefixIcon: Icon(Icons.height),
                      ),
                      enabled: _isEditing,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Height is required';
                        }
                        final height = double.tryParse(value);
                        if (height == null || height <= 0) {
                          return 'Please enter a valid height';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _heightUnit,
                      items: const [
                        DropdownMenuItem(value: 'cm', child: Text('cm')),
                        DropdownMenuItem(value: 'ft', child: Text('ft')),
                      ],
                      onChanged: _isEditing ? (value) => setState(() => _heightUnit = value!) : null,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(
                        labelText: 'Weight',
                        prefixIcon: Icon(Icons.monitor_weight),
                      ),
                      enabled: _isEditing,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Weight is required';
                        }
                        final weight = double.tryParse(value);
                        if (weight == null || weight <= 0) {
                          return 'Please enter a valid weight';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _weightUnit,
                      items: const [
                        DropdownMenuItem(value: 'kg', child: Text('kg')),
                        DropdownMenuItem(value: 'lbs', child: Text('lbs')),
                      ],
                      onChanged: _isEditing ? (value) => setState(() => _weightUnit = value!) : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFitnessTab(UserProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ProfileSection(
            title: 'Fitness Goals',
            children: [
              MultiSelectField(
                title: 'Primary Goals',
                subtitle: 'Select your main fitness objectives',
                options: const [
                  'Weight Loss',
                  'Muscle Gain',
                  'Strength',
                  'Endurance',
                  'Flexibility',
                  'General Fitness',
                  'Athletic Performance',
                  'Rehabilitation',
                ],
                selectedValues: _selectedFitnessGoals,
                onChanged: _isEditing ? (values) => setState(() => _selectedFitnessGoals = values) : null,
                enabled: _isEditing,
                maxSelections: 3,
                icon: Icons.flag,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          ProfileSection(
            title: 'Fitness Level',
            children: [
              RangeSelectField(
                title: 'Cardio Fitness Level',
                subtitle: 'Rate your cardiovascular fitness level',
                min: 1,
                max: 5,
                value: _cardioFitnessLevel?.toDouble(),
                onChanged: _isEditing ? (value) => setState(() => _cardioFitnessLevel = value.round()) : null,
                enabled: _isEditing,
                divisions: 4,
                labelFormatter: (value) {
                  const labels = ['Beginner', 'Novice', 'Intermediate', 'Advanced', 'Expert'];
                  return labels[value.round() - 1];
                },
                icon: Icons.favorite,
              ),
              
              const SizedBox(height: 16),
              
              RangeSelectField(
                title: 'Weightlifting Fitness Level',
                subtitle: 'Rate your strength training experience',
                min: 1,
                max: 5,
                value: _weightliftingFitnessLevel?.toDouble(),
                onChanged: _isEditing ? (value) => setState(() => _weightliftingFitnessLevel = value.round()) : null,
                enabled: _isEditing,
                divisions: 4,
                labelFormatter: (value) {
                  const labels = ['Beginner', 'Novice', 'Intermediate', 'Advanced', 'Expert'];
                  return labels[value.round() - 1];
                },
                icon: Icons.fitness_center,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          ProfileSection(
            title: 'Sports & Activities',
            children: [
              DropdownButtonFormField<String>(
                value: _sportActivity,
                decoration: const InputDecoration(
                  labelText: 'Primary Sport/Activity',
                  prefixIcon: Icon(Icons.sports),
                ),
                items: const [
                  DropdownMenuItem(value: 'running', child: Text('Running')),
                  DropdownMenuItem(value: 'cycling', child: Text('Cycling')),
                  DropdownMenuItem(value: 'swimming', child: Text('Swimming')),
                  DropdownMenuItem(value: 'weightlifting', child: Text('Weightlifting')),
                  DropdownMenuItem(value: 'yoga', child: Text('Yoga')),
                  DropdownMenuItem(value: 'pilates', child: Text('Pilates')),
                  DropdownMenuItem(value: 'martial_arts', child: Text('Martial Arts')),
                  DropdownMenuItem(value: 'team_sports', child: Text('Team Sports')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: _isEditing ? (value) => setState(() => _sportActivity = value) : null,
              ),
              
              if (_sportActivity == 'other') ...[
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _specificSportActivity,
                  decoration: const InputDecoration(
                    labelText: 'Specify Activity',
                    prefixIcon: Icon(Icons.edit),
                  ),
                  enabled: _isEditing,
                  onChanged: (value) => _specificSportActivity = value,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesTab(UserProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ProfileSection(
            title: 'Equipment',
            children: [
              MultiSelectField(
                title: 'Available Equipment',
                subtitle: 'Select all equipment you have access to',
                options: const [
                  'Dumbbells',
                  'Barbell',
                  'Resistance Bands',
                  'Pull-up Bar',
                  'Kettlebells',
                  'Treadmill',
                  'Stationary Bike',
                  'Yoga Mat',
                  'Bench',
                  'Cable Machine',
                  'Smith Machine',
                  'No Equipment',
                ],
                selectedValues: _selectedEquipment,
                onChanged: _isEditing ? (values) => setState(() => _selectedEquipment = values) : null,
                enabled: _isEditing,
                allowCustomInput: true,
                icon: Icons.fitness_center,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          ProfileSection(
            title: 'Workout Schedule',
            children: [
              MultiSelectField(
                title: 'Preferred Workout Days',
                subtitle: 'Select the days you prefer to work out',
                options: const [
                  'Monday',
                  'Tuesday',
                  'Wednesday',
                  'Thursday',
                  'Friday',
                  'Saturday',
                  'Sunday',
                ],
                selectedValues: _selectedWorkoutDays,
                onChanged: _isEditing ? (values) => setState(() => _selectedWorkoutDays = values) : null,
                enabled: _isEditing,
                maxSelections: 7,
                icon: Icons.calendar_today,
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _workoutDurationInt?.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Workout Duration',
                        suffixText: 'minutes',
                        prefixIcon: Icon(Icons.timer),
                      ),
                      enabled: _isEditing,
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _workoutDurationInt = int.tryParse(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      initialValue: _workoutFrequencyInt?.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Frequency',
                        suffixText: 'times/week',
                        prefixIcon: Icon(Icons.repeat),
                      ),
                      enabled: _isEditing,
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _workoutFrequencyInt = int.tryParse(value);
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _scheduleFlexibility,
                decoration: const InputDecoration(
                  labelText: 'Schedule Flexibility',
                  prefixIcon: Icon(Icons.schedule),
                ),
                items: const [
                  DropdownMenuItem(value: 'very_flexible', child: Text('Very Flexible')),
                  DropdownMenuItem(value: 'somewhat_flexible', child: Text('Somewhat Flexible')),
                  DropdownMenuItem(value: 'not_flexible', child: Text('Not Flexible')),
                ],
                onChanged: _isEditing ? (value) => setState(() => _scheduleFlexibility = value) : null,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          ProfileSection(
            title: 'Environment & Preferences',
            children: [
              MultiSelectField(
                title: 'Workout Environment',
                subtitle: 'Where do you prefer to work out?',
                options: const [
                  'Home',
                  'Gym',
                  'Outdoor',
                  'Studio',
                  'Pool',
                ],
                selectedValues: _selectedWorkoutEnvironment,
                onChanged: _isEditing ? (values) => setState(() => _selectedWorkoutEnvironment = values) : null,
                enabled: _isEditing,
                icon: Icons.location_on,
              ),
              
              const SizedBox(height: 16),
              
              MultiSelectField(
                title: 'Exercise Preferences',
                subtitle: 'What types of exercises do you enjoy?',
                options: const [
                  'Cardio',
                  'Strength Training',
                  'HIIT',
                  'Yoga',
                  'Pilates',
                  'Stretching',
                  'Functional Training',
                  'Bodyweight',
                ],
                selectedValues: _selectedExercisePreferences,
                onChanged: _isEditing ? (values) => setState(() => _selectedExercisePreferences = values) : null,
                enabled: _isEditing,
                icon: Icons.sports_gymnastics,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTab(UserProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ProfileSection(
            title: 'Health Conditions',
            children: [
              MultiSelectField(
                title: 'Current Health Conditions',
                subtitle: 'Select any health conditions that may affect your workouts',
                options: const [
                  'None',
                  'Diabetes',
                  'High Blood Pressure',
                  'Heart Disease',
                  'Asthma',
                  'Arthritis',
                  'Back Problems',
                  'Knee Problems',
                  'Other',
                ],
                selectedValues: _selectedHealthConditions,
                onChanged: _isEditing ? (values) => setState(() => _selectedHealthConditions = values) : null,
                enabled: _isEditing,
                allowCustomInput: true,
                icon: Icons.medical_services,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          ProfileSection(
            title: 'Physical Limitations',
            children: [
              MultiSelectField(
                title: 'Physical Limitations',
                subtitle: 'Select any physical limitations or injuries',
                options: const [
                  'None',
                  'Lower Back Issues',
                  'Knee Problems',
                  'Shoulder Issues',
                  'Neck Problems',
                  'Ankle Issues',
                  'Wrist Problems',
                  'Hip Issues',
                  'Other',
                ],
                selectedValues: _selectedPhysicalLimitations,
                onChanged: _isEditing ? (values) => setState(() => _selectedPhysicalLimitations = values) : null,
                enabled: _isEditing,
                allowCustomInput: true,
                icon: Icons.accessibility,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          ProfileSection(
            title: 'Exercise Restrictions',
            children: [
              MultiSelectField(
                title: 'Exercises to Avoid',
                subtitle: 'Select exercises you should avoid due to limitations',
                options: const [
                  'None',
                  'Heavy Lifting',
                  'High Impact',
                  'Jumping',
                  'Running',
                  'Overhead Movements',
                  'Twisting Movements',
                  'Deep Squats',
                  'Deadlifts',
                ],
                selectedValues: _selectedExercisesToAvoid,
                onChanged: _isEditing ? (values) => setState(() => _selectedExercisesToAvoid = values) : null,
                enabled: _isEditing,
                allowCustomInput: true,
                icon: Icons.block,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          ProfileSection(
            title: 'Additional Information',
            children: [
              TextFormField(
                controller: _additionalHealthInfoController,
                decoration: const InputDecoration(
                  labelText: 'Additional Health Information',
                  prefixIcon: Icon(Icons.medical_information),
                  hintText: 'Any other health information we should know about...',
                ),
                enabled: _isEditing,
                maxLines: 3,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionTab(UserProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ProfileSection(
            title: 'Dietary Preferences',
            children: [
              MultiSelectField(
                title: 'Diet Type',
                subtitle: 'Select your dietary preferences',
                options: const [
                  'No Restrictions',
                  'Vegetarian',
                  'Vegan',
                  'Keto',
                  'Paleo',
                  'Mediterranean',
                  'Low Carb',
                  'High Protein',
                  'Gluten Free',
                  'Dairy Free',
                ],
                selectedValues: _selectedDietPreferences,
                onChanged: _isEditing ? (values) => setState(() => _selectedDietPreferences = values) : null,
                enabled: _isEditing,
                icon: Icons.restaurant_menu,
              ),
              
              const SizedBox(height: 16),
              
              MultiSelectField(
                title: 'Dietary Restrictions',
                subtitle: 'Select any food allergies or intolerances',
                options: const [
                  'None',
                  'Gluten Intolerance',
                  'Lactose Intolerance',
                  'Nut Allergies',
                  'Shellfish Allergy',
                  'Egg Allergy',
                  'Soy Allergy',
                  'Other Food Allergies',
                ],
                selectedValues: _selectedDietaryRestrictions,
                onChanged: _isEditing ? (values) => setState(() => _selectedDietaryRestrictions = values) : null,
                enabled: _isEditing,
                allowCustomInput: true,
                icon: Icons.warning,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          ProfileSection(
            title: 'Nutrition Goals',
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _mealsPerDayController,
                      decoration: const InputDecoration(
                        labelText: 'Meals per Day',
                        prefixIcon: Icon(Icons.restaurant),
                      ),
                      enabled: _isEditing,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _caloricGoalController,
                      decoration: const InputDecoration(
                        labelText: 'Daily Calorie Goal',
                        prefixIcon: Icon(Icons.local_fire_department),
                        suffixText: 'kcal',
                      ),
                      enabled: _isEditing,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          ProfileSection(
            title: 'Supplements',
            children: [
              SwitchListTile(
                title: const Text('Taking Supplements'),
                subtitle: const Text('Do you currently take any supplements?'),
                value: _takingSupplements,
                onChanged: _isEditing ? (value) => setState(() => _takingSupplements = value) : null,
              ),
              
              if (_takingSupplements) ...[
                const SizedBox(height: 16),
                MultiSelectField(
                  title: 'Current Supplements',
                  subtitle: 'Select supplements you currently take',
                  options: const [
                    'Protein Powder',
                    'Creatine',
                    'Pre-Workout',
                    'BCAA',
                    'Multivitamin',
                    'Vitamin D',
                    'Omega-3',
                    'Magnesium',
                    'Zinc',
                    'Other',
                  ],
                  selectedValues: _selectedSupplements,
                  onChanged: _isEditing ? (values) => setState(() => _selectedSupplements = values) : null,
                  enabled: _isEditing,
                  allowCustomInput: true,
                  icon: Icons.medication,
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 24),
          
          ProfileSection(
            title: 'Sleep & Recovery',
            children: [
              DropdownButtonFormField<String>(
                value: _sleepQuality,
                decoration: const InputDecoration(
                  labelText: 'Sleep Quality',
                  prefixIcon: Icon(Icons.bedtime),
                ),
                items: const [
                  DropdownMenuItem(value: 'excellent', child: Text('Excellent (8+ hours, restful)')),
                  DropdownMenuItem(value: 'good', child: Text('Good (7-8 hours, mostly restful)')),
                  DropdownMenuItem(value: 'fair', child: Text('Fair (6-7 hours, sometimes restful)')),
                  DropdownMenuItem(value: 'poor', child: Text('Poor (less than 6 hours, not restful)')),
                ],
                onChanged: _isEditing ? (value) => setState(() => _sleepQuality = value) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(UserProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ProfileSection(
            title: 'Unit System',
            children: [
              UnitSystemToggle(
                heightUnit: _heightUnit,
                weightUnit: _weightUnit,
                onHeightUnitChanged: _isEditing ? (unit) => setState(() => _heightUnit = unit) : null,
                onWeightUnitChanged: _isEditing ? (unit) => setState(() => _weightUnit = unit) : null,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          ProfileSection(
            title: 'Additional Notes',
            children: [
              TextFormField(
                controller: _additionalNotesController,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes',
                  prefixIcon: Icon(Icons.note),
                  hintText: 'Any additional information about your fitness journey...',
                ),
                enabled: _isEditing,
                maxLines: 4,
              ),
            ],
          ),
        ],
      ),
    );
  }



  Future<void> _handlePhotoUpload(File imageFile) async {
    if (!_isEditing) return;
    
    setState(() => _isLoading = true);
    
    try {
      final profileService = ref.read(profileServiceProvider);
      final profile = ref.read(userProfileProvider);
      
      if (profile != null) {
        await profileService.uploadProfilePhoto(profile.id, imageFile);
        
        // Refresh the profile to get the updated photo URL
        await ref.read(authProvider.notifier).updateProfile(profile);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile photo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _initializeFormData(); // Reset form data
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final currentProfile = ref.read(userProfileProvider);
      if (currentProfile == null) return;
      
      final updatedProfile = currentProfile.copyWith(
        displayName: _displayNameController.text.trim(),
        age: int.tryParse(_ageController.text),
        gender: _selectedGender,
        height: double.tryParse(_heightController.text),
        heightUnit: _heightUnit,
        weight: double.tryParse(_weightController.text),
        weightUnit: _weightUnit,
        fitnessGoalsArray: _selectedFitnessGoals,
        equipment: _selectedEquipment,
        workoutDays: _selectedWorkoutDays,
        healthConditions: _selectedHealthConditions,
        dietaryRestrictions: _selectedDietaryRestrictions,
        physicalLimitations: _selectedPhysicalLimitations,
        exercisesToAvoid: _selectedExercisesToAvoid,
        workoutEnvironment: _selectedWorkoutEnvironment,
        exercisePreferences: _selectedExercisePreferences,
        dietPreferences: _selectedDietPreferences,
        supplements: _selectedSupplements,
        cardioFitnessLevel: _cardioFitnessLevel,
        weightliftingFitnessLevel: _weightliftingFitnessLevel,
        workoutDurationInt: _workoutDurationInt,
        workoutFrequencyInt: _workoutFrequencyInt,
        sleepQuality: _sleepQuality,
        sportActivity: _sportActivity,
        specificSportActivity: _specificSportActivity,
        scheduleFlexibility: _scheduleFlexibility,
        takingSupplements: _takingSupplements,
        additionalNotes: _additionalNotesController.text.trim(),
        additionalHealthInfo: _additionalHealthInfoController.text.trim(),
        mealsPerDay: int.tryParse(_mealsPerDayController.text),
        caloricGoal: int.tryParse(_caloricGoalController.text),
        updatedAt: DateTime.now(),
      );
      
      await ref.read(authProvider.notifier).updateProfile(updatedProfile);
      
      setState(() {
        _isEditing = false;
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    }
  }
}