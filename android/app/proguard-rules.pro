# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Preserve Firebase/GMS classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Preserve Supabase classes
-keep class io.supabase.** { *; }
