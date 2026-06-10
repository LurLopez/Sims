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
