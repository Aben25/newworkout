import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../models/models.dart';
import '../constants/app_constants.dart';

/// Service for managing workout timers with rest_interval support from workout_exercises table
class WorkoutTimerService {
  static WorkoutTimerService? _instance;
  static WorkoutTimerService get instance => _instance ??= WorkoutTimerService._();
  
  WorkoutTimerService._();
  
  final Logger _logger = Logger();
  Timer? _restTimer;
  Timer? _workoutTimer;
  
  // Timer state
  int _restTimeRemaining = 0;
  int _workoutElapsedTime = 0;
  bool _isRestTimerActive = false;
  bool _isWorkoutTimerActive = false;
  
  // Stream controllers for timer updates
  final StreamController<int> _restTimerController = StreamController<int>.broadcast();
  final StreamController<int> _workoutTimerController = StreamController<int>.broadcast();
  final StreamController<bool> _restTimerStateController = StreamController<bool>.broadcast();

  // Getters for current state
  int get restTimeRemaining => _restTimeRemaining;
  int get workoutElapsedTime => _workoutElapsedTime;
  bool get isRestTimerActive => _isRestTimerActive;
  bool get isWorkoutTimerActive => _isWorkoutTimerActive;

  // Streams for UI updates
  Stream<int> get restTimerStream => _restTimerController.stream;
  Stream<int> get workoutTimerStream => _workoutTimerController.stream;
  Stream<bool> get restTimerStateStream => _restTimerStateController.stream;

  /// Start rest timer with custom duration from workout_exercises.rest_interval
  void startRestTimer(int restSeconds) {
    _logger.d('Starting rest timer for $restSeconds seconds');
    
    _stopRestTimer();
    
    _restTimeRemaining = restSeconds;
    _isRestTimerActive = true;
    
    // Notify state change
    _restTimerStateController.add(true);
    _restTimerController.add(_restTimeRemaining);
    
    _restTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        _restTimeRemaining--;
        _restTimerController.add(_restTimeRemaining);
        
        if (_restTimeRemaining <= 0) {
          _stopRestTimer();
          _logger.d('Rest timer completed');
        }
      },
    );
  }

  /// Stop rest timer
  void _stopRestTimer() {
    _restTimer?.cancel();
    _restTimer = null;
    _isRestTimerActive = false;
    _restTimeRemaining = 0;
    
    _restTimerStateController.add(false);
    _restTimerController.add(0);
  }

  /// Skip rest timer
  void skipRestTimer() {
    _logger.d('Skipping rest timer');
    _stopRestTimer();
  }

  /// Add time to rest timer
  void addRestTime(int seconds) {
    if (!_isRestTimerActive) return;
    
    _restTimeRemaining += seconds;
    _restTimerController.add(_restTimeRemaining);
    _logger.d('Added $seconds seconds to rest timer');
  }

  /// Start workout timer for session tracking
  void startWorkoutTimer() {
    _logger.d('Starting workout timer');
    
    _stopWorkoutTimer();
    
    _workoutElapsedTime = 0;
    _isWorkoutTimerActive = true;
    
    _workoutTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        _workoutElapsedTime++;
        _workoutTimerController.add(_workoutElapsedTime);
      },
    );
  }

  /// Stop workout timer
  void _stopWorkoutTimer() {
    _workoutTimer?.cancel();
    _workoutTimer = null;
    _isWorkoutTimerActive = false;
  }

  /// Pause workout timer
  void pauseWorkoutTimer() {
    _logger.d('Pausing workout timer at ${_workoutElapsedTime}s');
    _stopWorkoutTimer();
  }

  /// Resume workout timer
  void resumeWorkoutTimer() {
    if (_isWorkoutTimerActive) return;
    
    _logger.d('Resuming workout timer from ${_workoutElapsedTime}s');
    _isWorkoutTimerActive = true;
    
    _workoutTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        _workoutElapsedTime++;
        _workoutTimerController.add(_workoutElapsedTime);
      },
    );
  }

  /// Stop all timers
  void stopAllTimers() {
    _logger.d('Stopping all timers');
    _stopRestTimer();
    _stopWorkoutTimer();
  }

  /// Get formatted rest time
  String getFormattedRestTime() {
    final minutes = _restTimeRemaining ~/ 60;
    final seconds = _restTimeRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get formatted workout time
  String getFormattedWorkoutTime() {
    final hours = _workoutElapsedTime ~/ 3600;
    final minutes = (_workoutElapsedTime % 3600) ~/ 60;
    final seconds = _workoutElapsedTime % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Get rest interval for exercise from workout_exercises table
  int getRestIntervalForExercise(WorkoutExercise workoutExercise) {
    return workoutExercise.restInterval ?? AppConstants.defaultRestTime;
  }

  /// Calculate recommended rest time based on exercise type and intensity
  int calculateRecommendedRestTime({
    required Exercise exercise,
    required int reps,
    required double weight,
    String? difficultyRating,
  }) {
    // Base rest time based on exercise category
    int baseRestTime = AppConstants.defaultRestTime;
    
    // Adjust based on exercise category
    switch (exercise.category?.toLowerCase()) {
      case 'strength':
      case 'powerlifting':
        baseRestTime = 180; // 3 minutes for heavy compound movements
        break;
      case 'hypertrophy':
      case 'bodybuilding':
        baseRestTime = 90; // 1.5 minutes for hypertrophy work
        break;
      case 'endurance':
      case 'cardio':
        baseRestTime = 30; // 30 seconds for endurance work
        break;
      default:
        baseRestTime = AppConstants.defaultRestTime;
    }
    
    // Adjust based on difficulty rating
    switch (difficultyRating?.toLowerCase()) {
      case 'very_hard':
        baseRestTime = (baseRestTime * 1.5).round();
        break;
      case 'hard':
        baseRestTime = (baseRestTime * 1.2).round();
        break;
      case 'easy':
        baseRestTime = (baseRestTime * 0.7).round();
        break;
      case 'very_easy':
        baseRestTime = (baseRestTime * 0.5).round();
        break;
    }
    
    // Ensure minimum and maximum bounds
    return baseRestTime.clamp(15, 300); // 15 seconds to 5 minutes
  }

  /// Dispose of service resources
  void dispose() {
    _logger.d('Disposing WorkoutTimerService');
    stopAllTimers();
    _restTimerController.close();
    _workoutTimerController.close();
    _restTimerStateController.close();
  }
}

// Provider
final workoutTimerServiceProvider = Provider<WorkoutTimerService>((ref) {
  return WorkoutTimerService.instance;
});

// Timer state providers
final restTimerProvider = StreamProvider<int>((ref) {
  final timerService = ref.read(workoutTimerServiceProvider);
  return timerService.restTimerStream;
});

final workoutTimerProvider = StreamProvider<int>((ref) {
  final timerService = ref.read(workoutTimerServiceProvider);
  return timerService.workoutTimerStream;
});

final restTimerStateProvider = StreamProvider<bool>((ref) {
  final timerService = ref.read(workoutTimerServiceProvider);
  return timerService.restTimerStateStream;
});