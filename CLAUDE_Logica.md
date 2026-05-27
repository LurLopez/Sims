# CLAUDE.md — Modo: Lógica de Juego

**Para implementar scripts, lógica, sistemas de juego, economia, timing, etc.**

---

## Regla fundamental: compatibilidad con Godot 4.4

Todos los cambios en `.gd` deben ser **GDScript válido para Godot 4.4**.
- No usar sintaxis de Godot 3 ni de otros lenguajes.
- Los scripts se editan en VS Code pero se ejecutan desde Godot 4.4.
- Autoloads se usan directamente como globales sin importar: `Variables_Dinamicas.Progreso`, `Funciones_Globales.Devolver_Dia(n)`.
- Rutas: `res://` relativo a `JOKUA/`.
- `class_name` registra globalmente (sin importar).
- **Comparación de celdas:** siempre `celda is String and celda == "valor"` para evitar errores de tipo.

---

## Autoloads (Singletons)

| Nombre | Archivo | Propósito |
|---|---|---|
| `Variables_Dinamicas` | `Scripts/Globales/Principales_Variables/Variables_Dinamicas.gd` | Estado del juego: Dinero, Necesidades_Basicas, Progreso, Matriz, timing |
| `Variables_Estaticas` | `Scripts/Globales/Principales_Variables/Variables_Estaticas.gd` | Inmutables: Habilidades, Personalidad, Catalogo_Actividades |
| `Guardar_Variables_Dinamicas` | `Scripts/Otro/Guardar/Guardar_Variables_Dinamicas.gd` | Save/Load de estado dinámico |
| `Guardar_Variables_Estaticas` | `Scripts/Otro/Guardar/Guardar_Variables_Estaticas.gd` | Save/Load de constantes |
| `Funciones_Globales` | `Scripts/Globales/Funciones_Globales.gd` | Utilidades: timing, matriz, logging |
| `Trabajo` | `Scripts/Logica/Escena_Principal/Actividades/Trabajo/Trabajo.gd` | Sistema de trabajos |
| `Actividades` | `Scripts/Logica/Escena_Principal/Actividades/Actividades.gd` | Ejecución de actividades, timing |
| `Actividades_Habilidades` | `Scripts/Logica/Escena_Principal/Actividades/Actividades_Habilidades.gd` | Sistema de progreso |
| `Actividades_Necesidades_Basicas` | `Scripts/Logica/Escena_Principal/Actividades/Actividades_Necesidades_Basicas.gd` | Sistema de necesidades |
| `Gestionar_Visibilidad` | `Scripts/GUI/Escena_Principal/Gestionar_Visibilidad.gd` | Control de visibilidad de pantallas |

---

## La Matriz Principal

- **Dimensiones:** 1440 filas (minutos del día) × 574 columnas (días totales).
- **Contenido:** strings (`""`, `"Actividad_Aleatoria"`) u objetos `Actividad`.
- **Índices:**
  - Fila: `hora * 60 + minuto` (0–1439)
  - Columna: `semana * 7 + dia_semana` (0–573)
- **Variables de posición:**
  - `Minute_Day` = columna actual
  - `Minute_Minute` = fila actual
  - `Minute` = minuto Unix absoluto

---

## Necesidades Básicas (5 valores, rango 1–100)

| Índice | Nombre | Cambio base |
|---|---|---|
| 0 | Salud Física | ~30 min |
| 1 | Salud Mental | ~30 min |
| 2 | Hambre | ~12 min |
| 3 | Descanso | ~15 min |
| 4 | Higiene | ~20 min |

**Mecánica:** `Ejecutar_Actividad_Necesidades_Basicas(por_cuanto, indice, frecuencia)` calcula probabilidad 1/`floor(frecuencia/abs(por_cuanto))` de cambio ±1/min.

**Penalización:** Si `En_La_Calle == true` O `Dinero < 0`, necesidades capadas a máximo 20.

---

## Progreso (3 valores, rango 1–100)

| Índice | Nombre |
|---|---|
| 0 | Deporte |
| 1 | Académico |
| 2 | Manualidades |

**Mecánica:** Fórmula exponencial con potencias basadas en progreso actual + suma de habilidades innatas. Más lento conforme sube.

---

## Economia

### Phase 1: ✅ DONE
- `Dinero` (float, empieza 1000)
- Trabajos: `Actividad_Fija_Trabajo` (horas, salario, requisitos de progreso)
- Auto-pago al final de turno
- Cancelar trabajo con confirmación

### Phase 2: ✅ DONE
- Alquiler timer-based: 200€ cada 7 días desde último pago
- `Ultima_Fecha_Alquiler` = minuto absoluto del último pago
- `En_La_Calle` = true si no puede pagar
- Transición suave: botón "En alquiler"/"En la calle"

### Phase 3: ⏳ PENDING
- Añadir Carpintero (25€/h, req Manualidades ≥30) y Científico (50€/h, req Académico ≥60)
- Validar requisitos antes de contratar
- Costos por actividad (Comer = -5€)

### Phase 4+: post-MVP
- Tienda (items con multiplicadores)
- Eventos aleatorios, premios por hitos
- Facturas recurrentes

**Referencia completa:** [Economia.md](Economia.md)

---

## Flujo de Actividades

### Tick Principal (`Script_Principal._process`)
1. Calcula `minuto_actual = floor(unix_time / 60)`.
2. Si `minuto_actual > Minute`: llama `Actividades.Actualizar_Horario(minuto_actual)`.
3. Guarda variables dinámicas.

### `Actividades.Actualizar_Horario(minuto)`
Por cada minuto [Minute, minuto_actual]:
1. Lee celda de matriz.
2. Si vacía (`""`) → marca `"Actividad_Aleatoria"` y ejecuta aleatoria.
3. Si `"Actividad_Aleatoria"` → ejecuta aleatoria.
4. Si objeto `Actividad` → ejecuta esa actividad.
5. Avanza índices (Minute_Minute, Minute_Day, Minute).
6. Al terminar: `Funciones_Globales.Guardar_Matriz()` (log).

### `Actividades.Ejecutar_Actividad(actividad)`
```gdscript
Actividades_Necesidades_Basicas.Ejecutar_Actividad_Necesidades_Basicas_Array(actividad.efectos_necesidades_basicas)
Actividades_Habilidades.Ejecutar_Actividad_Progreso_Array(actividad.efectos_progreso)
# Si es Actividad_Fija_Trabajo y es la última hora: paga salario
```

### Alquiler (`Actividades.Cobrar_Alquiler`)
- Condición: `(Minute - Ultima_Fecha_Alquiler) >= 7*1440`.
- Si `Dinero >= 200`: resta, actualiza `Ultima_Fecha_Alquiler = Minute`.
- Si `Dinero < 200`: llama `Ir_A_La_Calle()` (no cobra, `En_La_Calle=true`, `Ultima_Fecha_Alquiler=-1`).

---

## Convenciones

- Funciones/variables: `PascalCase_Con_Guiones`.
- Días: Lunes=0, ..., Domingo=6.
- Resolución: 720×1280 (portrait móvil).

---

## Bugs Conocidos

1. `Necesidades_Basicas_GUI.Actualizar_Necesidades_Basicas` llama `Inicializar` cada frame (ineficiente).
2. `Guardar_Variables_Dinamicas.save_game` convierte matriz entera cada minuto (lento en móvil).
3. `Funciones_Globales.Guardar_Matriz` escribe log cada minuto (desactivar en producción).
4. `Trabajo.gd` tiene `Trabajar_De_Carpintero/Cientifico` con referencias inexistentes en el catálogo.
5. Duplicación: `ActividadesBloqueGUI.gd` y `Consultar_Y_Eliminar_Actividades.gd` comparten lógica.

---

## Archivos Clave por Subsistema

**Economia:** `Actividades.gd`, `Trabajo.gd`, `Variables_Dinamicas.gd`, `Script_Principal.gd`

**Progreso/Habilidades:** `Actividades_Habilidades.gd`, `Variables_Estaticas.gd`

**Necesidades Básicas:** `Actividades_Necesidades_Basicas.gd`, `Variables_Dinamicas.gd`

**Timing:** `Script_Principal.gd`, `Funciones_Globales.gd`, `Actividades.gd`

---

## NO toques (usa otra conversación)

- Escenas `.tscn` → conversación de **Diseño**.
- Cambios visuales (colores, posiciones, nodos) → conversación de **Diseño**.
