# Auditoría de dependencias v1.0.0

- `file_picker 10.3.10`: fijado por compatibilidad actual con AGP/KGP. 11.x se revisará cuando todos los plugins soporten Built-in Kotlin.
- `share_plus 12.0.2`: API actual auditada; Flutter advierte migración futura a Built-in Kotlin.
- `pdf` + Roboto embebida: generación local Unicode.
- `image`: decodificación, orientación y compresión PDF en isolate.
- `image_picker`, `path_provider`, `file_picker` y `share_plus`: plugins nativos necesarios.
- `flutter_launcher_icons`: sólo desarrollo para generar recursos, no entra al runtime.

No se hicieron upgrades masivos. La advertencia KGP es riesgo futuro conocido; no bloquea el toolchain fijado.
