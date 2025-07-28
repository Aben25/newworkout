import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/onboarding_provider.dart';
import '../../providers/auth_provider.dart';

class OnboardingCompleteScreen extends ConsumerStatefulWidget {
  const OnboardingCompleteScreen({super.key});

  @override
  ConsumerState<OnboardingCompleteScreen> createState() => _OnboardingCompleteScreenState();
}

class _OnboardingCompleteScreenState extends ConsumerState<OnboardingCompleteScreen>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  bool _isCompleting = false;
  String _completionMessage = '';

  @override
  void initState() {
    super.initState();
    
    _celebrationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    // Start animations
    _celebrationController.forward();
    _fadeController.forward();
    
    // Generate personalized message
    _generatePersonalizedMessage();
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _generatePersonalizedMessage() {
    final onboardingState = ref.read(onboardingProvider);
    final stepData = onboardingState.stepData;
    
    final name = stepData['displayName']?.toString() ?? 'there';
    final goals = stepData['fitnessGoals'] as List<String>? ?? [];
    final equipment = stepData['equipment'] as List<String>? ?? [];
    
    String message = 'Welcome to your fitness journey, $name! ';
    
    if (goals.isNotEmpty) {
      final primaryGoal = goals.first.replaceAll('_', ' ').toLowerCase();
      message += 'We\'re excited to help you $primaryGoal. ';
    }
    
    if (equipment.contains('none')) {
      message += 'We\'ve prepared bodyweight workouts perfect for you. ';
    } else if (equipment.isNotEmpty) {
      message += 'We\'ve customized workouts based on your available equipment. ';
    }
    
    message += 'Let\'s get started!';
    
    setState(() {
      _completionMessage = message;
    });
  }

  Future<void> _completeOnboarding() async {
    if (_isCompleting) return;
    
    setState(() {
      _isCompleting = true;
    });

    try {
      final onboardingNotifier = ref.read(onboardingProvider.notifier);
      final authState = ref.read(authProvider);
      
      if (authState.user == null) {
        throw Exception('User not authenticated');
      }

      // Complete onboarding and persist data to Supabase
      await onboardingNotifier.completeOnboardingWithPersistence(authState.user!.id);
      
      // Navigate to home screen
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to complete onboarding. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        
                        // Celebration Animation
                        SizedBox(
                          height: 200,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Success Icon with Animation
                              AnimatedBuilder(
                                animation: _celebrationController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: 1.0 + (_celebrationController.value * 0.2),
                                    child: Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                            blurRadius: 20,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.check,
                                        size: 60,
                                        color: theme.colorScheme.onPrimary,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Completion Title
                        Text(
                          'Congratulations!',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Text(
                          'Your profile is complete',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Personalized Message
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            _completionMessage,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Action Buttons
                Column(
                  children: [
                    // Complete Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isCompleting ? null : _completeOnboarding,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isCompleting
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        theme.colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Setting up your profile...',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Start Your Fitness Journey',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward,
                                    size: 20,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ],
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Skip to Home Button
                    TextButton(
                      onPressed: _isCompleting ? null : () => context.go('/home'),
                      child: Text(
                        'Skip for now',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}