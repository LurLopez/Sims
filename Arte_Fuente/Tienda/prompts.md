# SIMS — Sprites de artículos de la tienda (prompt maestro)

Lote completo de **6 iconos de muebles** para la tienda, con el mismo estilo 2.5D casual del pack de cocina. El prompt pide **seis imágenes independientes**, una por artículo, no una lámina ni un collage.

## Cómo usar

1. Abre la IA de imágenes de Google (Gemini / Nano Banana) en modo de generación de imágenes.
2. Adjunta, si puedes, estas dos referencias de estilo del pack de cocina:
   - `Imagenes/Minijuego_Cocina/Comida/Platos/Hamburguesa_Sola.png`
   - `Imagenes/Minijuego_Cocina/Estaciones/Plancha.png`
3. Pega el bloque **PROMPT MAESTRO** completo en un solo mensaje. No lo dividas.
4. Si Google solo devuelve una imagen por mensaje, responde `SIGUIENTE` hasta completar las seis. Si devuelve varias de golpe, perfecto.
5. Guarda cada resultado con el nombre exacto de la tabla.
6. El fondo magenta `#FF00FF` es intencional: se recorta a alfa con el pipeline del proyecto. No pidas fondo transparente directo, porque los modelos suelen devolver un damero falso.

## Artículos del lote

| # | Archivo | Artículo | Precio | Categoría | Rasgo visual |
|---|---|---|---|---|---|
| 1 | `Cama_Basica.png` | Cama Básica | 0 € | Dormir | Cama individual de pino, manta teal |
| 2 | `Cama_Premium.png` | Cama Premium | 200 € | Dormir | Cama doble de nogal, cabecero teal acolchado, ribete dorado |
| 3 | `Cama_Lujo.png` | Cama de Lujo | 800 € | Dormir | Cama king, terciopelo esmeralda, tufting, postes y cresta dorados |
| 4 | `Mesa_Basica.png` | Mesa Básica | 0 € | Comer | Mesa rectangular de pino puesta para uno |
| 5 | `Ducha_Basica.png` | Ducha Básica | 0 € | Duchar | Plato blanco, azulejo, cortina, cromados |
| 6 | `Ducha_Premium.png` | Ducha Premium | 200 € | Duchar | Walk-in de pizarra, cristal, latón cepillado, lluvia |

---

## PROMPT MAESTRO — pegar entero en un solo mensaje

```text
You are the lead art director and image generator for SIMS LIFE, a casual mobile life-simulation game. Your task is to create the complete set of shop item icons for the in-game store: six furniture pieces, all in one batch, each as its own separate square image.

READ THIS FIRST — DELIVERY RULES
- Produce exactly SIX independent images, one per item, in the order listed below.
- ONE object per image. Do NOT create a collage, contact sheet, grid, lineup, sprite sheet, or scene with multiple items.
- Do NOT put two items in the same image, not even as a variant or a size comparison.
- Each image must be a square 1:1 composition, high resolution, with the object centered and complete.
- Generate all six images in this session. Do not wait for me to describe each item. The six descriptions below are the complete batch.
- If your system supports multiple images per response, return all six now, in order, each as a separate image.
- If your system supports only one image per response, return image 1 of 6 now, then continue with image 2 when I say "SIGUIENTE", and so on. Keep the exact same style, camera, lighting, palette and level of detail for all six. Do not ask me to repeat the style bible.
- Do not ask questions. Do not ask for a reference image. This description is complete.
- Do not describe the images in text instead of generating them. Generate them.
- Do not add any text, caption, label, number, logo or watermark inside the image. If you need to identify an image, write the item name in the chat, outside the image.
- Name the images exactly: Cama_Basica.png, Cama_Premium.png, Cama_Lujo.png, Mesa_Basica.png, Ducha_Basica.png, Ducha_Premium.png.

STYLE BIBLE — IDENTICAL FOR EVERY IMAGE
Rendering: 2.5D casual mobile game art: polished vector-like shapes with smooth soft shading, crisp clean silhouettes, thin dark outlines, glossy highlights, rich saturated colors, warm cheerful lighting, premium life-simulation game art. The objects should look like high-quality, hand-crafted game assets: not photographs, not flat clipart, not pixel art, not anime, not a rough sketch, not a 3D render with realistic dirty textures. Original designs; do not copy any existing game's furniture or icons.
Camera: three-quarter front view, slightly elevated (about 20 degrees down), object fully visible, natural proportions, no wide-angle distortion, no perspective exaggeration. Keep exactly the same camera angle and lens for all six images. Not top-down, not isometric, not a straight-on elevation.
Composition: a single object, centered, occupying about 80% of the canvas in its longest dimension, with generous empty margin on all four sides. Nothing cropped, nothing touching the edges, no supporting stand, and no room around the object: no wall, no floor, no ceiling, no rug, no lamp, no window, no other furniture, no people, no hands, no pets. The object's own built-in parts are allowed (the shower's tiled walls, tray and ceiling arm; the bed's headboard and legs). The object must read as a complete, usable piece of furniture. The only allowed secondary props are the ones explicitly described for that item (pillows and bedding on a bed, tableware on the table, soap dish and bath mat in the basic shower, bottles and towel on the premium shower bench). Do not add anything else.
Lighting: soft warm key light from the upper left, cool subtle fill from the lower right, gentle ambient occlusion in the crevices, clean specular highlights on metal, glass, ceramic and polished wood. No dramatic shadows, no rim light, no glow, no bloom, no light beams. Do not cast a shadow on the background.
Palette: teal #0d9488, cherry red #dc2626, cream #fdf8f0, warm gold #facc15, brushed steel #cbd5e1, fresh green #16a34a, walnut #5c2d16, pine #b45309, ivory #f1f5f9, slate #334155. Use these color families consistently across the set. Rich, warm, inviting, premium but not gaudy.
Materials: visible wood grain drawn as clean stylized lines, soft fabric with gentle folds, glossy ceramic, chrome and brass with sharp but simple reflections, frosted or clear glass with subtle edge highlights. Show material differences through shape and highlights, not through noise or photorealistic texture.
Outline: a thin, even, dark warm-gray outline (#111827) around the silhouette and around major internal shapes. Do not use a thick black cartoon outline, do not use double lines, do not use a sketchy line.
Readability: the silhouette must be instantly recognizable at 128 px. Simplify details that disappear at small size. Keep the main shape bold and uncluttered.
Background: the entire background is flat solid magenta #FF00FF, perfectly even, edge to edge. No gradient, no vignette, no texture, no grid, no shadow, no floor, no glow, no checkerboard, no fake transparency. The object must not contain any pink, magenta, purple or violet pixels; those colors are reserved for the background key. If a material would be purple or pink, use teal, emerald, cherry red or warm brown instead. Do not let the magenta background reflect in chrome, glass or polished surfaces; use neutral warm-gray, teal and cream reflections instead.

THE SIX ITEMS — IN THIS EXACT ORDER

1. Cama_Basica — "Cama Básica" (starter single bed, free, +0% rest)
A modest single bed with a simple warm-pine wooden frame, four sturdy rectangular legs, a low rectangular headboard, a thick cream mattress, one flat cream pillow, and a teal blanket folded neatly across the foot of the bed. The wood has a visible but simple grain, rounded edges and a slightly matte finish. The blanket has a clean stitched hem, no pattern. The bed looks affordable, clean and cared for — not broken, not dirty, not luxurious. No canopy, no tufting, no gold, no extra pillows, no nightstand, no lamp, no rug. Three-quarter view from the foot corner, headboard at the back left, bed axis running diagonally into the image. Colors: pine #b45309, cream #fdf8f0, teal #0d9488, dark outline #111827. The silhouette must read as a bed at a glance.

2. Cama_Premium — "Cama Premium" (200 EUR, +5% rest)
A double bed and a clear upgrade from the basic one: dark walnut frame, a tall rounded headboard upholstered in deep teal fabric with a thin gold piping and three subtle button tufts, a thick hotel-white mattress, two plump cream pillows, an ivory duvet with soft folds, and a folded gold-and-teal runner across the foot. Four short tapered legs with small brass caps. The wood is polished, the fabric is soft and dense, the metal is warm brass. It looks comfortable, elegant and expensive, but still cozy and inviting. No canopy, no tall posts, no chandelier, no nightstand, no lamp, no rug. Same three-quarter camera as the basic bed, headboard at the back left, bed axis diagonal. Colors: walnut #5c2d16, deep teal #0d9488, ivory #fdf8f0, warm gold #facc15, brass #d97706. The bed must look wider and more padded than the basic one.

3. Cama_Lujo — "Cama de Lujo" (800 EUR, +10% rest)
A king-size luxury bed, the hero of the set: a dramatic tall headboard upholstered in deep emerald-teal velvet with deep diamond tufting, a carved dark-walnut frame with a subtle gold inlay, a thick silk-like cream mattress, four pillows (two large, two small), a cream duvet with elegant folds, and a folded cherry-red throw with a thin gold fringe at the foot. Two slim brass posts rise from the headboard, each topped with a small solid gold finial; there is no full canopy and no hanging fabric. A small solid gold ornamental crest sits at the center of the headboard, geometric and abstract, with no letters or logo. The bed feels like a five-star hotel suite: rich, quiet luxury, not gaudy, not baroque, not a fantasy throne. No nightstands, no lamps, no rug, no chandelier. Same three-quarter camera, headboard at the back left, bed axis diagonal. Colors: deep emerald #0f766e, dark walnut #3f1d0b, cream #fdf8f0, warm gold #facc15, cherry red #dc2626. The tallest and most detailed silhouette of the three beds.

4. Mesa_Basica — "Mesa Básica" (starter dining table, free, decorative)
A simple rectangular dining table made of warm pine, with a thick top, rounded corners and four slightly splayed legs. The wood grain is visible but clean. On the table: a folded cream linen runner, one empty white ceramic plate, a simple steel fork and knife on a folded napkin, and a small clear water glass. No food, no flowers, no candle, no tablecloth, no chairs, no bench. The table is set for one person, modest and tidy. Three-quarter view from a front corner, tabletop clearly visible, the plate and glass arranged so they do not hide the table's silhouette. Colors: pine #b45309, cream #fdf8f0, white ceramic #f1f5f9, brushed steel #cbd5e1, a thin teal accent on the runner hem. The table must read as a dining table, not a desk or a workbench.

5. Ducha_Basica — "Ducha Básica" (starter shower, free, +0% hygiene)
A compact shower stall: a white ceramic square tray with a low lip, three walls covered in glossy white square tiles with light warm-gray grout, a chrome shower column with a fixed round shower head, a chrome mixer tap, and a plain white shower curtain pulled to the right side, hanging from a chrome rod. A small teal bath mat is folded over the front edge of the tray, and a simple chrome soap dish with a white bar of soap is mounted on the wall. Three or four separate solid pale-blue water droplets fall from the shower head, drawn as part of the object, with no mist, no spray cone and no glow. The stall is open toward the viewer on the front-left so the interior is visible. It looks clean, functional and affordable — not old, not dirty, not luxurious. No rain shower, no glass panels, no brass, no plants, no towels on the floor. Colors: white #f8fafc, tile #e2e8f0, chrome #cbd5e1, teal #0d9488, pale blue #38bdf8. The silhouette must read as a shower at a glance, not a phone booth or a window.

6. Ducha_Premium — "Ducha Premium" (200 EUR, +5% hygiene)
A large walk-in spa shower, a clear upgrade: a low-profile dark slate tray, two frameless glass panels with polished edges and a faint teal tint, a brushed-brass rainfall shower head on a ceiling arm, a matching brass hand shower on a slide bar, a built-in wall niche with two bottles — one amber, one teal — with no labels and no text, a small teak bench at the back, and a folded white towel on the bench. Three thin solid pale-blue water streams fall from the rain head, drawn as part of the object, with no mist, no cloud and no glow. The glass must look transparent: show the slate wall and the bench through it, with crisp edge highlights and subtle reflections; do not paint the glass as a solid blue block. The shower is open toward the viewer on the front-right. It feels like a luxury hotel spa: calm, warm, expensive, uncluttered. No plants, no candles, no rocks, no multiple bottles beyond the two described. Colors: slate #334155, glass tint #0d9488 at low opacity, brushed brass #d97706, warm gold #facc15, teak #b45309, cream towel #fdf8f0. The largest and most architectural silhouette of the set.

HARD NO — NEVER INCLUDE
- No collage, sheet, grid, lineup or multiple objects in one image.
- No text, letters, numbers, labels, price tags, logos, watermarks, signatures, UI, frames, borders, cards or drop shadows.
- No people, hands, pets, characters or faces.
- No room, wall, floor, ceiling, rug, window, lamp, plant or extra furniture around the object. The object's own built-in parts are allowed.
- No pink, magenta, purple or violet anywhere in the object; no magenta reflections in chrome or glass.
- No glow, bloom, rim light, sparkles, confetti, magic particles, light beams or lens flare.
- No cast shadow on the magenta background.
- No cropping, no object touching the image edge.
- No photorealistic, pixel art, flat clipart, anime, manga, sketch, watercolor, grunge, dirty or broken look.
- No top-down, isometric, straight-on elevation or wide-angle distortion.
- No changing the camera, lighting, palette or outline weight between images.

CONSISTENCY CHECK — VERIFY SILENTLY BEFORE DELIVERING EACH IMAGE
- Exactly one object, complete, centered, with empty magenta margin on all sides.
- The background is 100% flat #FF00FF, with no shadow, gradient, texture, floor or checkerboard.
- The object contains no pink, magenta, purple or violet.
- The camera, lighting direction, outline weight, palette and rendering style match the previous images exactly.
- The tier reads correctly: basic = modest and simple; premium = padded, richer materials, gold/brass accents; luxury = tallest, most detailed, emerald velvet and gold.
- No text, no logo, no watermark, no UI, no people, no extra furniture.
- The object is not cropped and does not touch the image border.
- The image works as a shop icon at 128 px and as a large card image at 512 px.
- The style matches the attached reference image(s), if any, without copying their subject.
If any check fails, fix it before delivering the image. Do not write the checklist in the chat; just deliver the clean image.

BEGIN THE BATCH NOW. Generate the six images in the exact order above. Each image must contain exactly one item. Do not merge the items into a single image under any circumstance. If you can only generate one image per message, generate image 1 of 6 now and end with "1/6 — di SIGUIENTE".
```

---

## Plan B — si Google devuelve una sola imagen con varios objetos

Pídele: «Divide esa lámina en seis PNG cuadrados, uno por objeto, sin cambiar el estilo». Si no lo hace, pásame la lámina y la corto con el pipeline del proyecto (`tools/cortar_sprites.py`). El fondo magenta está pensado exactamente para eso.

## Criterios de aceptación al recibir las imágenes

- [ ] Hay exactamente un objeto por imagen, completo y centrado.
- [ ] El fondo es magenta plano `#FF00FF`, sin sombra ni damero.
- [ ] El objeto no tiene rosa, magenta, morado ni violeta.
- [ ] La cámara, la luz y el grosor de línea son iguales en las seis.
- [ ] Se distingue básico / premium / lujo a simple vista.
- [ ] No hay texto, logos, precios ni marcos.
- [ ] La silueta se lee a 128 px.

## Post-proceso (aplicado)

Los seis JPG ya están procesados e integrados en el juego. Los originales viven en `Arte_Fuente/Tienda/Fuente/` (fuera de `Imagenes/` para que Godot no los empaquete en el APK) y las versiones con alfa en `Imagenes/Tienda/Iconos/`. (En este lote las imágenes se guardaron como `.jpg`; el script acepta `.jpg`, `.jpeg` y `.png`.)

1. `python3 tools/procesar_iconos_tienda.py` recorta el magenta por croma (`score = min(R,B) - G`), elimina el derrame del borde, limpia motas, recorta al objeto y lo centra en un lienzo cuadrado de 512×512 con un 5 % de margen transparente.
2. Salida en `Imagenes/Tienda/Iconos/{Cama_Basica,Cama_Premium,Cama_Lujo,Mesa_Basica,Ducha_Basica,Ducha_Premium}.png`.
3. `Estilos_UI.icono_tienda(clave)` carga y cachea cada textura; `Script_Principal._Redisenar_Tienda()` sustituye la vitrina de emoji/Lucide por un `TextureRect` de 304×200 con la píldora BÁSICO/PREMIUM/LUJO.
4. Hoja de control opcional: `python3 tools/procesar_iconos_tienda.py --preview /tmp/tienda_iconos_preview.png`.

Si se rehace algún icono, basta con guardar el JPG sobre el original y volver a ejecutar el script; Godot reimporta los PNG automáticamente.

---

## Ampliación del catálogo (36 muebles)

La tienda creció de 6 a **36 muebles**: 6 categorías × 6 niveles. Para que el
estilo siguiera siendo consistente, los 30 muebles nuevos se generaron en
**láminas de 2×2** (o 2×1) con el mismo prompt maestro, usando como referencia
`Cama_Lujo.jpg`, `Mesa_Basica.jpg` y `Ducha_Premium.jpg`.

| Lámina | Contenido |
|---|---|
| `Lamina_Salon.png` | Sofá Básico, Esquinero, Chester y Relax |
| `Lamina_Dormir_Comer_1.png` | Litera Compacta, Cama Nube, Cama Imperial y Mesa Familiar |
| `Lamina_Comer_1.png` | Mesa de Roble, Mesa de Cristal, Isla de Desayuno y Mesa del Chef |
| `Lamina_Duchar_1.png` | Bañera Clásica, Ducha Lluvia, Jacuzzi y Cabina Spa |
| `Lamina_Salon_Estudio_1.png` | Sofá Modular, Salón Imperial, Escritorio Básico y Moderno |
| `Lamina_Estudio_1.png` | Escritorio Ejecutivo, Mesa de Dibujo, Escritorio Gaming y Biblioteca |
| `Lamina_Cocina_1.png` | Cocina Básica, Modular, con Isla y del Chef |
| `Lamina_Cocina_2.png` | Cocina Pro y Cocina Industrial |

### Reglas de las láminas

- Fondo magenta `#FF00FF` plano de borde a borde, sin sombra de contacto.
- Cuatro objetos separados en cuadrantes invisibles, con ≥8 % de margen
  magenta alrededor y sin cruzar los ejes centrales.
- Un solo objeto por celda, cámara 3/4 elevada, misma luz y paleta.
- Nada de texto, logos, marcos, líneas de rejilla ni personas.

### Corte y procesado

```bash
python3 tools/cortar_sprites.py Arte_Fuente/Tienda/Fuente/Lamina_Salon.png \
  Arte_Fuente/Tienda/Fuente --grid 2x2 \
  --names Sofa_Basico,Sofa_Esquinero,Sofa_Chester,Sofa_Relax

python3 tools/procesar_iconos_tienda.py --preview /tmp/tienda_preview.png
```

`cortar_sprites.py` recorta cada celda; `procesar_iconos_tienda.py` acepta tanto
JPG con magenta como PNG ya recortados con alfa, limpia motas, centra el objeto
y guarda los 512×512 finales en `Imagenes/Tienda/Iconos/`.
