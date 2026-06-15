# Invertir en Bolsa

## Descripción General

Sistema de inversión financiera pasiva. El jugador puede meter dinero en la "bolsa" y su valor fluctúa cada ~8 horas de juego según su habilidad inversora (`Progreso_Inversion`). El resultado a largo plazo depende de tres factores:

- **`Progreso_Inversion`** (progreso 1–100): determina la tendencia; al principio es muy probable perder, al final muy probable ganar.
- **`Salud_Mental_Al_Invertir`** (snapshot): la salud mental en el **momento exacto de invertir** modifica la probabilidad. Después no cambia aunque cambie la salud mental real.
- **`Sangre_Fría` (`Habilidades[6]`)**: si es muy baja (<30) y la pérdida supera el 15%, el personaje entra en pánico y retira automáticamente la inversión.

El objetivo en el juego es que el jugador aprenda a invertir durante los ~60 años de partida, pasando de perder dinero al principio a ganar de forma consistente al final.

---

## Variables Dinámicas / Estáticas afectadas

| Variable | Tipo | Rango | Descripción |
|---|---|---|---|
| `Variables_Dinamicas.Esta_Invirtiendo` | `bool` | — | `true` mientras haya dinero en bolsa |
| `Variables_Dinamicas.Dinero_Invertido` | `float` | ≥ 0 | Cantidad original puesta (base para calcular %) |
| `Variables_Dinamicas.Valor_Inversion` | `float` | ≥ 0 | Valor actual de la cartera (sube/baja con los ticks) |
| `Variables_Dinamicas.Salud_Mental_Al_Invertir` | `int` | 1–100 | Snapshot de `Necesidades_Basicas[1]` al pulsar "Invertir" |
| `Variables_Dinamicas.Progreso_Inversion` | `int` | 1–100 | Habilidad inversora; sube mientras se está invertido |
| `Variables_Estaticas.Habilidades[6]` | `int` | 1–100 | Sangre Fría: umbral de auto-venta por pánico |

---

## Flujo de Ejecución

### 1. El jugador invierte

Desde `Script_Principal._Confirmar_Invertir()`:

```gdscript
var cantidad = float(texto)
# CRÍTICO: El snapshot de salud mental se toma aquí, no cambia durante la inversión.
Variables_Dinamicas.Dinero -= cantidad
Variables_Dinamicas.Dinero_Invertido = cantidad
Variables_Dinamicas.Valor_Inversion = cantidad
Variables_Dinamicas.Esta_Invirtiendo = true
Variables_Dinamicas.Salud_Mental_Al_Invertir = int(Variables_Dinamicas.Necesidades_Basicas[1])
```

### 2. Tick por minuto (en `Actividades.Actualizar_Horario`)

Cada minuto procesado:

```gdscript
if Variables_Dinamicas.Esta_Invirtiendo:
    _Tick_Inversion()
```

### 3. `_Tick_Inversion()` en `Actividades.gd`

```gdscript
func _Tick_Inversion():
    # Evento de mercado: probabilidad 1/480 por minuto (~1 vez cada 8 horas).
    if randi() % 480 != 0:
        return

    var progreso = Variables_Dinamicas.Progreso_Inversion
    var mental = Variables_Dinamicas.Salud_Mental_Al_Invertir

    # prob_subida: 0.15 en progreso=1, 0.50 en progreso=50, 0.85 en progreso=100.
    var tendencia = (progreso - 1.0) / 99.0
    var factor_mental = (mental - 50.0) / 300.0
    var prob_subida = clamp(0.15 + tendencia * 0.70 + factor_mental, 0.05, 0.95)

    var cambio_pct = (randi() % 26 + 5) / 1000.0  # 0.5% a 3.0%

    if randf() < prob_subida:
        Variables_Dinamicas.Valor_Inversion += Variables_Dinamicas.Valor_Inversion * cambio_pct
    else:
        Variables_Dinamicas.Valor_Inversion -= Variables_Dinamicas.Valor_Inversion * cambio_pct
        Variables_Dinamicas.Valor_Inversion = max(0.0, Variables_Dinamicas.Valor_Inversion)

    # CRÍTICO: Auto-venta solo si Sangre_Fría < 30 Y pérdida > 15%.
    var sangre_fria = Variables_Estaticas.Habilidades[6]
    if sangre_fria < 30 and Variables_Dinamicas.Dinero_Invertido > 0:
        var pct_cambio = (Variables_Dinamicas.Valor_Inversion - Variables_Dinamicas.Dinero_Invertido) / Variables_Dinamicas.Dinero_Invertido
        if pct_cambio < -0.15:
            _Auto_Vender_Inversion()
            return

    # Mejora de Progreso_Inversion: 1/20 por evento (~1 punto cada 2 semanas).
    if Variables_Dinamicas.Progreso_Inversion < 100:
        if randi() % 20 == 0:
            Variables_Dinamicas.Progreso_Inversion += 1
```

### 4. `_Auto_Vender_Inversion()` — venta por pánico

```gdscript
func _Auto_Vender_Inversion():
    var invertido = Variables_Dinamicas.Dinero_Invertido
    var valor_actual = Variables_Dinamicas.Valor_Inversion
    var pct_perdida = (invertido - valor_actual) / invertido * 100.0 if invertido > 0 else 0.0
    Variables_Dinamicas.Dinero += valor_actual
    Variables_Dinamicas.Esta_Invirtiendo = false
    Variables_Dinamicas.Valor_Inversion = 0.0
    Variables_Dinamicas.Dinero_Invertido = 0.0
    # Envía mensaje al perfil del jugador.
    var msg = Mensaje.new()
    msg.titulo = "Inversión retirada automáticamente"
    msg.descripcion = "Tu sangre fría es baja. Al alcanzar un %.0f%% de pérdidas has entrado en pánico..." % [pct_perdida]
    msg.leido = false
    msg.minuto = Variables_Dinamicas.Minute
    Variables_Dinamicas.Mensajes.append(msg)
```

### 5. El jugador retira manualmente

Desde `Script_Principal._Confirmar_Retirar()`:

```gdscript
Variables_Dinamicas.Dinero += Variables_Dinamicas.Valor_Inversion
Variables_Dinamicas.Esta_Invirtiendo = false
Variables_Dinamicas.Valor_Inversion = 0.0
Variables_Dinamicas.Dinero_Invertido = 0.0
```

---

## UI: Nodos y Visibilidad

### Botón de inversión

Creado dinámicamente en `Script_Principal._Inicializar_Boton_Inversion()`:

```
Escena_Principal (raíz)
  └── Inversion_Button  (Button, z_index=10, left=495, top=10, right=718, bottom=60)
```

**Texto del botón:**
- Sin invertir: `"Invertir\nen Bolsa"`
- Invirtiendo: `"Bolsa\n700€ (+15.3%)"` (valor actual + % respecto al invertido)

Se actualiza cada frame desde `Script_Principal.Actualizar_Dinero()` → `_Actualizar_Boton_Inversion()`.

`Gestionar_Visibilidad.Visibilizar_Lo_Basico()` incluye `raiz.inversion_button.visible = true`.

### Ventana de inversión (entrada de cantidad)

`Window` personalizado creado la primera vez que se pulsa:
- Campo `LineEdit` para introducir la cantidad en €
- Label actualizado con el dinero disponible en el momento
- Botones "Invertir" / "Cancelar"

### Diálogo de retirada

`ConfirmationDialog` estándar que muestra valor actual y % de ganancia/pérdida.

### Pantalla de Perfil (Tab Info)

`_Renderizar_Info()` añade la fila `"Inversiones  X / 100"` en la sección PROGRESO.

---

## Persistencia (Save/Load)

En `Guardar_Variables_Dinamicas.gd`:

| Clave | Tipo | Fallback para saves antiguos |
|---|---|---|
| `"Esta_Invirtiendo"` | bool | `false` |
| `"Dinero_Invertido"` | float | `0.0` |
| `"Valor_Inversion"` | float | `0.0` |
| `"Salud_Mental_Al_Invertir"` | int | `50` |
| `"Progreso_Inversion"` | int | `1` |

Se guarda con `store_var` binario al mismo archivo que el resto de variables dinámicas.

---

## Casos de Uso

| Escenario | Qué ocurre | Resultado esperado |
|---|---|---|
| Jugador pulsa "Invertir en Bolsa" sin inversión activa | Se abre la ventana con LineEdit | Introduce 500€ → `Dinero -= 500`, `Valor_Inversion = 500` |
| Tick de mercado con Progreso_Inversion=1 | `prob_subida ≈ 15%` | La mayoría de eventos reducen `Valor_Inversion` |
| Tick de mercado con Progreso_Inversion=100 | `prob_subida ≈ 85%` | La mayoría de eventos aumentan `Valor_Inversion` |
| Sangre_Fría=15, pérdida acumulada > 15% en un tick | Condición `<30 y pct<-0.15` se cumple | Auto-venta, mensaje en perfil |
| Sangre_Fría=70, pérdida del 20% | Condición `<30` es falsa | NO hay auto-venta, sigue invertido |
| Jugador pulsa botón mientras invierte | Se muestra diálogo de confirmación con valor actual | Si acepta: `Dinero += Valor_Inversion`, fin de inversión |

---

## Notas Técnicas

| Aspecto | Detalle |
|---|---|
| Frecuencia de eventos | 1/480 por minuto → ~3 eventos por día real (1 día real = 1 año de juego) |
| Punto neutro de progreso | Progreso_Inversion ≈ 50 → prob_subida ≈ 0.50 (ni gana ni pierde en media) |
| Impacto de salud mental | ±10 pp sobre `prob_subida` (va de -0.167 a +0.167 ajustado por 300) |
| Rango de cambio por evento | 0.5% a 3.0% del `Valor_Inversion` actual |
| Valor mínimo | `max(0.0, ...)` → nunca negativo |
| Velocidad de progreso | ~1 punto cada 2 semanas reales de inversión activa (1/20 por evento × 3 eventos/día × 7 días/semana ≈ 1.05 pts/semana) |
| Sangre_Fría como innata | `Habilidades[6]` — ya generada en `First_Time.Crear_Habilidades()` (7 habilidades) |
| Snapshot de salud mental | Se captura al invertir en `Necesidades_Basicas[1]`; NO se actualiza mientras dura la inversión |

---

## Convenciones de Nombres (Godot)

| Elemento | Nombre en código |
|---|---|
| Botón dinámico | `inversion_button` (var en Script_Principal) |
| Ventana de cantidad | `_ventana_invertir` (var en Script_Principal) |
| Input de cantidad | `_input_cantidad_invertir` (LineEdit) |
| Diálogo de retirada | `_dialog_retirar` (ConfirmationDialog) |
| Tick principal | `Actividades._Tick_Inversion()` |
| Auto-venta | `Actividades._Auto_Vender_Inversion()` |

---

## Checklist de Implementación

- [x] `Variables_Dinamicas.gd`: añadir 5 variables nuevas
- [x] `First_Time.gd`: inicializar `Progreso_Inversion = 1` en `Crear_Progreso()`
- [x] `Guardar_Variables_Dinamicas.gd`: guardar y cargar las 5 variables con fallback
- [x] `Actividades.gd`: `_Tick_Inversion()`, `_Auto_Vender_Inversion()` + llamada en `Actualizar_Horario`
- [x] `Script_Principal.gd`: botón dinámico, ventana de cantidad, diálogo de retirada, `_Actualizar_Boton_Inversion()` en `Actualizar_Dinero()`
- [x] `Gestionar_Visibilidad.gd`: `inversion_button.visible = true` en `Visibilizar_Lo_Basico()`
- [x] `Script_Principal._Renderizar_Info()`: fila "Inversiones X/100" en Tab Info del perfil
