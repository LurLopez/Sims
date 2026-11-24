# Roadmap y Progreso — SIMS 0.33

> **Versión 3.0 · 21 de noviembre de 2026**
> Este documento resume el roadmap vigente y la mecánica de progresión para NotebookLM.
> La fuente canónica del roadmap es [`ROADMAP.md`](../ROADMAP.md).

---

## 0. Norte del proyecto

SIMS 0.33 es un simulador de vida móvil (Android, vertical 720×1280) donde **el jugador decide y juega**, no solo espera. La escala es **1 semana real = 1 año de juego**; una partida completa dura ~60 semanas reales.

La diferencia frente a un BitLife clónico no es tener más barras: es que **las áreas importantes de la vida tienen un bucle activo propio**.

| Pilar | Bucle activo |
|---|---|
| **Cocina** | Minijuego de gestión de pedidos con economía de restaurante. |
| **Universidad** | Exámenes que se juegan y deciden la nota y el futuro laboral. |
| **Fútbol** | Partidos que se juegan y deciden la carrera deportiva. |
| **Bolsa** | Sesiones de trading con decisiones, riesgo y progresión. |

El objetivo no es añadir más sistemas, sino cerrar bien esos cuatro pilares, equilibrarlos entre sí y dejar el resto para después.

---

## 1. Estado actual (21/11/2026)

| Sistema | Estado | Lo que ya hay | Lo que falta |
|---|---|---|---|
| **Cocina** | 🟢 Prácticamente funcional | 4 mundos × 15 niveles, 5 mejoras, economía Caja + propinas, rangos 0–9, SFX, arte propio, tests. | Balance de dificultad y recompensas, claridad, pulido y QA en dispositivo. |
| **Fútbol** | 🟡 Simulación completa | Fichaje, entrenamientos, liga dominical de 4 equipos, playoff, Modo Rápido, salarios, primas, lesiones y conflictos con el trabajo. | Minijuego de partido. |
| **Universidad** | 🟡 Funcional, diseño débil | 4 carreras (4–5 años), matrícula, examen automático + test de 10 preguntas, apuntes, diplomas y desbloqueo de trabajos. | Rediseño del ciclo, del examen y de las recompensas. |
| **Bolsa** | 🟡 Funcional, sin juego | Inversión pasiva por ticks, aportes y retiradas parciales, eventos de mercado con titulares, gráfico de beneficio y estadísticas, auto-venta por pánico y persistencia. | Minijuego activo de trading. |
| **«Salir a correr» / PARK RUSH 3D** (extra) | 🟢 Implementado | Runner infinito vertical de 3 carriles con mundo 3D, swipe/teclado, trenes aparcados, móviles, largos de 3 vagones y exprés, túnel con cámara rasante, intro y cuenta atrás, tropiezo con segundo aviso, tabla 30 s, imán, x2, zapatillas, jetpack, pogo, caja misteriosa, llaves y reanimación, guardia/perro y 3 retos; récords persistentes y recompensa de Deporte/necesidades desde 100 m; 33 tests del runner y 355/355 de la suite. | Pulido y QA opcional. No entra en la Fase 1 ni altera las prioridades de los cuatro pilares. |
| **Base del simulador** | 🟢 Completa | Necesidades, progreso volátil, habilidades, calendario, trabajos, alquiler/calle, tienda, bienestar, vestuario, eventos, muerte, perfil, guardado, música y ajustes. | Pulir, conectar y equilibrar. |

> **Nota:** «Salir a correr» es un minijuego secundario ya implementado. No cambia el orden de la Fase 1 (universidad → fútbol → bolsa → cocina) ni la decisión de no crear un minijuego por cada actividad: es una pieza extra independiente.

---

## 2. Diagnóstico y decisiones

| Pilar | Lo que funciona | Lo que no funciona | Decisión |
|---|---|---|---|
| **Cocina** | Arte, loop, progresión, economía interna y cantidad de contenido. | Dificultad irregular, recompensas difíciles de leer, economía no comparable con los trabajos y los 4 mundos comparten la misma curva. | **Congelar contenido.** Solo balance, claridad, pulido y QA. |
| **Universidad** | Contenido de las carreras, apuntes, diploma y desbloqueo de empleos. | Burocracia de prematrícula, examen automático con test al 10 %, ventana de 1 hora, estudio genérico, 10 preguntas por año y nota opaca. | **Rediseñar ciclo y examen.** El test del jugador pasa a ser el centro. |
| **Fútbol** | Simulación coherente, liga, salarios, conflictos y persistencia. | Los partidos se resuelven sin jugar; el momento más importante es un mensaje de texto. | **Minijuego de partido MVP.** Modo mánager, después. |
| **Bolsa** | Cartera clara, eventos, historial, gráfico y estadísticas; auto-venta por pánico. | No hay ninguna decisión activa de trading: sigue siendo meter dinero y esperar. | **Sala de trading activa.** La inversión pasiva se mantiene como modo cómodo y ya se puede entender y gestionar. |

---

## 3. Fase 1 — Cerrar los cuatro pilares

Orden recomendado: **universidad → fútbol → bolsa → cocina**. La cocina se puede balancear en paralelo porque no bloquea a nadie.

El antiguo punto «minijuego genérico aplicado a actividades» queda **cancelado**: cada pilar tiene su propio minijuego con consecuencias reales en la economía y la progresión.

### 3.1 Universidad y exámenes (prioridad 1)

**Objetivo:** que estudiar una carrera sea una decisión semanal con tensión real y que el examen sea el momento más memorable del juego.

#### Problemas concretos del sistema actual

- Dos pasos de matrícula (prematrícula → matrícula) con reglas ocultas y cutoff del lunes.
- El examen se resuelve solo; el test del jugador solo suma hasta +10 puntos. La estrategia óptima es ignorarlo.
- Ventana de 1 hora: si no coincides, pierdes el test. Castiga al jugador móvil.
- Solo el «Estudiar» genérico alimenta la carrera; no hay clases, asistencia ni actividades propias.
- Banco de **10 preguntas por año**: el examen es siempre el mismo banco completo y se memoriza.
- Nota opaca (progreso 60 % + habilidades 20 % + necesidades 20 %) y recompensa plana de 2.000 €.

#### Diseño propuesto (MVP)

1. **Un solo estado de matrícula.** Al empezar el curso, el panel muestra «Matricularse en Año N» con su coste. Se paga una vez y se elige la fecha del examen (por defecto, viernes). Sin prematrícula ni conversión automática del lunes.
2. **Clases + estudio.** Añadir «Asistir a clase» como actividad de carrera (2 bloques/semana, 90 min) que sube progreso y desbloquea pistas de apuntes. «Estudiar» sigue existiendo como refuerzo. Faltar a clase no bloquea, pero baja progreso y nota.
3. **Examen del día completo.** El examen aparece como pendiente desde las 00:00 del día elegido. El jugador puede hacerlo **a cualquier hora de ese día**. A las 23:59, si no lo hizo, el personaje lo resuelve solo con penalización. Se elimina la ventana de 1 hora.
4. **Dos partes en el examen:**
   - **Test (60 %):** 10 preguntas, 25 s por pregunta, sin volver atrás. Salen de los apuntes del año y de años anteriores.
   - **Caso práctico (40 %):** una pregunta específica de la carrera, con contexto y 4 opciones:
     - **Ingeniería:** encontrar el bug u ordenar el algoritmo.
     - **Derecho:** elegir el argumento o la prueba correcta.
     - **Medicina:** diagnóstico a partir de síntomas.
     - **Bellas Artes:** elegir composición, paleta o técnica.
   - El caso práctico es el «killer feature»: el examen se siente como la carrera, no como un test genérico.
5. **Nota final:** 40 % progreso + 50 % examen + 10 % estado (descanso, salud mental y habilidades). Aprobado ≥ 50; notable ≥ 70; matrícula de honor ≥ 85.
6. **Consecuencias:** la nota desbloquea el trabajo de la carrera (ya existe) y añade bonus económico por tramo, descuento de matrícula al año siguiente con honor y un mensaje de «qué mejorar» tras suspender. Reintento con coste, sin bloqueo duro.
7. **Contenido:** ampliar el banco a **30–40 preguntas por año y carrera**, etiquetadas por dificultad. El examen final mezcla años anteriores. Los apuntes desbloquean pistas, no la respuesta literal.

#### Flujo anual (una semana real = un curso)

```
Lunes: panel «Matricularse Año N» → pagas y eliges día de examen (por defecto viernes)
Durante la semana: clases / estudiar / trabajar / entrenar
Día del examen: tarjeta «Examen pendiente» → puedes jugarlo a cualquier hora
  → Test + caso práctico → nota y consecuencia
Si no lo juegas: a las 23:59 se resuelve automáticamente con penalización
Resultado: apruebas y pasas de curso, o suspendes y repites (con coste)
```

#### Hitos

- **H1:** máquina de estados simplificada + matrícula única + examen pendiente todo el día.
- **H2:** nuevo modal de examen (test con temporizador + caso práctico) + resultado con desglose.
- **H3:** clases/asistencia + apuntes conectados a preguntas + expansión del banco.
- **H4:** balance de notas, costes y recompensas + migración de saves + tests.

#### Criterios de aceptación

- Un jugador nuevo entiende el ciclo sin guía y no puede perder el examen por no estar conectado a una hora exacta.
- Jugar el examen cambia la nota al menos ±20 puntos respecto a no jugarlo.
- Cada carrera tiene al menos un tipo de pregunta propio.
- 4 años (5 en Medicina) siguen durando 4–5 semanas reales.
- Los saves antiguos con prematrícula/matriculado siguen cargando.
- Tests GUT de estados, fórmula, migración y flujo UI.

**Esfuerzo:** 2–3 semanas.

---

### 3.2 Minijuego de fútbol (prioridad 2)

**Objetivo:** que el partido del domingo sea el momento que espera el jugador, no un mensaje de texto.

#### Lo que ya existe

La carrera de futbolista está implementada: fichaje, entrenamientos, liga dominical de 4 equipos, playoff, Modo Rápido, salarios, primas, lesiones y conflictos con el trabajo. Los partidos se resuelven con `Simulador_Futbol` y se notifican en Mensajes.

#### Diseño propuesto — «Partido en 90 segundos»

- Al empezar un bloque `Partido_Futbol`, si el jugador está en la app, aparece una tarjeta **«Hoy hay partido: ¿lo juegas?»** con las opciones «Jugar» y «Simular». Si no responde en 30 s o no está, se simula como ahora.
- Minijuego vertical 720×1280, **5–6 acciones decisivas**:
  - **3 ataques:** arrastrar para pasar o chutar, barra de potencia/precisión, portero y defensas en movimiento.
  - **2 defensas:** tocar la zona de corte o hacer swipe para entrar al rival.
  - **1 penalti** si el partido llega empatado (usa Sangre Fría).
- Cada acción tiene un resultado (gol, ocasión, pérdida, parada, corte). La actuación genera un `rendimiento` 0–100 y goles/asistencias.
- **Integración con la simulación:** la base del partido sigue saliendo de `Calcular_Puntuacion_Partido` y de la media del rival; el minijuego sustituye la variación aleatoria y añade los goles/asistencias del jugador. El resultado de la liga sigue siendo coherente. Si el jugador no juega, se usa la simulación actual.
- La condición física, la convocatoria y la relación con el entrenador siguen mandando: baja condición = menos acciones y más lentitud.
- Recompensas: primas actuales + bonus de MVP si el rendimiento es alto; subida de relación y progreso de Deporte.
- **Fuera del MVP:** 11v11 completo, táctica, modo mánager y licencias reales.

#### Hitos

- **H1:** motor puro de acciones (`Resolver_Accion`, `Calcular_Rendimiento`) + tests.
- **H2:** pantalla de partido con 5 acciones, arte placeholder y HUD.
- **H3:** integración con `Sistema_Futbol`, tarjeta de elección, auto-simulación y resultados.
- **H4:** arte final (campo, portero, defensas, balón), SFX, pulido y QA.

#### Criterios de aceptación

- Partido de 60–120 s, jugable con una mano y con opción de saltar.
- El rendimiento correlaciona con Deporte, condición y Sangre Fría.
- No hay softlocks; la tabla de liga sigue cuadrando y el auto-simulador sigue funcionando.
- Tests del motor puro y de la integración.

**Esfuerzo:** 2–3 semanas (incluido arte).

> **Fase 2 (después):** modo mánager tipo Top Eleven (plantilla, táctica, fichajes y economía de club). No empezar hasta cerrar la Fase 1.

---

### 3.3 Minijuego de bolsa (prioridad 3)

**Objetivo:** convertir la inversión pasiva en una decisión activa y divertida, sin romper la economía.

#### Diseño propuesto — «Sala de trading»

- Se mantiene la **inversión pasiva actual** como «gestión delegada» para quien no quiera jugar.
- Nueva sesión activa de **2–3 minutos**, en horizontal 1280×720, accesible desde la tarjeta de Bolsa:
  - Eliges el capital (sale de tu dinero; puedes perderlo).
  - **4 activos ficticios** con perfiles: índice estable, empresa de crecimiento, startup volátil y bono seguro.
  - **8 rondas.** En cada ronda ves una noticia y un gráfico de velas; decides comprar, mantener o vender. Una barra de ejecución añade precisión (comprar barato / vender caro).
  - Comisión del 1 %; sin cortos en el MVP; stop-loss opcional.
  - Al final: P&L, XP de `Progreso_Inversion`, desbloqueo de activos/análisis y mensaje de resultado.
- `Progreso_Inversion` desbloquea activos y mejora la lectura de noticias; `Sangre_Fría` reduce el pánico (venta forzada si es baja); la salud mental afecta a la claridad de las pistas.
- La inversión pasiva sigue existiendo, pero da menos XP y menos control.
- **Hitos:** motor de mercado determinista por semilla + tests; UI de gráfico/noticias; integración con dinero y progreso; balance de retorno y riesgo.
- **Criterios:** sesión comprensible tras una partida; el skill pesa más que la suerte (objetivo 60/40); no hay dinero infinito; se puede perder; tests.

**Esfuerzo:** 2 semanas (la UI del gráfico es lo más caro).

---

### 3.4 Cocina: balance y pulido (prioridad 4, en paralelo)

**Decisión:** **no añadir mundos, niveles, recetas ni monedas** hasta que los otros tres pilares estén cerrados. La cocina ya es prácticamente funcional; ahora toca que sea justa y legible.

#### Trabajo

- **Curva de dificultad:** medir con un bot/headless los 60 niveles (clientes, spawn, paciencia, metas y tiempo de limpieza). Detectar picos y valles. Objetivo: 1 estrella con juego básico, 3 estrellas con maestría/mejoras; ningún nivel imposible sin mejoras.
- **Economía:** comparar €/hora de cocina (propinas + parte del beneficio) con trabajos y fútbol. Bandas objetivo:
  - Niveles 1–5: aprendizaje, paga baja.
  - Niveles 6–10: comparable a un trabajo a tiempo parcial.
  - Niveles 11–15: comparable a un trabajo a tiempo completo, exigiendo mejoras.
  - Modo práctica: al 25 %, complemento, no granja.
- **Mejoras:** payback de 3–5 sesiones; evitar mejoras muertas; mostrar el retorno en la pantalla de Mejoras.
- **Claridad:** resultado con desglose (ticket, ventas, propinas, costes, Caja y dinero personal), «siguiente estrella» y aviso de merma.
- **UX/accesibilidad:** objetivos táctiles grandes, tickets legibles, pausa clara, skip de tutorial para veteranos y colores que no dependan solo del tono.
- **QA:** 10 niveles seguidos sin fugas, 60 fps en Android medio, 720×1280 y 720×1600, guardado/carga.
- **No hacer:** más contenido, nuevas monedas, anuncios dentro del minijuego ni multijugador.

#### Criterios de aceptación

- Curva documentada y sin picos injustos.
- €/h dentro de la banda objetivo.
- 10 niveles seguidos sin crash ni fuga de memoria.
- Tests actualizados.

**Esfuerzo:** 3–5 días.

---

## 4. Fase 2 — Economía y mundo (después de los cuatro pilares)

- **Auditoría económica global:** tabla de fuentes y sumideros. Alquiler 200 €/semana, sueldos 10–36 €/h, fútbol 150–10.000 €/semana, matrículas 400–750 €/año, cocina, bolsa y bienestar. Definir bandas y evitar exponenciales. Ajustar salarios de fútbol y retorno de bolsa si hace falta.
- **Modos de dificultad:** Relajado / Normal / Desafiante. `Modo_Rapido` sigue siendo velocidad, no dificultad.
- **Logros y metaprogresión** con bonificaciones permanentes entre partidas.
- **Relaciones (NPCs):** 2–3 NPCs, afinidad 0–100, quedadas y eventos; impacto en salud mental.
- **Hitos por edad:** 25 boda, 30 hijos, 50 mitad de vida, 65 jubilación, 80 muerte (conectada a la muerte existente).
- **Más actividades:** socializar, limpiar, meditar, pasear; que compitan por el calendario.
- **Notificaciones locales:** examen, partido y alquiler; plugin Android.
- **Onboarding:** primeros 10 minutos y tutorial por pilar.

---

## 5. Fase 3 — Lanzamiento

- Integrar anuncios reales (AdMob/UMP/SSV) sobre `Proveedor_Anuncios`; sin pagos ni moneda premium.
- Rendimiento y batería, migración de saves, QA en dispositivos y beta cerrada.
- Assets de tienda, política de privacidad, rating de edad y diferenciación legal.
- Avatares y animaciones adicionales solo si el resto está cerrado.

---

## 6. Orden de sprints

| Sprint | Duración | Trabajo | Salida |
|---|---|---|---|
| **S1** | 1 semana | Universidad H1–H2 | Matrícula única y examen jugable todo el día. |
| **S2** | 1 semana | Universidad H3–H4 + cocina | Casos prácticos, banco ampliado y balance de cocina. |
| **S3–S4** | 2 semanas | Fútbol H1–H4 | Partido jugable de 90 s integrado en la liga. |
| **S5–S6** | 1–2 semanas | Bolsa | Sala de trading completa. |
| **S7** | 1 semana | Economía global | Auditoría, dificultad y ajustes entre pilares. |
| **S8+** | — | Fase 2 | Relaciones, hitos, logros y onboarding. |

---

## 7. No hacer ahora

- Modo mánager de fútbol.
- Más mundos o niveles de cocina.
- Más carreras universitarias (4 bastan hasta que los exámenes sean divertidos).
- Un minijuego distinto para cada actividad.
- Multijugador o funciones sociales.
- Pagos o moneda premium.
- Ampliar el avatar visual (ya existe creador y personaje).

---

## 8. Riesgos

| Riesgo | Mitigación |
|---|---|
| El fútbol crece de alcance (11v11, táctica, mánager). | MVP de 5 acciones; auto-simulación siempre disponible. |
| El rediseño universitario rompe saves o calendario. | Migración explícita y tests de estados. |
| La bolsa se convierte en una máquina de dinero. | Comisiones, riesgo real, capital limitado y simulación. |
| El balance de cocina queda obsoleto al cambiar la economía. | Hacer la auditoría global después de los pilares y revisar entonces. |
| Sesiones demasiado largas en móvil. | Todo skippable o auto-resoluble; 2–5 minutos por acción. |

---

## 9. Métricas de éxito

- El jugador puede explicar el bucle de cada pilar.
- Sesión media de 3–8 minutos con al menos una decisión significativa.
- **>60 %** de exámenes jugados por el jugador, **>40 %** de partidos jugados y **>50 %** de sesiones de bolsa completadas.
- Ningún blocker de progresión y ninguna fuente de dinero infinita.
- Suites GUT en verde y 60 fps en Android medio.

---

# Anexo — Progreso y habilidades

> Fuente completa: [`Documentacion/Progreso.md`](../Documentacion/Progreso.md).

## Las dos métricas

### Progreso (volátil, visible siempre)

- 3 áreas: **Deporte, Académico y Manualidades** en `Variables_Dinamicas.Progreso` (0–100).
- Sube haciendo actividades relacionadas y **baja con el desuso**.
- La decadencia ya está implementada en `Actividades_Habilidades.Comprobar_Decadencia_Progreso()`: tras 5 días reales sin uso, baja 1 punto cada 3 días (escala 1/7 en Modo Rápido).
- Es tu nivel **actual**: «qué tan bueno soy ahora mismo».

### Habilidad mostrada (descubrimiento permanente)

- Refleja el valor **innato secreto** de `Variables_Estaticas.Habilidades` (7 valores 0–100: Deporte, Inteligencia, Destreza, Memoria, Liderazgo, Paciencia y Sangre Fría).
- Se revela progresivamente con las actividades. **Solo sube, nunca baja.**
- Es tu **cap demostrado**: «lo más alto que he probado que puedo llegar».

## Cómo funciona el descubrimiento

Se mantiene `Variables_Dinamicas.Habilidades_Mostradas` (7 ints). Cada actividad que usa una habilidad incrementa su contador de conocimiento; la habilidad mostrada es el mínimo entre ese contador y el valor innato.

Cuando el contador alcanza el valor innato se revela el límite:

> «Has descubierto tu límite natural en Deporte: **27**. Tu talento innato no dará para más en esta área, aunque puedes seguir subiendo tu Progreso a base de esfuerzo (mucho esfuerzo).»

El cap no bloquea técnicamente el Progreso: solo lo hace mucho más costoso. Eso permite pivotar sin sentir que se ha perdido el tiempo.

## Asimetría narrativa

| Talento innato | Revelación explícita | Pista implícita |
|---|---|---|
| Bajo (0–30) | Rápida: la habilidad llega al tope en pocas semanas. | El Progreso apenas sube. |
| Medio (30–70) | Moderada. | El Progreso sube con esfuerzo. |
| Alto (70–100) | Lenta: hace falta mucha práctica. | El Progreso sube rápido desde el primer día. |

**Los malos se enteran por el número. Los buenos se enteran por los resultados.**

## Pistas contextuales

Tras cada actividad se muestra un mensaje breve según el resultado del Progreso: «Te ha costado bastante», «Bien» o «Lo has bordado». Da feedback temprano sin romper el descubrimiento explícito.

## Mapeo actividad → habilidades

- **Deportivo** (`Salir_A_Correr`): 50·Deporte + 40·Liderazgo + 10·Memoria.
- **Académico** (`Estudiar`): 50·Inteligencia + 20·Paciencia + 30·Memoria.
- **Manualidades** (`Practicar_Manualidades`): 50·Destreza + 30·Paciencia + 10·Memoria + 10·Liderazgo.

Cada actividad incrementa el conocimiento de todas las habilidades implicadas.

## Importancia para el nuevo roadmap

- **Universidad:** el Progreso Académico y la Inteligencia/Memoria/Sangre Fría alimentan la nota del examen.
- **Fútbol:** el Progreso de Deporte, la condición física y la Sangre Fría alimentan la convocatoria y el rendimiento.
- **Cocina:** el Progreso de Manualidades y `Progreso_Cocina` alimentan la eficiencia y los rangos.
- **Bolsa:** `Progreso_Inversion` es una progresión aparte que se comparte entre la inversión pasiva y la sala de trading.
