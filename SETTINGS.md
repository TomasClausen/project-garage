# Configuración

v1.0.0 agrega privacidad, About, licencias y diagnóstico sanitizado. `ProjectProfile.onboardingCompleted` controla first run; no se piden permisos al iniciar.

`AppPreferences` usa Hive typeId 11 y box `app_preferences`.

Defaults: ARS, `$`, `es_AR`, `dd/MM/yyyy`, punto de miles y km. Cambiar moneda o
distancia sólo modifica presentación; no convierte datos almacenados. Settings
se abre desde Inicio y no agrega una pestaña inferior.
