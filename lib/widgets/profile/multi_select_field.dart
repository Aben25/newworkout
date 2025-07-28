import 'package:flutter/material.dart';

class MultiSelectField extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<String> options;
  final List<String> selectedValues;
  final Function(List<String>)? onChanged;
  final bool enabled;
  final int? maxSelections;
  final bool allowCustomInput;
  final IconData? icon;

  const MultiSelectField({
    super.key,
    required this.title,
    this.subtitle,
    required this.options,
    required this.selectedValues,
    this.onChanged,
    this.enabled = true,
    this.maxSelections,
    this.allowCustomInput = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (maxSelections != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${selectedValues.length}/$maxSelections',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        
        const SizedBox(height: 12),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...options.map((option) => _buildOptionChip(context, option)),
            if (allowCustomInput && enabled)
              _buildAddCustomChip(context),
          ],
        ),
        
        if (selectedValues.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Selected: ${selectedValues.join(', ')}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOptionChip(BuildContext context, String option) {
    final isSelected = selectedValues.contains(option);
    final canSelect = enabled && (maxSelections == null || 
                                 selectedValues.length < maxSelections! || 
                                 isSelected);

    return FilterChip(
      label: Text(option),
      selected: isSelected,
      onSelected: canSelect ? (selected) {
        if (onChanged != null) {
          final newValues = List<String>.from(selectedValues);
          if (selected) {
            newValues.add(option);
          } else {
            newValues.remove(option);
          }
          onChanged!(newValues);
        }
      } : null,
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : Theme.of(context).colorScheme.onSurface,
      ),
      side: BorderSide(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outline,
      ),
    );
  }

  Widget _buildAddCustomChip(BuildContext context) {
    return ActionChip(
      label: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add, size: 16),
          SizedBox(width: 4),
          Text('Add Custom'),
        ],
      ),
      onPressed: () => _showAddCustomDialog(context),
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
    );
  }

  void _showAddCustomDialog(BuildContext context) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Custom $title'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Enter custom value',
            hintText: 'Type your custom option...',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final customValue = controller.text.trim();
              if (customValue.isNotEmpty && 
                  !options.contains(customValue) && 
                  !selectedValues.contains(customValue)) {
                final newValues = List<String>.from(selectedValues);
                newValues.add(customValue);
                onChanged?.call(newValues);
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class SingleSelectField extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<String> options;
  final String? selectedValue;
  final Function(String?)? onChanged;
  final bool enabled;
  final IconData? icon;
  final String? hint;

  const SingleSelectField({
    super.key,
    required this.title,
    this.subtitle,
    required this.options,
    this.selectedValue,
    this.onChanged,
    this.enabled = true,
    this.icon,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          
          const SizedBox(height: 12),
        ],
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedValue == option;
            
            return ChoiceChip(
              label: Text(option),
              selected: isSelected,
              onSelected: enabled ? (selected) {
                if (onChanged != null) {
                  onChanged!(selected ? option : null);
                }
              } : null,
              backgroundColor: Theme.of(context).colorScheme.surface,
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurface,
              ),
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class RangeSelectField extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double min;
  final double max;
  final double? value;
  final Function(double)? onChanged;
  final bool enabled;
  final int divisions;
  final String Function(double)? labelFormatter;
  final IconData? icon;

  const RangeSelectField({
    super.key,
    required this.title,
    this.subtitle,
    required this.min,
    required this.max,
    this.value,
    this.onChanged,
    this.enabled = true,
    this.divisions = 10,
    this.labelFormatter,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final currentValue = value ?? min;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              labelFormatter?.call(currentValue) ?? currentValue.toStringAsFixed(1),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        
        const SizedBox(height: 8),
        
        Slider(
          value: currentValue,
          min: min,
          max: max,
          divisions: divisions,
          label: labelFormatter?.call(currentValue) ?? currentValue.toStringAsFixed(1),
          onChanged: enabled ? onChanged : null,
        ),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              labelFormatter?.call(min) ?? min.toStringAsFixed(1),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              labelFormatter?.call(max) ?? max.toStringAsFixed(1),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}