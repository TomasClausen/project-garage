# Guía de backup y restauración

Abrir Configuración → Backup y restauración.

- Crear genera y valida el archivo antes de mostrar éxito.
- Fusionar conserva datos, remapea colisiones y relaciones, y evita una segunda
  importación legacy financiera.
- Reemplazar exige confirmación y crea primero un backup automático verificado.

Hive y filesystem no comparten transacción. La compensación restaura el backup
automático si falla un reemplazo; el resultado informa si el rollback se aplicó.
