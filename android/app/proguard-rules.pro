# Reglas de ProGuard/R8 para Transferencias Flash.
# Flutter y sus plugins usan reflexión/canales de plataforma; conviene preservarlos.

# --- Flutter ---
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# --- Plugins usados por la app (acceso por canal/reflexión) ---
-keep class com.llfbandit.** { *; }            # file_picker
-keep class com.baseflow.permissionhandler.** { *; }
-keep class com.baseflow.geolocator.** { *; }

# No fallar por anotaciones ausentes en dependencias
-dontwarn javax.annotation.**
