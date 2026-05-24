# Progreso & Habilidades — Mecánica de descubrimiento

## Las dos métricas

### Progreso (volátil, visible siempre)
- 3 valores: Deporte, Académico, Manualidades (en `Variables_Dinamicas.Progreso`).
- Rango 0–100.
- Sube haciendo actividades relacionadas (fórmula compleja en `Actividades_Habilidades.Ejecutar_Actividad_Progreso`).
- Baja con desuso (decadencia pendiente de implementar).
- Es tu nivel ACTUAL — "qué tan bueno soy ahora mismo".

### Habilidad mostrada (descubrimiento permanente)
- Refleja tu valor INNATO secreto (`Variables_Estaticas.Habilidades`, 6 valores 0–100 generados aleatoriamente al inicio).
- Se va revelando progresivamente conforme haces actividades.
- **Solo sube, nunca baja.** Lo que has descubierto sobre ti mismo no se olvida.
- Es tu CAP DEMOSTRADO — "lo más alto que he probado que puedo llegar".

---

## Cómo funciona el descubrimiento

Se mantiene un contador auxiliar `Variables_Dinamicas.Conocimiento` (Array de 6 ints). Cada vez que ejecutas una actividad que usa esa habilidad, su contador correspondiente sube en 1.

La Habilidad mostrada en pantalla es:

```
Habilidad_mostrada[i] = min(Conocimiento[i], Innata[i])
```

Cuando `Conocimiento[i] >= Innata[i]`, el contador deja de tener efecto. En ese momento se dispara un mensaje:

> *"Has descubierto tu límite natural en Deporte: **27**. Tu talento innato no dará para más en esta área, aunque puedes seguir subiendo tu Progreso a base de esfuerzo (mucho esfuerzo)."*

Ese matiz final es importante: el jugador entiende que **el cap no bloquea técnicamente el Progreso**, solo lo hace mucho más costoso. Le da permiso para pivotar sin sentir que ha perdido el tiempo.

---

## Por qué Progreso y Habilidad no van paralelos

Las dos métricas dependen de cosas distintas:

| | Lo que la hace subir |
|---|---|
| **Conocimiento** (→ Habilidad mostrada) | El número de actividades hechas (lineal, 1 por actividad). Independiente del talento. |
| **Progreso** | Una fórmula que mezcla talento innato + dificultad por nivel actual. No lineal. |

Resultado típico para un talento bajo (cap = 20):

| Tras N actividades | Conocimiento | Habilidad mostrada | Progreso |
|---|---|---|---|
| 5 | 5 | 5 | ~3 |
| 12 | 12 | 12 | ~8 |
| 20 | 20 | **20 (revelado)** | ~13 |
| 30 | 30 | 20 (capped) | ~15 |

Por eso la revelación "este es tu tope" suele aparecer **antes** de que el Progreso haya tocado techo. El jugador tiene la información para decidir si pivotar mientras todavía hay tiempo en la partida.

---

## Asimetría del descubrimiento

Esto crea un equilibrio que se parece muchísimo a la vida real:

| Talento innato | Revelación explícita | Pista implícita |
|---|---|---|
| Bajo (cap 0–30) | Rápida: Habilidad llega al tope en pocas semanas | Progreso apenas sube |
| Medio (cap 30–70) | Moderada: tardas tiempo en revelar | Progreso sube con esfuerzo |
| Alto (cap 70–100) | Lenta: necesitas mucha práctica | Progreso sube rápido — lo intuyes desde el primer día |

**Los malos se enteran por el número. Los buenos se enteran por los resultados.**

Un futbolista profesional no necesita un test que le diga "tienes talento 92". Lo sabe porque gana partidos. Un mediocre lo descubre cuando se choca contra el techo.

---

## Mapeo actividad → habilidades

Ya existe en `Actividades_Habilidades.gd` la mezcla de habilidades para cada área de Progreso:

- **Deportivo** (Salir_A_Correr): 50·Deporte + 40·Liderazgo + 10·Memoria
- **Académico** (Estudiar): 50·Inteligencia + 20·Paciencia + 30·Memoria
- **Manualidades** (Practicar_Manualidades): 50·Destreza + 30·Paciencia + 10·Memoria + 10·Liderazgo

Para el descubrimiento, cada actividad incrementa el Conocimiento de TODAS las habilidades implicadas (con peso 1, no fraccionario).

Ejemplo: hacer `Salir_A_Correr` una vez → `Conocimiento[Deporte] += 1`, `Conocimiento[Liderazgo] += 1`, `Conocimiento[Memoria] += 1`.

---

## Decadencia del Progreso (pendiente)

El Progreso debe bajar con el desuso para mantener la presión de seguir entrenando. Propuesta:

- Trackear último uso por habilidad (timestamp del último incremento).
- Si pasan más de **5 días reales** sin actividad relacionada, empieza la decadencia.
- Decadencia suave: **1 punto cada 3 días sin uso** después del umbral.
- Mínimo nunca por debajo de 1.

**Importante**: la decadencia afecta solo al Progreso, NO al Conocimiento ni a la Habilidad mostrada. Lo que descubriste de ti mismo no se olvida; solo pierdes forma.



## Notas de implementación

1. **Añadir variable**: `Variables_Dinamicas.Conocimiento: Array` (6 ints, inicializado a `[0, 0, 0, 0, 0, 0]`).
2. **Persistencia**: añadir al `Guardar_Variables_Dinamicas` (store + load).
3. **Hook en cada actividad**: en `Actividades_Habilidades.Ejecutar_Actividad_Progreso_Array`, incrementar los contadores de las habilidades implicadas.
4. **Detector de revelación**: comprobar tras cada incremento si `Conocimiento[i]` acaba de alcanzar `Habilidades[i]`. Si sí → disparar dialogo.
5. **Pantalla Habilidades**: 6 entradas con barra + valor mostrado `min(Conocimiento[i], Habilidades[i])` + estado (`???` si Conocimiento == 0, número si > 0).
6. **Decadencia**: trackear `Variables_Dinamicas.Ultimo_Uso_Habilidad` (Array de 6 timestamps). Comprobar en `Actividades.Actualizar_Horario`.
7. **Pistas contextuales**: en `Actividades.Ejecutar_Actividad`, después del roll de progreso, encolar un mensaje en una lista mostrada en la GUI.
