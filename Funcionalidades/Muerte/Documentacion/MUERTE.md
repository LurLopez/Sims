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
