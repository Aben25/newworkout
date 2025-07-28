import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import 'constants/app_constants.dart';
import 'services/supabase_service.dart';
import 'services/storage_service.dart';
import 'services/connectivity_service.dart';
import 'services/sync_service.dart';
import 'services/background_sync_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final logger = Logger();
  
  try {
    // Initialize core services
    logger.i('Initializing Modern Workout Tracker...');
    
    // Initialize local storage
    await StorageService.initialize();
    
    // Initialize Supabase
    await SupabaseService.initialize();
    
    // Initialize connectivity service
    await ConnectivityService.instance.initialize();
    
    // Initialize sync service
    await SyncService.instance.initialize();
    
    // Initialize background sync service
    await BackgroundSyncService.instance.initialize();
    
    logger.i('All services initialized successfully');
    
    // Run the app with Riverpod
    runApp(
      const ProviderScope(
        child: ModernWorkoutTrackerApp(),
      ),
    );
  } catch (e, stackTrace) {
    logger.e(
      'Failed to initialize app',
      error: e,
      stackTrace: stackTrace,
    );
    
    // Run a minimal error app
    runApp(
      MaterialApp(
        title: AppConstants.appName,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to initialize app',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Restart the app
                    main();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}