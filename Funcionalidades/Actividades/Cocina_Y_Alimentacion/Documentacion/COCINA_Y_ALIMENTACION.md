# Cocina y alimentación dual

Sistema implementado en SIMS 0.33 (Godot 4, 720×1280 portrait). Sustituye la antigua actividad gratuita `Comer` por una decisión continua entre **cocinar**, **comer tuppers caseros** y **pagar comida rápida**.

---

## 1. Actividades nuevas

| Actividad | Clase | Efectos NB `[fís, men, ham, des, hig]` | Notas |
|---|---|---|---|
| `Cocinar` | `Actividad_Temporal` | `[-1, 1, -2, -2, -2]` | P1 · mínimo 15 min · produce 1 tupper por ciclo |
| `Comer_Tupper` | `Actividad_Temporal` | `[1, 2, 20, -1, -1]` | P1 · física/mental moduladas por calidad |
| `Comer_Basura` | `Actividad_Temporal` | `[-2, 2, 20, -1, -1]` | P1 · cobra cada 5 min |

Ninguna entra en `Variables_Estaticas.Actividades` (pool aleatorio) ni en la IA como comida gratuita.

La antigua `Comer` desaparece del catálogo. Las celdas `"Comer"` de partidas antiguas se migran a `Comer_Basura` al cargar (RLE y formato de strings).

---

## 2. Variables

### `Variables_Dinamicas`
```gdscript
var Progreso_Cocina: int = 1
var Tuppers: Array = []                 # [{id, porcentaje_restante, calidad, minuto_creacion, minuto_caducidad}]
var Tupper_Seleccionado_Idx: int = -1
var Minutos_Cocinando_Actuales: int = 0 # volátil, no se guarda
```

### `Variables_Estaticas`
```gdscript
const COSTE_COCINAR_BASE: float = 2.0
const COSTE_COMIDA_BASURA_BASE: float = 2.0
const DIAS_CADUCIDAD_TUPPER: int = 3
const MINUTOS_POR_TUPPER: int = 15
const MINUTOS_COMIDOS_POR_TUPPER: int = 30
```
Helpers: `Obtener_Coste_Cocinar()`, `Obtener_Coste_Comida_Basura()` y `Obtener_Minutos_Caducidad_Tupper()` (3 días normal / 1 día rápido), todos escalados con `Multiplicador_Precios()`.

---

## 3. Cocinar

- Bloqueado si `En_La_Calle == true` y si la duración es inferior a 15 minutos.
- Fórmula de progreso (cada minuto activo):
  ```gdscript
  suma = 40*Destreza + 25*Paciencia + 20*Sangre_Fría + 15*Memoria
  pot1 = (30 + Progreso_Cocina) / 100.0
  pot2 = 15000 / (5000 + suma)
  max_val = floor(20 * (8 ** pot1) ** pot2)
  ```
  Con probabilidad `1/max_val`, `Progreso_Cocina += 1` (tope 100).
- Descubrimiento de habilidades innatas con pesos 40/25/20/15 (Destreza, Paciencia, Sangre fría, Memoria).
- Cada minuto se comprueba `Dinero >= coste`; si no, se limpia el bloque actual y las celdas contiguas futuras, se resetea el contador y se envía un mensaje.
- `Minutos_Cocinando_Actuales` incrementa cada minuto de cocina. Cada 15 minutos se descuenta `2 € * Multiplicador_Precios()` y se crea un tupper al 100 % con `calidad = Progreso_Cocina` y caducidad `Minute + dias*1440`.
- Cualquier minuto que no sea `Cocinar` resetea `Minutos_Cocinando_Actuales = 0`.

---

## 4. Comer tuppers

- 1 tupper completo = 30 minutos de comida. Cada minuto resta `100/30 = 3,333 %`.
- Selección:
  - `Tupper_Seleccionado_Idx` válido → se consume ese.
  - `-1` o inválido → automático: primero tuppers vigentes (prioriza ya empezados y los que caducan antes); si solo hay caducados, el menos caducado.
- Efectos por minuto según calidad:
  - Salud física: `+1` (1–30), `+2` (31–70), `+3` (71–100).
  - Salud mental: `+2`, o `+3` si calidad > 60.
  - Hambre: `20` con frecuencia 12. Descanso/higiene: `-1`.
- Al agotarse (`<= 0,01 %`) se elimina y se reinicia la selección. Si quedan más tuppers, el bloque encadena automáticamente. Si no queda ninguno, **el resto del bloque se convierte en `Comer_Basura`** (cobrando) desde el minuto siguiente.
- Si el bloque empieza sin tuppers, se convierte también a `Comer_Basura`.

### Intoxicación
- Un tupper caducado permanece en el inventario y puede comerse.
- `minutos_caducado = Minute - minuto_caducidad`.
- Probabilidad por bloque de 30 min: `clamp(horas_caducado / 48, 0.05, 1.0)`.
- Probabilidad por minuto: `1 - (1 - p30) ** (1/30)`.
- Si dispara y no está activo, se añade `Estados_Temporales["Intoxicacion"] = 1440` (techo gradual 30→100 a Salud Física/Mental, 20 en calle/bancarrota) y se envía un mensaje.

---

## 5. Comida rápida

- Cobro cada 5 minutos (`Minute_Minute % 5 == 0`): `2 € * Multiplicador_Precios()`.
- Si no hay saldo, se cancela el bloque, se limpian las celdas contiguas y se notifica.
- Efectos: `[-2, 2, 20, -1, -1]`.

---

## 6. IA pasiva

`Alimentacion.Elegir_Comida_IA()`:
1. Si hay tupper vigente → `Comer_Tupper`.
2. Si no, y `Dinero >= coste` → `Comer_Basura`.
3. Si solo quedan caducados y no hay dinero → `Comer_Tupper` (último recurso, con riesgo).
4. Si no hay nada → `Ver_La_Television` (ocio; el Hambre sigue bajando).

Nunca se recupera Hambre gratis sin tupper.

---

## 7. Hostelería

Trabajos P2 que solo exigen `Progreso_Cocina` (campo `requisito_cocina` de `Actividad_Fija_Trabajo`):

| Puesto | Horario | Salario | Requisito |
|---|---|---|---|
| Ayudante de Cocina | 11:00–19:00 | 17 €/h | Cocina ≥ 30 |
| Cocinero de Partida | 12:00–20:00 | 24 €/h | Cocina ≥ 60 |
| Chef Ejecutivo | 13:00–21:00 | 36 €/h | Cocina ≥ 85 |

La comprobación está en `Script_Principal._Cumple_Requisitos_Trabajo()`.

---

## 8. UI

- Botón `🍳 COCINAR` en `Temporales → Necesidades_Basicas_Opciones`.
- El botón `🍽️ COMER` abre directamente `Seleccionar_Horario` en modo Comida (pestañas **Comida casera** / **Comida rápida**) con vista previa de coste, calidad, caducidad y avisos. Primero se elige la actividad y después se ajusta el horario.
- La pestaña **Despensa** del Perfil muestra todos los tuppers con porcentaje, calidad, caducidad, selección y descarte.
- `Modal_Tuppers.gd` permite elegir/descartar desde el reloj. Se abre automáticamente al entrar en modo Comida casera.
- Indicador `🍱 N` junto a Hambre en `Necesidades_Basicas_GUI`.
- `Progreso_Cocina` aparece en `Perfil → Info` y como cuarta barra del panel `Progreso`.
- `Mesa_Premium` se retiró de la tienda y `Comer` ya no usa multiplicadores de mesa.

---

## 9. Persistencia

- `Progreso_Cocina`, `Tuppers` y `Tupper_Seleccionado_Idx` se guardan en `Guardar_Variables_Dinamicas.dat`.
- `Minutos_Cocinando_Actuales` siempre arranca en 0.
- Saves antiguos: `Progreso_Cocina=1`, `Tuppers=[]`, `Tupper_Seleccionado_Idx=-1`.
- Los tuppers se normalizan al cargar (tipos, rangos y porcentajes > 0,01).
- `Mesa_Premium` y selecciones antiguas de esa mesa se limpian al cargar.

---

## 10. Tests

`Funcionalidades/Actividades/Actividades_Temporales/Tests/test_cocina_y_alimentacion.gd` (GUT):
- TC-01 catálogo, pool y migración de `Comer`.
- TC-02 validación de 15 min y vivienda.
- TC-03 producción, calidad, caducidad y modo rápido.
- TC-04 interrupción e insolvencia.
- TC-05 consumo parcial y agotamiento.
- TC-06 selección manual/automática y encadenado a comida rápida.
- TC-07 caducidad, probabilidad creciente e intoxicación.
- TC-08 cobro de basura, penalización física e insolvencia.
- TC-09 IA pasiva sin comida gratis.
- TC-10 fórmula de progreso y requisitos de hostelería.
- TC-11 persistencia y partidas antiguas.
- Integración de UI: pestaña Despensa, botón Cocinar, trabajos, modal y vista previa de los tres modos.

Ejecución:
```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd \
  -gdir=res://Funcionalidades/Actividades/Actividades_Temporales/Tests -gexit
```
