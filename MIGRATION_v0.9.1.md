# Migración v0.9.1

Migración aditiva. Se conservan typeId 0–10 y se agrega `AppPreferences` con
typeId 11 y box `app_preferences`. No se eliminan boxes ni campos. Las
preferencias se inicializan con defaults históricos. Las seeds actuales
permanecen aisladas y su retiro definitivo queda preparado para v1.0.
