# Prompt de Implementación — `Salir_De_Fiesta` (Euforia y Resacón)

**Cómo usarlo:** copia todo el bloque a partir de `PROMPT (pegar desde aquí)` y pégalo en el agente implementador. Este prompt parte de la especificación aprobada `Prompts/salir-de-fiesta/salir-de-fiesta.md` (v1.0).

---

PROMPT (pegar desde aquí)

# Tarea: implementar la actividad `Salir_De_Fiesta` y el sistema de estados temporales (`Euforia` y `Resacon`)

Actúa como desarrollador senior de Godot 4.4 en el proyecto `/home/lur/sims-0.33` (SIMS 0.33, juego tipo Sims en español, resolución 720×1280 portrait). Implementa de principio a fin la actividad temporal `Salir_De_Fiesta` con su ventana horaria nocturna, sus dos probabilidades independientes por minuto (ligar y resacón), el sistema de estados temporales persistentes (`Euforia` y `Resacon`), la vista previa en el selector de horario, el indicador en Necesidades Básicas, los tests GUT y la documentación.

No pidas confirmación: lee el código, implementa, ejecuta los tests GUT y entrégame un informe final.

---

## 1. Contexto obligatorio (léelo antes de editar)

- `Prompts/salir-de-fiesta/salir-de-fiesta.md` (v1.0 — fuente de verdad funcional).
- `CLAUDE.md` — reglas del proyecto, autoloads, jerarquía P1/P2/P3 y catálogo actual.
- `Scripts/Globales/Principales_Variables/Variables_Estaticas.gd` — `_Inicializar_Catalogo()`, `Actividades`, `BANCARROTA_MAX_NECESIDAD`.
- `Scripts/Globales/Principales_Variables/Variables_Dinamicas.gd` — `Necesidades_Basicas`, `Progreso`, `Personalidad`, `Matriz_Jugador`, `Mensajes`, `Dinero`, `En_La_Calle`, `Minute_Day`, `Minute_Minute`.
- `Scripts/Otro/Guardar/Guardar_Variables_Dinamicas.gd` — serialización de partida y compatibilidad hacia atrás.
- `Scripts/Globales/Menu.gd` — reseteo de variables al iniciar nueva partida.
- `Scripts/Logica/Escena_Principal/Actividades/Actividades.gd` — `Ejecutar_Actividad`, `_Calcular_Rango`, `Crear_Actividad_Especifica`, `Actualizar_Horario`, `Comprobar_Muerte`.
- `Scripts/Logica/Escena_Principal/Actividades/Actividades_Necesidades_Basicas.gd` — `Cambiar_Necesidades_Basicas` (donde ya vive el cap de bancarrota a 20).
- `Escenas/Escena_Principal/Escena principal.tscn` — botones bajo `Actividades/Elegir_Actividad/Tipos_De_Actividades/Temporales_Opciones/Necesidades_Basicas_Opciones` y conexiones `pressed`.
- `Scripts/Globales/Script_Principal.gd` — `_SUBTITULOS_ACTIVIDADES`, `_Redisenar_Actividades()`, handlers `Actividad_Terminada_*`, creación de bloques y diálogos de error.
- `Scripts/GUI/Escena_Principal/Estilos_UI.gd` — `ICONOS_BOTONES`.
- `Scripts/GUI/Escena_Principal/Actividades/Reloj/Auxiliar/SeleccionarHorarioReloj.gd` — selector de horario y cálculo de rango.
- `Scripts/GUI/Escena_Principal/Necesidades_Basicas/Necesidades_Basicas_GUI.gd` — actualización de barras y panel de Necesidades Básicas.
- `Funcionalidades/Actividades/Jerarquia/Tests/test_jerarquia.gd` — patrón de tests GUT del proyecto.

---

## 2. Reglas duras (inviolables)

1. **Godot 4.4 / GDScript 2.0**: nada de sintaxis de Godot 3. Tipado explícito en funciones nuevas.
2. **Claves ASCII estables**: `Salir_De_Fiesta`, `Euforia`, `Resacon` (sin tildes ni espacios en claves de catálogo o save).
3. **Prioridad P1**: `Salir_De_Fiesta` es `Actividad_Temporal`. No puede pisar trabajo (`P2`) ni examen (`P3`).
4. **No entra en el pool aleatorio en v1**: **NO** añadas `Salir_De_Fiesta` al array `Variables_Estaticas.Actividades`.
5. **Compatibilidad con saves antiguos**: si un save no tiene `Estados_Temporales` o `Fiesta_Evento_Ocurrido`, debe cargar limpiamente con `{}` y `false` respectivamente.
6. **Sin efectos secundarios en actividades existentes**: no modifiques efectos, prioridades, salarios, costes ni comportamientos de las actividades actuales.
7. **Funciones puras para la matemática**: puntaje de ligar, aguante de resacón, probabilidades por minuto, simulación de vista previa, validación de horario y cálculo de cap deben ser funciones puras deterministas (sin `randf()` ni acceso a UI) para poder testearlas unitariamente con GUT.
8. **Icono existente**: usa `"party-popper"` de `Imagenes/UI/Iconos/` (verifica su nombre exacto en la carpeta; no crees assets nuevos).
9. **Resolución 720×1280 portrait**: ni el botón en `Necesidades_Basicas_Opciones`, ni el panel de vista previa en `Seleccionar_Horario`, ni el label de estado en Necesidades Básicas pueden desbordarse ni cortarse.
10. **Rendimiento O(1) por minuto**: nada de trabajo en `_process` ni escaneos completos de `Matriz_Jugador`.

---

## 3. Especificación técnica detallada (12 puntos de integración)

### 3.1. `Variables_Estaticas.gd` — Catálogo de actividad y estados

1. En `_Inicializar_Catalogo()` (antes de `Actividades = [...]`), registra:
   ```gdscript
   var salir_de_fiesta = Actividad_Temporal.new()
   salir_de_fiesta.nombre = "Salir_De_Fiesta"
   salir_de_fiesta.color = Color(0.85, 0.15, 0.45)
   salir_de_fiesta.efectos_necesidades_basicas = [0, 9, -3, -4, -2]
   salir_de_fiesta.efectos_progreso = [0, 0, 0]
   Catalogo_Actividades["Salir_De_Fiesta"] = salir_de_fiesta
   ```
   - **No** la añadas a `Actividades = [...]`.

2. Añade el diccionario estático `Estados_Temporales`:
   ```gdscript
   var Estados_Temporales: Dictionary = {
       "Euforia": {
           "duracion": 1440,
           "meseta": 480,
           "tipo": "suelo_gradual",
           "indice": 1,
           "valor_inicial": 100,
           "valor_final": 50,
           "mensaje_inicio": "Has ligado. Euforia durante 24 h.",
           "mensaje_fin": "La euforia ha terminado."
       },
       "Resacon": {
           "duracion": 1440,
           "meseta": 480,
           "tipo": "cap_gradual",
           "indices": [0, 1],
           "cap_inicial": 30,
           "cap_final": 100,
           "mensaje_inicio": "Te has pasado con la bebida. Resacón durante 24 h.",
           "mensaje_fin": "El resacón ha terminado."
       }
   }
   ```

---

### 3.2. `Variables_Dinamicas.gd`, `Guardar_Variables_Dinamicas.gd` y `Menu.gd` — Estado y persistencia

1. En `Variables_Dinamicas.gd`:
   ```gdscript
   var Estados_Temporales: Dictionary = {}       # { "Euforia": minutos_restantes } o { "Resacon": minutos_restantes }
   var Fiesta_Evento_Ocurrido: bool = false      # true si ya saltó un evento en el bloque de fiesta actual
   ```
2. En `Guardar_Variables_Dinamicas.gd`:
   - Al **guardar**: serializa `Estados_Temporales` (copia del diccionario con valores `int`) y `Fiesta_Evento_Ocurrido` (`bool`).
   - Al **cargar**: lee ambos con fallback seguro si no existen en el save (`{}` y `false`), convirtiendo los valores de `Estados_Temporales` a `int` y filtrando claves desconocidas si hiciera falta.
3. En `Menu.gd` (al empezar partida nueva):
   - Resetea `Variables_Dinamicas.Estados_Temporales = {}` y `Variables_Dinamicas.Fiesta_Evento_Ocurrido = false`.

---

### 3.3. `Actividades.gd` — Fórmulas puras, validación de ventana, eventos y estados

Implementa las siguientes funciones (todas limpias, tipadas y reutilizables):

#### A. Validación de ventana horaria de fiesta
```gdscript
func Validar_Horario_Fiesta(dia_inicio: int, hora_inicio: int, minuto_inicio: int, dia_final: int, hora_final: int, minuto_final: int) -> Dictionary
```
Retorna `{ "valido": true, "duracion_min": int, "motivo": "" }` o `{ "valido": false, "duracion_min": 0, "motivo": "..." }`.

Reglas exactas:
- Convierte inicio a minutos del día `m_ini = hora_inicio * 60 + minuto_inicio` y fin a `m_fin = hora_final * 60 + minuto_final`.
- **Inicio permitido**: `18:00` a `04:00` inclusive (`m_ini >= 1080 or m_ini <= 240`).
  - Si no cumple → rechazo: `"La fiesta debe empezar entre las 18:00 y las 04:00"`.
- **Fin permitido**: `20:00` a `06:00` inclusive (`m_fin >= 1200 or m_fin <= 360`).
  - Si no cumple → rechazo: `"La fiesta debe terminar como máximo a las 06:00"`.
- **Cálculo de duración y cruce de medianoche**:
  - Si `dia_final == dia_inicio` y `m_fin > m_ini`: `duracion_min = m_fin - m_ini`.
  - Si `dia_final == dia_inicio + 1` (o si el selector deduce cruce de medianoche cuando `m_ini >= 1080` y `m_fin <= 360`): `duracion_min = (1440 - m_ini) + m_fin`.
  - Cualquier otra combinación donde fin no sea posterior al inicio o salte más de un día → rechazo: `"El horario de fin debe ser posterior al de inicio"`.
- **Duración**:
  - Si `duracion_min < 120` → rechazo: `"La fiesta debe durar al menos 2 horas"`.
  - Si `duracion_min > 720` → rechazo: `"La fiesta no puede durar más de 12 horas"`.
- **Límites de matriz**: si el bloque excede el día máximo de la matriz (574) o semana inválida → rechazo: `"El bloque se sale del calendario"`.
- **Nota**: respeta el mismo patrón que usa `_Calcular_Rango` para `dia_inicio`/`dia_final` (el selector puede pasar `dia_final = dia_inicio + 1` cuando cruza medianoche). Asegúrate de que un bloque como `22:00–02:00` o `02:00–06:00` o `18:00–06:00` (12 h exactas) funcione sin fallos.

#### B. Funciones puras de probabilidad (dos fórmulas independientes)

Índices de referencia en `Variables_Dinamicas`:
- `NB = Necesidades_Basicas`: `[0] Salud Física`, `[1] Salud Mental`, `[2] Hambre`, `[3] Descanso`, `[4] Higiene`.
- `Progreso`: `[0] Deporte`, `[1] Académico`, `[2] Manualidades`.

1. **Modificador de personalidad** (solo para Ligar):
   ```gdscript
   func _Obtener_Mod_Personalidad_Fiesta(personalidad: String) -> float:
       match personalidad:
           "Deportista":
               return 10.0
           "Culo_Del_Sofa":
               return -10.0
           "Trabajador_Compulsivo":
               return -5.0
           _:
               return 0.0
   ```
   *(Verifica en `Variables_Estaticas.gd` los nombres exactos de las personalidades por si llevan mayúsculas/guiones distintos y ajusta el `match` si hace falta).*

2. **Modificador de edad** (compartido por Ligar y Aguante de Resacón):
   ```gdscript
   func Calcular_Mod_Edad_Fiesta(edad: int) -> float:
       return clampf(10.0 - float(edad - 20) * 0.625, -25.0, 12.0)
   ```
   *(20 años → `+10.0`, 36 años → `0.0`, 60 años → `-15.0`, 76+ años → `-25.0`. En ejecución real se obtiene con `Variables_Estaticas.Calcular_Edad()`).*

3. **Multiplicador por día de la semana de la noche** (solo Ligar):
   - La "noche de fiesta" pertenece al día en que empezó la noche:
     ```gdscript
     func Obtener_Dia_Semana_Noche(dia: int, hora: int) -> int:
         var dia_noche = dia - 1 if hora < 6 else dia
         return posmod(dia_noche, 7)

     func Obtener_Mult_Dia_Fiesta(dia_semana_noche: int) -> float:
         match dia_semana_noche:
             0, 1, 2: return 0.70   # Lunes, Martes, Miércoles
             3:       return 1.00   # Jueves
             4:       return 1.25   # Viernes
             5:       return 1.45   # Sábado
             6:       return 0.80   # Domingo
             _:       return 1.00
     ```
   *(Así, salir el sábado 23:00 hasta el domingo 03:00 aplica `Sábado × 1.45` durante toda la fiesta).*

4. **Puntaje y probabilidad de Ligar**:
   ```gdscript
   func Calcular_Puntaje_Ligar(nb: Array, progreso: Array, personalidad: String, edad: int = 36) -> float:
       var mod_pers = _Obtener_Mod_Personalidad_Fiesta(personalidad)
       var mod_edad = Calcular_Mod_Edad_Fiesta(edad)
       var raw = 50.0 \
           + 0.30 * (float(nb[1]) - 50.0) \
           + 0.25 * (float(nb[4]) - 50.0) \
           + 0.20 * (float(progreso[0]) - 50.0) \
           + 0.15 * (float(progreso[1]) - 50.0) \
           + 0.10 * (float(nb[3]) - 50.0) \
           + mod_pers \
           + mod_edad
       return clampf(raw, 0.0, 100.0)

   func Calcular_Prob_Ligar_Min(puntaje_ligar: float, dia_semana_noche: int = 3) -> float:
       var base = 0.00001 + 0.00099 * (puntaje_ligar / 100.0)
       return base * Obtener_Mult_Dia_Fiesta(dia_semana_noche)
   ```

5. **Aguante y probabilidad de Resacón (invertida)**:
   ```gdscript
   func Calcular_Aguante_Resacon(nb: Array, progreso: Array, edad: int = 36) -> float:
       var mod_edad = Calcular_Mod_Edad_Fiesta(edad)
       var raw = 50.0 \
           + 0.40 * (float(nb[2]) - 50.0) \
           + 0.30 * (float(nb[3]) - 50.0) \
           + 0.20 * (float(nb[0]) - 50.0) \
           + 0.10 * (float(progreso[0]) - 50.0) \
           + mod_edad
       return clampf(raw, 0.0, 100.0)

   func Calcular_Prob_Resacon_Min(aguante_resacon: float) -> float:
       var riesgo = (100.0 - aguante_resacon) / 100.0
       return 0.00001 + 0.00099 * riesgo
   ```

6. **Simulación de vista previa** (`Simular_Preview_Fiesta`):
   ```gdscript
   func Simular_Preview_Fiesta(nb_inicial: Array, progreso: Array, personalidad: String, duracion_min: int, edad: int = 36, dia_semana_noche: int = 3) -> Dictionary
   ```
   - Copia `nb` en `Array` de `float` (clamp `1.0..100.0`).
   - Frecuencias `[30.0, 30.0, 12.0, 15.0, 20.0]`, efectos `[0.0, 9.0, -3.0, -4.0, -2.0]`.
   - En cada minuto `0 .. duracion_min - 1`:
     - Aplica el valor esperado de cada efecto:
       `delta = sign(eff[k]) * min(1.0, abs(eff[k]) / freq[k])`
       `nb[k] = clampf(nb[k] + delta, 1.0, 100.0)`
     - Calcula `pl = Calcular_Prob_Ligar_Min(Calcular_Puntaje_Ligar(nb, progreso, personalidad, edad), dia_semana_noche)`
     - Calcula `pr = Calcular_Prob_Resacon_Min(Calcular_Aguante_Resacon(nb, progreso, edad))`
     - Registra `pl_inicio`, `pr_inicio` (minuto 0) y `pl_fin`, `pr_fin` (último minuto).
     - Acumula con riesgos competitivos independientes (ligar se tira primero):
       ```gdscript
       p_ligar += supervivencia * pl
       p_resacon += supervivencia * pr * (1.0 - pl)
       supervivencia *= (1.0 - pl) * (1.0 - pr)
       ```
   - Retorna:
     ```gdscript
     {
         "duracion_min": duracion_min,
         "pl_inicio": pl_inicio,
         "pl_fin": pl_fin,
         "pr_inicio": pr_inicio,
         "pr_fin": pr_fin,
         "p_ligar": p_ligar,
         "p_resacon": p_resacon,
         "p_nada": supervivencia
     }
     ```

#### C. Gestión de estados temporales (`Euforia` y `Resacon`)

1. **`Obtener_Cap_Resacon() -> int`**:
   - Si `"Resacon"` no está en `Variables_Dinamicas.Estados_Temporales`, retorna `100` (o `BANCARROTA_MAX_NECESIDAD` si está en calle/bancarrota).
   - Si está activo con `minutos_restantes` (`duracion = 1440`, `meseta = 480`, ventana de bajada = `960`):
     - Primeras 8 h (`minutos_restantes > 960`): `cap_resacon = 30` (efecto a tope).
     - Últimas 16 h (`minutos_restantes <= 960`): sube linealmente de `30` a `100`:
     ```gdscript
     var cap_resacon: int = 30
     if minutos_restantes <= 960:
         var progreso_bajada = float(960 - minutos_restantes) / 960.0
         cap_resacon = 30 + int(floor(progreso_bajada * 70.0))
     cap_resacon = clampi(cap_resacon, 30, 100)
     if Variables_Dinamicas.En_La_Calle or Variables_Dinamicas.Dinero < 0:
         return mini(cap_resacon, Variables_Estaticas.BANCARROTA_MAX_NECESIDAD)
     return cap_resacon
     ```
   - Valores de referencia: `1440..960 -> 30`, `720 -> 47`, `480 -> 65`, `240 -> 82`, `0 -> 100`.

2. **`Obtener_Suelo_Euforia() -> int`**:
   - Si `"Euforia"` no está en `Variables_Dinamicas.Estados_Temporales`, retorna `1`.
   - Primeras 8 h (`minutos_restantes > 960`): `suelo = 100` (efecto a tope).
   - Últimas 16 h (`minutos_restantes <= 960`): baja linealmente de `100` a `50`:
     ```gdscript
     var suelo: int = 100
     if minutos_restantes <= 960:
         var progreso_bajada = float(960 - minutos_restantes) / 960.0
         suelo = 100 - int(floor(progreso_bajada * 50.0))
     suelo = clampi(suelo, 50, 100)
     if Variables_Dinamicas.En_La_Calle or Variables_Dinamicas.Dinero < 0:
         return mini(suelo, Variables_Estaticas.BANCARROTA_MAX_NECESIDAD)
     return suelo
     ```
   - Valores de referencia: `1440..960 -> 100`, `720 -> 87`, `480 -> 75`, `240 -> 62`, `0 -> 50`.

3. **`Activar_Estado(nombre_estado: String) -> void`**:
   - Lee la definición en `Variables_Estaticas.Estados_Temporales[nombre_estado]`.
   - Asigna `Variables_Dinamicas.Estados_Temporales[nombre_estado] = def["duracion"]` (`1440`). (Sin lógica de `opuesto`: cada estado es independiente).
   - Aplica efecto inmediato:
     - Si `"Euforia"`: sube `Variables_Dinamicas.Necesidades_Basicas[1]` (Salud Mental) al menos hasta `Obtener_Suelo_Euforia()` (`100`, o `20` en calle/bancarrota).
     - Si `"Resacon"`: recorta `Necesidades_Basicas[0]` (Salud Física) y `Necesidades_Basicas[1]` (Salud Mental) a `mini(valor, Obtener_Cap_Resacon())` (con `cap_inicial = 30`, o `20` en calle/bancarrota).
   - Añade el mensaje `def["mensaje_inicio"]` a `Variables_Dinamicas.Mensajes` (usando el mismo helper/formato que el resto del proyecto para mensajes).

4. **`Tick_Estados() -> void`**:
   - Para cada estado activo en `Variables_Dinamicas.Estados_Temporales.keys()`:
     - Primero aplica el efecto del estado con el valor actual del contador:
       - Si `"Euforia"`: si `Necesidades_Basicas[1] < Obtener_Suelo_Euforia()`, lo sube a `Obtener_Suelo_Euforia()`.
       - Si `"Resacon"`: recorta `Necesidades_Basicas[0]` y `Necesidades_Basicas[1]` si superan `Obtener_Cap_Resacon()`.
     - Después descuenta `1` minuto al contador.
     - Si llega a `<= 0`: elimina la clave de `Estados_Temporales` y añade `mensaje_fin` a `Variables_Dinamicas.Mensajes`.

4. **Detección de primer minuto del bloque (`Es_Primer_Minuto_Del_Bloque`) y `Resolver_Evento_Fiesta()`**:
   - En `Actualizar_Horario(minutos_a_procesar)` (en cada minuto antes de avanzar `Minute_Minute`/`Minute_Day`):
     1. Si la `celda` actual es `Salir_De_Fiesta`:
        - Comprueba la celda inmediatamente anterior (minuto anterior; si `Minute_Minute == 0`, mira `Minute_Day - 1` en `1439`). Si la celda anterior **no** es `Salir_De_Fiesta`, es el primer minuto de un bloque nuevo → `Variables_Dinamicas.Fiesta_Evento_Ocurrido = false`. (Esto hace que dos bloques adyacentes de fiesta cuenten como un solo bloque con máximo 1 evento).
     2. Se ejecuta `Ejecutar_Actividad(celda)`.
     3. Si la `celda` es `Salir_De_Fiesta` y `not Variables_Dinamicas.Fiesta_Evento_Ocurrido`:
        - Llama a `Resolver_Evento_Fiesta()`:
          - Obtiene `edad = Variables_Estaticas.Calcular_Edad(Variables_Dinamicas.Minute_Day)`, `pers = Variables_Estaticas.Personalidad`, `dia_noche = Obtener_Dia_Semana_Noche(Variables_Dinamicas.Minute_Day, Variables_Dinamicas.Minute_Minute / 60)`.
          - Calcula `pl = Calcular_Prob_Ligar_Min(Calcular_Puntaje_Ligar(Variables_Dinamicas.Necesidades_Basicas, Variables_Dinamicas.Progreso, pers, edad), dia_noche)`
          - Calcula `pr = Calcular_Prob_Resacon_Min(Calcular_Aguante_Resacon(Variables_Dinamicas.Necesidades_Basicas, Variables_Dinamicas.Progreso, edad))`
          - Tirada independiente 1: `if randf() < pl:` → `Fiesta_Evento_Ocurrido = true`, `Activar_Estado("Euforia")`.
          - Tirada independiente 2 (`elif randf() < pr:`): → `Fiesta_Evento_Ocurrido = true`, `Activar_Estado("Resacon")`.
     4. Llama a `Tick_Estados()` (siempre, esté o no de fiesta, para que `Euforia` y `Resacon` cuenten sus 24 h).
     5. Comprueba `Comprobar_Muerte()` **después** de `Tick_Estados()` (verifica dónde se llama `Comprobar_Muerte()` en el bucle actual para mantener el orden exacto sin romper nada).

---

### 3.4. `Actividades_Necesidades_Basicas.gd` — Cap en `Cambiar_Necesidades_Basicas`

En `Cambiar_Necesidades_Basicas(valor, indice)`, justo después del bloque de bancarrota/calle:
```gdscript
if indice in [0, 1] and Variables_Dinamicas.Estados_Temporales.has("Resacon"):
    var cap_resacon = Actividades.Obtener_Cap_Resacon()
    if Variables_Dinamicas.Necesidades_Basicas[indice] > cap_resacon:
        Variables_Dinamicas.Necesidades_Basicas[indice] = cap_resacon
```
Así ninguna actividad (como Dormir o TV) ni ningún evento puede subir Salud Física o Mental por encima del techo actual del resacón.

---

### 3.5. Escena y UI — Botón, subtítulo, icono y handler

1. **`Escenas/Escena_Principal/Escena principal.tscn`**:
   - Añade un `Button` dentro de `Actividades/Elegir_Actividad/Tipos_De_Actividades/Temporales_Opciones/Necesidades_Basicas_Opciones` con el mismo formato/propiedades que los botones hermanos (`Dormir`, `Comer`, `Duchar`, `Ver_La_Television`):
     - Nombre del nodo: `Salir_De_Fiesta` (o el patrón exacto de los hermanos).
     - Texto: `"🎉  SALIR DE FIESTA"` (o el formato exacto que use `_Redisenar_Actividades()`).
   - Conecta su señal `pressed` al final del `.tscn` hacia `Actividad_Terminada_Salir_De_Fiesta` en `Script_Principal`.
   - Comprueba la altura total de `Necesidades_Basicas_Opciones` a 720×1280; si excede los 960 px del contenedor, añade `ScrollContainer` o ajusta la separación para que no quede ningún botón cortado.

2. **`Scripts/GUI/Escena_Principal/Estilos_UI.gd`**:
   - En `ICONOS_BOTONES`, añade:
     ```gdscript
     "Salir_De_Fiesta": "party-popper",
     ```

3. **`Scripts/Globales/Script_Principal.gd`**:
   - En `_SUBTITULOS_ACTIVIDADES`, añade:
     ```gdscript
     "Salir_De_Fiesta": "Noche · 2–12 h · Prob. según estado",
     ```
   - Implementa `Actividad_Terminada_Salir_De_Fiesta()` siguiendo el patrón exacto de `Actividad_Terminada_Dormir()` / `Crear_Actividad("Salir_De_Fiesta")`.
   - Al confirmar la franja en `Seleccionar_Horario` cuando la actividad seleccionada es `Salir_De_Fiesta`, valida primero con `Actividades.Validar_Horario_Fiesta(...)`; si no es válido, muestra el diálogo de error existente con el `motivo` concreto y no escribe en `Matriz_Jugador`.

---

### 3.6. `SeleccionarHorarioReloj.gd` — Vista previa de Fiesta

Cuando la actividad a programar es `Salir_De_Fiesta`:
- Muestra un panel de vista previa (creado en código o en la escena, estilizado con la paleta del proyecto y legible a 720×1280 sin desbordes).
- Se actualiza automáticamente cada vez que el jugador cambia día/hora/minuto de inicio o fin.
- Si `Validar_Horario_Fiesta(...)` devuelve `valido == false`:
  - Muestra el motivo de rechazo (en color de alerta, sin depender solo del color).
  - Oculta o no muestra las probabilidades.
- Si `valido == true`:
  - Llama a `Actividades.Simular_Preview_Fiesta(...)` y muestra:
    ```
    Salir de fiesta
    Duración: Xh YYm
    Por minuto: ligar X,XXX % al empezar · X,XXX % al terminar
    Por minuto: resacón X,XXX % al empezar · X,XXX % al terminar
    Ligar: XX,X % · Resacón: XX,X % · Nada: XX,X %
    Estimación según tus necesidades actuales y el desgaste previsto.
    ```
- Para cualquier otra actividad, el panel permanece oculto (`visible = false`).

---

### 3.7. `Necesidades_Basicas_GUI.gd` — Label de estado activo

- En el panel de Necesidades Básicas, añade un `Label` (o `PanelContainer` + `Label`) visible únicamente cuando `Variables_Dinamicas.Estados_Temporales` tiene un estado activo:
  - Si `"Euforia"`: `"Euforia · Xh YYm"` en color positivo (verde legible).
  - Si `"Resacon"`: `"Resacón · Xh YYm · límite CC"` en color negativo (rojo/ámbar legible), donde `CC = Actividades.Obtener_Cap_Resacon()`.
  - Si no hay estado activo: oculto (`visible = false`).
- Se actualiza cuando se actualiza la GUI de Necesidades Básicas (una vez por minuto de simulación / al abrir el panel; nunca en `_process`).

---

### 3.8. Tests GUT y documentación

1. Crea `Funcionalidades/Actividades/Actividades_Temporales/Tests/test_salir_de_fiesta.gd` siguiendo el patrón de `test_jerarquia.gd`. Debe cubrir **todos** los Criterios de Aceptación (`AC-01` a `AC-17`):
   - Registro en catálogo (`Salir_De_Fiesta`, `[0, 9, -3, -4, -2]`, `[0, 0, 0]`, P1, fuera del pool aleatorio `Actividades`).
   - Botón en escena, subtítulo e icono `party-popper`.
   - Ventana horaria: `17:59–06:00` rechazado; `18:00–06:00` aceptado (12 h); `18:00–19:59` rechazado (<2 h); `18:00–20:00` aceptado (2 h); `18:00–06:01` rechazado; `22:00–02:00` aceptado (cruce medianoche); `02:00–06:00` aceptado.
   - Fórmulas independientes:
     - Subir Higiene o Salud Mental o Académico sube `prob_ligar_min` y **no** cambia `prob_resacon_min`.
     - Bajar Hambre o Salud Física sube `prob_resacon_min`.
     - Subir Deporte sube `prob_ligar_min` y baja `prob_resacon_min`.
     - **Edad**: a los 20 años tiene mayor `prob_ligar_min` y menor `prob_resacon_min` que a los 60 años.
     - **Día de la semana**: Sábado (`dia_noche % 7 == 5`, `×1.45`) tiene mayor `prob_ligar_min` que Lunes (`0`, `×0.70`), y `02:00` de la madrugada del domingo sigue contando como noche de sábado; `prob_resacon_min` no cambia por el día.
     - Valores numéricos exactos de la tabla para el perfil estándar (`NB=80`, `NB=40`, etc.).
   - Vista previa: `Simular_Preview_Fiesta` devuelve `p_ligar + p_resacon + p_nada ≈ 1.0` y refleja el desgaste durante el bloque.
   - Máximo 1 evento por fiesta (incluidos dos bloques adyacentes).
   - Activación de `Euforia` (1440 min, primeras 8 h a 100 y bajada gradual 100→50 en las 16 h siguientes, mensaje) y `Resacon` (1440 min, primeras 8 h techo 30 y subida gradual 30→100 en las 16 h siguientes, mensaje).
   - Curva de cap de `Resacon`: `1440..960 -> 30`, `480 -> 65`, `0 -> 100`, bancarrota/calle -> `20`.
   - Curva de suelo de `Euforia`: `1440..960 -> 100`, `480 -> 75`, `0 -> 50`, bancarrota/calle -> `20`.
   - Tick de estados (descuenta 1/min, al llegar a 0 elimina y genera mensaje fin).
   - Persistencia: guardar/cargar conserva `Estados_Temporales` y `Fiesta_Evento_Ocurrido`; save antiguo carga con `{}` y `false`.
   - No regresión de actividades existentes ni jerarquía P1/P2/P3.

2. Ejecuta los tests GUT desde CLI (headless) y verifica que **todos** pasan (incluidos los tests existentes del proyecto).

3. Documentación:
   - Crea `Funcionalidades/Actividades/Actividades_Temporales/Documentacion/SALIR_DE_FIESTA.md` (y `.html` si el proyecto usa fichas duales) documentando fórmulas, estados, persistencia y UI.
   - Actualiza `CLAUDE.md` con la nueva actividad `Salir_De_Fiesta` y los nuevos campos de `Variables_Dinamicas` / `Variables_Estaticas`.

---

## 4. Formato del informe final

Cuando termines, entrega un informe conciso con:
1. Archivos creados y modificados.
2. Resultado exacto de la suite GUT (tests totales, pasados, fallados).
3. Verificación visual/estructural de la UI a 720×1280.
4. Cualquier desviación o detalle relevante encontrado durante la implementación.
