# Project Garage Design System 2.0

## Filosofía

Project Garage se presenta como una herramienta técnica premium para medir, documentar y completar una restauración. La interfaz prioriza precisión, estructura y legibilidad sobre decoración. No imita un taller tradicional ni una estética racing.

## Logo y significado

La única fuente oficial es `assets/branding/project_garage_logo_1024.png`: un hexágono técnico que representa estructura y tres segmentos que representan progreso documentado. Los dos segmentos claros muestran trabajo consolidado y el bordó identifica el siguiente avance. El símbolo nunca se deforma, recorta ni acompaña con autos, herramientas, texto o efectos decorativos.

El fondo oficial es `#0D0F12` y el acento es `#9F2436`. Los launcher icons, adaptive icons, splash, web, onboarding y About se derivan exclusivamente del archivo oficial.

## Paleta

- Background `#0D0F12`
- Surface `#171A1F`
- Elevated `#20242B`
- Highlight `#262B33`
- Primary `#9F2436`; interacción `#B9364A`
- Text `#F5F7FA`; secondary `#9BA3AE`; disabled `#66707D`
- Success `#58B77A`; warning `#DDA447`; danger `#E15B64`; info `#65A7D8`

El bordó comunica identidad y acción principal, nunca peligro. Los colores semánticos no se intercambian ni se usan como decoración.

## Geometría y bordes

`TechnicalCardBorder` aplica un único corte diagonal de 12 px a componentes destacados. Se reserva para progreso, métricas y estados importantes. Las tarjetas comunes conservan bordes redondeados limpios. Los bordes oficiales son subtle, active, selected y danger.

## Motion

Duraciones: instant 110 ms, fast 170 ms, normal 220 ms, emphasis 280 ms y hero 300 ms. Entrada usa `easeOutCubic`, cambio `easeInOutCubic` y salida `easeInCubic`. Toda animación funcional consulta `MediaQuery.disableAnimations`; no hay loops, bounce, elastic ni animaciones superiores a 350 ms. La presentación inicial del logo dura 780 ms y no bloquea la carga.

## Progreso

`ProjectProgressModule` es la firma visual del producto. Combina título, porcentaje textual, segmentos inclinados, estado e icono opcionales. Sus variantes compact, standard y detailed aceptan 0–100 %, cantidad configurable de segmentos, texto grande y Semantics. `AppProgressBar` mantiene la API existente y utiliza el mismo painter segmentado sin alterar cálculos.

## Tarjetas

`AppCard` ofrece standard, elevated, highlight, progress, warning, danger e image. Centraliza padding, ripple, selección, disabled, borde y elevación. El corte técnico es opt-in. Level 0 no tiene sombra; level 1 separa mínimamente; level 2 se reserva para overlays.

## Tipografía

Display 28–32/800–900; screen title 26–28/800; section 19–21/700–800; card 16–18/700; metric 22–30/800–900; body 14–16; caption y label 11–13. Los textos largos no usan mayúsculas y todo layout debe tolerar escala 2×.

## Iconografía

Los iconos son lineales y estables. `NavigationIconMapper`, `RepairCategoryIconMapper`, `FinanceCategoryIconMapper`, `MaintenanceCategoryIconMapper` y `TimelineEventIconMapper` centralizan significados. Las cinco pestañas permanecen Inicio, Vehículo, Taller, Finanzas y Bitácora.

## Navegación y formularios

La navegación usa superficie grafito elevada, indicador bordó sutil, etiquetas siempre visibles y targets de 48 px. Inputs usan surface, borde subtle, foco bordó y error danger; nunca reciben cortes diagonales.

## Accesibilidad y responsive

El porcentaje siempre aparece como texto y Semantics; ningún estado depende sólo del color. Se mantienen targets mínimos, tooltips, contraste y reduce-motion. En 320 px, landscape, tablet y split screen, segmentos y cortes se adaptan al ancho y los módulos permiten crecimiento vertical.

## Uso correcto

- Un módulo segmentado para el progreso principal.
- Una tarjeta técnica para una métrica o estado destacado.
- Bordó para la acción primaria; verde para confirmación.
- Fotos protagonistas con overlay grafito sólo para legibilidad.

## Uso incorrecto

- Repetir hexágonos como fondo o convertir todas las tarjetas en hexágonos.
- Usar llaves, engranajes, autos, emojis, neón o gradientes decorativos.
- Usar bordó como danger o verde como acento de marca.
- Sombras grandes, shimmer intenso, animaciones elásticas o loops.
- Valores arbitrarios de color, espaciado, radio o duración dentro de pantallas.
