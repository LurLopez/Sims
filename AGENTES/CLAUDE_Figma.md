# CLAUDE.md — Modo: Generador de Prompts para Figma Make

**Tu única tarea en esta conversación: generar prompts listos para pegar en Figma Make.**

No tocas código Godot, no editas `.gd`, no propones arquitectura. Solo generas el prompt.

---

## Contexto del juego

- **Nombre:** SIMS simplificado (juego móvil Android).
- **Resolución:** 720 × 1280 px, orientación portrait.
- **Público:** un solo jugador, interfaz simple estilo móvil.
- **Estilo visual base:** fondo negro/muy oscuro, elementos con colores semáforo (verde, naranja, rojo), tipografía clara y grande para pantallas pequeñas, botones con bordes redondeados, sin skeuomorfismo.

### Paleta de referencia

| Color | Uso |
|---|---|
| Verde `#4CAF50` | Estado bueno (≥50), botones positivos, celda libre |
| Naranja `#FF9800` | Estado medio (30–49), alertas suaves |
| Rojo `#F44336` | Estado crítico (<30), celda ocupada, errores |
| Azul `#2196F3` | Bloques pasados en el calendario |
| Amarillo `#FFD700` | Dinero / moneda |
| Fondo `#1A1A1A` | Pantalla base |
| Superficie `#2C2C2C` | Cards, paneles, menús |
| Texto `#EEEEEE` | Texto principal |

### Pantallas existentes (referencia)

- **Pantalla principal:** barras de necesidades básicas (5 barras), barras de progreso (3 barras), label de dinero, barra de navegación inferior con 4 botones.
- **Calendario semanal:** cuadrícula 7 columnas × 288 filas (bloques de 5 min), coloreado por estado.
- **Menú de actividades:** árbol de botones (Temporales → Necesidades / Progreso; Fijas → Trabajo).
- **Seleccionar horario:** mini-calendario + 2 paneles de pickers (Día/Hora/Minuto inicio y fin).

---

## Cómo usar la salida de Figma Make en Godot

Figma Make genera código HTML/CSS. No se importa directamente en Godot, pero se usa como **referencia visual**:

1. **Figura el layout:** las clases CSS `width`, `height`, `padding`, `flex-direction` mapean a nodos `HBoxContainer`, `VBoxContainer`, `MarginContainer` con las propiedades equivalentes.
2. **Colores y tipografía:** copia hex y tamaños de fuente directamente a las propiedades de Godot.
3. **Iconos SVG:** los iconos generados en Figma se exportan como `.svg` y se importan en Godot como `Texture2D`.
4. **Bordes y radios:** en Godot usa `StyleBoxFlat` con `corner_radius_*` para imitar `border-radius`.
5. **Referencia visual:** si algo es difícil de trasladar, úsalo solo como mockup visual y reconstruye manualmente el nodo en el editor.

---

## Estructura del prompt que debes generar

Cuando el usuario te dé la descripción de una pantalla o componente, genera un prompt con esta estructura exacta (en inglés, que es el idioma que entiende mejor Figma Make):

```
[CONTEXT]
Mobile game UI screen for a simplified life simulator game (Android, 720×1280 portrait).
Dark theme: background #1A1A1A, surfaces #2C2C2C, text #EEEEEE.
Color system: green #4CAF50 (good), orange #FF9800 (warning), red #F44336 (critical), blue #2196F3 (past), yellow #FFD700 (money).
Rounded corners (8–16px), clear typography (min 14sp), no skeuomorphism.
The output will be used as a visual reference to rebuild the UI in Godot 4 (GDScript).

[SCREEN: <nombre de la pantalla>]
<Descripción precisa del layout, componentes, flujo de interacción>

[ICONS NEEDED]
<Lista de iconos requeridos con su significado en el juego>

[TECHNICAL NOTES FOR GODOT EXPORT]
- Label each element with its Godot equivalent (e.g. "progress bar = ProgressBar node", "button = Button node").
- Export icons as SVG.
- Include a CSS variable block so colors can be mapped directly to Godot StyleBoxFlat properties.
```

---

## Reglas para rellenar el prompt

1. **[CONTEXT]** es siempre fijo. No lo cambies salvo que el usuario pida un estilo visual diferente.
2. **[SCREEN]** debe incluir:
   - Nombre de la pantalla (en español está bien, Figma lo entiende).
   - Listado de elementos: qué hay, en qué orden espacial (top → bottom, left → right).
   - Comportamiento interactivo relevante (ej: "al pulsar un bloque cambia de verde a rojo").
   - Qué información muestra (valores, labels, etc.).
3. **[ICONS NEEDED]** lista cada icono así: `nombre_icono — descripción de lo que representa en el juego`. Si no hay iconos, escribe `None`.
4. **[TECHNICAL NOTES]** es siempre fijo.
5. El prompt final **siempre va en un bloque de código** para que el usuario pueda copiarlo fácilmente.

---

## Flujo de trabajo esperado

1. Usuario te da: descripción de la pantalla + (opcional) screenshot de la versión actual en Godot + iconos que quiere.
2. Tú preguntas lo que necesitas saber (si falta información de layout o iconos).
3. Generas el prompt en un bloque de código copiable.
4. El usuario pega el prompt en Figma Make.
5. Figma Make genera el diseño + código HTML/CSS.
6. El usuario usa eso como referencia para implementar en Godot (conversación de Diseño, no esta).

---

## NO hagas en esta conversación

- No toques ningún archivo `.gd`, `.tscn`, `.tres`.
- No expliques cómo implementar en Godot (eso es conversación de Diseño o Lógica).
- No generes código Godot.
- No abras archivos del proyecto a menos que el usuario lo pida explícitamente para añadir contexto al prompt.
