# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter mobile application for water can delivery vendors called "Can Can Vendor App". The app allows vendors to manage their water can delivery business, including order management, inventory tracking, payment processing, and customer interactions.

## Technology Stack

- **Framework**: Flutter (Dart SDK >=3.0.0)
- **Backend**: Supabase (authentication, database, and realtime)
- **State Management**: Provider pattern
- **UI**: Material Design 3 with custom theme
- **Logging**: Logger package with debug mode filtering
- **Error Handling**: Centralized error handler with user-friendly messages
- **Security**: Input sanitization and validation helpers
- **Performance**: Caching utilities and performance monitoring

## Development Commands

### Essential Commands
```bash
# Install dependencies
flutter pub get

# Run the app (requires connected device or emulator)
flutter run

# Run all tests
flutter test

# Analyze code for issues
flutter analyze

# Build for Android
flutter build apk

# Build for iOS
flutter build ios

# Generate app icons (after updating icon assets)
flutter pub run flutter_launcher_icons:main
```

### Environment Setup
Before running the app, create a `.env` file in the root directory with:
```
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anonymous_key
```

### Development Mode (Testing without Supabase)
The app includes a development mode for testing without backend setup:
- **Dev Mode**: Enter phone number `1111111111` to auto-login
- **Test Mode**: Use OTP `123456` for any phone number
- **Location**: `lib/services/auth_service.dart` (set `_devMode = false` for production)

## Architecture Overview

### Directory Structure
```
lib/
├── config/          # App configuration (supabase, theme, constants)
├── models/          # Data models (Order, etc.)
├── screens/         # UI screens organized by feature
│   ├── auth/        # Authentication flow
│   ├── home/        # Main dashboard
│   ├── catalog/     # Product management
│   ├── history/     # Order history
│   ├── payments/    # Payment management
│   ├── inventory/   # Inventory tracking
│   ├── settings/    # App settings
│   ├── vacation/    # Vacation mode
│   └── qr_code/     # QR code features
├── services/        # Business logic and API services
└── utils/           # Utility functions
```

### Key Architecture Patterns

1. **Authentication Flow**: Login → OTP Verification → Profile Setup → Home
2. **Navigation**: Bottom navigation with 5 main sections (Home, History, Payments, Inventory, Settings)
3. **State Management**: Provider pattern for state distribution
4. **Backend Integration**: Supabase for authentication, real-time database, and storage

### Core Services

- **SessionService**: Manages local user session using SharedPreferences
- **OrderService**: Handles order-related business logic
- **SupabaseConfig**: Centralizes Supabase client configuration and initialization

### Authentication System

The app uses phone number-based authentication with OTP verification:
- Uses Supabase Auth with PKCE flow for security
- Includes development mode for testing without backend
- Implements session persistence using SharedPreferences
- **Dev Mode**: Auto-login with phone `1111111111`

### Key Dependencies and Their Uses

- `supabase_flutter`: Backend-as-a-service integration
- `provider`: State management
- `pinput`: OTP input fields
- `qr_flutter`: QR code generation
- `url_launcher`: Launch external URLs (WhatsApp, phone calls)
- `image_picker`: Camera and gallery access
- `cached_network_image`: Optimized image loading
- `shared_preferences`: Local data persistence
- `flutter_dotenv`: Environment variable management
- `logger`: Structured logging with debug filtering
- `uuid`: Generate UUIDs

## Production Readiness Features

### Security & Performance
- **SecurityHelper**: Input sanitization, SQL injection prevention, data masking
- **PerformanceHelper**: Caching, debouncing, performance monitoring
- **ErrorHandler**: Centralized error handling with user-friendly messages

### Code Quality
- **Flutter Lints**: Enforced code quality standards (version 6.0.0)
- **Logger**: Replaced all print statements with structured logging
- **Constants**: Centralized configuration in `lib/config/constants.dart`
- **Error Handling**: Proper try-catch blocks with user feedback

### Architecture Improvements
- **Firebase Removed**: Eliminated unused Firebase dependencies for cleaner codebase
- **Supabase Only**: Single backend solution for all data needs
- **Environment Validation**: App validates required environment variables on startup
- **Error Screen**: Dedicated error screen for initialization failures

## Development Notes

### Code Quality
- Uses `flutter_lints` for code analysis (see analysis_options.yaml)
- Follows Material Design 3 guidelines
- Implements proper error handling throughout the app
- No Firebase dependencies (removed for production simplicity)

### Asset Management
- App icons should be placed in `assets/icons/`
- Images should be placed in `assets/images/`
- After updating icon assets, run `flutter pub run flutter_launcher_icons:main`
- Currently assets are commented out in pubspec.yaml until proper icons are added

### Testing
- Test files should be placed in `test/` directory
- Use `flutter test` to run all tests
- Widget tests use `flutter_test` framework
- Basic test structure provided with unit test examples

### Platform-Specific Considerations
- Android: Configured and ready to build
- iOS: Basic configuration present but may need additional setup
- App currently locked to portrait orientation

### Common Patterns
- All API calls go through Supabase client
- Use Provider for state management across screens
- Implement proper loading states using `flutter_spinkit`
- Use `google_fonts` with Inter font family for consistent typography
- Use AppLogger instead of print statements for debugging

### Testing & Development
- **Dev Mode**: Use phone `1111111111` for instant login without backend
- **Test OTP**: Use `123456` for any phone number in test mode
- **Mock Data**: Services include fallback handling for development
- **Environment Variables**: App validates required variables on startup

### Database Schema (Supabase)
Key tables needed for production:
- `vendors` - Vendor information and profiles
- `products` - Product catalog
- `vendor_products` - Vendor-specific products and pricing
- `customers` - Customer information
- `orders` - Order management
- `order_items` - Order line items

See README.md for complete SQL schema for database setup.