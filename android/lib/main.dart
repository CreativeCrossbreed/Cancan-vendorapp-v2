import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/app_config.dart';
import 'config/supabase_config.dart';
import 'config/theme.dart';
import 'services/session_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_tab_screen_enhanced.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Validate compile-time config
  if (!AppConfig.isValidConfig) {
    runApp(const ErrorApp(
      error: 'Missing SUPABASE_URL or SUPABASE_ANON_KEY.\n'
          'Run with: flutter run --dart-define-from-file=api-keys.json',
    ));
    return;
  }

  if (AppConfig.shouldEnableVerboseLogging) {
    AppLogger.d('App configuration: ${AppConfig.debugInfo}');
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Supabase
  try {
    await SupabaseConfig.initialize();
    AppLogger.i('Supabase initialized successfully');
  } catch (e) {
    AppLogger.critical('Supabase initialization failed: $e');
    runApp(const ErrorApp(error: 'Failed to initialize database'));
    return;
  }

  // Initialize local session storage
  await SessionService.init();

  runApp(const CanCanApp());
}

class CanCanApp extends StatelessWidget {
  const CanCanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Can Can',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: SupabaseConfig.isAuthenticated
          ? const HomeScreenEnhanced()
          : const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreenEnhanced(),
        '/home_enhanced': (context) => const HomeScreenEnhanced(),
      },
    );
  }
}

/// Error screen for critical initialization failures
class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.red[50],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red[700],
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Initialization Error',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    SystemNavigator.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Close App'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
