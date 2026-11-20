# Pack de sprites del escenario — Minijuego de Cocina

## 1. Resumen

Pack de **134 sprites PNG** para el escenario del minijuego de cocina estilo *Cooking Fever*, más un **layout JSON** y una **escena editable de muestra a 1280×720** que reproduce la composición de referencia: chef a la izquierda, cuatro clientes tras el mostrador, tickets de pedido, vitrina, estaciones de cocina y primer plano de acero inoxidable.

- Arte **original generado por IA** (no se han extraído sprites del juego original).
- Dirección: 2.5D casual, brillos suaves, colores saturados, perspectiva ligeramente cenital.
- Los maestros, hojas de generación, prompts y catálogos viven en `Arte_Fuente/Minijuego_Cocina/` (ignorado por Godot mediante `Arte_Fuente/.gdignore`).
- La escena de muestra es **independiente**: no está enganchada al minijuego jugable ni modifica su lógica.

## 2. Alcance

**Incluido**

- 134 PNG RGBA en `Imagenes/Minijuego_Cocina/` con sus `.import` de Godot.
- `Imagenes/Minijuego_Cocina/escenario_layout.json` con 54 entradas de composición (`ruta`, `x`, `y`, `w`, `h`, `modo`).
- Escena de muestra `Escenas/Minijuego_Cocina/Escenario_Cooking_Fever.tscn` y su controlador `Scripts/GUI/Minijuego_Cocina/Escenario_Cooking_Fever.gd`.
- Herramientas reproducibles en `tools/` y catálogos visuales en `Arte_Fuente/Minijuego_Cocina/Catalogo/`.

**Excluido**

- Lógica, economía, niveles, pedidos y temporizadores del minijuego jugable (viven en `Sistema_Cocina` y `Minijuego_Cocina.gd`).
- Integración visual en la escena jugable: el minijuego sigue dibujando sus sprites vectoriales con `Sprites_Cocina.gd`; este pack no se carga desde allí.
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
| `UI/` | 24 | HUD, tickets, monedas, botones y estrellas |
| `Decoracion/` | 8 | Toldos, rótulos, planta, lámpara y trofeo |
| `Efectos/` | 8 | Vapor, humo, chispas, fuego, monedas, estrellas, frescura y enfado |
| Raíz | 1 | `Fondo_Restaurante.png` |
| **Total** | **134** | |

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

### `UI/` (24)

`Ticket_Verde.png`, `Ticket_Rojo.png`, `Moneda.png`, `Pila_Monedas.png`, `Gema.png`, `Reloj.png`, `Bote_Propinas.png`, `Burbuja.png`, `Boton_Verde.png`, `Boton_Azul.png`, `Boton_Naranja.png`, `Boton_Check.png`, `Boton_X.png`, `Flecha.png`, `Engranaje.png`, `Estrella_Dorada.png`, `Estrella_Plateada.png`, `Estrella_Vacia.png`, `Corazon.png`, `Candado_Abierto.png`, `Candado_Cerrado.png`, `Insignia_Nivel.png`, `Regalo.png`, `Cinta_Dorada.png`.

### `Decoracion/` (8)

`Toldo_Verde.png`, `Toldo_Rojo.png`, `Pizarra.png`, `Rotulo.png`, `Reloj_Pared.png`, `Trofeo.png`, `Planta.png`, `Lampara.png`.

### `Efectos/` (8)

`Vapor.png`, `Humo.png`, `Chispas.png`, `Monedas.png`, `Fuego.png`, `Estrellas.png`, `Frescura.png`, `Enfado.png`.

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
| `Escenas/Minijuego_Cocina/Escenario_Cooking_Fever.tscn` | Escena editable de 1280×720. 76 nodos: 2 `Control`, 59 `TextureRect` (58 del layout + fondo), 9 `Label` y 6 `ColorRect` (fondo de ventana, HUD y estante). |
| `Scripts/GUI/Minijuego_Cocina/Escenario_Cooking_Fever.gd` | Formato horizontal, animación idle, cierre con `Esc` y captura opcional. |
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

La escena es una maqueta visual: no se instancia desde `Minijuego_Cocina.tscn`, `Pantalla_Minijuegos` ni `Script_Principal`. La única referencia en el proyecto, fuera de la documentación, es `ver_escenario.sh`.

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

Notas del recorte:

- `--grid COLSxROWS` corta celdas iguales; sin `--grid` se detectan blobs conectados y se agrupan por filas.
- `--erode N` elimina el fleco blanco del *keying*; requiere OpenCV.
- `--alpha-cutoff N` descarta píxeles por debajo de ese alfa (útil para quitar tableros horneados).
- `--no-clean` conserva motas sueltas, necesario en hojas de efectos.
- `--trim-white` recorta el halo blanco de contorno.

Advertencias:

- `optimizar_sprites.py` **no sobreescribe** maestros existentes: si `Sprites_Full/` ya existe, solo reduce los PNG de runtime. Para refrescar maestros hay que mover o borrar esa carpeta antes.
- `generar_escena_godot.py` reescribe `Escenario_Cooking_Fever.tscn`; si se edita la escena a mano, se pierden los cambios al regenerar.
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

- **Formato:** 134 PNG en RGBA de 8 bits por canal, sin perfil ICC incrustado (Godot los interpreta como sRGB) y sin indexar.
- **Importación:** los 134 tienen `.import` con `compress/mode=0` (lossless), compresión VRAM desactivada, `mipmaps/generate=false`, `process/fix_alpha_border=true` y filtro lineal por defecto. No hay atlas ni `SpriteFrames`.
- **Peso:** ~19,3 MB de PNG de runtime; el más pesado es el fondo (~1,39 MB). Para Android conviene valorar compresión VRAM o un atlas si el pack se integra en el juego real.
- **Maestros:** `Arte_Fuente/Minijuego_Cocina/Sprites_Full/` contiene **134 PNG** e incluye los 8 clientes enfadados. Esa carpeta no se importa en Godot.

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
- **Escena de muestra:** es una maqueta visual; no sustituye al minijuego jugable ni se engancha a él. Incluye 3 nodos de vapor y 1 de chispas animados.
- **Fondo:** está horneado a 1280×720; en otras relaciones de aspecto hay que recortarlo o rellenar.
- **Maestros:** `Sprites_Full/` está completo (134 PNG). El optimizador no sobreescribe maestros si la carpeta ya existe; para refrescarlos hay que moverla o borrarla antes.
- **Texto y marcas:** los sprites no contienen texto, pero el pack se inspira en una IP ajena; ver el aviso legal.

## 11. Aviso legal

*Cooking Fever* es una marca de Nordcurrent. Este pack es una **inspiración/homenaje** con arte propio generado para el proyecto; no contiene recursos extraídos del juego original. Para una publicación comercial conviene diferenciar aún más el diseño de la chef y no usar nombres, logotipos ni marcas ajenas.

## 12. Verificación

- 134 PNG RGBA válidos y 134 `.import`; 19,3 MB en runtime.
- 58 entradas de layout; 0 rutas rotas.
- Escena: 76 nodos, 59 `TextureRect`, 9 `Label` y 46 recursos externos (43 texturas, 2 fuentes y el script); 0 rutas rotas.
- Tests del minijuego: **11/11, 336 asserts**.
- Escena ejecutada en Godot 4.7.2 a 1280×720 y capturada en `Arte_Fuente/Minijuego_Cocina/escenario_godot_1280x720.png`.
