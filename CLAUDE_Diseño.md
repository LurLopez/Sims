# CLAUDE.md — Modo: Diseño UI/UX

**Para cambiar escenas, nodos, colores, posiciones, botones, layouts, visual polish, etc.**

---

## Importante: Estructura de Nodos

La escena principal es **compleja con muchos nodos anidados**. Para entenderla bien:

1. **Referencia rápida:** [Documentacion/Estructura_Nodos.txt](Documentacion/Estructura_Nodos.txt)
   - Árbol completo expandido (legible, sin tokens caros).
   - Úsalo para navegar, no para describir cambios (es solo consulta).

2. **Para hacer cambios:** 
   - Arrastra la escena `.tscn` a la conversación o muestra screenshots de la parte que tocas.
   - O describe el cambio en natural (ej: "en la pantalla de Elegir Actividad, quiero que el menú sea scroll horizontal en vez de vertical").

3. **Herramienta útil:** Usa Stitch (que ya conocemos) para mockups visuales antes de implementar en Godot.

---

## Resolución y Viewport

- **Objetivo:** 720×1280 (portrait, móvil Android).
- **Margen seguro:** Considera que el bottom bar (`Barra_Abajo`) es siempre visible → diseña contenido para ~1050px de altura útil.
- **CanvasLayer:** Se usa para UI superpuesta (layers, z-index).

---

## Componentes Visuales Clave

### Barras de Progreso
- **Necesidades Básicas:** 5 barras (Salud Física, Mental, Hambre, Descanso, Higiene).
  - Verde ≥50, Naranja 30–49, Rojo <30.
  - Update cada frame en `_process`.

- **Progreso (Habilidades):** 3 barras (Deporte, Académico, Manualidades).
  - Mismos colores.
  - Labels con nombres.

- **Habilidades Innatas:** 5 barras (display, no editables).

### Labels
- **Dinero:** Top-right, amarillo brillante, borde negro, desplaza izquierda si >3 dígitos.
- **Textos:** Labels para nombres de necesidades, habilidades, progreso.

### Botones
- **Barra abajo:** 4 botones (Habilidades, Progreso, Dinero, Necesidades).
- **Menú de actividades:** Árbol de botones (Temporales → Necesidades/Progreso; Fijas → Trabajo).
- **Trabajo:** 3 opciones (Comida Rápida, Carpintero, Científico).
- **Navegación:** Flechas arriba/abajo en menús scrolleables.

### Calendario Semanal
- **Bloques de 5 minutos:** 288 bloques × 7 días.
- **Colores:**
  - Azul: bloques pasados.
  - Verde: libre (sin actividad).
  - Rojo: ocupado (actividad programada).
- **Interactividad:** Al pulsar, muestra "Ocupar" o "Eliminar" según estado.
- **Mini-versión en Seleccionar_Horario:** 1 hora de resolución, blink para rango seleccionado.

### Seleccionar Horario
- **Layout vertical:**
  - Título.
  - Mini-calendario (scroll).
  - Panel "Inicio" (3 pickers: Día/Hora/Minuto).
  - Panel "Final" (3 pickers: Día/Hora/Minuto).
  - Botones "Crear Actividad" / "Cancelar".
- **Pickers:** Botón arriba, display, botón abajo (patrón repetido).

---

## Colores de Referencia

(Del proyecto, ajusta según CLAUDDE.md principal):
- **Verde:** actividades libres, valores altos (≥50).
- **Naranja:** valores medios (30–49).
- **Rojo:** valores bajos (<30), bloques ocupados, errores.
- **Azul:** bloques pasados.
- **Amarillo:** dinero (label).
- **Negro:** fondos, bordes.

---

## Convenciones de Nombres (Godot)

- Nodos: `PascalCase_Con_Guiones` (ej: `Dinero_Label`, `Barra_Abajo`, `Progreso_Barra`).
- Recursos (`.tres`, `.tscn`): mismo patrón.
- Mantén la coherencia visual: si un label se llama `Salud_Fisica_Barra`, el label de texto sea `Salud_Fisica_Texto`.

---

## Estructura de Pantallas

Gestionar_Visibilidad controla visibilidad recursiva:
- `Quitar_Todo(raiz)` → solo Barra_Abajo, Fondo, Moneda visibles.
- `Visibilizar_Elegir_Actividad()` → menú de actividades.
- `Visibilizar_Horario_Semanal()` → calendario.
- `Visibilizar_Seleccionar_Horario()` → reloj + pickers.

---

## Próximas Mejoras de UX

(Del documento de proyectos):
1. **Animaciones de dinero:** "+80€" (verde) / "-200€" (rojo) flotando al cobrar/perder.
2. **Indicador de próximo alquiler:** "Próximo pago en 5 días".
3. **Polish de transiciones:** fade/slide entre pantallas.
4. **Responsive ajustes:** labels con números largos, scroll en menús densos.

---

## NO toques (usa otra conversación)

- Scripts `.gd` → conversación de **Lógica**.
- Timing, economia, progreso, necesidades → conversación de **Lógica**.
- Save/load → conversación de **Lógica**.

---

## Herramientas Útiles

- **Stitch:** Para mockups HTML antes de implementar en Godot.
- **Godot Editor:** Para preview en tiempo real (viewport 720×1280).
- **VS Code + Extensión Godot:** Para editar `.tscn` textualmente (avanzado, no necesario).

---

## Tips para Cambios Grandes

1. **Screenshot → Descripción:** Toma screenshot de lo que ves vs. lo que quieres.
2. **Referencia al árbol:** "En el nodo Actividades/Elegir_Actividad/Tipos_De_Actividades, quiero..."
3. **Mockup → Código:** Si es visual complejo, crea mockup en Stitch primero.
4. **Test en Godot:** Después de cambios, abre el editor y verifica aspectos (posiciones, colores, interactividad).
