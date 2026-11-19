# Prompt para añadir actividades temporales — SIMS 0.33

**Cómo usarlo:** copia todo lo que hay a partir de la línea `PROMPT (pegar desde aquí)` y pégalo en el agente que vaya a implementar. Cambia o duplica las fichas de la sección 7 por las actividades que quieras. Si quieres que el agente proponga el diseño, borra esa sección y pídeselo explícitamente.

---

PROMPT (pegar desde aquí)

# Tarea: añadir nuevas actividades temporales al juego

Actúa como desarrollador senior de Godot 4.4 en el proyecto `/home/lur/sims-0.33` (SIMS 0.33, juego tipo Sims en español, resolución 720×1280 portrait). Añade las actividades temporales definidas al final de este prompt y déjalas completamente integradas: catálogo, botones, handlers, metadatos visuales, documentación y validación.

No pidas confirmación: lee el código, implementa, valida y entrégame un informe final.

## 1. Contexto obligatorio (léelo antes de tocar nada)

- `CLAUDE.md` — reglas del proyecto, autoloads y catálogo actual.
- `Scripts/Globales/Principales_Variables/Variables_Estaticas.gd` — `_Inicializar_Catalogo()` y array `Actividades` (pool aleatorio).
- `Escenas/Escena_Principal/Escena principal.tscn` — contenedores `Actividades/Elegir_Actividad/Tipos_De_Actividades/Temporales_Opciones/Progreso_Opciones` y `.../Necesidades_Basicas_Opciones`, más las conexiones `pressed` al final del archivo.
- `Scripts/Globales/Script_Principal.gd` — funciones `Actividad_Terminada_*`, constante `_SUBTITULOS_ACTIVIDADES` y `_Redisenar_Actividades()`.
- `Scripts/GUI/Escena_Principal/Estilos_UI.gd` — constante `ICONOS_BOTONES`.
- `Scripts/Logica/Escena_Principal/Actividades/Actividades.gd` — ejecución por minuto, pool aleatorio y prioridades.
- `Scripts/Logica/Escena_Principal/Actividades/Actividades_Necesidades_Basicas.gd` — semántica de los 5 efectos de necesidades.
- `Scripts/Logica/Escena_Principal/Actividades/Actividades_Habilidades.gd` — semántica de los 3 efectos de progreso.

## 2. Reglas duras (no las rompas)

1. GDScript válido para **Godot 4.4**. Nada de sintaxis de Godot 3.
2. No modifiques `Guardar_Variables_Dinamicas.gd` ni `Guardar_Variables_Estaticas.gd`: el catálogo se reconstruye solo en `Variables_Estaticas._ready()`. Las celdas de la matriz guardan referencias al objeto del catálogo y el save las convierte a `nombre`.
3. El campo `nombre` es la clave de guardado. Debe ser **único, ASCII, sin espacios ni acentos**, en formato `PascalCase_Con_Guiones_Bajos` (ej.: `Leer`, `Ordenar_La_Casa`).
4. Cada actividad nueva es `Actividad_Temporal` (prioridad P1 heredada). No crees subclases salvo que la ficha pida comportamiento especial por minuto (como `Actividad_Carrera` o `Actividad_Examen`).
5. `efectos_necesidades_basicas` debe tener **siempre 5 enteros**: `[salud_física, salud_mental, hambre, descanso, higiene]`.
6. `efectos_progreso` debe tener **siempre 3 enteros**: `[deporte, académico, manualidades]`.
7. No inventes costes ni ingresos de dinero: las actividades temporales no cobran ni pagan. Eso es exclusivo de trabajos, tienda, alquiler e inversión.
8. No cambies nombres, efectos, colores ni comportamiento de las actividades existentes.
9. No añadas una actividad al pool aleatorio (`Variables_Estaticas.Actividades`) si su ficha dice `Pool aleatorio: No`. Si dice `Sí`, comprueba que sus efectos no puedan matar al personaje mientras el jugador está ausente.
10. No dejes botones cortados: el contenedor mide 680×960 y cada tarjeta renderizada ocupa unos 78 px + 10 px de separación. Si la categoría se desborda, añade un `ScrollContainer` o reduce la separación; valida a 720×1280.
11. Usa solo iconos existentes en `Imagenes/UI/Iconos/` (nombres sin `.svg`). Si el icono deseado no existe, usa `circle-check`; no inventes rutas ni assets.
12. Mantén el estilo del proyecto: nombres en español, `PascalCase_Con_Guiones_Bajos`, comentarios breves solo donde aporten contexto.

## 3. Semántica de efectos (para no desbalancear)

Cada minuto de actividad aplica como máximo **1 punto** por necesidad o progreso, con probabilidad `1 / floor(frecuencia / |valor|)`. Las frecuencias son:

| Necesidad | Frecuencia |
|---|---|
| Salud física | 30 |
| Salud mental | 30 |
| Hambre | 12 |
| Descanso | 15 |
| Higiene | 20 |

Consecuencias:

- `0` = sin efecto.
- `1` = 1 punto cada 30/12/15/20 minutos según la necesidad.
- Un valor `>= frecuencia` = 1 punto **cada minuto** (se satura; no sirve poner 50).
- Signo positivo = sube la barra; negativo = la baja.
- Referencias actuales:
  - `Dormir`: `[1, 1, -1, 4, -1]`
  - `Comer`: `[-1, 2, 20, -1, -1]`
  - `Duchar`: `[1, 1, -1, -1, 20]`
  - `Ver_La_Television`: `[-1, 5, -1, 2, -1]`
  - `Estudiar`: `[-1, -2, -1, -2, -1]` + `[0, 4, 0]`
  - `Salir_A_Correr`: `[4, 2, -3, -3, -4]` + `[4, 0, 0]`
  - `Practicar_Manualidades`: `[-2, -1, -1, -2, -1]` + `[0, 0, 4]`
- Toda actividad nueva debe tener un **trade-off real**: no puede dominar a una existente en todos los ejes. Si sube mucho una barra, debe costar otra cosa (tiempo, hambre, descanso, higiene o salud).
- No uses valores enormes para "hacerla fuerte": saturan y rompen el balance. Rango recomendado: `-5..+8` en necesidades y `1..4` en progreso.

## 4. Pasos de implementación (en este orden)

### Paso 1 — Registrar en el catálogo

En `Variables_Estaticas._Inicializar_Catalogo()`, añade un bloque por actividad con el mismo estilo que las existentes:

```gdscript
var leer = Actividad_Temporal.new()
leer.nombre = "Leer"
leer.color = Color(0.30, 0.45, 0.75)
leer.efectos_necesidades_basicas = [0, 4, -1, -1, -1]
leer.efectos_progreso = [0, 3, 0]
Catalogo_Actividades["Leer"] = leer
```

Colócalo antes del bloque `Actividades = [...]`.

### Paso 2 — Pool aleatorio (solo si la ficha lo indica)

Si `Pool aleatorio: Sí`, añade la referencia al final del array:

```gdscript
Actividades = [
    # ... existentes ...
    Catalogo_Actividades["Leer"],
]
```

No toques `Crear_Actividad_Aleatoria_Debajo_De_30()` salvo que la ficha lo pida expresamente. Si `Pool aleatorio: No`, no añadas nada.

### Paso 3 — Botón en la escena

En `Escenas/Escena_Principal/Escena principal.tscn`, dentro del contenedor que indique la ficha (`Progreso_Opciones` o `Necesidades_Basicas_Opciones`), duplica **un bloque `Button` existente completo** y ajusta:

- `name` = nombre del nodo, sin acentos (ej.: `Leer`, `Ordenar_La_Casa`).
- `text` = `"EMOJI  NOMBRE EN MAYÚSCULAS"` (dos espacios entre emoji y texto, como el resto).
- Conserva `layout_mode = 2`, `size_flags_vertical = 3`, `theme_override_colors/font_color`, `theme_override_fonts/font`, `theme_override_font_sizes/font_size = 45` y los `StyleBox` existentes. El restilizado a tarjeta lo hace `_Redisenar_Actividades()` en runtime.

Al final del `.tscn`, añade la conexión:

```ini
[connection signal="pressed" from="Actividades/Elegir_Actividad/Tipos_De_Actividades/Temporales_Opciones/Progreso_Opciones/Leer" to="." method="Actividad_Terminada_Leer"]
```

La ruta debe coincidir exactamente con el contenedor y el nombre del nodo.

### Paso 4 — Handler en `Script_Principal.gd`

Junto a los `Actividad_Terminada_*` existentes, añade:

```gdscript
func Actividad_Terminada_Leer() -> void:
    Crear_Actividad("Leer")
```

El string debe ser **idéntico** a la clave del catálogo. `Crear_Actividad()` ya comprueba la prioridad P1/P2/P3 y abre el calendario.

### Paso 5 — Metadatos visuales

a) En `Script_Principal.gd`, añade una entrada a `_SUBTITULOS_ACTIVIDADES` con el **nombre del nodo** como clave:

```gdscript
"Leer": ["book-open", "Académico +3 · Salud mental +4", Color("#2563eb")],
```

Formato: `[icono_lucide, subtítulo corto, color_del_badge]`. El subtítulo debe resumir los efectos reales; no copies texto genérico.

b) En `Estilos_UI.gd`, añade una entrada a `ICONOS_BOTONES`:

```gdscript
"Leer": ["Leer", "book-open"],
```

Formato: `[título visible, icono_lucide]`.

Comprueba que el icono existe en `Imagenes/UI/Iconos/`. Iconos disponibles útiles: `book-open`, `brain`, `coffee`, `flame`, `house`, `leaf`, `newspaper`, `notebook-pen`, `party-popper`, `puzzle`, `sparkles`, `sun`, `users`, `utensils`, `utensils-crossed`, `dumbbell`.

### Paso 6 — Documentación

- Añade una fila por actividad a la tabla del catálogo en `CLAUDE.md` con: nombre, clase, `efectos_nb`, `efectos_prog` y notas.
- Crea `Funcionalidades/Actividades/Actividades_Temporales/Documentacion/ACTIVIDADES_TEMPORALES.md` con una tabla de todas las actividades temporales (existentes y nuevas): nombre, categoría, efectos, pool aleatorio y trade-off. Si la carpeta no existe, créala.
- No dupliques documentación obsoleta: enlaza al código como fuente de verdad.

### Paso 7 — Validación

Ejecuta estas comprobaciones y reporta el resultado:

1. **Nombres únicos:** busca cada `nombre` nuevo en `Variables_Estaticas.gd` y confirma que no colisiona con claves existentes.
2. **Longitudes correctas:** todas las actividades del catálogo tienen arrays de 5 y 3 enteros.
3. **Referencias del pool:** cada elemento de `Variables_Estaticas.Actividades` existe en `Catalogo_Actividades` y es una `Actividad`.
4. **Godot 4.4:** abre el proyecto y confirma que no hay errores de parser ni conexiones rotas (`pressed` → método inexistente).
5. **Prueba manual:** abre Actividades → temporales → categoría, comprueba que el botón aparece con icono y subtítulo; programa un bloque; avanza el tiempo; verifica que las barras cambian según los efectos.
6. **Prioridad:** intenta programar la actividad sobre un bloque de trabajo o examen; debe bloquearse con el diálogo existente.
7. **Guardado:** programa la actividad, guarda, cierra y vuelve a cargar; el bloque debe seguir ahí y ejecutarse.
8. **UI:** valida a 720×1280 que ningún botón queda cortado ni fuera del contenedor.
9. **Tests:** si GUT está disponible, añade tests siguiendo `Funcionalidades/Actividades/Jerarquia/Tests/test_jerarquia.gd` (catálogo válido, longitudes 5/3, nombres únicos, pool coherente). Si no está disponible, documenta las comprobaciones manuales en la documentación.

## 5. Criterios de aceptación

- [ ] Cada actividad existe en `Catalogo_Actividades` con `nombre`, `color` y arrays válidos.
- [ ] Cada actividad tiene su botón en el contenedor correcto y su conexión `pressed`.
- [ ] Cada botón tiene handler, entrada en `_SUBTITULOS_ACTIVIDADES` y entrada en `ICONOS_BOTONES`.
- [ ] El pool aleatorio solo contiene actividades marcadas con `Sí`.
- [ ] No se ha modificado el sistema de guardado ni actividades existentes.
- [ ] El juego abre sin errores y la actividad se puede programar, ejecutar y guardar.
- [ ] `CLAUDE.md` y la documentación de la funcionalidad están actualizados.
- [ ] El informe final indica archivos tocados, efectos exactos, pool y validaciones realizadas.

## 6. Formato del informe final

Devuelve una tabla como esta:

| Actividad | Categoría | Efectos NB | Efectos progreso | Pool | Archivos tocados |
|---|---|---|---|---|---|
| `Leer` | Progreso | `[0,4,-1,-1,-1]` | `[0,3,0]` | No | ... |

Y después: validaciones ejecutadas, problemas encontrados y cualquier decisión de diseño que hayas tenido que tomar.

## 7. Actividades a añadir

> Estas fichas son un ejemplo editable. Sustitúyelas por las tuyas manteniendo el mismo formato. Si una ficha no especifica un campo, decídelo tú siguiendo las reglas de balance y justifícalo en el informe.

### Actividad 1 — Leer

- **Nombre de catálogo:** `Leer`
- **Categoría:** Progreso
- **Emoji / texto del botón:** `📖  LEER`
- **Color:** `Color(0.30, 0.45, 0.75)`
- **Efectos necesidades:** `[0, 4, -1, -1, -1]`
- **Efectos progreso:** `[0, 3, 0]`
- **Pool aleatorio:** No
- **Icono:** `book-open`
- **Subtítulo:** `Académico +3 · Salud mental +4`
- **Trade-off:** menos académico que Estudiar, pero recupera salud mental en vez de castigarla.

### Actividad 2 — Cocinar

- **Nombre de catálogo:** `Cocinar`
- **Categoría:** Necesidades
- **Emoji / texto del botón:** `🍳  COCINAR`
- **Color:** `Color(0.80, 0.50, 0.20)`
- **Efectos necesidades:** `[-1, 2, 6, -2, -1]`
- **Efectos progreso:** `[0, 0, 3]`
- **Pool aleatorio:** No
- **Icono:** `utensils`
- **Subtítulo:** `Hambre +6 · Manualidades +3`
- **Trade-off:** sacia menos que Comer y cuesta descanso, pero entrena manualidades.

### Actividad 3 — Meditar

- **Nombre de catálogo:** `Meditar`
- **Categoría:** Necesidades
- **Emoji / texto del botón:** `🧘  MEDITAR`
- **Color:** `Color(0.45, 0.35, 0.70)`
- **Efectos necesidades:** `[0, 6, -2, -1, -1]`
- **Efectos progreso:** `[0, 0, 0]`
- **Pool aleatorio:** No
- **Icono:** `brain`
- **Subtítulo:** `Salud mental +6 · Cuesta hambre`
- **Trade-off:** más salud mental que Ver la TV, pero no da descanso y gasta hambre.

### Actividad 4 — Ordenar la casa

- **Nombre de catálogo:** `Ordenar_La_Casa`
- **Categoría:** Necesidades
- **Emoji / texto del botón:** `🧹  ORDENAR LA CASA`
- **Color:** `Color(0.40, 0.65, 0.55)`
- **Efectos necesidades:** `[1, 2, -1, -2, 8]`
- **Efectos progreso:** `[0, 0, 2]`
- **Pool aleatorio:** No
- **Icono:** `house`
- **Subtítulo:** `Higiene +8 · Manualidades +2`
- **Trade-off:** mucha menos higiene que Duchar y cuesta descanso, pero sube manualidades y salud mental.

---

## Plantilla vacía (para añadir más)

```markdown
### Actividad N — <Nombre visible>

- **Nombre de catálogo:** `<Nombre_En_Catalogo>`
- **Categoría:** `<Progreso | Necesidades>`
- **Emoji / texto del botón:** `<emoji>  <TEXTO>`
- **Color:** `Color(r, g, b)`
- **Efectos necesidades:** `[fís, men, ham, des, hig]`
- **Efectos progreso:** `[dep, aca, man]`
- **Pool aleatorio:** `<Sí | No>`
- **Icono:** `<icono_existente>`
- **Subtítulo:** `<resumen de efectos>`
- **Trade-off:** `<qué pierde frente a las actividades existentes>`
```
