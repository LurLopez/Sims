# Progreso y Habilidades — Mecánica de descubrimiento

> Documento de referencia de la progresión del personaje.
> Implementación: `Scripts/Logica/Escena_Principal/Actividades/Actividades_Habilidades.gd`.

---

## Las dos métricas

### Progreso (volátil, visible siempre)

- **3 áreas:** Deporte, Académico y Manualidades en `Variables_Dinamicas.Progreso` (0–100).
- Sube al ejecutar actividades relacionadas, con una probabilidad que depende del talento innato y del nivel actual.
- **Baja con el desuso:** tras 5 días reales sin practicar un área, pierde 1 punto cada 3 días (en Modo Rápido, el umbral y el intervalo se escalan a 1/7).
- Es el nivel **actual**: «qué tan bueno soy ahora mismo».

### Habilidad mostrada (descubrimiento permanente)

- 7 habilidades en `Variables_Estaticas.Habilidades` (0–100): Deporte, Inteligencia, Destreza manual, Memoria, Liderazgo, Paciencia y Sangre Fría.
- El valor innato es secreto. `Variables_Dinamicas.Habilidades_Mostradas` empieza en 0 y se revela progresivamente.
- **Solo sube, nunca baja.** Al alcanzar el valor innato se detiene y se avisa al jugador.
- Es el **cap demostrado**: «lo más alto que he probado que puedo llegar».

---

## Cómo sube el Progreso

En `Actividades_Habilidades.Ejecutar_Actividad_Progreso_Array()` cada actividad reparte sus efectos entre las tres áreas. Para cada área con efecto:

```
sum_habilidades = combinación ponderada de habilidades innatas
max = Calcular_Max_Numero_Aleatorio(Progreso[área], sum_habilidades, 20)
max_ajustado = max / efecto_de_la_actividad
probabilidad = 1 / max_ajustado
```

Si la tirada sale bien, el área sube 1 punto. La probabilidad se mejora con:

- **Ropa** con bonus de progreso del área.
- **Muebles** de estudio, deporte o taller.
- **Maestría Culinaria** rango ≥ 5 (+15 % en Manualidades).

Por eso un talento alto progresa rápido y un talento bajo se estanca: el mismo esfuerzo rinde mucho menos.

### Combinaciones de habilidades

| Área | Habilidades y peso |
|---|---|
| **Deportivo** | 50·Deporte + 40·Liderazgo + 10·Memoria |
| **Académico** | 50·Inteligencia + 20·Paciencia + 30·Memoria |
| **Manualidades** | 50·Destreza + 30·Paciencia + 10·Memoria + 10·Liderazgo |

La cocina tiene su propia progresión (`Progreso_Cocina`, 1–100) con Destreza 40, Paciencia 25, Sangre Fría 20 y Memoria 15.

---

## Cómo se descubre la habilidad innata

`Ejecutar_Actividad_Mostrar_Habilidad_Array()` intenta incrementar `Habilidades_Mostradas` para cada habilidad implicada en la actividad. La probabilidad depende del efecto de la actividad y del peso de esa habilidad:

```
max = Calcular_Max_Numero_Aleatorio(Habilidades_Mostradas[i], 5000, 8)
max_ajustado = max · 100 / (efecto · peso)
probabilidad = 1 / max_ajustado
```

Cuando `Habilidades_Mostradas[i]` alcanza `Habilidades[i]`:

> «Has descubierto tu límite natural en Deporte: **27**. Tu talento innato no dará para más en esta habilidad, aunque puedes seguir subiendo tu Progreso con esfuerzo.»

El aviso se envía una sola vez por habilidad (`Habilidades_Cap_Notificado`). El cap no bloquea el Progreso: solo lo hace mucho más costoso. Eso permite pivotar sin sentir que se ha perdido el tiempo.

La cocina también descubre habilidades al cocinar: Destreza 40, Paciencia 25, Sangre Fría 20 y Memoria 15.

---

## Asimetría narrativa

| Talento innato | Revelación explícita | Pista implícita |
|---|---|---|
| Bajo (0–30) | Rápida: la habilidad llega al tope en pocas semanas. | El Progreso apenas sube. |
| Medio (30–70) | Moderada. | El Progreso sube con esfuerzo. |
| Alto (70–100) | Lenta: hace falta mucha práctica. | El Progreso sube rápido desde el primer día. |

**Los malos se enteran por el número. Los buenos se enteran por los resultados.**

Un futbolista profesional no necesita un test que le diga «tienes talento 92». Lo sabe porque gana partidos. Un mediocre lo descubre cuando se choca contra el techo.

---

## Decadencia del Progreso (implementada)

`Actividades_Habilidades.Comprobar_Decadencia_Progreso()` se ejecuta desde `Actividades.Actualizar_Horario()`:

- Si un área lleva **5 días reales** sin uso, empieza a decaer.
- Después baja **1 punto cada 3 días**.
- Nunca baja de 1.
- En Modo Rápido, ambos plazos se dividen entre 7.
- Solo afecta al Progreso. **No toca `Habilidades_Mostradas` ni el talento innato:** lo que has descubierto de ti mismo no se olvida; solo pierdes forma.

Los timestamps viven en `Variables_Dinamicas.Ultimo_Uso_Progreso` (3 áreas) y `Variables_Dinamicas.Ultimo_Check_Decadencia` (3 áreas).

---

## Pistas contextuales

Tras cada actividad, `Registrar_Pista_Contextual()` encola un mensaje breve según el resultado del Progreso:

- «Te ha costado bastante» → probablemente talento bajo.
- «Bien» → rendimiento normal.
- «Lo has bordado» → probablemente talento alto.

Da feedback temprano sin romper el descubrimiento explícito. Las pistas se guardan en `Variables_Dinamicas.Ultimas_Pistas_Progreso`.

---

## Para qué sirve cada métrica en el roadmap

- **Universidad:** el examen usa Progreso Académico, Inteligencia, Memoria y Sangre Fría.
- **Fútbol:** la convocatoria y el rendimiento usan Progreso de Deporte, condición física, Liderazgo y Sangre Fría.
- **Cocina:** la eficiencia usa Progreso de Manualidades y `Progreso_Cocina`; los rangos desbloquean ventajas.
- **Bolsa:** `Progreso_Inversion` es una progresión aparte, compartida entre la inversión pasiva y la futura sala de trading.

---

## Archivos clave

| Archivo | Responsabilidad |
|---|---|
| `Scripts/Logica/Escena_Principal/Actividades/Actividades_Habilidades.gd` | Fórmulas de Progreso, descubrimiento, decadencia y pistas. |
| `Scripts/Globales/Principales_Variables/Variables_Dinamicas.gd` | `Progreso`, `Habilidades_Mostradas`, `Ultimo_Uso_Progreso`, `Ultimo_Check_Decadencia`, `Habilidades_Cap_Notificado`, `Ultimas_Pistas_Progreso`. |
| `Scripts/Globales/Principales_Variables/Variables_Estaticas.gd` | `Habilidades` (7 valores innatos). |
| `Scripts/Logica/Escena_Principal/First_Time/First_Time.gd` | Generación de habilidades y valores iniciales. |
| `Scripts/Otro/Guardar/Guardar_Variables_Dinamicas.gd` | Persistencia de la progresión. |
