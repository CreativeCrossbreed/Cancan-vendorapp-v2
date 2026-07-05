# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
# Supabase / OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class com.google.gson.** { *; }
# Firebase
-keep class com.google.firebase.** { *; }
# Play Core (Flutter deferred components — not used, ignore missing refs)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
