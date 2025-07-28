import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'workout_log.g.dart';

@JsonSerializable()
@HiveType(typeId: 5)
class WorkoutLog extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  @JsonKey(name: 'user_id')
  final String? userId;
  
  @HiveField(2)
  @JsonKey(name: 'workout_id')
  final String? workoutId;
  
  @HiveField(3)
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;
  
  @HiveField(4)
  @JsonKey(name: 'started_at')
  final DateTime? startedAt;
  
  @HiveField(5)
  @JsonKey(name: 'ended_at')
  final DateTime? endedAt;
  
  @HiveField(6)
  final int? duration;
  
  @HiveField(7)
  @JsonKey(name: 'duration_seconds')
  final int? durationSeconds;
  
  @HiveField(8)
  final int? rating;
  
  @HiveField(9)
  final String? notes;
  
  @HiveField(10)
  final String? status;
  
  @HiveField(11)
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  WorkoutLog({
    required this.id,
    this.userId,
    this.workoutId,
    this.completedAt,
    this.startedAt,
    this.endedAt,
    this.duration,
    this.durationSeconds,
    this.rating,
    this.notes,
    this.status,
    required this.createdAt,
  });

  factory WorkoutLog.fromJson(Map<String, dynamic> json) => 
      _$WorkoutLogFromJson(json);

  Map<String, dynamic> toJson() => _$WorkoutLogToJson(this);

  WorkoutLog copyWith({
    String? id,
    String? userId,
    String? workoutId,
    DateTime? completedAt,
    DateTime? startedAt,
    DateTime? endedAt,
    int? duration,
    int? durationSeconds,
    int? rating,
    String? notes,
    String? status,
    DateTime? createdAt,
  }) {
    return WorkoutLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      workoutId: workoutId ?? this.workoutId,
      completedAt: completedAt ?? this.completedAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      duration: duration ?? this.duration,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutLog &&
        other.id == id &&
        other.userId == userId &&
        other.workoutId == workoutId &&
        other.completedAt == completedAt &&
        other.startedAt == startedAt &&
        other.endedAt == endedAt &&
        other.duration == duration &&
        other.durationSeconds == durationSeconds &&
        other.rating == rating &&
        other.notes == notes &&
        other.status == status &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      workoutId,
      completedAt,
      startedAt,
      endedAt,
      duration,
      durationSeconds,
      rating,
      notes,
      status,
      createdAt,
    );
  }

  // Validation methods
  bool get isValid => 
      id.isNotEmpty && 
      userId != null && 
      workoutId != null;

  bool get isCompleted => status?.toLowerCase() == 'completed' || completedAt != null;
  
  bool get isInProgress => status?.toLowerCase() == 'in_progress';
  
  bool get isCancelled => status?.toLowerCase() == 'cancelled';

  bool get hasRating => rating != null && rating! >= 1 && rating! <= 5;
  
  bool get hasNotes => notes != null && notes!.isNotEmpty;

  // Duration calculations
  Duration? get actualDuration {
    if (startedAt != null && endedAt != null) {
      return endedAt!.difference(startedAt!);
    }
    if (durationSeconds != null) {
      return Duration(seconds: durationSeconds!);
    }
    if (duration != null) {
      return Duration(minutes: duration!);
    }
    return null;
  }

  int? get durationInMinutes {
    final dur = actualDuration;
    return dur?.inMinutes;
  }

  int? get durationInSeconds {
    final dur = actualDuration;
    return dur?.inSeconds;
  }

  // Status helpers
  WorkoutStatus get workoutStatus {
    switch (status?.toLowerCase()) {
      case 'completed':
        return WorkoutStatus.completed;
      case 'in_progress':
        return WorkoutStatus.inProgress;
      case 'cancelled':
        return WorkoutStatus.cancelled;
      case 'paused':
        return WorkoutStatus.paused;
      default:
        return WorkoutStatus.unknown;
    }
  }

  // Time-based analysis
  bool get isToday {
    final now = DateTime.now();
    final logDate = completedAt ?? startedAt ?? createdAt;
    return logDate.year == now.year && 
           logDate.month == now.month && 
           logDate.day == now.day;
  }

  bool get isThisWeek {
    final now = DateTime.now();
    final logDate = completedAt ?? startedAt ?? createdAt;
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return logDate.isAfter(weekStart);
  }

  bool get isThisMonth {
    final now = DateTime.now();
    final logDate = completedAt ?? startedAt ?? createdAt;
    return logDate.year == now.year && logDate.month == now.month;
  }

  // Performance metrics
  double get ratingScore => (rating ?? 0) / 5.0;
  
  bool get isHighRated => rating != null && rating! >= 4;
  
  bool get isLowRated => rating != null && rating! <= 2;

  // Formatting helpers
  String get formattedDuration {
    final dur = actualDuration;
    if (dur == null) return 'Unknown';
    
    final hours = dur.inHours;
    final minutes = dur.inMinutes.remainder(60);
    final seconds = dur.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String get formattedRating {
    if (!hasRating) return 'Not rated';
    return '${'⭐' * rating!}${'☆' * (5 - rating!)}';
  }

  String get statusDisplayName => workoutStatus.displayName;

  // Comparison methods
  int compareTo(WorkoutLog other) {
    final thisDate = completedAt ?? startedAt ?? createdAt;
    final otherDate = other.completedAt ?? other.startedAt ?? other.createdAt;
    return thisDate.compareTo(otherDate);
  }

  bool isNewerThan(WorkoutLog other) => compareTo(other) > 0;
  
  bool isOlderThan(WorkoutLog other) => compareTo(other) < 0;
}

@HiveType(typeId: 6)
enum WorkoutStatus {
  @HiveField(0)
  unknown,
  
  @HiveField(1)
  inProgress,
  
  @HiveField(2)
  completed,
  
  @HiveField(3)
  cancelled,
  
  @HiveField(4)
  paused,
}

extension WorkoutStatusExtension on WorkoutStatus {
  String get displayName {
    switch (this) {
      case WorkoutStatus.inProgress:
        return 'In Progress';
      case WorkoutStatus.completed:
        return 'Completed';
      case WorkoutStatus.cancelled:
        return 'Cancelled';
      case WorkoutStatus.paused:
        return 'Paused';
      case WorkoutStatus.unknown:
        return 'Unknown';
    }
  }

  String get emoji {
    switch (this) {
      case WorkoutStatus.inProgress:
        return '🏃‍♂️';
      case WorkoutStatus.completed:
        return '✅';
      case WorkoutStatus.cancelled:
        return '❌';
      case WorkoutStatus.paused:
        return '⏸️';
      case WorkoutStatus.unknown:
        return '❓';
    }
  }

  bool get isActive => this == WorkoutStatus.inProgress || this == WorkoutStatus.paused;
  
  bool get isFinished => this == WorkoutStatus.completed || this == WorkoutStatus.cancelled;
}