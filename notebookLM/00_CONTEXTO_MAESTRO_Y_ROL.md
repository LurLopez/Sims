# CONTEXTO MAESTRO DEL PROYECTO: SIMS 0.33 ("Sims Life")

> **Uso:** Sube este archivo como fuente en **NotebookLM** o pégalo al inicio de tu **chat de Chrome** para planificar nuevas funcionalidades con conocimiento del 100 % del proyecto y generar prompts cerrados para Antigravity.
> **Mantenimiento:** Este archivo debe actualizarse cada vez que se implemente o documente una nueva funcionalidad (variables, actividades, autoloads, escenas, fórmulas, sistemas y roadmap).

Actúa como **Game Designer Senior y Arquitecto de Godot 4.4 (GDScript 2.0)** especializado en el proyecto **SIMS 0.33** (`/home/lur/sims-0.33`).
Tu objetivo es **planificar, diseñar y especificar al 100 % nuevas funcionalidades** conmigo en este chat para ahorrar al máximo el uso de Antigravity. Cuando cerremos un diseño, generarás un **Prompt de Implementación cerrado** para que Antigravity solo tenga que leer los archivos exactos, programar, pasar tests y entregar el informe.

---

## 1. Visión General del Juego y Escala Temporal
- **Género:** Simulador de vida simplificado tipo BitLife / Los Sims para **Android** (`720×1280` portrait, renderer `mobile`, `stretch/mode="canvas_items"`, `stretch/aspect="expand"`, `pointing/emulate_touch_from_mouse=true`).
- **Motor:** Godot 4.x (`config/features=PackedStringArray("4.7", "Mobile")`, GDScript válido para Godot 4.4+).
- **Escena de arranque:** `res://Escenas/Menu/Menu.tscn`.
- **Tema global:** `res://UI/Tema_Principal.tres`.
- **Escala de tiempo real:**
  - El juego avanza en **minutos Unix reales**. `Script_Principal._process` calcula cuántos minutos reales han pasado desde el último tick y llama a `Actividades.Actualizar_Horario(minutos_a_procesar)`.
  - Cada día tiene **1440 minutos** (`0..1439`). La vida máxima cubre **574 días** (`0..573`, ~82 semanas).
  - **Modo normal (`Variables_Estaticas.Modo_Rapido == false`):**
    - **1 semana real (7 días) = 1 año de juego** (`Dias_Por_Anio() = 7`).
    - Edad = `18 + int(max(0, dia - First_Time_Minute_Day) / 7.0)` (de 18 a ~100 años en 574 días, ~82 años de partida).
    - Capital inicial: `1000€`. Alquiler semanal: `200€`.
  - **Modo rápido (`Variables_Estaticas.Modo_Rapido == true`):**
    - **1 día real = 1 año de juego** (`Dias_Por_Anio() = 1`).
    - Multiplicador de precios: `0.1` (alquiler `20€`, objetos y matrículas ×0.1, bonus carrera ×0.1).
    - Capital inicial: `100€`.
    - Multiplicador de salario: `10.0 / 7.0` por hora (para compensar que 1 año dura 1 día en lugar de 7).
    - En trabajos (`Trabajo.gd`), empieza al día siguiente (`Minute_Day + 1`) y trabaja todos los días (no filtra `dias_laborales`).

---

## 2. Reglas Técnicas Inviolables
1. **GDScript 2.0 (Godot 4.4+):** Prohibida sintaxis de Godot 3. Usar tipado explícito en funciones nuevas.
2. **Autoloads globales:** Se usan directamente por su nombre global (sin `get_node` ni `preload` para ellos, salvo excepciones puntuales existentes). Las clases con `class_name` también son globales.
3. **Comparación segura de celdas en `Matriz_Jugador`:** Las celdas pueden contener `String` (`""` o `"Actividad_Aleatoria"`), `null`, o un objeto `Actividad`. **Nunca** comparar un objeto `Actividad` directamente contra `String` sin filtrar antes (`if celda is String and celda == "..."` o `if celda is Actividad_Fija_Trabajo and celda == actividad`).
4. **Referencias en `Matriz_Jugador`:** Las celdas programadas deben guardar **referencias al mismo objeto** de `Variables_Estaticas.Catalogo_Actividades`, porque la GUI y la lógica comparan por referencia.
5. **Rutas de recursos:** `res://...` relativo a la raíz del proyecto.
6. **Claves ASCII estables:** Sin tildes ni espacios en claves de `Catalogo_Actividades`, `Catalogo_Objetos` o diccionarios de guardado.
7. **Rendimiento O(1) por minuto:** Nada de escaneos completos de `Matriz_Jugador` ni trabajo pesado en `_process`.
8. **Compatibilidad hacia atrás en saves:** Cualquier campo nuevo en `Variables_Dinamicas` debe tener fallback seguro en `Guardar_Variables_Dinamicas.load_game()` usando `.get("clave", default)` o `if game_data.has(...)`.
9. **Resolución 720×1280 portrait:** Toda UI nueva debe caber en 720px de ancho sin desbordarse ni cortarse. Con `stretch/aspect="expand"` el alto visible crece en móviles alargados (p. ej. 720×1600); los fondos, el dock inferior y las secciones deben usar `_Alto_Pantalla()` (alto real del viewport) en vez de 1280 fijo, y recolocarse en `get_viewport().size_changed`.
10. **Orientación Android:** `display/window/handheld/orientation` debe ser el entero `1` (Portrait). El exportador hace `int()` del valor; el string `"portrait"` se convierte en `0` (Landscape).

---

## 3. Autoloads (Singletons en `project.godot`)
1. `Variables_Dinamicas` (`Scripts/Globales/Principales_Variables/Variables_Dinamicas.gd`) — Estado mutable de la partida.
2. `Variables_Estaticas` (`Scripts/Globales/Principales_Variables/Variables_Estaticas.gd`) — Constantes, catálogos y configuración fija de partida.
3. `Guardar_Variables_Dinamicas` (`Scripts/Otro/Guardar/Guardar_Variables_Dinamicas.gd`) — Save/Load binario de estado dinámico.
4. `Guardar_Variables_Estaticas` (`Scripts/Otro/Guardar/Guardar_Variables_Estaticas.gd`) — Save/Load binario de estado estático.
5. `Funciones_Globales` (`Scripts/Globales/Funciones_Globales.gd`) — Utilidades de tiempo, matriz, aleatorios y logs debug (`user://guardado/otros/`).
6. `Trabajo` (`Scripts/Logica/Escena_Principal/Actividades/Trabajo/Trabajo.gd`) — Contratación y abandono/cancelación de trabajos.
7. `Actividades_Habilidades` (`Scripts/Logica/Escena_Principal/Actividades/Actividades_Habilidades.gd`) — Fórmulas de Progreso y Descubrimiento de habilidades.
8. `Actividades_Necesidades_Basicas` (`Scripts/Logica/Escena_Principal/Actividades/Actividades_Necesidades_Basicas.gd`) — Aplicación de efectos a necesidades, multiplicadores de objetos y cap de bancarrota.
9. `Sistema_Examenes` (`Scripts/Logica/Escena_Principal/Actividades/Carreras/Sistema_Examenes.gd`) — Progreso de carrera, matrículas y cálculo de exámenes semanales.
10. `Actividades` (`Scripts/Logica/Escena_Principal/Actividades/Actividades.gd`) — Bucle principal minuto a minuto (`Actualizar_Horario`), ejecución de actividades, alquiler, tienda, bolsa y muerte.
11. `Alimentacion` (`Scripts/Logica/Escena_Principal/Actividades/Alimentacion.gd`) — Cocina, tuppers, caducidad, intoxicación, comida rápida y selección de comida de la IA.
12. `Eventos_Aleatorios` (`Scripts/Logica/Escena_Principal/Actividades/Eventos_Aleatorios.gd`) — Despido por higiene y 20 eventos generales con franja horaria.
13. `Gestionar_Visibilidad` (`Scripts/GUI/Escena_Principal/Gestionar_Visibilidad.gd`) — Control de pantallas/paneles en `Escena principal.tscn`.
14. `Debug_Cargar_Guardado` (`Scripts/Otro/Debug/Debug_Cargar_Guardado.gd`) — Utilidades de debug.

---

## 4. Arquitectura de Escenas, Nodos y UI

### Escenas principales (`.tscn`)
1. **`Escenas/Menu/Menu.tscn`** (`Scripts/Globales/Menu.gd`):
   - Carga saves al arrancar. Si `Variables_Dinamicas.Muerto == true`, muestra Game Over.
   - Gestiona creación de nueva partida (`Intro_Nueva_Partida.gd`, `Creador_Personaje.gd`), selección de modo normal/rápido, apariencia y personalidad.
2. **`Escenas/Escena_Principal/Escena principal.tscn`** (`Scripts/Globales/Script_Principal.gd`):
   - **Nodos de primer nivel:**
     - `Top_Bar_Panel`, `Moneda`, `Dinero_Label`, `Boton_Perfil`, `Economia_Button`, `Calendario_Button`, `Carrera_Button`, `Tienda_Button` (oculto por defecto).
     - `Barra_Abajo` → `Boton_Habilidades`, `Boton_Progreso`, `Boton_Actividades`, `Boton_Necesidades_Basicas`.
     - `Fondo`, `Progreso` (oculto), `Necesidades_Basicas`, `Trabajo` (oculto), `Habilidades` (oculto).
     - `Actividades`: contiene `Elegir_Actividad/Tipos_De_Actividades/Temporales_Opciones/[Necesidades_Basicas_Opciones|Progreso_Opciones]`, `Horario_Semanal/[OPCIONES_CALENDARIO|Cabezal_horario|Mover_Vertical/Todo calendario/Dias]`, `Seleccionar_Horario/[Inicio|Final|Cancelar|Crear_Actividad]`.
     - `Tienda` (instancia de `Tienda.tscn`): `Flecha_Atras`, `Categorias/[Tab_Dormir|Tab_Comer|Tab_Duchar]`, `Objetos_Dormir/...`, `Objetos_Comer/Mesa_Basica`, `Objetos_Duchar/...`.
     - `Pantalla_Mensajes` (instancia de `Pantalla_Mensajes.tscn`): `Tab_Bar/[Tab_Mensajes|Tab_Info|Tab_Apuntes|Tab_Despensa]`, `Panel_Info`, `Panel_Apuntes`, `Panel_Despensa/Scroll_Tuppers/VBox_Tuppers`, `Lista_Mensajes`, `Contenido_Mensaje`.
   - **Modales dinámicos:** Creados/instanciados desde código (`Modal_Seleccionar_Carrera.gd`, `Modal_Seleccionar_Examen.gd`, `Modal_Examen.gd`, `Lector_Libros.gd`, `Lector_Libro.gd`, `Tutorial_Inicial.gd`).
   - **Escenario visual:** `Escenario_Actividad.gd`, `Personaje_Visual.gd`, `Apariencia_Personaje.gd`.

### Sistema de Diseño UI (`Scripts/GUI/Escena_Principal/Estilos_UI.gd`)
- Paleta unificada estilo BitLife: `FONDO` (`#efeff4`), `SUPERFICIE` (`#ffffff`), `ROJO_BIT` (`#d62828`), `EXITO` (`#1ea34a`), `AVISO` (`#f59e0b`), `PELIGRO` (`#dc2626`), `AZUL` (`#1d7afc`), `INDIGO` (`#4f46e5`), `MORADO` (`#7c3aed`), `NAVY` (`#182234`), `TINTA` (`#111827`).
- Fuentes en `Fuentes/UI/`: `DMSans` (400/500/600/700), `Bricolage`, `Fraunces`, `Manrope`, `Mulish`, `RussoOne`, `TitanOne`.
- Iconos SVG en `Imagenes/UI/Iconos/` mapeados en `Estilos_UI.ICONOS_BOTONES`.

### Dónde añadir elementos comunes en UI
- **Nuevo objeto en Tienda:** `Tienda.tscn` (copiar bloque existente), conexiones al final de `Escena principal.tscn`, registrar en `Variables_Estaticas._Inicializar_Catalogo_Objetos()`.
- **Nueva actividad temporal:** botón en `Escena principal.tscn` dentro de `Necesidades_Basicas_Opciones` o `Progreso_Opciones`, registrar en `Variables_Estaticas._Inicializar_Catalogo()`, añadir subtítulo/icono en `Script_Principal.gd` / `Estilos_UI.gd` y handler de botón.
- **Nuevo trabajo de nómina:** botón en `Trabajo/Actividades_Trabajo_Nomina_Opciones`, registrar `Actividad_Fija_Trabajo` en `Variables_Estaticas.gd`, helper en `Trabajo.gd` y verificación de requisitos en `Script_Principal._Cumple_Requisitos_Trabajo()`.

### Build Android (APK)
- **Compilar:** `./exportar_apk.sh` (debug) o `./exportar_apk.sh --release`; `--instalar` instala por ADB. Salida: `build/sims-0.33.apk` (arm64-v8a).
- **Orientación:** `display/window/handheld/orientation=1` (int, Portrait). Un string `"portrait"` se interpreta como `0` (Landscape) al exportar.
- **Pantalla completa:** `screen/immersive_mode=true` en `export_presets.cfg` → `--fullscreen` al arrancar. `screen/edge_to_edge=false`.
- **Splash sin logo de Godot:** `application/boot_splash/show_image=false` + `splash_screen/disable_godot_boot_splash=true` en el preset.
- **Iconos:** `Iconos_Android/` (192, adaptativo frente/fondo/monocromo 432, splash 512) generados desde `icon.svg` con `Scripts/Otro/Herramientas/Generar_Iconos_Android.gd`.

---

## 5. Modelo de Datos Completo

### `Variables_Dinamicas` (`user://guardado/variables/Guardar_Variables_Dinamicas.dat`)
- `Matriz_Jugador`: Array 2D `[1440][574]`. Cada celda es `""`, `"Actividad_Aleatoria"`, o referencia a un objeto `Actividad`. En disco se serializa con compresión **RLE** (`formato: "rle"`).
- `Minute_Day` (int, `0..573`), `Minute_Minute` (int, `0..1439`), `Minute` (int, minuto Unix).
- `Necesidades_Basicas`: Array de 5 ints (`1..100`):
  - `[0]` Salud Física
  - `[1]` Salud Mental
  - `[2]` Hambre
  - `[3]` Descanso
  - `[4]` Higiene
- `Progreso`: Array de 3 ints/floats (`1..100`):
  - `[0]` Deporte
  - `[1]` Académico
  - `[2]` Manualidades
- `Progreso_Cocina`: int (`1..100`), destreza culinaria; sube cocinando y no decae.
- `Tuppers`: Array de diccionarios `{id, porcentaje_restante, calidad, minuto_creacion, minuto_caducidad}`. Un tupper completo = 30 min (3,333 %/min).
- `Tupper_Seleccionado_Idx`: int (`-1` = automático).
- `Minutos_Cocinando_Actuales`: int volátil (no se guarda).
- `Habilidades_Mostradas`: Array de **7 ints** (`0..100`), uno por cada habilidad innata. Solo sube; se detiene al alcanzar `Variables_Estaticas.Habilidades[i]`.
- `Dinero`: float.
- `En_La_Calle`: bool (`true` si no pudo pagar alquiler).
- `Ultima_Fecha_Alquiler`: int (minuto absoluto `Minute_Day * 1440 + Minute_Minute` del último pago, o `-1` si está en la calle).
- `Trabajo_Actual`: `Actividad_Fija_Trabajo` o `null`.
- `Objetos_Poseidos`: Dictionary `{clave_objeto: bool}`.
- `Objeto_Seleccionado`: Dictionary `{nombre_actividad: clave_objeto}` (para `"Dormir"`, `"Comer"`, `"Duchar"`).
- `Carrera_Actual`: instancia de `Carrera` o `null`.
- `Carreras_Completadas`: Array de `Carrera`.
- `Inicio_Semana_Carrera`: int (`-1` si no aplica).
- `Mensajes`: Array de objetos `Mensaje` (`titulo`, `descripcion`, `leido`, `minuto`).
- `Estados_Temporales`: Dictionary `{ "Euforia"|"Resacon"|"Intoxicacion": minutos_restantes }`. Euforia y Resacón son mutuamente excluyentes; Intoxicación puede convivir con ellos. Todos duran 1440 min (480 de meseta + 960 de bajada).
- `Fiesta_Evento_Ocurrido`: bool. `true` si ya ocurrió un evento (ligar o resacón) en el bloque de fiesta actual.
- `Esta_Invirtiendo`: bool, `Dinero_Invertido`: float, `Valor_Inversion`: float, `Salud_Mental_Al_Invertir`: int (snapshot al invertir), `Progreso_Inversion`: int (`1..100`).
- `Cooldown_Trabajos`: Dictionary `{nombre_trabajo: minuto_fin_cooldown}`.
- `Muerto`: bool, `Edad_Muerte`: int, `Prob_Supervivencia_Acumulada`: float.

### `Variables_Estaticas` (`user://guardado/variables/Guardar_Variables_Estaticas.dat`)
- Constantes: `ALQUILER_SEMANAL = 200`, `BANCARROTA_MAX_NECESIDAD = 20`, `COSTE_COCINAR_BASE = 2.0`, `COSTE_COMIDA_BASURA_BASE = 2.0`, `DIAS_CADUCIDAD_TUPPER = 3`, `MINUTOS_POR_TUPPER = 15`, `MINUTOS_COMIDOS_POR_TUPPER = 30`.
- `First_Time`: bool, `Modo_Rapido`: bool, `Tutorial_Completado`: bool.
- `First_Time_Minute`, `First_Time_Minute_Day`, `First_Time_Minute_Minute`, `First_Time_Year`, `First_Time_Month`, `First_Time_Day_Of_Month`.
- `Personalidad`: `"Trabajador_Compulsivo"` | `"Deportista"` | `"Culo_Del_Sofa"`.
- `Apariencia`: Dictionary.
- `Habilidades`: Array de **7 ints innatos secretos** (`1..100`) generados al crear el personaje:
  - `[0]` Deporte
  - `[1]` Inteligencia
  - `[2]` Destreza manual
  - `[3]` Memoria
  - `[4]` Liderazgo
  - `[5]` Paciencia
  - `[6]` **Sangre Fría** (usada en exámenes académicos y auto-venta por pánico en bolsa).
- `Catalogo_Actividades`: Dictionary `{nombre: Actividad}` (no se guarda, se reconstruye en `_ready()`).
- `Estados_Temporales`: Dictionary con las definiciones de `Euforia`, `Resacon` e `Intoxicacion` (duración, meseta, curvas, índices, títulos y mensajes de inicio/fin).
- `Actividades`: Array de 6 actividades elegibles para relleno aleatorio cuando una celda está vacía. `Cocinar`, `Comer_Tupper` y `Comer_Basura` quedan fuera del pool.
- `Catalogo_Objetos`: Dictionary `{clave: Objeto}`.

---

## 6. Mecánicas y Fórmulas Exactas de Todos los Sistemas

### A. Ejecución Minuto a Minuto (`Actividades.Actualizar_Horario`)
Por cada minuto transcurrido:
1. Si `Minute_Day >= 574` → muerte inmediata.
2. Lee `celda = Matriz_Jugador[Minute_Minute][Minute_Day]`:
   - Si es `""` o `null`: la marca como `"Actividad_Aleatoria"` y ejecuta `Crear_Actividad_Aleatoria()` con `es_aleatoria = true`.
   - Si es `"Actividad_Aleatoria"`: ejecuta `Crear_Actividad_Aleatoria()` con `es_aleatoria = true`.
   - Si es un objeto `Actividad`: ejecuta `Ejecutar_Actividad(celda, false)`.
3. **Fiesta:** si la celda es `Salir_De_Fiesta`, comprueba `Es_Primer_Minuto_Del_Bloque`; si es el primero, `Fiesta_Evento_Ocurrido = false`. Tras aplicar los efectos del minuto, si no ha ocurrido un evento, `Resolver_Evento_Fiesta()` tira ligar (primero) y resacón.
4. **Actividad aleatoria (`Crear_Actividad_Aleatoria`):**
   - Busca la necesidad básica más baja. Si `< 30`, elige la actividad que la recupera (`0→Salir_A_Correr`, `1→Ver_La_Television`, `2→Alimentacion.Elegir_Comida_IA()`, `3→Dormir`, `4→Duchar`). Para Hambre, la IA usa tupper vigente, comida rápida si hay dinero, tupper caducado como último recurso o `Ver_La_Television` si no puede comer.
   - Si todas `>= 30`, tiene 50 % de probabilidad de elegir la actividad favorita de `Personalidad` (`Trabajador_Compulsivo→Estudiar`, `Deportista→Salir_A_Correr`, `Culo_Del_Sofa→Ver_La_Television`) y 50 % de elegir una al azar de `Variables_Estaticas.Actividades`.
   - **Importante:** cuando `es_aleatoria == true`, **solo** aplica Necesidades Básicas; **no** da Progreso, **no** revela Habilidades y **no** avanza la Carrera.
5. Llama a `Eventos_Aleatorios.Tick_Eventos(celda)`.
6. Llama a `Tick_Estados()`: aplica Euforia/Resacón con el contador actual y descuenta 1 min. Si llega a 0, elimina el estado y añade el mensaje de fin.
7. Avanza `Minute_Minute`, `Minute_Day`, `Minute`.
8. Si `Esta_Invirtiendo`: llama a `_Tick_Inversion()`.
9. Si `not En_La_Calle` y `Ultima_Fecha_Alquiler >= 0`: si `Minute - Ultima_Fecha_Alquiler >= Dias_Por_Anio() * 1440` → `Cobrar_Alquiler()`.
10. Si `Carrera_Actual != null`: gestiona conversión de prematrícula a matrícula (Lunes 00:00 en modo normal, 00:00 del día elegido en modo rápido) y disparo del examen al terminar su bloque de 60 min.
11. Llama a `Comprobar_Muerte()` (después de `Tick_Estados`).

### B. Necesidades Básicas y Objetos (`Actividades_Necesidades_Basicas.gd`)
- Frecuencias base por índice: `[30, 30, 12, 15, 20]` (Salud Física 30, Salud Mental 30, Hambre 12, Descanso 15, Higiene 20).
- Para cada necesidad cuyo efecto `por_cuanto != 0`:
  - `valor_maximo = floor(frecuencia / abs(por_cuanto))`
  - Si `por_cuanto > 0` y la actividad es `"Dormir"` o `"Duchar"`, se divide por el `multiplicador` del objeto seleccionado: `valor_maximo = max(1, floor(valor_maximo / multiplicador))`. Las mesas ya no afectan a comer.
  - Con probabilidad `1 / valor_maximo` (cuando `randi() % valor_maximo == 0`), suma o resta `1` a `Necesidades_Basicas[indice]` (rango `1..100`).
- **Penalización de calle / bancarrota:** si `En_La_Calle == true` o `Dinero < 0`, cualquier necesidad por encima de `BANCARROTA_MAX_NECESIDAD` (`20`) se recorta a `20`.

### C. Progreso Volátil y Descubrimiento de Habilidades (`Actividades_Habilidades.gd`)
- **Combinaciones ponderadas de habilidades innatas para Progreso:**
  - Deporte (`[0]`): `50*Deporte + 40*Liderazgo + 10*Memoria`
  - Académico (`[1]`): `50*Inteligencia + 20*Paciencia + 30*Memoria`
  - Manualidades (`[2]`): `50*Destreza + 30*Paciencia + 10*Memoria + 10*Liderazgo`
- **Fórmula exponencial de dificultad:**
  ```gdscript
  potencia1 = (30 + valor_actual) / 100.0
  potencia2 = 15000 / float(5000 + suma_habilidad)
  max_val = floor(por_cuanto_ecuacion * (8 ** potencia1) ** potencia2)
  ```
  - Para **Progreso**: `por_cuanto_ecuacion = 20`, `max_ajustado = floor(max_val / por_cuanto_efecto)`, probabilidad `1 / max_ajustado` de sumar `+1` (tope `100`).
  - Para **Descubrimiento (`Habilidades_Mostradas[i]`)**: usa la misma fórmula con `valor_actual = Habilidades_Mostradas[i]`, `suma_habilidad = 5000`, `por_cuanto_ecuacion = 8`, `max_ajustado = max(1, floor(max_val * 100.0 / (por_cuanto_efecto * peso_porcentaje)))` y se detiene al llegar al valor innato `Variables_Estaticas.Habilidades[i]`.

### D. Catálogo de Actividades y Jerarquía de Prioridades
Clases en `Scripts/Logica/Escena_Principal/Actividades/Herencia/`:
- `Actividad` (Prioridad **P1**): base.
- `Actividad_Temporal` (P1):
  - `Dormir`: NB `[1, 1, -1, 4, -1]`, Prog `[0,0,0]`
  - `Cocinar`: NB `[-1, 1, -2, -2, -2]`, Prog `[0,0,0]` (produce tuppers y sube `Progreso_Cocina`; ver D3)
  - `Comer_Tupper`: NB `[1, 2, 20, -1, -1]`, Prog `[0,0,0]` (física/mental moduladas por calidad)
  - `Comer_Basura`: NB `[-2, 2, 20, -1, -1]`, Prog `[0,0,0]`
  - `Duchar`: NB `[1, 1, -1, -1, 20]`, Prog `[0,0,0]`
  - `Ver_La_Television`: NB `[-1, 5, -1, 2, -1]`, Prog `[0,0,0]`
  - `Estudiar`: NB `[-1, -2, -1, -2, -1]`, Prog `[0, 4, 0]` (también avanza `Carrera_Actual` si hay una activa)
  - `Salir_A_Correr`: NB `[4, 2, -3, -3, -4]`, Prog `[4, 0, 0]`
  - `Practicar_Manualidades`: NB `[-2, -1, -1, -2, -1]`, Prog `[0, 0, 4]`
  - `Salir_De_Fiesta`: NB `[0, 9, -3, -4, -2]`, Prog `[0, 0, 0]`. P1, **fuera del pool aleatorio**; ventana 18:00–06:00, 2–12 h.
- `Actividad_Carrera` (`Estudiar_Carrera`, P1): NB `[-1, -2, -1, -2, -1]`, avanza `Carrera_Actual.progreso_actual`.
- `Actividad_Examen` (`Examen_Carrera`, Prioridad **P3** máxima): NB `[-1, -3, -1, -3, -1]`, bloque de 60 min.
- `Actividad_Fija` → `Actividad_Fija_Trabajo` (Prioridad **P2**):
  - Paga el salario completo al cruzar el último minuto de la jornada (`Minute_Minute == hora_final - 1`): `Obtener_Salario_Hora(actividad) * ((hora_final - hora_inicio) / 60.0)`.
  - `Trabajar_En_Comida_Rapida`: 8–16h, `10.0€/h`, sin requisitos.
  - `Trabajar_De_Carpintero`: 7–15h, `18.0€/h`, Manualidades ≥ 30.
  - `Trabajar_De_Cientifico`: 9–17h, `28.0€/h`, Académico ≥ 65, carrera `Ingenieria_Informatica`.
  - `Trabajar_De_Abogado`: 9–17h, `30.0€/h`, Académico ≥ 50, carrera `Derecho`.
  - `Trabajar_De_Medico`: 9–17h, `35.0€/h`, Académico ≥ 60, carrera `Medicina`.
  - `Trabajar_De_Artista`: 9–17h, `25.0€/h`, Manualidades ≥ 50, carrera `Bellas_Artes`.
  - `Trabajar_De_Ayudante_Cocina`: 11–19h, `17.0€/h`, `requisito_cocina = 30`.
  - `Trabajar_De_Cocinero_Partida`: 12–20h, `24.0€/h`, `requisito_cocina = 60`.
  - `Trabajar_De_Chef_Ejecutivo`: 13–21h, `36.0€/h`, `requisito_cocina = 85`.
  - `Actividad_Fija_Trabajo` incorpora `requisito_cocina: int = 0`, validado en `Script_Principal._Cumple_Requisitos_Trabajo()`.

### D2. Salir de Fiesta (`Salir_De_Fiesta`)
- Actividad `Actividad_Temporal` P1, color `Color(0.85, 0.15, 0.45)`, NB `[0, 9, -3, -4, -2]`, Prog `[0, 0, 0]`. **No** está en `Variables_Estaticas.Actividades`.
- Ventana: inicio 18:00–04:00, fin 20:00–06:00, duración 120–720 min. Cruce de medianoche por horas; domingo(6) → lunes(0) se normaliza a `dia_inicio + 1` para `_Calcular_Rango`. Con `semana`, el día final absoluto no puede superar 573.
- Por minuto, tras aplicar los efectos de la fiesta:
  - `puntaje_ligar = clamp(50 + 0.30*(Mental-50) + 0.25*(Higiene-50) + 0.20*(Deporte-50) + 0.15*(Académico-50) + 0.10*(Descanso-50) + mod_personalidad + mod_edad, 0, 100)`.
  - `prob_ligar = (0.00001 + 0.00099 * puntaje_ligar / 100) * mult_dia`. `mod_edad = clamp(10 - (edad-20)*0.625, -25, 12)`. Personalidad: Deportista +10, Culo_Del_Sofa −10, Trabajador_Compulsivo −5.
  - `mult_dia`: L–X 0.70, J 1.00, V 1.25, S 1.45, D 0.80. La noche pertenece al día de inicio; **las 06:00 cuentan como el día anterior**.
  - `aguante_resacon = clamp(50 + 0.40*(Hambre-50) + 0.30*(Descanso-50) + 0.20*(Física-50) + 0.10*(Deporte-50) + mod_edad, 0, 100)`; `prob_resacon = 0.00001 + 0.00099 * (100-aguante)/100`.
  - Tirada: primero ligar; si no, resacón. `Fiesta_Evento_Ocurrido` limita a un evento por bloque (dos bloques adyacentes cuentan como uno).
- Estados mutuamente excluyentes, 1440 min (480 de meseta + 960 de bajada):
  - `Euforia`: suelo de Salud Mental 100 → 50; al activarse sube a 100 (20 en calle/bancarrota). `suelo = floor(100 - progreso*50)`.
  - `Resacon`: techo de Salud Física/Mental 30 → 100; al activarse recorta a 30 (20 en calle/bancarrota). `cap = 30 + floor(progreso*70)`. `Cambiar_Necesidades_Basicas` aplica el cap a índices 0 y 1.
  - `Tick_Estados()` aplica el efecto, descuenta 1 y al llegar a 0 elimina el estado y añade el mensaje de fin. Se ejecuta siempre.
  - Mensajes en `Variables_Dinamicas.Mensajes` con `leido = false` (badge del perfil): `Has ligado`, `Resacón`, `Fin de la euforia`, `Fin del resacón`.
- Vista previa pura `Simular_Preview_Fiesta`: proyecta NB con `delta = signo(efecto) * min(1, abs(efecto)/frecuencia)` y acumula riesgos competitivos. `p_ligar + p_resacon + p_nada = 1`.
- UI: botón `Necesidades_Basicas_Opciones/Salir_De_Fiesta` (`party-popper`, `Noche · 2–12 h · Prob. según estado`), flujo de dos pasos para reabrir `Seleccionar_Horario` con preview, panel `Preview_Fiesta` (688×584 en y=174) y label `Estado_Temporal_Label` en `Resumen_Necesidades`.
- Persistencia: `Estados_Temporales` y `Fiesta_Evento_Ocurrido` en el save dinámico, con fallback `{}`/`false`, filtrado de claves y saneado de ambos estados.
- Tests: `Funcionalidades/Actividades/Actividades_Temporales/Tests/test_salir_de_fiesta.gd` y `test_cocina_y_alimentacion.gd` (suite de Actividades Temporales).

### D3. Cocina, Tuppers y Alimentación Dual (`Alimentacion.gd`)
- **Actividades:** `Cocinar`, `Comer_Tupper`, `Comer_Basura` (P1, fuera del pool aleatorio). La antigua `Comer` gratuita se elimina del catálogo; las celdas `"Comer"` de saves antiguos se migran a `"Comer_Basura"` al cargar.
- **Costes:** `2 € * Multiplicador_Precios()` por ciclo de 15 min de cocina y por cada cobro de 5 min de comida rápida. Caducidad: 3 días (normal) / 1 día (rápido).
- **Cocinar:**
  - Requiere `En_La_Calle == false` y ≥ 15 min. Si el bloque ya estaba programado y el personaje se queda en la calle, se cancela al ejecutar.
  - Cada minuto: `suma = 40*Destreza + 25*Paciencia + 20*Sangre_Fría + 15*Memoria`; `max_val = floor(20 * (8^((30+Progreso_Cocina)/100))^(15000/(5000+suma)))`; con probabilidad `1/max_val`, `Progreso_Cocina += 1` (tope 100). También descubre habilidades con pesos 40/25/20/15.
  - Cada 15 min: descuenta el coste y crea un tupper al 100 % con `calidad = Progreso_Cocina`, `minuto_creacion = Minute` y `minuto_caducidad = Minute + dias*1440`.
  - Si `Dinero < coste` o `En_La_Calle`, se limpia el bloque actual y las celdas contiguas futuras, se resetea el contador y se envía un mensaje.
  - `Minutos_Cocinando_Actuales` se resetea en cualquier minuto que no sea `Cocinar`.
- **Comer_Tupper:**
  - 1 tupper = 30 min; `porcentaje_restante -= 100/30` por minuto.
  - Selección manual (`Tupper_Seleccionado_Idx`) o automática: vigentes primero (ya empezados y caducidad más cercana), luego el menos caducado.
  - Efectos: física `+1/+2/+3` según calidad `1–30/31–70/71–100`; mental `+2` (`+3` si calidad > 60); hambre `20` (frecuencia 12); descanso/higiene `-1`.
  - Al agotarse se elimina y se reinicia la selección. Si quedan tuppers, encadena; si no, el resto del bloque pasa a `Comer_Basura` (cobrando). Si empieza sin tuppers, también pasa a basura.
- **Intoxicación:** si `Minute > minuto_caducidad`, `p30 = clamp(horas_caducado/48, 0.05, 1.0)`; `p_min = 1 - (1-p30)^(1/30)`. Si dispara y no está activo, `Estados_Temporales["Intoxicacion"] = 1440` (techo 30→100 a índices 0 y 1; 20 en calle/bancarrota).
- **Comer_Basura:** cobra cada 5 min (`Minute_Minute % 5 == 0`); si no hay saldo, cancela y limpia el bloque. Efectos `[-2, 2, 20, -1, -1]`.
- **IA:** tupper vigente → `Comer_Tupper`; si no, basura si hay dinero; si solo hay caducados y no hay dinero, tupper (riesgo); si no, `Ver_La_Television`. Nunca comida gratis.
- **UI:** botón `🍳 COCINAR` en Necesidades; el reloj de `Comer` tiene pestañas `📦 Comida casera` / `🍔 Comida rápida` con vista previa de coste/calidad/caducidad; pestaña `Despensa` en el Perfil; modal `Modal_Tuppers.gd`; indicador `🍱 N` junto a Hambre; `Progreso_Cocina` en Perfil/Info y cuarta barra del panel Progreso.
- **Persistencia:** `Progreso_Cocina`, `Tuppers` y `Tupper_Seleccionado_Idx`; `Minutos_Cocinando_Actuales = 0` al cargar. Saves antiguos usan `1`, `[]`, `-1`.
- **Tests:** `Funcionalidades/Actividades/Actividades_Temporales/Tests/test_cocina_y_alimentacion.gd` (TC-01 a TC-11 + integración UI).

### E. Tienda y Objetos (`Variables_Estaticas.gd` / `Actividades.gd`)
- Categorías: `Dormir` (`Cama_Basica` 0€/×1.0, `Cama_Premium` 200€/×1.05, `Cama_Lujo` 800€/×1.10), `Comer` (`Mesa_Basica`, sin multiplicador), `Duchar` (`Ducha_Basica`, `Ducha_Premium`, `Ducha_Lujo`). `Mesa_Premium` fue retirada.
- Venta: devuelve el **50 %** del precio actual (`precio * 0.5`). No se puede vender si es el único objeto poseído de su categoría ni si está seleccionado actualmente.

### F. Inversión en Bolsa (`Actividades._Tick_Inversion`)
- Se evalúa cada minuto si `Esta_Invirtiendo == true`: dispara evento de mercado con probabilidad `1/480` (~3 veces/día).
- `prob_subida = clamp(0.15 + ((Progreso_Inversion - 1.0) / 99.0) * 0.70 + ((Salud_Mental_Al_Invertir - 50.0) / 300.0), 0.05, 0.95)`.
- Variación por evento: entre `0.5%` y `3.0%`.
- **Auto-venta por pánico:** si `Habilidades[6]` (`Sangre_Fría`) `< 30` y las pérdidas superan el `15%`, vende automáticamente y envía un `Mensaje`.
- `Progreso_Inversion` sube en +1 con probabilidad `1/20` en cada evento de mercado (máximo 100).

### G. Carreras Universitarias y Exámenes (`Sistema_Examenes.gd`)
- 4 carreras: `Ingenieria_Informatica` (4 años), `Derecho` (4 años), `Bellas_Artes` (4 años) y `Medicina` (5 años).
- Cada año desbloquea apuntes (`apuntes_<carrera>_anio<N>.txt`) visibles en Perfil → Apuntes y preguntas (`preguntas_<carrera>.json`) para `Modal_Examen.gd`.
- **Cálculo de nota final:**
  - `hab_acad = Inteligencia*0.35 + Memoria*0.15 + Sangre_Fria*0.50`
  - `nec_examen = Descanso*0.40 + Salud_Mental*0.40 + Hambre*0.20`
  - `valor_esperado = progreso_actual*0.60 + hab_acad*0.20 + nec_examen*0.20`
  - `nota_personaje = Distribucion_Normal(valor_esperado, sigma=15.0)` (clamp `0..100`)
  - `nota_final = clamp(nota_personaje + nota_real_jugador * 0.1, 0.0, 100.0)`
  - Aprueba con `>= 50` (Matrícula de honor `>= 90`). Al completar todos los años, otorga bonus `2000 * Multiplicador_Precios()`.

### H. Eventos Aleatorios (`Eventos_Aleatorios.gd`)
- **Despido por higiene:** mientras trabaja, si Higiene es baja puede ser despedido y añade un cooldown de **5 días** (`5 * 1440` min) a ese trabajo en `Cooldown_Trabajos`.
- **20 eventos generales:** probabilidad base `1/2880` por minuto (~1 cada 2 días), acumulativa tras `1440` min sin eventos. Tipos: `ENFERMEDAD_LEVE`, `ENFERMEDAD_GRAVE`, `BONUS_DINERO`, `BONUS_DINERO_GRANDE`, `ACCIDENTE_LEVE`, `ACCIDENTE_GRAVE`, `EVENTO_SOCIAL_POSITIVO`, `EVENTO_SOCIAL_NEGATIVO`, `HALLAZGO`, `INSPIRACION`, con franja horaria opcional (`hora_inicio..hora_fin`, soporta cruzar medianoche).

### I. Muerte (`Actividades.Comprobar_Muerte`)
- Muerte garantizada al llegar al final de los 574 días (`Minute_Day >= 573 and Minute_Minute >= 1439`).
- En cada minuto:
  - `factor_edad = pow(2.0, (edad - 18) / 10.0)`
  - `factor_nec = pow(35.0, media_necesidades / 100.0)`
  - `factor_modo = 7.0 if Modo_Rapido else 1.0`
  - `max_valor = max(1, int((1_875_000.0 * factor_nec / factor_edad) / factor_modo))`
  - Muere si `randi() % max_valor == 0`.

### J. Marca y Logo Dinámico (`Logo_Juego.gd`)
- `Logo_Juego` (HBoxContainer) = insignia circular con la cara real del Sim + wordmark `SIMS` + pastilla `LIFE`.
- La insignia usa `Personaje_Visual` en modo `retrato_cercano` y `Variables_Estaticas.Apariencia`; el logo local cambia con el personaje creado.
- Se usa en el menú principal (`Scripts/Globales/Menu.gd`).
- **Fijo (no dinámico):** icono de Play Store (`Imagenes/Marca/logo_play_store_512.png`) e icono del lanzador/APK (`icon.svg` → `Iconos_Android/`). Android no permite generar un icono de lanzador arbitrario en runtime; solo `activity-alias` predefinidos.
- Herramientas: `Generar_Iconos_Android.gd` (iconos APK) y `Exportar_Logo_Marca.gd` (lockup + feature graphic 1024×500).
- Documentación: `Documentacion/Marca/README.md`.

---

## 7. Roadmap Pendiente (por prioridad)
1. **Minijuego genérico aplicado a actividades** (+20 % efecto base, 1 mecánica reutilizable con skins por actividad; evitar hacer un minijuego distinto por cada actividad).
2. **Relaciones simples (NPCs)** (2–3 NPCs base: amigo, pareja potencial, familiar; `afinidad` 0–100; actividad "Quedar con X"; eventos por umbral).
3. **Hitos por edad** (25 casarse, 30 hijos, 50 reflexión, 65 jubilación, 80+ conectar muerte con edad).
4. ~~**Avatar visual completo** (post-MVP, alto coste de assets).~~ Implementado: creador de personaje, `Personaje_Visual` y logo dinámico (ver J).

---

## 8. Tu Protocolo de Trabajo Conmigo
Cuando te proponga una nueva funcionalidad o cambio:
1. **Analiza el encaje** con los sistemas actuales (autoloads, variables, matriz, prioridades P1/P2/P3, saves, `Modo_Rapido`, UI portrait 720×1280).
2. **Detecta huecos y hazme preguntas concretas** sobre diseño, balanceo, UX o edge cases antes de cerrar la especificación.
3. **Propón la arquitectura exacta** (archivos a crear/modificar, funciones puras testeables con GUT, nodos `.tscn` y `Estilos_UI`).
4. **Cuando te diga "genera el prompt para Antigravity"**, entrega un único bloque Markdown copiable con:
   - **Contexto obligatorio** (lista exacta de archivos que Antigravity debe leer).
   - **Reglas duras** (Godot 4.4, portrait 720×1280, compatibilidad saves, rendimiento O(1), etc.).
   - **Especificación técnica paso a paso** (archivo por archivo, firmas exactas, fórmulas, nodos UI, textos).
   - **Tests GUT obligatorios** (funciones puras deterministas) y **criterios de aceptación**.

Confirma que has entendido el proyecto al 100 % resumiendo en 3 líneas su arquitectura clave y pregúntame qué nueva funcionalidad queremos diseñar hoy.
