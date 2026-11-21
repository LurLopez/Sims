# Propuesta de Diseño — Minijuego Extenso de Cocina (gestión de pedidos)

> **Propósito de este documento:** Servir como fuente de trabajo en NotebookLM para debatir, equilibrar y cerrar las especificaciones de un minijuego extenso de gestión de pedidos integrado en **SIMS 0.33**, antes de generar el prompt final de implementación en Godot 4.4.
>
> **Estado (nov 2026):** la economía ya está implementada como **Caja del restaurante en € + costes**: cada servicio ingresa `ventas − 30% ingredientes − (6 € + 2 € × nivel) − 30% merma` en la Caja (paga las 5 mejoras), mientras el Sim cobra propinas (50% del bote), `5%` del beneficio neto y primas por estrellas. Fuera de turno, los 2 primeros servicios/día con ≥1★ pagan paga completa; después se aplica el modo práctica al 25% (la Caja sigue al 100%). En turno activo la paga es ilimitada, las propinas son ×1.5 y se suma el `+10%` de nómina. La **pantalla de Mejoras** (`Scripts/GUI/Minijuego_Cocina/Mejoras_Cocina.gd`) también está implementada: modal a pantalla completa con las 5 mejoras, escaparate de la siguiente versión, pestañas Nv.1–3 y compra pagada con la Caja, ilustrada con 15 sprites propios (3 por mejora). La especificación vigente está en `Funcionalidades/Minijuego_Cocina/Documentacion/MINIJUEGO_COCINA.md`.

---

## 1. Resumen de la idea

Para evitar que el bucle diario de **SIMS 0.33** se vuelva repetitivo, esta funcionalidad convierte la rama de cocina y hostelería en **un juego completo dentro del juego**, muy fiel al bucle adictivo de los juegos de gestión de restaurantes (gestión de comandas en tiempo real, mejoras de cocina, niveles con 1–3 estrellas y logros), pero conectado directamente con la vida, economía y habilidades del Sim.

---

## 2. Contexto técnico actual en SIMS 0.33 (puntos de anclaje)

- **Motor y formato:** Godot 4.4 (GDScript 2.0), Android **portrait (`720×1280`)** con `stretch/aspect="expand"`.
- **Escala de tiempo real:** 1 semana real = 1 año de juego (Modo Rápido: 1 día real = 1 año, con `Multiplicador_Precios() = 0.1`).
- **Sistemas de cocina ya existentes:**
  - `Variables_Dinamicas.Progreso_Cocina` (1–100; sube cocinando y no decae).
  - `Variables_Dinamicas.Tuppers`: raciones caseras con `{id, porcentaje_restante, calidad, minuto_creacion, minuto_caducidad}` (caducidad base 3 días en normal / 1 día en rápido; coste base `2,00 €` cada 15 min).
  - **Habilidades innatas (`Variables_Estaticas.Habilidades`)** que ya contribuyen a cocina:
    - `[2]` **Destreza manual** (peso 40)
    - `[5]` **Paciencia** (peso 25)
    - `[6]` **Sangre fría** (peso 20)
    - `[3]` **Memoria** (peso 15)
  - **Trabajos de hostelería ya implementados (`Variables_Estaticas.gd`):**
    - `Trabajar_En_Comida_Rapida` (8–16h, `10.0 €/h`, sin requisito)
    - `Trabajar_De_Ayudante_Cocina` (11–19h, `17.0 €/h`, `requisito_cocina = 30`)
    - `Trabajar_De_Cocinero_Partida` (12–20h, `24.0 €/h`, `requisito_cocina = 60`)
    - `Trabajar_De_Chef_Ejecutivo` (13–21h, `36.0 €/h`, `requisito_cocina = 85`)

---

## 3. Mecánica central de gestión de pedidos (2D Portrait)

El minijuego se desarrolla en una escena 2D vertical (`720×1280`) pensada para jugar con el pulgar (toques rápidos):

1. **Barra superior (Clientes):**
   - 3 a 4 huecos de clientes que van llegando durante el servicio (duración de nivel: ~60–90 segundos).
   - Cada cliente muestra su **pedido** (1 a 3 ítems: plato principal + guarnición/salsa + bebida) y una **barra de paciencia** (verde → amarillo → rojo).
   - Entregar rápido da **propina** y activa **combos** (x2, x3) si encadenas entregas seguidas.
2. **Zona central (Estaciones de cocina y emplatado):**
   - **Fogones / Plancha / Horno:** Al tocar un ingrediente crudo pasa a cocinarse con una barra circular o lineal de cocción:
     - *Cocinando* → **En su punto** (verde, listo para pasar al plato) → **¡Quemado!** (rojo/humo si tardas demasiado; hay que tirarlo a la **papelera** perdiendo dinero/tiempo).
   - **Mesa de emplatado:** Huecos donde colocas la base (pan, plato, pasta) y vas añadiendo los ingredientes cocinados + acompañamientos antes de tocar al cliente para servir.
   - **Bebidas / Postres:** Máquina automática con recarga temporal (ej. café, refresco, copa).
3. **Fin de nivel (1 a 3 estrellas):**
   - Objetivo mínimo de monedas recaudadas en el servicio (1 estrella para superar el nivel, 2 y 3 estrellas para recompensas extra).

> **Nota de implementación (noviembre de 2026):** el juego final no usa la cocina en vertical descrita en esta sección. El mapa de niveles se mantiene en vertical `720×1280`, pero la partida se juega en horizontal `1280×720`. El mapa abre sin niveles visibles: muestra las 4 tarjetas de mundo dentro de un panel cartoon (`Selector_Niveles_Arte.gd`: marco celeste, tablero azul y monedas verdes). Al tocar una tarjeta jugable, el tablero de 15 niveles sustituye a la lista; «ATRÁS» regresa al selector y «Mejoras» solo se habilita con un mundo jugable abierto. La pantalla de Mejoras es un modal a tamaño completo (`Mejoras_Cocina.gd`) con las 5 mejoras, el escaparate de la siguiente versión, pestañas Nv.1–3 y compra con la Caja. En partida, **MENÚ → Al mapa** pide confirmación (`Modal_Confirmar_Salida`) y pausa el nivel; el botón atrás de Android y `Escape` pasan por `_Volver_Atras()`, y el minijuego desactiva temporalmente «Quit On Go Back» (`set_quit_on_go_back(false)` en `_ready()`, restaurado en `_exit_tree()`). Detalle completo en `Funcionalidades/Minijuego_Cocina/Documentacion/MINIJUEGO_COCINA.md`.

---

## 4. Estructura extensa: Restaurantes, Mejoras y Logros

### A. 3 Restaurantes Progresivos (~15 niveles cada uno = 45 niveles)
Conectados con el mundo del juego:
1. **Restaurante 1 — *Burger & Street Food* (Desbloqueado desde inicio / Comida Rápida):**
   - Hamburguesas, patatas fritas, refrescos, toppings simples (queso, bacon).
2. **Restaurante 2 — *Bistró Tradicional* (Desbloqueado con `Progreso_Cocina >= 30` o completando R1):**
   - Filetes/pescados al punto, salsas, guarniciones, cafés/postres.
3. **Restaurante 3 — *Alta Cocina Gourmet* (Desbloqueado con `Progreso_Cocina >= 65` o completando R2):**
   - Platos multi-paso complejos, tiempos más exigentes, clientes muy rentables pero impacientes.

### B. Tienda de Mejoras del Restaurante (progresión de gestión de restaurantes)

> **Implementado (nov 2026):** las 5 mejoras (`plancha`, `emplatado`, `termostato`, `ingredientes`, `ambiente`) se compran con la **Caja del restaurante** (90–360 €) desde la pantalla `Scripts/GUI/Minijuego_Cocina/Mejoras_Cocina.gd`: lista con estrellas y coste a la izquierda, escaparate grande de la siguiente versión a la derecha, pestañas `Nv.1/Nv.2/Nv.3` con `INCLUIDO`/coste/`BLOQUEADO` y comparativa `AHORA / CON LA MEJORA`. No hay gemas ni moneda premium. Arte: 15 PNG (3 variantes por mejora) en `Imagenes/Minijuego_Cocina/Mejoras/`, procesados con `python3 tools/procesar_mejoras_cocina.py` desde `Arte_Fuente/Minijuego_Cocina/Mejoras/` (prompts P22–P26). QA con `Escenas/Herramientas/Captura_Mejoras_Cocina.tscn`; suite del minijuego **33/33**. Detalle en `Funcionalidades/Minijuego_Cocina/Documentacion/MINIJUEGO_COCINA.md`.

Cada restaurante tiene mejoras comprables en niveles (Nv. 1 → Nv. 3):
- **Equipamiento de cocina:** Más huecos en plancha/platos (de 2 a 4), cocción más rápida, máquina de bebidas automática/doble.
- **Tolerancia a quemado:** Platos aguantan más tiempo en su punto antes de quemarse.
- **Ingredientes:** Aumentan el precio de venta por plato.
- **Interior / Ambiente:** Aumenta la paciencia de los clientes y las propinas.

### C. Sistema de Logros
Logros con progreso acumulativo y recompensa:
- *Primer servicio* / *Sin quemar ni un plato* / *Combo x5* / *100 clientes atendidos* / *3 estrellas en todos los niveles de un restaurante* / *Maestro de la Alta Cocina*.

---

## 5. Ventajas reales en el mundo de SIMS 0.33 (lo que lo conecta con el Sim)

Para que jugar al minijuego tenga impacto real en la vida del Sim (y viceversa):

1. **Impacto del Sim en el minijuego:**
   - `Habilidades[2]` (**Destreza manual**): reduce ligeramente el tiempo de cocción/preparación.
   - `Habilidades[5]` (**Paciencia**): da un % extra de margen antes de que se queme la comida o se enfade el cliente.
   - `Habilidades[6]` (**Sangre fría**): reduce la penalización de propina/paciencia en horas punta.
   - `Necesidades_Basicas` (`Descanso` / `Salud_Mental`): si están muy bajas (<25), el servicio es más exigente o da menos propina.
2. **Ventajas del minijuego hacia el Sim (recompensas):**
   - **Dinero:** Ganar propinas/beneficios netos por servicio superado (escalados con `Multiplicador_Precios()`).
   - **Progreso de cocina:** Sube `Progreso_Cocina` mucho más rápido que cocinar en casa, desbloqueando antes los trabajos de `Ayudante`, `Cocinero_Partida` y `Chef_Ejecutivo`.
   - **Ventajas en casa (`Tuppers`):** Al alcanzar ciertos logros o estrellas en restaurantes, desbloquear mejoras pasivas permanentes en el hogar:
     - *Tuppers de chef:* +1 día extra de caducidad o +15 de calidad base en los tuppers caseros.
     - *Compra inteligente:* descuento en el coste de `Cocinar` en casa.
   - **Ventajas laborales en hostelería:** Bonus permanente de salario (+10 % / +20 %) en `Trabajar_De_Ayudante_Cocina`, `Cocinero_Partida` y `Chef_Ejecutivo` según estrellas/logros conseguidos.

---

## 6. Decisiones abiertas para debatir con NotebookLM

Usa estas preguntas para cerrar la especificación exacta antes de pasar a código:

1. **Economía y moneda (¿dinero del Sim o moneda separada?):**
   - ¿Las mejoras de la cocina se compran con `Variables_Dinamicas.Dinero` (arriesgando el dinero del alquiler/bolsa para ganar más luego), o con una moneda propia del restaurante ("Caja del Restaurante") de la que solo las propinas/premios pasan a `Dinero`?
   - *Riesgo a vigilar:* Que repetir el Nivel 1 muchas veces no genere dinero infinito que rompa el alquiler (`200 €/semana`) ni los trabajos universitarios.
2. **¿Cuándo se puede jugar?**
   - *Opción A:* Acceso libre desde un botón ("Cocina / Restaurante") en cualquier momento para jugar niveles cuando te apetezca (con un límite diario o coste de `Descanso`/`Higiene` por partida).
   - *Opción B:* Ligado al turno de trabajo de hostelería (durante tu jornada laboral puedes entrar a jugar un servicio para multiplicar lo que ganas ese día).
   - *Opción C (Híbrida):* Modo libre por niveles siempre disponible (para no frustrar cuando quieres jugar), y un bonus extra si lo juegas estando contratado en hostelería.
3. **Desgaste de necesidades del Sim al jugar un nivel:**
   - ¿Jugar un nivel de 60–90 segundos consume un poco de `Descanso` y `Higiene` del Sim (por el estrés de la cocina) o no toca las necesidades?
4. **Nivel de detalle del MVP (primera fase):**
   - ¿Empezamos por los 3 restaurantes completos (45 niveles) o cerramos primero **1 restaurante completo (15 niveles) + todas las mejoras + logros + conexión con el Sim** y dejamos los restaurantes 2 y 3 como datos configurables?
5. **Sistema de Guardado:**
   - ¿Los niveles superados, estrellas, mejoras compradas y logros pertenecen a la partida actual (`Guardar_Variables_Dinamicas.dat`) o los **logros** se guardan entre partidas (`Guardar_Variables_Estaticas.dat`)?

---

## 7. Prompts recomendados para usar en NotebookLM

- **Para equilibrar la economía sin romper el juego base:**
  > *"Analizando la economía de SIMS 0.33 (`04_ECONOMIA_ALQUILER_BOLSA_TIENDA.md` y salarios de hostelería de 10–36€/h) y `09_PROPUESTA_MINIJUEGO_COCINA.md`, diseña el sistema económico del minijuego para que comprar mejoras y ganar propinas sea muy adictivo, pero sin permitir farmear dinero infinito fácilmente en el Nivel 1."*

- **Para diseñar las recetas, mejoras y logros concretos:**
  > *"Con base en `09_PROPUESTA_MINIJUEGO_COCINA.md`, define la tabla exacta de ingredientes, estaciones y recetas de los 3 restaurantes, la lista de mejoras (niveles 1–3 con costes y efectos) y 10–12 logros con sus ventajas concretas sobre `Tuppers`, `Progreso_Cocina` y salarios."*

- **Para cerrar la especificación paso a paso:**
  > *"Ayúdame a responder una a una las 5 preguntas de la sección 6 de `09_PROPUESTA_MINIJUEGO_COCINA.md`. Dame tu recomendación argumentada para Android portrait (`720×1280`) y espera mi confirmación en cada punto."*
