import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'exercise_collection.g.dart';

@JsonSerializable()
@HiveType(typeId: 11)
class ExerciseCollection extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  @JsonKey(name: 'user_id')
  final String userId;
  
  @HiveField(2)
  final String name;
  
  @HiveField(3)
  final String? description;
  
  @HiveField(4)
  @JsonKey(name: 'exercise_ids')
  final List<String> exerciseIds;
  
  @HiveField(5)
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @HiveField(6)
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  
  @HiveField(7)
  @JsonKey(name: 'is_public')
  final bool isPublic;
  
  @HiveField(8)
  final String? color;
  
  @HiveField(9)
  final String? icon;

  ExerciseCollection({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.exerciseIds,
    required this.createdAt,
    required this.updatedAt,
    this.isPublic = false,
    this.color,
    this.icon,
  });

  factory ExerciseCollection.fromJson(Map<String, dynamic> json) => 
      _$ExerciseCollectionFromJson(json);

  Map<String, dynamic> toJson() => _$ExerciseCollectionToJson(this);

  ExerciseCollection copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    List<String>? exerciseIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPublic,
    String? color,
    String? icon,
  }) {
    return ExerciseCollection(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      exerciseIds: exerciseIds ?? this.exerciseIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPublic: isPublic ?? this.isPublic,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }

  int get exerciseCount => exerciseIds.length;
  
  bool get isEmpty => exerciseIds.isEmpty;
  
  bool containsExercise(String exerciseId) => exerciseIds.contains(exerciseId);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExerciseCollection &&
        other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.description == description &&
        _listEquals(other.exerciseIds, exerciseIds) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isPublic == isPublic &&
        other.color == color &&
        other.icon == icon;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      name,
      description,
      Object.hashAll(exerciseIds),
      createdAt,
      updatedAt,
      isPublic,
      color,
      icon,
    );
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}