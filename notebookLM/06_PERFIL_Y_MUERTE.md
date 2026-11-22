# Perfil

## Descripción General
Pantalla de perfil del jugador accesible desde el botón "Perfil" en la barra superior izquierda. Organizada en cuatro pestañas: **Info** (datos del personaje, etapa de vida, progreso, habilidades innatas y acceso a Vestuario), **Mensajes** (bandeja de mensajes del juego con badge de no leídos), **Apuntes** (libros desbloqueados por carrera y diplomas de graduación) y **Despensa** (tuppers caseros con calidad, caducidad y selección). Se abre siempre en la pestaña Info.

---

## UI: Nodos y Visibilidad

### Jerarquía de nodos (Escena principal.tscn)

```
Pantalla_Mensajes (Control, 720×1280, z_index=5)   ← nombre histórico, es la pantalla de perfil
├── Fondo_Mensajes (ColorRect, fondo oscuro)
├── Header_Bar (Panel, y:0–132, StyleBox_Top_Bar)
├── Titulo (Label, "👤 PERFIL", y:72–128, amarillo, centrado)
├── Boton_Cerrar (Button, "← Volver", y:10–60)
├── Tab_Bar (HBoxContainer, y:132–205)
│   ├── Tab_Info (Button, "Info")
│   ├── Tab_Mensajes (Button, "Mensajes")
│   ├── Tab_Apuntes (Button, "Apuntes")
│   └── Tab_Despensa (Button, "Despensa")
├── Panel_Info (Control, y:210–1280)            ← Tab Info
│   └── Scroll_Info (ScrollContainer)
│       └── VBox_Info (VBoxContainer, sep=16)
├── Lista_Mensajes (ScrollContainer, y:210–1050) ← Tab Mensajes
│   └── VBoxContainer
├── Contenido_Mensaje (ColorRect, y:210–1280)   ← Detalle de mensaje (oculto por defecto)
│   ├── Mensaje_Card (Panel)
│   ├── Boton_Volver (Button)
│   ├── Hora_Mensaje_Label
│   ├── Titulo_Mensaje_Label
│   └── Descripcion_Mensaje_Label
└── Panel_Apuntes (Control, y:210–1280)         ← Tab Apuntes (ver Inventario)
    ├── Tabs_Libros (HBoxContainer)
    ├── Texto_Apuntes (TextEdit, editable=false)
└── Panel_Despensa (Control, y:210–1280)        ← Tab Despensa (tuppers)
    ├── Sin_Tuppers_Label (Label)
    └── Scroll_Tuppers/VBox_Tuppers (filas de Tupper_UI.crear_fila)
```
    └── Sin_Apuntes_Label (Label, hidden si hay libros)
```

### Gestionar_Visibilidad.gd — `Visibilizar_Perfil`

```gdscript
func Visibilizar_Perfil(raiz):
    Quitar_Todo(raiz)
    Visibilizar_Lo_Basico(raiz)
    var pantalla = raiz.get_node("Pantalla_Mensajes")
    Recursivo_Visibilizar(pantalla)          # hace todo visible
    pantalla.get_node("Contenido_Mensaje").visible = false
    pantalla.get_node("Panel_Info").visible = false
    pantalla.get_node("Lista_Mensajes").visible = false
    pantalla.get_node("Panel_Apuntes").visible = false
    # CRÍTICO: los tres paneles de contenido quedan ocultos; cada tab los activa individualmente
```

---

## Flujo de Ejecución

### Apertura del perfil

```gdscript
# Script_Principal.gd
func _on_perfil_button_pressed():
    Detener_Blink()
    Gestionar_Visibilidad.Visibilizar_Perfil(self)
    _on_perfil_tab_info_pressed()   # siempre abre en Info
```

### Cambio de pestaña

```gdscript
func _on_perfil_tab_info_pressed():
    $Pantalla_Mensajes/Panel_Info.visible = true
    $Pantalla_Mensajes/Lista_Mensajes.visible = false
    $Pantalla_Mensajes/Panel_Apuntes.visible = false
    $Pantalla_Mensajes/Contenido_Mensaje.visible = false
    _Renderizar_Info()

func _on_perfil_tab_mensajes_pressed():
    $Pantalla_Mensajes/Panel_Info.visible = false
    $Pantalla_Mensajes/Lista_Mensajes.visible = true
    $Pantalla_Mensajes/Panel_Apuntes.visible = false
    $Pantalla_Mensajes/Contenido_Mensaje.visible = false
    _Renderizar_Lista_Mensajes()

func _on_perfil_tab_apuntes_pressed():
    $Pantalla_Mensajes/Panel_Info.visible = false
    $Pantalla_Mensajes/Lista_Mensajes.visible = false
    $Pantalla_Mensajes/Panel_Apuntes.visible = true
    $Pantalla_Mensajes/Contenido_Mensaje.visible = false
    _Renderizar_Apuntes()
```

### Tab Info — renderizado (resumen)

`Script_Principal._Renderizar_Info()` muestra:
- **PERSONAJE:** edad calculada con `Variables_Estaticas.Calcular_Edad()` (que resta `Rejuvenecimiento_Anios` con suelo 18 y soporta `Modo_Rapido`), **Etapa de vida** (`Envejecimiento_Personaje.etapa(edad)`), personalidad, dinero, estado de vivienda y acceso directo «Cambiar de atuendo» (abre `Pantalla_Vestuario`).
- **PROGRESO:** Deporte, Académico, Manualidades (`Variables_Dinamicas.Progreso`) y Cocina (`Progreso_Cocina`).
- **HABILIDADES INNATAS:** las 7 habilidades (`Deporte`, `Inteligencia`, `Destreza manual`, `Memoria`, `Liderazgo`, `Paciencia`, `Sangre fría`); cada una muestra `? / 100` hasta que `Habilidades_Mostradas[i]` alcanza el límite innato.

### Helpers de UI para Info (creación dinámica de nodos)

```gdscript
func _Info_Seccion(vbox: VBoxContainer, titulo: String):
    # Label amarillo de sección, h=50, font_size=20

func _Info_Fila(vbox: VBoxContainer, clave: String, valor: String):
    # HBoxContainer h=55 con fondo oscuro (bg_color 0.18/0.2/0.25)
    # Label izquierdo (clave, azulado, expand) + Label derecho (valor, blanco)
```

### Tab Mensajes — renderizado y detalle

Ver documentación `Funcionalidades/Perfil/Mensajes/` para el sistema completo de mensajes. El renderizado es `_Renderizar_Lista_Mensajes()` y el detalle `_Mostrar_Mensaje(indice)`. Al volver del detalle: `_on_mensajes_boton_volver_pressed()` llama `_on_perfil_tab_mensajes_pressed()` (no `_Renderizar_Lista_Mensajes` directamente).

### Cierre del perfil

```gdscript
func _on_mensajes_boton_cerrar_pressed():
    Gestionar_Visibilidad.Quitar_Todo(self)   # vuelve a la pantalla principal
```

---

## Variables afectadas (solo lectura, no modifica)

| Variable | Tipo | Usado en |
|---|---|---|
| `Variables_Dinamicas.Minute_Day` | int | Cálculo de edad |
| `Variables_Estaticas.First_Time_Minute_Day` | int | Cálculo de edad |
| `Variables_Estaticas.Personalidad` | String | Tab Info |
| `Variables_Dinamicas.Dinero` | float | Tab Info |
| `Variables_Dinamicas.Progreso` | Array[int] | Tab Info |
| `Variables_Estaticas.Habilidades` | Array[int] | Tab Info |
| `Variables_Dinamicas.Mensajes` | Array[Mensaje] | Tab Mensajes |

---

## Persistencia

Esta funcionalidad no persiste estado propio. El panel visible al abrir siempre es Info. Los mensajes leídos se guardan en el sistema de Mensajes (ver su documentación).

---

## Casos de Uso

| Escenario | Resultado |
|---|---|
| Pulsar "👤 Perfil" | Abre el perfil en Tab Info con datos actualizados |
| Pulsar "Mensajes" | Muestra la lista de mensajes ordenados por fecha descendente |
| Pulsar "Apuntes" | Muestra libros disponibles o mensaje "sin apuntes" |
| Pulsar "← Volver" | Cierra el perfil y vuelve a la pantalla principal |
| Abrir mensaje y volver | Vuelve a Tab Mensajes (no a Info) |

---

## Notas Técnicas

| Aspecto | Detalle |
|---|---|
| Nombre del nodo raíz | `Pantalla_Mensajes` (nombre histórico, es la pantalla de perfil completa) |
| Pestaña por defecto | Siempre Info al abrir |
| Edad calculada | `Variables_Estaticas.Calcular_Edad()`: `max(18, 18 + int(max(0, Minute_Day - First_Time_Minute_Day) / Dias_Por_Anio()) - Rejuvenecimiento_Anios)` |
| Habilidades límite | `min(nombres_hab.size(), Habilidades.size())` para evitar out-of-bounds |
| Contenido_Mensaje | Cubre toda la zona de contenido (y:210) ocultando tabs y lista al leer un mensaje |

---

## Convenciones de Nombres

| Elemento | Nombre |
|---|---|
| Nodo raíz pantalla | `Pantalla_Mensajes` |
| Tab de pestañas | `Tab_Bar` |
| Pestaña Info | `Tab_Info` → `_on_perfil_tab_info_pressed()` |
| Pestaña Mensajes | `Tab_Mensajes` → `_on_perfil_tab_mensajes_pressed()` |
| Pestaña Apuntes | `Tab_Apuntes` → `_on_perfil_tab_apuntes_pressed()` |
| Pestaña Despensa | `Tab_Despensa` → `_on_perfil_tab_despensa_pressed()` |
| Panel Info | `Panel_Info` |
| Scroll Info | `Scroll_Info / VBox_Info` |
| Función visibilidad | `Gestionar_Visibilidad.Visibilizar_Perfil(raiz)` |

---

## Checklist de Implementación

- [x] Nodo `Tab_Bar` con `Tab_Info`, `Tab_Mensajes`, `Tab_Apuntes`, `Tab_Despensa` en escena
- [x] Nodo `Panel_Info` con `Scroll_Info/VBox_Info` en escena
- [x] Nodo `Panel_Apuntes` con `Tabs_Libros`, `Texto_Apuntes`, `Sin_Apuntes_Label`
- [x] `Lista_Mensajes` y `Contenido_Mensaje` desplazados a y:210
- [x] Título cambiado a "👤 PERFIL"
- [x] `Gestionar_Visibilidad.Visibilizar_Perfil()` implementado
- [x] `_on_perfil_button_pressed()` llama `Visibilizar_Perfil` + abre Tab Info
- [x] Tres funciones de cambio de pestaña implementadas
- [x] `_Renderizar_Info()` con secciones PERSONAJE, PROGRESO, HABILIDADES INNATAS
- [x] `_Info_Seccion()` y `_Info_Fila()` como helpers de UI
- [x] Signals de Tab_Bar conectados en escena
# Inventario (Tab Apuntes)

## Descripción General
Pestaña "Apuntes" dentro de la pantalla de Perfil. Muestra los libros/apuntes que el jugador ha desbloqueado al avanzar en sus carreras universitarias. Cada libro corresponde a un año de carrera completado. El jugador puede leer el contenido de cada libro pulsando su pestaña. Si no hay ningún libro disponible, muestra un mensaje informativo.

Los apuntes provienen de:
- La carrera activa actual (`Variables_Dinamicas.Carrera_Actual.libros_desbloqueados`)
- Las carreras ya completadas (`Variables_Dinamicas.Carreras_Completadas[i].libros_desbloqueados`)

---

## Nodos UI

```
Panel_Apuntes (Control, y:210–1280, visible=false por defecto)
├── Tabs_Libros (HBoxContainer, y:0–65)      ← botones creados dinámicamente
├── Texto_Apuntes (TextEdit, y:70–1060)      ← editable=false, wrap=BOUNDARY
└── Sin_Apuntes_Label (Label, visible=false) ← "Aún no tienes apuntes..."
```

Nodo padre: `Pantalla_Mensajes` (pantalla de perfil).

---

## Flujo de Ejecución

### Apertura de la pestaña

```gdscript
# Script_Principal.gd
func _on_perfil_tab_apuntes_pressed():
    $Pantalla_Mensajes/Panel_Info.visible = false
    $Pantalla_Mensajes/Lista_Mensajes.visible = false
    $Pantalla_Mensajes/Panel_Apuntes.visible = true
    $Pantalla_Mensajes/Contenido_Mensaje.visible = false
    _Renderizar_Apuntes()
```

### Renderizado del inventario

```gdscript
func _Renderizar_Apuntes():
    var panel = $Pantalla_Mensajes/Panel_Apuntes
    var tabs = panel.get_node("Tabs_Libros")
    var texto = panel.get_node("Texto_Apuntes")
    var sin_apuntes = panel.get_node("Sin_Apuntes_Label")

    for hijo in tabs.get_children():
        hijo.queue_free()   # limpia botones anteriores

    # Recopilar todos los libros disponibles
    var libros = []   # Array de {carrera, libro}
    var carrera_actual = Variables_Dinamicas.Carrera_Actual
    if carrera_actual != null:
        for libro in carrera_actual.libros_desbloqueados:
            libros.append({"carrera": carrera_actual, "libro": libro})
    for c in Variables_Dinamicas.Carreras_Completadas:
        for libro in c.libros_desbloqueados:
            libros.append({"carrera": c, "libro": libro})

    if libros.is_empty():
        sin_apuntes.visible = true
        texto.visible = false
        return

    sin_apuntes.visible = false
    texto.visible = true

    # Crear botón por libro
    for item in libros:
        var año = int(String(item.libro).replace("Anio_", ""))
        var btn = Button.new()
        btn.text = item.carrera.nombre + " – Año " + str(año)
        btn.add_theme_font_size_override("font_size", 20)
        btn.pressed.connect(_Mostrar_Apunte.bind(item.carrera, año))
        tabs.add_child(btn)

    # Mostrar el primer libro automáticamente
    var primero = libros[0]
    _Mostrar_Apunte(primero.carrera, int(String(primero.libro).replace("Anio_", "")))
```

### Mostrar contenido de un libro y diplomas

`Panel_Apuntes` resuelve la ruta de forma genérica mediante `carrera.slug_contenido` (`ing_informatica`, `derecho`, `medicina`, `bellas_artes`) y abre `Lector_Libro.gd` (que también renderiza la página `"diploma"` para las carreras completadas).

---

## Origen de los libros (sistema de Carreras)

Los libros se desbloquean en `Sistema_Examenes.gd` cuando el jugador supera un examen (`"Anio_1"`, `"Anio_2"`, etc.), y las 4 carreras disponen de sus archivos `apuntes_<slug>_anioN.txt` en `Scripts/Logica/Escena_Principal/Actividades/Carreras/Contenido/`.

---

## Tab Despensa (Tuppers)

`Panel_Despensa/Scroll_Tuppers/VBox_Tuppers` lista todos los tuppers de `Variables_Dinamicas.Tuppers` usando las filas reutilizables de `Scripts/GUI/Escena_Principal/Tuppers/Tupper_UI.gd`, mostrando calidad, porcentaje restante, caducidad (vigente o caducado) y permitiendo elegir manualmente el tupper prioritario (`Tupper_Seleccionado_Idx`).

La ruta está hardcoded en `_Mostrar_Apunte`. Si se añaden más carreras en el futuro, habrá que hacerla dinámica usando `carrera.nombre` para construir el path.

---

## Variables afectadas (solo lectura)

| Variable | Tipo | Descripción |
|---|---|---|
| `Variables_Dinamicas.Carrera_Actual` | Carrera\|null | Carrera en curso; puede ser null |
| `Variables_Dinamicas.Carreras_Completadas` | Array[Carrera] | Historial de carreras terminadas |
| `carrera.libros_desbloqueados` | Array[String] | Lista de strings "Anio_N" |
| `carrera.nombre` | String | Nombre de la carrera (ej: "Ingeniería Informática") |

---

## Persistencia

Los libros desbloqueados forman parte del objeto `Carrera`, que se guarda dentro de `Variables_Dinamicas` mediante `Guardar_Variables_Dinamicas.save_game()`. No hay persistencia adicional específica del inventario.

---

## Casos de Uso

| Escenario | Resultado |
|---|---|
| Sin carrera activa ni completada | `Sin_Apuntes_Label` visible; `Texto_Apuntes` oculto |
| Con carrera activa, sin libros aún | Mismo que el caso anterior |
| Con 1 libro desbloqueado | Un botón en `Tabs_Libros`; su contenido cargado automáticamente |
| Con varios libros | Un botón por libro; el primero se carga al abrir |
| Archivo .txt no encontrado | `Texto_Apuntes` muestra "Apuntes no disponibles para Año N." |
| Pulsar botón de otro libro | `Texto_Apuntes` se actualiza con el contenido del nuevo libro |

---

## Notas Técnicas

| Aspecto | Detalle |
|---|---|
| Orden de libros | Primero los de la carrera activa, luego los de completadas (orden de insert) |
| Primer libro automático | Al abrir la pestaña se carga `libros[0]` sin que el usuario pulse nada |
| Botones dinámicos | Se recrean cada vez que se abre la pestaña (`queue_free` + recrear) |
| Ruta de contenido hardcoded | Solo soporta una carrera actualmente; generalizar si se añaden más |
| Relación con libros_button | `libros_button` (botón dinámico en pantalla principal) abre `Lector_Libros` como popup; es independiente del inventario del perfil |

---

## Convenciones de Nombres

| Elemento | Nombre |
|---|---|
| Panel principal | `Panel_Apuntes` (hijo de `Pantalla_Mensajes`) |
| Contenedor de tabs | `Tabs_Libros` |
| Área de lectura | `Texto_Apuntes` |
| Label sin libros | `Sin_Apuntes_Label` |
| Función de renderizado | `_Renderizar_Apuntes()` |
| Función de carga | `_Mostrar_Apunte(carrera, año)` |

---

## Checklist de Implementación

- [x] Nodo `Panel_Apuntes` en escena (y:210–1280, visible=false)
- [x] `Tabs_Libros` (HBoxContainer, y:0–65) dentro de `Panel_Apuntes`
- [x] `Texto_Apuntes` (TextEdit, editable=false, wrap=BOUNDARY, y:70–1060)
- [x] `Sin_Apuntes_Label` (Label, visible=false por defecto)
- [x] `_Renderizar_Apuntes()` implementado con recopilación de carrera activa + completadas
- [x] `_Mostrar_Apunte(carrera, año)` lee el archivo .txt y lo vuelca en `Texto_Apuntes`
- [x] Signal `Tab_Apuntes.pressed` conectado a `_on_perfil_tab_apuntes_pressed`
- [ ] Generalizar ruta de archivos si se añaden carreras con nombres distintos

---

## Tab Despensa (tuppers) — implementado

- [x] `Tab_Despensa` + `Panel_Despensa` en `Pantalla_Mensajes.tscn`
- [x] `_on_perfil_tab_despensa_pressed()` y `_Renderizar_Despensa()`
- [x] Filas reutilizables `Tupper_UI.crear_fila()`: porcentaje, calidad, caducidad, elegir y tirar
- [x] `Modal_Tuppers.gd` para elegir/descartar desde el reloj de Comer
- [x] `Tupper_Seleccionado_Idx` persistido en el save dinámico
- [x] Indicador `🍱 N` junto a Hambre en `Necesidades_Basicas_GUI`
- [x] `Progreso_Cocina` visible en Perfil/Info y en el panel Progreso
# Sistema de Mensajes / Notificaciones

## Descripción General

Sistema para almacenar y mostrar mensajes de eventos del juego. Los mensajes aparecen en una pantalla accesible desde un botón "Perfil" en la barra inferior. Cada mensaje tiene un timestamp que indica **cuándo ocurrió el evento en la matriz**, no cuándo se procesa en ejecución real (crítico para offline).

**Objetivo:** Informar al jugador de eventos importantes (trabajos cancelados, cambios de estado, logros, etc.) de forma no intrusiva.

---

## Clase Mensaje

**Ubicación:** `Scripts/Logica/Mensajes/Mensaje.gd`

**Tipo:** Resource (`.tres`)

```gdscript
class_name Mensaje extends Resource

@export var titulo: String = ""
@export var descripcion: String = ""
@export var leido: bool = false
@export var minuto: int = 0  # Minuto Unix del evento en la matriz
```

### Propiedades

| Propiedad | Tipo | Rango | Significado |
|-----------|------|-------|-------------|
| `titulo` | String | N/A | Título del mensaje (ej: "Despedido de trabajo") |
| `descripcion` | String | N/A | Detalles (ej: "Te han despedido por falta de higiene") |
| `leido` | bool | true/false | false = no leído, true = ya lo abrió |
| `minuto` | int | ≥0 | **Minuto Unix absoluto del evento EN LA MATRIZ** |

### Propiedad crítica: `minuto`

- **Se guarda en el momento que ocurre el evento**, en el minuto de la matriz donde se ejecuta.
- Si el jugador cierra el juego el lunes 12:00 y vuelve martes 12:00, el sistema procesa lunes 12:00 → martes 12:00.
- Un evento que ocurrió lunes 6:00 **debe conservar minuto_del_lunes_6:00**, no minuto_actual (martes 12:00).
- Permite que los mensajes muestren la hora correcta del evento aunque se procesen offline.

---

## Variables Dinámicas

**En `Variables_Dinamicas.gd`:**

```gdscript
@export var Mensajes: Array[Mensaje] = []
```

- Se inicializa vacío al empezar una nueva partida.
- Se persiste en save/load (guardado binario).
- Sin límite de tamaño (puede crecer indefinidamente).
- No hay categorías ni filtros por ahora (all messages unfiltered).

---

## Flujo de Creación de Mensajes

### Punto 0: TESTING — Crear un mensaje cada minuto

**De momento, por testing:** En `Actividades.Actualizar_Horario(minuto)`, al final del loop de minutos:

```gdscript
# TEMPORAL: Para testing, crear un mensaje cada minuto
var mensaje = Mensaje.new()
mensaje.titulo = "Mensaje de prueba - Minuto %d" % Variables_Dinamicas.Minute
mensaje.descripcion = "Este es un mensaje automático para testing"
mensaje.leido = false
mensaje.minuto = Variables_Dinamicas.Minute

Variables_Dinamicas.Mensajes.append(mensaje)
# Guardar NO es necesario cada minuto (ya se guarda al final de Actualizar_Horario)
```

**Luego se cambiará** a crear mensajes solo en eventos reales (despidos, cambios de estado, etc.).

### Punto 1: Evento ocurre en la matriz

En cualquier función de `Actividades.gd`, `Trabajo.gd` o lógica de eventos:

```gdscript
func evento_algo_ocurrio():
    # El evento ocurre AHORA, en este minuto de la matriz
    var mensaje = Mensaje.new()
    mensaje.titulo = "Título del evento"
    mensaje.descripcion = "Explicación detallada"
    mensaje.leido = false
    mensaje.minuto = Variables_Dinamicas.Minute  # ← CRÍTICO: usar Minute actual
    
    Variables_Dinamicas.Mensajes.append(mensaje)
    # No hace falta guardar aquí, ya lo hace Actualizar_Horario al final
```

### Ejemplo: Despido de trabajo (futuro)

En `Trabajo.gd`, cuando se cancela un trabajo:

```gdscript
func Cancelar_Trabajo_Fijo():
    var mensaje = Mensaje.new()
    mensaje.titulo = "Trabajo cancelado"
    mensaje.descripcion = "Te han despedido del trabajo por bajo rendimiento"
    mensaje.leido = false
    mensaje.minuto = Variables_Dinamicas.Minute
    
    Variables_Dinamicas.Mensajes.append(mensaje)
```

### Punto 2: Jugador abre pantalla de Mensajes

GUI en `Gestionar_Visibilidad.gd`:

```gdscript
func Visibilizar_Mensajes(raiz):
    Quitar_Todo(raiz)
    Visibilizar_Lo_Basico(raiz)
    raiz.get_node("Pantalla_Mensajes").visible = true
```

### Punto 3: Jugador abre un mensaje no leído

En el script de la pantalla de mensajes:

```gdscript
func _on_mensaje_clicked(indice: int):
    var mensaje = Variables_Dinamicas.Mensajes[indice]
    
    # Mostrar contenido
    titulo_label.text = mensaje.titulo
    descripcion_label.text = mensaje.descripcion
    
    # Marcar como leído
    if not mensaje.leido:
        mensaje.leido = true
        Guardar_Variables_Dinamicas.save_game()
```

---

## UI: Pantalla de Perfil/Mensajes

### Nodos a crear

Jerarquía tentativa en la escena principal:

```
Escena_Principal
├── [otros nodos]
├── Pantalla_Mensajes (Panel)
│   ├── Titulo_Label ("Mensajes")
│   ├── Lista_Mensajes (ItemList o ScrollContainer)
│   │   └── VBoxContainer
│   │       └── [Items dinámicos]
│   ├── Contenido_Mensaje (Panel, se muestra al pulsar un mensaje)
│   │   ├── Titulo_Mensaje_Label
│   │   ├── Descripcion_Mensaje_Label
│   │   ├── Hora_Mensaje_Label (muestra fecha/hora del minuto)
│   │   └── Boton_Volver
│   └── Boton_Cerrar
├── Botones_Barra_Abajo
│   ├── [...otros botones]
│   └── Boton_Perfil (NUEVO)
```

### Integración en visibilidad

**En `Gestionar_Visibilidad.gd`:**

1. Añadir nodo a la lista de pantallas ocultas en `Quitar_Todo()`.
2. Crear función:
   ```gdscript
   func Visibilizar_Mensajes(raiz):
       Quitar_Todo(raiz)
       Visibilizar_Lo_Basico(raiz)
       raiz.get_node("Pantalla_Mensajes").visible = true
   ```

3. Hacer visible el botón "Perfil" en `Visibilizar_Lo_Basico()`:
   ```gdscript
   raiz.get_node("Botones_Barra_Abajo/Boton_Perfil").visible = true
   ```

### Ubicación del botón Perfil

- **Ubicación:** Donde está el botón Tienda ahora (en la posición actual de Tienda).
- **Tienda se mueve:** Ligéramente a la derecha para que no se solapen (lado a lado).
- **Z-index:** 10 (superpuesto).
- **Orden en árbol:** Al final (después de otros nodos para que se dibuje encima).
- **Comportamiento:** Al pulsar → llama `Gestionar_Visibilidad.Visibilizar_Mensajes(raiz)`.

### Renderizado de lista (Estilo Gmail)

Cuando se entra a la pantalla, mostrar lista ordenada por fecha (más recientes primero):

```gdscript
func _on_visibilizar_mensajes():
    var lista = Pantalla_Mensajes.get_node("Lista_Mensajes/VBoxContainer")
    
    # Limpiar items anteriores
    for child in lista.get_children():
        child.queue_free()
    
    # Ordenar mensajes por fecha (más recientes primero)
    var mensajes_ordenados = Variables_Dinamicas.Mensajes.duplicate()
    mensajes_ordenados.sort_custom(func(a, b): return a.minuto > b.minuto)
    
    for i in range(mensajes_ordenados.size()):
        var mensaje = mensajes_ordenados[i]
        var indice_original = Variables_Dinamicas.Mensajes.find(mensaje)
        
        # Crear panel/container para cada mensaje (estilo Gmail)
        var item_panel = Panel.new()
        item_panel.set_meta("mensaje_index", indice_original)
        
        # Color de fondo según si está leído
        var stylebox = StyleBox.new()
        if mensaje.leido:
            stylebox.bg_color = Color(0.95, 0.95, 0.95)  # Gris claro
        else:
            stylebox.bg_color = Color(1.0, 1.0, 1.0)  # Blanco
        item_panel.add_theme_stylebox_override("panel", stylebox)
        
        # Contenido: HBoxContainer con fecha + título
        var hbox = HBoxContainer.new()
        var fecha_label = Label.new()
        var fecha_hora = Funciones_Globales.Convertir_Minuto_A_Fecha_Hora(mensaje.minuto)
        fecha_label.text = fecha_hora
        fecha_label.custom_minimum_size = Vector2(100, 0)  # Ancho fijo
        
        var titulo_label = Label.new()
        titulo_label.text = mensaje.titulo
        titulo_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        
        hbox.add_child(fecha_label)
        hbox.add_child(titulo_label)
        item_panel.add_child(hbox)
        
        # Conectar click
        item_panel.gui_input.connect(_on_mensaje_item_clicked.bindv([indice_original]))
        lista.add_child(item_panel)
```

### Mostrar contenido de un mensaje

```gdscript
func mostrar_mensaje(indice: int):
    var contenido = Pantalla_Mensajes.get_node("Contenido_Mensaje")
    var mensaje = Variables_Dinamicas.Mensajes[indice]
    
    contenido.get_node("Titulo_Mensaje_Label").text = mensaje.titulo
    contenido.get_node("Descripcion_Mensaje_Label").text = mensaje.descripcion
    
    # Convertir minuto a fecha/hora legible
    var fecha_hora = Funciones_Globales.Convertir_Minuto_A_Fecha_Hora(mensaje.minuto)
    contenido.get_node("Hora_Mensaje_Label").text = fecha_hora
    
    contenido.visible = true
    
    # Marcar como leído
    if not mensaje.leido:
        mensaje.leido = true
        Guardar_Variables_Dinamicas.save_game()
```

---

## Conversión de minuto a fecha/hora

**En `Funciones_Globales.gd`, crear:**

```gdscript
func Convertir_Minuto_A_Fecha_Hora(minuto: int) -> String:
    # minuto es el minuto absoluto en la matriz
    # Ejemplo: minuto 1000 = columna, fila específica
    # Devolver string legible: "Lunes, 6:40"
    
    var dia_absoluto = minuto / 1440  # Días desde inicio
    var minuto_del_dia = minuto % 1440  # Minuto dentro del día
    
    var hora = minuto_del_dia / 60
    var minuto_final = minuto_del_dia % 60
    
    var dias_semana = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]
    var dia_semana_nombre = dias_semana[dia_absoluto % 7]
    
    return "%s, %d:%02d" % [dia_semana_nombre, hora, minuto_final]
```

---

## Persistencia (Save/Load)

### Al guardar (`Guardar_Variables_Dinamicas.gd`)

```gdscript
func save_game():
    var file = FileAccess.open(path, FileAccess.WRITE)
    # ... otras variables ...
    file.store_var(Variables_Dinamicas.Mensajes)  # Guardar array entero
```

**Nota:** Como `Mensaje` es un `Resource`, Godot lo serializa automáticamente.

### Al cargar

```gdscript
func load_game():
    var file = FileAccess.open(path, FileAccess.READ)
    # ... otras variables ...
    if file.get_var():
        Variables_Dinamicas.Mensajes = file.get_var()
    else:
        Variables_Dinamicas.Mensajes = []
```

---

## Casos de Uso

### Caso 1: Despido de trabajo
- **Evento:** Se cancela un trabajo fijo porque requisitos ya no se cumplen.
- **Mensaje creado:** "Trabajo cancelado - Despedido por falta de higiene"
- **Minuto:** El minuto exacto en que ocurrió en la matriz.

### Caso 2: Cambio de estado en la calle
- **Evento:** Automáticamente vas a la calle (dinero insuficiente para alquiler).
- **Mensaje creado:** "Sin alojamiento - No tenías dinero para pagar alquiler"
- **Minuto:** Minuto del evento.

### Caso 3: Evento offline
- **Escenario:** Cierra juego lunes 12:00, abre martes 12:00.
- **Evento:** Despido de trabajo ocurrió lunes 18:00.
- **Mensaje:** Se crea con minuto_lunes_18:00.
- **GUI muestra:** "Lunes, 18:00" (correcto, no "Martes, 12:00").

---

## Notas Técnicas

| Aspecto | Detalle |
|---------|---------|
| **Clase base** | Resource (serializable) |
| **Límite de mensajes** | Ninguno por ahora |
| **Orden** | Se muestran en orden de creación (FIFO) |
| **Filtros** | No hay (mostrar todos) |
| **Categorías** | No hay (todo bajo "Mensajes") |
| **Notificaciones push** | No; solo en-juego |
| **Badges/Contadores** | Mostrar "X sin leer" en botón Perfil (futuro) |

---

## Convenciones de Nombres (Godot)

- **Nodos:** `Pantalla_Mensajes`, `Boton_Perfil`, `Lista_Mensajes`
- **Recursos:** `Mensaje.gd`, `Scripts/Logica/Mensajes/Mensaje.gd`
- **Funciones:** `Visibilizar_Mensajes()`, `Convertir_Minuto_A_Fecha_Hora()`

---

## Checklist de Implementación

- [ ] Crear `Scripts/Logica/Mensajes/Mensaje.gd` (class_name, @export properties)
- [ ] Añadir `Mensajes: Array[Mensaje]` a `Variables_Dinamicas.gd`
- [ ] Crear nodos UI: `Pantalla_Mensajes`, `Boton_Perfil`, `Lista_Mensajes`, etc.
- [ ] Mover botón Tienda a la derecha, crear botón "Perfil" en su posición
- [ ] Integrar en `Gestionar_Visibilidad.Visibilizar_Lo_Basico()` y `Visibilizar_Mensajes()`
- [ ] Implementar renderizado de lista (estilo Gmail: blanco=no leído, gris=leído, fecha + título, ordenado por fecha)
- [ ] Implementar marcar como leído al abrir
- [ ] Crear `Funciones_Globales.Convertir_Minuto_A_Fecha_Hora()`
- [ ] Actualizar save/load para persistencia de Mensajes
- [ ] **[TESTING]** Crear un mensaje cada minuto en `Actividades.Actualizar_Horario()`
- [ ] Crear casos de prueba (test_mensajes.gd)
- [ ] **[FUTURO]** Integrar creación de mensajes en eventos reales (Trabajo, Actividades, etc.)
# Sistema de Muerte

## Descripción

Cada minuto de juego el personaje tiene una pequeña probabilidad de morir. La probabilidad depende de dos factores: la edad (factor dominante, crecimiento exponencial) y la media de las necesidades básicas (factor modulador, hasta ~8x de diferencia entre mínimo y máximo). Cuando se muere, el juego vuelve al menú y muestra estadísticas de la partida. No se puede continuar.

---

## Fórmula

```gdscript
# En Actividades.gd → Comprobar_Muerte()

# Muerte garantizada al último minuto de la matriz (99 años, domingo 23:59)
if Minute_Day >= 573 and Minute_Minute >= 1439:
    return true

var edad = 18 + int(Minute_Day / 7.0)

var media_nec = sum(Necesidades_Basicas) / 5.0   # 0–100

var factor_edad = pow(2.0, (edad - 18) / 10.0)   # se dobla cada 10 años
var factor_nec  = pow(35.0, media_nec / 100.0)    # rango [1.0, 35.0]

var max_valor = max(1, int(1_875_000.0 * factor_nec / factor_edad))

# Muere si sale el 0 de un dado de max_valor caras
return randi() % max_valor == 0
```

### Parámetros clave

| Parámetro | Valor | Significado |
|---|---|---|
| BASE | 1.875.000 | Escala global de peligrosidad |
| Base factor_edad | 2.0 | El riesgo se dobla cada 10 años de vida |
| Base factor_nec | 35.0 | Las necesidades al 100% dan 35x más protección que al 0% |
| Límite duro | Minute_Day ≥ 573 y Minute_Minute ≥ 1439 | Muerte garantizada a los 99 años |

---

## Esperanza de vida por media de necesidades básicas

La **esperanza de vida** es la edad a la que el 50% de las partidas ya han terminado (mediana estadística).

La relación es **casi perfectamente lineal**: `esperanza_vida ≈ 50 + media/2`

| Media necesidades | Esperanza de vida | P(llegar a esa edad) |
|---|---|---|
| 1 | ~51 años | 50% |
| 10 | ~55 años | 50% |
| 20 | ~60 años | 50% |
| 30 | ~65 años | 50% |
| 40 | ~70 años | 50% |
| 50 | ~75 años | 50% |
| 60 | ~80 años | 50% |
| 70 | ~85 años | 50% |
| 80 | ~90 años | 50% |
| 90 | ~95 años | 50% |
| 100 | ~100 años | 50% |

---

## Probabilidad de supervivencia acumulada

Probabilidad de **llegar vivo** a una edad dada según la media de necesidades.

| Edad | media=20 (vagabundo) | media=50 (normal) | media=80 (cuidado) |
|---|---|---|---|
| 40 | 87.3% | 95.5% | 98.4% |
| 50 | 73.3% | 90.2% | 96.5% |
| 60 | 51.7% | 80.2% | 92.7% |
| 65 | 38.7% | 72.9% | 89.7% |
| 70 | 25.8% | 63.6% | 85.6% |
| 75 | 14.5% | 52.5% | 80.1% |
| 80 | 6.4% | 39.9% | 72.9% |
| 85 | 2.0% | 27.2% | 63.8% |
| 90 | 0.4% | 15.9% | 53.0% |
| 95 | 0.04% | 7.2% | 40.4% |
| 99 | 0.003% | 3.1% | 30.3% |

Verificación de consistencia con la tabla de esperanza de vida:
- media=20: P(75) = 14.5%, P(60) = 51.7% → mediana entre 60 y 65 ✓
- media=50: P(75) = 52.5%, P(80) = 39.9% → mediana entre 75 y 80 ✓
- media=80: P(90) = 53.0%, P(95) = 40.4% → mediana entre 90 y 95 ✓

---

## Probabilidad instantánea por minuto

Probabilidad de morir **en un minuto concreto** (`1 / max_valor`) para distintas edades y niveles de necesidades.

| Edad | media=20 | media=50 | media=80 |
|---|---|---|---|
| 20 | 1 en 3.223.000 | 1 en 9.656.000 | 1 en 28.045.000 |
| 30 | 1 en 1.611.000 | 1 en 4.828.000 | 1 en 14.022.000 |
| 40 | 1 en 806.000 | 1 en 2.414.000 | 1 en 7.011.000 |
| 50 | 1 en 403.000 | 1 en 1.207.000 | 1 en 3.506.000 |
| 60 | 1 en 201.000 | 1 en 604.000 | 1 en 1.753.000 |
| 70 | 1 en 101.000 | 1 en 302.000 | 1 en 876.000 |
| 75 | 1 en 71.000 | 1 en 213.000 | 1 en 620.000 |
| 80 | 1 en 50.000 | 1 en 151.000 | 1 en 438.000 |
| 85 | 1 en 36.000 | 1 en 107.000 | 1 en 310.000 |
| 90 | 1 en 25.000 | 1 en 76.000 | 1 en 220.000 |
| 95 | 1 en 18.000 | 1 en 53.000 | 1 en 155.000 |

---

## Probabilidad anual de morir por edad

| Edad | media=20 | media=50 | media=80 |
|---|---|---|---|
| 40 | 1.25% | 0.42% | 0.14% |
| 50 | 2.49% | 0.83% | 0.29% |
| 60 | 4.89% | 1.66% | 0.57% |
| 70 | 9.52% | 3.29% | 1.14% |
| 75 | 13.2% | 4.62% | 1.61% |
| 80 | 18.1% | 6.46% | 2.28% |
| 85 | 24.7% | 8.99% | 3.20% |
| 90 | 33.0% | 12.5% | 4.48% |

---

## Casuísticas relevantes del juego

### Jugador en la calle (vagabundo)
- Las necesidades se capan a 20 (`BANCARROTA_MAX_NECESIDAD`)
- Las actividades aleatorias las pueden subir hasta ~30
- Media efectiva: entre 20 y 30
- **Esperanza de vida: 60–65 años**

### Jugador normal sin optimizar
- Necesidades fluctúan alrededor de 50
- **Esperanza de vida: ~75 años**

### Jugador que cuida sus necesidades
- Media sostenida en torno a 70–80
- **Esperanza de vida: 85–90 años**

### Jugador perfectamente optimizado
- Media sostenida en torno a 90–100
- **Esperanza de vida: 95–100 años**

---

## Variables nuevas en Variables_Dinamicas

| Variable | Tipo | Valor inicial | Descripción |
|---|---|---|---|
| `Muerto` | bool | false | Flag de muerte. Si es true al cargar, el juego salta directamente al menú con stats. |
| `Edad_Muerte` | int | 0 | Edad en años en el momento de morir. Se usa para la pantalla de game over. |
| `Prob_Supervivencia_Acumulada` | float | 1.0 | Producto acumulado de `(1 - p_minuto)` desde el inicio. Solo para debug. |

Todas se guardan y cargan en `Guardar_Variables_Dinamicas.gd` con fallback para saves antiguos.

---

## Flujo de game over

1. `Actividades.Actualizar_Horario()` llama `Comprobar_Muerte()` al final de cada tick.
2. Si devuelve `true`: pone `Muerto=true`, `Edad_Muerte`, y retorna `true` desde `Actualizar_Horario()`.
3. `Script_Principal._process()` detecta el retorno, guarda y llama `get_tree().change_scene_to_file("res://Escenas/Menu/Menu.tscn")`.
4. Si al cargar la escena principal `Muerto==true` (partida muerta guardada): redirige al menú sin procesar ningún minuto.
5. `Menu._ready()` detecta `Muerto==true` y llama `_Mostrar_Game_Over()`.
6. La pantalla de game over muestra: edad de muerte, progreso final (Deporte/Académico/Manualidades), dinero, carreras completadas.

---

## Log de debug

Cada vez que se procesa un batch de minutos, el output de Godot muestra:

```
[Muerte] Edad: 45 | P.minuto: 0.00000147% (1 en 680272) | P.acumulada: 2.3841%
```

- **P.minuto**: probabilidad de morir en ese minuto exacto.
- **P.acumulada**: probabilidad de haber muerto en cualquier minuto anterior (= `1 - Prob_Supervivencia_Acumulada`).

---

## Archivos modificados

| Archivo | Cambio |
|---|---|
| `Scripts/Logica/Escena_Principal/Actividades/Actividades.gd` | `Comprobar_Muerte()`, `_Guardar_Log_Muerte()`, `Actualizar_Horario()` retorna bool |
| `Scripts/Globales/Script_Principal.gd` | Detecta muerte en `_process()`, redirige si `Muerto` en `_ready()` |
| `Scripts/Globales/Menu.gd` | `_Mostrar_Game_Over()` con estadísticas |
| `Scripts/Globales/Principales_Variables/Variables_Dinamicas.gd` | `Muerto`, `Edad_Muerte`, `Prob_Supervivencia_Acumulada` |
| `Scripts/Otro/Guardar/Guardar_Variables_Dinamicas.gd` | Guarda/carga las 3 nuevas variables |

---

# Personaje, Vestuario, Envejecimiento y Escenografía de Inicio (nov 2026)

## 1. Creador y Apariencia (`Apariencia_Personaje.gd` + `Creador_Personaje.gd`)
- Flujo guiado en **6 pasos** (Identidad, Cuerpo, Cara, Pelo, Ropa, Extras) con barra de progreso, valor actual por sección, botones Atrás/Siguiente, 3 niveles de zoom (`Cara`, `Busto`, `Cuerpo`), barra de poses en vivo y arquetipos rápidos.
- Configura complexión (`atletica`, `normal`, `robusta`), 12 tonos de piel, rasgos faciales, 16 peinados, 7 estilos de vello facial, ropa por partes con calzado/complementos y personalidad (`Variables_Estaticas.Personalidad`).
- Se refleja en `Menu.gd`, `Logo_Juego.gd` (medallón dinámico), `Intro_Nueva_Partida.gd`, avatar de cabecera, Perfil → Info y Home (`Escenario_Actividad`).

## 2. Envejecimiento y Rejuvenecimiento (`Envejecimiento_Personaje.gd`)
- `Envejecimiento_Personaje.gd` aplica canas, arrugas, manchas, piel apagada/flacidez, cejas finas y postura encorvada mediante curvas suaves (`CURVAS`, 0 a los 18 años → 1 a los 100 años).
- `Personaje_Visual.edad = -1` consulta `Variables_Estaticas.Calcular_Edad()` en cada dibujo, de modo que **Tienda → Bienestar** (`Rejuvenecimiento_Anios`, suelo 18 años) rejuvenece al personaje en todos los retratos, HUD y escenas al instante.

## 3. Vestuario (`Pantalla_Vestuario.gd` + `Ropa_Catalogo.gd`)
- Sección propia accesible desde `Vestuario_Button` (barra superior), botón «Vestuario» en Inicio y «Cambiar de atuendo» en Perfil → Info.
- **25 atuendos** (`Objeto_Ropa`, categoría `"Ropa"`): 10 gratis de inicio, 11 comprables en tienda y 4 desbloqueables por **Maestría Culinaria** (Rangos 1, 3, 6 y 9; cada rango = 20 ★ en `Minijuego_Cocina`).
- Filtros por categoría (`diario`, `deporte`, `elegante`, `trabajo`, `fiesta`, `cocina`), compra integrada, vista previa animada con chips de bonificaciones (progreso, salario hostelería, propinas, reducción de desgaste de higiene) y tarjeta de **Maestría Culinaria** visible únicamente en el filtro `Cocina`.
- `Personaje_Visual._dibujar_atuendo_encima()` dibuja los 19 estilos visuales en todas las animaciones del Sim.

## 4. Escenografía de Inicio (`Escenario_Actividad.gd` + `Escenografia_Inicio.gd`)
- `Escenario_Actividad.gd` muestra en tiempo real la actividad actual del Sim (o su tiempo libre `idle`).
- `Escenografia_Inicio.gd` dibuja las **11 escenografías de actividad** (`correr`, `dormir`, `comer`, `duchar`, `estudiar`, `tv`, `manualidades`, `cocinar`, `fiesta`, `futbol`, `trabajar`) adaptadas a la franja horaria (`_franja_horaria()`: mañana, tarde, atardecer, noche), muebles equipados y variante de calle (`idle`/`comer`).
- El tiempo libre (`idle`) muestra un salón cálido con ventana al cielo, planta y encimera con el Sim detrás de la barra (sin comida ni platos).
- Cada pose tiene 3–6 micro-acciones en `VARIACIONES` con mezcla de rig del 14 % al inicio y al final (`obtener_rig_pose()`) y fundido de escena de `0,28 s` al cambiar de actividad.
- QA reproducible con `Debug_Pose_Inicio.gd` y escenas `Captura_{Tiempo_Libre,Poses_Inicio,Animaciones_Inicio,Home_Poses,Variantes_Inicio}.tscn`. Doc: `Funcionalidades/Personaje/Documentacion/ESCENARIO_INICIO.md` y `Funcionalidades/Vestuario/Documentacion/VESTUARIO.md`.
