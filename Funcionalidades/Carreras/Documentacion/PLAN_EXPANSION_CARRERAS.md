# Añadir carreras universitarias: Derecho, Medicina y Bellas Artes

> **Estado: pendiente de implementación.** Este documento es el plan aprobado antes de tocar
> código — no describe comportamiento ya implementado. La versión visual está en
> [PLAN_EXPANSION_CARRERAS.html](PLAN_EXPANSION_CARRERAS.html). El sistema ya implementado está en
> [SISTEMA_CARRERAS.md](SISTEMA_CARRERAS.md).

## Contexto

Hoy solo existe una carrera jugable (`Carrera_Ingenieria_Informatica`), instanciada de forma
hardcodeada en `Script_Principal.gd:1222`. El propio doc del sistema
(`Funcionalidades/Carreras/Documentacion/SISTEMA_CARRERAS.md`) ya proponía como expansión futura
añadir Derecho, Medicina y Bellas Artes.

Decisiones tomadas con el usuario:
- **Una única carrera activa a la vez** (se mantiene `Variables_Dinamicas.Carrera_Actual` como
  referencia única — no se permite cursar varias en paralelo).
- **La ventaja de cada carrera es desbloquear un trabajo de nómina de alto salario.** Ya existe la
  infraestructura: `Actividad_Fija_Trabajo.requisito_carrera` se comprueba en
  `Script_Principal._Cumple_Requisitos_Trabajo()` (líneas 657-678) contra
  `Variables_Dinamicas.Carreras_Completadas`. "Científico" ya usa este mecanismo
  (`requisito_carrera = ["Ingenieria_Informatica"]`), así que el patrón a replicar ya existe.
- **Carreras nuevas**: Derecho, Medicina, Bellas Artes.
- **Medicina dura 5 años** (no 4) para que sea más difícil que el resto. El resto de ajustes de
  dificultad por carrera se dejan para más adelante — de momento solo este cambio de duración.
- **Al completar una carrera debe aparecer un logro/certificado en el Inventario** (pestaña
  Apuntes del Perfil), no solo los libros por año.
- **No se puede volver a empezar una carrera ya completada.** El selector de carrera debe excluir
  (o mostrar bloqueada) cualquier carrera cuyo `nombre` ya esté en `Carreras_Completadas`.
- Cada carrera necesita contenido educativo real por año (apuntes + banco de preguntas) — hay que
  escribirlo, no dejarlo vacío.

Hallazgos de la exploración (para no repetir trabajo ni romper nada existente):
- El guardado (`Guardar_Variables_Dinamicas._Dict_A_Carrera`) reconstruye la carrera cargando
  dinámicamente `dict["script_path"]` con `load(...).new()` — no hay un `match` hardcodeado por
  nombre. Basta con crear las nuevas clases `Carrera_*.gd`; guardado/carga funciona automático.
- El progreso de años (`Sistema_Examenes.gd:76-86`) ya usa `carrera.años_totales` de forma
  genérica (no hay ningún "4" hardcodeado en la lógica de avance de año) — Medicina a 5 años
  funciona sin tocar `Sistema_Examenes.gd`.
- El bug conocido #4 de `CLAUDE.md` ("Carpintero y Científico referencian entradas del catálogo
  inexistentes") está desactualizado: ambas entradas SÍ existen en `Variables_Estaticas.gd`
  (líneas 103-125) y el requisito de carrera SÍ se comprueba. Se corregirá la nota.
- Hay **tres** sitios con rutas de contenido hardcodeadas a `ing_informatica` que hay que
  generalizar (no dos, como parecía al principio):
  1. `Modal_Examen.gd:3` (`PREGUNTAS_PATH`) — examen real del jugador.
  2. `Carreras/UI/Lector_Libros.gd:3` (`APUNTES_PATH_BASE`) — modal "Leer Apuntes" (botón en el
     panel de carrera, `_on_libros_button_pressed`, línea 1327).
  3. `Script_Principal._Parsear_Libro()` (línea 1088-1090) — usado por `_Abrir_Libro()`, la lectura
     "página a página" desde la pestaña Inventario. **Ojo:** `_Parsear_Libro` hoy solo recibe
     `año`, no `carrera` — hay que ampliar su firma para poder construir la ruta correcta.
- Hay **dos lectores de libros distintos** en el proyecto, ambos deben generalizarse:
  - `Carreras/UI/Lector_Libros.gd`: `AcceptDialog` con pestañas por año (abierto desde el botón
    "Leer Apuntes" del panel de carrera).
  - `GUI/Escena_Principal/Lector_Libro.gd`: `CanvasLayer` con paso de página tipo libro (abierto
    al tocar una miniatura en la pestaña Inventario). Este es el que tiene el emoji de portada
    hardcodeado (`"💻"`, línea 250 de `Lector_Libro.gd`) y también hay que generalizarlo.
- Los botones de trabajo realmente conectados a lógica están en
  `Actividades/Elegir_Actividad/Tipos_De_Actividades/Fijas_Opciones/Trabajo_Opciones/*`
  (conectados vía `[connection]` en la tscn a `_on_<trabajo>_pressed`). El panel
  `Trabajo/Actividades_Trabajo_Nomina_Opciones` (documentado en `CLAUDE.md`) es puramente
  visual/no está conectado a ningún script hoy.
- El botón único de carrera (`_on_carrera_accion_pressed`, `Script_Principal.gd:1217`) ya maneja
  todo el ciclo; solo hay que interceptar el caso "sin carrera" (líneas 1221-1226) para abrir un
  selector en vez de instanciar directamente.

## Cambios

### 1. Modelo de datos de carrera
- `Carrera.gd`: añadir dos campos:
  - `@export var slug_contenido: String = ""` (para construir rutas de contenido: "derecho",
    "medicina", "bellas_artes", "ing_informatica").
  - `@export var emoji: String = "📘"` (icono usado en la miniatura del Inventario y en la portada
    del libro).
- `Carrera_Ingenieria_Informatica.gd`: añadir `slug_contenido = "ing_informatica"`,
  `emoji = "💻"` (mantiene el aspecto actual).
- Nuevas clases (mismo patrón `extends Carrera`, `_init()`):
  - `Carrera_Derecho.gd` → `nombre = "Derecho"`, `slug_contenido = "derecho"`, `emoji = "⚖️"`,
    `años_totales = 4`.
  - `Carrera_Medicina.gd` → `nombre = "Medicina"`, `slug_contenido = "medicina"`,
    `emoji = "🩺"`, **`años_totales = 5`**.
  - `Carrera_Bellas_Artes.gd` → `nombre = "Bellas_Artes"`, `slug_contenido = "bellas_artes"`,
    `emoji = "🎨"`, `años_totales = 4`.
  - Todas con `costo_matricula_anual = 500.0`, `libros_desbloqueados = ["Anio_1"]` (mismo coste
    que Ingeniería; no se introduce balance nuevo sin pedirlo, salvo la duración de Medicina).

### 2. Generalizar rutas de contenido y emoji (los 3 puntos hardcodeados detectados)
- `Modal_Examen.gd`: construir la ruta de preguntas con `carrera.slug_contenido` en
  `_Cargar_Preguntas()` en vez de la constante fija.
- `Carreras/UI/Lector_Libros.gd`: igual con `APUNTES_PATH_BASE` → usar `carrera.slug_contenido`
  en `_Mostrar_Año()`.
- `Script_Principal.gd`:
  - `_Parsear_Libro(carrera, año)`: añadir el parámetro `carrera` y usar
    `carrera.slug_contenido` para construir la ruta; actualizar la llamada en `_Abrir_Libro()`.
  - `_Crear_Miniatura_Libro()`: usar `carrera.emoji` en vez de `"💻"` hardcodeado (línea 1039).
  - `_Abrir_Libro()`: pasar `carrera.emoji` al `Lector_Libro` al configurarlo.
- `GUI/Escena_Principal/Lector_Libro.gd`: ampliar `configurar()` para aceptar un `emoji: String`
  (guardarlo en `_emoji`) y usarlo en `_Renderizar_Cover()` en vez del `"💻"` fijo (línea 250).

### 3. Contenido educativo nuevo (mismo formato que el existente)
Referencia de formato: `Contenido/apuntes_ing_informatica_anio1.txt` (notas numeradas + sección
"Consejos de examen") y `Contenido/preguntas_ing_informatica.json` (dict `Anio_1..N`, 10 preguntas
de opción múltiple por año, 4 opciones, `respuesta_correcta` como índice).

Crear en `Scripts/Logica/Escena_Principal/Actividades/Carreras/Contenido/`:
- `apuntes_derecho_anio{1..4}.txt` — Año1 Fundamentos del Derecho, Año2 Derecho Civil, Año3 Derecho
  Penal, Año4 Derecho Procesal y Deontología. + `preguntas_derecho.json` (40 preguntas, `Anio_1..4`).
- `apuntes_medicina_anio{1..5}.txt` — Año1 Anatomía y Fisiología Básica, Año2 Patología General,
  Año3 Diagnóstico Clínico, Año4 Farmacología, **Año5 Ética Médica y Práctica Clínica**. +
  `preguntas_medicina.json` (50 preguntas, `Anio_1..5`, porque son 5 años).
- `apuntes_bellas_artes_anio{1..4}.txt` — Año1 Color y Dibujo, Año2 Técnicas de Pintura, Año3
  Historia del Arte, Año4 Composición y Crítica de Arte. + `preguntas_bellas_artes.json` (40
  preguntas, `Anio_1..4`).

### 4. Selector de carrera (nuevo modal)
- Nuevo `Carreras/UI/Modal_Seleccionar_Carrera.gd`, construido por código igual que
  `Modal_Seleccionar_Examen.gd` (mismo patrón `AcceptDialog` + `_Construir_UI()`), pero en vez de
  elegir día/hora, muestra un botón por carrera disponible (con su `emoji`) y emite
  `signal carrera_elegida(script_path: String)`.
- **Carreras ya completadas quedan fuera de la lista.** Al construir la UI, el modal recibe (o lee
  directamente) `Variables_Dinamicas.Carreras_Completadas` y compara por `nombre`: si una carrera
  del catálogo ya aparece ahí, no se ofrece un botón activo para ella — se omite de la lista, o se
  muestra deshabilitada con un texto tipo "Ya completada 🎓" (a decidir en implementación cuál se
  ve mejor en el modal; funcionalmente el resultado es el mismo: no se puede volver a elegir).
- `Script_Principal.gd`:
  - En `_on_carrera_accion_pressed()`, sustituir la instanciación directa (líneas 1221-1226) por
    abrir `Modal_Seleccionar_Carrera` cuando `carrera == null`.
  - Nuevo handler `_on_carrera_elegida(script_path: String)`: `load(script_path).new()` →
    `Variables_Dinamicas.Carrera_Actual`, guardar partida, actualizar pantalla (mismo patrón que
    `_on_horario_elegido`). Como el modal ya filtra las completadas, este handler no necesita
    revalidar, pero es una comprobación barata de añadir por seguridad (defensa en profundidad
    ante una señal manipulada).

### 5. Trabajos desbloqueados por carrera (ventaja de cada carrera)
Replicar el patrón exacto de "Científico" (`Variables_Estaticas.gd:115-125`, `requisito_carrera =
["Ingenieria_Informatica"]`):

| Carrera | Trabajo nuevo | Catálogo (nombre) | Salario | `requisito_progreso` | `requisito_carrera` |
|---|---|---|---|---|---|
| Derecho | Abogado | `Trabajar_De_Abogado` | 30.0 | `[0, 50, 0]` | `["Derecho"]` |
| Medicina | Médico | `Trabajar_De_Medico` | 35.0 | `[0, 60, 0]` | `["Medicina"]` |
| Bellas Artes | Artista | `Trabajar_De_Artista` | 25.0 | `[0, 0, 50]` | `["Bellas_Artes"]` |

- `Variables_Estaticas.gd`: registrar las 3 entradas nuevas en `Catalogo_Actividades` (mismo
  bloque que `cientifico`, horario laboral 9-17 como Científico).
- `Trabajo.gd`: añadir `Trabajar_De_Abogado()`, `Trabajar_De_Medico()`, `Trabajar_De_Artista()`
  (mismo patrón de una línea que `Trabajar_De_Cientifico()`).
- `Script_Principal.gd`: añadir `_on_abogado_pressed()`, `_on_medico_pressed()`,
  `_on_artista_pressed()` (mismo patrón que `_on_cientifico_pressed()`), llamando a
  `_Intentar_Tomar_Trabajo(...)`.
- `Escena principal.tscn`:
  - Añadir 3 botones nuevos en `Fijas_Opciones/Trabajo_Opciones/` (clonar el nodo `Cientifico`,
    líneas 942-951) + sus `[connection signal="pressed" ...]` al final del archivo (clonar
    líneas 1583-1585) apuntando a los nuevos handlers.
  - Añadir los mismos 3 botones (visuales) en `Trabajo/Actividades_Trabajo_Nomina_Opciones` por
    consistencia con la convención documentada en `CLAUDE.md`, aunque ese contenedor no tiene
    lógica conectada hoy.

### 6. Logro/Certificado en el Inventario al completar una carrera
- `GUI/Escena_Principal/Lector_Libro.gd`: añadir un tipo de página nuevo `"diploma"` en
  `_Renderizar_Pagina()` (junto a `"cover"`/`"content"`) con una función `_Renderizar_Diploma()`
  de estética distinta (dorado, emoji `🎓`, "TÍTULO OFICIAL", nombre de la carrera, nota media).
  Todos los datos del diploma van dentro del propio diccionario de página (no depende de
  `_carrera_nombre`/`_año`), reutilizando el helper `_Crear_Divisor_Gradiente()` ya existente.
- `Script_Principal.gd`:
  - `_Renderizar_Apuntes()`: además de los libros por año, añadir una miniatura de diploma por
    cada carrera en `Variables_Dinamicas.Carreras_Completadas`.
  - `_Crear_Miniatura_Diploma(carrera)`: mismo patrón que `_Crear_Miniatura_Libro` pero con
    color dorado/distinto y texto "Título: <carrera>".
  - `_Abrir_Diploma(carrera)`: calcula la nota media a partir de `carrera.historial_notas`
    (promedio de las entradas con `aprobado == true`), arma una única página tipo `"diploma"` y
    la abre con el mismo `Lector_Libro` (`CanvasLayer`) que usan los libros.

### 7. Documentación
- `CLAUDE.md`: eliminar/corregir el bug #4 (ya no aplica). Añadir Derecho/Medicina/Bellas Artes a
  la tabla de catálogo de actividades y anotar que Medicina dura 5 años.
- `Funcionalidades/Carreras/Documentacion/SISTEMA_CARRERAS.md`: actualizar "Expansión Futura"
  (las 3 carreras dejan de ser futuras), corregir "Bonus económico (a definir)" → ya implementado
  como +2000€ (`Sistema_Examenes.gd:9`), y documentar el diploma/certificado y el trabajo
  desbloqueado por carrera.

## Fuera de alcance (a menos que el usuario pida lo contrario)
- No se varía el coste de matrícula por carrera (las 4 cuestan 500€/año); solo cambia la duración
  de Medicina.
- No se ajusta más la dificultad por carrera (dejado para una iteración futura, según lo pedido).
- No se permite cursar varias carreras a la vez.
- No se toca `Guardar_Variables_Dinamicas.gd` ni el formato de guardado — ya son compatibles
  gracias a la reconstrucción por `script_path`.

## Verificación
- Abrir el proyecto en Godot 4.4, comprobar que no hay errores de parseo de escena/script al
  cargar `Escena principal.tscn`.
- Partida nueva: pulsar "Matricularse Carrera" → debe aparecer el selector con las 4 carreras.
- Elegir Derecho (o cualquiera nueva): completar el ciclo de matrícula → examen → aprobar/suspender
  y comprobar que se cargan las preguntas/apuntes correctos (no los de Ingeniería Informática) en
  ambos lectores (modal "Leer Apuntes" y pestaña Inventario).
- Elegir Medicina y comprobar que pide 5 años (revisar `carrera.años_totales` y que el selector de
  horario/examen sigue funcionando en el año 5 igual que en los anteriores).
- Forzar (en pruebas) `carrera.completada = true` para una carrera y confirmar que aparece en
  `Carreras_Completadas`, que el trabajo correspondiente (ej. Abogado) deja de dar error de
  "requisito no cumplido", y que aparece la miniatura de diploma en la pestaña Inventario con la
  nota media correcta.
- Guardar y recargar partida a mitad de una carrera nueva (ej. Medicina en año 3, matriculado) y
  comprobar que `Carrera_Actual` se reconstruye con la clase correcta y todos los datos tras
  cargar.
