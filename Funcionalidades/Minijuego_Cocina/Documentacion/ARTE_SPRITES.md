# Pack de sprites del escenario — Minijuego de Cocina

## 1. Resumen

Pack de **152 sprites PNG** para el escenario del minijuego de cocina de estilo casual —134 del pack base + 15 de mejoras + **3 fondos de los mundos nuevos**—, más **3 recursos de composición** para el banner de la tarjeta «Cocina» y el fondo del selector (`Banner_Cocina.png`, `Emplatado/Plato_Perspectiva.png` y `Fondo_Restaurante_Selector.png`), un **layout JSON** y una **escena editable de muestra a 1280×720** que reproduce la composición de referencia: chef a la izquierda, cuatro clientes tras el mostrador, tickets de pedido, vitrina, estaciones de cocina y primer plano de acero inoxidable. Las **15 ilustraciones de mejoras** (`Mejoras/`) son nuevas y se usan en la pantalla de Mejoras.

- Arte **original generado por IA** (no se han extraído sprites del juego original).
- Dirección: 2.5D casual, brillos suaves, colores saturados, perspectiva ligeramente cenital.
- Los maestros, hojas de generación, prompts y catálogos viven en `Arte_Fuente/Minijuego_Cocina/` (ignorado por Godot mediante `Arte_Fuente/.gdignore`).
- El pack **está integrado en el minijuego jugable** mediante `Scripts/GUI/Minijuego_Cocina/Arte_Cocina.gd`; la escena de muestra sigue siendo una maqueta independiente para revisar el arte completo.

## 2. Alcance

**Incluido**

- 134 PNG RGBA en `Imagenes/Minijuego_Cocina/` con sus `.import` de Godot.
- 15 PNG RGBA de mejoras en `Imagenes/Minijuego_Cocina/Mejoras/` (3 variantes por mejora), con sus `.import`.
- 3 recursos de composición fuera del pack: `Banner_Cocina.png` (1288×284, RGB), `Emplatado/Plato_Perspectiva.png` (640×297, RGBA) y `Fondo_Restaurante_Selector.png` (360×640, RGBA, generado por `tools/generar_fondo_selector.py`). Los dos primeros conservan maestros en `Arte_Fuente/Minijuego_Cocina/`.
- `Imagenes/Minijuego_Cocina/escenario_layout.json` con 54 entradas de composición (`ruta`, `x`, `y`, `w`, `h`, `modo`).
- Escena de muestra `Escenas/Minijuego_Cocina/Escenario_Maqueta_Cocina.tscn` y su controlador `Scripts/GUI/Minijuego_Cocina/Escenario_Maqueta_Cocina.gd`.
- Herramientas reproducibles en `tools/` y catálogos visuales en `Arte_Fuente/Minijuego_Cocina/Catalogo/`.

**Excluido**

- Lógica, economía, niveles, pedidos y temporizadores del minijuego jugable (viven en `Sistema_Cocina` y `Minijuego_Cocina.gd`).
- Integración visual en la escena jugable: `Minijuego_Cocina.gd` usa `Arte_Cocina.gd` para cargar fondo, clientes, chef, estaciones, comida, tickets, UI y efectos. `Sprites_Cocina.gd` queda como implementación vectorial legacy.
- Capturas del juego real: `Funcionalidades/Minijuego_Cocina/Documentacion/Capturas/`.
- Animaciones de personajes, audio, textos localizados, atlas de sprites o `SpriteFrames`.
- Revisión legal para publicación comercial (ver aviso legal).

## 3. Inventario completo

| Carpeta | Nº | Contenido |
|---|---:|---|
| `Chef/` | 7 | Chef protagonista + 6 poses |
| `Clientes/` | 8 | Bustos de clientes |
| `Clientes/Enojados/` | 8 | Las mismas ocho caras enfadadas |
| `Comida/Platos/` | 8 | Platos terminados e iconos de pedido |
| `Comida/Ingredientes/` | 12 | Insumos y estados de carne/salchicha |
| `Comida/Extras/` | 12 | Platos y bebidas adicionales |
| `Estaciones/` | 8 | Máquinas y estaciones de cocina |
| `Mostrador/` | 8 | Módulos, vitrina, caja y tiras de mostrador |
| `Emplatado/` | 22 | Platos, bandejas, salsas, utensilios y props |
| `UI/` | 28 | 24 del pack + 4 botones glossy 9-patch de los modales (`Boton_Modal_*`); HUD, tickets, monedas, botones y estrellas |
| `Decoracion/` | 8 | Toldos, rótulos, planta, lámpara y trofeo |
| `Efectos/` | 8 | Vapor, humo, chispas, fuego, monedas, estrellas, frescura y enfado |
| `Mejoras/` | 15 | Tres variantes (Nv.1/Nv.2/Nv.3) de cada una de las 5 mejoras |
| `Fondos/` | 3 | Fondos 16:9 de Bistró, Mercado y Alta Cocina (1280×720) |
| Raíz | 1 | `Fondo_Restaurante.png` |
| **Total** | **152** | |

La carpeta `Emplatado/` contiene además `Plato_Perspectiva.png`, la raíz contiene `Banner_Cocina.png` y `Fondo_Restaurante_Selector.png`; los tres son recursos de composición y no se cuentan en los 149 sprites del pack. Se detallan a continuación.

### Recursos de composición (fuera de los 149)

| Archivo | Tamaño | Maestro | Uso |
|---|---:|---|---|
| `Banner_Cocina.png` (raíz) | 1288×284 | `Arte_Fuente/Minijuego_Cocina/Fondos/banner_cocina_maestro.png` (1913×822) | Fondo del banner de la tarjeta «Cocina» en `Pantalla_Minijuegos`: mostrador de diner con damero crema/negro, borde metálico inferior y comedor desenfocado detrás. Lleva horneados el desenfoque de fondo, la viñeta y la luz cálida. |
| `Emplatado/Plato_Perspectiva.png` | 640×297 | `Arte_Fuente/Minijuego_Cocina/plato_perspectiva_maestro.png` (1336×1177) | Plato vacío de cerámica blanca en perspectiva 3/4 (ala, hueco, brillos y transparencia limpia) para el banner y el pase jugable; en esas composiciones sustituye al plato cenital `Plato_Vacio.png`. |
| `Fondo_Restaurante_Selector.png` (raíz) | 360×640 | Generado con `tools/generar_fondo_selector.py` desde `Fondo_Restaurante.png` | Fondo vertical desenfocado y viñeteado del selector cartoon de niveles; se usa detrás del marco celeste y no forma parte del pack. |

### Fondos de los mundos nuevos (`Fondos/`)

Los tres fondos 16:9 se generaron a partir de los prompts de `Arte_Fuente/Minijuego_Cocina/prompts_fondos_restaurantes.md` y se redujeron a **1280×720** con Lanczos. Los maestros viven en `Arte_Fuente/Minijuego_Cocina/Fondos/`.

| Archivo | Mundo | Maestro | Uso |
|---|---|---|---|
| `Fondos/Fondo_Bistro.png` | Bistró Tradicional | `fondo_bistro_maestro.png` | Comedor francés con banquinas burdeos, mármol, latón, cafetera y vitrina de postres. |
| `Fondos/Fondo_Mercado.png` | Cocina de Mercado | `fondo_mercado_maestro.png` | Taberna mediterránea con azulejos azules, vigas, jamones, horno de leña y puestos de verdura. |
| `Fondos/Fondo_Alta_Cocina.png` | Alta Cocina Gourmet | `fondo_alta_cocina_maestro.png` | Comedor de lujo en hora azul con paneles azul noche, lámparas de latón, mesas de mantel blanco y bodega. |

Se cargan con `Arte_Cocina.fondo_restaurante(id)` y se usan en la cocina, la pantalla de carga y la miniatura de la tarjeta de mundo. Los tres están marcados como **VRAM comprimida (ETC2/S3TC)** con `tools/optimizar_import_texturas.py`.

Se consumen desde `Scripts/GUI/Minijuego_Cocina/Arte_Cocina.gd` (`TEX_BANNER`, `TEX_PLATO_PERSPECTIVA` y la textura cacheada `textura_sombra_contacto()`) y `Scripts/Globales/Script_Principal.gd` (`_Actualizar_Pantalla_Minijuegos()`, `_Anadir_Item_Banner()`, `_Anadir_Sombra_Banner()`).

### `Chef/` (7)

- `Chef_Michelle.png` — cuerpo entero de la chef protagonista.
- `Poses/Chef_Pulgar_Arriba.png`
- `Poses/Chef_Sirviendo.png`
- `Poses/Chef_Sorprendida.png`
- `Poses/Chef_Enfadada.png`
- `Poses/Chef_Brazos_Cruzados.png`
- `Poses/Chef_Celebrando.png`

### `Clientes/` (8)

- `Cliente_01_Nino.png`, `Cliente_02_Mujer.png`, `Cliente_03_Mayor.png`, `Cliente_04_Nina.png`
- `Cliente_05_Ejecutivo.png`, `Cliente_06_Abuela.png`, `Cliente_07_Adolescente.png`, `Cliente_08_Nina_Pequena.png`

### `Clientes/Enojados/` (8)

- `Cliente_01_Nino_Enojado.png`, `Cliente_02_Mujer_Enojado.png`, `Cliente_03_Mayor_Enojado.png`, `Cliente_04_Nina_Enojado.png`
- `Cliente_05_Ejecutivo_Enojado.png`, `Cliente_06_Abuela_Enojado.png`, `Cliente_07_Adolescente_Enojado.png`, `Cliente_08_Nina_Pequena_Enojado.png`

### `Comida/Platos/` (8)

`Hamburguesa_Sola.png`, `Hamburguesa_Doble.png`, `Perrito_Caliente.png`, `Patatas_Fritas.png`, `Refresco_Cola.png`, `Batido.png`, `Cupcake.png`, `Bocadillo_Pollo.png`.

### `Comida/Ingredientes/` (12)

`Pan_Superior.png`, `Pan_Inferior.png`, `Carne_Cruda.png`, `Carne_Hecha.png`, `Carne_Quemada.png`, `Salchicha_Cruda.png`, `Salchicha_Hecha.png`, `Queso.png`, `Lechuga.png`, `Tomate.png`, `Cebolla.png`, `Pepinillo.png`.

### `Comida/Extras/` (12)

`Hamburguesa_Bacon.png`, `Hamburguesa_Veggie.png`, `Corn_Dog.png`, `Aros_Cebolla.png`, `Nachos.png`, `Ensalada.png`, `Helado.png`, `Donut.png`, `Cafe.png`, `Zumo_Naranja.png`, `Agua.png`, `Tarta_Cereza.png`.

### `Estaciones/` (8)

`Plancha.png`, `Freidora.png`, `Dispensador_Refrescos.png`, `Calentador_Comida.png`, `Tostador_Panes.png`, `Vitrina_Preparacion.png`, `Cafetera.png`, `Papelera.png`.

### `Mostrador/` (8)

`Modulo_Recto.png`, `Modulo_Esquina.png`, `Vitrina_Exposicion.png`, `Caja_Registradora.png`, `Pase_Servicio.png`, `Fregadero.png`, `Frente_Mostrador.png`, `Encimera_Larga.png`.

### `Emplatado/` (22)

`Plato_Vacio.png`, `Pila_Platos.png`, `Bandeja_Metal.png`, `Bandeja_Tomate.png`, `Bandejas_Apiladas.png`, `Cesta_Patatas.png`, `Bol_Lechuga.png`, `Salsera.png`, `Ketchup.png`, `Mostaza.png`, `Sal_Pimienta.png`, `Rastrillo_Salsas.png`, `Pinzas.png`, `Espatula.png`, `Tabla_Cortar.png`, `Servilleta.png`, `Servilletero.png`, `Tarro_Pepinillos.png`, `Vasos_Rojos.png`, `Tapas_Vasos.png`, `Pajitas.png`, `Limpiador.png`.

> **Emplatado en el juego:** el pase es un puesto 3D. La base es la bandeja metálica renderizada `Emplatado/Bandeja_Metal.png`, con borde, paredes interiores y sombra de contacto; dentro va una alfombrilla beige hundida y detrás una mampara de cristal con marco cromado y filo verde (`Arte_Cocina.Fondo_Pase`). El pase muestra **siempre cuatro huecos**: al empezar se abren dos y las mejoras de Emplatado abren el tercero (`Nv.2`) y el cuarto (`Nv.3`); los cerrados son rebajes metálicos con candado y una pastilla de nivel. Los platos activos usan `Emplatado/Plato_Perspectiva.png` (640×297, `PLATO_PERSPECTIVA = 0.464`), cerámica 3/4 con filo celeste grueso. El plato se centra en su hueco con `ancho_plato_visible()` y `centro_plato_visible()`, y deja un margen de 2 px en cada celda; el ancho se acota por la celda para que los cuatro platos compartan la misma línea de base sin invadir la celda vecina. `Bandeja_Metal.png` también se usa para la bandeja de carne cruda.
>
> **Filete del Bistró:** `Arte_Cocina.dibujar_filete()` dibuja por código un filete con hueso en 3/4, costra, veteado de grasa, marcas de parrilla, hueso lateral con nudillos, brillo de jugo y romero. El color de la carne y el centro rosado cambian con el punto (`crudo`, `poco_hecho`, `al_punto`, `hecho`, `quemado`). Se usa en la parrilla, el pase, los tickets, la despensa y las ilustraciones de mejoras; al ser vectorial escala de 30 a 220 px sin perder nitidez. `dibujar_plato_bistro()` monta el plato 3/4 del pack con el filete, la salsa y un abanico de patatas alineado con el borde.
>
> **Alineación de iconos y capas:** los PNG de `Comida/Ingredientes` y `Comida/Platos` llevan ~10 px de margen transparente y encuadres distintos, así que no se pueden alinear por el tamaño de la textura. `Arte_Cocina.region_contenido()` calcula una sola vez (y cachea) el rectángulo de píxeles visibles con alfa > 24 y `dibujar_tex_recortada()` dibuja solo esa región. La bandeja inferior usa `rect_icono_alineado()` para que los seis iconos compartan línea de base (y = 70), centro horizontal (x = 49) y altura máxima (56 px) sin deformar su proporción; el icono de «Pan» es `Pan_Superior.png`, igual que el fantasma del plato vacío. La hamburguesa se compone con `_capas_hamburguesa()`, que fija ancho, alto y solape de cada capa sobre un eje común de 120 unidades. El fantasma del pan y su botón «+» comparten el centro del plato, de modo que quedan siempre alineados.

### `UI/` (28: 24 del pack + 4 botones 9-patch)

`Ticket_Verde.png`, `Ticket_Rojo.png`, `Moneda.png`, `Pila_Monedas.png`, `Gema.png`, `Reloj.png`, `Bote_Propinas.png`, `Burbuja.png`, `Boton_Verde.png`, `Boton_Azul.png`, `Boton_Naranja.png`, `Boton_Check.png`, `Boton_X.png`, `Flecha.png`, `Engranaje.png`, `Estrella_Dorada.png`, `Estrella_Plateada.png`, `Estrella_Vacia.png`, `Corazon.png`, `Candado_Abierto.png`, `Candado_Cerrado.png`, `Insignia_Nivel.png`, `Regalo.png`, `Cinta_Dorada.png`.

Además, `Boton_Modal_Azul.png`, `Boton_Modal_Verde.png`, `Boton_Modal_Naranja.png` y `Boton_Modal_Rojo.png` (600×64) son texturas 9-patch de los botones glossy de los modales, generadas con `tools/generar_botones_modal.py` a partir de `Boton_Azul/Verde/Naranja.png` (el rojo, por rotación de tono y refuerzo de saturación). No forman parte del pack original: los remaches laterales se conservan y el centro se rellena con una columna estirable.

### `Decoracion/` (8)

`Toldo_Verde.png`, `Toldo_Rojo.png`, `Pizarra.png`, `Rotulo.png`, `Reloj_Pared.png`, `Trofeo.png`, `Planta.png`, `Lampara.png`.

### `Efectos/` (8)

`Vapor.png`, `Humo.png`, `Chispas.png`, `Monedas.png`, `Fuego.png`, `Estrellas.png`, `Frescura.png`, `Enfado.png`.

### `Mejoras/` (15)

Tres variantes por cada mejora, de básica a profesional:

- `plancha_nv1.png`, `plancha_nv2.png`, `plancha_nv3.png` — sartén/plancha con 2, 3 y 4 hamburguesas.
- `emplatado_nv1.png`, `emplatado_nv2.png`, `emplatado_nv3.png` — 1, 2 y 3 servicios con plato y refresco.
- `termostato_nv1.png`, `termostato_nv2.png`, `termostato_nv3.png` — dial manual, dial de precisión y panel digital.
- `ingredientes_nv1.png`, `ingredientes_nv2.png`, `ingredientes_nv3.png` — caja de madera, bandeja de acero y cesta premium.
- `ambiente_nv1.png`, `ambiente_nv2.png`, `ambiente_nv3.png` — jukebox de mesa, jukebox de diner y jukebox de lujo.

El **Bistró Tradicional** no reutiliza estas láminas de hamburguesas: sus cinco mejoras se dibujan por código con `Arte_Cocina.dibujar_mejora_bistro()` (parrilla con filetes, pase con platos y café, dial del punto, tabla de género y comedor). La tarjeta grande y los iconos de 48 px usan la misma composición en dos escalas, y los textos de beneficios/frases salen de `MEJORAS_UI_POR_RESTAURANTE`; así el Bistró no muestra «vasos de refresco» ni una plancha de burgers.

Se generaron con el modelo de imagen a partir de cinco hojas maestras (`Arte_Fuente/Minijuego_Cocina/Mejoras/hoja_<mejora>.png`), cada una con las tres variantes en fila sobre magenta. El procesado es reproducible con:

```bash
python3 tools/procesar_mejoras_cocina.py
```

El script recorta cada variante, limpia el halo blanco, aplica un **despill de magenta más agresivo** que el estándar (los vapores y brillos semitransparentes quedan grises en vez de rosados), limita el lado mayor a 640 px y guarda los PNG con optimización. También compone el catálogo de control `Arte_Fuente/Minijuego_Cocina/Mejoras/catalogo_mejoras.png`. Los prompts están documentados en `Arte_Fuente/Minijuego_Cocina/prompts.md` (P22–P26).

### Raíz (1)

`Fondo_Restaurante.png` — diner a 1280×720, con la franja inferior despejada para colocar sprites.

Nombres en `PascalCase_Con_Guiones_Bajos`, sin acentos (`Nina`, `Pequena`) para evitar problemas de codificación en rutas.

## 4. Guía de estilo

- **Registro visual:** 2.5D casual *mobile*, formas tipo vector con sombreado suave, contornos limpios, brillos puntuales y colores saturados. No es pixel art.
- **Perspectiva:** tres cuartos ligeramente cenital; los alimentos se leen desde arriba y los clientes son bustos recortados a la altura del pecho.
- **Iluminación:** cálida y alegre, con luces suaves y reflejos en metal, cristal y salsas.
- **Paleta de referencia** (coherente con la UI y con `Sprites_Cocina.gd`):
  - Teal `#0d9488` — paredes, rótulos y acentos.
  - Rojo cereza `#dc2626` — mostrador, delantal, toldos y tickets de urgencia.
  - Crema `#fdf8f0` — papel, platos y zonas neutras.
  - Amarillo dorado `#facc15` — monedas, estrellas y luces.
  - Acero `#cbd5e1` — encimeras, máquinas y cubiertos.
  - Verde fresco `#16a34a` — vegetales y toldos.
- **Fondos:** las hojas se generaron sobre magenta `#FF00FF` y se recortaron a alfa; los efectos se generaron sobre negro para usarlos con mezcla aditiva.
- **Sin texto:** los sprites no llevan letras, precios ni logotipos; los textos del HUD y de los tickets son `Label` de la escena.
- **Toldos:** algunos están cortados a propósito en el borde de la hoja para usarlos como bandas decorativas.

## 5. Escena de muestra

| Archivo | Rol |
|---|---|
| `Escenas/Minijuego_Cocina/Escenario_Maqueta_Cocina.tscn` | Escena editable de 1280×720. 76 nodos: 2 `Control`, 59 `TextureRect` (58 del layout + fondo), 9 `Label` y 6 `ColorRect` (fondo de ventana, HUD y estante). |
| `Scripts/GUI/Minijuego_Cocina/Escenario_Maqueta_Cocina.gd` | Formato horizontal, animación idle, cierre con `Esc` y captura opcional. |
| `Imagenes/Minijuego_Cocina/escenario_layout.json` | Layout de origen (58 entradas) usado por el generador. |
| `Arte_Fuente/Minijuego_Cocina/escenario_godot_1280x720.png` | Captura real del resultado en Godot. |
| `Arte_Fuente/Minijuego_Cocina/escenario_preview.png` | Composición de referencia hecha con PIL. |

La composición muestra a la chef a la izquierda, cuatro clientes con sus tickets, una vitrina de exposición, tres módulos de mostrador, plancha, freidora, dispensador, calentador, tostador, caja registradora y una franja de acero inoxidable en primer plano. Los tickets llevan precios como `Label` (12, 10, 8, 6 en la muestra).

Abrir:

```bash
./ver_escenario.sh
# Captura a user://escenario_cocina_godot.png y cierra:
./ver_escenario.sh --captura
```

La escena fija `content_scale_size = 1280×720`, rota a horizontal en Android/iOS y restaura el formato vertical al salir. En escritorio abre una ventana de 1280×720.

**Animación idle:** el script mueve los nodos del grupo `ticket` (tickets y sus precios), del grupo `chef`, 3 nodos de `vapor` sobre la plancha/freidora y 1 de `sparkle` sobre las monedas.

La escena de muestra no se instancia desde `Minijuego_Cocina.tscn`, pero el pack sí se consume desde el juego real. La maqueta se conserva para revisar el arte completo con `ver_escenario.sh`.

## 6. Pipeline reproducible

| Herramienta | Función |
|---|---|
| `Arte_Fuente/Minijuego_Cocina/prompts.md` | Prompts de las 19 hojas (P1–P19) con estilo, encuadre y fondo indicados. |
| `tools/cortar_sprites.py` | Recorta hojas con alfa o magenta, elimina fleco, erosiona, limpia motas y genera preview. Si la hoja ya tiene alfa útil, la usa; si no, aplica *keying* de magenta con *despill*. |
| `tools/optimizar_sprites.py` | Copia maestros a `Arte_Fuente/.../Sprites_Full/` (solo si la carpeta no existe) y reduce los PNG de runtime según límites por carpeta. |
| `tools/componer_escenario.py` | Compone el preview 1280×720 con sombras y texto, y escribe `escenario_layout.json`. |
| `tools/generar_escena_godot.py` | Genera el `.tscn` editable a partir del layout. |
| `tools/catalogo_sprites.py` | Genera los cuatro catálogos visuales por categorías. |

Flujo típico:

```bash
python3 tools/cortar_sprites.py hoja.png salida --names a,b,c --grid 4x3 --erode 3 --preview check.png
python3 tools/optimizar_sprites.py
python3 tools/componer_escenario.py
python3 tools/generar_escena_godot.py
python3 tools/catalogo_sprites.py
godot --headless --path . --editor --quit   # importar PNG nuevos
```

Los recursos de composición no salen de hojas: el banner y el plato se generaron como imágenes completas y se conservan como maestros en `Arte_Fuente/Minijuego_Cocina/` (`Fondos/banner_cocina_maestro.png` y `plato_perspectiva_maestro.png`); el fondo del selector es procedural (`tools/generar_fondo_selector.py`). Los PNG de runtime del banner y el plato son versiones reducidas (1288×284 y 640×297) con los mismos parámetros de importación que el pack; no pasan por `cortar_sprites.py` ni por `componer_escenario.py`.

Notas del recorte:

- `--grid COLSxROWS` corta celdas iguales; sin `--grid` se detectan blobs conectados y se agrupan por filas.
- `--erode N` elimina el fleco blanco del *keying*; requiere OpenCV.
- `--alpha-cutoff N` descarta píxeles por debajo de ese alfa (útil para quitar tableros horneados).
- `--no-clean` conserva motas sueltas, necesario en hojas de efectos.
- `--trim-white` recorta el halo blanco de contorno.

Advertencias:

- `optimizar_sprites.py` **no sobreescribe** maestros existentes: si `Sprites_Full/` ya existe, solo reduce los PNG de runtime. Para refrescar maestros hay que mover o borrar esa carpeta antes.
- `generar_escena_godot.py` reescribe `Escenario_Maqueta_Cocina.tscn`; si se edita la escena a mano, se pierden los cambios al regenerar.
- Las hojas originales y los maestros no se importan en Godot porque `Arte_Fuente/.gdignore` corta esa carpeta.

## 7. Cómo usarlo en Godot

### Sprite suelto

Para respetar la proporción dentro de un rectángulo concreto:

```gdscript
var icono := TextureRect.new()
icono.texture = preload("res://Imagenes/Minijuego_Cocina/Comida/Platos/Hamburguesa_Sola.png")
icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
icono.custom_minimum_size = Vector2(96, 96)
```

La escena de muestra usa `expand_mode = 1` (`EXPAND_IGNORE_SIZE`) y `stretch_mode = 0` (`STRETCH_SCALE`) porque cada rectángulo ya tiene la proporción del sprite. Para un `Sprite2D`, basta asignar `texture` y ajustar `scale`; el filtro lineal por defecto es el adecuado al ser arte no pixel.

### Efectos aditivos

`Chispas`, `Fuego`, `Monedas` y `Estrellas` están pensados para sumar luz:

```gdscript
var mat := CanvasItemMaterial.new()
mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
$Chispas.material = mat
```

`Vapor`, `Humo` y `Enfado` tienen alfa y funcionan con mezcla normal; con aditivo se vuelven más luminosos pero pierden cuerpo. En la escena de muestra no hay efectos colocados.

### Mostrador con 9-slice

`Frente_Mostrador.png` (1600×232) y `Encimera_Larga.png` (1600×242) son tiras largas. Para estirarlas sin deformar los extremos:

```gdscript
var frente := NinePatchRect.new()
frente.texture = preload("res://Imagenes/Minijuego_Cocina/Mostrador/Frente_Mostrador.png")
frente.patch_margin_left = 96
frente.patch_margin_right = 96
frente.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_STRETCH
```

En la muestra, `Frente_Mostrador` se estira a 1280×200 y `Encimera_Larga` se usa como banda; para patrones repetidos se puede probar `AXIS_STRETCH_MODE_TILE`.

### Tickets y HUD

- `Ticket_Verde.png` / `Ticket_Rojo.png` son el papel; el icono del plato y el precio se superponen como nodos hijos (`TextureRect` + `Label`), no van horneados en el sprite.
- Los botones, estrellas, monedas y candados ya incluyen brillo; no necesitan `StyleBox` adicional.
- Para un icono de UI se recomienda `custom_minimum_size` de 48–96 px y `STRETCH_KEEP_ASPECT_CENTERED` para no deformar.

### Capas

La escena usa `z_index` crecientes: fondo 0, clientes 12–18, vitrina 20, comida de pedido 22–28, chef 30, tickets 32–44, mostrador 48–54, estaciones 56–66, emplatado y props 68–98, HUD 100–118 y textos 200. Mantén ese orden al añadir nodos.

## 8. Tamaños, encoding y rendimiento

| Grupo | Tamaño real (px) |
|---|---|
| `Chef/Chef_Michelle.png` | 422×900 |
| `Chef/Poses/` | 275–398 × 484–489 |
| `Clientes/` y `Clientes/Enojados/` | 253–320 × 314–320 |
| `Comida/Platos/` | 207–388 × 280–416 |
| `Comida/Ingredientes/` | 368–436 × 226–315 |
| `Comida/Extras/` | 119–358 × 254–353 |
| `Estaciones/` | 285–420 × 314–420 |
| `Mostrador/` | 392–1600 × 232–432 |
| `Emplatado/` | 141–300 × 142–300 |
| `UI/` | 217–300 × 117–300 |
| `Decoracion/` | 317–420 × 206–420 |
| `Efectos/` | 187–280 × 242–280 |
| `Fondo_Restaurante.png` | 1280×720 |
| `Banner_Cocina.png` | 1288×284 |
| `Emplatado/Plato_Perspectiva.png` | 640×297 |

- **Formato:** 149 PNG del pack en RGBA de 8 bits por canal, sin perfil ICC incrustado (Godot los interpreta como sRGB) y sin indexar. Los tres recursos de composición añaden un PNG opaco en RGB (`Banner_Cocina.png`) y dos en RGBA (`Plato_Perspectiva.png` y `Fondo_Restaurante_Selector.png`).
- **Importación:** los 152 PNG tienen `.import` con `compress/mode=2` y `compress/high_quality=false` (VRAM comprimida: ETC2 en Android, S3TC/BPTC en escritorio), `mipmaps/generate=false`, `process/fix_alpha_border=true` y filtro lineal por defecto. No hay atlas ni `SpriteFrames`. Se aplica con `python3 tools/optimizar_import_texturas.py` y `godot --headless --import`; el resto de texturas del juego (iconos pequeños, marca) se queda en lossless.
- **Peso:** ~26,2 MB de PNG de runtime (149 del pack: ~25,6 MB; 3 de composición: ~0,6 MB); el más pesado es el fondo (~1,39 MB). En memoria, las versiones ETC2 ocupan ~4-8× menos que RGBA y el APK queda en ~62 MB.
- **Carga perezosa:** `Arte_Cocina.gd` no usa `preload` de texturas: cada `TEX_*` es un `static var` con getter a `_tex(ruta)` y caché. Así el menú y la escena principal no cargan los ~72 MB del pack; las texturas se decodifican al dibujarse por primera vez en la cocina.
- **Maestros:** `Arte_Fuente/Minijuego_Cocina/Sprites_Full/` contiene **134 PNG** e incluye los 8 clientes enfadados. Las 15 mejoras tienen sus hojas maestras en `Arte_Fuente/Minijuego_Cocina/Mejoras/` y se procesan con `tools/procesar_mejoras_cocina.py`. Los maestros de composición quedan fuera de esas carpetas: `Fondos/banner_cocina_maestro.png` y `plato_perspectiva_maestro.png`; ninguna de esas rutas se importa en Godot.

## 9. Catálogos visuales

`Arte_Fuente/Minijuego_Cocina/Catalogo/` (JPG, fuera de `res://` por `.gdignore`):

- `catalogo_1_comida.jpg` — platos, ingredientes y extras (32).
- `catalogo_2_personajes.jpg` — chef, poses, clientes y enfadados (23).
- `catalogo_3_cocina.jpg` — estaciones, mostrador, emplatado y props (38).
- `catalogo_4_ui_y_ambiente.jpg` — UI, decoración y efectos (40).

Sirven para revisar el pack completo de un vistazo; se regeneran con `tools/catalogo_sprites.py`.

## 10. Limitaciones conocidas

- **Botella de agua:** `Comida/Extras/Agua.png` se recortó con una máscara de silueta manual porque el modelo la generó sobre fondo azul; el borde puede ser algo más duro que el resto.
- **Erosión:** varios sprites llevan una erosión de 1–4 px para quitar el fleco blanco del *keying*; a tamaño de juego no se aprecia, pero en zooms grandes pueden perder un píxel de contorno.
- **Tamaños de comida:** algunos PNG de `Comida/` superan el límite nominal de 320 px del optimizador (hasta 436 px de ancho y 416 px de alto); el estado actual no refleja una pasada estricta. Si se necesita un tope, hay que volver a ejecutar `tools/optimizar_sprites.py` sobre una copia.
- **Toldos:** están cortados a propósito en el borde de la hoja; no son sprites completos.
- **Frente de mostrador:** se estira a 1280×200 en la muestra; no está pensado para escalar verticalmente sin pérdida. Usar 9-slice o repetir la encimera.
- **Tickets:** los precios son `Label`, no sprite, para poder cambiarlos por código.
- **Escena de muestra:** es una maqueta visual; no sustituye al minijuego jugable, pero el pack sí está integrado en la cocina real. Incluye 3 nodos de vapor y 1 de chispas animados.
- **Fondo:** está horneado a 1280×720; en otras relaciones de aspecto hay que recortarlo o rellenar.
- **Banner:** está horneado a 1288×284 (≈4,5:1) y es opaco; la tarjeta lo muestra con `STRETCH_KEEP_ASPECT_COVERED` en una franja de 142 px de alto, así que en anchos extremos se recorta por los lados.
- **Plato en perspectiva:** `Emplatado/Plato_Perspectiva.png` se usa en el banner y en el **pase jugable** (con filo celeste, contacto y plato fantasma); `Plato_Vacio.png` queda como recurso heredado para props y pruebas. La proporción del pase es `PLATO_PERSPECTIVA = 0.464`, la del sprite 640×297.
- **Maestros:** `Sprites_Full/` está completo (134 PNG). El optimizador no sobreescribe maestros si la carpeta ya existe; para refrescarlos hay que moverla o borrarla antes.
- **Texto y marcas:** los sprites no contienen texto ni logotipos; ver el aviso legal.

## 11. Aviso legal

Este pack es una **obra original** con arte propio generado para el proyecto; no contiene recursos extraídos de ningún juego comercial. Para una publicación comercial conviene evitar nombres, logotipos o marcas ajenas.

## 12. Verificación

- 152 PNG válidos y 152 `.import`: 149 del pack en RGBA (incluidas las 15 mejoras), el banner opaco en RGB, el plato en RGBA y el fondo del selector en RGBA; ~26,2 MB en runtime.
- 58 entradas de layout; 0 rutas rotas.
- Escena: 76 nodos, 59 `TextureRect`, 9 `Label` y 46 recursos externos (43 texturas, 2 fuentes y el script); 0 rutas rotas.
- Tests del minijuego: **45/45, 1318 asserts** (incluye 11 tests de arrastre y toque rápido, 1 de pedidos deterministas, 6 de alineación del arte, 10 de los mundos 2–4 y la compra de mejoras con la Caja). La pantalla de Mejoras añade 1 test y no altera la suite existente.
- Escena ejecutada en Godot 4.7.2 a 1280×720 y capturada en `Arte_Fuente/Minijuego_Cocina/escenario_godot_1280x720.png`.
