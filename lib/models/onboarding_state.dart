import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'onboarding_state.g.dart';

@JsonSerializable()
@HiveType(typeId: 12)
class OnboardingState extends HiveObject {
  @HiveField(0)
  final int currentStep;
  
  @HiveField(1)
  final int totalSteps;
  
  @HiveField(2)
  final bool isCompleted;
  
  @HiveField(3)
  final Map<String, dynamic> stepData;
  
  @HiveField(4)
  final DateTime? lastUpdated;
  
  @HiveField(5)
  final bool canSkip;

  OnboardingState({
    this.currentStep = 0,
    this.totalSteps = 5,
    this.isCompleted = false,
    this.stepData = const {},
    this.lastUpdated,
    this.canSkip = true,
  });

  factory OnboardingState.fromJson(Map<String, dynamic> json) =>
      _$OnboardingStateFromJson(json);

  Map<String, dynamic> toJson() => _$OnboardingStateToJson(this);

  OnboardingState copyWith({
    int? currentStep,
    int? totalSteps,
    bool? isCompleted,
    Map<String, dynamic>? stepData,
    DateTime? lastUpdated,
    bool? canSkip,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      isCompleted: isCompleted ?? this.isCompleted,
      stepData: stepData ?? Map<String, dynamic>.from(this.stepData),
      lastUpdated: lastUpdated ?? this.lastUpdated,
      canSkip: canSkip ?? this.canSkip,
    );
  }

  double get progress => currentStep / totalSteps;
  
  bool get isFirstStep => currentStep == 0;
  
  bool get isLastStep => currentStep >= totalSteps - 1;
  
  bool get canGoNext => currentStep < totalSteps - 1;
  
  bool get canGoBack => currentStep > 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OnboardingState &&
        other.currentStep == currentStep &&
        other.totalSteps == totalSteps &&
        other.isCompleted == isCompleted &&
        other.canSkip == canSkip;
  }

  @override
  int get hashCode {
    return Object.hash(
      currentStep,
      totalSteps,
      isCompleted,
      canSkip,
    );
  }
}

enum OnboardingStep {
  personalInfo,
  fitnessGoals,
  fitnessLevel,
  equipment,
  preferences,
}

extension OnboardingStepExtension on OnboardingStep {
  String get title {
    switch (this) {
      case OnboardingStep.personalInfo:
        return 'Personal Information';
      case OnboardingStep.fitnessGoals:
        return 'Fitness Goals';
      case OnboardingStep.fitnessLevel:
        return 'Fitness Level';
      case OnboardingStep.equipment:
        return 'Equipment';
      case OnboardingStep.preferences:
        return 'Preferences';
    }
  }

  String get description {
    switch (this) {
      case OnboardingStep.personalInfo:
        return 'Tell us about yourself';
      case OnboardingStep.fitnessGoals:
        return 'What are your fitness goals?';
      case OnboardingStep.fitnessLevel:
        return 'What\'s your current fitness level?';
      case OnboardingStep.equipment:
        return 'What equipment do you have access to?';
      case OnboardingStep.preferences:
        return 'Set your workout preferences';
    }
  }

  int get index {
    switch (this) {
      case OnboardingStep.personalInfo:
        return 0;
      case OnboardingStep.fitnessGoals:
        return 1;
      case OnboardingStep.fitnessLevel:
        return 2;
      case OnboardingStep.equipment:
        return 3;
      case OnboardingStep.preferences:
        return 4;
    }
  }

  static OnboardingStep fromIndex(int index) {
    switch (index) {
      case 0:
        return OnboardingStep.personalInfo;
      case 1:
        return OnboardingStep.fitnessGoals;
      case 2:
        return OnboardingStep.fitnessLevel;
      case 3:
        return OnboardingStep.equipment;
      case 4:
        return OnboardingStep.preferences;
      default:
        return OnboardingStep.personalInfo;
    }
  }
}