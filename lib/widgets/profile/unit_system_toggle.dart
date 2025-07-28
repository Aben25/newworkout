import 'package:flutter/material.dart';

class UnitSystemToggle extends StatelessWidget {
  final String heightUnit;
  final String weightUnit;
  final Function(String)? onHeightUnitChanged;
  final Function(String)? onWeightUnitChanged;

  const UnitSystemToggle({
    super.key,
    required this.heightUnit,
    required this.weightUnit,
    this.onHeightUnitChanged,
    this.onWeightUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Unit System',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Quick toggle buttons for common unit systems
        Row(
          children: [
            Expanded(
              child: _buildUnitSystemCard(
                context,
                title: 'Metric',
                subtitle: 'cm, kg',
                isSelected: heightUnit == 'cm' && weightUnit == 'kg',
                onTap: () {
                  onHeightUnitChanged?.call('cm');
                  onWeightUnitChanged?.call('kg');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildUnitSystemCard(
                context,
                title: 'Imperial',
                subtitle: 'ft, lbs',
                isSelected: heightUnit == 'ft' && weightUnit == 'lbs',
                onTap: () {
                  onHeightUnitChanged?.call('ft');
                  onWeightUnitChanged?.call('lbs');
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Individual unit controls
        Text(
          'Individual Units',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Height Unit',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(
                        value: 'cm',
                        label: Text('cm'),
                      ),
                      ButtonSegment<String>(
                        value: 'ft',
                        label: Text('ft'),
                      ),
                    ],
                    selected: {heightUnit},
                    onSelectionChanged: onHeightUnitChanged != null
                        ? (Set<String> selection) {
                            onHeightUnitChanged!(selection.first);
                          }
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weight Unit',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(
                        value: 'kg',
                        label: Text('kg'),
                      ),
                      ButtonSegment<String>(
                        value: 'lbs',
                        label: Text('lbs'),
                      ),
                    ],
                    selected: {weightUnit},
                    onSelectionChanged: onWeightUnitChanged != null
                        ? (Set<String> selection) {
                            onWeightUnitChanged!(selection.first);
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Unit conversion info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your existing measurements will be automatically converted when you change units.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnitSystemCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback? onTap,
  }) {
    return Card(
      elevation: isSelected ? 2 : 0,
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UnitConverter extends StatelessWidget {
  final double? value;
  final String fromUnit;
  final String toUnit;
  final String type; // 'height' or 'weight'

  const UnitConverter({
    super.key,
    required this.value,
    required this.fromUnit,
    required this.toUnit,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    if (value == null || fromUnit == toUnit) {
      return const SizedBox.shrink();
    }

    final convertedValue = _convertValue(value!, fromUnit, toUnit, type);
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '≈ ${_formatValue(convertedValue, toUnit, type)}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  double _convertValue(double value, String fromUnit, String toUnit, String type) {
    if (type == 'height') {
      if (fromUnit == 'cm' && toUnit == 'ft') {
        return value / 30.48;
      } else if (fromUnit == 'ft' && toUnit == 'cm') {
        return value * 30.48;
      }
    } else if (type == 'weight') {
      if (fromUnit == 'kg' && toUnit == 'lbs') {
        return value * 2.20462;
      } else if (fromUnit == 'lbs' && toUnit == 'kg') {
        return value / 2.20462;
      }
    }
    return value;
  }

  String _formatValue(double value, String unit, String type) {
    if (type == 'height' && unit == 'ft') {
      final feet = value.floor();
      final inches = ((value - feet) * 12).round();
      return '$feet\'$inches"';
    } else {
      return '${value.toStringAsFixed(1)} $unit';
    }
  }
}