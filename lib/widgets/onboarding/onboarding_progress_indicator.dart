import 'package:flutter/material.dart';

class OnboardingProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Animation<double> animation;

  const OnboardingProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step indicator text
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step ${currentStep + 1} of $totalSteps',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${((currentStep / totalSteps) * 100).round()}%',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Progress bar with enhanced animations
        AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Column(
              children: [
                // Linear progress indicator with gradient
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        // Background
                        Container(
                          width: double.infinity,
                          height: 8,
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                        // Animated progress
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOutCubic,
                          width: MediaQuery.of(context).size.width * 
                                 (currentStep / totalSteps) * 0.85, // Account for padding
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.primary.withValues(alpha: 0.8),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Enhanced step dots indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    totalSteps,
                    (index) => _buildEnhancedStepDot(
                      context,
                      index,
                      currentStep,
                      animation.value,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }



  Widget _buildEnhancedStepDot(
    BuildContext context,
    int index,
    int currentStep,
    double animationValue,
  ) {
    final theme = Theme.of(context);
    final isCompleted = index < currentStep;
    final isCurrent = index == currentStep;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring for current step
          if (isCurrent)
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
            ),
          
          // Main dot
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
            width: isCompleted || isCurrent ? 24 : 16,
            height: isCompleted || isCurrent ? 24 : 16,
            decoration: BoxDecoration(
              color: isCompleted || isCurrent
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
              boxShadow: isCompleted || isCurrent
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: isCompleted
                ? Icon(
                    Icons.check,
                    size: 14,
                    color: theme.colorScheme.onPrimary,
                  )
                : isCurrent
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onPrimary,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
          ),
          
          // Pulse animation for current step
          if (isCurrent)
            AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Container(
                  width: 24 + (8 * animationValue),
                  height: 24 + (8 * animationValue),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withValues(
                      alpha: 0.1 * (1 - animationValue),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}