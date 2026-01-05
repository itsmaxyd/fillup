# ---------------------------------------------------------
# Flutter & Plugins
# ---------------------------------------------------------
# Keep Flutter engine and plugins
-keep class io.flutter.** { *; }
-keep class com.fillup.fillup.** { *; } 

# ---------------------------------------------------------
# Third Party Libraries (Only keep what is broken)
# ---------------------------------------------------------
# Fix for some Http client libraries
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# ---------------------------------------------------------
# F-Droid / Google Play Core Fix (CRITICAL FOR YOUR BUILD)
# ---------------------------------------------------------
# Ignore missing Play Core classes since we stripped them for F-Droid
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# ---------------------------------------------------------
# Optimization & Cleanup
# ---------------------------------------------------------
# Preserve annotations and line numbers for crash reports
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable

# Remove Android logging in release builds
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}