# Optimización del arranque en Android (v0.33)

## Síntoma

En un **Xiaomi Redmi 11S** el APK se quedaba en la pantalla de carga y no llegaba a mostrar el juego. El problema no era un error de lógica: la escena principal tardaba demasiado en cargar y el dispositivo podía quedarse sin memoria o bloquear el hilo principal antes de retirar la capa de carga.

## Causas detectadas

1. **Texturas del minijuego precargadas al arrancar.** `Script_Principal.gd` hacía `preload("res://Escenas/Minijuego_Cocina/Minijuego_Cocina.tscn")`, que a su vez cargaba `Arte_Cocina.gd` con 152 `preload()` de PNG. Son ~72 MB en RGBA que el menú y la escena principal no necesitan.
2. **Flecha de 2400×2400.** `Imagenes/Juego/Flecha.png` ocupaba 22 MB en VRAM y se usaba en botones de 100×100.
3. **Pantallas completas construidas al inicio.** Carrera, Economía, Minijuegos y Vestuario se montaban en `_ready()` aunque el jugador no las abriera.
4. **Primer guardado costoso.** `First_Time_Function.Crear_Matriz()` hacía 826.560 `append()` y `_RLE_A_Matriz()` recorría cada celda, incluidos los tramos vacíos.
5. **Escaneo periódico del árbol.** `_process` llamaba a `find_children("*", "", true, false)` cada 0,5 s para estilizar diálogos.
6. **Renderer `mobile` (Vulkan).** En GPUs modestas o drivers problemáticos añade compilación de pipelines y puede colgar la inicialización.

## Cambios aplicados

### Carga perezosa de arte y pantallas

- `Arte_Cocina.gd`: las 48 texturas escalares son `static var TEX_*: Texture2D` con getter a `_tex(ruta)` y caché. `RUTAS_CLIENTES`, `RUTAS_CHEF` y `RUTAS_MEJORAS` cargan solo el recurso solicitado.
- `Script_Principal.gd`: `Minijuego_Cocina.tscn`, `Transicion_Minijuego.gd` y el arte de la cocina se cargan al abrir el minijuego (`_Obtener_Escena_Minijuego_Cocina()`, `_Obtener_Transicion_Minijuego()`).
- `Pantalla_Carrera`, `Pantalla_Economia`, `Pantalla_Minijuegos` y `Pantalla_Vestuario` se crean la primera vez que se abren y tienen guardas para no duplicarse.
- `Musica`: el MP3 del minijuego ya no se precarga; se carga en el primer `Reproducir_Minijuego()`.
- `Logo_Juego`: assets de runtime reducidos (medallón 256×256, wordmarks 512×182). Los maestros quedan en `Arte_Fuente/Marca/` y `generar_logo.py` genera ambas versiones.

### Texturas

- `tools/optimizar_import_texturas.py` marca los 160 PNG grandes del minijuego y del cómic con `compress/mode=2` y `compress/high_quality=false` → ETC2 en Android (obligatorio en GLES3), S3TC/BPTC en escritorio.
- El resto de texturas (iconos, tienda, marca) se queda en lossless: los PNG planos pesan menos que un bloque comprimido.
- `Imagenes/Juego/Flecha.png` 2400×2400 → 256×256; `Flecha_Atras.png` 356 → 128.

### Guardado

- `First_Time.Crear_Matriz()`: `resize(1440)` + `resize(574)` + `fill("")` + `duplicate()` por fila.
- `_Matriz_A_RLE()`: detecta filas completamente vacías comparando con una fila base y añade un tramo de 574 celdas sin recorrerlas.
- `_RLE_A_Matriz()`: las filas se crean ya rellenas de `""` y los tramos vacíos solo avanzan el índice.
- Test de regresión: `Funcionalidades/Guardado/Tests/test_guardado_matriz.gd`.

### UI y pantalla de carga

- `SceneTree.node_added` sustituye al `find_children()` periódico: los `AcceptDialog`/`Window` se estilizan al añadirse, una sola vez.
- `Pantalla_Carga` añade un vigilante: si el hilo no avanza en 8 s o la carga supera 30 s, deja de esperar y resuelve la carga en primer plano. La barra ya no puede quedarse congelada indefinidamente.
- `project.godot`: `renderer/rendering_method="gl_compatibility"` y `rendering_device/fallback_to_opengl3=true`. El juego es 2D y no usa shaders, luces ni 3D.
- `export_presets.cfg`: `export_filter="exclude"` para dejar fuera tests GUT, documentación, capturas y escenas de herramientas.

## Medición (escritorio de referencia)

| Métrica | Antes | Después |
|---|---:|---:|
| Carga de `Escena principal.tscn` | 1,06 s | 0,52 s |
| Memoria estática tras cargar | 124,6 MB | 48,0 MB |
| `_ready` + 5 frames | 1,70 s | 0,74 s |
| Memoria final tras `_ready` | 242,2 MB | ~130 MB |
| APK debug | 62,5 MB | ~62 MB |

Las cifras son de escritorio; en Android el ahorro relativo es mayor porque las texturas pasan de RGBA a ETC2 y ya no se cargan las del minijuego.

## Reproducir la medición

```bash
# Recursos pesados (menú, arte de cocina, escena principal)
godot --headless --path . --script res://Scripts/Otro/Herramientas/Perfil_Arranque.gd

# Instanciación completa de la escena principal en modo partida nueva
XDG_DATA_HOME=/tmp/sims-perfil godot --headless --path . \
  --script res://Scripts/Otro/Herramientas/Perfil_Escena_Principal.gd

# Reimportar texturas tras cambiar el script de optimización
python3 tools/optimizar_import_texturas.py
godot --headless --path . --import
```

## Verificación

- GUT: **256 tests / 256 pasan** (`addons/gut/gut_cmdln.gd`).
- Captura visual del minijuego y del Home con `Escenas/Herramientas/Captura_*`.
- APK debug generado y subido a Google Drive con `scripts_vps/crear_apk_drive.sh`.
