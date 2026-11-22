# Invertir en Bolsa

## Descripción general

Sistema de inversión **pasiva** con gestión de cartera, eventos de mercado, historial y estadísticas. El jugador puede aportar dinero cuando quiera, añadir capital a una posición abierta, retirar solo una parte o cerrar la posición completa. El valor de la cartera fluctúa automáticamente mientras hay dinero invertido.

La pantalla dedicada (**Economía → Bolsa e inversiones**) incluye tres pestañas:

- **Resumen:** valor de la cartera, beneficio, nivel inversor, pulso del mercado y perfil inversor.
- **Evolución:** gráfico del beneficio acumulado con periodos de 1, 5 y 10 años o todo el historial.
- **Estadísticas:** aportado, retirado, rentabilidad, tasa de acierto, mejores y peores operaciones, tiempo invertido, eventos, rachas y máxima caída.

> El minijuego activo de trading («Sala de trading») sigue pendiente. Esta mejora mantiene la inversión pasiva como modo cómodo y deja el motor preparado para compartir progreso con el futuro minijuego.

---

## Variables dinámicas

### Posición actual

| Variable | Tipo | Rango | Descripción |
|---|---|---|---|
| `Esta_Invirtiendo` | `bool` | — | `true` mientras haya valor en la cartera |
| `Dinero_Invertido` | `float` | ≥ 0 | Coste base de la posición abierta (aportes menos coste liberado en retiradas) |
| `Valor_Inversion` | `float` | ≥ 0 | Valor actual de la cartera |
| `Salud_Mental_Al_Invertir` | `int` | 1–100 | Snapshot de salud mental al abrir una posición nueva |
| `Progreso_Inversion` | `int` | 1–100 | Nivel inversor |
| `Inversion_Minuto_Inicio` | `int` | ≥ -1 | Minuto de juego en el que se abrió la posición |
| `Inversion_Tendencia` | `float` | -1…1 | Régimen de mercado (bajista ↔ alcista) |

### Historial y estadísticas

| Variable | Tipo | Descripción |
|---|---|---|
| `Inversion_Historial` | `Array` | Puntos `{minuto, beneficio, valor, invertido}` para el gráfico |
| `Inversion_Operaciones` | `Array` | Últimas 40 operaciones `{minuto, tipo, cantidad, beneficio, cerrado, acumulado}` |
| `Inversion_Eventos` | `Array` | Últimos 30 eventos `{minuto, titulo, delta_pct, importe, tipo}` |
| `Inversion_Aportado_Total` | `float` | Dinero total aportado a lo largo de la partida |
| `Inversion_Retirado_Total` | `float` | Dinero total retirado |
| `Inversion_Beneficio_Realizado` | `float` | Beneficio/pérdida ya materializado en retiradas |
| `Inversion_Num_Aportes` | `int` | Número total de aportes |
| `Inversion_Num_Retiradas` | `int` | Número total de retiradas |
| `Inversion_Cierres_Ganadores` | `int` | Retiradas con beneficio > 0,01 € |
| `Inversion_Cierres_Perdedores` | `int` | Retiradas con pérdida < -0,01 € |
| `Inversion_Mejor_Operacion` | `float` | Mejor beneficio realizado |
| `Inversion_Peor_Operacion` | `float` | Peor pérdida realizada |
| `Inversion_Eventos_Subida` / `_Bajada` | `int` | Eventos de mercado al alza / a la baja |
| `Inversion_Panicos` | `int` | Auto-ventas por pánico |
| `Inversion_Minutos_Activos` | `int` | Minutos de juego con una posición abierta |
| `Inversion_Racha_Actual` | `int` | Racha actual del mercado (positiva = subidas) |
| `Inversion_Mejor_Racha` / `_Peor_Racha` | `int` | Mejor racha alcista / bajista |
| `Inversion_Racha_Operaciones` | `int` | Retiradas rentables consecutivas |
| `Inversion_Mejor_Racha_Operaciones` | `int` | Mejor racha de retiradas rentables |
| `Inversion_Pico_Beneficio` | `float` | Pico de beneficio acumulado alcanzado |
| `Inversion_Max_Caida` | `float` | Mayor caída desde un pico (drawdown) |
| `Inversion_Ultimo_Evento_Minuto` | `int` | Minuto del último evento de mercado |

`Inversion_...` es el prefijo persistente de la bolsa. `Inversion_Historial`, `Inversion_Operaciones` e `Inversion_Eventos` se recortan automáticamente para no hacer crecer el guardado sin límite.

---

## Flujo de ejecución

### 1. Abrir la pantalla

El botón de la tarjeta **Bolsa e inversiones** abre `Panel_Bolsa` a pantalla completa. El panel se reconstruye cada vez que se abre porque `Gestionar_Visibilidad.Quitar_Todo()` oculta recursivamente todos los controles de la pantalla anterior.

### 2. Invertir o aportar

`Sistema_Bolsa.Invertir(cantidad, minuto)`:

```gdscript
if no hay posición:
    Dinero_Invertido = 0
    Valor_Inversion = 0
    Salud_Mental_Al_Invertir = Necesidades_Basicas[1]
    Inversion_Minuto_Inicio = minuto

Dinero -= cantidad
Dinero_Invertido += cantidad
Valor_Inversion += cantidad
Esta_Invirtiendo = true
Inversion_Aportado_Total += cantidad
Inversion_Num_Aportes += 1
```

La salud mental solo se captura al **abrir** una posición. Aportar más capital a una posición existente conserva el snapshot original.

### 3. Tick de mercado

`Actividades._Tick_Inversion()` llama una vez por minuto de juego a `Sistema_Bolsa.Procesar_Minuto()` mientras `Esta_Invirtiendo` es verdadero. Cada minuto suma `Inversion_Minutos_Activos`.

El evento de mercado ocurre con probabilidad **1/480 por minuto** (~3 eventos por día de juego):

```gdscript
tendencia = clamp(tendencia * 0.90 + randfn(0.0, 0.20), -1.0, 1.0)
prob_subida = clamp(
    0.15 + ((nivel - 1) / 99.0) * 0.70
         + (mental - 50.0) / 300.0
         + tendencia * 0.05,
    0.05, 0.95)
```

- Nivel 1 y salud mental 50: ~15 % de probabilidad de subida.
- Nivel 100 y salud mental 50: ~85 %.
- La tendencia de mercado añade hasta ±5 puntos porcentuales; no sustituye al nivel.
- La salud mental del snapshot aporta hasta ±16,6 puntos porcentuales.

Magnitud del movimiento:

- Evento normal: **0,5 % – 3,0 %**.
- Shock (6 % de probabilidad): **3,0 % – 6,5 %**, con titulares dramáticos.

El valor nunca baja de 0,01 €. Cada evento genera un titular ficticio (resultados, tipos, inflación, rally, pánico…) que se muestra en el resumen y en el historial.

### 4. Retirar parcialmente o cerrar

`Sistema_Bolsa.Retirar(cantidad, motivo, minuto)`:

```gdscript
fraccion = cantidad / Valor_Inversion
coste_liberado = Dinero_Invertido * fraccion
beneficio = cantidad - coste_liberado

Dinero += cantidad
Valor_Inversion -= cantidad
Dinero_Invertido -= coste_liberado
Inversion_Beneficio_Realizado += beneficio
```

Si `cantidad` cubre todo el valor, la posición se cierra (`Esta_Invirtiendo = false`) y se resetean `Valor_Inversion` y `Dinero_Invertido`.

El beneficio acumulado del gráfico es:

```text
beneficio_acumulado = beneficio_realizado + (valor_actual - coste_base)
```

Al aportar o retirar, el beneficio acumulado no cambia: solo se mueve dinero propio entre efectivo y cartera.

### 5. Venta por pánico

Se mantiene la regla original: si **Sangre Fría < 30** y la posición pierde más del **15 %** respecto a su coste base, se vende todo automáticamente. Se incrementa `Inversion_Panicos` y se crea un mensaje en el perfil.

La pantalla avisa de este riesgo cuando la Sangre Fría es baja.

### 6. Progreso del nivel inversor

- `1/20` de probabilidad de +1 punto por evento de mercado.
- +1 punto al cerrar una posición completa con beneficio > 0,01 €.
- Máximo 100.

El progreso se guardaba desde la primera versión, pero **no se cargaba**: la habilidad volvía siempre a 1. Corregido en `Guardar_Variables_Dinamicas.load_game()`.

---

## Historial y gráfico

- Se registra un punto después de cada evento y de cada operación.
- Si ya existe un punto en el mismo minuto, se actualiza en vez de duplicarse.
- El máximo es de **600 puntos**. Al superarlo se reduce la resolución a la mitad conservando el primer y el último punto, para no perder la forma de la curva.
- El gráfico pinta verde por encima de cero y rojo por debajo, con relleno suave, línea de cero discontinua y marcadores de aportes (azul), retiradas (oro) y ventas por pánico (rojo).
- Periodos: **1 año**, **5 años**, **10 años** y **Todo**. Un año equivale a `Variables_Estaticas.Dias_Por_Anio()` días de juego (7 en modo normal, 1 en modo rápido).
- El panel añade un punto visual con el valor actual aunque todavía no se haya registrado un evento, para que la línea llegue hasta «Ahora».

### Estadísticas mostradas

| Métrica | Cálculo |
|---|---|
| Beneficio total | `Beneficio_Realizado + (Valor_Inversion - Dinero_Invertido)` |
| Rentabilidad | `Beneficio_Total / Inversion_Aportado_Total * 100` |
| Capital aportado | `Inversion_Aportado_Total` |
| Capital retirado | `Inversion_Retirado_Total` |
| Operaciones | `Num_Aportes + Num_Retiradas` |
| Tasa de acierto | `Cierres_Ganadores / (Cierres_Ganadores + Cierres_Perdedores)` |
| Mejor / peor operación | Máximo y mínimo beneficio realizado |
| Tiempo invertido | `Inversion_Minutos_Activos` formateado en años/días |
| Eventos de mercado | `Eventos_Subida + Eventos_Bajada` |
| Racha del mercado | Racha actual de subidas o bajadas |
| Máxima caída | Mayor diferencia entre `Inversion_Pico_Beneficio` y el beneficio actual |

---

## UI

### Archivos

| Archivo | Función |
|---|---|
| `Scripts/Logica/Escena_Principal/Economia/Sistema_Bolsa.gd` | Autoload con toda la lógica: operaciones, mercado, historial, estadísticas y compatibilidad de guardado |
| `Scripts/GUI/Escena_Principal/Bolsa/Panel_Bolsa.gd` | Pantalla completa con pestañas Resumen / Evolución / Estadísticas y diálogo de cantidad |
| `Scripts/GUI/Escena_Principal/Bolsa/Grafico_Bolsa.gd` | Control `Grafico_Bolsa` que dibuja la evolución del beneficio |
| `Scripts/Globales/Script_Principal.gd` | Abre la pantalla desde la tarjeta de Economía y actualiza el dinero al operar |
| `Scripts/Logica/Escena_Principal/Actividades/Actividades.gd` | Llamadas a `Sistema_Bolsa.Procesar_Minuto()` y `Auto_Vender_Por_Panico()` |

### Acciones

- **Invertir en bolsa:** solo si no hay posición abierta.
- **Aportar:** añade capital a la posición actual.
- **Retirar:** permite una cantidad parcial o el total.
- El diálogo incluye botones rápidos **25 % / 50 % / 75 % / Todo**, validación visible y aviso del riesgo de pánico.

### Navegación

- La tarjeta de Economía muestra el porcentaje actual y cambia a **Gestionar inversión (X €)** cuando hay una posición abierta.
- La pantalla de Bolsa mantiene activa la pestaña superior **Economía**.
- Volver con la flecha devuelve a Economía.

---

## Persistencia y compatibilidad

Claves nuevas en `Guardar_Variables_Dinamicas.game_data_func()`:

```text
Inversion_Historial, Inversion_Operaciones, Inversion_Eventos,
Inversion_Tendencia, Inversion_Ultimo_Evento_Minuto, Inversion_Minuto_Inicio,
Inversion_Aportado_Total, Inversion_Retirado_Total, Inversion_Beneficio_Realizado,
Inversion_Num_Aportes, Inversion_Num_Retiradas, Inversion_Cierres_Ganadores,
Inversion_Cierres_Perdedores, Inversion_Mejor_Operacion, Inversion_Peor_Operacion,
Inversion_Eventos_Subida, Inversion_Eventos_Bajada, Inversion_Panicos,
Inversion_Minutos_Activos, Inversion_Racha_Actual, Inversion_Mejor_Racha,
Inversion_Peor_Racha, Inversion_Racha_Operaciones, Inversion_Mejor_Racha_Operaciones,
Inversion_Pico_Beneficio, Inversion_Max_Caida
```

Al cargar, `Sistema_Bolsa.Asegurar_Estado()`:

- Sanea tipos y recorta arrays.
- Descarta posiciones inválidas (`Esta_Invirtiendo` con valor 0).
- Si el guardado es antiguo y hay una posición activa, rellena `Inversion_Aportado_Total` con `Dinero_Invertido` y siembra el primer punto del historial.
- Ajusta el nivel a 1–100 y la tendencia a -1…1.

Los guardados antiguos sin las claves nuevas cargan sin errores.

---

## Tests

`Funcionalidades/Economia/Invertir_En_Bolsa/Tests/test_sistema_bolsa.gd` (GUT):

- Invertir descuenta efectivo y abre posición.
- Aportar suma al coste base.
- Retirada parcial reparte coste y beneficio.
- Retirada total cierra y registra ganancia/pérdida.
- Auto-venta por pánico y ausencia de auto-venta con Sangre Fría alta.
- Nivel +1 al cerrar en positivo.
- Estadísticas y tasa de acierto.
- Filtro y compactación del historial.
- Migración de guardados antiguos.
- Claves de guardado.
- Construcción del panel, pestañas y diálogos de invertir/retirar.
- `Grafico_Bolsa` acepta puntos y marcadores.
- Guardado atómico con `.bak` y sin temporales residuales.

También se mantiene `test_inversion.gd` con las comprobaciones básicas anteriores. El script antiguo no extiende `GutTest`, por lo que GUT lo ignora y sirve como prueba manual.

---

## Notas de balance

- El evento ocurre solo mientras hay una posición abierta; no se simula el mercado con la cartera vacía.
- La tendencia es un paseo aleatorio con reversión suave. No garantiza beneficios: un nivel alto mejora la probabilidad, pero un shock puede borrar varios eventos positivos.
- No hay comisiones en la inversión pasiva. La comisión del 1 % queda reservada para el futuro minijuego de trading, según el roadmap.
- La auto-venta por pánico sigue siendo la consecuencia directa de una Sangre Fría baja (<30). La pantalla avisa antes de invertir.

---

## Checklist

- [x] `Variables_Dinamicas.gd`: variables de historial y estadísticas.
- [x] `Sistema_Bolsa.gd`: motor de aportes, retiradas, eventos, historial y estadísticas.
- [x] `Grafico_Bolsa.gd`: gráfico de evolución con periodos y marcadores.
- [x] `Panel_Bolsa.gd`: pantalla Resumen / Evolución / Estadísticas y diálogos.
- [x] `Script_Principal.gd`: tarjeta de Economía, apertura del panel y actualización del dinero.
- [x] `Actividades.gd`: wrappers `_Tick_Inversion` y `_Auto_Vender_Inversion`.
- [x] `Guardar_Variables_Dinamicas.gd`: guardado, carga, migración y corrección de `Progreso_Inversion`.
- [x] `Menu.gd`: reinicio del estado de bolsa en partidas nuevas.
- [x] `First_Time.gd`: reinicio defensivo al crear una partida nueva.
- [x] `project.godot`: autoload `Sistema_Bolsa`.
- [x] Tests GUT del sistema, del panel y del gráfico.
