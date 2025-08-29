# ProGuard rules for LinkSan - aggressively optimized for minimal size

# Basic rules
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Flutter specific rules - optimized
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep only essential Kotlin classes
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-keep class kotlin.jvm.** { *; }

# Keep data classes and their properties
-keep class com.ganixdev.linksan.** { *; }

# Aggressive debug log removal
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
}

# Remove print statements
-assumenosideeffects class java.io.PrintStream {
    public void print(...);
    public void println(...);
}

# Enhanced tree shaking optimizations
-optimizationpasses 15
-allowaccessmodification
-dontpreverify
-dontoptimize
-dontshrink
-dontskipnonpubliclibraryclassmembers
-dontskipnonpubliclibraryclasses
-mergeinterfacesaggressively
-overloadaggressively
-repackageclasses 'com.ganixdev.linksan'
-allowaccessmodification
-dontusemixedcaseclassnames
-dontwarn java.lang.**

# Aggressive unused code removal
-keepclasseswithmembers class * {
    public <init>(...);
}
-keepclasseswithmembers class * {
    public static void main(java.lang.String[]);
}

# Remove unused annotations
-dontnote
-dontwarn kotlin.**
-dontwarn android.**
-ignorewarnings

# Remove unused resources more aggressively
-adaptresourcefilenames
-adaptresourcefilecontents

# Additional tree shaking for Flutter plugins
-keep class com.apptreesoftware.** { *; }
-keep class io.github.ponnamkarthik.** { *; }
-keep class com.ryanheise.** { *; }

# Google Play Core rules (added to fix R8 compilation)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task
