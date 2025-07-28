# Modern Workout Tracker

A comprehensive Flutter mobile application for fitness tracking with personalized workout experiences, real-time progress tracking, and social fitness features.

## Features

- 🔐 **User Authentication** - Secure login with email/password and social providers
- 📋 **Comprehensive Onboarding** - Personalized fitness assessment and goal setting
- 💪 **Workout Management** - Browse, create, and customize workout routines
- ⏱️ **Active Workout Sessions** - Real-time workout tracking with timers and logging
- 📊 **Progress Analytics** - Detailed progress tracking and visualization
- 🌐 **Offline Support** - Work out without internet connection
- 👥 **Social Features** - Share achievements and participate in challenges
- 🔔 **Smart Notifications** - Workout reminders and motivational messages

## Tech Stack

- **Framework**: Flutter with Dart
- **State Management**: Riverpod
- **Backend**: Supabase (PostgreSQL, Auth, Realtime, Storage)
- **Navigation**: GoRouter
- **Local Storage**: Hive + Flutter Secure Storage
- **Charts**: FL Chart
- **UI**: Material Design 3

## Getting Started

### Prerequisites

- Flutter SDK (>=3.8.1)
- Dart SDK
- Android Studio / Xcode for mobile development
- Supabase account and project

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd modern_workout_tracker
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**
   - Copy `.env.example` to `.env`
   - Update the Supabase URL and anon key in `.env`
   ```env
   SUPABASE_URL=your_supabase_url_here
   SUPABASE_ANON_KEY=your_supabase_anon_key_here
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Build Configuration

Use the provided build script for easy setup:

```bash
./scripts/build_config.sh
```

This script will:
- Check Flutter installation
- Clean previous builds
- Install dependencies
- Run code generation
- Build debug versions for Android and iOS

## Project Structure

```
lib/
├── constants/          # App constants and configuration
├── models/            # Data models and entities
├── providers/         # Riverpod providers for state management
├── screens/           # UI screens and pages
├── services/          # Business logic and API services
├── utils/             # Utility functions and helpers
├── widgets/           # Reusable UI components
├── app.dart           # Main app widget
└── main.dart          # App entry point
```

## Environment Configuration

The app uses environment variables for configuration:

- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_ANON_KEY`: Your Supabase anonymous key
- `ENVIRONMENT`: Development/production environment

## Database Schema

The app integrates with a Supabase PostgreSQL database with the following main tables:

- `profiles` - User profile information and preferences
- `workouts` - Workout session data
- `exercises` - Exercise library and instructions
- `workout_exercises` - Workout-exercise relationships
- `completed_sets` - Individual set performance logs
- `workout_logs` - Historical workout records

## Development

### Code Generation

The project uses code generation for various features:

```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Testing

Run tests with:

```bash
flutter test
```

### Building for Release

**Android:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please open an issue in the repository or contact the development team.