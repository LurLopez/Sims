# Roadmap — SIMS 0.33

## Estado actual del juego

El bucle de juego ya funciona end-to-end. La GUI tiene cuatro pantallas accesibles desde la `Barra_Abajo`:

| Botón | Estado | Notas |
|---|---|---|
| **Necesidades Básicas** | ✅ Hecho | 5 barras (Salud Física, Salud Mental, Hambre, Descanso, Higiene) que cambian con el tiempo y la actividad. |
| **Progreso** | ✅ Hecho | 3 barras (Deporte, Académico, Manualidades) que aumentan al hacer actividades relacionadas. |
| **Actividades** | ✅ Hecho | Calendario semanal, selección de bloques, mini calendario con preview blink, cancelar/crear actividad. |
| **Habilidades / Talentos** | ✅ Hecho | 6 barras de habilidades innatas visibles. Descubrimiento progresivo pendiente. |

### Funcionalidades adicionales implementadas

| Funcionalidad | Estado | Notas |
|---|---|---|
| **Economía / Alquiler** | ✅ Hecho | 200€/semana; sin dinero → calle; necesidades capeadas a 20 en calle. |
| **Trabajos** | ✅ Hecho | Comida rápida, carpintero, científico. Salario al final del turno. Jerarquía P1/P2/P3. |
| **Invertir en bolsa** | ✅ Hecho | Inversión pasiva; ~3 eventos/día; auto-venta si pánico (Sangre_Fría < 30). |
| **Sistema de objetos / Tienda** | ✅ Hecho | Compra/venta de camas, mesas, duchas con multiplicadores de efectos. |
| **Carreras universitarias** | ✅ Hecho | Sistema de carreras; libros desbloqueados por carrera visibles en Apuntes. |
| **Muerte** | ✅ Hecho | Condiciones de muerte del personaje implementadas. |
| **Eventos aleatorios** | ✅ Hecho | Despido por higiene (cooldown 5 días) + 20 eventos generales con franja horaria. |
| **Perfil** | ✅ Hecho | 3 pestañas: Info (datos en tiempo real), Mensajes, Apuntes. |
| **Calendario solo lectura** | ✅ Hecho | Botón horario abre el calendario en modo consulta (`calendario_solo_lectura`). |
| **Jerarquía de actividades** | ✅ Hecho | Prioridades P1 (Normal) / P2 (Trabajo) / P3 (Examen). |
| **Refactorización de escenas** | ✅ Hecho | Escenas reorganizadas; mejoras de UI e iconos. |

---

## Mecánica nueva: Progreso volátil + Habilidad como descubrimiento

> Diseño completo: ver [Progreso.md](Progreso.md).

### El modelo en una frase

- **Progreso** = nivel actual, volátil (sube con práctica, baja con desuso).
- **Habilidad mostrada** = contador de actividades hechas que se detiene al alcanzar tu valor innato secreto. Solo sube, nunca baja.

### Cómo funciona

Cada habilidad innata es un valor 0–100 generado al crear el personaje. El jugador no lo ve. Se mantiene un contador auxiliar `Conocimiento[i]` que sube en 1 por cada actividad relacionada. La Habilidad mostrada en pantalla es:

```
Habilidad_mostrada[i] = min(Conocimiento[i], Innata[i])
```

Cuando se detiene → mensaje: *"Has descubierto tu límite natural en Deporte: 27"*. El cap no bloquea técnicamente el Progreso (solo lo hace mucho más costoso), así que el jugador puede seguir esforzándose o pivotar.

### Asimetría narrativa

| Talento innato | Descubrimiento explícito | Descubrimiento implícito |
|---|---|---|
| Bajo (cap 0–30) | Rápido: Habilidad llega al tope en semanas | Progreso apenas sube |
| Medio (cap 30–70) | Moderado | Progreso sube con esfuerzo |
| Alto (cap 70–100) | Lento: necesita mucha práctica | Progreso sube rápido — lo intuyes desde el día 1 |

**Los malos se enteran por el número. Los buenos se enteran por los resultados.**

### Pistas contextuales tras cada actividad

Para que el jugador no esté completamente a ciegas al principio, después de cada actividad se muestra un mensaje breve según el roll de Progreso: *"Te ha costado bastante"* (cap probablemente bajo), *"Bien"*, *"Lo has bordado"* (cap probablemente alto). Esto da feedback temprano sin romper el descubrimiento explícito.

---

## Roadmap priorizado (mayor → menor importancia)

### ~~1. Economía real (dinero, alquiler, comida)~~ ✅ HECHO
- Alquiler 200€/semana, modo calle, trabajos con salario, inversión en bolsa, tienda de objetos.

### ~~2. Pantalla de Habilidades + descubrimiento progresivo~~ ✅ HECHO
- `Habilidades_Mostradas[]` (6 ints) creado, persistido e incrementado por actividad.
- Capeado en el valor innato (`Variables_Estaticas.Habilidades[i]`), con revelación al alcanzarlo.

### ~~3. Sistema universitario + examen del jugador~~ ✅ HECHO
- Carreras, libros, apuntes y minijuego de examen implementados (`Sistema_Examenes.gd`, `Modal_Examen.gd`).

### ~~4. Eventos aleatorios narrativos~~ ✅ HECHO
- 20 eventos generales con franja horaria + despido por higiene.

### 5. Minijuego genérico aplicado a actividades
- **Por qué**: convierte tiempo pasivo en activo, pero hay que validar antes de escalar.
- **Qué hacer**:
  - UN minijuego sencillo (tap-rhythm, memoria, o cálculo mental rápido).
  - Skin distinto por actividad para que parezca específico.
  - Opcional. Da +20% al efecto base de la actividad.
- **Esfuerzo**: 4–7 días.
- **Nota**: NO hacer un minijuego por actividad (8+ minijuegos = trampa de scope). Si funciona el genérico, después se escala.

### 7. Relaciones simples (NPCs)
- **Por qué**: añade dimensión social, abre el espacio para eventos románticos y narrativos.
- **Qué hacer**:
  - 2–3 NPCs base: amigo, pareja potencial, familiar.
  - Cada uno tiene `afinidad` (0–100).
  - Programar "Quedar con X" sube afinidad + salud mental.
  - Si afinidad > umbral → desbloquea evento (cita, boda, etc.).
- **Esfuerzo**: 1 semana.

### 8. Hitos por edad
- **Por qué**: estructura narrativa al largo plazo. Da sentido a las 60 semanas reales.
- **Qué hacer**:
  - 25 años → puedes casarte.
  - 30 años → puedes tener hijos.
  - 50 años → reflexión de mitad de vida.
  - 65 años → jubilación.
  - 80+ años → game over (muerte implementada, falta conectar con edad).
- **Esfuerzo**: 3–5 días.

### 9. Avatar visual del personaje
- **Por qué último**: muchísimo trabajo de assets. No es necesario para validar que el juego funciona.
- **Qué hacer**: dejarlo para después del MVP. Mientras tanto, un retrato estático + texto descriptivo basta.
- **Esfuerzo**: 2–4 semanas (con assets).

---

## Notas estratégicas

- **No intentar todo a la vez.** Implementar 1–2 al mismo tiempo, validar, seguir.
- **El "killer feature" del juego es el examen universitario.** Es lo que diferencia este juego de un BitLife clónico. Construirlo bien.
- **Avatar visual y minijuegos por actividad** son trampas de scope para un prototipo. Resistir el impulso.
- **Onboarding de los primeros 10 minutos** es lo que determina la retención en móvil. Cuando esté el roadmap implementado, dedicar 1 semana solo a pulir esos primeros minutos.
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
