# Project Garage — sistema visual

La identidad pública conserva grafito + bordó. El símbolo combina garage y herramienta sin marcas. Onboarding y pantallas legales soportan escala de texto 2.0, SafeArea y objetivos táctiles Material.

## Filosofía

Project Garage usa un lenguaje de tablero automotriz contemporáneo: oscuro,
técnico, robusto y preciso. La interfaz prioriza lectura y operación; el color de
acento identifica acciones y selección, nunca funciona como decoración. No se
usan neón, rebotes, brillos intensos ni gradientes salvo sobre fotografías para
preservar legibilidad.

## Paleta

| Token | Valor | Uso |
| --- | --- | --- |
| `background` | `#0D0F12` | Fondo principal |
| `surface` | `#171A1F` | Tarjetas y navegación |
| `surfaceElevated` | `#20242B` | Controles, menús y diálogos |
| `primary` | `#9F2436` | Acción principal y selección |
| `text` | `#F5F7FA` | Texto principal |
| `secondaryText` | `#9BA3AE` | Texto de apoyo |
| `disabledText` | `#66707D` | Contenido deshabilitado |
| `success` | `#58B77A` | Resultado correcto/completo |
| `warning` | `#DDA447` | Atención/proceso |
| `danger` | `#E15B64` | Error o acción destructiva |
| `info` | `#65A7D8` | Información neutral |

Los bordes son blanco al 8 % y los divisores blanco al 10 %. Los estados
incluyen siempre texto o icono además del color.

## Tipografía

Se utiliza la fuente del sistema. `AppTextStyles` define: título de pantalla
29/800, título de sección 20/800, título de tarjeta 17/700, métrica 24/800,
cuerpo 15/400, subtítulo 14 y caption/label 12. Las mayúsculas se reservan para
microetiquetas y estados breves.

## Espaciado y radios

`AppSpacing` usa la escala 4, 8, 12, 16, 20, 24 y 32. `AppRadius` ofrece 12,
16, 24, 30 y pill (999). Las tarjetas usan radio 24 y padding base 20; los
controles usan radio 16 y una superficie táctil mínima de 48 px.

## Tarjetas

`AppCard` es la única base de tarjeta y ofrece variantes `standard`,
`highlight`, `warning` y `danger`. Todas comparten padding, radio, borde tenue y
elevación mínima. Una tarjeta con imagen puede componer `AppCard` con una foto y
un degradado negro únicamente detrás del texto.

```dart
AppCard(
  variant: AppCardVariant.highlight,
  child: Text('Próximo objetivo'),
)
```

## Botones y formularios

- Primario: `FilledButton` o `AppButton`, bordó, altura mínima 48.
- Secundario: `OutlinedButton`, borde sutil.
- Terciario: `TextButton`.
- Destructivo: `AppButton(isDestructive: true)`.
- Iconos: superficie táctil mínima 48 y tooltip descriptivo.

`AppTheme.inputDecorationTheme` centraliza relleno, superficies, bordes, foco,
error, labels y hints para `TextField`, `DropdownButtonFormField` y formularios.
Los switches también heredan estados globales; no se deben recrear decoraciones
por pantalla.

## Chips y estados

`PriorityChip`, `StatusChip` y los chips Material usan forma pill, tipografía de
12 px y fondos tonales de baja opacidad. Verde significa completado, ámbar en
proceso, rojo pendiente/error y gris sin datos. Texto e icono hacen comprensible
el estado sin depender sólo del color.

## Iconos

`AppIcons` mantiene los conceptos principales: tablero, vehículo, taller,
finanzas, bitácora, mantenimiento, evidencia y kilometraje.
`RepairCategoryIconMapper` resuelve categorías técnicas conocidas y usa taller
como fallback. Un concepto debe conservar el mismo icono en toda la app.

## Movimiento y elevación

`AppDurations`: fast 140 ms, normal 220 ms, slow 320 ms. `AppCurves` usa
`easeOutCubic` en entradas y `easeInOutCubic` en cambios. `AppShadows` limita la
elevación a una sombra tenue. Las animaciones comunican aparición, selección o
progreso; no se animan grupos completos sin propósito.

## Evitar

- Colores, radios, sombras o `InputDecoration` nuevos dentro de una pantalla.
- Emojis como iconografía funcional.
- Bordes blancos brillantes, neón o gradientes decorativos.
- Estados diferenciados sólo por color.
- Botones de menos de 48 px o acciones de icono sin tooltip.
- Animaciones largas, elásticas, rotaciones o efectos simultáneos masivos.

## Patrones financieros

Los importes principales usan `metricValue`; las transacciones muestran icono de
categoría, estado textual y signo. Verde identifica ingresos o pagos completos,
ámbar pagos parciales/cercanía al límite y rojo deuda o sobrecosto. El progreso
de presupuesto se limita visualmente a 100 %; el exceso se expresa aparte como
“Excedido por” y nunca como una cifra disponible negativa.
# Design System 2.0

La especificación vigente es [PROJECT_GARAGE_DESIGN_SYSTEM_2.md](PROJECT_GARAGE_DESIGN_SYSTEM_2.md). Este documento anterior se conserva como referencia histórica; ante diferencias prevalece la versión 2.0 y el logo oficial `assets/branding/project_garage_logo_1024.png`.
