# Flutter ProGuard Rules for Can Can Vendor App

# Keep Flutter engine
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Supabase / GoTrue
-keep class io.supabase.** { *; }

# Keep Google Maps
-keep class com.google.android.gms.maps.** { *; }

# Keep Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Suppress warnings for common Flutter dependencies
-dontwarn io.flutter.embedding.**
-dontwarn com.google.android.play.core.**
