import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/onboarding_provider.dart';
import '../providers/auth_provider.dart';
import '../models/onboarding_state.dart';
import '../widgets/onboarding/onboarding_progress_indicator.dart';
import '../widgets/onboarding/onboarding_navigation_bar.dart';
import 'onboarding/personal_info_screen.dart';
import 'onboarding/fitness_goals_screen.dart';
import 'onboarding/fitness_level_screen.dart';
import 'onboarding/equipment_selection_screen.dart';
import 'onboarding/workout_preferences_screen.dart';

class OnboardingPageView extends ConsumerStatefulWidget {
  const OnboardingPageView({super.key});

  @override
  ConsumerState<OnboardingPageView> createState() => _OnboardingPageViewState();
}

class _OnboardingPageViewState extends ConsumerState<OnboardingPageView>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressAnimationController;
  late AnimationController _pageTransitionController;
  late Animation<double> _progressAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  static const String _resumeOnboardingKey = 'resume_onboarding_available';
  bool _hasResumeData = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _checkResumeData();
  }

  void _initializeControllers() {
    _pageController = PageController();
    
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _pageTransitionController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
      value: 1.0, // Start with content visible
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOutCubic,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _pageTransitionController,
      curve: Curves.easeInOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pageTransitionController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _checkResumeData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasResumeData = prefs.getBool(_resumeOnboardingKey) ?? false;
      if (mounted) {
        setState(() {
          _hasResumeData = hasResumeData;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressAnimationController.dispose();
    _pageTransitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingProvider);
    final onboardingNotifier = ref.read(onboardingProvider.notifier);
    final isCurrentStepValid = ref.watch(currentStepValidProvider);

    // Update page controller when state changes with smooth transitions
    ref.listen<OnboardingState>(onboardingProvider, (previous, next) {
      if (previous?.currentStep != next.currentStep) {
        _animateToPage(next.currentStep);
        _updateProgressAnimation(next.progress);
        _saveResumeData();
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: onboardingState.canGoBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => onboardingNotifier.previousStep(),
              )
            : null,
        actions: [
          // Resume button if data is available
          if (_hasResumeData && onboardingState.currentStep == 0)
            TextButton.icon(
              onPressed: () => _showResumeDialog(context, onboardingNotifier),
              icon: const Icon(Icons.restore, size: 18),
              label: const Text('Resume'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          // Profile data indicator
          if (onboardingState.currentStep == 0)
            Consumer(
              builder: (context, ref, child) {
                final hasExistingData = ref.watch(hasExistingProfileDataProvider);
                final profileCompletion = ref.watch(profileCompletionProvider);
                
                if (hasExistingData) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(profileCompletion * 100).round()}% complete',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          if (onboardingState.canSkip)
            TextButton(
              onPressed: () => _showSkipDialog(context, onboardingNotifier),
              child: Text(
                'Skip',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: OnboardingProgressIndicator(
              currentStep: onboardingState.currentStep,
              totalSteps: onboardingState.totalSteps,
              animation: _progressAnimation,
            ),
          ),
          
          // Page content with enhanced transitions
          Expanded(
            child: AnimatedBuilder(
              animation: _pageTransitionController,
              builder: (context, child) {
                return SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(), // Disable swipe navigation
                      children: const [
                        PersonalInfoScreen(),
                        FitnessGoalsScreen(),
                        FitnessLevelScreen(),
                        EquipmentSelectionScreen(),
                        WorkoutPreferencesScreen(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Navigation bar
          OnboardingNavigationBar(
            canGoBack: onboardingState.canGoBack,
            canGoNext: onboardingState.canGoNext && isCurrentStepValid,
            isLastStep: onboardingState.isLastStep,
            onBack: () => onboardingNotifier.previousStep(),
            onNext: () => _handleNext(onboardingNotifier),
            onComplete: () => _handleComplete(onboardingNotifier),
          ),
        ],
      ),
    );
  }

  void _updateProgressAnimation(double progress) {
    _progressAnimationController.animateTo(progress);
  }

  Future<void> _animateToPage(int page) async {
    // Start page transition animation
    _pageTransitionController.reset();
    _pageTransitionController.forward();
    
    // Animate to the new page
    await _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _saveResumeData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_resumeOnboardingKey, true);
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _clearResumeData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_resumeOnboardingKey);
      if (mounted) {
        setState(() {
          _hasResumeData = false;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _handleNext(OnboardingNotifier notifier) {
    notifier.nextStep();
  }

  void _handleComplete(OnboardingNotifier notifier) async {
    await _clearResumeData();
    if (mounted) {
      context.go('/onboarding/complete');
    }
  }

  void _showSkipDialog(BuildContext context, OnboardingNotifier notifier) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.skip_next_outlined,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Skip Onboarding?'),
        content: const Text(
          'You can always complete your profile later in the settings. '
          'However, we recommend completing the onboarding for a better experience.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _clearResumeData();
              await notifier.skipOnboarding();
              if (mounted) {
                context.go('/home');
              }
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  void _showResumeDialog(BuildContext context, OnboardingNotifier notifier) {
    final userProfile = ref.read(userProfileProvider);
    final hasExistingProfile = userProfile != null && 
        (userProfile.displayName?.isNotEmpty == true || 
         userProfile.age != null || 
         userProfile.fitnessGoalsArray?.isNotEmpty == true);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.restore,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Resume Onboarding?'),
        content: Text(
          hasExistingProfile 
            ? 'We found your previous onboarding progress and existing profile data. Would you like to continue where you left off?'
            : 'We found your previous onboarding progress. Would you like to continue where you left off?',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _clearResumeData();
              await notifier.resetOnboarding();
            },
            child: const Text('Start Over'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Refresh data from profile before resuming
              await notifier.refreshFromProfile();
              // Trigger a page animation to the current step
              final onboardingState = ref.read(onboardingProvider);
              if (onboardingState.currentStep > 0) {
                _animateToPage(onboardingState.currentStep);
                _updateProgressAnimation(onboardingState.progress);
              }
            },
            child: const Text('Resume'),
          ),
        ],
      ),
    );
  }
}