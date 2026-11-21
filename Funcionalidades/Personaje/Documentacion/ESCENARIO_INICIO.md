# Escenario animado de Inicio

`Escenario_Actividad` (`Scripts/GUI/Personaje/Escenario_Actividad.gd`) es el mini‑escenario que muestra al Sim realizando su actividad actual. Se incrusta en:

- la tarjeta de estado del Home de `Script_Principal.gd` (`_home_escenario`);
- la tarjeta de partida activa del menú (`Menu.gd`, `escenario_inicio`).

La pose se elige en `Apariencia_Personaje.pose_para_actividad()` a partir del nombre de la actividad que ocupa la celda de la matriz en ese minuto. Cada pose tiene su fondo dibujado y un catálogo de micro‑acciones espontáneas (`VARIACIONES`) que salta cada 2,6–4,4 s; tocar el escenario lanza una al momento.

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

## Añadir una pose nueva

1. Mapear la actividad en `Apariencia_Personaje.POSE_POR_ACTIVIDAD`.
2. Dibujar la pose en `Personaje_Visual` y su fondo/frente en `Escenario_Actividad` (`_CapaFondoActividad` y `_CapaFrenteActividad`).
3. Añadir sus micro‑acciones a `Escenario_Actividad.VARIACIONES`.
4. Añadir el atajo a `Debug_Pose_Inicio.ACTIVIDAD_POR_POSE`.

El test `test_debug_pose_inicio_fuerza_las_poses_del_escenario` comprueba que todas las poses de `VARIACIONES` tienen atajo y que el override funciona:

```
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://Funcionalidades/Personaje/Tests -gexit
```
