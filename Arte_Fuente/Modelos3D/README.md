# Modelos 3D de Blender — minijuego «Salir a correr / PARK RUSH 3D»

Pipeline paramétrico en Blender (`bpy` / `bmesh`) que sustituye por completo los
modelos procedurales del runner (vías, escenario, obstáculos, coleccionables,
power-ups, equipamiento del Sim, guardia y perro K9) por 38 mallas `.glb`
detalladas e importadas en `Modelos/Minijuego_Correr/`.

> El personaje jugable (`Runner_Personaje_3D`) conserva intacto su modelo
> dinámico del Sim con ropa equipada, peinados, rasgos faciales y edad; los
> accesorios de power-up (`hoverboard`, `jetpack`, `pogo`, `alas_zapatilla`) sí
> usan `.glb` de Blender.

## Requisitos

- Blender 4.2 LTS en `~/.local/bin/blender` (`blender --version`).
- Python 3 del sistema con `Pillow` y `numpy` para generar las texturas UV.
- Todo corre en modo headless (sin UI).

Si Blender no está instalado:

```bash
curl -sSL -o /tmp/blender.tar.xz \
  https://download.blender.org/release/Blender4.2/blender-4.2.23-linux-x64.tar.xz
tar xf /tmp/blender.tar.xz -C ~ && ln -sfn ~/blender-4.2.23-linux-x64/blender ~/.local/bin/blender
```

## Regeneración completa (38 modelos `.glb`)

```bash
python3 Arte_Fuente/Modelos3D/Correr/generar_todo.py
```

O con hojas 4-vistas de comprobación (`*_preview.png`):

```bash
python3 Arte_Fuente/Modelos3D/Correr/generar_todo.py --con-render
```

Genera texturas UV en `Imagenes/Minijuego_Correr/Texturas3D/`, ejecuta los 34
scripts de `Arte_Fuente/Modelos3D/Correr/`, exporta los 38 `.glb` a
`Modelos/Minijuego_Correr/` y valida cada uno con `verificar_glb.py`.

Para regenerar e inspeccionar un único modelo (ejemplo: vagón):

```bash
~/.local/bin/blender -b --python Arte_Fuente/Modelos3D/Correr/vagon_metro.py -- \
  --salida Modelos/Minijuego_Correr/vagon_metro.glb \
  --blend Arte_Fuente/Modelos3D/Correr/vagon_metro.blend \
  --render Arte_Fuente/Modelos3D/Correr/vagon_metro_preview.png
```

Tras regenerar modelos o texturas, reimporta en Godot y verifica visualmente:

```bash
~/.local/bin/godot --headless --import
GODOT_BIN=~/.local/bin/godot ./scripts_vps/captura.sh Captura_Correr
GODOT_BIN=~/.local/bin/godot ./scripts_vps/captura.sh Captura_Vagon_Blender
```

## Catálogo de scripts y modelos (`Arte_Fuente/Modelos3D/Correr/`)

- **Librería y texturas:** `lib_blender.py` (primitivas `bmesh`, biseles acotados,
  tubos Catmull-Rom, muelles helicoidales, estrellas 3D, render 4-vistas),
  `generar_texturas_modelos.py`, `generar_todo.py`.
- **Trenes y obstáculos:** `vagon_metro.py`, `fuelle_vagon.py`,
  `tren_movil_extra.py`, `rampa_tren.py`, `vagoneta_speeder.py`,
  `valla_baja.py`, `arco_galibo.py`, `tunel_ferroviario.py`.
- **Vía y entorno urbano:** `balasto_chunk.py`, `traviesa.py`, `rail_tramo.py`,
  `catenaria_tramo.py`, `anden_tramo.py`, `muro_corredor.py`,
  `banco_estacion.py`, `cajas_andenes.py`, `papelera_urbana.py`,
  `farola_estacion.py`, `arbol_parque.py`, `portico_catenaria.py`,
  `puente_cartel.py`, `edificios.py` (`edificio_0..4.glb`).
- **Coleccionables y power-ups:** `moneda.py`, `powerup_iman.py`,
  `powerup_zapatillas.py`, `alas_zapatilla.py`, `powerup_estrella_2x.py`,
  `powerup_llave.py`, `powerup_caja.py`, `hoverboard.py`, `jetpack.py`, `pogo.py`.
- **Personajes persecutores articulados:** `guardia.py`, `perro_policia.py`.

## Reglas de integración

1. **Shader curvo obligatorio.** `Runner_Escenario_3D` convierte cada superficie
   del `.glb` a `ShaderMaterial` con `Shaders/Runner_Curvo.gdshader` (conservando
   albedo, normales, mapas de emisión nocturna y nombres de ranura para variantes).
2. **Subdivisión en profundidad.** Los tramos largos (`balasto_chunk`, `rail_tramo`,
   `catenaria_tramo`, `anden_tramo`, `muro_corredor`, `vagon_metro`, `rampa_tren`,
   `tunel_ferroviario`, `edificios`) llevan cortes suficientes en `+Y` de Blender
   (`-Z` de Godot) para curvarse suavemente con el horizonte sin quiebres.
3. **Ejes glTF -> Godot.** Con `export_yup=True`, `+Y` en Blender equivale a
   `-Z` (hacia el horizonte / frente del Sim) en Godot, y `+Z` en Blender a `+Y`
   (arriba).
4. **Sólidos cerrados y apliques en capas.** Evitar mallas abiertas que inviertan
   normales (`balasto_chunk`) y separar cuerpo base y apliques en capas para
   impedir z-fighting. Contorno de tinta (`next_pass`) solo en Sim, sus accesorios
   de power-up, guardia y perro K9.
5. **Presupuesto móvil.** Todo por debajo de `25 000` triángulos y `<= 8`
   materiales Principled BSDF por `.glb`, validado con `verificar_glb.py`.

## Skill de modelado y validador

El flujo completo está empaquetado como skill (`blender-modelado-3d`), disponible
en OpenCode (`~/.agents/skills/`) y en Antigravity (`~/.gemini/config/skills/`).
Incluye:

- `scripts/verificar_glb.py` — valida triángulos, materiales, atributos y caja
  envolvente del `.glb`. Devuelve código 1 si algo no cuadra.
- `scripts/plantilla_modelo.py` — esqueleto de script `bpy` con bisel acotado,
  capas de relieve, UVs, exportación y render de comprobación.

```bash
python3 ~/.agents/skills/blender-modelado-3d/scripts/verificar_glb.py \
    Modelos/Minijuego_Correr/vagon_metro.glb --esperado 2.28,2.98,13.5
```

Tras cambiar la skill, sincroniza las dos copias:
`~/.local/bin/sincronizar-skill-blender`.
