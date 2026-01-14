import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/supabase_config.dart';
import 'config/theme.dart';
import 'services/session_service.dart';
import 'services/vendor_data_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (portrait only for now)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Supabase
  try {
    await SupabaseConfig.initialize();
    print('✅ Supabase initialized successfully');
  } catch (e) {
    print('❌ Supabase initialization failed: $e');
    // In production, show error screen
  }

  // Initialize local session storage (SharedPreferences)
  await SessionService.init();

  // Initialize vendor data caching (loads vendor profile once)
  if (SupabaseConfig.isAuthenticated) {
    await VendorDataService.initialize();
  }

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
