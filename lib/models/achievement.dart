import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'achievement.g.dart';

@JsonSerializable()
@HiveType(typeId: 14)
class Achievement extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String description;
  
  @HiveField(3)
  final String icon;
  
  @HiveField(4)
  final AchievementType type;
  
  @HiveField(5)
  final AchievementRarity rarity;
  
  @HiveField(6)
  final Map<String, dynamic> criteria;
  
  @HiveField(7)
  final int points;
  
  @HiveField(8)
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
    required this.rarity,
    required this.criteria,
    required this.points,
    required this.createdAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) => 
      _$AchievementFromJson(json);

  Map<String, dynamic> toJson() => _$AchievementToJson(this);

  Achievement copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    AchievementType? type,
    AchievementRarity? rarity,
    Map<String, dynamic>? criteria,
    int? points,
    DateTime? createdAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      rarity: rarity ?? this.rarity,
      criteria: criteria ?? this.criteria,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Achievement &&
        other.id == id &&
        other.name == name &&
        other.type == type &&
        other.rarity == rarity;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, type, rarity);
  }
}

@JsonSerializable()
@HiveType(typeId: 15)
class UserAchievement extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  @JsonKey(name: 'user_id')
  final String userId;
  
  @HiveField(2)
  @JsonKey(name: 'achievement_id')
  final String achievementId;
  
  @HiveField(3)
  @JsonKey(name: 'unlocked_at')
  final DateTime unlockedAt;
  
  @HiveField(4)
  @JsonKey(name: 'workout_id')
  final String? workoutId;
  
  @HiveField(5)
  final Map<String, dynamic>? metadata;
  
  @HiveField(6)
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  UserAchievement({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.unlockedAt,
    this.workoutId,
    this.metadata,
    required this.createdAt,
  });

  factory UserAchievement.fromJson(Map<String, dynamic> json) => 
      _$UserAchievementFromJson(json);

  Map<String, dynamic> toJson() => _$UserAchievementToJson(this);

  UserAchievement copyWith({
    String? id,
    String? userId,
    String? achievementId,
    DateTime? unlockedAt,
    String? workoutId,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return UserAchievement(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      achievementId: achievementId ?? this.achievementId,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      workoutId: workoutId ?? this.workoutId,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserAchievement &&
        other.id == id &&
        other.userId == userId &&
        other.achievementId == achievementId &&
        other.unlockedAt == unlockedAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, userId, achievementId, unlockedAt);
  }

  // Time-based analysis
  bool get isRecent => DateTime.now().difference(unlockedAt).inDays < 7;
  
  Duration get ageInDays => DateTime.now().difference(unlockedAt);

  // Formatting helpers
  String get formattedUnlockDate {
    final now = DateTime.now();
    final difference = now.difference(unlockedAt);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = difference.inDays ~/ 7;
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else {
      final months = difference.inDays ~/ 30;
      return '$months month${months > 1 ? 's' : ''} ago';
    }
  }
}

@HiveType(typeId: 37)
enum AchievementType {
  @HiveField(0)
  workout,
  
  @HiveField(1)
  strength,
  
  @HiveField(2)
  endurance,
  
  @HiveField(3)
  consistency,
  
  @HiveField(4)
  volume,
  
  @HiveField(5)
  personal_record,
  
  @HiveField(6)
  milestone,
  
  @HiveField(7)
  social,
}

@HiveType(typeId: 38)
enum AchievementRarity {
  @HiveField(0)
  common,
  
  @HiveField(1)
  uncommon,
  
  @HiveField(2)
  rare,
  
  @HiveField(3)
  epic,
  
  @HiveField(4)
  legendary,
}

extension AchievementTypeExtension on AchievementType {
  String get displayName {
    switch (this) {
      case AchievementType.workout:
        return 'Workout';
      case AchievementType.strength:
        return 'Strength';
      case AchievementType.endurance:
        return 'Endurance';
      case AchievementType.consistency:
        return 'Consistency';
      case AchievementType.volume:
        return 'Volume';
      case AchievementType.personal_record:
        return 'Personal Record';
      case AchievementType.milestone:
        return 'Milestone';
      case AchievementType.social:
        return 'Social';
    }
  }

  String get emoji {
    switch (this) {
      case AchievementType.workout:
        return '💪';
      case AchievementType.strength:
        return '🏋️';
      case AchievementType.endurance:
        return '🏃';
      case AchievementType.consistency:
        return '📅';
      case AchievementType.volume:
        return '📊';
      case AchievementType.personal_record:
        return '🏆';
      case AchievementType.milestone:
        return '🎯';
      case AchievementType.social:
        return '👥';
    }
  }
}

extension AchievementRarityExtension on AchievementRarity {
  String get displayName {
    switch (this) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.uncommon:
        return 'Uncommon';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
      case AchievementRarity.legendary:
        return 'Legendary';
    }
  }

  String get color {
    switch (this) {
      case AchievementRarity.common:
        return '#9E9E9E'; // Grey
      case AchievementRarity.uncommon:
        return '#4CAF50'; // Green
      case AchievementRarity.rare:
        return '#2196F3'; // Blue
      case AchievementRarity.epic:
        return '#9C27B0'; // Purple
      case AchievementRarity.legendary:
        return '#FF9800'; // Orange/Gold
    }
  }

  int get basePoints {
    switch (this) {
      case AchievementRarity.common:
        return 10;
      case AchievementRarity.uncommon:
        return 25;
      case AchievementRarity.rare:
        return 50;
      case AchievementRarity.epic:
        return 100;
      case AchievementRarity.legendary:
        return 250;
    }
  }
}

/// Predefined achievements for the workout tracker
class PredefinedAchievements {
  static final List<Achievement> achievements = [
    // Workout achievements
    Achievement(
      id: 'first_workout',
      name: 'First Steps',
      description: 'Complete your first workout',
      icon: '🎯',
      type: AchievementType.workout,
      rarity: AchievementRarity.common,
      criteria: {'workouts_completed': 1},
      points: 10,
      createdAt: DateTime.now(),
    ),
    Achievement(
      id: 'workout_streak_7',
      name: 'Week Warrior',
      description: 'Complete workouts for 7 consecutive days',
      icon: '🔥',
      type: AchievementType.consistency,
      rarity: AchievementRarity.uncommon,
      criteria: {'consecutive_days': 7},
      points: 50,
      createdAt: DateTime.now(),
    ),
    Achievement(
      id: 'workout_streak_30',
      name: 'Monthly Master',
      description: 'Complete workouts for 30 consecutive days',
      icon: '🏆',
      type: AchievementType.consistency,
      rarity: AchievementRarity.epic,
      criteria: {'consecutive_days': 30},
      points: 200,
      createdAt: DateTime.now(),
    ),
    
    // Volume achievements
    Achievement(
      id: 'volume_1000',
      name: 'Ton Lifter',
      description: 'Lift 1000kg in a single workout',
      icon: '🏋️',
      type: AchievementType.volume,
      rarity: AchievementRarity.rare,
      criteria: {'single_workout_volume': 1000},
      points: 75,
      createdAt: DateTime.now(),
    ),
    Achievement(
      id: 'volume_10000',
      name: 'Volume King',
      description: 'Lift 10,000kg total volume',
      icon: '👑',
      type: AchievementType.volume,
      rarity: AchievementRarity.legendary,
      criteria: {'total_volume': 10000},
      points: 300,
      createdAt: DateTime.now(),
    ),
    
    // Endurance achievements
    Achievement(
      id: 'long_workout_60',
      name: 'Endurance Warrior',
      description: 'Complete a workout lasting 60+ minutes',
      icon: '⏰',
      type: AchievementType.endurance,
      rarity: AchievementRarity.uncommon,
      criteria: {'workout_duration_minutes': 60},
      points: 30,
      createdAt: DateTime.now(),
    ),
    Achievement(
      id: 'long_workout_120',
      name: 'Marathon Lifter',
      description: 'Complete a workout lasting 120+ minutes',
      icon: '🏃‍♂️',
      type: AchievementType.endurance,
      rarity: AchievementRarity.rare,
      criteria: {'workout_duration_minutes': 120},
      points: 100,
      createdAt: DateTime.now(),
    ),
    
    // Milestone achievements
    Achievement(
      id: 'workouts_10',
      name: 'Getting Started',
      description: 'Complete 10 workouts',
      icon: '🌟',
      type: AchievementType.milestone,
      rarity: AchievementRarity.common,
      criteria: {'total_workouts': 10},
      points: 25,
      createdAt: DateTime.now(),
    ),
    Achievement(
      id: 'workouts_50',
      name: 'Dedicated Athlete',
      description: 'Complete 50 workouts',
      icon: '💎',
      type: AchievementType.milestone,
      rarity: AchievementRarity.uncommon,
      criteria: {'total_workouts': 50},
      points: 75,
      createdAt: DateTime.now(),
    ),
    Achievement(
      id: 'workouts_100',
      name: 'Century Club',
      description: 'Complete 100 workouts',
      icon: '🏅',
      type: AchievementType.milestone,
      rarity: AchievementRarity.rare,
      criteria: {'total_workouts': 100},
      points: 150,
      createdAt: DateTime.now(),
    ),
    
    // Personal Record achievements
    Achievement(
      id: 'first_pr',
      name: 'Personal Best',
      description: 'Set your first personal record',
      icon: '🎖️',
      type: AchievementType.personal_record,
      rarity: AchievementRarity.uncommon,
      criteria: {'personal_records': 1},
      points: 40,
      createdAt: DateTime.now(),
    ),
    Achievement(
      id: 'pr_streak_5',
      name: 'PR Machine',
      description: 'Set 5 personal records in a single workout',
      icon: '🚀',
      type: AchievementType.personal_record,
      rarity: AchievementRarity.epic,
      criteria: {'prs_in_single_workout': 5},
      points: 125,
      createdAt: DateTime.now(),
    ),
    
    // Social achievements
    Achievement(
      id: 'first_share',
      name: 'Social Butterfly',
      description: 'Share your first workout',
      icon: '📱',
      type: AchievementType.social,
      rarity: AchievementRarity.common,
      criteria: {'workouts_shared': 1},
      points: 15,
      createdAt: DateTime.now(),
    ),
  ];

  static Achievement? getAchievementById(String id) {
    try {
      return achievements.firstWhere((achievement) => achievement.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<Achievement> getAchievementsByType(AchievementType type) {
    return achievements.where((achievement) => achievement.type == type).toList();
  }

  static List<Achievement> getAchievementsByRarity(AchievementRarity rarity) {
    return achievements.where((achievement) => achievement.rarity == rarity).toList();
  }
}