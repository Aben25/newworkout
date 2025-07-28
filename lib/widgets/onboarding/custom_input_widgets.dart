import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'unit_conversion_helper.dart';

// Enhanced input widgets with better styling and validation

class EnhancedNameInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const EnhancedNameInputWidget({
    super.key,
    required this.controller,
    this.validator,
  });

  @override
  State<EnhancedNameInputWidget> createState() => _EnhancedNameInputWidgetState();
}

class _EnhancedNameInputWidgetState extends State<EnhancedNameInputWidget> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Full Name',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          textCapitalization: TextCapitalization.words,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s\-\.]')),
            LengthLimitingTextInputFormatter(50),
          ],
          decoration: InputDecoration(
            hintText: 'Enter your full name',
            prefixIcon: Icon(
              Icons.person_outline,
              color: _hasError 
                  ? theme.colorScheme.error 
                  : theme.colorScheme.primary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.outline,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withOpacity( 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity( 0.3),
          ),
          validator: (value) {
            final error = widget.validator?.call(value) ?? _validateName(value);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _hasError = error != null;
                });
              }
            });
            return error;
          },
        ),
      ],
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    final nameRegex = RegExp(r'^[a-zA-Z\s\-\.]+$');
    if (!nameRegex.hasMatch(value.trim())) {
      return 'Name can only contain letters, spaces, hyphens, and periods';
    }
    return null;
  }
}
class
 EnhancedAgeInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const EnhancedAgeInputWidget({
    super.key,
    required this.controller,
    this.validator,
  });

  @override
  State<EnhancedAgeInputWidget> createState() => _EnhancedAgeInputWidgetState();
}

class _EnhancedAgeInputWidgetState extends State<EnhancedAgeInputWidget> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Age',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
          decoration: InputDecoration(
            hintText: 'Enter your age',
            prefixIcon: Icon(
              Icons.cake_outlined,
              color: _hasError 
                  ? theme.colorScheme.error 
                  : theme.colorScheme.primary,
            ),
            suffixText: 'years',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withOpacity( 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity( 0.3),
          ),
          validator: (value) {
            final error = widget.validator?.call(value) ?? _validateAge(value);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _hasError = error != null;
                });
              }
            });
            return error;
          },
        ),
      ],
    );
  }

  String? _validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your age';
    }
    final age = int.tryParse(value);
    if (age == null || age < 13 || age > 120) {
      return 'Please enter a valid age (13-120)';
    }
    return null;
  }
}

class EnhancedGenderSelectionWidget extends StatefulWidget {
  final String? selectedGender;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  const EnhancedGenderSelectionWidget({
    super.key,
    required this.selectedGender,
    required this.onChanged,
    this.validator,
  });

  @override
  State<EnhancedGenderSelectionWidget> createState() => _EnhancedGenderSelectionWidgetState();
}

class _EnhancedGenderSelectionWidgetState extends State<EnhancedGenderSelectionWidget> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _getValidGenderValue(widget.selectedGender),
          decoration: InputDecoration(
            hintText: 'Select your gender',
            prefixIcon: Icon(
              Icons.wc_outlined,
              color: _hasError 
                  ? theme.colorScheme.error 
                  : theme.colorScheme.primary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withOpacity( 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity( 0.3),
          ),
          items: const [
            DropdownMenuItem(value: 'male', child: Text('Male')),
            DropdownMenuItem(value: 'female', child: Text('Female')),
            DropdownMenuItem(value: 'other', child: Text('Other')),
            DropdownMenuItem(value: 'prefer_not_to_say', child: Text('Prefer not to say')),
          ],
          onChanged: widget.onChanged,
          validator: (value) {
            final error = widget.validator?.call(value) ?? _validateGender(value);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _hasError = error != null;
                });
              }
            });
            return error;
          },
        ),
      ],
    );
  }

  String? _validateGender(String? value) {
    if (value == null) {
      return 'Please select your gender';
    }
    return null;
  }

  // Helper method to ensure the gender value is valid for the dropdown
  String? _getValidGenderValue(String? value) {
    if (value == null) return null;
    
    // Normalize the value to match dropdown options
    final normalizedValue = value.toLowerCase().trim();
    
    switch (normalizedValue) {
      case 'male':
      case 'm':
        return 'male';
      case 'female':
      case 'f':
        return 'female';
      case 'other':
      case 'non-binary':
      case 'nonbinary':
        return 'other';
      case 'prefer_not_to_say':
      case 'prefer not to say':
      case 'not specified':
        return 'prefer_not_to_say';
      default:
        // If the value doesn't match any known option, return null to show placeholder
        return null;
    }
  }
}class
 EnhancedHeightInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final String unit;
  final ValueChanged<String> onUnitChanged;
  final String? Function(String?)? validator;

  const EnhancedHeightInputWidget({
    super.key,
    required this.controller,
    required this.unit,
    required this.onUnitChanged,
    this.validator,
  });

  @override
  State<EnhancedHeightInputWidget> createState() => _EnhancedHeightInputWidgetState();
}

class _EnhancedHeightInputWidgetState extends State<EnhancedHeightInputWidget> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Height',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: widget.controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: InputDecoration(
                  hintText: UnitConversionHelper.getHeightHint(widget.unit),
                  prefixIcon: Icon(
                    Icons.height_outlined,
                    color: _hasError 
                        ? theme.colorScheme.error 
                        : theme.colorScheme.primary,
                  ),
                  suffixText: widget.unit,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outline.withOpacity( 0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: theme.colorScheme.error,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity( 0.3),
                  helperText: widget.unit == 'ft' ? 'Enter as decimal (e.g., 5.7)' : null,
                ),
                validator: (value) {
                  final error = widget.validator?.call(value) ?? 
                      UnitConversionHelper.validateHeight(value, widget.unit);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _hasError = error != null;
                      });
                    }
                  });
                  return error;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity( 0.5),
                  ),
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity( 0.3),
                ),
                child: DropdownButtonFormField<String>(
                  value: _getValidHeightUnit(widget.unit),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cm', child: Text('cm')),
                    DropdownMenuItem(value: 'ft', child: Text('ft')),
                  ],
                  onChanged: (value) {
                    if (value != null && value != widget.unit) {
                      _convertHeight(widget.unit, value);
                      widget.onUnitChanged(value);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _convertHeight(String fromUnit, String toUnit) {
    final currentValue = double.tryParse(widget.controller.text);
    if (currentValue != null) {
      final convertedValue = UnitConversionHelper.convertHeight(
        currentValue,
        fromUnit,
        toUnit,
      );
      widget.controller.text = convertedValue.toStringAsFixed(1);
    }
  }

  // Helper method to ensure the height unit is valid for the dropdown
  String _getValidHeightUnit(String unit) {
    switch (unit.toLowerCase()) {
      case 'cm':
      case 'centimeters':
      case 'centimeter':
        return 'cm';
      case 'ft':
      case 'feet':
      case 'foot':
        return 'ft';
      default:
        return 'cm'; // Default to cm if unknown unit
    }
  }
}

class EnhancedWeightInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final String unit;
  final ValueChanged<String> onUnitChanged;
  final String? Function(String?)? validator;

  const EnhancedWeightInputWidget({
    super.key,
    required this.controller,
    required this.unit,
    required this.onUnitChanged,
    this.validator,
  });

  @override
  State<EnhancedWeightInputWidget> createState() => _EnhancedWeightInputWidgetState();
}

class _EnhancedWeightInputWidgetState extends State<EnhancedWeightInputWidget> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weight',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: widget.controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: InputDecoration(
                  hintText: UnitConversionHelper.getWeightHint(widget.unit),
                  prefixIcon: Icon(
                    Icons.monitor_weight_outlined,
                    color: _hasError 
                        ? theme.colorScheme.error 
                        : theme.colorScheme.primary,
                  ),
                  suffixText: widget.unit,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outline.withOpacity( 0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: theme.colorScheme.error,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity( 0.3),
                ),
                validator: (value) {
                  final error = widget.validator?.call(value) ?? 
                      UnitConversionHelper.validateWeight(value, widget.unit);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _hasError = error != null;
                      });
                    }
                  });
                  return error;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity( 0.5),
                  ),
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity( 0.3),
                ),
                child: DropdownButtonFormField<String>(
                  value: _getValidWeightUnit(widget.unit),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'kg', child: Text('kg')),
                    DropdownMenuItem(value: 'lbs', child: Text('lbs')),
                  ],
                  onChanged: (value) {
                    if (value != null && value != widget.unit) {
                      _convertWeight(widget.unit, value);
                      widget.onUnitChanged(value);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _convertWeight(String fromUnit, String toUnit) {
    final currentValue = double.tryParse(widget.controller.text);
    if (currentValue != null) {
      final convertedValue = UnitConversionHelper.convertWeight(
        currentValue,
        fromUnit,
        toUnit,
      );
      widget.controller.text = convertedValue.toStringAsFixed(1);
    }
  }

  // Helper method to ensure the weight unit is valid for the dropdown
  String _getValidWeightUnit(String unit) {
    switch (unit.toLowerCase()) {
      case 'kg':
      case 'kilograms':
      case 'kilogram':
        return 'kg';
      case 'lbs':
      case 'lb':
      case 'pounds':
      case 'pound':
        return 'lbs';
      default:
        return 'kg'; // Default to kg if unknown unit
    }
  }
}