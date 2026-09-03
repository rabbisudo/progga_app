# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Play Core / Deferred Components
-dontwarn com.google.android.play.core.**

# AndroidX / Support
-dontwarn androidx.**
-dontwarn com.google.android.material.**

# Firebase
-dontwarn com.google.firebase.**
-keep class com.google.firebase.** { *; }

# Google Sign In
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.common.api.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Secure Storage / Crypto / Net
-dontwarn javax.crypto.**
-dontwarn okio.**
-dontwarn sun.misc.**
