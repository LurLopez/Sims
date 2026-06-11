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

### Mostrar contenido de un libro

```gdscript
func _Mostrar_Apunte(carrera, año: int):
    var texto = $Pantalla_Mensajes/Panel_Apuntes/Texto_Apuntes
    var ruta = "res://Scripts/Logica/Escena_Principal/Actividades/Carreras/Contenido/apuntes_ing_informatica_anio%d.txt" % año
    if FileAccess.file_exists(ruta):
        texto.text = FileAccess.get_file_as_string(ruta)
    else:
        texto.text = "Apuntes no disponibles para Año %d." % año
```

---

## Origen de los libros (sistema de Carreras)

Los libros se desbloquean en `Sistema_Examenes.gd` cuando el jugador supera un examen:

```gdscript
var libro_siguiente = "Anio_%d" % carrera.año_actual
if not carrera.libros_desbloqueados.has(libro_siguiente):
    carrera.libros_desbloqueados.append(libro_siguiente)
```

El formato de cada entrada en `libros_desbloqueados` es el string `"Anio_1"`, `"Anio_2"`, etc. `_Renderizar_Apuntes` extrae el número con `.replace("Anio_", "")`.

---

## Archivos de contenido

Los textos de los libros son archivos `.txt` en:

```
res://Scripts/Logica/Escena_Principal/Actividades/Carreras/Contenido/
├── apuntes_ing_informatica_anio1.txt
├── apuntes_ing_informatica_anio2.txt
├── apuntes_ing_informatica_anio3.txt
└── apuntes_ing_informatica_anio4.txt
```

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
