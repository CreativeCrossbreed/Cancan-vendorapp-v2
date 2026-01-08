# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Can Can Vendor is a Flutter mobile application for water can delivery vendors. The app allows vendors to manage their water can delivery business, including order management, inventory tracking, payment processing, and customer interactions.

## Technology Stack

- **Framework**: Flutter (Dart SDK >=3.0.0)
- **Backend**: Supabase (authentication, database, real-time)
- **State Management**: Provider pattern
- **UI**: Material Design 3 with custom Agrandir font theme
- **Push Notifications**: Firebase Cloud Messaging (FCM)
- **Phone Auth**: Supabase Auth with OTP (currently in TEST MODE)

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
flutter build apk --release
flutter build appbundle --release

# Build for iOS
flutter build ios

# Generate app icons (after updating icon assets)
flutter pub run flutter_launcher_icons
```

### Environment Setup
Before running the app, create a `.env` file in the root directory with:
```
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anonymous_key
```

## Architecture Overview

### Directory Structure
```
lib/
├── config/           # App configuration (theme, constants, Supabase)
├── models/           # Data models (Order, Customer, etc.)
├── screens/          # UI screens organized by feature
│   ├── auth/        # Login, OTP, Profile Setup
│   ├── home/        # Main dashboard with bottom nav
│   ├── inventory/   # Stock management
│   ├── payments/    # Payment tracking
│   ├── history/     # Order history
│   ├── qr_code/     # QR code generation/scanning
│   ├── catalog/     # Product catalog
│   ├── vacation/    # Vacation mode settings
│   └── settings/    # App settings
├── services/         # Business logic and API calls
├── widgets/          # Reusable UI components
└── utils/            # Helper utilities
```

### Key Configuration Files
- `lib/config/supabase_config.dart`: Supabase initialization and client access
- `lib/config/theme.dart`: App-wide theme constants, colors, 8dp spacing grid, and Material theme
- `.env`: Supabase credentials (SUPABASE_URL, SUPABASE_ANON_KEY) - **do not commit**

### Key Architecture Patterns

1. **Authentication Flow**: Login → OTP Verification → Profile Setup → Home
2. **Navigation**: `HomeScreen` hosts bottom navigation bar with 4 tabs (Home, History, Payments, Inventory)
3. **State Management**: Provider pattern for state distribution
4. **Backend Integration**: Supabase for authentication, real-time database, and storage

### Data Models
- `Order`: Core model with nested `Customer`, `OrderItem`, and `Product`
- All models include `fromJson()` factory constructors for Supabase response parsing
- Database column names use snake_case (e.g., `order_number`) mapped to camelCase Dart fields

### Services Layer
- `AuthService`: Phone OTP authentication with TEST MODE flag
- `OrderService`: Order management with dummy data toggle (`_useDummyData`)
- `VendorService`: Vendor profile management
- `InventoryService`: Stock tracking and automatic deduction on delivery
- `SessionService`: Local session persistence via SharedPreferences

### Navigation Pattern
- `HomeScreen` hosts the bottom navigation bar with 4 tabs
- Each tab renders its screen directly in the body (no routing between tabs)
- `ScreenWithNav` wrapper provides nav bar for detail screens
- `AppBottomNavBar` reusable bottom navigation widget
- Auth flow uses named routes: `/login`, `/home`

### Testing Mode Flags
Two important flags control test vs production behavior:

1. **AuthService._testMode** (lib/services/auth_service.dart:11)
   - `true`: Bypasses real OTP, accepts "123456", uses mock session
   - `false`: Real Supabase phone OTP authentication

2. **OrderService._useDummyData** (lib/services/order_service.dart:12)
   - `true`: Returns hardcoded Tamil dummy data for UI development
   - `false`: Fetches real data from Supabase orders table

Remember to set both to `false` before production deployment.

### Theme System
- Uses custom Agrandir font (assets/fonts/) - NOT Google Fonts
- 8dp spacing grid system with constants in `AppTheme` (spacingXS through spacingXXXL)
- Predefined padding constants (paddingXS, paddingHorizontalL, etc.)
- Primary color: `#4A90E2` (blue)
- Status colors: pending (orange), completed (green), cancelled (red)

### Database Schema (Supabase)
Key tables referenced in code:
- `vendors`: Vendor profiles
- `orders`: Orders with delivery dates, time slots, status
- `customers`: Customer addresses and contact info
- `order_items`: Order line items with quantities
- `products`: Product catalog (water cans)

## Development Notes

### Code Quality
- Uses `flutter_lints` for code analysis (see analysis_options.yaml)
- Follows Material Design 3 guidelines
- Implements proper error handling throughout the app

### Asset Management
- App icons should be placed in `assets/icons/`
- Images should be placed in `assets/images/`
- Agrandir font files in `assets/fonts/`
- After updating icon assets, run `flutter pub run flutter_launcher_icons`

### Testing
- Test files should be placed in `test/` directory
- Use `flutter test` to run all tests
- Widget tests use `flutter_test` framework

### Platform-Specific Considerations
- Android: Configured and ready to build
- iOS: Basic configuration present but may need additional setup
- App currently locked to portrait orientation

### Print Debugging
The codebase uses extensive `print()` statements for debugging (prefixed with emoji indicators like ✅, ❌, 📦, 🧪). These are intentional for development and should remain for debugging complex flows.

### Push Notifications
- Firebase Messaging for FCM tokens
- flutter_local_notifications for local notifications
- Permission handling via permission_handler

### Key Dependencies
- `supabase_flutter`: Backend-as-a-service integration
- `provider`: State management
- `pinput`: OTP input fields
- `qr_flutter`: QR code generation
- `url_launcher`: Launch external URLs (WhatsApp, phone calls)
- `image_picker`: Camera and gallery access
- `firebase_messaging`: Push notifications
- `cached_network_image`: Optimized image loading
- `shared_preferences`: Local data persistence
- `flutter_dotenv`: Environment variable management
