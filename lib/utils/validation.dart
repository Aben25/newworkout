/// Validation utilities for workout tracker models
class ValidationUtils {
  // User Profile Validations
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  static String? validateDisplayName(String? name) {
    if (name == null || name.isEmpty) {
      return 'Display name is required';
    }
    
    if (name.length < 2) {
      return 'Display name must be at least 2 characters';
    }
    
    if (name.length > 50) {
      return 'Display name must be less than 50 characters';
    }
    
    return null;
  }

  static String? validateAge(int? age) {
    if (age == null) {
      return 'Age is required';
    }
    
    if (age < 13) {
      return 'You must be at least 13 years old';
    }
    
    if (age > 120) {
      return 'Please enter a valid age';
    }
    
    return null;
  }

  static String? validateHeight(double? height, String unit) {
    if (height == null) {
      return 'Height is required';
    }
    
    if (unit == 'cm') {
      if (height < 100 || height > 250) {
        return 'Height must be between 100-250 cm';
      }
    } else if (unit == 'ft') {
      if (height < 3.0 || height > 8.0) {
        return 'Height must be between 3-8 feet';
      }
    }
    
    return null;
  }

  static String? validateWeight(double? weight, String unit) {
    if (weight == null) {
      return 'Weight is required';
    }
    
    if (unit == 'kg') {
      if (weight < 30 || weight > 300) {
        return 'Weight must be between 30-300 kg';
      }
    } else if (unit == 'lbs') {
      if (weight < 66 || weight > 660) {
        return 'Weight must be between 66-660 lbs';
      }
    }
    
    return null;
  }

  static String? validateGender(String? gender) {
    if (gender == null || gender.isEmpty) {
      return 'Gender is required';
    }
    
    final validGenders = ['male', 'female', 'other', 'prefer_not_to_say'];
    if (!validGenders.contains(gender.toLowerCase())) {
      return 'Please select a valid gender option';
    }
    
    return null;
  }

  static String? validateFitnessGoals(List<String>? goals) {
    if (goals == null || goals.isEmpty) {
      return 'Please select at least one fitness goal';
    }
    
    if (goals.length > 5) {
      return 'Please select no more than 5 fitness goals';
    }
    
    return null;
  }

  static String? validateEquipment(List<String>? equipment) {
    if (equipment == null || equipment.isEmpty) {
      return 'Please select your available equipment';
    }
    
    return null;
  }

  static String? validateWorkoutDays(List<String>? days) {
    if (days == null || days.isEmpty) {
      return 'Please select at least one workout day';
    }
    
    if (days.length > 7) {
      return 'Cannot select more than 7 days';
    }
    
    final validDays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    for (final day in days) {
      if (!validDays.contains(day.toLowerCase())) {
        return 'Invalid day selected: $day';
      }
    }
    
    return null;
  }

  static String? validateWorkoutDuration(int? duration) {
    if (duration == null) {
      return 'Workout duration is required';
    }
    
    if (duration < 15 || duration > 180) {
      return 'Workout duration must be between 15-180 minutes';
    }
    
    return null;
  }

  static String? validateWorkoutFrequency(int? frequency) {
    if (frequency == null) {
      return 'Workout frequency is required';
    }
    
    if (frequency < 1 || frequency > 7) {
      return 'Workout frequency must be between 1-7 days per week';
    }
    
    return null;
  }

  static String? validateFitnessLevel(int? level) {
    if (level == null) {
      return 'Fitness level is required';
    }
    
    if (level < 1 || level > 5) {
      return 'Fitness level must be between 1-5';
    }
    
    return null;
  }

  // Exercise Validations
  static String? validateExerciseName(String? name) {
    if (name == null || name.isEmpty) {
      return 'Exercise name is required';
    }
    
    if (name.length < 2) {
      return 'Exercise name must be at least 2 characters';
    }
    
    if (name.length > 100) {
      return 'Exercise name must be less than 100 characters';
    }
    
    return null;
  }

  static String? validateMuscleGroup(String? muscle) {
    if (muscle == null || muscle.isEmpty) {
      return 'Primary muscle group is required';
    }
    
    final validMuscles = [
      'chest', 'back', 'shoulders', 'biceps', 'triceps', 'forearms',
      'abs', 'obliques', 'quadriceps', 'hamstrings', 'glutes', 'calves',
      'full_body', 'cardio'
    ];
    
    if (!validMuscles.contains(muscle.toLowerCase())) {
      return 'Please select a valid muscle group';
    }
    
    return null;
  }

  static String? validateEquipmentType(String? equipment) {
    if (equipment == null || equipment.isEmpty) {
      return 'Equipment type is required';
    }
    
    final validEquipment = [
      'bodyweight', 'dumbbells', 'barbell', 'resistance_bands', 'kettlebell',
      'cable_machine', 'pull_up_bar', 'bench', 'stability_ball', 'medicine_ball',
      'foam_roller', 'yoga_mat', 'cardio_machine'
    ];
    
    if (!validEquipment.contains(equipment.toLowerCase())) {
      return 'Please select a valid equipment type';
    }
    
    return null;
  }

  // Workout Exercise Validations
  static String? validateSets(int? sets) {
    if (sets == null) {
      return 'Number of sets is required';
    }
    
    if (sets < 1 || sets > 20) {
      return 'Sets must be between 1-20';
    }
    
    return null;
  }

  static String? validateReps(int? reps) {
    if (reps == null) {
      return 'Number of reps is required';
    }
    
    if (reps < 1 || reps > 100) {
      return 'Reps must be between 1-100';
    }
    
    return null;
  }

  static String? validateExerciseWeight(double? weight) {
    if (weight == null) {
      return null; // Weight is optional for bodyweight exercises
    }
    
    if (weight < 0 || weight > 1000) {
      return 'Weight must be between 0-1000 kg';
    }
    
    return null;
  }

  static String? validateRestInterval(int? restInterval) {
    if (restInterval == null) {
      return null; // Rest interval is optional
    }
    
    if (restInterval < 10 || restInterval > 600) {
      return 'Rest interval must be between 10-600 seconds';
    }
    
    return null;
  }

  // Workout Log Validations
  static String? validateRating(int? rating) {
    if (rating == null) {
      return null; // Rating is optional
    }
    
    if (rating < 1 || rating > 5) {
      return 'Rating must be between 1-5 stars';
    }
    
    return null;
  }

  static String? validateNotes(String? notes) {
    if (notes == null || notes.isEmpty) {
      return null; // Notes are optional
    }
    
    if (notes.length > 500) {
      return 'Notes must be less than 500 characters';
    }
    
    return null;
  }

  static String? validateWorkoutDurationMinutes(int? duration) {
    if (duration == null) {
      return null; // Duration might be calculated automatically
    }
    
    if (duration < 1 || duration > 480) {
      return 'Workout duration must be between 1-480 minutes';
    }
    
    return null;
  }

  // List Validations
  static String? validateStringList(List<String>? list, String fieldName, {
    int? minLength,
    int? maxLength,
    List<String>? allowedValues,
  }) {
    if (list == null || list.isEmpty) {
      if (minLength != null && minLength > 0) {
        return '$fieldName is required';
      }
      return null;
    }
    
    if (minLength != null && list.length < minLength) {
      return '$fieldName must have at least $minLength item${minLength > 1 ? 's' : ''}';
    }
    
    if (maxLength != null && list.length > maxLength) {
      return '$fieldName must have no more than $maxLength item${maxLength > 1 ? 's' : ''}';
    }
    
    if (allowedValues != null) {
      for (final item in list) {
        if (!allowedValues.contains(item.toLowerCase())) {
          return 'Invalid $fieldName: $item';
        }
      }
    }
    
    return null;
  }

  static String? validateIntList(List<int>? list, String fieldName, {
    int? minLength,
    int? maxLength,
    int? minValue,
    int? maxValue,
  }) {
    if (list == null || list.isEmpty) {
      if (minLength != null && minLength > 0) {
        return '$fieldName is required';
      }
      return null;
    }
    
    if (minLength != null && list.length < minLength) {
      return '$fieldName must have at least $minLength item${minLength > 1 ? 's' : ''}';
    }
    
    if (maxLength != null && list.length > maxLength) {
      return '$fieldName must have no more than $maxLength item${maxLength > 1 ? 's' : ''}';
    }
    
    if (minValue != null || maxValue != null) {
      for (final item in list) {
        if (minValue != null && item < minValue) {
          return '$fieldName values must be at least $minValue';
        }
        if (maxValue != null && item > maxValue) {
          return '$fieldName values must be no more than $maxValue';
        }
      }
    }
    
    return null;
  }

  // Date Validations
  static String? validateDate(DateTime? date, String fieldName, {
    DateTime? minDate,
    DateTime? maxDate,
  }) {
    if (date == null) {
      return '$fieldName is required';
    }
    
    if (minDate != null && date.isBefore(minDate)) {
      return '$fieldName cannot be before ${minDate.toLocal().toString().split(' ')[0]}';
    }
    
    if (maxDate != null && date.isAfter(maxDate)) {
      return '$fieldName cannot be after ${maxDate.toLocal().toString().split(' ')[0]}';
    }
    
    return null;
  }

  // Complex Validations
  static Map<String, String> validateUserProfile({
    String? email,
    String? displayName,
    int? age,
    String? gender,
    double? height,
    String heightUnit = 'cm',
    double? weight,
    String weightUnit = 'kg',
    List<String>? fitnessGoals,
    List<String>? equipment,
    List<String>? workoutDays,
    int? workoutDuration,
    int? workoutFrequency,
    int? fitnessLevel,
  }) {
    final errors = <String, String>{};
    
    final emailError = validateEmail(email);
    if (emailError != null) errors['email'] = emailError;
    
    final nameError = validateDisplayName(displayName);
    if (nameError != null) errors['displayName'] = nameError;
    
    final ageError = validateAge(age);
    if (ageError != null) errors['age'] = ageError;
    
    final genderError = validateGender(gender);
    if (genderError != null) errors['gender'] = genderError;
    
    final heightError = validateHeight(height, heightUnit);
    if (heightError != null) errors['height'] = heightError;
    
    final weightError = validateWeight(weight, weightUnit);
    if (weightError != null) errors['weight'] = weightError;
    
    final goalsError = validateFitnessGoals(fitnessGoals);
    if (goalsError != null) errors['fitnessGoals'] = goalsError;
    
    final equipmentError = validateEquipment(equipment);
    if (equipmentError != null) errors['equipment'] = equipmentError;
    
    final daysError = validateWorkoutDays(workoutDays);
    if (daysError != null) errors['workoutDays'] = daysError;
    
    final durationError = validateWorkoutDuration(workoutDuration);
    if (durationError != null) errors['workoutDuration'] = durationError;
    
    final frequencyError = validateWorkoutFrequency(workoutFrequency);
    if (frequencyError != null) errors['workoutFrequency'] = frequencyError;
    
    final levelError = validateFitnessLevel(fitnessLevel);
    if (levelError != null) errors['fitnessLevel'] = levelError;
    
    return errors;
  }

  static Map<String, String> validateWorkoutExercise({
    String? name,
    int? sets,
    List<int>? reps,
    List<double>? weights,
    int? restInterval,
  }) {
    final errors = <String, String>{};
    
    final nameError = validateExerciseName(name);
    if (nameError != null) errors['name'] = nameError;
    
    final setsError = validateSets(sets);
    if (setsError != null) errors['sets'] = setsError;
    
    if (reps != null) {
      for (int i = 0; i < reps.length; i++) {
        final repError = validateReps(reps[i]);
        if (repError != null) {
          errors['reps_$i'] = repError;
        }
      }
    }
    
    if (weights != null) {
      for (int i = 0; i < weights.length; i++) {
        final weightError = validateExerciseWeight(weights[i]);
        if (weightError != null) {
          errors['weight_$i'] = weightError;
        }
      }
    }
    
    final restError = validateRestInterval(restInterval);
    if (restError != null) errors['restInterval'] = restError;
    
    return errors;
  }

  // Utility methods
  static bool isValidEmail(String email) => validateEmail(email) == null;
  
  static bool isValidAge(int age) => validateAge(age) == null;
  
  static bool isValidHeight(double height, String unit) => 
      validateHeight(height, unit) == null;
  
  static bool isValidWeight(double weight, String unit) => 
      validateWeight(weight, unit) == null;
  
  static bool hasValidationErrors(Map<String, String> errors) => 
      errors.isNotEmpty;
}