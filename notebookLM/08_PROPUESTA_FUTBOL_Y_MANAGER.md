# Propuesta de Diseño — Carrera de Futbolista y Modo Mánager (*Top Eleven*)

> **Propósito de este documento:** Servir como fuente de trabajo en NotebookLM para debatir, aterrizar y cerrar las especificaciones de la nueva línea de juego deportivo en **SIMS 0.33** antes de pasar a implementación.

---

## 1. Resumen de la idea

Añadir una nueva trayectoria vital de dos etapas conectadas dentro del simulador de vida:

1. **Etapa 1 — Futbolista profesional (juventud/madurez):**
   - El Sim entra en el mundo del fútbol (desde categorías bajas) y avanza jugando temporadas de liga y entrenando.
   - **Decisión técnica actual:** Para no disparar la complejidad inicial, el minijuego táctico tipo *Score! Hero* (en versión 2D cenital portrait) **se deja para una fase posterior**. En esta primera versión, los partidos se resuelven mediante **simulación por estadísticas, estado físico y eventos**, dejando preparada la arquitectura para enchufar el minijuego 2D más adelante.
2. **Etapa 2 — Retiro y Modo Mánager (tipo *Top Eleven*):**
   - Tras varios años de carrera (o al decidir retirarse), el Sim cuelga las botas y da el salto a los despachos/banquillos.
   - Se desbloquea un sistema de gestión de club donde puede **fichar jugadores, definir alineación/táctica, gestionar salarios y competir en liga**.

---

## 2. Contexto técnico actual de SIMS 0.33 (restricciones a respetar)

- **Motor y formato:** Godot 4.4 (GDScript), Android en formato **portrait (`720×1280`)** con `stretch/aspect="expand"`.
- **Escala de tiempo real:**
  - El personaje vive de los **18 a ~80 años**.
  - **1 semana real = 1 año de juego** (~60 semanas reales de vida total).
  - El tiempo avanza minuto a minuto en tiempo real (`Matriz_Jugador` de 1440 filas × 574 columnas).
- **Sistemas existentes con los que debe convivir e integrarse:**
  - `Progreso`: `[0] Deporte`, `[1] Académico`, `[2] Manualidades` (1–100) + `Progreso_Cocina`.
  - `Habilidades` innatas: `Deporte`, `Inteligencia`, `Destreza manual`, `Memoria`, `Liderazgo`, `Paciencia`, `Sangre fría`.
  - `Necesidades_Basicas`: `Salud_Fisica`, `Salud_Mental`, `Hambre`, `Descanso`, `Higiene`.
  - `Actividades`: `Actividad_Fija_Trabajo` (horarios fijos y días laborales) + prioridades P1/P2/P3.
  - `Economia`: `Dinero`, alquiler semanal (200 €/semana), inversión en bolsa, tienda de objetos.
  - `Pantalla_Mensajes`: bandeja de mensajes/crónicas dentro del Perfil.
  - Guardado en `Guardar_Variables_Dinamicas.dat` (debe mantener retrocompatibilidad con partidas existentes).

---

## 3. Diseño preliminar por etapas

### Etapa 1: Futbolista (versión inicial sin minijuego)
- **Acceso:** Requisitos mínimos (p. ej. `Progreso[0]` Deporte ≥ X, edad máxima de entrada).
- **Rutina semanal:**
  - Entrenamientos programados en el calendario (consumen necesidades básicas, mejoran `Deporte` y forma física).
  - Partidos de liga en días/horas concretas.
- **Resolución de partidos (hueco preparado para el futuro *Score! Hero* 2D):**
  - Ahora: función `Simular_Partido_Jugador()` que usa `Progreso[0]`, `Habilidades` (`Deporte`, `Liderazgo`, `Sangre fría`), `Salud_Fisica`, `Descanso` y nivel del equipo rival.
  - Resultado enviado a `Pantalla_Mensajes` (crónica: resultado, goles, asistencias, valoración, posible lesión).
- **Progresión:** Divisiones (p. ej. 3.ª → 2.ª → 1.ª → Élite), mejora de salario y ofertas de otros clubes al final de temporada.

### Etapa 2: Mánager / Club (tipo *Top Eleven*)
- **Transición desde el retiro:**
  - El legado como jugador (títulos, goles, última división) + el `Dinero` personal acumulado influyen en el punto de partida (categoría del club y presupuesto inicial).
- **Módulos del Modo Club:**
  1. **Plantilla y Táctica:** ~15 jugadores (11 titulares + suplentes), formación (`4-4-2`, `4-3-3`, `3-5-2`, etc.), media global, edad y fatiga.
  2. **Mercado de Fichajes:** Pool rotativo de jugadores fichables (precio de traspaso + salario semanal), venta de jugadores propios y renovación de contratos.
  3. **Liga y Partidos:** Liga de 8–10 equipos con jornadas periódicas, tabla de clasificación, goleadores y simulación por medias de ataque/medio/defensa + táctica.
  4. **Economía del Club:** Caja separada de la cuenta personal del Sim (ingresos por taquilla, premios de liga, ventas; gastos por salarios). Posibilidad de asignarse un sueldo o invertir dinero propio en el club.

---

## 4. Decisiones abiertas para debatir con NotebookLM

Usa estas preguntas para definir las reglas exactas antes de diseñar la arquitectura en código:

### A. Ritmo y escala de tiempo real
1. **Duración de una temporada de liga:**
   - *Opción 1:* **1 semana real = 1 temporada = 1 año de juego** (alineado al 100 % con la edad del Sim; p. ej., liga de 10 equipos = 9 o 18 jornadas → 1–3 partidos por día real).
   - *Opción 2:* Temporadas más cortas (p. ej. 2 temporadas por semana real) para que haya más acción en menos días.
2. **¿Cuántos años reales tarda en llegar al retiro?**
   - Si 1 año = 1 semana real y un futbolista se retira a los 35 años (empezando a los 18), serían **17 semanas reales (~4 meses)**.
   - ¿Debe existir **retiro voluntario anticipado** (p. ej. a partir de los 25–28 años o tras 2–3 temporadas) o posibilidad de entrar al modo Mánager también comprando un club sin haber sido futbolista estrella?
3. **Partidos cuando el jugador no abre la app:**
   - ¿Se simulan automáticamente a la hora fijada en `Matriz_Jugador` y luego lees el resumen en Mensajes?
   - Cuando en el futuro exista el minijuego 2D, ¿habrá una ventana (p. ej. 24h) para jugarlo antes de que se autosimule?

### B. Etapa 1 — Carrera de Futbolista
4. **Compatibilidad con otros trabajos o estudios:**
   - ¿Ser futbolista es dedicación exclusiva (como un trabajo P2) o en categorías bajas (3.ª división) se puede compatibilizar con estudios/trabajo a tiempo parcial?
5. **Sistema de lesiones y necesidades:**
   - ¿Jugar o entrenar con `Descanso` o `Salud_Fisica` bajos (<30) puede provocar una lesión temporal (ej. 1–2 días reales sin poder jugar)?
6. **Contratos y fichajes como jugador:**
   - ¿Solo recibes ofertas automáticas al final de temporada o puedes pedir traspaso / negociar salario?

### C. Etapa 2 — Modo Mánager (*Top Eleven*)
7. **Rol del Sim en el club:**
   - *Opción A (Presidente-Mánager):* Compras/fundas un club con tu propio dinero (conectando directamente con el ahorro y la bolsa).
   - *Opción B (Entrenador contratado):* Un club te contrata con un salario fijo y tú gestionas un presupuesto que pertenece al club (si lo haces mal, te despiden).
   - *Opción C (Híbrido):* Empiezas como entrenador contratado y, cuando acumulas suficiente dinero personal, puedes comprar tu propio club.
8. **Profundidad del Mercado de Fichajes:**
   - ¿Compra directa a precio fijo/negociación simple con IA, o subastas/ofertas con barra de interés?
   - ¿Los jugadores de tu plantilla envejecen y se retiran cada año de juego (1 semana real), obligando a renovar el equipo con cantera/fichajes?
9. **Economía entre Club y Sim:**
   - Para evitar dinero infinito fácil (o bancarrota injusta), ¿cómo se regula el flujo entre la caja del club y `Variables_Dinamicas.Dinero` (alquiler de 200 €/semana, objetos, bolsa)?
10. **Interacción diaria del Mánager:**
    - ¿Qué acciones debe hacer el usuario cada día para sentir que "juega" a *Top Eleven* en 2–5 minutos? (Ej.: revisar lesionados/cansados, ajustar el 11 titular, ojeador/mercado del día, entrenar una línea del equipo).

### D. UI / UX en Portrait (`720×1280`)
11. **Dónde vive en la interfaz actual:**
    - ¿Un nuevo botón/modal desde `Carrera_Button` o un panel principal dedicado ("Fútbol / Club")?
    - ¿Cómo mostrar la alineación 11v11, la tabla de liga y el mercado de forma cómoda en vertical sin saturar la pantalla?

---

## 5. Prompts recomendados para usar en NotebookLM

Puedes copiar cualquiera de estos prompts en tu chat con NotebookLM teniendo cargadas las fuentes del proyecto (`00` a `08`):

- **Para definir el ritmo y evitar frustración:**
  > *"Analizando la escala de tiempo de SIMS 0.33 (1 semana real = 1 año de juego) y la propuesta de Futbolista + Mánager en `08_PROPUESTA_FUTBOL_Y_MANAGER.md`, propón un calendario realista de temporadas, edad de retiro y duración de partidos para que el jugador no tenga que esperar meses reales para probar el modo Top Eleven, sin romper la coherencia con el resto del juego."*

- **Para equilibrar la economía:**
  > *"Compara la economía actual de SIMS 0.33 (salarios de 10–36€/h, alquiler de 200€/semana, bolsa) con los salarios de futbolista y los presupuestos de un club tipo Top Eleven. Propón rangos numéricos concretos de sueldos, premios, precios de fichajes y reglas entre dinero personal y presupuesto del club."*

- **Para cerrar la especificación final (MVP):**
  > *"Ayúdame a responder una a una las 11 preguntas de la sección 4 de `08_PROPUESTA_FUTBOL_Y_MANAGER.md`. Empieza por el bloque A (Ritmo y tiempo real), dame tu recomendación argumentada según la arquitectura actual del juego y espera mi decisión antes de pasar al bloque B."*

---

## 6. Estado de implementación

- **Fase 1 — Modo Jugador: IMPLEMENTADA** en SIMS 0.33.
  - Autoload `Sistema_Futbol`, motor puro `Simulador_Futbol`, calendario `Calendario_Futbol`, `Actividad_Partido` P3, panel `Panel_Futbol.tscn`, 34 tests GUT.
  - Documentación técnica: `Funcionalidades/Actividades/Futbol/Documentacion/CARRERA_FUTBOL.md`.
  - Incluye fichaje, entrenamientos, liga dominical de 4 equipos con playoff, partido decisivo diario en Modo Rápido, primas, salario, lesiones y conflictos con el trabajo.
- **Fase 2 — Retiro y Modo Mánager (*Top Eleven*): PENDIENTE.** Las preguntas de la sección 4 siguen abiertas para esa fase.
