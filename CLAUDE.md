# CLAUDE.md — Contexto del proyecto SIMS

## Regla fundamental: compatibilidad con Godot
Todos los cambios en los archivos `.gd` deben ser **GDScript válido para Godot 4.4**.
- No usar sintaxis de otros lenguajes ni de Godot 3.
- Los scripts se editan desde VS Code, pero se ejecutan desde el editor/runtime de Godot.
- Los nombres de autoloads (singletons) se usan directamente como globales: `Variables_Dinamicas.Progreso`, `Funciones_Globales.Devolver_Dia(n)`, etc. No importar nada, no usar `get_node` para acceder a ellos.
- Las rutas de recursos usan `res://` (relativo a la carpeta `JOKUA/`).

## Autoloads registrados en project.godot
| Nombre global | Archivo |
|---|---|
| `Variables_Dinamicas` | `Scripts/Globales/Principales_Variables/Variables_Dinamicas.gd` |
| `Variables_Estaticas` | `Scripts/Globales/Principales_Variables/Variables_Estaticas.gd` |
| `Guardar_Variables_Dinamicas` | `Scripts/Otro/Guardar/Guardar_Variables_Dinamicas.gd` |
| `Guardar_Variables_Estaticas` | `Scripts/Otro/Guardar/Guardar_Variables_Estaticas.gd` |
| `Funciones_Globales` | `Scripts/Globales/Funciones_Globales.gd` |
| `Trabajo` | `Scripts/Logica/Escena_Principal/Actividades/Trabajo/Trabajo.gd` |
| `Actividades` | `Scripts/Logica/Escena_Principal/Actividades/Actividades.gd` |
| `Actividades_Habilidades` | `Scripts/Logica/Escena_Principal/Actividades/Actividades_Habilidades.gd` |
| `Actividades_Necesidades_Basicas` | `Scripts/Logica/Escena_Principal/Actividades/Actividades_Necesidades_Basicas.gd` |
| `Gestionar_Visibilidad` | `Scripts/GUI/Escena_Principal/Gestionar_Visibilidad.gd` |

## Descripción del juego
Juego tipo SIMS simplificado para móvil (Android). El personaje empieza con 18 años y puede vivir hasta ~80-90 años de edad en el juego.

### Tiempo
- **1 día real = 1 día en el juego.** La duración de las actividades es realista (dormir 8h = 8h reales).
- **1 semana real = 1 año en el juego.**
- La partida completa dura unas 60 semanas reales (60 años de juego, de los 18 a los ~80).
- El tiempo se mide en minutos Unix: `Variables_Dinamicas.Minute` = último minuto Unix procesado.

### La Matriz principal
La estructura de datos central es `Variables_Dinamicas.Matriz_Jugador`, una matriz 2D:
- **Filas (1440):** minutos de un día (0 = medianoche, 1439 = 23:59).
- **Columnas (574):** días totales del juego (7 días × 82 años ≈ 574).
- Cada celda contiene un objeto `Actividad` (o subclase) o el string `"Actividad_Aleatoria"`.
- Columna → índice de día absoluto. `semana * 7 + dia_semana` da la columna.
- Fila → `hora * 60 + minuto`.

### Necesidades básicas
Array de 5 valores (0-100) en `Variables_Dinamicas.Necesidades_Basicas`:
- `[0]` Salud física
- `[1]` Salud mental
- `[2]` Hambre
- `[3]` Descanso
- `[4]` Higiene

### Progreso (habilidades aprendidas)
Array de 3 valores (0-100) en `Variables_Dinamicas.Progreso`:
- `[0]` Deporte
- `[1]` Académico
- `[2]` Manualidades

### Habilidades innatas del personaje
Array de 6 valores (1-100) en `Variables_Estaticas.Habilidades`, generados aleatoriamente al inicio:
- `[0]` Deporte · `[1]` Inteligencia · `[2]` Destreza manual
- `[3]` Memoria · `[4]` Liderazgo · `[5]` Paciencia

### Personalidad
`Variables_Estaticas.Personalidad` — string con uno de tres valores:
- `"Trabajador_Compulsivo"` → tiende a estudiar en tiempo libre
- `"Deportista"` → tiende a salir a correr
- `"Culo_Del_Sofa"` → tiende a ver la televisión

### Actividades disponibles
Temporales (el jugador las programa manualmente con hora inicio/fin):
- Necesidades básicas: `Duchar`, `Dormir`, `Comer`, `Ver_La_Television`
- Progreso: `Estudiar`, `Salir_A_Correr`, `Practicar_Manualidades`

Fijas (se repiten cada semana, días laborables):
- `Trabajar_En_Comida_Rapida` (8:00–16:00)

### Jerarquía de clases de actividades
```
Actividad (Resource)
├── Actividad_Temporal
│   ├── Actividad_Temporal_Necesidades_Basicas
│   │   ├── Actividad_Temporal_Necesidades_Basicas_Comer
│   │   ├── Actividad_Temporal_Necesidades_Basicas_Dormir
│   │   ├── Actividad_Temporal_Necesidades_Basicas_Duchar
│   │   └── Actividad_Temporal_Necesidades_Basicas_Ver_La_Television
│   └── Actividad_Temporal_Progreso
│       ├── Actividad_Temporal_Progreso_Estudiar
│       ├── Actividad_Temporal_Progreso_Salir_A_Correr
│       └── Actividad_Temporal_Progreso_Practicar_Manualidades
├── Actividad_Fija
│   └── Actividad_Fija_Trabajo
│       └── Actividad_Fija_Trabajo_Comida_Rapida
└── Libre  (celda vacía / sin actividad programada)
```

## Bugs conocidos (pendientes de corregir)

1. **`Actividades.gd:107`** — `Matriz_Jugador[min][dia].nombre_actividad` crash si la celda es un string en vez de un objeto `Actividad`.
2. **`Actividades.gd:109`** — `Actualizar_Horario` siempre ejecuta una actividad aleatoria, ignorando lo que el jugador ha programado. Las actividades programadas nunca tienen efecto.
3. **`Actividades_Habilidades.gd:25`** — `max_ajustado` se calcula pero se pasa `max` (sin ajustar) a la función aleatoria. La progresión de habilidades es incorrecta.
4. **`Actividades_Habilidades.gd:45`** — `Calcular_Max_Para_Numero_Aleatorio_No_Especifico` no tiene `return`, siempre devuelve `null`.
5. **`Actividades/Herencia_Actividades/Actividad/Fija/Trabajo.gd:7`** — Usa `requisitos_progreso` (variable miembro) en vez del parámetro local `requisito_progreso`. Además, pasa `hora_f` donde debería ir `hora_i`, dejando `hora_final = null`.
6. **`Actividades/Herencia_Actividades/Actividad/Fija/Trabajo/Comida_Rapida.gd:6`** — Argumentos empaquetados en un array anidado en vez de pasarse por separado.
7. **`Actividades.gd` — `Crear_Actividad_Aleatoria_Mas_De_30`** — Puede devolver `null` si `Personalidad` no coincide con ningún valor esperado.

## Problemas de rendimiento conocidos
- `Funciones_Globales.Guardar_Matriz()` se llama cada minuto de juego. Escribe una matriz enorme en disco en cada tick — muy lento en móvil.
- `Necesidades_Basicas_GUI.Inicializar(raiz)` se llama dentro de `_process` (cada frame), obteniendo referencias a nodos innecesariamente.

## Duplicación de código conocida
- `ActividadesBloqueGUI.gd` y `Consultar_Y_Eliminar_Actividades.gd` contienen prácticamente el mismo código. Deberían compartir una clase base.

## Convenciones del proyecto
- Nombres de funciones y variables en `PascalCase` con guiones bajos (estilo propio del autor).
- Los días de la semana: Lunes=0, Martes=1, Miércoles=2, Jueves=3, Viernes=4, Sábado=5, Domingo=6.
- Resolución objetivo: 720×1280 (portrait móvil).
- `Minute_Day` = índice de columna absoluto en la matriz (día desde el inicio del juego).
- `Minute_Minute` = índice de fila en la matriz (minuto dentro del día, 0–1439).
- `Minute` = minuto Unix absoluto (para comparar con `Time.get_unix_time_from_system()/60`).