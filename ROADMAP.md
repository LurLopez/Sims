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

### 2. Pantalla de Habilidades + descubrimiento progresivo
- **Estado**: Las barras existen. Falta el sistema de descubrimiento (`Conocimiento[]`).
- **Qué hacer**:
  - Añadir `Variables_Dinamicas.Conocimiento` (Array de 6 ints, persistido).
  - Incrementar Conocimiento al ejecutar cada actividad que use esa habilidad.
  - Mostrar `min(Conocimiento[i], Innata[i])` en la pantalla Habilidades.
  - Dialogo de revelación cuando Conocimiento alcanza Innata.
  - Pistas contextuales tras cada actividad ("te ha costado", "lo has bordado").
  - Decadencia del Progreso por desuso (1 punto cada 3 días sin actividad, tras umbral de 5 días).
- **Esfuerzo**: 2–3 días.

### ~~3. Sistema universitario + examen del jugador~~ ✅ HECHO (parcial)
- Carreras implementadas con libros y apuntes. El minijuego de examen sigue pendiente.
- **Pendiente**: Minijuego de 10 preguntas tipo test en el examen. Nota final combinada jugador + personaje.

### ~~4. Eventos aleatorios narrativos~~ ✅ HECHO
- 20 eventos generales con franja horaria + despido por higiene.

### 5. Minijuego de examen universitario
- **Por qué**: es el **feature único y vendible**. Mecánica que diferencia este juego de un BitLife clónico.
- **Qué hacer**:
  - Minijuego de 10 preguntas tipo test cuando llega el examen.
  - Nota final = (nota_del_jugador × peso1) + (estudio_del_personaje × peso2).
  - Aprobar desbloquea trabajos mejor pagados.
- **Esfuerzo**: 1 semana.

### 6. Minijuego genérico aplicado a actividades
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
