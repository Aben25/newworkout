import 'package:shared_preferences/shared_preferences.dart';

class UnitConversionHelper {
  static const String _heightUnitKey = 'height_unit_preference';
  static const String _weightUnitKey = 'weight_unit_preference';

  // Height conversion
  static double convertHeight(double value, String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return value;
    
    if (fromUnit == 'cm' && toUnit == 'ft') {
      return value / 30.48; // Convert cm to feet
    } else if (fromUnit == 'ft' && toUnit == 'cm') {
      return value * 30.48; // Convert feet to cm
    }
    
    return value;
  }

  // Weight conversion
  static double convertWeight(double value, String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return value;
    
    if (fromUnit == 'kg' && toUnit == 'lbs') {
      return value * 2.20462; // Convert kg to lbs
    } else if (fromUnit == 'lbs' && toUnit == 'kg') {
      return value / 2.20462; // Convert lbs to kg
    }
    
    return value;
  }

  // Format height for display
  static String formatHeight(double value, String unit) {
    if (unit == 'ft') {
      final feet = value.floor();
      final inches = ((value - feet) * 12).round();
      return '$feet\'$inches"';
    } else {
      return '${value.toStringAsFixed(0)} cm';
    }
  }

  // Format weight for display
  static String formatWeight(double value, String unit) {
    return '${value.toStringAsFixed(1)} $unit';
  }

  // Save unit preferences
  static Future<void> saveHeightUnitPreference(String unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_heightUnitKey, unit);
  }

  static Future<void> saveWeightUnitPreference(String unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_weightUnitKey, unit);
  }

  // Load unit preferences
  static Future<String> getHeightUnitPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_heightUnitKey) ?? 'cm';
  }

  static Future<String> getWeightUnitPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_weightUnitKey) ?? 'kg';
  }

  // Validate height input
  static String? validateHeight(String? value, String unit) {
    if (value == null || value.isEmpty) {
      return 'Please enter your height';
    }
    
    final height = double.tryParse(value);
    if (height == null || height <= 0) {
      return 'Please enter a valid height';
    }
    
    if (unit == 'cm') {
      if (height < 50 || height > 300) {
        return 'Height must be between 50-300 cm';
      }
    } else if (unit == 'ft') {
      if (height < 1.5 || height > 10) {
        return 'Height must be between 1.5-10 feet';
      }
    }
    
    return null;
  }

  // Validate weight input
  static String? validateWeight(String? value, String unit) {
    if (value == null || value.isEmpty) {
      return 'Please enter your weight';
    }
    
    final weight = double.tryParse(value);
    if (weight == null || weight <= 0) {
      return 'Please enter a valid weight';
    }
    
    if (unit == 'kg') {
      if (weight < 20 || weight > 300) {
        return 'Weight must be between 20-300 kg';
      }
    } else if (unit == 'lbs') {
      if (weight < 44 || weight > 660) {
        return 'Weight must be between 44-660 lbs';
      }
    }
    
    return null;
  }

  // Get height hint text
  static String getHeightHint(String unit) {
    return unit == 'cm' ? '170' : '5.7';
  }

  // Get weight hint text
  static String getWeightHint(String unit) {
    return unit == 'kg' ? '70' : '154';
  }
}