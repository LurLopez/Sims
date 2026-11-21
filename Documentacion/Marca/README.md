# Marca y logo — SIMS LIFE

## Concepto: «La chispa de una vida»

El logotipo combina tres piezas:

1. **Medallón**: un camafeo cálido con la cara del Sim, aro de oro, banda de crema y
   anillo carmesí. Un destello dorado rompe el aro por la esquina superior derecha:
   la «chispa» de una vida que empieza.
2. **Wordmark**: `SIMS` en Titan One, convertido a trazados, con relleno crema,
   contorno granate y volumen. La etiqueta `LIFE` va en una chapa dorada inclinada
   con un corazón, como una pegatina.
3. **Fondo**: carmesí con franjas diagonales, luz cálida y viñeta. Hay versiones
   para fondo rojo, claro y oscuro.

La cara del medallón es **dinámica** dentro del juego: se dibuja con
`Personaje_Visual` y la apariencia del protagonista. El icono de Play Store y el
del lanzador son **fijos** (Android no permite cambiar el icono del lanzador en
runtime salvo con `activity-alias` predefinidos).

## Paleta

| Token | Hex | Uso |
|---|---|---|
| Rojo Vida | `#D62828` | color principal, fondo y anillo |
| Rojo vivo | `#ED4133` | luz superior del fondo |
| Granate | `#7A1020` | contorno del wordmark y del medallón |
| Granate profundo | `#6E0B16` / `#4C0710` | volumen y sombras |
| Crema | `#FFF7E8` | relleno del wordmark y banda del medallón |
| Arena | `#F3DFC0` | degradado de la banda |
| Oro | `#F5B942` | aro, etiqueta LIFE y destellos |
| Oro claro | `#FFE3A3` | brillos |
| Melocotón | `#FDE3C8` | fondo del retrato |
| Melocotón rayo | `#F8C795` | rayos del sunburst |
| Tinta | `#231318` | líneas del personaje |
| Azul Sim | `#2563EB` | sudadera de la mascota base |

## Tipografía

- **Titan One** (`Fuentes/UI/TitanOne-400.ttf`): wordmark `SIMS` y etiqueta `LIFE`.
  En los assets se convierte a trazados SVG para no depender de la fuente instalada.
- **Mulish 700** (`Fuentes/UI/Mulish-700.ttf`): subtítulo
  «Simulador de vida en tiempo real».

## Assets oficiales

| Archivo | Uso |
|---|---|
| `Imagenes/Marca/logo_play_store_512.png` | **subir este** a Play Console (512×512, PNG 32 bits) |
| `Imagenes/Marca/logo_play_store_1024.png` | maestro del icono |
| `Imagenes/Marca/logo_horizontal_1024x240.png` | lockup sobre rojo (web, prensa, capturas) |
| `Imagenes/Marca/logo_horizontal_claro_1024x240.png` | lockup sobre fondo claro |
| `Imagenes/Marca/logo_horizontal_oscuro_1024x240.png` | lockup sobre fondo oscuro |
| `Imagenes/Marca/logo_vertical_1024.png` | composición vertical / redes |
| `Imagenes/Marca/feature_graphic_1024x500.png` | gráfico destacado de Play Store |
| `Imagenes/Marca/wordmark_claro.png` | wordmark transparente para fondos rojos/oscuros (logo in-game, 512×182; maestro 1013 px en `Arte_Fuente/Marca/`) |
| `Imagenes/Marca/wordmark_oscuro.png` | wordmark transparente para fondos claros (512×182) |
| `Imagenes/Marca/medallon_marco.png` | marco del medallón con el centro transparente (256×256 para runtime; maestro 1024 en `Arte_Fuente/Marca/`) |
| `Imagenes/Marca/Fondos/` | fondos rojo/claro/oscuro para variantes personalizadas |
| `Imagenes/Marca/Personalizado/` | variantes opcionales con la cara del Sim guardado |

## Logo dinámico in-game

`Scripts/GUI/Menu/Logo_Juego.gd` (`class_name Logo_Juego`) es un `HBoxContainer`:

- **Medallón**: `medallon_marco.png` sobre una máscara circular con
  `Personaje_Visual` en modo `retrato`, `margen_retrato = 12`, expresión `sonrisa` y
  sunburst melocotón. La máscara usa un `Panel` con `clip_children` y radio 999.
- **Wordmark**: `wordmark_claro.png` (o `wordmark_oscuro.png` con
  `variante_oscura = true`). Escala con `tamano_insignia`.
- **Subtítulo**: `Mulish-700` + regla dorada. El tamaño es proporcional al medallón
  (`tamano_insignia * 0.125`); `tamano_subtitulo` permite fijarlo a mano (0 = auto).
- **Cara dinámica**: se actualiza con `configurar_apariencia(datos)` sin reconstruir
  el logo. En el menú principal se alimenta de `Variables_Estaticas.Apariencia`.

```gdscript
var logo := Logo_Juego.new()
logo.tamano_insignia = 104
logo.subtitulo = "Simulador de vida en tiempo real"
logo.variante_oscura = false # true sobre fondos claros
add_child(logo)
logo.configurar_apariencia(Variables_Estaticas.Apariencia)
```

## Cómo regenerar

Dependencias: Python 3 con `fontTools` y `Pillow`, `rsvg-convert` y Godot 4.4+.

```bash
# 1. Mascota base del icono (solo si cambia Personaje_Visual o la apariencia por defecto)
godot --path . --script res://Scripts/Otro/Herramientas/Exportar_Mascota_Logo.gd

# 2. Assets oficiales (icono, lockups, vertical, feature, wordmark, marco y fondos)
python3 Arte_Fuente/Marca/generar_logo.py

# 3. Iconos Android del APK (opcional: el paso 2 ya los deja generados)
godot --headless --path . --script res://Scripts/Otro/Herramientas/Generar_Iconos_Android.gd

# 4. Variantes personalizadas con el Sim guardado (opcional)
godot --path . --script res://Scripts/Otro/Herramientas/Exportar_Logo_Marca.gd
```

`Arte_Fuente/` tiene un `.gdignore`: es la carpeta de fuentes (Python, SVGs, mascota
maestra) y Godot no la importa. Los PNG finales viven en `Imagenes/Marca/` y en
`Iconos_Android/`.

## Play Store y APK

- **Icono de ficha**: `logo_play_store_512.png` (512×512, PNG 32 bits). Se sube una
  vez por versión; Play Store no usa iconos generados en el dispositivo.
- **Gráfico destacado**: `feature_graphic_1024x500.png` (opcional pero recomendado).
- **Lanzador/APK**: `Iconos_Android/icono_192.png`,
  `icono_adaptativo_frente_432.png`, `icono_adaptativo_fondo_432.png`,
  `icono_monocromo_432.png` y `splash_icon_512.png`.
- `project.godot` apunta `config/icon` a `logo_play_store_512.png`. `icon.svg` queda
  como versión vectorial de respaldo.
- El icono del lanzador Android es fijo; la personalización por Sim se queda dentro
  de la app (menú, avatar, perfil y logo in-game).

## Archivos

```
Arte_Fuente/Marca/
├── generar_logo.py          # pipeline de marca (SVG → PNG)
├── mascota_logo.png         # render base del Sim (2048×2048)
├── medallon_completo.png    # medallón con cara, fondo transparente
├── icono.svg                # fuente vectorial del icono
├── lockup_rojo.svg
├── lockup_claro.svg
├── lockup_oscuro.svg
└── monocromo.svg

Imagenes/Marca/
├── logo_play_store_512.png
├── logo_play_store_1024.png
├── logo_horizontal_1024x240.png
├── logo_horizontal_claro_1024x240.png
├── logo_horizontal_oscuro_1024x240.png
├── logo_vertical_1024.png
├── feature_graphic_1024x500.png
├── wordmark_claro.png
├── wordmark_oscuro.png
├── medallon_marco.png
├── Fondos/
└── Personalizado/

Scripts/GUI/Menu/Logo_Juego.gd
Scripts/Otro/Herramientas/Exportar_Mascota_Logo.gd
Scripts/Otro/Herramientas/Generar_Iconos_Android.gd
Scripts/Otro/Herramientas/Exportar_Logo_Marca.gd
```

> No edites los PNG a mano: se regeneran desde `generar_logo.py`. Si cambias la
> paleta o la tipografía, actualiza también este README y el Mega Prompt.
