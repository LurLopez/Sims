# Roadmap — SIMS 0.33

## Estado actual del juego

El bucle de juego ya funciona end-to-end. La GUI tiene cuatro pantallas accesibles desde la `Barra_Abajo`:

| Botón | Estado | Notas |
|---|---|---|
| **Necesidades Básicas** | Hecho | 5 barras (Salud Física, Salud Mental, Hambre, Descanso, Higiene) que cambian con el tiempo y la actividad. |
| **Progreso** | Hecho | 3 barras (Deporte, Académico, Manualidades) que aumentan al hacer actividades relacionadas. |
| **Actividades** | Hecho | Calendario semanal, selección de bloques, mini calendario con preview blink, cancelar/crear actividad. |
| **Habilidades / Talentos** | **Pendiente** | El icono existe pero no abre nada. Hay que diseñar e implementar esta pantalla — ver sección siguiente. |

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

### 1. Economía real (dinero, alquiler, comida)
- **Por qué primero**: sin presión económica no hay tensión. El jugador necesita un motivo para trabajar.
- **Qué hacer**:
  - `Dinero -= alquiler` cada lunes (semana real).
  - `Dinero -= coste_comida` cuando se programa `Comer`.
  - Trabajo paga al final del turno.
  - Si `Dinero < 0` → desalojo → game over o consecuencia narrativa.
- **Esfuerzo**: 1–2 días.

### 2. Pantalla de Habilidades + descubrimiento progresivo
- **Por qué segundo**: define toda la estrategia del jugador. Mientras no sepa sus aptitudes, no puede planificar a medio plazo.
- **Qué hacer** (diseño completo en [Progreso.md](Progreso.md)):
  - Añadir `Variables_Dinamicas.Conocimiento` (Array de 6 ints, persistido).
  - Incrementar Conocimiento al ejecutar cada actividad que use esa habilidad.
  - Pantalla `Habilidades` con 6 barras mostrando `min(Conocimiento[i], Innata[i])`.
  - Dialogo de revelación cuando Conocimiento alcanza Innata.
  - Pistas contextuales tras cada actividad ("te ha costado", "lo has bordado").
  - Decadencia del Progreso por desuso (1 punto cada 3 días sin actividad, tras umbral de 5 días).
- **Esfuerzo**: 3–4 días.

### 3. Sistema universitario + examen del jugador
- **Por qué tercero**: es el **feature único y vendible**. Mecánica que no he visto en otros life-sim. Profundidad emocional: el personaje estudió toda la semana, ahora TÚ tienes que aprobar.
- **Qué hacer**:
  - Matricularte en una carrera (empieza con UNA, p.ej. Derecho).
  - Duración 4 semanas reales. Cada semana se programa "Estudiar".
  - Viernes por la tarde: examen. Se abre un minijuego de 10 preguntas tipo test.
  - Nota final = (nota_del_jugador × peso1) + (estudio_del_personaje × peso2).
  - Aprobar la carrera desbloquea trabajos mejor pagados.
- **Esfuerzo**: 1–2 semanas (lo más grande del roadmap).

### 4. Eventos aleatorios narrativos
- **Por qué cuarto**: barato y alto impacto en retención. Rompe la monotonía.
- **Qué hacer**:
  - 20–30 eventos cortos: "Te ofrecen un ascenso", "Te enfermas", "Encuentras 50€ en la calle", "Un amigo te invita a una fiesta"…
  - Cada evento: condición de disparo + 1–3 opciones + consecuencia (dinero, necesidad básica, progreso, dia perdido…).
  - Disparador: probabilidad pequeña cada día.
- **Esfuerzo**: 3–5 días (el diseño del contenido es lo que más cuesta).

### 5. Minijuego genérico aplicado a 2–3 actividades
- **Por qué quinto**: convierte tiempo pasivo en activo, pero hay que validar antes de escalar.
- **Qué hacer**:
  - UN minijuego sencillo (tap-rhythm, memoria, o cálculo mental rápido).
  - Skin distinto por actividad para que parezca específico.
  - Opcional. Da +20% al efecto base de la actividad.
- **Esfuerzo**: 4–7 días.
- **Nota**: NO hacer un minijuego por actividad (8+ minijuegos = trampa de scope). Si funciona el genérico, después se escala.

### 6. Relaciones simples (NPCs)
- **Por qué sexto**: añade dimensión social, abre el espacio para eventos románticos y narrativos.
- **Qué hacer**:
  - 2–3 NPCs base: amigo, pareja potencial, familiar.
  - Cada uno tiene `afinidad` (0–100).
  - Programar "Quedar con X" sube afinidad + salud mental.
  - Si afinidad > umbral → desbloquea evento (cita, boda, etc.).
- **Esfuerzo**: 1 semana.

### 7. Hitos por edad
- **Por qué séptimo**: estructura narrativa al largo plazo. Da sentido a las 60 semanas reales.
- **Qué hacer**:
  - 25 años → puedes casarte.
  - 30 años → puedes tener hijos.
  - 50 años → reflexión de mitad de vida.
  - 65 años → jubilación.
  - 80+ años → game over.
- **Esfuerzo**: 3–5 días (depende de cuántos hitos haya).

### 8. Avatar visual del personaje
- **Por qué último**: muchísimo trabajo de assets. No es necesario para validar que el juego funciona.
- **Qué hacer**: dejarlo para después del MVP. Mientras tanto, un retrato estático + texto descriptivo basta.
- **Esfuerzo**: 2–4 semanas (con assets).

---

## Notas estratégicas

- **No intentar todo a la vez.** Implementar 1–2 al mismo tiempo, validar, seguir.
- **El "killer feature" del juego es el examen universitario.** Es lo que diferencia este juego de un BitLife clónico. Construirlo bien.
- **Avatar visual y minijuegos por actividad** son trampas de scope para un prototipo. Resistir el impulso.
- **Onboarding de los primeros 10 minutos** es lo que determina la retención en móvil. Cuando esté el roadmap implementado, dedicar 1 semana solo a pulir esos primeros minutos.
