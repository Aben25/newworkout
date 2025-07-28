// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_state.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OnboardingStateAdapter extends TypeAdapter<OnboardingState> {
  @override
  final int typeId = 12;

  @override
  OnboardingState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OnboardingState(
      currentStep: fields[0] as int,
      totalSteps: fields[1] as int,
      isCompleted: fields[2] as bool,
      stepData: (fields[3] as Map).cast<String, dynamic>(),
      lastUpdated: fields[4] as DateTime?,
      canSkip: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, OnboardingState obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.currentStep)
      ..writeByte(1)
      ..write(obj.totalSteps)
      ..writeByte(2)
      ..write(obj.isCompleted)
      ..writeByte(3)
      ..write(obj.stepData)
      ..writeByte(4)
      ..write(obj.lastUpdated)
      ..writeByte(5)
      ..write(obj.canSkip);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OnboardingStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OnboardingState _$OnboardingStateFromJson(Map<String, dynamic> json) =>
    OnboardingState(
      currentStep: (json['currentStep'] as num?)?.toInt() ?? 0,
      totalSteps: (json['totalSteps'] as num?)?.toInt() ?? 5,
      isCompleted: json['isCompleted'] as bool? ?? false,
      stepData: json['stepData'] as Map<String, dynamic>? ?? const {},
      lastUpdated: json['lastUpdated'] == null
          ? null
          : DateTime.parse(json['lastUpdated'] as String),
      canSkip: json['canSkip'] as bool? ?? true,
    );

Map<String, dynamic> _$OnboardingStateToJson(OnboardingState instance) =>
    <String, dynamic>{
      'currentStep': instance.currentStep,
      'totalSteps': instance.totalSteps,
      'isCompleted': instance.isCompleted,
      'stepData': instance.stepData,
      'lastUpdated': instance.lastUpdated?.toIso8601String(),
      'canSkip': instance.canSkip,
    };
