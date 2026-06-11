# Perfil

## Descripción General
Pantalla de perfil del jugador accesible desde el botón "👤 Perfil" en la barra superior izquierda. Organizada en tres pestañas: **Info** (datos del personaje), **Mensajes** (bandeja de mensajes del juego) e **Inventario/Apuntes** (libros desbloqueados). Se abre siempre en la pestaña Info.

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
│   └── Tab_Apuntes (Button, "Apuntes")
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

### Tab Info — renderizado

```gdscript
func _Renderizar_Info():
    var vbox = $Pantalla_Mensajes/Panel_Info/Scroll_Info/VBox_Info
    for child in vbox.get_children():
        child.queue_free()

    var edad = 18 + (Variables_Dinamicas.Minute_Day - Variables_Estaticas.First_Time_Minute_Day) / 7
    var personalidad = Variables_Estaticas.Personalidad.replace("_", " ")

    _Info_Seccion(vbox, "PERSONAJE")
    _Info_Fila(vbox, "Edad", str(edad) + " años")
    _Info_Fila(vbox, "Personalidad", personalidad)
    _Info_Fila(vbox, "Dinero", str(int(Variables_Dinamicas.Dinero)) + " €")

    _Info_Seccion(vbox, "PROGRESO")
    _Info_Fila(vbox, "Deporte", str(Variables_Dinamicas.Progreso[0]) + " / 100")
    _Info_Fila(vbox, "Académico", str(Variables_Dinamicas.Progreso[1]) + " / 100")
    _Info_Fila(vbox, "Manualidades", str(Variables_Dinamicas.Progreso[2]) + " / 100")

    _Info_Seccion(vbox, "HABILIDADES INNATAS")
    var nombres_hab = ["Deporte", "Inteligencia", "Destreza manual", "Memoria", "Liderazgo", "Paciencia"]
    for i in range(min(nombres_hab.size(), Variables_Estaticas.Habilidades.size())):
        _Info_Fila(vbox, nombres_hab[i], str(Variables_Estaticas.Habilidades[i]) + " / 100")

# CRÍTICO: la edad se recalcula cada vez que se abre — no se guarda como variable
# Fórmula: 18 + (Minute_Day - First_Time_Minute_Day) / 7  (división entera)
```

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
| Edad calculada | División entera: 18 + (Minute_Day - First_Time_Minute_Day) / 7 |
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
| Panel Info | `Panel_Info` |
| Scroll Info | `Scroll_Info / VBox_Info` |
| Función visibilidad | `Gestionar_Visibilidad.Visibilizar_Perfil(raiz)` |

---

## Checklist de Implementación

- [x] Nodo `Tab_Bar` con `Tab_Info`, `Tab_Mensajes`, `Tab_Apuntes` en escena
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
