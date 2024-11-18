-keep class com.sgmaq.flutter_application_sgmaq.MainActivity { *; }

# Preservar clases y métodos de Dio
-keep class dio.** { *; }
-keep interface dio.** { *; }

# Preservar clases de serialización si usas JSON
-keep class kotlinx.serialization.** { *; }
-keepclassmembers class * {
    @kotlinx.serialization.* <methods>;
}
