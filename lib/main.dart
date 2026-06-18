import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/supabase_config.dart';
import 'config/theme.dart';
import 'config/app_localizations.dart';
import 'services/vendor_data_service.dart';
import 'providers/locale_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  bool supabaseReady = false;
  String? startupError;

  // Set preferred orientations (portrait only for now)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Supabase
  try {
    await SupabaseConfig.initialize();
    supabaseReady = true;
    print('✅ Supabase initialized successfully');
  } catch (e) {
    print('❌ Supabase initialization failed: $e');
    startupError = e.toString();
  }

  // Initialize vendor data caching (loads vendor profile once)
  if (supabaseReady && SupabaseConfig.isAuthenticated) {
    await VendorDataService.initialize();
  }

  runApp(CanCanApp(
    supabaseReady: supabaseReady,
    startupError: startupError,
  ));
}

class CanCanApp extends StatelessWidget {
  final bool supabaseReady;
  final String? startupError;

  const CanCanApp({
    super.key,
    required this.supabaseReady,
    this.startupError,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            title: 'Can Can',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,

            // Localization support with Tamil as default
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ta'), // Tamil
              Locale('en'), // English
            ],
            locale: localeProvider.currentLocale, // Dynamic locale from provider

            // Check authentication state and navigate accordingly
            home: !supabaseReady
                ? StartupErrorScreen(
                    message: startupError ??
                        'Failed to initialize app configuration. Please restart.',
                  )
                : SupabaseConfig.isAuthenticated
                ? const HomeScreen()
                : const LoginScreen(),

            // Define routes
            routes: {
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const HomeScreen(),
            },
          );
        },
      ),
    );
  }
}

class StartupErrorScreen extends StatelessWidget {
  final String message;

  const StartupErrorScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 56, color: AppTheme.white),
                const SizedBox(height: 16),
                Text(
                  'Startup Error',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.white,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.white,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
