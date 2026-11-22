# Escenario animado de Inicio

`Escenario_Actividad` (`Scripts/GUI/Personaje/Escenario_Actividad.gd`) es el mini‑escenario que muestra al Sim realizando su actividad actual. Se incrusta en:

- la tarjeta de estado del Home de `Script_Principal.gd` (`_home_escenario`);
- la tarjeta de partida activa del menú (`Menu.gd`, `escenario_inicio`).

La pose se elige en `Apariencia_Personaje.pose_para_actividad()` a partir del nombre de la actividad que ocupa la celda de la matriz en ese minuto. Cada pose tiene su fondo dibujado y un catálogo de micro‑acciones espontáneas (`VARIACIONES`) que salta cada 2,6–4,4 s; tocar el escenario lanza una al momento.

## Escenografía

El arte de las escenas vive en `Scripts/GUI/Personaje/Escenografia_Inicio.gd` (`Escenografia_Inicio`). `_CapaFondoActividad` y `_CapaFrenteActividad` le delegan el dibujo de todas las poses salvo `idle`, que conserva su salón original (la lámina de referencia).

Cada escena se compone en tres capas:

1. **Fondo**: pared o cielo con degradado, ventana con hora real del día, luz volumétrica, muebles de fondo, plantas y decoración.
2. **Personaje**: `Personaje_Visual` con la pose y la micro‑acción activas.
3. **Frente**: mostrador, mesa, escritorio, sartén, manta o espuma que tapa la parte baja del torso; partículas, vapor, destellos y sombras de contacto.

El estilo busca el mismo lenguaje que el tiempo libre: contornos tintados (no negro puro), volumen con brillos y sombras, props dibujados a mano y partículas ambientales. La escena responde a la hora de `_franja_horaria()` (mañana, tarde, atardecer o noche) en las ventanas y paletas. La variante de calle de `idle` y `comer` tiene su propia plaza urbana con cafetería, farolas, guirnalda y palomas.

Puntos destacados por pose:

| Pose | Escena |
|---|---|
| `correr` | Parque con sol/luna, nubes en parallax, colinas, arboleda, camino, farola, banco, flores y luciérnagas; polvo y líneas de velocidad al sprintar. |
| `dormir` | Habitación nocturna con luna, skyline, cortinas, guirnalda de luces, cabecero tallado, almohadas, mesilla con lámpara, reloj y libro; manta acolchada, peluche y libro con gafas. |
| `comer` | Comedor básico o premium con ventana y cortinas, papel pintado, zócalo, cuadro, estante, lámpara colgante, panera, jarrón y vela; variante de calle con carrito de comida. |
| `duchar` | Baño alicatado con nicho de botes, toallero, mampara de cristal, ducha de lluvia, vapor, pompas, patito y desagüe. |
| `estudiar` | Biblioteca, corcho con notas, póster, ventana, silla y escritorio con cuaderno, lámpara, café, lápices y libros. |
| `tv` | Salón oscuro con televisión en perspectiva, mueble, sofá, lámpara de pie, pósters, mesa de café con palomitas, latas y mando. |
| `manualidades` | Taller con galería de cuadros, caballete, botes de pintura, pinceles y mantel de trabajo manchado. |
| `cocinar` | Cocina con armarios, campana, azulejos, utensilios, especias, ventana, olla y sartén con fuego y vapor. |
| `fiesta` | Club con barra, neón «FEST», altavoces, bola de discoteca, focos volumétricos, bokeh, público y pista de baile. |
| `futbol` | Estadio con graderío, focos, vallas, césped segado, portería, banderín y confeti. |
| `trabajar` | Oficina con ventanal y skyline, reloj, pizarra, estantería, planta, silla, escritorio con portátil, lámpara, taza y notas. |

## Micro-acciones y transiciones

`VARIACIONES` incluye entre 3 y 6 acciones por pose. Además de las clásicas (`saludar`, `beber`, `soplar`, `roncar`, `cantar`…), se añadieron:

- `correr`: `senalar`.
- `dormir`: `abrazar_almohada`.
- `estudiar`: `subrayar`.
- `tv`: `bostezo_tv`.
- `manualidades`: `soplar_pintura`.
- `cocinar`: `oler_guiso`.
- `fiesta`: `saltar`.
- `futbol`: `regate`.
- `trabajar`: `estirar_cuello`.

`Personaje_Visual.obtener_rig_pose()` calcula el rig de reposo y el de la micro-acción y los funde durante el primer y el último 14 % de la variación. Así los brazos, la cabeza y los props no saltan al empezar ni al terminar. Los estados discretos (tipo de mano, prop sostenido, expresión de comida) cambian a mitad del fundido. Las poses base también tienen respiración, balanceo, mirada y gestos secundarios propios.

Cuando cambia la actividad o la variante de calle, `Escenario_Actividad._fundir_escena()` hace un fundido de entrada de 0,28 s sobre `_escena_clip` para suavizar el cambio de escenografía.

## Poses y actividades

| Pose | Actividades | Variante de calle |
|---|---|---|
| `idle` | tiempo libre (`""`), `Actividad_Aleatoria` y actividades sin mapear | sí |
| `correr` | `Salir_A_Correr`, `Carrera_Deportiva` | no |
| `dormir` | `Dormir` | no |
| `comer` | `Comer_Tupper`, `Comer_Basura` (y el antiguo `Comer`) | sí |
| `duchar` | `Duchar` | no |
| `estudiar` | `Estudiar`, `Estudiar_Carrera`, `Examen_Carrera` | no |
| `tv` | `Ver_La_Television` | no |
| `manualidades` | `Practicar_Manualidades` | no |
| `cocinar` | `Cocinar` | no |
| `fiesta` | `Salir_De_Fiesta` | no |
| `futbol` | `Entrenamiento_Futbol`, `Partido_Futbol` | no |
| `trabajar` | cualquier `Trabajar_*` | no |

Cualquier nombre que no esté en la tabla cae en `idle`.

## Forzar una pose para QA

`Scripts/Otro/Herramientas/Debug_Pose_Inicio.gd` permite revisar una animación sin programar ni ejecutar la actividad. Solo cambia lo que se dibuja: no toca la matriz, las necesidades, el dinero ni el estado de la partida.

```gdscript
# Scripts/Otro/Herramientas/Debug_Pose_Inicio.gd
static var POSE_FORZADA: String = "correr" # "0" = desactivado
static var FORZAR_CALLE: int = -1         # -1 real · 0 vivienda · 1 calle
```

Valores admitidos en `POSE_FORZADA`:

- `"0"` (o `""`): comportamiento normal, se ve la actividad real;
- `"idle"`, `"correr"`, `"dormir"`, `"comer"`, `"duchar"`, `"estudiar"`, `"tv"`, `"manualidades"`, `"cocinar"`, `"fiesta"`, `"futbol"`, `"trabajar"`;
- el nombre exacto de una actividad del catálogo (`"Dormir"`, `"Salir_De_Fiesta"`, `"Partido_Futbol"`…).

Tras editar el valor, relanza el juego con `./jugar.sh`. Al arrancar, la consola imprime `[Debug_Pose_Inicio] Forzando la pose «…»`. El escenario del menú y el del Home muestran la misma pose forzada; `FORZAR_CALLE` solo cambia el fondo de `idle` y `comer`, las dos poses con variante de calle.

El enganche está al principio de `Escenario_Actividad.actualizar_estado()`. Con `POSE_FORZADA = "0"` la llamada a `Debug_Pose_Inicio.actividad_forzada()` devuelve `""` y no altera nada.

## Herramientas de captura

Además de `Debug_Pose_Inicio`, hay escenas de QA que generan PNG en `user://`:

| Escena | Qué genera |
|---|---|
| `Escenas/Herramientas/Captura_Poses_Inicio.tscn` | Todas las poses en estado base y con micro-acción, a 640×219, 664×184 (Home) y 450×184 (menú). |
| `Escenas/Herramientas/Captura_Animaciones_Inicio.tscn` | Tiras de 10 fotogramas por pose para revisar el ciclo y la transición. |
| `Escenas/Herramientas/Captura_Home_Poses.tscn` | La tarjeta real del Home con cada pose forzada. |
| `Escenas/Herramientas/Captura_Variantes_Inicio.tscn` | Comedor básico, premium y de calle, y tiempo libre en la calle, en dos tamaños. |

Ejemplo:

```
godot --path . --resolution 720x1280 res://Escenas/Herramientas/Captura_Poses_Inicio.tscn
```

## Añadir una pose nueva

1. Mapear la actividad en `Apariencia_Personaje.POSE_POR_ACTIVIDAD`.
2. Dibujar la pose en `Personaje_Visual` y sus fondos/frentes en `Escenografia_Inicio` (`dibujar_fondo()` / `dibujar_frente()`).
3. Añadir sus micro‑acciones a `Escenario_Actividad.VARIACIONES` y, si necesitan gestos propios, sus ramas en `Personaje_Visual.obtener_rig_pose()`.
4. Añadir el atajo a `Debug_Pose_Inicio.ACTIVIDAD_POR_POSE`.

El test `test_debug_pose_inicio_fuerza_las_poses_del_escenario` comprueba que todas las poses de `VARIACIONES` tienen atajo y que el override funciona:

```
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://Funcionalidades/Personaje/Tests -gexit
```
