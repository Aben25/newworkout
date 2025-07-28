import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'exercise.g.dart';

@JsonSerializable()
@HiveType(typeId: 1)
class Exercise extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String? description;
  
  @HiveField(3)
  final String? instructions;
  
  @HiveField(4)
  @JsonKey(name: 'video_url')
  final String? videoUrl;
  
  @HiveField(5)
  @JsonKey(name: 'vertical_video')
  final String? verticalVideo;
  
  @HiveField(6)
  @JsonKey(name: 'primary_muscle')
  final String? primaryMuscle;
  
  @HiveField(7)
  @JsonKey(name: 'secondary_muscle')
  final String? secondaryMuscle;
  
  @HiveField(8)
  final String? equipment;
  
  @HiveField(9)
  final String? category;
  
  @HiveField(10)
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Exercise({
    required this.id,
    required this.name,
    this.description,
    this.instructions,
    this.videoUrl,
    this.verticalVideo,
    this.primaryMuscle,
    this.secondaryMuscle,
    this.equipment,
    this.category,
    required this.createdAt,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) => _$ExerciseFromJson(json);

  Map<String, dynamic> toJson() => _$ExerciseToJson(this);

  Exercise copyWith({
    String? id,
    String? name,
    String? description,
    String? instructions,
    String? videoUrl,
    String? verticalVideo,
    String? primaryMuscle,
    String? secondaryMuscle,
    String? equipment,
    String? category,
    DateTime? createdAt,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      videoUrl: videoUrl ?? this.videoUrl,
      verticalVideo: verticalVideo ?? this.verticalVideo,
      primaryMuscle: primaryMuscle ?? this.primaryMuscle,
      secondaryMuscle: secondaryMuscle ?? this.secondaryMuscle,
      equipment: equipment ?? this.equipment,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Exercise &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.instructions == instructions &&
        other.videoUrl == videoUrl &&
        other.verticalVideo == verticalVideo &&
        other.primaryMuscle == primaryMuscle &&
        other.secondaryMuscle == secondaryMuscle &&
        other.equipment == equipment &&
        other.category == category &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      instructions,
      videoUrl,
      verticalVideo,
      primaryMuscle,
      secondaryMuscle,
      equipment,
      category,
      createdAt,
    );
  }

  // Validation methods
  bool get hasVideo => videoUrl != null || verticalVideo != null;
  
  bool get hasInstructions => instructions != null && instructions!.isNotEmpty;
  
  bool get isComplete => name.isNotEmpty && 
                        primaryMuscle != null && 
                        equipment != null && 
                        category != null;

  // Helper methods for filtering
  List<String> get muscleGroups {
    final muscles = <String>[];
    if (primaryMuscle != null) muscles.add(primaryMuscle!);
    if (secondaryMuscle != null) muscles.add(secondaryMuscle!);
    return muscles;
  }

  bool matchesFilter({
    String? muscleGroup,
    String? equipmentType,
    String? categoryFilter,
  }) {
    if (muscleGroup != null && !muscleGroups.contains(muscleGroup)) {
      return false;
    }
    if (equipmentType != null && equipment != equipmentType) {
      return false;
    }
    if (categoryFilter != null && category != categoryFilter) {
      return false;
    }
    return true;
  }

  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return name.toLowerCase().contains(lowerQuery) ||
           (description?.toLowerCase().contains(lowerQuery) ?? false) ||
           (instructions?.toLowerCase().contains(lowerQuery) ?? false) ||
           (primaryMuscle?.toLowerCase().contains(lowerQuery) ?? false) ||
           (secondaryMuscle?.toLowerCase().contains(lowerQuery) ?? false);
  }
}