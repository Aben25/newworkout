import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/onboarding_provider.dart';
import '../../models/onboarding_state.dart';
import '../../widgets/onboarding/custom_input_widgets.dart';
import '../../widgets/onboarding/unit_conversion_helper.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String? _selectedGender;
  String _heightUnit = 'cm';
  String _weightUnit = 'kg';

  @override
  void initState() {
    super.initState();
    _refreshOnboardingData();
    _loadExistingData();
    _loadUnitPreferences();
    
    // Add listeners to save data when text changes
    _nameController.addListener(_saveData);
    _ageController.addListener(_saveData);
    _heightController.addListener(_saveData);
    _weightController.addListener(_saveData);
  }

  Future<void> _refreshOnboardingData() async {
    // Refresh onboarding data from current profile
    final onboardingNotifier = ref.read(onboardingProvider.notifier);
    await onboardingNotifier.refreshFromProfile();
  }

  Future<void> _loadUnitPreferences() async {
    try {
      final heightUnit = await UnitConversionHelper.getHeightUnitPreference();
      final weightUnit = await UnitConversionHelper.getWeightUnitPreference();
      
      if (mounted) {
        setState(() {
          _heightUnit = heightUnit;
          _weightUnit = weightUnit;
        });
      }
    } catch (e) {
      // Use default units if loading fails
      if (mounted) {
        setState(() {
          _heightUnit = 'cm';
          _weightUnit = 'kg';
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _loadExistingData() {
    final onboardingState = ref.read(onboardingProvider);
    final stepData = onboardingState.stepData;

    // Load data from onboarding state (which now includes profile data)
    _nameController.text = stepData['displayName']?.toString() ?? '';
    _ageController.text = stepData['age']?.toString() ?? '';
    _heightController.text = stepData['height']?.toString() ?? '';
    _weightController.text = stepData['weight']?.toString() ?? '';
    _selectedGender = stepData['gender']?.toString();
    _heightUnit = stepData['heightUnit']?.toString() ?? 'cm';
    _weightUnit = stepData['weightUnit']?.toString() ?? 'kg';
    
    // If we have existing data, trigger validation
    if (_nameController.text.isNotEmpty || 
        _ageController.text.isNotEmpty || 
        _selectedGender != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _saveData(); // This will trigger validation
      });
    }
  }

  void _saveData() {
    try {
      final onboardingNotifier = ref.read(onboardingProvider.notifier);
      
      onboardingNotifier.updateMultipleStepData({
        'displayName': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text),
        'gender': _selectedGender,
        'height': double.tryParse(_heightController.text),
        'weight': double.tryParse(_weightController.text),
        'heightUnit': _heightUnit,
        'weightUnit': _weightUnit,
      });
    } catch (e) {
      // Handle error silently to prevent UI blocking
      // Handle error silently to prevent UI blocking
    }
  }

  void _onUnitChanged(String type, String newUnit) async {
    if (type == 'height') {
      setState(() {
        _heightUnit = newUnit;
      });
      await UnitConversionHelper.saveHeightUnitPreference(newUnit);
    } else if (type == 'weight') {
      setState(() {
        _weightUnit = newUnit;
      });
      await UnitConversionHelper.saveWeightUnitPreference(newUnit);
    }
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasExistingData = ref.watch(hasExistingProfileDataProvider);
    final profileCompletion = ref.watch(profileCompletionProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with enhanced styling
            Text(
              OnboardingStep.personalInfo.title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              OnboardingStep.personalInfo.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            // Existing data indicator
            if (hasExistingData) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_circle,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'We\'ve pre-filled some information from your profile (${(profileCompletion * 100).round()}% complete). You can update any details below.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 32),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Name field with enhanced styling
                    EnhancedNameInputWidget(
                      controller: _nameController,
                    ),
                    const SizedBox(height: 24),

                    // Age field with enhanced styling
                    EnhancedAgeInputWidget(
                      controller: _ageController,
                    ),
                    const SizedBox(height: 24),

                    // Gender selection with enhanced styling
                    EnhancedGenderSelectionWidget(
                      selectedGender: _selectedGender,
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                        _saveData();
                      },
                    ),
                    const SizedBox(height: 24),

                    // Height field with enhanced unit selector
                    EnhancedHeightInputWidget(
                      controller: _heightController,
                      unit: _heightUnit,
                      onUnitChanged: (unit) => _onUnitChanged('height', unit),
                    ),
                    const SizedBox(height: 24),

                    // Weight field with enhanced unit selector
                    EnhancedWeightInputWidget(
                      controller: _weightController,
                      unit: _weightUnit,
                      onUnitChanged: (unit) => _onUnitChanged('weight', unit),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Help text
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This information helps us create personalized workout recommendations for you.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
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
          ],
        ),
      ),
    );
  }
}