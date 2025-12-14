import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/supabase_config.dart';
import 'config/theme.dart';
import 'services/session_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'utils/logger.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");

    // Validate required environment variables
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseAnonKey == null) {
      throw Exception(
        'Missing required environment variables. Please check your .env file.\n'
        'Required: SUPABASE_URL, SUPABASE_ANON_KEY\n'
        'Copy .env.example to .env and fill in the values.',
      );
    }
  } catch (e) {
    AppLogger.critical('Environment setup failed: $e');
    runApp(ErrorApp(error: e.toString()));
    return;
  }

  // Set preferred orientations (portrait only for now)
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

  // Initialize local session storage (SharedPreferences)
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

      // Check authentication state and navigate accordingly
      home: SupabaseConfig.isAuthenticated
          ? const HomeScreen()
          : const LoginScreen(),

      // Define routes
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
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
                    // User should fix the error and restart the app
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
