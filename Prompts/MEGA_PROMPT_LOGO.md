# MEGA PROMPT — Diseño del logo de SIMS LIFE

**Versión:** 1.0 · **Fecha:** 20/11/2026
**Activo:** identidad de SIMS LIFE (Android, 720×1280, Godot 4.4)
**Objetivo:** que una IA de diseño o de imagen produzca un logo de app móvil que se lea a 48 px, funcione con las máscaras de Android y encaje con el medallón dinámico que ya usa el juego.

---

## CÓMO USAR ESTE DOCUMENTO

| Herramienta | Qué pegar | Qué esperar |
|---|---|---|
| ChatGPT / Claude / Gemini | El documento completo (secciones 1–13) | Concepto, 12 miniaturas descritas, 3 finalistas, geometría y crítica. |
| Midjourney / DALL·E / Imagen / Firefly | Solo el bloque **10.1** (icono), **10.2** (wordmark) o **10.3** (lockup) + **10.8** (negativo) | Imágenes de exploración. Nunca las uses como asset final sin vectorizar. |
| Diseñador humano | Todo el documento | Un brief cerrado y medible. |
| Producción | Secciones 9 y 14 | Medidas, nombres de archivo e integración con Godot. |

**Regla de oro:** los modelos de imagen escriben mal y dibujan caras inconsistentes. Generan **exploración**; el arte final se redibuja en vector (Figma, Illustrator o Inkscape) y se exporta con el pipeline `Arte_Fuente/Marca/generar_logo.py`.

## MODO DE TRABAJO

- **Evolución (por defecto):** conserva medallón, chispa, wordmark, paleta y jerarquía; refina proporciones, luz y legibilidad. Es el modo recomendado porque el juego ya usa el marco con la cara dinámica.
- **Rediseño:** conserva solo la esencia (“la chispa de una vida”), la paleta y el requisito de cara + chispa; propone una forma nueva. Úsalo solo si la ruta A no supera la prueba de 48 px.

Si no se indica lo contrario, trabaja en **evolución**.

**Si el modelo pide más información:** no la pidas tú. Usa los valores por defecto de este brief y decide.

---

# 1. ROL

Eres **director de arte y diseñador de identidad visual**, especializado en iconos de aplicaciones móviles y marcas de videojuegos. Llevas 15 años haciendo iconos que funcionan en una pantalla de inicio llena de competencia, y sabes que un logo no es una ilustración: es una **señal** que debe reconocerse antes de leerse.

Tu trabajo no es “hacer algo bonito”. Es entregar un **sistema de marca** que:

1. se reconozca a 48 px y sobreviva a 24 px;
2. funcione con las máscaras adaptativas de Android (círculo, squircle, cuadrado redondeado);
3. se pueda vectorizar sin degradarse;
4. conviva con una cara dibujada en tiempo de ejecución dentro del juego;
5. resista diez años sin parecer una tendencia de 2026.

No imites el logo de *The Sims* ni de *EA*. No uses el rombo verde (*plumbob*). Nuestra marca es un **retrato**, no un símbolo abstracto.

---

# 2. EL PRODUCTO EN 60 SEGUNDOS

**SIMS LIFE** es un simulador de vida simplificado para Android, en español, con estética 2D cartoon y cámara fija. El jugador crea un Sim de 18 años y lo acompaña hasta los ~80. Una semana real equivale a un año de juego.

**Sistemas que el jugador asocia a la marca:**

- necesidades básicas (salud, hambre, descanso, higiene);
- trabajo, nómina y alquiler (200 €/semana; si no pagas, acabas en la calle);
- carreras universitarias (Informática, Derecho, Bellas Artes, Medicina);
- cocina con minijuego de restaurante y tuppers;
- carrera de futbolista, liga dominical y playoff;
- bolsa, eventos aleatorios, fiestas, resaca e intoxicación;
- muerte del personaje.

**Promesa:** *la vida entera, en el bolsillo, en sesiones de dos minutos.*

**Público:** 16–40 años, casual, España y Latinoamérica. Juega en el transporte, en la cama, mientras espera. Le gustan los juegos de progreso, decoración y “una cosa más”. No quiere un simulador de gestión frío; quiere **una vida pequeña y cálida** que le haga sonreír.

**Paradoja del tono:** el juego trata temas adultos (alquiler, despido, muerte) con una cara amable. El logo debe ser **cálido, no infantil**; **optimista, no bobo**; **premium casual, no barato**.

---

# 3. PLATAFORMA DE MARCA

## 3.1 Esencia

> **“La chispa de una vida.”**

El instante en que un Sim empieza: una cara que te mira, un destello dorado y todo lo que puede pasar. El logo no representa una casa, ni un corazón, ni un mando: representa **una persona con una vida por delante**.

## 3.2 Personalidad

| Atributo | Sí | No |
|---|---|---|
| Cercano | cara reconocible, sonrisa pequeña, luz cálida | bebé gigante, ojos de anime, empalago |
| Luminoso | carmesí, oro, crema, rayos de sol | neón, cian, violeta “tech” |
| Artesanal | trazo grueso, formas redondeadas, sticker | degradados de agencia, glassmorphism |
| Optimista | chispa, amanecer, diagonal ascendente | ironía, colores apagados, estética indie triste |
| Con humor | una ceja relajada, un destello cómplice | payaso, emoticono, chiste visual obvio |

## 3.3 Qué debe decir el logo

- “Esto es una vida, no una planilla.”
- “Es para móvil y es fácil de tocar.”
- “Hay algo dorado dentro de lo cotidiano.”
- “Es el mismo juego que ya conozco, pero mejor.”

## 3.4 Qué NO debe decir

- “Soy *The Sims*” (demanda inmediata).
- “Soy un juego de casas” (el icono no es un tejado).
- “Soy un juego infantil” (el público tiene 30 años).
- “Soy un asset genérico de banco de iconos.”
- “Soy una app de productividad con un calendario sonriente.”

## 3.5 Territorio competitivo

En Play Store, los simuladores de vida usan **verdes, azules pastel y morados**. El carmesí + oro + crema es un territorio **libre y cálido**. No lo cambies por azul “confiable” ni por violeta “premium”: ahí te vuelves invisible.

La cara es el diferencial. La mayoría de competidores usan símbolos (casas, corazones, rombos). Nosotros usamos **contacto visual**.

---

# 4. ANATOMÍA DE LA MARCA

El logo es un **sistema modular**, no una imagen plana. Tiene cuatro piezas:

```
┌─────────────────────────────────────────────┐
│  1. MEDALLÓN      2. CHISPA                 │
│     (marco)          (firma)                │
│                                             │
│  3. WORDMARK      4. ETIQUETA LIFE          │
│     (SIMS)           (chapa dorada)         │
└─────────────────────────────────────────────┘
```

## 4.1 Medallón — “el camafeo vivo”

Un camafeo circular con la cara del Sim dentro. Es la pieza principal y la que se reutiliza en el juego con la cara real del jugador.

**De fuera hacia dentro:**

1. contorno exterior granate fino;
2. aro de oro pulido, con brillo en la parte superior izquierda;
3. banda de esmalte crema con 8 remaches dorados pequeños;
4. anillo de esmalte carmesí;
5. filete dorado fino;
6. labio interior crema que separa la cara del anillo;
7. hueco circular transparente con la cara.

**Reglas:**

- El hueco debe ser **perfectamente circular y concéntrico** (±1 px). El juego recorta la cara con una máscara circular.
- El labio crema es obligatorio: separa cualquier tono de piel o pelo del carmesí. Sin él, las apariencias oscuras se funden con el aro.
- La cara ocupa el **71,4 %** del lado del medallón. No la acerques más: el pelo con puntas necesita aire.
- No incrustes la cara en el marco fijo. El marco se exporta con el centro transparente.
- El medallón debe funcionar con **cualquier** apariencia: piel clara u oscura, pelo liso, rizado o rapado, gafas, barba. Prueba al menos tres.

**Por qué un medallón:** funciona a cualquier tamaño, contiene una cara sin recortarla, tiene herencia de camafeo/insignia y se distingue de los símbolos planos de la competencia.

## 4.2 Chispa — “la firma”

Una estrella de cuatro puntas, dorada, con contorno granate, que **rompe el aro** por la **1–2 en punto**. Va acompañada de una segunda chispa blanca más pequeña y dos puntos.

- Es el detalle **propietario** de la marca. No la muevas, no la cambies de esquina, no la conviertas en un destello de lens flare.
- Debe verse a 24 px. Si desaparece, es demasiado pequeña.
- La punta de la chispa puede salir del círculo, pero no del lienzo.
- En monocromo se convierte en una silueta sólida de cuatro puntas.

**Por qué:** la chispa cuenta la historia (“una vida que empieza”) y da asimetría a una forma que, si no, sería un círculo perfecto y aburrido.

## 4.3 Wordmark — “SIMS”

Lettering **custom**, no una fuente aplicada sin más. Base: **Titan One** (`Fuentes/UI/TitanOne-400.ttf`), convertida a trazados.

- Relleno crema `#FFF7E8`, contorno granate `#7A1020`, sombra desplazada granate profundo.
- Trazo grueso, terminaciones redondeadas, contadores amplios, línea de base ligeramente irregular (hecho a mano, no descuidado).
- Altura ≈ **59 %** de la altura del lockup; relación de aspecto ≈ **2,8:1**.
- Debe leerse a 200 px de ancho y a 1024 px.
- No uses ligaduras que rompan la lectura. Son cuatro letras: S-I-M-S.
- Versión clara (crema) para fondos rojos/oscuros; versión oscura (carmesí) para fondos claros.
- Exporta en PNG transparente a **2026×720** como mínimo, y en SVG con texto convertido a trazados.

## 4.4 Etiqueta LIFE — “la pegatina”

Una chapa dorada inclinada **4–8°**, con la palabra `LIFE` en granate y un corazón pequeño. Se solapa con la base de la S final, como una pegatina puesta a mano.

- No es una pastilla genérica: tiene bisel suave, sombra y un corazón dibujado, no un emoji.
- Debe leerse a 48 px de alto total del wordmark.
- No la conviertas en el elemento principal. Es un acento.

## 4.5 Fondo

- **Rojo (principal):** carmesí `#D62828` con degradado cálido, franjas diagonales a 45° (paso 7,5 %, ancho 2,8 %, blanco al 4,5 %), luz radial superior izquierda y viñeta.
- **Claro:** crema `#FFF7E8`, puntos dorados sutiles, marco fino al 22 %.
- **Oscuro:** casi negro `#120D19` con luz carmesí y estrellas pequeñas.
- El fondo nunca debe competir con el medallón. Si dudas, quita detalle.

---

# 5. SISTEMA DE COLOR

Mantén estos anclajes. Puedes ajustar luminosidad ±5 %, no el tono.

| Token | Hex | Uso |
|---|---|---|
| Rojo Vida | `#D62828` | fondo principal, anillo de esmalte |
| Rojo vivo | `#ED4133` | luz superior del fondo |
| Granate | `#7A1020` | contornos, wordmark, texto |
| Granate profundo | `#6E0B16` | volumen y sombras |
| Granate noche | `#4C0710` | viñeta, sombra máxima |
| Crema | `#FFF7E8` | relleno del wordmark, banda, labio |
| Arena | `#F3DFC0` | degradado de la banda |
| Oro | `#F5B942` | aro, etiqueta LIFE, regla |
| Oro claro | `#FFE3A3` | brillos y chispa |
| Oro oscuro | `#D99A2B` | sombra del oro, remaches |
| Melocotón | `#FDE3C8` | fondo del retrato |
| Melocotón rayo | `#F8C795` | rayos del sunburst |
| Tinta | `#231318` | líneas del personaje |
| Azul Sim | `#2563EB` | sudadera de la mascota base |

**Prohibido:** verde plumbob, cian, violeta, rosa chicle, blanco puro como fondo del icono, negro puro en el contorno (usa granate noche).

**Contraste:** crema sobre carmesí ≈ 5:1 (bien). Oro sobre crema es insuficiente: nunca pongas texto dorado sobre crema. Texto de la etiqueta LIFE siempre granate sobre oro.

**Accesibilidad:** el icono debe seguir leyéndose en deuteranopia. Rojo y oro se distinguen por **luminancia**, no solo por tono. Comprueba en escala de grises.

---

# 6. TIPOGRAFÍA

| Uso | Fuente | Peso | Notas |
|---|---|---|---|
| Wordmark `SIMS` | Titan One | 400 | Convertida a trazados. Nunca dependas de la fuente instalada. |
| Etiqueta `LIFE` | Titan One | 400 | Más pequeña, tracking amplio. |
| Subtítulo | Mulish | 700 | “Simulador de vida en tiempo real”. 24 px en lockup 1024×240. |
| Textos de apoyo | Mulish | 600/700 | Si alguna vez hay copy. |

**Reglas:**

- No pongas el subtítulo dentro del icono.
- No uses una fuente fina para el wordmark: a 48 px desaparece.
- Si el wordmark generado por IA tiene letras deformes, **no lo corrijas con parches**: redibújalo en vector con Titan One como base.
- El wordmark debe funcionar sin el medallón y el medallón sin el wordmark.

---

# 7. REGLAS DE DISEÑO

## 7.1 Jerarquía visual

1. **Silueta** del medallón + chispa (se reconoce en negro).
2. **Ojos** de la cara (contacto visual).
3. **Aro dorado** (calidez, premium).
4. **Wordmark** (solo cuando hay espacio).
5. **Detalles** (remaches, rayos, franjas).

Si a 48 px se ve el punto 5 antes que el 1, has fallado.

## 7.2 Icono primero

- Lienzo cuadrado 1:1.
- Sin texto, sin letras, sin números. El nombre va en la ficha de la tienda, no en el icono.
- El **conjunto** medallón + chispa ocupa el **82,5 %** del lienzo (845 px sobre 1024). El aro dorado queda en ~73 % y la chispa cabe dentro de esa caja: no la recortes.
- Margen interior mínimo de 8 px a 512 (16 px a 1024).
- Fondo a sangre, sin esquinas redondeadas propias: Android aplica la máscara.
- Un solo foco: la cara. No añadas casa, corazón, mando ni calendario.

## 7.3 Android

- **Icono adaptativo:** lienzo 108×108 dp; zona visible 72×72 dp (66,7 %); deja el aro y la chispa principal dentro de ~66 dp para que ninguna máscara los corte. A 4x: 432×432 px, zona visible 288×288 px.
  - *Foreground:* medallón + chispa principal, sin fondo, dentro de la zona visible (caja completa ≤ 285 px). La chispa secundaria y los puntos pueden omitirse en esta capa si el recorte circular los corta.
  - *Background:* carmesí + franjas + viñeta, a sangre, sin logo.
  - *Monocromo:* una sola tinta sobre transparente; silueta de aro + cabeza + chispa. Sin degradados ni detalles. Se usa en iconos temáticos de Android 13+.
- **Icono legacy:** 192×192 px, cuadrado, a sangre.
- **Splash:** 512×512 px, medallón al 72 %, fondo transparente.
- Comprueba el icono con máscara circular, squircle, cuadrado redondeado y gota.

## 7.4 Tamaños de prueba obligatorios

512 · 192 · 96 · 72 · 48 · 32 · 24 px.

A **48 px** debe verse: círculo, cara y chispa. A **32 px**: círculo y cara. A **24 px**: círculo y chispa (la cara puede simplificarse).

Haz tres pruebas:

1. **Escala de grises.**
2. **Silueta negra al 100 %.**
3. **Desenfoque de 1,5 px** (simula visión cansada).

## 7.5 Lo que sí

- Trazo grueso y uniforme (3–4 % del icono).
- Color plano + una capa de sombra suave.
- Formas redondeadas, esquinas limpias.
- Luz cálida desde arriba a la izquierda; sombra abajo a la derecha.
- Centrado óptico: el medallón puede subir un 0,8 % para compensar la chispa.
- Firma constante: chispa siempre a la 1–2.
- Fondo a sangre.
- Vector desde el primer boceto.

## 7.6 Lo que no

- Render 3D, Pixar, plástico, bisel grueso, brillos de lente.
- Degradados en la piel o en el pelo.
- Líneas finas de 1 px.
- Casa + corazón + mando + destellos (sopa de iconos).
- Calendario con carita, engranaje, burbuja de chat.
- Avatar genérico dentro de un círculo.
- Más de una cara.
- Texto dentro del icono.
- Sombra proyectada fuera del lienzo.
- Fondo blanco o transparente en el icono de tienda.
- Estética “AI glow”, bloom, chispas por todas partes.
- Pelo con miles de hebras, dientes, manos (si no hay manos, no hay dedos raros).
- Guiño: a tamaño pequeño parece un ojo cerrado o un defecto.
- El rombo verde de *The Sims* / *EA*.

## 7.7 La cara por defecto

- Joven adulto estilizado (20–25 años), **no un niño**.
- Piel media clara, pelo castaño con puntas gruesas, sudadera azul.
- Ojos grandes, marrones, con catchlight blanco; mirada al frente.
- Cejas gruesas y relajadas; sonrisa cerrada y pequeña; mejillas rosadas sutiles.
- Cabeza y hombros (busto), sin manos.
- Expresión: “me alegro de verte”, no “estoy emocionado”.
- La cara debe ser **simétrica en los ojos**; la asimetría se reserva a la sonrisa y al pelo.
- Deja 4–6 % de crema entre el pelo y el aro.

**Importante:** el icono de la tienda usa esta cara fija, pero el marco debe verse bien con otras apariencias. No fijes la marca al color de piel.

---

# 8. RUTAS CREATIVAS

Explora tres rutas antes de producir. Dibuja cada una como miniatura a **un color** y a **48 px**. Elige por silueta, no por detalle.

## Ruta A — “El camafeo vivo” (recomendada)

**Qué es:** evolución del logo actual. Medallón circular, cara, chispa, wordmark.

**Qué conservar:** círculo, oro, crema, carmesí, chispa a la 1–2, cara, `SIMS` + `LIFE`.

**Qué mejorar:**

- reduce el aro de 5 bandas a 3–4 (oro, crema, carmesí, labio);
- agranda la cara un 5–8 % dentro del hueco;
- engrosa el contorno un 10 %;
- haz la chispa más angular y un 10 % más grande;
- baja los remaches de 8 a 4 o elimínalos si ensucian a 48 px;
- suaviza las franjas del fondo (opacidad 3–4 %);
- unifica la luz: todo entra desde arriba a la izquierda.

**Por qué:** máxima continuidad, funciona con la cara dinámica, ya está integrada en `Logo_Juego.gd`, y es la que más se diferencia de los símbolos abstractos de la competencia.

**Riesgo:** que parezca “el logo viejo con un lavado de cara”. Para evitarlo, la chispa y el aro deben tener una mejora visible, no cosmética.

## Ruta B — “La ventana encendida”

**Qué es:** un cuadrado redondeado que es a la vez ventana y habitación; dentro, un busto de perfil o tres cuartos a la hora dorada; la chispa es el sol en el alféizar.

**Qué conservar:** paleta, calidez, cara, chispa.

**Por qué:** cuenta “vida doméstica” y “hogar” sin usar una casa literal.

**Riesgo:** se lee como app de decoración o inmobiliaria; a 48 px la ventana parece un cuadrado cualquiera; necesita el wordmark para explicarse. **No la elijas si la silueta no es inconfundible.**

## Ruta C — “El día uno”

**Qué es:** un reloj/calendario circular donde una aguja es la chispa y el centro es un corazón; el aro tiene marcas de edad (18→80).

**Qué conservar:** paleta, chispa, concepto de tiempo.

**Por qué:** conecta con “una semana real = un año” y con el ciclo de vida.

**Riesgo:** demasiado detalle a 48 px; parece app de productividad; el corazón + reloj es un cliché. **Resérvala para una sub-marca o un evento, no para el icono principal.**

## Decisión

Si ninguna ruta supera a A en la prueba de 48 px, **quédate con A**. La innovación debe estar en la ejecución (proporciones, luz, chispa, cara), no en cambiar el concepto por cambiar.

---

# 9. ENTREGABLES

## 9.1 Lista de archivos

| # | Archivo | Tamaño | Formato | Alpha | Notas |
|---|---|---|---|---|---|
| 1 | `Arte_Fuente/Marca/logo_maestro.svg` | vector | SVG 1.1 | sí | Fuente de verdad. Texto a trazados. Sin fuentes externas. |
| 2 | `Imagenes/Marca/logo_play_store_1024.png` | 1024² | PNG 32 bits | no visible | Maestro del icono. |
| 3 | `Imagenes/Marca/logo_play_store_512.png` | 512² | PNG 32 bits, ≤1 MB | no visible | **Subir a Play Console.** |
| 4 | `Imagenes/Marca/logo_horizontal_1024x240.png` | 1024×240 | PNG | no | Lockup sobre rojo. |
| 5 | `Imagenes/Marca/logo_horizontal_claro_1024x240.png` | 1024×240 | PNG | no | Lockup sobre crema. |
| 6 | `Imagenes/Marca/logo_horizontal_oscuro_1024x240.png` | 1024×240 | PNG | no | Lockup sobre oscuro. |
| 7 | `Imagenes/Marca/logo_vertical_1024.png` | 1024² | PNG | no | Composición vertical. |
| 8 | `Imagenes/Marca/feature_graphic_1024x500.png` | 1024×500 | PNG/JPEG, ≤15 MB | no | Gráfico destacado de Play. |
| 9 | `Imagenes/Marca/wordmark_claro.png` | 2026×720 | PNG | sí | Wordmark crema, sin subtítulo. |
| 10 | `Imagenes/Marca/wordmark_oscuro.png` | 2026×720 | PNG | sí | Wordmark carmesí, sin subtítulo. |
| 11 | `Imagenes/Marca/medallon_marco.png` | 1024² | PNG | sí, hueco central | Marco sin cara. Hueco Ø 731 px. |
| 12 | `Imagenes/Marca/medallon_completo.png` | 1024² | PNG | sí | Medallón con cara por defecto. |
| 13 | `Iconos_Android/icono_192.png` | 192² | PNG | no | Legacy. |
| 14 | `Iconos_Android/icono_adaptativo_frente_432.png` | 432² | PNG | sí | Dentro de zona segura. |
| 15 | `Iconos_Android/icono_adaptativo_fondo_432.png` | 432² | PNG | no | A sangre. |
| 16 | `Iconos_Android/icono_monocromo_432.png` | 432² | PNG | sí | Una tinta. |
| 17 | `Iconos_Android/splash_icon_512.png` | 512² | PNG | sí | Medallón al 72 %. |

## 9.2 Reglas de exportación

- sRGB, 8 bits por canal, sin interlazado.
- PNG con alpha **straight** (no premultiplicado), borde limpio, sin halo blanco.
- SVG: `viewBox="0 0 1024 1024"`, IDs únicos, sin scripts, sin fuentes externas, sin imágenes embebidas salvo la cara por defecto del icono.
- Nombres en minúsculas con guiones bajos y dimensiones.
- No entregues solo un PNG aplanado: el SVG es la fuente de verdad.
- No edites los PNG a mano: se regeneran con `python3 Arte_Fuente/Marca/generar_logo.py`.

## 9.3 Entregables de exploración (no finales)

- Hoja 3×4 con 12 miniaturas a un color.
- 3 finalistas a 1024 px, en color y en negro.
- Prueba de los 3 finalistas a 48/32/24 px.
- Prueba sobre pantalla de inicio simulada (fondo variado, 30 iconos).
- Prueba con 3 apariencias distintas (clara, oscura, gafas/pelo rizado).
- Tabla de puntuación de la sección 12.

---

# 10. BLOQUES LISTOS PARA PEGAR

> En los prompts de imagen, usa 1:1 y estilo “raw” si el modelo lo permite. Genera 4 variantes por bloque. Elige por silueta, no por detalle.

## 10.1 Icono de app (inglés)

```text
Square 1:1 mobile game app icon, 1024x1024, flat 2D vector cartoon illustration, premium casual style.

A circular enamel-and-gold medallion badge, perfectly centered, the complete badge including the spark occupying 82% of the canvas, the gold ring itself about 73%, floating on a deep crimson background (#D62828) with subtle 45-degree diagonal stripes, warm light from the upper left and a soft dark vignette in the corners.

Inside the medallion: a friendly young adult Sim, front-facing bust, light-medium skin, big warm brown eyes with white catchlights, thick relaxed dark-brown eyebrows, chunky spiky chestnut hair, rosy cheeks, small closed-mouth smile, blue hoodie. The face sits on a cream sunburst background with peach rays. Generous cream margin between the hair and the frame.

Medallion frame from outside in: thin deep-garnet outline, polished gold ring with a bright highlight at the upper left, cream enamel band with 8 tiny gold rivets, crimson enamel ring, thin gold pinstripe, cream inner lip. Thick uniform dark-garnet outlines, 3-4% of the icon. Flat colors with one soft shade layer.

At the upper right (1-2 o'clock), a bright four-point golden spark breaks the outer ring, with a smaller white spark and two tiny dots.

Style: crisp sticker-like vector, rounded shapes, high contrast, readable at 48x48, no gradients on the skin, no photorealism, no 3D bevel, no glossy plastic, no text, no letters, no numbers, no watermark, no mockup, no phone frame, no shadow outside the canvas.
```

## 10.2 Wordmark (inglés)

```text
Custom chunky rounded display lettering, the word "SIMS" only, spelled S-I-M-S, four letters, cream #FFF7E8 fill, thick deep-garnet #7A1020 outline, offset garnet shadow, subtle top highlight, playful baseline, wide counters, sticker style. To the lower right, a small tilted gold ticket with the word "LIFE" in garnet and a tiny heart, overlapping the baseline. Transparent background, 2.8:1 aspect ratio, 2048 px wide, flat 2D vector, no extra text, no subtitle, no mockup, no watermark.
```

> Si el modelo deforma las letras (lo normal), descarta la imagen y redibuja el wordmark en vector con Titan One como base. No aceptes “SIMS” con una letra inventada.

## 10.3 Lockup horizontal (inglés)

```text
Horizontal brand lockup, 1024x240, crimson background with subtle diagonal stripes and warm light. On the left, the circular gold-and-enamel medallion badge with the friendly Sim face, badge height 83% of the canvas. On the right, the chunky cream "SIMS" wordmark at 59% of the canvas height, with the tilted gold "LIFE" ticket. Below the wordmark, a small gold rule and the subtitle "Simulador de vida en tiempo real" in Mulish Bold cream. Left-aligned, balanced, 48 px safe margins, flat 2D vector, crisp, no extra text, no watermark, no mockup.
```

## 10.4 Gráfico destacado de Play Store (inglés)

```text
Google Play feature graphic, 1024x500, no transparency. Deep crimson background with 45-degree diagonal stripes, warm light from the upper left, soft vignette. Left: the circular gold-and-enamel medallion badge with the friendly Sim face, 300 px diameter, at 52 px from the left edge. Right: the chunky cream "SIMS" wordmark, 200 px tall, with the tilted gold "LIFE" ticket. Below: a short gold rule and the subtitle "Simulador de vida en tiempo real" in Mulish Bold cream. 48 px safe margins, strong hierarchy, flat 2D vector, no screenshots, no phone, no extra text, no watermark.
```

## 10.5 Icono adaptativo (inglés)

**Foreground**

```text
Android adaptive icon foreground, 432x432, transparent background. The circular gold-and-enamel medallion badge with the friendly Sim face and the four-point golden spark at the upper right, centered, the complete artwork including the main spark fitting inside the central 66% of the canvas (285 px, within the 288 px visible area); omit the tiny secondary spark and dots if the circular mask would crop them. The gold ring itself is about 58%. No background, no text, no letters, flat 2D vector, thick dark-garnet outlines, crisp clean alpha edges, no shadow outside the artwork.
```

**Background**

```text
Android adaptive icon background, 432x432, fully opaque. Deep crimson (#D62828) with subtle 45-degree diagonal stripes, warm radial light from the upper left, soft dark vignette in the corners. No logo, no text, no face, no spark, flat 2D vector, full bleed.
```

## 10.6 Monocromo (inglés)

```text
Android monochrome icon, 432x432, transparent background, single-color cream silhouette: a thick ring, a simple head-and-shoulders silhouette inside, and a four-point spark breaking the ring at the upper right. No gradients, no facial details, maximum two shapes, alpha-only, crisp edges, readable at 24x24. Android will tint it.
```

## 10.7 Exploración para IA de diseño (español)

```text
Actúa como director de arte de identidad visual. No generes la imagen final todavía.

Con el brief anterior, entrega:
1. Una frase de concepto y un nombre de ruta.
2. Doce miniaturas descritas en una línea cada una (forma, silueta, qué la hace distinta). Si puedes generar imágenes, haz una hoja 3x4; si no, descríbelas.
3. Tres finalistas. Para cada uno: por qué funciona a 48 px, qué la hace distinta de The Sims y qué riesgo tiene.
4. La geometría del finalista: diámetros, grosores, proporciones, posición de la chispa.
5. La lista de archivos que producirías.
6. Una crítica honesta: ¿qué es lo más débil y cómo lo arreglarías sin añadir detalle?

No uses casas, corazones, mandos, engranajes, burbujas de chat ni el rombo verde. No me des una lista de adjetivos: toma decisiones y justifícalas.
```

## 10.8 Prompt negativo (inglés)

```text
text, letters, numbers, wordmark, subtitle, watermark, signature, 3D render, CGI, photorealism, glossy plastic, bevel, metallic reflection, lens flare, bloom, intricate details, thin lines, low contrast, blurry, noisy, jpeg artifacts, cropped, off-center, multiple logos, logo sheet, mockup, phone, hand, grid, green diamond, plumbob, The Sims logo, EA logo, generic house icon, game controller, joystick, gear, chat bubble, calendar smiley, clipart, stock icon, gradients on the face, deformed eyes, asymmetric eyes, extra teeth, extra fingers, child face, baby face
```

## 10.9 Variaciones útiles (seguimiento)

- “Haz 6 variaciones cambiando solo el peinado; mantén el resto idéntico.”
- “Reduce el detalle del aro un 30 % y engrosa el contorno un 15 %.”
- “Acerca la cara un 8 % y deja más aire entre el pelo y el aro.”
- “Haz la chispa un 20 % más grande y más angular.”
- “Elimina las franjas del fondo y compara la legibilidad a 48 px.”
- “Genera la versión monocroma con solo aro, cabeza y chispa.”
- “Muestra el icono a 512, 96, 48 y 24 px en la misma imagen.”
- “Pon el icono entre 30 iconos de app y dime cuál es el más reconocible.”

## 10.10 Qué corregir cuando la IA falla

| Fallo | Corrección |
|---|---|
| Letras deformes | No usar texto generado; redibujar en vector. |
| Ojos raros o bizcos | “symmetric eyes, centered gaze, no wink, no teeth”. |
| Aspecto 3D | “flat 2D vector, no 3D render, no bevel, no gloss”. |
| Demasiado detalle | “simplify to 3 main shapes, readable at 48 px”. |
| Icono pequeño en el lienzo | “badge fills 82% of the canvas”. |
| Fondo blanco | “solid crimson background, full bleed, no white”. |
| Cara infantil | “young adult, 22 years old, stylized, not a child”. |
| Marca de agua | Activa el negativo y recorta; no la tapes con parches. |
| Varias caras | “one single face, one single badge”. |

---

# 11. PROTOCOLO DE ITERACIÓN

1. **Ronda 1 — Siluetas (15 min).** 12 miniaturas a un color, 256 px. Sin texto. Puntúa solo silueta.
2. **Ronda 2 — Finalistas.** 3 propuestas a 1024 px, color y negro. A 48/32/24 px. Elimina una.
3. **Ronda 3 — Refinado.** 1 propuesta. Ajusta geometría, luz y cara. Prueba con 3 apariencias.
4. **Ronda 4 — Sistema.** Icono, adaptativo, monocromo, lockups, fondo claro/oscuro, feature.
5. **Ronda 5 — Vector y QA.** Redibuja en SVG, exporta, pasa la checklist de la sección 16.

**Regla de descarte:** si a 48 px no se distingue la cara o la chispa, no pasa. No se arregla con más detalle; se arregla simplificando.

---

# 12. RÚBRICA (100 puntos)

| Criterio | Peso | Qué se evalúa |
|---|---|---|
| Legibilidad a 48 px | 25 | Silueta, cara y chispa reconocibles; sin texto. |
| Diferenciación | 20 | No parece *The Sims* ni un icono genérico; el carmesí/oro/crema es territorio propio. |
| Adecuación emocional | 15 | Cálido, optimista, joven adulto; no infantil ni frío. |
| Escalabilidad y versatilidad | 15 | Funciona en icono, adaptativo, mono, lockup, claro/oscuro. |
| Producción vectorial | 15 | Formas limpias, trazos uniformes, sin efectos imposibles. |
| Resistencia a tendencias | 10 | No depende de glassmorphism, neón ni 3D. |

**Aprobado:** ≥ 80/100 y ningún criterio por debajo del 50 %.

---

# 13. FORMATO DE RESPUESTA

Entrega exactamente este bloque, sin relleno:

```text
CONCEPTO
Nombre:
Frase (máx. 12 palabras):

POR QUÉ FUNCIONA
- ...
- ...
- ...

GEOMETRÍA
Lienzo:
Medallón:
Hueco:
Aro:
Chispa:
Wordmark:
Etiqueta LIFE:

COLOR
Tokens usados:

TIPOGRAFÍA
Wordmark:
Subtítulo:

ADAPTACIONES
Icono:
Adaptativo:
Monocromo:
Lockup:
Feature:

PRUEBAS
48 px:
32 px:
24 px:
Gris:
Silueta:
3 apariencias:

ARCHIVOS
...

RIESGOS
- ...
- ...
```

Si produces imágenes, entrega además: 12 miniaturas, 3 finalistas y una prueba de tamaños. No entregues una imagen final sin la geometría y la justificación.

---

# 14. ANEXO TÉCNICO — INTEGRACIÓN CON EL JUEGO

## 14.1 Geometría exacta (medallón 1024)

```
Lienzo 1024 × 1024
┌────────────────────────────────────┐
│              ✦  chispa             │
│         ╭──────────────╮           │
│        │    ○ cara     │           │
│         ╰──────────────╯           │
└────────────────────────────────────┘

Aro exterior:      904 px (88,3 %), R = 452 px
Caja del medallón: 1024 px (la chispa llega a ~935 px de ancho)
Hueco central:     731 px (71,4 %), r = 357 px
Margen por lado:   146 px (14,29 %)
Banda total:        95 px (9,3 %)
  · oro exterior:   22 px
  · crema:          30 px
  · carmesí:        22 px
  · filete oro:     21 px
```

- Centro: `(512, 512)`.
- Hueco concéntrico, tolerancia ±1 px.
- Chispa principal: centro aproximado `(810, 196)`, radio `92 px`, a la 1–2.
- Segunda chispa: `(903, 103)`, radio `32 px`.
- Remaches: 8, a 45°, radio `415 px`, r `5,3 px`, empezando a −68°.
- Franjas del fondo: paso 76,8 px, ancho 28,7 px, 45°, blanco al 4,5 %.

## 14.2 Cómo lo usa el juego

`Scripts/GUI/Menu/Logo_Juego.gd` construye un `HBoxContainer`:

- **Insignia:** `medallon_marco.png` sobre una máscara circular con `Personaje_Visual` en modo `retrato`, `margen_retrato = 12`, expresión `sonrisa`.
- **Margen de la máscara:** `MARGEN_MARCO = 0.1429` (coincide con el 14,29 % del hueco).
- **Wordmark:** `wordmark_claro.png` o `wordmark_oscuro.png`; alto = `0.72 × tamano_insignia`; aspecto ≈ 2,81.
- **Subtítulo:** Mulish 700; tamaño = `0.125 × tamano_insignia` (o manual).
- **Cara dinámica:** se actualiza con `configurar_apariencia(datos)` sin reconstruir el logo.

**Consecuencias para el diseño:**

- El marco debe ser un PNG con el **centro realmente transparente** y el borde del hueco limpio; si hay halo, se ve sobre la cara.
- El hueco debe ser un círculo perfecto: la máscara es un `Panel` con `clip_children` y radio 999.
- El wordmark debe ir **separado** del medallón; no lo incrustes en el marco.
- No cambies `MARGEN_MARCO` sin actualizar también la geometría del PNG y este documento.
- El icono de tienda y el logo in-game comparten el medallón, pero son archivos distintos: el de tienda lleva cara fija; el del juego, marco vacío.

## 14.3 Pipeline

```bash
# 1. Mascota base (solo si cambia Personaje_Visual o la apariencia por defecto)
godot --path . --script res://Scripts/Otro/Herramientas/Exportar_Mascota_Logo.gd

# 2. Assets oficiales (icono, lockups, vertical, feature, wordmark, marco, fondos)
python3 Arte_Fuente/Marca/generar_logo.py

# 3. Iconos Android del APK
godot --headless --path . --script res://Scripts/Otro/Herramientas/Generar_Iconos_Android.gd

# 4. Variantes con el Sim guardado (opcional)
godot --path . --script res://Scripts/Otro/Herramientas/Exportar_Logo_Marca.gd
```

`Arte_Fuente/` tiene `.gdignore`: Godot no la importa. Los PNG finales viven en `Imagenes/Marca/` y `Iconos_Android/`.

## 14.4 Restricciones de Play Store

- Icono: 512×512, PNG de 32 bits, ≤1 MB, sin transparencia visible, sRGB.
- Feature graphic: 1024×500, PNG/JPEG sin alpha, ≤15 MB.
- No uses capturas de pantalla dentro del icono.
- No incluyas texto ilegible ni marcas de terceros.
- Comprueba el icono en la ficha móvil y en la web.

---

# 15. NOTA LEGAL (IMPORTANTE)

`SIMS` es una marca registrada de Electronic Arts. Este brief **no autoriza** a imitar el logotipo de *The Sims*, su *plumbob* verde ni sus elementos distintivos. El diseño debe ser original: medallón, camafeo, chispa y paleta propios.

Si el objetivo es publicar comercialmente, revisa el nombre con un profesional de propiedad industrial. El sistema visual funciona igual con un nombre propio distinto: el medallón y la chispa son la marca; el wordmark se puede sustituir sin rehacer el icono.

---

# 16. CHECKLIST FINAL

- [ ] Se reconoce a 48 px y a 32 px.
- [ ] La chispa se ve a 24 px.
- [ ] Funciona en escala de grises y en silueta negra.
- [ ] Funciona con máscara circular, squircle y cuadrado redondeado.
- [ ] Fondo rojo, claro y oscuro.
- [ ] Tres apariencias distintas (clara, oscura, gafas/rizado).
- [ ] Sin texto dentro del icono.
- [ ] Sin rombo verde ni referencias a EA/*The Sims*.
- [ ] Hueco del medallón perfectamente circular y limpio.
- [ ] Wordmark bien escrito: S-I-M-S.
- [ ] Subtítulo bien escrito: “Simulador de vida en tiempo real”.
- [ ] SVG sin fuentes externas, texto a trazados.
- [ ] PNG sRGB, sin halo, sin transparencia visible en el icono de tienda.
- [ ] Archivos con los nombres y tamaños de la sección 9.
- [ ] Probado en un móvil real, entre otros iconos.
- [ ] Documentación actualizada (`Documentacion/Marca/README.md` y este prompt).

---

**Recordatorio final:** si dudas entre dos opciones, elige la que se lea mejor a 48 px. El logo no es una ilustración; es una señal. En una pantalla llena de iconos, este debe ser el que parece mirarte.
