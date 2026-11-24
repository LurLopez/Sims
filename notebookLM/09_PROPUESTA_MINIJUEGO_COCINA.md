# Propuesta de Diseño — Minijuego Extenso de Cocina (gestión de pedidos)

> **Propósito de este documento:** Recoger el origen de diseño del Minijuego de Cocina y su **estado real implementado** en **SIMS 0.33** para debatir en NotebookLM el **balance, claridad y pulido** pendientes.
>
> **Estado real implementado (22/11/2026) — 🟢 MVP funcional, contenido congelado en Roadmap v3.0:**
> - **4 mundos jugables × 15 niveles = 60 niveles** (no 3 mundos/45 niveles como en la propuesta inicial):
>   1. **Burger & Street Food** (montaje de hamburguesas, patatas y refrescos).
>   2. **Bistró Tradicional** (punto del filete: crudo/poco hecho/al punto/hecho/quemado, filete vectorial 3/4 con hueso, etiquetas bajo la carne, quemados retirables, servicio completo por toque rápido además de arrastre, patatas, salsa, café, tarta y mejoras con textos/arte propios).
>   3. **Cocina de Mercado** (2–4 cazuelas independientes en paralelo combinando 2 ingredientes: fabada, pisto, arroz del senyoret, con margen de quemado + plancha de huevos + agua/sangría).
>   4. **Alta Cocina Gourmet** (corte de pescado entero a clicks en tabla y fritura en sartén, horno con ventana dorada 62–88 %, cazo de salsa que se quema si no se remueve, bodega sommelier tinto/blanco con decantado rápido, 33 sprites 2.5D propios en `Alta/`, guía visual `? GUÍA`, tutorial en vivo y mejoras propias).
> - **Formato y UX:** todo el minijuego (selector 2×2 de mundos, mapa 5×3 de niveles, pantalla de Mejoras y partida) corre en **horizontal `1280×720`** (restaura `720×1280` al volver al Sim); partidas por número de clientes (11–31, sin límite de tiempo), botón **MENÚ** (seguir/repetir/salir), pase de 4 huecos (2 abiertos; Nv.2/Nv.3 abren los demás), mueble bajo de despensa, modales cartoon compartidos (`Arte_Modal_Cocina.gd`) y 15 SFX propios en bus `SFX`.
> - **Economía:** **Caja del restaurante en € + costes** (`ventas − 30% ingredientes − (6 € + 2 € × nivel) − 30% merma`), que paga las 5 mejoras (`Mejoras_Cocina.gd`, 90–360 €). El Sim cobra propinas (50 % del bote, ×1.5 en turno, ×0.25 en práctica), `5%` del beneficio neto y primas por estrellas. Fuera de turno, los 2 primeros servicios/día con ≥1★ dan paga completa; después modo práctica al 25 %.
> - **Progresión y QA:** desbloqueo por trabajar 1 minuto en su puesto o superar 1 nivel del mundo anterior (`desbloqueo_total_qa = true` en `Sistema_Cocina.gd` durante pruebas QA; poner `false` antes de publicar). Rangos de Maestría Culinaria 0–9 (cada 20 ★), 4 prendas exclusivas en Vestuario y bonos pasivos. Suite cocina: **52/52 tests** (1441 aserciones).
> - **Decisión Roadmap v3.0 (Prioridad 4):** **NO añadir mundos, niveles, recetas ni monedas nuevas.** El foco actual en NotebookLM debe ser equilibrar la curva de los 60 niveles, comparar €/h frente a trabajos y fútbol, verificar payback de mejoras, mejorar claridad del desglose final y QA en dispositivo. Documentación técnica: `Funcionalidades/Minijuego_Cocina/Documentacion/MINIJUEGO_COCINA.md` y `MUNDOS_NUEVOS.md`.

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

> **Nota de implementación (noviembre de 2026):** el juego final no usa la cocina en vertical descrita en esta sección. Todo el minijuego (mapa, Mejoras y partida) se juega en horizontal `1280×720` y restaura la vertical `720×1280` al salir al Sim. El mapa abre sin niveles visibles: muestra las 4 tarjetas de mundo dentro de un panel cartoon (`Selector_Niveles_Arte.gd`: marco celeste, tablero azul y monedas verdes). Al tocar una tarjeta jugable, el tablero de 15 niveles sustituye a la lista; «ATRÁS» regresa al selector y «Mejoras» solo se habilita con un mundo jugable abierto. La pantalla de Mejoras es un modal a tamaño completo (`Mejoras_Cocina.gd`) con las 5 mejoras, el escaparate de la siguiente versión, pestañas Nv.1–3 y compra con la Caja. En partida, **MENÚ → Al mapa** pide confirmación (`Modal_Confirmar_Salida`) y pausa el nivel; el botón atrás de Android y `Escape` pasan por `_Volver_Atras()`, y el minijuego desactiva temporalmente «Quit On Go Back» (`set_quit_on_go_back(false)` en `_ready()`, restaurado en `_exit_tree()`). Detalle completo en `Funcionalidades/Minijuego_Cocina/Documentacion/MINIJUEGO_COCINA.md`.

---

## 4. Estructura extensa: Restaurantes, Mejoras y Logros

### A. Propuesta original (3 restaurantes) → Implementación actual (4 mundos × 15 niveles = 60 niveles)
Conectados con el mundo del juego (desbloqueo al trabajar 1 minuto en el puesto o al superar 1 nivel del mundo anterior):
1. **Mundo 1 — *Burger & Street Food* (`Comida Rápida`):** hamburguesas, patatas fritas, refrescos y toppings.
2. **Mundo 2 — *Bistró Tradicional* (`Ayudante de Cocina`):** filetes al punto, patatas, salsa, café y tarta de cereza (servicio táctil completo y mejoras con arte propio).
3. **Mundo 3 — *Cocina de Mercado* (`Cocinero de Partida`):** guisos en 2–4 cazuelas independientes en paralelo, huevos a la plancha, agua y sangría.
4. **Mundo 4 — *Alta Cocina Gourmet* (`Chef Ejecutivo`):** pescado entero cortado a clicks en tabla + fritura en sartén, horno con ventana dorada, cazo de salsa, maridaje tinto/blanco con decantado rápido, 33 sprites 2.5D propios en `Alta/` y mejoras propias.

### B. Tienda de Mejoras del Restaurante (progresión de gestión de restaurantes)

> **Implementado (nov 2026):** las 5 mejoras (`plancha`, `emplatado`, `termostato`, `ingredientes`, `ambiente`) se compran con la **Caja del restaurante** (90–360 €) desde la pantalla `Scripts/GUI/Minijuego_Cocina/Mejoras_Cocina.gd`: lista con estrellas y coste a la izquierda, escaparate grande de la siguiente versión a la derecha, pestañas `Nv.1/Nv.2/Nv.3` con `INCLUIDO`/coste/`BLOQUEADO` y comparativa `AHORA / CON LA MEJORA`. En el Bistró usan textos, beneficios e ilustraciones vectoriales propias (`MEJORAS_UI_POR_RESTAURANTE`). No hay gemas ni moneda premium. Arte: 15 PNG (3 variantes por mejora) en `Imagenes/Minijuego_Cocina/Mejoras/`, procesados con `python3 tools/procesar_mejoras_cocina.py` desde `Arte_Fuente/Minijuego_Cocina/Mejoras/` (prompts P22–P26). QA con `Escenas/Herramientas/Captura_Mejoras_Cocina.tscn`; suite del minijuego **52/52** (1441 aserciones). Detalle en `Funcionalidades/Minijuego_Cocina/Documentacion/MINIJUEGO_COCINA.md`.

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

## 6. Decisiones ya cerradas vs. temas abiertos para debatir en NotebookLM

### Ya cerrado e implementado (no reabrir salvo balance)
1. **Economía:** Caja del restaurante en € + costes, separada de `Variables_Dinamicas.Dinero`; el Sim cobra propinas, 5 % del beneficio y primas por estrellas.
2. **Cuándo se puede jugar:** Modo libre por niveles siempre disponible (2 primeros servicios/día al 100 % y luego práctica al 25 %) + bonus en turno activo (sin límite diario, propinas ×1.5, +10 % nómina).
3. **Alcance de contenido:** 4 mundos × 15 niveles = 60 niveles + 5 mejoras + Rangos 0–9 + 4 prendas + mundos con mecánicas propias.
4. **Guardado:** `Cocina_Estado` en partida (`Guardar_Variables_Dinamicas.dat`) y `Record_Max_Niveles_Cocina` entre partidas (`Guardar_Variables_Estaticas.dat`).

### Temas abiertos para debatir ahora (Roadmap v3.0 · Prioridad 4)
1. **Curva de dificultad de los 60 niveles:** detectar picos/valles de spawns, paciencia y metas en los 4 mundos (hoy comparten curva demasiado similar).
2. **Balance €/hora frente a trabajos y fútbol:** ajustar precios, propinas y costes para que Nv.1–5 paguen poco, Nv.6–10 equivalgan a media jornada y Nv.11–15 a jornada completa (exigiendo mejoras).
3. **Payback de las 5 mejoras:** asegurar retorno en 3–5 sesiones, evitar mejoras muertas y mostrar claramente el retorno en `Mejoras_Cocina.gd`.
4. **Claridad en resultados y UX táctil:** desglose legible (ticket, ventas, propinas, costes, Caja, dinero personal, siguiente estrella y merma) y opción de saltar el tutorial en partidas nuevas.

---

## 7. Prompts recomendados para usar en NotebookLM

- **Para equilibrar los 60 niveles y el €/hora frente al resto del juego:**
  > *"Analizando la economía actual de SIMS 0.33 (`04_ECONOMIA_ALQUILER_BOLSA_TIENDA.md`, trabajos de 10–36 €/h, fútbol) y el modelo implementado en `MINIJUEGO_COCINA.md` / `MUNDOS_NUEVOS.md`, diseña el ajuste de metas, propinas y costes de los 4 mundos (60 niveles) para cumplir las bandas objetivo del Roadmap v3.0 sin crear dinero infinito."*

- **Para revisar payback de mejoras y claridad del modal de resultados:**
  > *"Revisa las 5 mejoras (`plancha`, `emplatado`, `termostato`, `ingredientes`, `ambiente`, costes 90–360 €) y propón cómo hacer que todas tengan un payback de 3–5 servicios y qué desglose exacto debería ver el jugador en el modal de resultados."*
