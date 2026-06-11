# CLAUDE.md — Contexto del proyecto SIMS

## Regla fundamental: compatibilidad con Godot
Todos los cambios en los archivos `.gd` deben ser **GDScript válido para Godot 4.4**.
- No usar sintaxis de otros lenguajes ni de Godot 3.
- Los scripts se editan desde VS Code, pero se ejecutan desde el editor/runtime de Godot.
- Los nombres de autoloads (singletons) se usan directamente como globales: `Variables_Dinamicas.Progreso`, `Funciones_Globales.Devolver_Dia(n)`, etc. No importar nada, no usar `get_node` para acceder a ellos.
- Las rutas de recursos usan `res://` (relativo a la carpeta `JOKUA/`).
- Las clases definidas con `class_name` en cualquier `.gd` se registran globalmente y se pueden usar sin importar.
- Al comparar celdas de la matriz con strings como `"Actividad_Aleatoria"`, usar siempre `celda is String and celda == "Actividad_Aleatoria"` para evitar errores de tipo al comparar con objetos `Actividad`.

---

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

---

## Descripción del juego

Juego tipo SIMS simplificado para móvil (Android). El personaje empieza con 18 años y puede vivir hasta ~80-90 años de edad en el juego.

### Tiempo
- **1 día real = 1 día en el juego.** La duración de las actividades es realista (dormir 8h = 8h reales).
- **1 semana real = 1 año en el juego.**
- La partida completa dura unas 60 semanas reales (60 años de juego, de los 18 a los ~80).
- El tiempo se mide en minutos Unix: `Variables_Dinamicas.Minute` = último minuto Unix procesado.
- `_process` en `Script_Principal.gd` compara `floor(unix_time / 60)` con `Variables_Dinamicas.Minute` cada frame. Si hay diferencia positiva, llama `Actividades.Actualizar_Horario(minuto_actual)` y guarda.

### La Matriz principal
La estructura de datos central es `Variables_Dinamicas.Matriz_Jugador`, una matriz 2D:
- **Filas (1440):** minutos de un día (0 = medianoche, 1439 = 23:59).
- **Columnas (574):** días totales del juego (7 días × 82 años ≈ 574).
- Índice de columna: `semana * 7 + dia_semana`.
- Índice de fila: `hora * 60 + minuto`.

**Contenido posible de cada celda:**

| Valor | Tipo | Significado |
|---|---|---|
| `""` | String | Celda futura sin actividad programada |
| `"Actividad_Aleatoria"` | String | Celda ya procesada; el sistema ejecutó una actividad aleatoria |
| Objeto `Actividad` | Resource | Actividad concreta programada por el jugador o por trabajo |

La distinción pasado/futuro para la GUI se determina por comparación de fechas (clase `fecha`), no por el valor de celda. Las celdas `""` futuras se ven verdes; los bloques pasados se ven azules independientemente de su contenido.

### Variables de posición en la matriz
- `Minute_Day` = índice de columna actual (día absoluto desde inicio del juego).
- `Minute_Minute` = índice de fila actual (minuto dentro del día, 0–1439).
- `Minute` = minuto Unix absoluto (para comparar con `Time.get_unix_time_from_system()/60`).

---

## Necesidades básicas

Array de 5 valores (rango 1–100) en `Variables_Dinamicas.Necesidades_Basicas`:

| Índice | Necesidad | Frecuencia de cambio base |
|---|---|---|
| `[0]` | Salud física | cada ~30 min en media |
| `[1]` | Salud mental | cada ~30 min en media |
| `[2]` | Hambre | cada ~12 min en media |
| `[3]` | Descanso | cada ~15 min en media |
| `[4]` | Higiene | cada ~20 min en media |

**Mecánica:** `Ejecutar_Actividad_Necesidades_Basicas(por_cuanto, indice, frecuencia)` calcula `valor_maximo = floor(frecuencia / abs(por_cuanto))` y hay una probabilidad de 1/`valor_maximo` de que el valor cambie en ±1 ese minuto. Mínimo 1, máximo 100.

Las barras de la GUI cambian de color: verde (≥50), naranja (30–49), rojo (<30).

---

## Progreso (habilidades aprendidas)

Array de 3 valores (rango 1–100) en `Variables_Dinamicas.Progreso`:

| Índice | Habilidad |
|---|---|
| `[0]` | Deporte |
| `[1]` | Académico |
| `[2]` | Manualidades |

**Mecánica de progresión** (`Ejecutar_Actividad_Progreso`):
1. Calcula `max` con la fórmula: `floor(por_cuanto_ecuacion * (8 ^ potencia1) ^ potencia2)`
   - `potencia1 = (30 + Progreso[indice]) / 100.0`
   - `potencia2 = 15000.0 / (5000 + sum_habilidades)`
2. `max_ajustado = floor(max / por_cuanto_efecto)`
3. Si `random(1, max_ajustado) == 1` → Progreso sube en 1.

Cuanto mayor la suma de habilidades innatas y menor el progreso actual, mayor probabilidad de avanzar. El progreso se vuelve más lento conforme sube.

---

## Habilidades innatas del personaje

Array de 6 valores (1–100) en `Variables_Estaticas.Habilidades`, generados aleatoriamente al inicio:

| Índice | Habilidad | Afecta a |
|---|---|---|
| `[0]` | Deporte | Progreso Deporte |
| `[1]` | Inteligencia | Progreso Académico |
| `[2]` | Destreza manual | Progreso Manualidades |
| `[3]` | Memoria | Todos los progresos |
| `[4]` | Liderazgo | Deporte + Manualidades |
| `[5]` | Paciencia | Académico + Manualidades |

Sumas usadas en `Actividades_Habilidades.gd`:
- Deportivo: `50*Deporte + 40*Liderazgo + 10*Memoria`
- Académico: `50*Inteligencia + 20*Paciencia + 30*Memoria`
- Manualidades: `50*Destreza + 30*Paciencia + 10*Memoria + 10*Liderazgo`

---

## Personalidad

`Variables_Estaticas.Personalidad` — string con uno de tres valores:

| Valor | Actividad preferida en tiempo libre |
|---|---|
| `"Trabajador_Compulsivo"` | Estudiar |
| `"Deportista"` | Salir_A_Correr |
| `"Culo_Del_Sofa"` | Ver_La_Television |

---

## Jerarquía de clases de Actividad

Archivos en `Scripts/Logica/Escena_Principal/Actividades/Herencia/`.

```
Actividad (Resource)                           → Actividad.gd
  @export var nombre: String
  @export var efectos_necesidades_basicas: Array  (5 elementos)
  @export var efectos_progreso: Array             (3 elementos, default [0,0,0])

Actividad_Temporal extends Actividad           → Actividad_Temporal.gd
  (actividades programadas manualmente por el jugador)

Actividad_Fija extends Actividad               → Actividad_Fija.gd
  (actividades fijas recurrentes, marcador de tipo)

Actividad_Fija_Trabajo extends Actividad_Fija  → Actividad_Fija_Trabajo.gd
  @export var hora_inicio: int        (minutos desde medianoche; ej: 480 = 8:00)
  @export var hora_final: int         (minutos desde medianoche; ej: 960 = 16:00)
  @export var salario: float
  @export var requisito_progreso: Array        (3 elementos)
  @export var dias_laborales: Array            (default [0,1,2,3,4] = Lunes–Viernes)
```

---

## Catálogo de actividades

`Variables_Estaticas.Catalogo_Actividades` es un `Dictionary` (`nombre → Actividad`) inicializado en `Variables_Estaticas._ready()`. Todas las actividades son **instancias únicas**; las celdas de la matriz guardan referencias a estos mismos objetos para que las comparaciones `==` de la GUI funcionen correctamente por referencia.

`Variables_Estaticas.Actividades` es un `Array` con las instancias usadas para generar actividades aleatorias generales (incluye las 7 actividades temporales, excluye trabajo).

| Nombre | Clase | efectos_nb `[fís, men, ham, des, hig]` | efectos_prog `[dep, aca, man]` |
|---|---|---|---|
| `Dormir` | Actividad_Temporal | `[1, 1, -1, 4, -1]` | `[0, 0, 0]` |
| `Comer` | Actividad_Temporal | `[-1, 2, 20, -1, -1]` | `[0, 0, 0]` |
| `Duchar` | Actividad_Temporal | `[1, 1, -1, -1, 20]` | `[0, 0, 0]` |
| `Ver_La_Television` | Actividad_Temporal | `[-1, 5, -1, 2, -1]` | `[0, 0, 0]` |
| `Estudiar` | Actividad_Temporal | `[-1, -2, -1, -2, -1]` | `[0, 4, 0]` |
| `Salir_A_Correr` | Actividad_Temporal | `[4, 2, -3, -3, -4]` | `[4, 0, 0]` |
| `Practicar_Manualidades` | Actividad_Temporal | `[-2, -1, -1, -2, -1]` | `[0, 0, 4]` |
| `Trabajar_En_Comida_Rapida` | Actividad_Fija_Trabajo | `[-1, -1, -1, -2, -1]` | `[0, 0, 0]` · hora 8–16 · salario 10.0 |

---

## Flujo de ejecución de actividades

### Tick principal (`Script_Principal.gd._process`)

Cada frame:
1. `minuto_actual = floor(unix_time / 60)`
2. Si `minuto_actual - Minute > -1`: llama `Actividades.Actualizar_Horario(minuto_actual)` y guarda variables dinámicas.
3. Actualiza barras de progreso y necesidades básicas en la GUI.

### `Actividades.Actualizar_Horario(minuto_actual)`

Itera cada minuto entre `Minute` y `minuto_actual` (inclusive, +1 para incluir la casilla 0):

1. Lee `celda = Matriz_Jugador[Minute_Minute][Minute_Day]`
2. Si `celda == "" o null` → escribe `"Actividad_Aleatoria"` en esa celda y ejecuta una actividad aleatoria.
3. Si `celda == "Actividad_Aleatoria"` → ejecuta una actividad aleatoria (ya estaba marcada de un ciclo anterior sin guardar).
4. Si `celda` es un objeto `Actividad` → ejecuta esa actividad programada.
5. Avanza `Minute_Minute` (si llega a 1439 → resetea a 0 y avanza `Minute_Day`).
6. Avanza `Minute`.
7. Al terminar el loop: `Funciones_Globales.Guardar_Matriz()` (log de depuración en disco).

### `Actividades.Ejecutar_Actividad(actividad: Actividad)`

```gdscript
Actividades_Necesidades_Basicas.Ejecutar_Actividad_Necesidades_Basicas_Array(actividad.efectos_necesidades_basicas)
Actividades_Habilidades.Ejecutar_Actividad_Progreso_Array(actividad.efectos_progreso)
```

### `Actividades.Crear_Actividad_Aleatoria()` → objeto `Actividad`

1. Busca la necesidad con valor más bajo en `Necesidades_Basicas`.
2. Si mínimo < 30 → `Crear_Actividad_Aleatoria_Debajo_De_30(indice)`:
   - 0 (salud física) → Salir_A_Correr
   - 1 (salud mental) → Ver_La_Television
   - 2 (hambre) → Comer
   - 3 (descanso) → Dormir
   - 4 (higiene) → Duchar
3. Si mínimo ≥ 30 → `Crear_Actividad_Aleatoria_Mas_De_30()`:
   - `valor = random(0, Actividades.size() * 2)`
   - Si `valor >= Actividades.size()` (~50% prob.): devuelve la actividad de la `Personalidad`.
   - Si `valor < Actividades.size()`: devuelve `Actividades[valor]` (aleatorio de la lista general).

---

## Flujo de programación de actividades (GUI)

1. Jugador pulsa "Actividades" → menú de selección.
2. Elige tipo (Progreso / Necesidades Básicas) y actividad → `Script_Principal.Actividad_Terminada_X()`.
3. `SeleccionarHorarioReloj.Crear_Actividad(semana, nombre)` → `Actividades.Crear_Actividad_Especifica(...)`.
4. `Crear_Actividad_Especifica` acepta nombre String u objeto `Actividad`:
   - String no vacío → busca en `Variables_Estaticas.Catalogo_Actividades`.
   - String vacío `""` → borra las celdas (las limpia a `""`).
   - Objeto `Actividad` → lo usa directamente.
5. Escribe el objeto del catálogo en cada celda del rango. Todas las celdas del mismo tipo apuntan a la **misma instancia** del catálogo.
6. Guarda ambos archivos de save.

Para **eliminar**: `Script_Principal._on_eliminar_actividad_pressed()` llama `Crear_Actividad(semana, "")`, que escribe `""` en el rango seleccionado.

---

## Trabajo fijo (`Trabajo.gd`)

`Trabajar_En_Comida_Rapida()` obtiene el objeto del catálogo y llama `Trabajar(actividad)`:
- Itera desde la semana siguiente a la actual hasta la columna 573.
- Solo escribe en días que estén en `actividad.dias_laborales` (`i % 7 not in dias_laborales` → skip).
- Escribe la referencia del objeto catálogo en las celdas `[hora_inicio..hora_final-1]` de esos días.
- Al usar la misma referencia del catálogo, los bloques del calendario se agrupan correctamente.

---

## Sistema de guardado

### Variables dinámicas (`Guardar_Variables_Dinamicas.gd`)
- Ruta: `user://guardado/variables/Guardar_Variables_Dinamicas.dat`
- Formato: binario (`store_var` / `get_var`).
- **Al guardar** (`_Matriz_A_Strings`): objetos `Actividad` → su `nombre` (String). Strings `""` y `"Actividad_Aleatoria"` se guardan tal cual.
- **Al cargar** (`_Strings_A_Matriz`): strings que coincidan con claves del catálogo → referencia del catálogo; `""` y `"Actividad_Aleatoria"` se restauran como strings. Esto garantiza que todas las celdas del mismo tipo apunten al **mismo objeto** del catálogo.
- Campos guardados: `Matriz_Jugador`, `Progreso`, `Necesidades_Basicas`, `Dinero`, `Minute`, `Minute_Day`, `Minute_Minute`.

### Variables estáticas (`Guardar_Variables_Estaticas.gd`)
- Ruta: `user://guardado/variables/Guardar_Variables_Estaticas.dat`
- Campos guardados: `First_Time`, `First_Time_Minute`, `Habilidades`, `Personalidad`, `First_Time_Minute_Day`, `First_Time_Minute_Minute`.
- `Catalogo_Actividades` y `Actividades` **no se guardan**; se reconstruyen en `Variables_Estaticas._ready()` cada vez que arranca el juego, antes de que cualquier escena cargue.

### Logs de depuración (no son saves reales)
- `user://guardado/otros/Guardar_Matriz.txt` — volcado legible de toda la matriz (columna por columna, hora por hora). Se genera al final de cada `Actualizar_Horario`.
- `user://guardado/otros/Matriz_Dia.txt` — volcado de un día concreto (se genera al llamar `Trabajo.Trabajar`).

### Primera partida
Si `Variables_Estaticas.First_Time == true` al entrar en la escena principal, `First_Time.First_Time_Function()`:
1. Crea la matriz 1440×574 rellena de `""`.
2. Genera `Personalidad` aleatoria (1 de 3 valores).
3. Genera 6 habilidades aleatorias (1–100).
4. Inicializa `Necesidades_Basicas` a `[50, 50, 50, 50, 50]`.
5. Inicializa `Progreso` a `[1, 1, 1]`.
6. Captura el minuto Unix actual y el día/minuto actual como punto de partida.
7. `Dinero = 1000`. Guarda y pone `First_Time = false`.

El menú (`Menu.gd`) carga variables estáticas y dinámicas en su `_ready()` antes de entrar a la escena principal.

---

## GUI — Arquitectura de pantallas

### Gestionar_Visibilidad.gd (autoload)
Controla toda la visibilidad mediante `visible = true/false` recursivo:
- `Quitar_Todo(raiz)`: oculta todo, muestra solo `Barra_Abajo`, `Fondo`, `Moneda`.
- `Visibilizar_Elegir_Actividad`: menú de selección de actividad con árbol de submenús.
- `Visibilizar_Horario_Semanal`: calendario semanal.
- `Visibilizar_Seleccionar_Horario`: reloj de selección de hora inicio/fin.
- `Pulsar_Boton_Opciones_Actividades(opcion)` / `Pulsar_Flecha_Atras()`: navegan el árbol de submenús usando `raiz_path` (string de ruta de nodo).

### Calendario semanal (`ActividadesBloqueGUI.gd`)
- Obtiene datos de `Funciones_Globales.Devolver_Bloque_Matriz_Semana_(semana)` → matriz 288×7 de **strings** (288 bloques de 5 minutos × 7 días).
- Colores de bloques:
  - **Azul**: bloques pasados (determinado por `fecha.Comparar_Dos_Fechas`, no por valor de celda).
  - **Verde**: bloques futuros con celda `""` (libre para programar).
  - **Rojo**: bloques futuros con actividad programada (nombre de actividad).
- Al pulsar verde → botón "Ocupar actividad" visible. Al pulsar rojo → botón "Eliminar actividad" visible.
- El texto mostrado al pulsar un bloque es `boton.get_meta("actividad")` (siempre String: nombre de actividad, `""`, o `"Actividad_Aleatoria"`).

### `Funciones_Globales.Devolver_Bloque_Matriz_Semana_(semana)`
Convierte un tramo de `Matriz_Jugador` a strings:
- Toma la celda en el minuto `*5` como representante del bloque.
- Si alguno de los 5 minutos del bloque tiene `"Actividad_Aleatoria"` → el bloque entero muestra `"Actividad_Aleatoria"`.
- Convierte objetos `Actividad` a su `nombre` con `_Celda_A_Clave(celda)`.
- El resultado es siempre strings puros → sin problemas de tipos en las comparaciones de la GUI.

### Consultar y eliminar (`Consultar_Y_Eliminar_Actividades.gd`)
Vista similar al calendario semanal pero simplificada: muestra verde si la celda está vacía (`""`), rojo si tiene cualquier contenido.

### Selección de horario
- `SeleccionarHorarioReloj.gd`: referencias a controles del reloj (día/hora/minuto inicio y fin). Sube/baja cada componente con botones.
- `ActividadesRelojGUI.gd`: valida consistencia del horario (no solapamiento con bloque origen, no horas inválidas) y muestra/oculta botones según límites.
- `HorarioDesdeBloque.gd`: transfiere el horario del bloque origen al reloj.

### Necesidades básicas GUI (`Necesidades_Basicas_GUI.gd`)
`Actualizar_Necesidades_Basicas(raiz)` actualiza los 5 `ProgressBar` con el valor actual y ajusta su color semafórico.

### Clases auxiliares de GUI
- `BloqueDiaColumna` (`Bloque_Dia_Columna.gd`): referencias a las 7 columnas VBox del calendario + funciones de limpieza.
- `fecha` (`Fecha.gd`): par `(dia, minuto)` con método `Comparar_Dos_Fechas(f)` para determinar si una fecha es anterior a otra.

---

## Convenciones del proyecto

- Nombres de funciones y variables en `PascalCase` con guiones bajos (estilo propio del autor).
- Los días de la semana: Lunes=0, Martes=1, Miércoles=2, Jueves=3, Viernes=4, Sábado=5, Domingo=6.
- Resolución objetivo: 720×1280 (portrait móvil).

---

## Bugs conocidos pendientes

### Rendimiento
1. **`Necesidades_Basicas_GUI.Actualizar_Necesidades_Basicas`** llama `Inicializar(raiz)` cada frame, obteniendo referencias a nodos innecesariamente. Debería inicializar una sola vez.
2. **`Guardar_Variables_Dinamicas.save_game()`** convierte la matriz entera (~827 K celdas) a strings en cada guardado, que ocurre cada minuto de juego. Muy lento en móvil. Solución futura: guardado diferencial o formato esparso.
3. **`Funciones_Globales.Guardar_Matriz()`** escribe toda la matriz como texto plano en disco cada minuto. Es solo para depuración; en producción debería desactivarse.

### Trabajo
4. **`Trabajo.gd`** tiene las funciones `Trabajar_De_Carpintero()` y `Trabajar_De_Cientifico()` que buscan en el catálogo objetos que aún no existen. Llamarlas causará error de clave no encontrada. Hay que añadirlas al catálogo en `Variables_Estaticas._Inicializar_Catalogo()` antes de activarlas.

### Duplicación de código
5. **`ActividadesBloqueGUI.gd`** y **`Consultar_Y_Eliminar_Actividades.gd`** contienen lógica muy similar de renderizado de bloques semanales. Deberían compartir una clase base.

### Typo en guardado
6. **`Guardar_Variables_Estaticas.gd`**: la clave `"First_TIme_Minute_Minute"` (I mayúscula) es consistente entre save y load por lo que funciona, pero es un typo que podría causar confusión en el futuro.

---

## Estructura de Funcionalidades

A partir de este punto, las funcionalidades implementadas se documentan en la carpeta `Funcionalidades/` con la siguiente estructura:

```
Funcionalidades/
├── Nombre_Funcionalidad/
│   ├── Tests/
│   │   └── test_funcionalidad.gd    (Tests automatizados)
│   └── Documentacion/
│       ├── FUNCIONALIDAD.md         (Para IA - referencia rápida)
│       └── FUNCIONALIDAD.html       (Para humano - visualización PDF)
```

### Funcionalidades Implementadas

#### 1. Cobrar_Alquiler
**Ubicación:** `Funcionalidades/Cobrar_Alquiler/`
- **Tests:** `Tests/test_alquiler.gd` - 6 casos de prueba cubriendo todos los escenarios
- **Documentación:** `Documentacion/ALQUILER.html` - Guía completa visual (abre en navegador)

**Descripción:** Sistema timer-based de alquiler semanal (200€ cada 7 días). El jugador puede elegir ir a la calle voluntariamente o automáticamente si no tiene dinero. Necesidades básicas caen a máximo 20 cuando está en la calle.

**Variables afectadas:**
- `Variables_Dinamicas.En_La_Calle` (bool)
- `Variables_Dinamicas.Ultima_Fecha_Alquiler` (int)
- `Variables_Dinamicas.Dinero` (int)
- `Variables_Dinamicas.Necesidades_Basicas` (Array)

**Funciones principales:**
- `Actividades.Cobrar_Alquiler()` - Intenta cobrar 200€ o va a la calle
- `Actividades.Ir_A_La_Calle()` - Marca como sin alojamiento, capa necesidades a 20
- `Actividades.Volver_A_Alquiler()` - Requiere 200€, inicia nuevo timer
- `Script_Principal._on_alquiler_button_pressed()` - UI: botón de estado alquiler/calle
- `Gestionar_Visibilidad.Visibilizar_Lo_Basico()` - Asegura que el botón sea siempre visible

#### 2. Ver_Calendario
**Ubicación:** `Funcionalidades/Ver_Calendario/`
- **Tests:** `Tests/test_ver_calendario.gd` - 8 casos de prueba cubriendo flag, navegación y visibilidad de botones
- **Documentación:** `Documentacion/VER_CALENDARIO.html` - Guía completa visual (abre en navegador)

**Descripción:** Botón "📅 Horario" en la barra superior izquierda que abre el calendario semanal en modo solo lectura. El jugador puede navegar entre semanas y eliminar actividades futuras, pero no puede crear nuevas.

**Variables afectadas:**
- `Script_Principal.mirar_semana` (int) — semana mostrada, inicializada a semana actual
- `Script_Principal.calendario_solo_lectura` (bool) — bloquea OCUPAR_ACTIVIDAD cuando es true

**Funciones principales:**
- `Script_Principal._on_calendario_boton_pressed()` - Abre el calendario en modo solo lectura
- `ActividadesBloqueGUI.verde_seleccionado(raiz)` - Respeta el flag para OCUPAR_ACTIVIDAD
- `ActividadesBloqueGUI.rojo_seleccionado(raiz)` - Siempre muestra ELIMINAR independientemente del flag
- `Gestionar_Visibilidad.Visibilizar_Lo_Basico()` - Incluye Calendario_Button en la barra superior

#### 3. Informacion (pantalla de perfil con pestañas)
**Ubicación:** `Funcionalidades/Perfil/Informacion/`
- **Tests:** `Tests/test_perfil.gd` - 8 casos cubriendo cálculo de edad, personalidad y límite de habilidades
- **Documentación:** `Documentacion/PERFIL.html`

**Descripción:** Pantalla de perfil reorganizada en tres pestañas (Info, Mensajes, Apuntes). Se abre siempre en Tab Info con datos calculados en tiempo real (edad, personalidad, progreso, habilidades).

**Variables afectadas (solo lectura):**
- `Variables_Dinamicas.Minute_Day`, `Variables_Estaticas.First_Time_Minute_Day` (cálculo de edad)
- `Variables_Estaticas.Personalidad`, `Variables_Dinamicas.Dinero`
- `Variables_Dinamicas.Progreso`, `Variables_Estaticas.Habilidades`

**Funciones principales:**
- `Script_Principal._on_perfil_button_pressed()` - Abre el perfil en Tab Info
- `Script_Principal._on_perfil_tab_info/mensajes/apuntes_pressed()` - Cambio de pestaña
- `Script_Principal._Renderizar_Info()` - Rellena Panel_Info dinámicamente
- `Gestionar_Visibilidad.Visibilizar_Perfil(raiz)` - Muestra la pantalla ocultando los 4 paneles de contenido

#### 4. Inventario (Tab Apuntes)
**Ubicación:** `Funcionalidades/Perfil/Inventario/`
- **Tests:** `Tests/test_inventario.gd` - 8 casos cubriendo recopilación de libros, formato y edge cases
- **Documentación:** `Documentacion/INVENTARIO.html`

**Descripción:** Pestaña "Apuntes" dentro del Perfil. Muestra los libros desbloqueados al avanzar en carreras (formato "Anio_N"). El jugador puede leer el contenido de cada libro. Sin libros, muestra mensaje informativo.

**Variables afectadas (solo lectura):**
- `Variables_Dinamicas.Carrera_Actual` (Carrera|null)
- `Variables_Dinamicas.Carreras_Completadas` (Array[Carrera])
- `carrera.libros_desbloqueados` (Array[String])

**Funciones principales:**
- `Script_Principal._Renderizar_Apuntes()` - Recopila libros y crea botones en Tabs_Libros
- `Script_Principal._Mostrar_Apunte(carrera, año)` - Lee archivo .txt y lo vuelca en Texto_Apuntes
