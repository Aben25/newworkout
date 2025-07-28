import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Enhanced multi-select chip widget with animations and feedback
class AnimatedMultiSelectChips extends StatefulWidget {
  final List<Map<String, dynamic>> options;
  final List<String> selectedValues;
  final ValueChanged<List<String>> onSelectionChanged;
  final String title;
  final String? subtitle;
  final int maxSelections;
  final bool allowReordering;

  const AnimatedMultiSelectChips({
    super.key,
    required this.options,
    required this.selectedValues,
    required this.onSelectionChanged,
    required this.title,
    this.subtitle,
    this.maxSelections = -1, // -1 means no limit
    this.allowReordering = false,
  });

  @override
  State<AnimatedMultiSelectChips> createState() => _AnimatedMultiSelectChipsState();
}

class _AnimatedMultiSelectChipsState extends State<AnimatedMultiSelectChips>
    with TickerProviderStateMixin {
  late AnimationController _selectionAnimationController;
  late AnimationController _pulseAnimationController;
  String? _lastSelectedId;

  @override
  void initState() {
    super.initState();
    _selectionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _selectionAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  void _toggleSelection(String id) {
    final newSelection = List<String>.from(widget.selectedValues);
    
    if (newSelection.contains(id)) {
      newSelection.remove(id);
      _triggerDeselectionFeedback();
    } else {
      if (widget.maxSelections > 0 && newSelection.length >= widget.maxSelections) {
        _triggerMaxSelectionFeedback();
        return;
      }
      newSelection.add(id);
      _lastSelectedId = id;
      _triggerSelectionFeedback();
    }
    
    widget.onSelectionChanged(newSelection);
  }

  void _triggerSelectionFeedback() {
    HapticFeedback.lightImpact();
    _selectionAnimationController.forward().then((_) {
      _selectionAnimationController.reset();
    });
  }

  void _triggerDeselectionFeedback() {
    HapticFeedback.selectionClick();
  }

  void _triggerMaxSelectionFeedback() {
    HapticFeedback.heavyImpact();
    _pulseAnimationController.forward().then((_) {
      _pulseAnimationController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          widget.title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 16),

        // Selection counter
        if (widget.maxSelections > 0) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity( 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${widget.selectedValues.length}/${widget.maxSelections} selected',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Chips grid
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: widget.options.map((option) {
            final id = option['id'] as String;
            final isSelected = widget.selectedValues.contains(id);
            final isLastSelected = _lastSelectedId == id;

            return AnimatedBuilder(
              animation: _selectionAnimationController,
              builder: (context, child) {
                final scale = isLastSelected
                    ? 1.0 + (_selectionAnimationController.value * 0.1)
                    : 1.0;

                return AnimatedBuilder(
                  animation: _pulseAnimationController,
                  builder: (context, child) {
                    final pulseScale = widget.maxSelections > 0 &&
                            widget.selectedValues.length >= widget.maxSelections &&
                            !isSelected
                        ? 1.0 + (_pulseAnimationController.value * 0.05)
                        : 1.0;

                    return Transform.scale(
                      scale: scale * pulseScale,
                      child: _buildEnhancedChip(option, isSelected, theme),
                    );
                  },
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEnhancedChip(Map<String, dynamic> option, bool isSelected, ThemeData theme) {
    final id = option['id'] as String;
    final title = option['title'] as String;
    final description = option['description'] as String?;
    final icon = option['icon'] as IconData?;
    final color = option['color'] as Color? ?? theme.colorScheme.primary;

    final isDisabled = widget.maxSelections > 0 &&
        widget.selectedValues.length >= widget.maxSelections &&
        !isSelected;

    return GestureDetector(
      onTap: isDisabled ? null : () => _toggleSelection(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    color.withOpacity( 0.2),
                    color.withOpacity( 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected
              ? null
              : isDisabled
                  ? theme.colorScheme.surfaceContainerHighest.withOpacity( 0.5)
                  : theme.colorScheme.surface,
          border: Border.all(
            color: isSelected
                ? color
                : isDisabled
                    ? theme.colorScheme.outline.withOpacity( 0.3)
                    : theme.colorScheme.outline.withOpacity( 0.5),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity( 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity( 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with animation
            if (icon != null) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity( 0.2)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isSelected
                      ? color
                      : isDisabled
                          ? theme.colorScheme.onSurfaceVariant.withOpacity( 0.5)
                          : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Title
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? color
                    : isDisabled
                        ? theme.colorScheme.onSurfaceVariant.withOpacity( 0.5)
                        : theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            // Description
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? color.withOpacity( 0.8)
                      : isDisabled
                          ? theme.colorScheme.onSurfaceVariant.withOpacity( 0.4)
                          : theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Selection indicator
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Selected',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Container(
                      height: 20,
                      width: 20,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDisabled
                              ? theme.colorScheme.outline.withOpacity( 0.3)
                              : theme.colorScheme.outline,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Enhanced slider widget with visual feedback and descriptive labels
class EnhancedLevelSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final String title;
  final String? subtitle;
  final List<Map<String, dynamic>> levelDescriptions;
  final Color? activeColor;

  const EnhancedLevelSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.subtitle,
    required this.levelDescriptions,
    this.activeColor,
  });

  @override
  State<EnhancedLevelSlider> createState() => _EnhancedLevelSliderState();
}

class _EnhancedLevelSliderState extends State<EnhancedLevelSlider>
    with TickerProviderStateMixin {
  late AnimationController _changeAnimationController;

  @override
  void initState() {
    super.initState();
    _changeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _changeAnimationController.dispose();
    super.dispose();
  }

  void _onSliderChanged(double value) {
    HapticFeedback.selectionClick();
    _changeAnimationController.forward().then((_) {
      _changeAnimationController.reset();
    });
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentIndex = (widget.value - 1).round();
    final currentLevel = widget.levelDescriptions[currentIndex];
    final activeColor = widget.activeColor ?? currentLevel['color'] as Color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          widget.title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 20),

        // Current level indicator
        AnimatedBuilder(
          animation: _changeAnimationController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_changeAnimationController.value * 0.02),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      activeColor.withOpacity( 0.2),
                      activeColor.withOpacity( 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: activeColor.withOpacity( 0.4),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      currentLevel['icon'],
                      size: 32,
                      color: activeColor,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentLevel['title'],
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: activeColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentLevel['description'] ?? '',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        // Enhanced slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 8,
            thumbShape: RoundSliderThumbShape(
              enabledThumbRadius: 14,
              elevation: 4,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            activeTrackColor: activeColor,
            thumbColor: activeColor,
            overlayColor: activeColor.withOpacity( 0.2),
            tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 3),
            activeTickMarkColor: activeColor,
            inactiveTickMarkColor: theme.colorScheme.outline.withOpacity( 0.3),
          ),
          child: Slider(
            value: widget.value,
            min: 1,
            max: widget.levelDescriptions.length.toDouble(),
            divisions: widget.levelDescriptions.length - 1,
            onChanged: _onSliderChanged,
            inactiveColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),

        // Level labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: widget.levelDescriptions.asMap().entries.map((entry) {
              final index = entry.key;
              final level = entry.value;
              final isActive = index == currentIndex;
              final levelColor = level['color'] as Color;

              return Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? levelColor.withOpacity( 0.2)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isActive
                          ? Border.all(
                              color: levelColor.withOpacity( 0.5),
                            )
                          : null,
                    ),
                    child: Icon(
                      level['icon'],
                      size: 16,
                      color: isActive
                          ? levelColor
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    level['title'],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isActive
                          ? levelColor
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}