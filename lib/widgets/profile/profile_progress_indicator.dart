import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_profile.dart';
import '../../services/profile_service.dart';

class ProfileProgressIndicator extends ConsumerWidget {
  final UserProfile profile;

  const ProfileProgressIndicator({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileService = ref.read(profileServiceProvider);
    final completionPercentage = profileService.calculateProfileCompletion(profile);
    final sectionStatus = profileService.getProfileSectionStatus(profile);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Profile Completion',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${(completionPercentage * 100).round()}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Overall progress bar
          LinearProgressIndicator(
            value: completionPercentage,
            backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Section breakdown
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sectionStatus.entries.map((entry) {
              final sectionName = entry.key;
              final status = entry.value;
              
              return _buildSectionChip(
                context,
                sectionName,
                status.completionPercentage,
                status.isComplete,
              );
            }).toList(),
          ),
          
          if (completionPercentage < 1.0) ...[
            const SizedBox(height: 12),
            Text(
              _getCompletionMessage(completionPercentage),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionChip(
    BuildContext context,
    String sectionName,
    double completionPercentage,
    bool isComplete,
  ) {
    final color = isComplete
        ? Theme.of(context).colorScheme.primary
        : completionPercentage > 0.5
            ? Colors.orange
            : Theme.of(context).colorScheme.outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            sectionName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getCompletionMessage(double completionPercentage) {
    if (completionPercentage < 0.25) {
      return 'Complete your basic information to get personalized workout recommendations.';
    } else if (completionPercentage < 0.5) {
      return 'Add your fitness goals and preferences for better workout suggestions.';
    } else if (completionPercentage < 0.75) {
      return 'Almost there! Complete your health and nutrition information.';
    } else {
      return 'Just a few more details to complete your profile!';
    }
  }
}

class ProfileCompletionCard extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback? onTap;

  const ProfileCompletionCard({
    super.key,
    required this.profile,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final completionPercentage = profile.profileCompletionPercentage;
    
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Profile Setup',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(completionPercentage * 100).round()}%',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              LinearProgressIndicator(
                value: completionPercentage,
                backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                completionPercentage == 1.0
                    ? 'Profile complete! You\'re ready to start your fitness journey.'
                    : 'Complete your profile to get personalized workout recommendations.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}