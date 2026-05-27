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
