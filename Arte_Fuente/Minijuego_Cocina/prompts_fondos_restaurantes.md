# Fondos de restaurante del Minijuego de Cocina — Bistró, Mercado y Alta Cocina

Prompts para generar los **tres fondos que faltan** del minijuego de cocina (inspirado en *Cooking Fever*), con el mismo estilo que el fondo ya terminado de **Burger & Street Food** (`Imagenes/Minijuego_Cocina/Fondo_Restaurante.png`).

| Restaurante | Trabajo | Archivo sugerido | Paleta |
|---|---|---|---|
| Bistró Tradicional | Ayudante de Cocina (17 €/h) | `Fondo_Bistro.png` | Burdeos, latón, crema, roble, verde bosque |
| Cocina de Mercado | Cocinero de Partida (24 €/h) | `Fondo_Mercado.png` | Terracota, azul cobalto, crema, oliva, madera |
| Alta Cocina Gourmet | Chef Ejecutivo (36 €/h) | `Fondo_Alta_Cocina.png` | Azul medianoche, carbón, esmeralda, oro, marfil |

---

## Cómo usarlos

1. **Adjunta como referencia** `Imagenes/Minijuego_Cocina/Fondo_Restaurante.png`. Sirve solo para copiar la técnica: mismo trazo, mismo sombreado, misma saturación, misma cámara y mismo nivel de detalle. **No** debe copiar el local.
2. Pega el prompt completo del restaurante que toque (ya incluye el bloque de estilo común).
3. Genera **3–4 variantes** por fondo y elige la que pase el checklist final.
4. Genera a 16:9 (1920×1080 o el tamaño 16:9 más cercano del modelo) y reduce a **1280×720** con Lanczos.
5. Guarda el maestro en `Arte_Fuente/Minijuego_Cocina/Fondos/` y el PNG final en `Imagenes/Minijuego_Cocina/Fondos/`.

**Truco de consistencia:** genera los tres en la misma sesión, con la misma imagen de referencia y sin tocar el párrafo de estilo. Si el modelo se queja del nombre *Cooking Fever*, sustitúyelo por «inspired by popular casual cooking time-management games».

**En partida**, el juego tapa desde `y=430` hasta abajo con plancha, freidora, dispensador, emplatado, papelera y bandeja de ingredientes. Todo lo identificativo debe vivir en los **primeros 432 px (60 %)**; los **288 px inferiores (40 %)** deben quedar limpios. Los bustos de clientes se dibujan entre `y≈240` y `y≈392`, así que la banda central debe ser tranquila.

---

## Prompt 1 — Bistró Tradicional (Ayudante de Cocina)

```text
Use the attached fast-food diner background only as a style reference: match its rendering technique, line weight, shading, saturation, warm lighting and camera angle exactly, but paint a completely different restaurant. Wide 16:9 game background for a casual mobile cooking time-management minigame inspired by Cooking Fever, with no characters. 2.5D casual mobile cooking-game art: polished vector-like shapes with smooth soft shading, crisp clean outlines, glossy highlights, rich saturated colors, warm cheerful lighting, premium restaurant game backdrop, bold readable shapes that stay clear when scaled down to 1280×720.

Interior of a cozy traditional French bistro at golden hour. Pale cream plaster walls above, deep oxblood-red lacquered wood wainscoting below with slim antique brass rails. Worn honey-oak herringbone parquet floor. Along the back wall, tall arched windows with thin brass frames, sheer white lace café curtains and warm late-afternoon sunlight pouring in; outside, softly blurred leafy plane trees and a pale stone Parisian facade. Oxblood leather banquettes with button tufting, small round marble bistro tables with brass rims, bentwood chairs, crisp white napkins, tiny brass table lamps with warm cream shades, a single red gerbera in a small glass vase and a lit candle on every table. In the background, a marble bar with a polished brass espresso machine, a pyramid of wine glasses, dusty wine bottles in a wooden rack, glass cloches over tarts and éclairs, and a chalkboard menu with abstract unreadable marks. A gilt-framed mirror, framed vintage posters with no lettering, copper pans hanging on the wall, a brass coat rack and three brass pendant lamps with opal glass globes.

Camera: straight-on, slightly elevated eye level, one-point perspective facing the back wall, symmetrical stage-set composition, horizon line around 62% of the image height. All the personality of the place lives in the upper 60% of the frame. Keep the middle band at seated-customer height calm: no tall objects or busy patterns in the center. The bottom 40% is a plain dark polished walnut counter surface with soft reflections, no props, no furniture, no detail, so game UI can be overlaid there.

Palette: burgundy, aged brass, cream, honey oak and forest-green accents. Mood: intimate, warm, inviting, slightly nostalgic, upscale but cozy. Bright enough for readable gameplay, never gloomy.

No people, no animals, no text, no lettering, no numbers, no logos, no brand marks, no watermark, no signature, no UI, no HUD, no icons, no border, no frame, no split panels, no collage. Menu boards and posters are blank or carry only abstract unreadable decorative marks. No magenta, no neon purple. No photorealism, no 3D render, no pixel art, no sketch. Do not include the reference restaurant's teal walls, red vinyl booths, black-and-white checkered floor, jukebox, burger posters or milkshake signs. This description is complete.
```

---

## Prompt 2 — Cocina de Mercado (Cocinero de Partida)

```text
Use the attached fast-food diner background only as a style reference: match its rendering technique, line weight, shading, saturation, warm lighting and camera angle exactly, but paint a completely different restaurant. Wide 16:9 game background for a casual mobile cooking time-management minigame inspired by Cooking Fever, with no characters. 2.5D casual mobile cooking-game art: polished vector-like shapes with smooth soft shading, crisp clean outlines, glossy highlights, rich saturated colors, warm cheerful lighting, premium restaurant game backdrop, bold readable shapes that stay clear when scaled down to 1280×720.

Interior of a lively Spanish Mediterranean market kitchen and rustic tavern at midday. Whitewashed plaster walls with patches of exposed terracotta brick; glossy cobalt-blue and white patterned ceramic tiles with geometric azulejo motifs only along the lower walls. Dark exposed timber ceiling beams hung with strings of dried red peppers, garlic braids, herb bundles and cured hams in the background. Wide open wooden-framed windows and a doorway onto a sunlit market square: bright blue sky, green foliage, red geraniums in terracotta pots and a cream-and-terracotta striped canvas awning. Worn terracotta tile floor. A long communal wooden table with benches, small barrel tables with wooden stools, wicker baskets and wooden crates overflowing with tomatoes, lemons, oranges, artichokes, red peppers, onions and fresh herbs. In the background, a zinc-and-marble service counter with copper pots and paella pans hanging above, shelves of olive oil bottles and ceramic bowls, a chalkboard with abstract unreadable marks and a small wood-fired oven arch. Hanging scales, ceramic jugs and a bowl of lemons as decoration.

Camera: straight-on, slightly elevated eye level, one-point perspective facing the back wall, symmetrical stage-set composition, horizon line around 62% of the image height. All the personality of the place lives in the upper 60% of the frame. Keep the middle band at seated-customer height calm: no tall objects or busy patterns in the center. The bottom 40% is a plain dark terracotta-and-stone counter surface with soft reflections, no props, no furniture, no detail, so game UI can be overlaid there.

Palette: terracotta, cream, azure blue, olive green, sun-bleached wood, tomato red and lemon yellow. Mood: bright, fresh, rustic, bustling and appetizing, flooded with warm Mediterranean sunlight and crisp shadows.

No people, no animals, no text, no lettering, no numbers, no logos, no brand marks, no watermark, no signature, no UI, no HUD, no icons, no border, no frame, no split panels, no collage. Menu boards and posters are blank or carry only abstract unreadable decorative marks. No magenta, no neon purple. No photorealism, no 3D render, no pixel art, no sketch. Do not include the reference restaurant's teal walls, red vinyl booths, black-and-white checkered floor, jukebox, burger posters or milkshake signs. This description is complete.
```

---

## Prompt 3 — Alta Cocina Gourmet (Chef Ejecutivo)

```text
Use the attached fast-food diner background only as a style reference: match its rendering technique, line weight, shading, saturation, warm lighting and camera angle exactly, but paint a completely different restaurant. Wide 16:9 game background for a casual mobile cooking time-management minigame inspired by Cooking Fever, with no characters. 2.5D casual mobile cooking-game art: polished vector-like shapes with smooth soft shading, crisp clean outlines, glossy highlights, rich saturated colors, warm cheerful lighting, premium restaurant game backdrop, bold readable shapes that stay clear when scaled down to 1280×720.

Interior of an elegant Michelin-star fine-dining restaurant at blue hour. Deep midnight-blue fluted wood panelling with slim brass inlays, textured charcoal plaster above. Polished dark marble floor with thin brass inlay lines and a small inlaid brass five-point star motif. Tall arched windows with sheer ivory curtains showing a deep blue evening sky and soft golden garden lights outside, gently blurred. Round tables dressed with floor-length crisp white tablecloths, deep emerald velvet chairs with brass legs, crystal glassware, silver cutlery, white porcelain, a single white orchid and a slim lit candle. In the background, a softly backlit glass wine wall with rows of bottles, a white marble pass with brass warming lamps, neat stacks of white plates and polished copper pans. A crystal chandelier with warm golden bulbs, brass wall sconces and elegant pools of warm light, with rich shadows but clear readable midtones. Framed abstract art with no text.

Camera: straight-on, slightly elevated eye level, one-point perspective facing the back wall, symmetrical stage-set composition, horizon line around 62% of the image height. All the personality of the place lives in the upper 60% of the frame. Keep the middle band at seated-customer height calm: no tall objects or busy patterns in the center. The bottom 40% is a plain dark polished marble counter surface with soft reflections, no props, no furniture, no detail, so game UI can be overlaid there.

Palette: midnight blue, charcoal, emerald, gold and brass, ivory and warm amber. Mood: refined, quiet, luxurious, intimate and exclusive. Elegant contrast but never so dark that gameplay becomes hard to read.

No people, no animals, no text, no lettering, no numbers, no logos, no brand marks, no watermark, no signature, no UI, no HUD, no icons, no border, no frame, no split panels, no collage. Menu boards and posters are blank or carry only abstract unreadable decorative marks. No magenta, no neon purple. No photorealism, no 3D render, no pixel art, no sketch. Do not include the reference restaurant's teal walls, red vinyl booths, black-and-white checkered floor, jukebox, burger posters or milkshake signs. Do not add rustic chalkboards, market crates or diner furniture. This description is complete.
```

---

## Negative prompt

Para Stable Diffusion, ComfyUI o cualquier modelo con campo negativo:

```text
text, letters, words, typography, numbers, readable signs, logo, brand logo, watermark, signature, people, human, character, chef, waiter, customer, hands, face, animal, kitchen equipment in the foreground, stove, fryer, pots in the foreground, game UI, HUD, buttons, icons, frame, border, collage, split screen, photorealism, photograph, 3D render, CGI, pixel art, sketch, line art, low contrast, blurry, heavy noise, magenta, purple neon, clutter in the bottom third, distorted perspective, fisheye
```

En Midjourney no hay negativo: añade al final `--ar 16:9 --no text, letters, people, logo, watermark, border`.

---

## Checklist de aceptación

- [ ] Relación de aspecto **16:9** exacta.
- [ ] A 1280×720 se sigue leyendo todo: formas grandes, sin detalle minúsculo.
- [ ] Los **primeros 432 px** concentran la identidad del restaurante (paredes, ventanas, decoración, mobiliario).
- [ ] Los **288 px inferiores** son una superficie lisa y oscura, sin props ni texto.
- [ ] La banda central (240–400 px) no tiene objetos altos ni patrones ruidosos que compitan con los clientes.
- [ ] **Cero texto**, letras, números, logotipos o marcas de agua.
- [ ] **Cero personas** y cero equipo de cocina en primer plano.
- [ ] La paleta es claramente distinta a la del local de hamburguesas (nada de pared turquesa + asientos rojos + damero).
- [ ] Luz cálida y saturada; el local no queda oscuro ni apagado.
- [ ] Sin magenta ni morado neón; sin marco ni borde.
- [ ] El estilo encaja con `Fondo_Restaurante.png`: mismo trazo, mismo sombreado, misma cámara.

---

## Integración en Godot (siguiente paso)

Ahora mismo `Scripts/GUI/Minijuego_Cocina/Arte_Cocina.gd` tiene un único `const TEX_FONDO := preload("res://Imagenes/Minijuego_Cocina/Fondo_Restaurante.png")`. Para usar un fondo por restaurante hay que:

1. Guardar los PNG en `Imagenes/Minijuego_Cocina/Fondos/`.
2. Sustituir la constante por un `Dictionary` `restaurante_id → Texture2D`.
3. En `Minijuego_Cocina.gd`, usar el `_restaurante_actual` al construir `Fondo_Restaurante`, `Fondo_Mapa`, `Fondo_Carga` y el banner de `Script_Principal.gd`.
