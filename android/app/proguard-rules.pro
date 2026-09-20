# Flutter Wrapper Keep Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Pokidex Native Ble & Foreground Service Classes
-keep class com.pokidex.pokidex.** { *; }
-keep class com.pokidex.pokidex.BlePeripheralPlugin { *; }
-keep class com.pokidex.pokidex.TelemetryForegroundService { *; }

# Kotlin / AndroidX Coroutines & Jetpack
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-dontwarn java.lang.invoke.**
-dontwarn javax.annotation.**
