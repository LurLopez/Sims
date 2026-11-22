# Mundos 2–4 del Minijuego de Cocina

Los tres mundos que antes aparecían como «Fase 2» ya son jugables: **Bistró Tradicional**, **Cocina de Mercado** y **Alta Cocina Gourmet**. Cada uno tiene 15 niveles, fondo propio, estaciones propias, despensa propia y una mecánica distinta a la de Burger & Street Food.

---

## 1. Resumen

| Mundo | Fondo | Mecánica estrella | Estación A | Estación B | Bebidas |
|---|---|---|---|---|---|
| Burger & Street Food | `Fondo_Restaurante.png` | Montaje de hamburguesas | Plancha | Freidora | Refrescos |
| Bistró Tradicional | `Fondos/Fondo_Bistro.png` | **Punto del filete** | Parrilla con punto | Freidora | Cafetera |
| Cocina de Mercado | `Fondos/Fondo_Mercado.png` | **Guisos por lotes** | Olla | Plancha de huevos | Barra (agua/sangría) |
| Alta Cocina Gourmet | `Fondos/Fondo_Alta_Cocina.png` | **Precisión + salsa + maridaje** | Horno | Sartén de salsa | Bodega (tinto/blanco) |

Todos comparten:

- 11–31 clientes por nivel y final por agotamiento de clientes (sin límite de tiempo).
- Pase de 2/3/4 huecos según la mejora de Emplatado.
- Las 5 mejoras de cocina y la economía de Caja + costes.
- La ropa equipable, los rangos de Maestría Culinaria y los SFX/música del minijuego.
- El botón **MENÚ** (seguir / repetir / salir) y el guardado de estrellas por nivel.

---

## 2. Bistró Tradicional

### Mecánica: punto del filete

La parrilla sustituye la plancha de hamburguesas. Cada filete recorre cinco estados según su progreso de cocción:

| Progreso | Estado | ¿Servible? |
|---|---|---|
| 0–30 % | `crudo` | No |
| 30–55 % | `poco_hecho` | Sí |
| 55–78 % | `al_punto` | Sí |
| 78–100 % | `hecho` | Sí |
| Quemado acumulado ≥ 45 % | `quemado` | No |

- La etiqueta **bajo** cada filete muestra el punto actual sin tapar la carne.
- La barra inferior del slot se colorea con el punto.
- Un filete crudo o quemado se descarta tocándolo; un filete servible se coloca en el primer plato libre del pase.
- El tiempo base de la parrilla es 5,2 s y se reduce con la mejora de Plancha y con la Destreza del Sim.

### Interacción táctil (Bistró)

El Bistró se puede jugar entero **sin arrastrar**, pensando en móvil:

| Acción | Resultado |
|---|---|
| Tocar el filete de la despensa | Lo pone en el primer hueco libre de la parrilla |
| Tocar un filete en su punto | Lo pasa al primer plato libre del pase |
| Tocar un filete quemado o crudo | Lo descarta (el quemado con coste de merma) |
| Tocar las patatas / la freidora lista | Fríe o pasa las patatas al primer plato sin guarnición |
| Tocar la salsa | La añade al primer plato sin salsa |
| Tocar la tarta | La sirve al cliente que la está pidiendo |
| Tocar un plato completo | Lo sirve al cliente que lo pide (con halo verde si hay match) |
| Tocar un cliente | Sirve el plato, el café o el postre que tenga listo y ese cliente espere |
| Tocar un plato que nadie pide | Avisa de que hay que arrastrarlo a la basura |
| Arrastrar comida o plato a la basura | Lo descarta y calcula la merma |

El arrastre sigue disponible para colocar con precisión: el destino de cliente es una zona generosa que cubre cuerpo y ticket, y los platos aceptan cualquier hueco del pase. Las zonas de toque solo se activan cuando el origen no puede arrastrarse (plato vacío, carne cruda, bebida llenándose), de modo que un gesto de arrastre nunca dispara una acción por accidente.

### Mejoras propias del Bistró

Las cinco mejoras comparten costes y números con el resto de mundos, pero el Bistró tiene **textos, beneficios e ilustraciones propias** (`MEJORAS_UI_POR_RESTAURANTE` y `dibujar_mejora_bistro`), para que no siga mostrando la plancha de hamburguesas ni los vasos de refresco:

| Mejora | Nombre en el Bistró | Ilustración |
|---|---|---|
| `plancha` | Parrilla y Freidora | Parrilla 3/4 con 2–4 filetes y freidora con cestas |
| `emplatado` | Pase y Cafetera | Bandeja del pase con 2–4 platos y 1–3 tazas de café |
| `termostato` | Punto de la Carne | Dial del punto con filete, termómetro y panel digital |
| `ingredientes` | Género Seleccionado | Tabla de carnicero con filetes crudos y sello premium |
| `ambiente` | Ambiente del Bistró | Comedor con terciopelo, espejo, lámpara y mantel |

Los iconos de la lista (48 px) usan la misma composición en versión compacta y se actualizan con el nivel de mejora comprado.

### Recetas

| id | Nombre | Composición | Precio base |
|---|---|---|---|
| `filete_punto` | Filete al punto | filete al punto | 14 € |
| `filete_patatas` | Filete al punto con patatas | filete al punto + patatas | 20 € |
| `filete_completo` | Filete completo | filete al punto + patatas + salsa | 24 € |
| `solomillo_jugoso` | Solomillo jugoso | filete poco hecho + patatas + salsa | 26 € |
| `entrecot_hecho` | Entrecot hecho con patatas | filete hecho + patatas | 22 € |
| `cafe` | Café | cafetera | 6 € |
| `tarta_cereza` | Tarta de cereza | vitrina (postre listo) | 9 € |

### Despensa

`carne` (filete crudo), `patatas`, `salsa` y `tarta_cereza`.

- **Filete** → parrilla.
- **Patatas** → freidora; después se arrastran al pase como guarnición.
- **Salsa** → topping del plato.
- **Tarta** → se sirve directamente al cliente que la pide (no pasa por el pase).

---

## 3. Cocina de Mercado

### Mecánica: guisos por lotes

La olla admite **dos ingredientes** y forma un guiso cuando la combinación es válida:

| Guiso | Ingredientes | Raciones |
|---|---|---|
| `fabada` | `alubias` + `chorizo` | 4 |
| `pisto` | `tomate` + `pimiento` | 4 |
| `arroz` | `arroz` + `marisco` | 4 |

- Añadir un ingrediente que no pertenece al guiso que se está formando se rechaza.
- La olla tarda 6,2 s en cocinar la tanda y muestra vapor, burbujas y una barra de progreso.
- Al estar lista, **tocar la olla** sirve una ración al primer plato libre (o arrastrar la olla al pase). Cada ración es un plato independiente.
- Cuando se agotan las 4 raciones, la olla se vacía y hay que preparar otra tanda.
- La plancha de al lado cocina **huevos**; el huevo se añade al pisto para `pisto_huevo`.

### Recetas

| id | Nombre | Composición | Precio base |
|---|---|---|---|
| `fabada` | Fabada asturiana | guiso fabada | 16 € |
| `pisto` | Pisto manchego | guiso pisto | 14 € |
| `pisto_huevo` | Pisto con huevo | guiso pisto + huevo | 18 € |
| `arroz_senyoret` | Arroz del senyoret | guiso arroz | 20 € |
| `agua` | Agua | barra | 4 € |
| `sangria` | Sangría | barra | 7 € |

### Despensa

`alubias`, `chorizo`, `tomate`, `pimiento`, `arroz`, `marisco` y `huevo`.

- Los seis primeros van a la olla.
- **Huevo** → plancha; después se arrastra al pase.

---

## 4. Alta Cocina Gourmet

### Mecánica: precisión, salsa y maridaje

1. **Horno con ventana dorada.** Cada proteína recorre el progreso 0–115 %. La franja dorada está entre el **62 % y el 88 %**. Antes está cruda; después está pasada y hay que tirarla. La barra del slot dibuja la franja y un marcador.
2. **Salsa que se quema.** La sartén empieza lista y acumula quemado a razón de ~4,2 %/s. Tocar la sartén **remueve** y baja el medidor un 34 %. Arrastrar la sartén al pase añade la reducción al plato. Si llega al 100 %, la salsa queda arruinada; hay que tocarla para empezar una nueva.
3. **Maridaje.** Cada plato tiene un vino asignado. El cliente pide siempre plato + copa; la bodega tiene dos huecos (tinto y blanco). Hay que servir la copa correcta.
4. **Flor opcional.** Añadir una flor al plato antes de servirlo suma **+3 € de propina**.

### Recetas

| id | Nombre | Composición | Maridaje | Precio base |
|---|---|---|---|---|
| `solomillo_tinto` | Solomillo al vino tinto | solomillo + reducción + puré | `vino_tinto` | 32 € |
| `lubina_blanca` | Lubina con beurre blanc | lubina + reducción + espárragos | `vino_blanco` | 30 € |
| `pato_tinto` | Pato al Pedro Ximénez | pato + reducción + puré | `vino_tinto` | 36 € |
| `vino_tinto` | Copa de tinto | bodega | — | 10 € |
| `vino_blanco` | Copa de blanco | bodega | — | 10 € |

### Despensa

`solomillo`, `lubina`, `pato`, `pure`, `esparragos` y `flor`.

- Las tres proteínas van al horno.
- **Puré** y **espárragos** son guarniciones instantáneas del pase.
- **Flor** es un extra opcional (+3 € de propina).

---

## 5. Desbloqueo y progresión

Un mundo se abre por cualquiera de estas dos vías:

1. **Trabajo:** ejecutar al menos 1 minuto real en el puesto de hostelería asociado (Ayudante de Cocina, Cocinero de Partida o Chef Ejecutivo).
2. **Progresión:** superar al menos 1 nivel del mundo anterior. Esto permite jugar los cuatro mundos sin depender del turno de trabajo.

Los niveles dentro de un mundo se abren al conseguir ≥1 estrella en el anterior, igual que en Burger Street. Cada mundo tiene su propio registro de estrellas (`bistro_tradicional_1`, `cocina_mercado_7`, etc.) y su propia Caja compartida.

### Modo prueba (QA)

Para probar todo el contenido sin esperar a los trabajos ni a las estrellas, `Sistema_Cocina.gd` incluye:

```gdscript
## MODO PRUEBA: desbloquea los 4 mundos y sus 15 niveles.
## Ponlo en false antes de publicar.
var desbloqueo_total_qa: bool = true
```

Con `true`, `Esta_Desbloqueado_Minijuego()`, `Esta_Desbloqueado_Restaurante()` y `Esta_Nivel_Desbloqueado()` devuelven `true` para todo, el mapa muestra el aviso «MODO PRUEBA: todos los mundos abiertos» y se puede entrar en cualquier nivel de cualquier mundo. Los tests desactivan el flag en sus setups para seguir validando la progresión real. Para volver al desbloqueo normal, cámbialo a `false`.

---

## 6. Archivos y puntos de extensión

| Archivo | Qué contiene |
|---|---|
| `Scripts/Logica/Escena_Principal/Minijuego_Cocina/Sistema_Cocina.gd` | `RECETAS_BISTRO`, `RECETAS_MERCADO`, `RECETAS_ALTA`, `PERFILES_RESTAURANTE`, `COMBOS_OLLA`, `PUNTO_FILETE_UMBRALES`, `VENTANA_ALTA_INICIO/FIN` y los helpers puros. |
| `Scripts/GUI/Minijuego_Cocina/Arte_Cocina.gd` | Fondos por restaurante, platos/iconos de los mundos 2–4, `Puesto_Ingrediente` genérico, `Estacion_Olla`, `Sarten_Salsa`, `Estacion_Horno` y `Estacion_Botellas`. |
| `Scripts/GUI/Minijuego_Cocina/Minijuego_Cocina.gd` | `_perfil_actual`, `_olla`, `_sarten`, `_Actualizar_Estaciones_Mundo()`, `_Reconstruir_Despensa()`, `_Tick_Slots_Coccion()` genérico, `_Anadir_Ingrediente_Olla()`, `_Servir_Racion_Olla()`, `_Remover_Salsa()` y el flujo de pedidos por receta. |
| `Escenas/Herramientas/Captura_Mundos_Cocina.tscn` | Capturas de QA de los 3 mundos y sus modales. |
| `Funcionalidades/Minijuego_Cocina/Tests/test_mundos_cocina.gd` | 12 tests de datos, gameplay, los 60 niveles y el modo QA. |

### Añadir otra receta

1. Añade el diccionario a `RECETAS_BISTRO`, `RECETAS_MERCADO` o `RECETAS_ALTA` con `id`, `nombre`, `nombre_corto`, `detalle`, `precio_base`, `tipo` y los componentes (`proteina`/`punto`/`guarnicion`/`salsa`/`guiso`/`extra`/`maridaje`).
2. Añádela al menú de los niveles en `_Inicializar_Restaurantes()` (arrays `menus_bistro`, `menus_mercado` o `menus_alta`).
3. Si usa un ingrediente nuevo, añádelo a `PERFILES_RESTAURANTE[<mundo>].puestos` y dibuja su icono en `Arte_Cocina.dibujar_ingrediente_icono()`.
4. Si necesita una composición nueva, amplía `dibujar_icono_*` y `dibujar_plato_*`.
5. Añade un caso a `test_mundos_cocina.gd` con la receta y su combinación.

### Añadir otro mundo

1. Crea el fondo 16:9, guárdalo en `Imagenes/Minijuego_Cocina/Fondos/` y añade su ruta a un nuevo perfil en `PERFILES_RESTAURANTE`.
2. Añade las recetas a un nuevo diccionario y regístralo en `RECETAS_POR_RESTAURANTE`.
3. Añade el id a `ORDEN_RESTAURANTES` y su configuración a `_restaurantes`.
4. Implementa su estación/mecánica en `Minijuego_Cocina.gd` (o reutiliza una de las existentes) y su arte en `Arte_Cocina.gd`.
5. Añade sus 15 niveles a `_Generar_Niveles_Mundo()` con los menús correspondientes.
6. Añade la miniatura al selector (se resuelve sola con `fondo_restaurante(id)`), el desbloqueo y los tests.

---

## 7. QA

```bash
# Suite completa del minijuego (45 tests)
godot --headless --path . -s addons/gut/gut_cmdln.gd \
  -gdir=res://Funcionalidades/Minijuego_Cocina/Tests -gexit

# Capturas de los 3 mundos + modales
godot --path . --resolution 1280x720 \
  res://Escenas/Herramientas/Captura_Mundos_Cocina.tscn
# Salida: user://capturas_mundos_cocina/
```

Las capturas de referencia están en `Funcionalidades/Minijuego_Cocina/Documentacion/Capturas/` para el mundo 1 y en `user://capturas_mundos_cocina` para los mundos nuevos.
