# Tamaño de build v1.0.0

Registrar después de la validación final los bytes de APK debug, APK release y AAB. El release conserva tree shaking; no se activa R8/minificación o `shrinkResources` agresivos sin pruebas. Se incluye una sola fuente PDF y un asset maestro de branding. Los APK universales contienen múltiples ABI; Google Play divide el AAB por dispositivo.
