# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.**

# Preserve Firebase/GMS classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.**

# Preserve Supabase classes
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# Avoid R8 crashing on missing classes from background isolates or native libs
-dontwarn android.**
-dontwarn androidx.**
-dontwarn org.**
-ignorewarnings
