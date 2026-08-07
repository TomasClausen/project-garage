# Migración a v1.0.0

No se modifican typeId 0–11. Se agrega `ProjectProfile` con typeId 12. Los datos v0.9.1 crean un perfil completado sin alterar registros. Un restore antiguo crea el perfil faltante. `Vehicle.lancer` queda como constante legacy pero no se inserta en instalaciones nuevas.

El package ID definitivo es `com.projectgarage.app`. Migrar desde cualquier identificador anterior requiere exportar un backup e importarlo en la aplicación nueva; el sistema operativo no lo trata como actualización directa.
