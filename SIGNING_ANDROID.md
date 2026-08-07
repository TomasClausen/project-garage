# Firma Android de producción

Project Garage usa `android/key.properties`; nunca usa la clave debug para release.

1. Generar una clave fuera del repositorio: `keytool -genkeypair -v -keystore project-garage-upload.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000`.
2. Guardar `android/key.properties` con `storeFile`, `storePassword`, `keyAlias` y `keyPassword`.
3. Mantener `.jks`, `.keystore` y `key.properties` fuera de Git y del CI sin secretos.
4. Respaldar la clave cifrada en dos ubicaciones. Perderla puede impedir actualizar la aplicación; Play App Signing permite rotar la upload key según las reglas de Google Play.
5. Generar con `flutter build appbundle` y verificar con `jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab`.

En CI, reconstruir `key.properties` y el keystore desde secretos protegidos antes del build release.
