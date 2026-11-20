# Carrera de Futbolista — Fase 1 (Modo Jugador)

Implementación de la carrera de futbolista dentro de SIMS 0.33. La **Fase 2 (Modo Mánager / Top Eleven)** queda expresamente fuera de alcance.

## Archivos principales

| Archivo | Función |
|---|---|
| `Scripts/Logica/Escena_Principal/Actividades/Futbol/Simulador_Futbol.gd` | Motor matemático puro (condición, convocatoria, puntuación, penaltis, playoff y Modo Rápido). |
| `Scripts/Logica/Escena_Principal/Actividades/Futbol/Calendario_Futbol.gd` | Horarios y días de entrenamiento/partido en Modo Normal y Rápido. |
| `Scripts/Logica/Escena_Principal/Actividades/Futbol/Sistema_Futbol.gd` | Autoload `Sistema_Futbol`: estado, fichaje, programación de bloques, ticks, liga, salario, primas, lesiones y conflictos. |
| `Scripts/Logica/Escena_Principal/Actividades/Herencia/Actividad_Partido.gd` | `Actividad_Partido` (P3) para `Partido_Futbol`. |
| `Scripts/GUI/Escena_Principal/Actividades/Futbol/Panel_Futbol_GUI.gd` | Panel vertical responsive 720×1280. |
| `Escenas/Escena_Principal/Panel_Futbol.tscn` | Escena del panel, instanciada desde `Script_Principal`. |
| `Funcionalidades/Actividades/Futbol/Tests/test_futbol.gd` | 34 tests GUT (motor puro, persistencia, jerarquía, conflictos, integración y UI). |

## Estado persistente

`Variables_Dinamicas.Carrera_Futbol` es un `Dictionary` que se guarda en `Guardar_Variables_Dinamicas.dat` y se normaliza al cargar:

- `Activo`, `Division` (4 = 3ª División Regional, 1 = Superliga), `Relacion_Entrenador`.
- `Entrenamientos_Cancelados_Seguidos`, `Partidos_Jugados`, `Goles_Totales`, `Asistencias_Totales`.
- `Temporadas_Jugadas`, `Titulos_Superliga`, `Salario_Semanal`, `Estado_Temporada`.
- `Entrenamientos_Asistencia` (`Martes`, `Jueves`, `Diario`).
- `Liga_Domingo` (`Jornada_Actual`, `Puntos_Jugador`, `Puntos_Rivales`, `Medias_Rivales`, `Posicion_Regular`).
- Claves internas de bloque en curso, salario y ascenso pendiente.

Los saves sin `Carrera_Futbol` cargan el diccionario por defecto (`Activo = false`) sin errores. El reset de nueva partida en `Menu.gd` también lo restaura.

## Actividades y prioridades

| Actividad | Clase | Prioridad | Efectos NB | Efectos progreso |
|---|---|---|---|---|
| `Entrenamiento_Futbol` | `Actividad_Fija` | P2 | `[2, 1, -2, -3, -3]` | `[4, 0, 0]` |
| `Partido_Futbol` | `Actividad_Partido` | P3 | `[-1, 3, -4, -5, -4]` | `[6, 0, 0]` |

Ninguna entra en el pool de actividades aleatorias. `Partido_Futbol` usa P3 para que ningún trabajo P2 ni actividad temporal P1 lo pise. Los bloques de fútbol se programan en `Matriz_Jugador` al fichar, al cambiar de división y al cambiar la asistencia; no se recorre la matriz en cada minuto.

## Calendario

### Modo Normal

| División | Entrenamiento | Partidos |
|---|---|---|
| 3ª División (4) | Martes y jueves, 19:00–21:00 (120 min) | Domingos 10:00, 13:00, 16:00 y 19:00 (60 min) |
| Profesional (3, 2, 1) | Martes y jueves, 10:00–12:00 (120 min) | Domingos 10:00, 13:00, 16:00 y 19:00 (60 min) |

La liga dominical tiene 4 equipos: 3 jornadas regulares (el jugador contra un rival y el otro cruce simulado) y un 4º partido de playoff:

- Posiciones 1–2: `1º vs 2º` por el ascenso.
- Posiciones 3–4: `3º vs 4º` por la permanencia.

### Modo Rápido

- Entrenamiento **todos los días**, 45 min: 3ª División 18:30–19:15; profesional 10:00–10:45.
- Un **partido decisivo diario** de 60 min a las 20:30–21:30.
- Cada partido diario cuenta como una temporada.

## Fórmulas (`Simulador_Futbol`)

- **Condición física:** `clamp(0.45*SaludFísica + 0.35*Descanso + 0.20*Hambre, 0, 100)`.
- **Innata de fútbol:** `0.50*Habilidades[0] + 0.25*Habilidades[4] + 0.25*Habilidades[6]`.
- **Convocatoria:**
  - Bloqueo si lesionado, Salud Física < 30 o Relación < 25.
  - Índice: `0.55*Relación + 0.30*Condición + 0.15*Liderazgo`; convoca desde 45.
- **Puntuación normal:** `0.50*Deporte + 0.30*Condición + 0.20*Innata + variación`.
- **Puntuación decisiva:** `0.42*Deporte + 0.25*Condición + 0.13*Innata + 0.20*SangreFría + variación`.
- **Penaltis:** `prob = clamp(0.25 + 0.55*SangreFría/100 + 0.20*Deporte/100, 0.15, 0.90)`.
- **Playoff:** ganar como 1º/2º asciende; perder como 1º/2º mantiene; ganar como 3º/4º mantiene; perder como 3º/4º desciende, y en 3ª División supone el despido.
- **Modo Rápido:** victoria contra el umbral de la división asciende (o gana la Superliga); empate mantiene; derrota desciende (o despide en 3ª).
- **Lesión:** si Condición < 30 o Salud Física < 25, probabilidad del 25 % por partido de activar `Lesion_Deportiva` durante 24 h (techo de Salud Física 35 → 100).

Umbrales y economía:

| División | Umbral | Salario semanal | Prima victoria | Prima gol |
|---|---|---|---|---|
| 3ª División Regional | 45.0 | 150 € | 50 € | 15 € |
| 2ª División Nacional | 62.0 | 600 € | 200 € | 50 € |
| 1ª División Élite | 78.0 | 2500 € | 800 € | 150 € |
| Superliga Internacional | 90.0 | 10000 € | 3000 € | 500 € |

Las primas se multiplican por `Multiplicador_Precios()` (0.1 en Modo Rápido). El salario se cobra el domingo a las 23:59 en Modo Normal y todos los días a las 23:59 en Modo Rápido, también multiplicado.

## Entrenamientos y relación

- Asistir suma `+5` de relación si la condición al terminar es ≥ 70; si no, `+3`. Reinicia `Entrenamientos_Cancelados_Seguidos`.
- Faltar resta `-12` de relación, incrementa el contador y envía un mensaje.
- Si un trabajo ocupa la franja del entrenamiento (por ejemplo tras un descenso), el entrenamiento no borra el trabajo y se registra la falta.

## Conflictos fútbol ↔ trabajo

Los solapamientos se comprueban contra **entrenamientos y partidos**:

1. **Fichar por 3ª División** con un trabajo que solapa: el panel muestra “Seguir con el fútbol” (deja el empleo y firma) o “Mantener trabajo” (cancela el fichaje).
2. **Ascender** a una división cuyo entrenamiento solapa con el trabajo actual: se guarda un `Conflicto_Ascenso_Pendiente` y se muestra un modal. “Seguir con el fútbol” deja el empleo y confirma el ascenso; “Mantener trabajo” rechaza el ascenso y mantiene la división.
3. **Aceptar un empleo** con la carrera activa y horario solapado: “Dejar el fútbol y trabajar” rescinde el contrato y limpia sus bloques; “Seguir en el fútbol” cancela la contratación.

## UI

- Botón `Carrera futbolística` en `Actividades → Fijas`.
- `Panel_Futbol.tscn` cubre la pantalla con fondo opaco, cabecera con botón volver y `ScrollContainer` vertical.
- Se monta dentro de un `CanvasLayer` (`Capa_Panel_Futbol`, capa 60) creado en `Script_Principal`: un `Control` anclado directamente al `Node2D` raíz calcula su rectángulo contra un padre de tamaño cero y queda en 0×0 (solo se verían sus hijos posicionados en absoluto).
- **Sin club:** requisitos (`Deporte ≥ 25`, edad `< 30`) en verde/rojo, valores actuales y botón “Realizar prueba de fichaje”.
- **Con club:** división, salario (semanal o diario), estado de temporada, entrenamientos y partidos, barras de Deporte/Relación/Condición, estadísticas, tabla de la liga dominical (domingos en Modo Normal), toggles de asistencia y “Rescindir contrato” con confirmación.

## Persistencia y compatibilidad

- `Carrera_Futbol` se serializa con `duplicate(true)`.
- `_Normalizar_Carrera_Futbol()` completa claves ausentes, valida rangos y normaliza arrays de la liga.
- `Lesion_Deportiva` se añade a `Variables_Estaticas.Estados_Temporales` y, por tanto, pasa el filtro de `_Cargar_Estados_Temporales`.
- Al cargar un save sin la clave, la carrera queda inactiva y no se escribe nada en la matriz.

## Tests

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd \
  -gtest=res://Funcionalidades/Actividades/Futbol/Tests/test_futbol.gd -gexit
```

Cobertura: condición, innata, convocatoria, puntuación normal/decisiva, penaltis, liga, playoff, Modo Rápido, lesiones, calendario, normalización de saves, catálogo/prioridades, integración de fichaje + 3 jornadas/entrenamiento, Modo Rápido con ascenso, jerarquía P1/P2/P3, conflictos horarios e instanciación del panel.
