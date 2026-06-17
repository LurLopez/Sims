# CLAUDE.md — Modo: Aplicar Diseño Figma a Godot

**Tu tarea: leer un proyecto exportado de Figma Make y aplicar sus cambios de estilo (colores, bordes, tamaños) a las escenas Godot.**

No tocas lógica, no tocas `.gd`. Solo editas `.tscn` (y `.tres` si los hay).

---

## Flujo de trabajo

Cuando el usuario diga "aplica los cambios de figma/X" (o similar), sigue estos pasos en orden.

---

### Paso 1 — Leer el diseño de Figma Make

El proyecto descargado de Figma Make tiene esta estructura:
```
figma/<nombre>/
  src/app/App.tsx          ← FUENTE PRINCIPAL
  src/app/components/      ← componentes adicionales (revisar si hay colores ahí)
  src/styles/globals.css   ← variables CSS (secundario)
```

Lee `figma/<nombre>/src/app/App.tsx`. Extrae **dos bloques**:

**Bloque A — Comentario `GODOT 4 NODE MAPPING`** (en la parte superior del archivo):
```
Root               → Control ...
TopBar             → HBoxContainer
                       StyleBoxFlat bg = #2C2C2C
  btn_perfil       → Button
                       StyleBoxFlat bg=#3A3A3A, border=#4A4A4A 1px, r=8
...
CSS → Godot StyleBoxFlat color mapping:
  --bg-base:     #1A1A1A  → bg_color of main Control
  --bg-surface:  #2C2C2C  → bg_color of HBoxContainer bars
  ...
```

**Bloque B — Inline styles en el JSX**:
Busca `style={{ background: "...", color: "...", borderRadius: ..., height: ..., fontSize: ... }}`.
Estos complementan o confirman los valores del Bloque A.

Con ambos bloques construye una tabla:

| Elemento UI | Propiedad Godot | Valor nuevo (hex o px) |
|---|---|---|
| TopBar bg | bg_color StyleBox_Top_Bar | #2C2C2C |
| top Button bg | bg_color StyleBox_Button_Normal | #3A3A3A |
| top Button border | border_color, border_width 1px | #4A4A4A |
| top Button radius | corner_radius_* | 8 |
| BottomNav bg | bg_color [StyleBox de barra abajo] | #2C2C2C |
| nav card bg | bg_color [StyleBox de nav card] | #1565C0 |
| nav card radius | corner_radius_* | 16 |
| money label color | font_color / theme_override | #FFD700 |
| main content bg | bg_color Control principal | #1A1A1A |

---

### Paso 2 — Leer la escena Godot objetivo

Identifica el `.tscn` correcto según el nombre del proyecto Figma:

| Carpeta Figma | Escena Godot |
|---|---|
| `figma/escena_principal/` | `Escenas/Escena_Principal/Escena principal.tscn` |
| `figma/menu/` | `Escenas/Menu/Menu.tscn` |
| Otro | Pregunta al usuario |

Lee el `.tscn` completo. Extrae y lista:
1. Todos los `[sub_resource type="StyleBoxFlat" id="..."]` con sus propiedades actuales.
2. Los nodos con `custom_minimum_size`, `theme_override_colors/*`, `theme_override_font_sizes/*`.

---

### Paso 3 — Mapear elementos → StyleBoxFlat IDs

Relaciona la tabla del Paso 1 con los IDs reales del .tscn por coincidencia semántica:

| Elemento App.tsx | Busca en .tscn |
|---|---|
| TopBar / top bar background | `StyleBox_Top_Bar` o similar |
| top buttons (Perfil/Tienda/Horario) | `StyleBox_Button_Normal`, `StyleBox_Button_Hover` |
| BottomNav background | StyleBoxFlat de la barra inferior |
| nav card buttons | StyleBoxFlat de los botones de la barra inferior |
| Barra de progreso (fondo) | `StyleBox_ProgressBar_*` o similar |

Si el nombre del StyleBoxFlat no coincide claramente, lee el contexto del nodo que lo usa en el .tscn (busca `custom_styles/normal`, `custom_styles/hover`, `theme_override_styles/panel`).

Si hay ambigüedad entre 2+ candidatos → lista las opciones y pregunta al usuario antes de editar.

---

### Paso 4 — Convertir hex a Godot Color

**Fórmula:**
```
#RRGGBB → Color(RR/255, GG/255, BB/255, 1)
```
Redondea a **2 decimales**.

**Tabla de conversiones frecuentes:**

| Hex | Godot Color |
|---|---|
| `#1A1A1A` | `Color(0.10, 0.10, 0.10, 1)` |
| `#2C2C2C` | `Color(0.17, 0.17, 0.17, 1)` |
| `#3A3A3A` | `Color(0.23, 0.23, 0.23, 1)` |
| `#4A4A4A` | `Color(0.29, 0.29, 0.29, 1)` |
| `#1565C0` | `Color(0.08, 0.40, 0.75, 1)` |
| `#1976D2` | `Color(0.10, 0.46, 0.82, 1)` |
| `#0D47A1` | `Color(0.05, 0.28, 0.63, 1)` |
| `#64B5F6` | `Color(0.39, 0.71, 0.96, 1)` |
| `#FFD700` | `Color(1.00, 0.84, 0.00, 1)` |
| `#EEEEEE` | `Color(0.93, 0.93, 0.93, 1)` |
| `#4CAF50` | `Color(0.30, 0.69, 0.31, 1)` |
| `#FF9800` | `Color(1.00, 0.60, 0.00, 1)` |
| `#F44336` | `Color(0.96, 0.26, 0.21, 1)` |

Si el diseño usa `rgba()` con alpha < 1, úsalo como 4º valor. Si no hay alpha explícito, **conserva el alpha que ya tenía el StyleBoxFlat en el .tscn**.

---

### Paso 5 — Aplicar cambios

Edita el `.tscn` con los cambios identificados:

**Propiedades que puedes cambiar directamente** (no requieren confirmación):
- `bg_color` en StyleBoxFlat
- `border_color` en StyleBoxFlat
- `border_width_left/top/right/bottom` en StyleBoxFlat
- `corner_radius_top_left/top_right/bottom_right/bottom_left` en StyleBoxFlat
- `custom_minimum_size` en nodos de layout si el diseño especifica altura/anchura diferente
- `theme_override_colors/font_color` en Label/Button si el diseño especifica color de texto distinto
- `theme_override_font_sizes/font_size` en Label/Button si el diseño especifica tamaño de fuente distinto

**Propiedades que SIEMPRE requieren confirmación del usuario antes de tocar:**
- Añadir o quitar nodos del árbol
- Cambiar el script de un nodo
- Cambiar texturas (`ext_resource` de tipo Texture2D)
- Cambiar fuentes (`ext_resource` de tipo FontFile)
- Modificar anclas o posiciones absolutas
- Añadir nuevos `sub_resource` (StyleBoxFlat, LabelSettings, etc.)

---

### Paso 6 — Informe final

Cuando termines, muestra un resumen de los cambios aplicados:

```
Cambios aplicados en Escenas/Escena_Principal/Escena principal.tscn:
  StyleBox_Top_Bar       bg_color: Color(0.05, 0.07, 0.12, 0.94) → Color(0.17, 0.17, 0.17, 1)
  StyleBox_Button_Normal bg_color: Color(0.10, 0.55, 0.75, 1)    → Color(0.23, 0.23, 0.23, 1)
  ...
```

Y si hubo algo que no pudiste aplicar (ambigüedad, falta de StyleBoxFlat, etc.), explícalo brevemente.

---

## Qué NO hacer en esta conversación

- No toques archivos `.gd`.
- No cambies lógica de gameplay ni señales.
- No refactorices el árbol de nodos.
- No añadas comentarios al `.tscn`.
- No crees nuevos sub_resources si no existían antes.
- No hagas `git commit` — el usuario lo hace manualmente.
