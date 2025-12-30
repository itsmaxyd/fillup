# ProGuard rules for Fillup App

# Keep Flutter classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep provider
-keep class provider.** { *; }

# Keep sqflite
-keep class sqflite.** { *; }
-keep class com.** { *; }

# Keep fl_chart
-keep class fl.chart.** { *; }

# Keep http
-keep class http.** { *; }
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# Keep model classes
-keep class com.fillup.fillup.** { *; }
-keep class lib.models.** { *; }
-keep class lib.providers.** { *; }
-keep class lib.services.** { *; }
-keep class lib.utils.** { *; }
-keep class lib.screens.** { *; }

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Preserve annotations
-keepattributes *Annotation*

# Preserve line number tables
-keepattributes SourceFile,LineNumberTable

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# Google Play Core (required by Flutter)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
