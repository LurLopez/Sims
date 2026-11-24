# Arte del minijuego «Salir a correr» / PARK DASH

Revisión gráfica del **22 de noviembre de 2026**. Sustituye el antiguo escenario 100 % vectorial por un parque ilustrado con personaje animado por fotogramas y objetos de alta calidad, manteniendo el aspecto general del protagonista de SIMS.

## Fuentes

- **Mockup y sprites aportados por el usuario:** `mockup_escenario_carrera.jpg`, `sprite_moneda_oro.jpg`, `sprite_obstaculo_contenedor.jpg`, `sprite_obstaculo_valla.jpg` y `sprite_personaje_corredor.jpg`. Los originales viven fuera del repositorio; los recortes listos para el juego están en `Imagenes/Minijuego_Correr/`.
- **Generación asistida:** fondo de menú, poses del corredor, letrero, power-ups y escenografía de parque se generaron con el modelo de imagen del proyecto a partir de los sprites y el mockup como referencia de estilo. Los prompts están documentados en el diario del 22/11/2026.
- **Postproceso:** recorte por clave de color/alpha, eliminación de sombras horneadas, matte suave, recorte al bounding box y reescalado con alfa premultiplicado (Pillow + OpenCV).

## Archivos y uso

| Archivo | Tamaño | Uso |
|---|---|---|
| `fondo_menu.webp` | 941×1672 · 179 KB | Fondo del menú; recortado también para el cielo de la partida. |
| `fondo_parque.webp` | 941×610 · 33 KB | Franja de cielo, skyline y copas tras la pista. |
| `Personaje/run1-4.png` | ~330×520 · 160-168 KB | Ciclo de zancada. |
| `Personaje/idle.png` | 208×489 · 154 KB | Pose de menú. |
| `Personaje/jump.png` | 284×412 · 174 KB | Salto. |
| `Personaje/fall.png` | 392×449 · 211 KB | Caída. |
| `Personaje/slide.png` | 494×300 · 206 KB | Deslizamiento. |
| `Personaje/crash.png` | 411×412 · 214 KB | Choque. |
| `Personaje/celebrate.png` | 271×481 · 178 KB | Celebración. |
| `Objetos/moneda.png` | 310×360 · 114 KB | Moneda giratoria con estrella. |
| `Objetos/contenedor.png` | 556×620 · 292 KB | Obstáculo de carril. |
| `Objetos/valla.png` | 620×541 · 253 KB | Obstáculo saltable. |
| `Objetos/letrero.png` | 560×364 · 125 KB | Arco para deslizarse. |
| `Objetos/escudo.png` | 304×320 · 98 KB | Power-up de escudo. |
| `Objetos/iman.png` | 320×301 · 91 KB | Power-up de imán. |
| `Parque/*.png` | 187-407 px de ancho | Árboles, setos, banco, fuente, farola y flores. |

Total aproximado: **4,0 MB** de arte de runtime. Godot importa los PNG con alfa, genera mipmaps (para que los props lejanos no centelleen) y comprime las texturas para móvil según los ajustes del proyecto (`textures/vram_compression/import_etc2_astc=true`).

## Integración

- `Runner_Personaje.gd` precarga las poses y las dibuja ancladas por los pies; `Runner_Mundo.gd` precarga el fondo, los objetos y la escenografía.
- `Banner_Correr.gd` usa un recorte panorámico de `fondo_menu.webp` y los sprites del corredor, moneda, valla y contenedor.
- Las texturas se dibujan con `draw_texture_rect` y `draw_texture_rect_region`; no hay atlas porque cada sprite se usa por separado y el número de draws es reducido.
- El arte se ha revisado a tamaño real (720×1280) y en las capturas de `Documentacion/Capturas/` (menú, partida, salto, deslizamiento, power-ups, pausa y resultado).

## Verificación

- Capturas generadas con `godot --path . res://Escenas/Herramientas/Captura_Correr.tscn`.
- Comprobado que no quedan halos de fondo, sombras horneadas ni recortes en los bordes de los sprites principales.
- Tests del minijuego: 15/15 y 60 aserciones.

## Prompts y referencias (resumen)

- **Corredor, ciclo de zancada:** 4 fotogramas en una fila, vista de espaldas, misma altura y línea de pies, fondo magenta `#FF00FF`, referencia obligatoria del sprite `sprite_personaje_corredor.jpg`.
- **Corredor, poses:** 6 poses en 2×3 (idle, salto, caída, deslizamiento, choque y celebración), adjuntando el sprite original y la hoja de zancada para mantener identidad y proporciones.
- **Fondo de menú:** parque urbano vertical con camino central, skyline pastel, árboles, bancos, fuente, farolas y amanecer; sin personajes, texto, HUD ni obstáculos; el mockup se usó como referencia de estilo.
- **Escenografía:** hoja 2×4 de árbol, ciprés, seto redondo, banco, fuente, farola, seto alargado y jardinera de flores, con fondo magenta/transparente y sin sombras horneadas.
- **Letrero:** arco de madera con tablón verde, hueco inferior despejado y fondo blanco/magenta; se recortó por máscara para conservar el hueco.
- **Power-ups:** escudo cian con check y imán rojo con chispas, en hoja magenta de dos figuras.

Los prompts completos se conservan en el historial de generación del proyecto (22/11/2026). Cualquier nueva variante debe adjuntar el sprite original del corredor y mantener la misma escala de cabeza/cuerpo.
