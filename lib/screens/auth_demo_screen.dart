import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../models/auth_state.dart';
import '../services/biometric_service.dart';

class AuthDemoScreen extends ConsumerStatefulWidget {
  const AuthDemoScreen({super.key});

  @override
  ConsumerState<AuthDemoScreen> createState() => _AuthDemoScreenState();
}

class _AuthDemoScreenState extends ConsumerState<AuthDemoScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final BiometricService _biometricService = BiometricService.instance;
  bool _isSignUp = false;
  bool _biometricAvailable = false;
  String _biometricDescription = '';

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final isAvailable = await _biometricService.isBiometricAvailable();
    final description = await _biometricService.getBiometricDescription();
    
    if (mounted) {
      setState(() {
        _biometricAvailable = isAvailable;
        _biometricDescription = description;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentication Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildBody(authState),
      ),
    );
  }

  Widget _buildBody(AuthState authState) {
    if (authState.isAuthenticated) {
      return _buildAuthenticatedView(authState);
    } else {
      return _buildAuthForm(authState);
    }
  }

  Widget _buildAuthenticatedView(AuthState authState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome! You are authenticated.',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'User Information:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('ID: ${authState.user?.id ?? 'N/A'}'),
                Text('Email: ${authState.user?.email ?? 'N/A'}'),
                Text('Display Name: ${authState.profile?.displayName ?? 'N/A'}'),
                Text('Onboarding Completed: ${authState.profile?.onboardingCompleted ?? false}'),
                const SizedBox(height: 16),
                const Text(
                  'Profile Details:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (authState.profile != null) ...[
                  Text('Age: ${authState.profile!.age ?? 'Not set'}'),
                  Text('Gender: ${authState.profile!.gender ?? 'Not set'}'),
                  Text('Height: ${authState.profile!.height ?? 'Not set'}'),
                  Text('Weight: ${authState.profile!.weight ?? 'Not set'}'),
                  Text('Fitness Goals: ${authState.profile!.fitnessGoalsArray.join(', ')}'),
                  Text('Equipment: ${authState.profile!.equipment.join(', ')}'),
                ] else
                  const Text('Profile not loaded'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Biometric settings
        if (_biometricAvailable) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Biometric Authentication:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Available: $_biometricDescription'),
                  const SizedBox(height: 8),
                  FutureBuilder<bool>(
                    future: _biometricService.isBiometricEnabled(),
                    builder: (context, snapshot) {
                      final isEnabled = snapshot.data ?? false;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Enable biometric login'),
                          Switch(
                            value: isEnabled,
                            onChanged: authState.isLoading ? null : (value) async {
                              if (value) {
                                await _biometricService.enableBiometricAuth();
                              } else {
                                await _biometricService.disableBiometricAuth();
                              }
                              setState(() {}); // Refresh the UI
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: authState.isLoading ? null : () {
              ref.read(authProvider.notifier).signOut();
            },
            child: authState.isLoading 
                ? const CircularProgressIndicator()
                : const Text('Sign Out'),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthForm(AuthState authState) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isSignUp ? 'Create Account' : 'Sign In',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          if (_isSignUp) ...[
            TextFormField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (_isSignUp && (value == null || value.trim().isEmpty)) {
                  return 'Please enter a display name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],
          
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter an email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              if (value.length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          if (authState.hasError) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      authState.errorMessage ?? 'An error occurred',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: authState.isLoading ? null : _handleSubmit,
              child: authState.isLoading
                  ? const CircularProgressIndicator()
                  : Text(_isSignUp ? 'Sign Up' : 'Sign In'),
            ),
          ),
          const SizedBox(height: 16),
          
          TextButton(
            onPressed: authState.isLoading ? null : () {
              setState(() {
                _isSignUp = !_isSignUp;
              });
              _formKey.currentState?.reset();
            },
            child: Text(
              _isSignUp 
                  ? 'Already have an account? Sign In'
                  : 'Don\'t have an account? Sign Up',
            ),
          ),
          
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          
          OutlinedButton.icon(
            onPressed: authState.isLoading ? null : () {
              ref.read(authProvider.notifier).signInWithGoogle();
            },
            icon: const Icon(Icons.login),
            label: const Text('Sign in with Google'),
          ),
          const SizedBox(height: 8),
          
          OutlinedButton.icon(
            onPressed: authState.isLoading ? null : () {
              ref.read(authProvider.notifier).signInWithApple();
            },
            icon: const Icon(Icons.apple),
            label: const Text('Sign in with Apple'),
          ),
        ],
      ),
    );
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final displayName = _displayNameController.text.trim();

    if (_isSignUp) {
      ref.read(authProvider.notifier).signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName.isNotEmpty ? displayName : null,
      );
    } else {
      ref.read(authProvider.notifier).signInWithEmail(
        email: email,
        password: password,
      );
    }
  }
}