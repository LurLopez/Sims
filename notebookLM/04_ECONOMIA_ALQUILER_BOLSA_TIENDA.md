# Análisis del Sistema de Alquiler Timer-Based

## Implementación

### Método elegido: Timer absoluto

Se implementó con `Ultima_Fecha_Alquiler` guardando el minuto absoluto en que se cobró el último alquiler.

```
Lógica de cobro: if (Minute_Actual - Ultima_Fecha_Alquiler) >= 7*1440 → Cobrar
```

**Ventajas:**
- Preciso al minuto (no depende de qué día de la semana sea)
- Si pagas el martes 14:30, próximo alquiler es martes 14:30 +7 días
- Resistente a cambios de reloj del sistema

**Alternativa rechazada:** Guardar `Proxima_Fecha_Alquiler = Ultima_Fecha + 7*1440`
- Requeriría actualizar una segunda variable
- Menos flexible ante desincronizaciones

---

## Casos de Prueba

### Test 1: Primera vez - Alquiler cobra después de 7 días
**Inicial:**
- Dinero: 1000€
- En_La_Calle: false
- Ultima_Fecha_Alquiler: 0 (minuto de creación)

**Acción:** Esperar 7 días (7*1440 = 10080 minutos)

**Esperado:**
- Dinero: 800€ (1000 - 200)
- En_La_Calle: false (sigue alquilando)
- Ultima_Fecha_Alquiler: 10080 (se actualiza al cobro)

**Validación:** ✓ Correcto
- Cuando `(10080 - 0) >= 10080` es true → se ejecuta `Cobrar_Alquiler()`
- `Cobrar_Alquiler()` restituye dinero y actualiza `Ultima_Fecha_Alquiler`

---

### Test 2: Ir a la calle voluntariamente
**Inicial:**
- Dinero: 1000€
- En_La_Calle: false
- Ultima_Fecha_Alquiler: 0

**Acción:** Pulsar botón "En alquiler" → Confirmar "Irme a la calle"

**Esperado:**
- Dinero: 1000€ (sin cambio)
- En_La_Calle: true
- Ultima_Fecha_Alquiler: -1 (se anula el timer)

**Validación:** ✓ Correcto
- `Ir_A_La_Calle()` marca `En_La_Calle=true` y `Ultima_Fecha_Alquiler=-1`
- No se cobra nada
- Próximo cobro se cancela porque `Ultima_Fecha_Alquiler < 0`

---

### Test 3: Dinero insuficiente al cobrar
**Inicial:**
- Dinero: 150€
- En_La_Calle: false
- Ultima_Fecha_Alquiler: 0

**Acción:** Esperar 7 días

**Esperado:**
- Dinero: 150€ (sin cambio, no se cobra)
- En_La_Calle: true (automáticamente a la calle)
- Ultima_Fecha_Alquiler: -1 (se anula el timer)

**Validación:** ✓ Correcto
- Cuando llega la hora de cobrar, `Cobrar_Alquiler()` chequea:
  ```gdscript
  if Variables_Dinamicas.Dinero >= ALQUILER_SEMANAL:
      # Cobrar
  else:
      # Ir a la calle sin cobrar
      Ir_A_La_Calle()
  ```
- Se preserva el dinero (no puedes quedarte en negativo)

---

### Test 4: Volver a alquiler desde la calle (con 300€)
**Inicial:**
- Dinero: 300€
- En_La_Calle: true
- Ultima_Fecha_Alquiler: -1

**Acción:** Pulsar botón "En la calle" → Se cobra 200€ automático

**Esperado:**
- Dinero: 100€ (300 - 200)
- En_La_Calle: false (vuelve a alquiler)
- Ultima_Fecha_Alquiler: Minute_Actual (nuevo timer de 7 días)

**Validación:** ✓ Correcto
- `Volver_A_Alquiler()` chequea dinero:
  ```gdscript
  if Variables_Dinamicas.Dinero >= ALQUILER_SEMANAL:
      En_La_Calle = false
      Dinero -= 200
      Ultima_Fecha_Alquiler = Minute_Actual
  ```
- Próximo cobro será en 7 días desde el minuto actual

---

### Test 5: Intenta volver a alquiler sin dinero suficiente (150€)
**Inicial:**
- Dinero: 150€
- En_La_Calle: true
- Ultima_Fecha_Alquiler: -1

**Acción:** Pulsar botón "En la calle" → No pasa nada (silenciosamente)

**Esperado:**
- Dinero: 150€ (sin cambio)
- En_La_Calle: true (se queda en la calle)
- Ultima_Fecha_Alquiler: -1 (sin cambio)

**Validación:** ✓ Correcto
- `Volver_A_Alquiler()` chequea:
  ```gdscript
  if Variables_Dinamicas.Dinero >= ALQUILER_SEMANAL:
      # Cambiar a alquiler
  else:
      pass  # No hace nada
  ```
- El usuario se queda en la calle hasta conseguir 200€

---

### Test 6: Segundo alquiler después de volver (7 días después de entrar)
**Inicial:** (Estado después de Test 4)
- Dinero: 100€
- En_La_Calle: false
- Ultima_Fecha_Alquiler: Minuto_Actual (ej: 100)

**Acción:** Esperar 7 días

**Esperado:**
- Dinero: ??? (no hay dinero suficiente para cobrar)
- En_La_Calle: true (va automáticamente a la calle)
- Ultima_Fecha_Alquiler: -1

**Validación:** ✓ Correcto - Variante de Test 3

---

## Edge Cases Identificados

### 1. Save/Load en la calle
- Al cargar un save donde estás en la calle:
  - `En_La_Calle = true`
  - `Ultima_Fecha_Alquiler = -1`
  - No hay timer activo ✓

### 2. Save/Load con timer activo
- Al cargar un save donde estás alquilando:
  - `En_La_Calle = false`
  - `Ultima_Fecha_Alquiler = <minuto anterior>`
  - Timer se reanuda correctamente ✓

### 3. Fallback para saves viejos
- En `Guardar_Variables_Dinamicas.load_game()`:
  ```gdscript
  if not game_data.has("En_La_Calle"):
      En_La_Calle = false
      Ultima_Fecha_Alquiler = Minute_Day * 1440 + Minute_Minute
  ```
  - Los saves antiguos se asumen como "en alquiler" con 7 días de gracia ✓

### 4. Necesidades capadas a 20
- Cuando `En_La_Calle = true` O `Dinero < 0`:
  - Necesidades nunca suben de 20 ✓
  - El jugador se deteriora rápidamente en la calle

---

## Conclusión

La implementación es **robusta y correcta**:
- ✓ No permite dinero negativo
- ✓ Timer basado en minutos absolutos (preciso)
- ✓ Transición suave alquiler ↔ calle
- ✓ Compatible con save/load
- ✓ Fallback para saves viejos
- ✓ Necesidades caen rápidamente en la calle (mecánica de presión)
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
# Sistema de Objetos/Muebles

## Descripción
Sistema de compra, venta y selección de objetos que afectan a necesidades básicas mediante multiplicadores de probabilidad. Inspirado en los Sims.

## Estructura

### Clases
```
Scripts/Logica/Escena_Principal/Economia/Herencia/
├── Objeto.gd (clase_name Objeto)
│   ├── nombre: String
│   ├── precio: float
│   ├── multiplicador: float (1.0 = sin efecto)
│   ├── afecta_a: String (ej: "Dormir", "Comer", "Duchar")
│   └── es_basico: bool (true = no se puede vender si es único)
├── Objeto_Dormir.gd (extends Objeto)
├── Objeto_Comer.gd (extends Objeto)
└── Objeto_Duchar.gd (extends Objeto)
```

### Variables
**Variables_Estaticas:**
```gdscript
var Catalogo_Objetos: Dictionary = {
    "Cama_Basica": Objeto_Dormir(...),    # multiplicador 1.0, es_basico true
    "Cama_Premium": Objeto_Dormir(...),   # multiplicador 1.05
    "Cama_Lujo": Objeto_Dormir(...),      # multiplicador 1.10
    # ... más objetos
}
```

**Variables_Dinamicas:**
```gdscript
var Objetos_Poseidos: Dictionary = {
    "Cama_Basica": true,
    "Cama_Premium": false,
    # ... estado de posesión
}

var Objeto_Seleccionado: Dictionary = {
    "Dormir": "Cama_Basica",    # qué objeto está usando
    "Comer": "Mesa_Basica",
    "Duchar": "Ducha_Basica"
}
```

## Flujos

### Compra
```gdscript
Actividades.Comprar_Objeto("Cama_Premium")
```
- Validación: objeto existe, no lo posee, tiene dinero
- Efecto: `-precio` dinero, `+true` en `Objetos_Poseidos`
- Retorna: `bool` (éxito/fracaso)

### Venta
```gdscript
Actividades.Vender_Objeto("Cama_Premium")
```
- Validación: lo posee, no es único de su categoría, no está seleccionado
- Efecto: `+precio*0.5` dinero, `-false` en `Objetos_Poseidos`
- Retorna: `bool`

### Selección
```gdscript
Actividades.Seleccionar_Objeto("Dormir", "Cama_Premium")
```
- Validación: lo posee, categoría coincide
- Efecto: actualiza `Objeto_Seleccionado["Dormir"]`
- Retorna: `bool`

## Lógica de Multiplicador

### Implementación Actual
En `Actividades_Necesidades_Basicas.gd`:

```gdscript
func _Obtener_Multiplicador(nombre_actividad: String) -> float:
    match nombre_actividad:
        "Dormir", "Duchar":
            var clave = Variables_Dinamicas.Objeto_Seleccionado.get(nombre_actividad, "")
            if clave == "" or not Variables_Estaticas.Catalogo_Objetos.has(clave):
                return 1.0
            return Variables_Estaticas.Catalogo_Objetos[clave].multiplicador
        _:
            return 1.0
```
Las mesas ya no modulan comer: `Comer_Tupper` usa la calidad del tupper y `Comer_Basura` tiene efectos fijos.

Aplica el multiplicador **solo a efectos positivos**:
```gdscript
if por_cuanto > 0 and multiplicador != 1.0:
    valor_maximo = max(1, floor(valor_maximo / multiplicador))
```

**Ejemplo:**
- Actividad Dormir: efecto +4 descanso cada ~15 min
- Cama Premium (1.05): efecto sube a +4.2, intervalo baja a ~14.3 min
- Resultado: descansa más rápido, NO acelera caída de hambre/higiene

### Expansión Futura (No Implementada)
**Objetivo:** Permitir objetos que reduzcan efectos negativos.

**Ejemplo:** Ropa Premium (multiplicador 0.95 en Higiene)
- Actividad normal pierde higiene cada ~20 min
- Con ropa: pierde cada ~21 min (0.95 * 20)

**Cambio necesario:**
```gdscript
if multiplicador != 1.0:
    if por_cuanto > 0:  # Efectos positivos
        valor_maximo = max(1, floor(valor_maximo / multiplicador))
    else:  # Efectos negativos
        valor_maximo = floor(valor_maximo * multiplicador)
```

**Nuevos objetos:**
- `Objeto_Higiene.gd` (extends Objeto)
- `Ropa_Premium`: precio 150, multiplicador 0.95, afecta_a "Duchar"

## Inicialización

### First_Time
```gdscript
Crear_Objetos_Iniciales()
# Inicia con los básicos de cada categoría
Objetos_Poseidos = {
    "Cama_Basica": true,
    "Mesa_Basica": true,
    "Ducha_Basica": true
}
Objeto_Seleccionado = {
    "Dormir": "Cama_Basica",
    "Comer": "Mesa_Basica",
    "Duchar": "Ducha_Basica"
}
```

### Guardado
En `Guardar_Variables_Dinamicas.gd`:
- Guarda `Objetos_Poseidos` (Dictionary)
- Guarda `Objeto_Seleccionado` (Dictionary)
- Fallback para saves antiguos: inicializa con `_Inicializar_Objetos_Por_Defecto()`

## Restricciones

1. **Obligatoriedad:** Siempre hay al menos un objeto seleccionado por categoría
2. **Venta:** No se puede vender si es el único de su categoría
3. **Venta:** No se puede vender si está actualmente seleccionado
4. **Precio:** Reventa = 50% del precio original

## Catálogo Implementado (7 objetos)

| Nombre | Categoría | Precio | Multiplicador | Básico | Descripción |
|--------|-----------|--------|----------------|--------|-------------|
| **Cama_Basica** | Dormir | 0€ | 1.0 | ✓ | Cama de inicio. No se puede vender si es única. |
| **Cama_Premium** | Dormir | 200€ | 1.05 | ✗ | Descanso 5% más rápido. |
| **Cama_Lujo** | Dormir | 800€ | 1.10 | ✗ | Descanso 10% más rápido. |
| **Mesa_Basica** | Comer | 0€ | 1.0 | ✓ | Mesa de inicio sin efecto sobre los alimentos. Ya no hay mesas premium. |
| **Ducha_Basica** | Duchar | 0€ | 1.0 | ✓ | Ducha de inicio. No se puede vender si es única. |
| **Ducha_Premium** | Duchar | 200€ | 1.05 | ✗ | Higiene 5% más rápida. |

## Testing

Ubicación: `Funcionalidades/Economia/Sistema_Objetos_Muebles/Tests/`

Tests pendientes:
- [ ] Compra exitosa y fallida (dinero insuficiente, objeto ya poseído)
- [ ] Venta exitosa y fallida (único, seleccionado)
- [ ] Selección de objeto
- [ ] Aplicación de multiplicador en actividades
- [ ] Persistencia en guardado
- [ ] Fallback para saves antiguos

## Cómo Expandir el Catálogo

### Añadir un nuevo objeto (ej: Cama Súper Premium)

```gdscript
# En Variables_Estaticas._Inicializar_Catalogo_Objetos()

var cama_super = Objeto_Dormir.new()
cama_super.nombre = "Cama_Super_Premium"
cama_super.precio = 1500.0
cama_super.multiplicador = 1.15  # +15%
cama_super.afecta_a = "Dormir"
cama_super.es_basico = false
Catalogo_Objetos["Cama_Super_Premium"] = cama_super
```

### Crear una nueva categoría (ej: Objetos para Higiene/efectos negativos)

1. Crear `Objeto_Higiene.gd`:
   ```gdscript
   class_name Objeto_Higiene
   extends Objeto
   ```

2. Añadir objetos en el catálogo:
   ```gdscript
   var ropa_premium = Objeto_Higiene.new()
   ropa_premium.nombre = "Ropa_Premium"
   ropa_premium.precio = 150.0
   ropa_premium.multiplicador = 0.95  # Reduce caída de higiene en 5%
   ropa_premium.afecta_a = "Duchar"
   ropa_premium.es_basico = false
   Catalogo_Objetos["Ropa_Premium"] = ropa_premium
   ```

3. Actualizar lógica de multiplicadores en `Actividades_Necesidades_Basicas.gd` para soportar multiplicadores < 1.0 en efectos negativos (ver sección "Expansión Futura")

## UI de la Tienda

### Estructura de Nodos

Añadida bajo el nodo raíz de `Escena_Principal.tscn`:

```
Tienda (Control, visible=false por defecto, z_index=5)
├── Flecha_Atras (Button)         ← arriba-izq, vuelve al menú
├── Titulo (Label)                ← "TIENDA"
├── Categorias (Control)
│   ├── Tab_Dormir (Button)       ← icono bed-double
│   ├── Tab_Comer (Button)        ← icono utensils
│   └── Tab_Duchar (Button)       ← icono shower-head
├── Objetos_Dormir (Control)
│   ├── Cama_Basica (Panel)
│   ├── Cama_Premium (Panel)
│   └── Cama_Lujo (Panel)
├── Objetos_Comer (Control)
│   └── Mesa_Basica (Panel)
└── Objetos_Duchar (Control)
    ├── Ducha_Basica (Panel)
    └── Ducha_Premium (Panel)
```

Cada `Panel` de objeto contiene:
- `Imagen_Placeholder` (Panel) → vitrina con el fondo tintado, la píldora de nivel (`BÁSICO`/`PREMIUM`/`LUJO`) y un `Icono_Item` (`TextureRect`) con la ilustración propia del mueble
- `Nombre`, `Precio`, `Multiplicador` (Labels)
- `En_Uso` (Label, "✓ En uso") — visible solo si seleccionado
- `Comprar`, `Vender`, `Elegir` (Buttons superpuestos en el mismo slot)

El layout final de las tarjetas se construye en `Script_Principal._Redisenar_Tienda()`: rejilla de 2 columnas (tarjeta 332×442), vitrina de 304×200 y una tarjeta única o la tercera de Dormir centradas.

### Ilustraciones de los muebles

Las tarjetas usan ilustraciones 2.5D propias en lugar de emojis o iconos Lucide:

- **Originales:** JPG con fondo magenta plano en `Arte_Fuente/Tienda/Fuente/` (`Cama_Basica.jpg`, `Ducha_Premium.jpg`, …). Los prompts del lote están en `Arte_Fuente/Tienda/prompts.md`.
- **Runtime:** PNG cuadrados 512×512 con alfa en `Imagenes/Tienda/Iconos/`, con el nombre exacto de la clave del catálogo (`Cama_Basica.png`, `Cama_Premium.png`, `Cama_Lujo.png`, `Mesa_Basica.png`, `Ducha_Basica.png`, `Ducha_Premium.png`).
- **Pipeline:** `python3 tools/procesar_iconos_tienda.py [--preview preview.png]` recorta el magenta por croma, elimina el derrame del borde, limpia motas, recorta al contenido y centra cada objeto con un 5 % de margen transparente.
- **Carga:** `Estilos_UI.icono_tienda(clave)` resuelve la ruta desde `Estilos_UI.RUTAS_ICONOS_TIENDA` y cachea la textura. Si falta el PNG, la tarjeta cae al icono Lucide anterior.

### Estados Visuales del Panel

Construidos en código (`Script_Principal._Inicializar_Tienda_Estilos()`):

| Estado | StyleBox | Borde |
|---|---|---|
| No poseído | `_tienda_estilo_normal` | Gris (3px) |
| Poseído, no seleccionado | `_tienda_estilo_owned` | Azul (4px) |
| Seleccionado (en uso) | `_tienda_estilo_selected` | Verde (5px) |

### Reglas de Visibilidad de Botones

Calculadas en `_Actualizar_Card_Tienda(categoria, clave)`:

| Botón | Visible cuando |
|---|---|
| `Comprar` | NO poseído |
| `Vender` | Poseído **y** NO seleccionado **y** existe otro poseído de misma categoría |
| `Elegir` | Poseído **y** NO seleccionado |
| `En_Uso` | Seleccionado |

### Funciones de Visibilidad (`Gestionar_Visibilidad.gd`)

```gdscript
Visibilizar_Tienda(raiz)
    # Oculta todo, deja visibles solo Fondo, Moneda, Dinero_Label, Alquiler_Button
    # Muestra el Control Tienda y abre la categoría Dormir

Mostrar_Categoria_Tienda(raiz, categoria)
    # Oculta Objetos_Dormir/Comer/Duchar/Ventajas y muestra solo la categoría indicada
```

### Handlers en `Script_Principal.gd`

- `_on_tienda_button_pressed` — abre la tienda, refresca UI
- `_on_tienda_flecha_atras_pressed` — `Quitar_Todo` (vuelve al menú)
- `_on_tab_<dormir|comer|duchar|ventajas>_pressed` — switcher de categorías; Ventajas abre la pestaña Bienestar (anuncios + clínica)
- 18 handlers `_on_<comprar|vender|elegir>_<objeto>_pressed` → delegan a 3 helpers (`_Tienda_Comprar/Vender/Elegir`) que llaman a `Actividades.Comprar_Objeto/Vender_Objeto/Seleccionar_Objeto`, refrescan UI y `Actualizar_Dinero()`

### Limitaciones Actuales de la UI

- La vitrina está pensada para las seis ilustraciones actuales; un objeto nuevo sin PNG usa el respaldo Lucide, pero conviene añadir su ilustración y su entrada en `Estilos_UI.RUTAS_ICONOS_TIENDA`.
- Las tarjetas de muebles usan posiciones fijas en coordenadas de diseño 720×1280 (el dock inferior empieza en `alto - 92`). La pestaña Bienestar sí usa un `ScrollContainer` y se adapta a pantallas altas.

## Estado Actual

- **Implementado:** 6 objetos en catálogo, 3 categorías (Dormir, Comer, Duchar), backend completo (compra/venta/selección), aplicación de multiplicador en Dormir/Duchar, guardado/carga, UI de tienda funcional con tabs y estados visuales, y tarjetas con ilustraciones 2.5D propias (Cama Básica/Premium/Lujo, Mesa Básica, Ducha Básica/Premium). La alimentación pasó a `Cocinar`/`Comer_Tupper`/`Comer_Basura`; las mesas ya no modulan comer.
- **Planeado:** Efectos negativos (multiplicador < 1.0), más categorías de muebles (Ocio, Trabajo) e integración de una red de anuncios real (sin pagos ni moneda premium).


---

## Bienestar y rejuvenecimiento (Tienda → Bienestar)

La tienda incorpora una cuarta pestaña, **Bienestar**, que sustituye al antiguo
prototipo de monetización. No hay gemas, Pase VIP, moneda premium ni pasarela de
pago. Solo hay dos fuentes de contenido:

1. **Anuncios recompensados simulados** con espera entre uno y otro.
2. **Servicios pagados con euros del juego**: cuidado exprés y tratamientos que
   restan años reales al Sim.

### Archivos

- `Scripts/Globales/Recompensas.gd` (autoload): anuncios, servicios, tokens,
  recompensas, esperas, historial y señales.
- `Scripts/Globales/Recompensas/Recompensas_Catalogo.gd`: catálogo y
  creatividades.
- `Proveedor_Anuncios.gd` / `Proveedor_Simulado_Anuncios.gd`: interfaz y
  adaptador de la red falsa.
- `Scripts/GUI/Tienda/Tienda_Bienestar.gd`, `Modal_Tratamiento.gd`,
  `Modal_Anuncio_Bienestar.gd` y `Visual_Bienestar.gd`.
- `Tienda.tscn`: `Tab_Ventajas` y `Objetos_Ventajas`.
- Tests: `Funcionalidades/Bienestar/Tests/test_bienestar.gd`.
- Doc: `Funcionalidades/Bienestar/Documentacion/BIENESTAR.md`.

### Catálogo

| Anuncio | Duración | Espera | Recompensa |
|---|---|---|---|
| Bono de 150 € | 5 s | 30 min | +150 € |
| Recarga de bienestar | 6 s | 10 min | +30 a cada necesidad |
| Cesta caliente | 6 s | 15 min | 2 tuppers al 100 % |
| Spa express | 8 s | 60 min | −1 año |

| Servicio | Precio base | Recompensa |
|---|---|---|
| Spa revitalizante | 400 € | −1 año |
| Clínica regenerativa | 1.100 € | −3 años |
| Cápsula del tiempo | 2.200 € | −5 años |
| Día de spa | 120 € | Necesidades al 100 % |
| Cesta gourmet | 90 € | 3 tuppers al 100 % |

Los tratamientos de rejuvenecimiento suben de precio con cada sesión:
`coste = base + incremento × Tratamientos_Rejuvenecimiento`. El contador es
global y se guarda con la partida.

### Rejuvenecimiento

`Variables_Estaticas.Calcular_Edad()` resta `Rejuvenecimiento_Anios` a la edad
natural y aplica un suelo de 18 años. El cambio afecta a todos los retratos de
`Personaje_Visual`, al HUD de Inicio, a la carrera de futbolista y a cualquier
sistema que consulte la edad. `First_Time_Function()` pone el contador a cero
en una partida nueva y `Guardar_Variables_Dinamicas.gd` lo persiste.

### Flujo y arquitectura

1. La UI lee anuncios y servicios de `Recompensas_Catalogo`.
2. `Solicitar_Anuncio` valida proveedor, espera y edad, y emite un token de un
   solo uso. `Completar_Anuncio` lo invalida antes de verificar para evitar
   dobles cobros.
3. `Comprar_Servicio` vuelve a validar dinero y edad mínima, descuenta euros,
   aplica la recompensa y registra el historial.
4. `Script_Principal._On_Recompensa_Bienestar()` repinta dinero, necesidades,
   Home y tarjetas de la tienda.
5. Las esperas y el historial se guardan en `user://recompensas.cfg`, fuera de
   la partida. El dinero, necesidades, tuppers y años se guardan con la partida.

La UI muestra la edad actual, un medidor de 18 a 100 con marca fantasma de la
edad sin tratamientos, tarjetas de servicios, cuidado exprés, anuncios con
barra de espera y pie con reinicio de esperas. Se adapta a `720×1280` y a
pantallas altas (`720×1600`).

### Integración futura

Sustituir `Proveedor_Simulado_Anuncios` por un adaptador real (AdMob u otro).
Antes de publicar: consentimiento (GDPR/UMP), protección de menores, SSV de
anuncios y pruebas de políticas. No hay pagos ni compras integradas; si se
añaden en el futuro deben validarse en servidor y no reutilizar este catálogo.
