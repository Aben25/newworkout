import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'exercise_favorite.g.dart';

@JsonSerializable()
@HiveType(typeId: 10)
class ExerciseFavorite extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  @JsonKey(name: 'user_id')
  final String userId;
  
  @HiveField(2)
  @JsonKey(name: 'exercise_id')
  final String exerciseId;
  
  @HiveField(3)
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @HiveField(4)
  final String? notes;

  ExerciseFavorite({
    required this.id,
    required this.userId,
    required this.exerciseId,
    required this.createdAt,
    this.notes,
  });

  factory ExerciseFavorite.fromJson(Map<String, dynamic> json) => 
      _$ExerciseFavoriteFromJson(json);

  Map<String, dynamic> toJson() => _$ExerciseFavoriteToJson(this);

  ExerciseFavorite copyWith({
    String? id,
    String? userId,
    String? exerciseId,
    DateTime? createdAt,
    String? notes,
  }) {
    return ExerciseFavorite(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      exerciseId: exerciseId ?? this.exerciseId,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExerciseFavorite &&
        other.id == id &&
        other.userId == userId &&
        other.exerciseId == exerciseId &&
        other.createdAt == createdAt &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return Object.hash(id, userId, exerciseId, createdAt, notes);
  }
}