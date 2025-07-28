import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/onboarding_provider.dart';
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
    _loadExistingData();
    _loadUnitPreferences();
    
    // Add listeners to save data when text changes
    _nameController.addListener(_saveData);
    _ageController.addListener(_saveData);
    _heightController.addListener(_saveData);
    _weightController.addListener(_saveData);
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
      // Handle error silently
    }
  }

  void _loadExistingData() {
    final onboardingState = ref.read(onboardingProvider);
    final stepData = onboardingState.stepData;
    
    _nameController.text = stepData['displayName']?.toString() ?? '';
    _ageController.text = stepData['age']?.toString() ?? '';
    _heightController.text = stepData['height']?.toString() ?? '';
    _weightController.text = stepData['weight']?.toString() ?? '';
    _selectedGender = stepData['gender']?.toString();
    _heightUnit = stepData['heightUnit']?.toString() ?? 'cm';
    _weightUnit = stepData['weightUnit']?.toString() ?? 'kg';
  }

  void _saveData() {
    final onboardingNotifier = ref.read(onboardingProvider.notifier);
    onboardingNotifier.updateMultipleStepData({
      'displayName': _nameController.text,
      'age': int.tryParse(_ageController.text),
      'gender': _selectedGender,
      'height': double.tryParse(_heightController.text),
      'weight': double.tryParse(_weightController.text),
      'heightUnit': _heightUnit,
      'weightUnit': _weightUnit,
    });
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
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Simple header matching Figma
              Text(
                'Tell Us About Yourself',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Help us personalize your fitness journey',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              
              const SizedBox(height: 32),

              // Form fields
              EnhancedNameInputWidget(
                controller: _nameController,
              ),
              const SizedBox(height: 24),

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

              EnhancedAgeInputWidget(
                controller: _ageController,
              ),
              const SizedBox(height: 24),

              EnhancedHeightInputWidget(
                controller: _heightController,
                unit: _heightUnit,
                onUnitChanged: (newUnit) => _onUnitChanged('height', newUnit),
              ),
              const SizedBox(height: 24),

              EnhancedWeightInputWidget(
                controller: _weightController,
                unit: _weightUnit,
                onUnitChanged: (newUnit) => _onUnitChanged('weight', newUnit),
              ),
              
              // Extra bottom padding to prevent overflow
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}