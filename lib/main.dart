import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/supabase_config.dart';
import 'config/theme.dart';
import 'config/app_localizations.dart';
import 'services/vendor_data_service.dart';
import 'services/push_notification_service.dart';
import 'providers/locale_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/profile_setup_screen.dart';
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
    debugPrint('✅ Supabase initialized successfully');
  } catch (e) {
    debugPrint('❌ Supabase initialization failed: $e');
    startupError = e.toString();
  }

  // Initialize vendor data caching (loads vendor profile once) and determine
  // whether an authenticated user still needs to complete profile setup — a
  // user can have a valid session (OTP verified) but no vendors row yet if
  // they abandoned onboarding. Without this they'd be dropped on an empty Home.
  bool needsProfileSetup = false;
  if (supabaseReady && SupabaseConfig.isAuthenticated) {
    await VendorDataService.initialize();
    needsProfileSetup = (await VendorDataService.getVendorProfile()) == null;
  }

  // Initialize push notifications (best-effort — must not block startup)
  try {
    await Firebase.initializeApp();
    if (supabaseReady && SupabaseConfig.isAuthenticated) {
      await PushNotificationService.initialize();
    }
  } catch (e) {
    debugPrint('⚠️ Firebase/push init failed: $e');
  }

  runApp(CanCanApp(
    supabaseReady: supabaseReady,
    startupError: startupError,
    needsProfileSetup: needsProfileSetup,
  ));
}

/// Best-effort +91XXXXXXXXXX form of the signed-in user's phone (auth.users
/// stores it as digits like "919080808080").
String _authPhone() {
  final raw = (SupabaseConfig.currentUser?.phone ?? '').replaceAll(RegExp(r'\D'), '');
  final ten = raw.length >= 10 ? raw.substring(raw.length - 10) : raw;
  return '+91$ten';
}

class CanCanApp extends StatelessWidget {
  final bool supabaseReady;
  final String? startupError;
  final bool needsProfileSetup;

  const CanCanApp({
    super.key,
    required this.supabaseReady,
    this.startupError,
    this.needsProfileSetup = false,
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
                : !SupabaseConfig.isAuthenticated
                ? const LoginScreen()
                : needsProfileSetup
                ? ProfileSetupScreen(phoneNumber: _authPhone())
                : const HomeScreen(),

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
