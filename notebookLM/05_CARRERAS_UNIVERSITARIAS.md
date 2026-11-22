# Sistema de Carreras Universitarias - Documentación Completa

**Versión:** 1.2  
**Estado:** Implementado (UI móvil rediseñada en nov 2026; ciclo/examen en Roadmap v3.0 Prioridad 1)  
**Última actualización:** 21 de Noviembre de 2026  

---

## Tabla de Contenidos

1. [Visión General](#visión-general)
2. [Interfaz de usuario](#interfaz-de-usuario)
3. [Duración Total](#duración-total)
4. [Ciclo Semanal Completo](#ciclo-semanal-completo)
5. [Estados del Botón](#estados-del-botón)
6. [Flujos Detallados](#flujos-detallados)
7. [Timeline de Ejemplos](#timeline-de-ejemplos)
8. [Dinero y Matrícula](#dinero-y-matrícula)
9. [El Examen Real del Jugador](#el-examen-real-del-jugador)
10. [Reglas Clave](#reglas-clave)
11. [Rediseño planificado en el Roadmap v3.0 (Prioridad 1)](#rediseño-planificado-en-el-roadmap-v30-prioridad-1)

---

## Visión General

El sistema de carreras universitarias es una **mecánica híbrida** (1 semana real = 1 año de juego) donde:

- El **personaje estudia automáticamente** progresando aleatoriamente
- El **personaje hace exámenes automáticos** a hora programada
- El **jugador real puede hacer exámenes** para sumar +10% bonus a la nota final
- **Matriculación y prematriculación** crean estructura y compromiso

**Carreras disponibles:** Ingeniería Informática, Derecho y Bellas Artes duran 4 años; **Medicina dura 5 años** (la única con duración distinta, para ser más difícil). Solo se puede cursar una carrera a la vez (`Variables_Dinamicas.Carrera_Actual`) y no se puede repetir una carrera que ya esté en `Carreras_Completadas`.

**Objetivo final:** Completar todos los años de la carrera elegida en ~N semanas reales de juego (N = `carrera.años_totales`)

---

## Interfaz de usuario

La pantalla de Carrera y todos sus modales se rediseñaron para móvil vertical (base `720×1280` con `aspect=expand`). Mantienen la identidad visual del juego —banda de cabecera, tarjetas blancas, Bricolage/DM Sans, iconos Lucide y animaciones de pulsación— y usan el color de cada titulación como acento.

| Pantalla | Qué incluye |
|---|---|
| **Carrera universitaria** | Tarjeta de expediente con icono y color de la carrera, estado, progreso del curso, línea temporal de años, acción contextual, acceso a apuntes, consejo de estudio y títulos obtenidos. Sin carrera activa muestra una guía de tres pasos. |
| **Elegir carrera** | Tarjetas táctiles con duración, coste anual, dificultad y estado de graduación. |
| **Programar examen** | Selector directo de día y hora en rejilla, resumen de matrícula/prematrícula, coste y aviso de saldo insuficiente. |
| **Apuntes** | Lector con pestañas de año fijas, temario maquetado por secciones, numeración, viñetas con negritas, tiempo de lectura y estado vacío. Sustituye el antiguo `AcceptDialog` con `TextEdit`. |
| **Test del jugador** | Preguntas en tarjetas, opciones A–D táctiles con estado seleccionado, progreso fijo, aviso de respuestas pendientes, confirmación al salir y resultado con anillo de nota y bonus. |
| **Resultado oficial** | Ficha de expediente con estado, nota final, test del jugador, recompensa de graduación y cierre seguro. Sustituye el `AcceptDialog` de texto. |

La base común `Modal_Carrera_Base.gd` construye el velo, la tarjeta a pantalla casi completa, la cabecera, el área de contenido desplazable y el pie de acciones fijo. Los modales son `CanvasLayer`; `popup_centered()` se conserva como no-op para no romper las llamadas antiguas de `Script_Principal.gd`.

Capturas de QA generadas con `Escenas/Herramientas/Captura_Carreras.tscn` (`Funcionalidades/Carreras/Documentacion/Capturas/`). Tests de humo de la UI: `Funcionalidades/Carreras/Tests/test_ui_carreras.gd`.

---

## Duración Total

- **1 semana real = 1 año académico**, para cualquier carrera
- **`carrera.años_totales` exámenes en total** (1 por semana): 4 para Ingeniería Informática/Derecho/Bellas Artes, **5 para Medicina**
- Una carrera se completa en ~1 mes real (~5 semanas en el caso de Medicina)

---

## Ciclo Semanal Completo

### Fase 1: PREMATRICULACIÓN (Después del examen anterior)

**Cuándo está disponible:**
- Si hiciste examen **Miércoles**: Ju-Do de esa semana (cool-down 2 días)
- Si hiciste examen **Jueves**: V-Do de esa semana (cool-down 2 días)
- Si hiciste examen **Viernes**: V-Do de esa semana (cool-down 2 días)

**Qué hace:**
- Aparece **inmediatamente después del examen** (mismo día, después de la hora)
- Eliges fecha/hora para la **siguiente semana** (Mi-Do)
- **Dinero NO se quita**
- **PUEDES cambiar/cancelar sin costo**
- Al **Lunes 00:00** se convierte automáticamente en matriculación

**Ejemplo:**
```
Viernes 14:00: Haces examen (aprobado o suspenso)
Viernes tarde: Botón "Prematricularse"
               → Eliges "Jueves semana que viene a las 15:00"

Sábado: Te das cuenta que es muy justo
        Cambias a "Viernes a las 16:00" (sin dinero)

Domingo 23:59: Todavía puedes cambiar

Lunes 00:00: ⚙️ AUTOMÁTICO
            → Se ejecuta como matriculación
            → Se quitan 500€
            → Ya NO puedes cambiar
```

---

### Fase 2: MATRICULACIÓN (Lunes-Martes)

**Cuándo está disponible:**
- Si NO estás prematriculado: **Lunes-Martes**
- Si ya estás prematriculado: No aparece este botón

**Qué hace:**
- Eliges fecha/hora para **ESTA semana** (Mi-Do)
- **Se quitan 500€ INMEDIATAMENTE**
- **NO puedes cambiar después**
- El examen está bloqueado

**Importante:** 
- Si haces examen **Lunes**, tu siguiente matriculación/prematriculación es **Miércoles en adelante**
- Esto da un "cool-down" de 2 días después de exámenes lunes

**Ejemplo:**
```
Lunes 10:00: Presionas "Matricularse"
             → Eliges "Viernes a las 14:00"
             → Se quitan 500€ INMEDIATAMENTE
             → Bloqueado, no puedes cambiar
```

---

### Fase 3: EXAMEN (Hora programada)

**Automático:** A la hora exacta que programaste, el personaje **automáticamente hace el examen**

**El jugador real tiene opción de:**
- Hacer el examen real (test con preguntas) → +10% bonus
- No hacer nada → El personaje hace el examen sin bonus

**Timeline exacta:**
```
Ejemplo: Examen programado "Viernes 14:00"

Viernes 14:00:00
  → Examen del personaje se ejecuta automáticamente
  → Se calcula nota del personaje (probabilística)

Viernes 14:00:01 - 14:59:59
  → Botón cambia a "Hacer Examen"
  → El jugador real puede hacer el examen (si está jugando)
  → Obtiene 0-100 puntos
  → Suma 10% a la nota final del personaje

Viernes 15:00:00
  → Botón cambia a "Ver Resultado"
  → Se muestra: APROBADO (≥50) o SUSPENSO (<50)
```

**¿Qué pasa si entras DESPUÉS del horario?**
- El examen ya se ejecutó automáticamente
- Ves el resultado
- NO puedes hacer el examen real (ya pasó la ventana de 1 hora)

---

### Fase 4: RESULTADO Y SIGUIENTE PASO

**Si APROBASTE:**
```
Inmediatamente después del examen:
  → Botón "Prematricularse" disponible
  → Siempre que estés dentro de la ventana de tiempo
```

**Si SUSPENDISTE:**
```
Inmediatamente después del examen:
  → Botón "Prematricularse" disponible (para reintentar el mismo año)
  → Igual funcionalidad que aprobado
  → Dinero: 500€ de nuevo para reintentar
```

**Al completar el último año (Año 4, o Año 5 en Medicina):**
```
Después de aprobar el último año:
  → 🎓 CARRERA COMPLETADA
  → Bonus económico: +2000€ (Sistema_Examenes.BONUS_DINERO_CARRERA_COMPLETADA)
  → Se guarda en Carreras_Completadas (historial de carreras)
  → Aparece un diploma/certificado en la pestaña Apuntes del Perfil
  → Se desbloquea el trabajo de nómina asociado a esa carrera (ver tabla más abajo)
```

---

## Estados del Botón

Un **único botón** cambia de estado/texto según la situación:

| Estado | Texto | Acción | Dinero |
|--------|-------|--------|--------|
| **Prematriculación abierta** | `"Prematricularse"` | Eliges fecha próx semana | ❌ No se quita |
| **Matriculación abierta** (L-Ma) | `"Matricularse"` | Eliges fecha esta semana | ✅ Se quita (500€) |
| **Esperando examen** | `"Examen: Viernes 14:00"` | Botón desactivado (info) | ❌ Ya quitado |
| **Hora del examen** | `"Hacer Examen"` | Abres test real | ❌ Ya quitado |
| **Después del examen** | `"Ver Resultado"` | Ves aprobado/suspenso | ❌ Ya quitado |
| **Carrera completada** | `"Carrera Completada 🎓"` | Ver certificado | ❌ Sin acción |
| **Sin carrera** | `"Matricularse Carrera"` | Menú de carreras | ❌ No se quita |

---

## Flujos Detallados

### Flujo A: PREMATRICULACIÓN → MATRICULACIÓN AUTOMÁTICA

```
PASO 1: Haces el examen (cualquier día)
        └─ Jueves 14:00 examen

PASO 2: Aparece botón "Prematricularse"
        └─ Presionas → Eliges "Viernes semana siguiente a las 15:00"
        └─ Dinero: NO se quita
        └─ Estado: FLEXIBLE (puedes cambiar)

PASO 3: Cambio automático Domingo 23:59 → Lunes 00:00
        └─ Se ejecuta automáticamente
        └─ Es como si presionaras "Matricularse" en el lunes
        └─ Dinero: Se quitan 500€
        └─ Estado: BLOQUEADO (no puedes cambiar)

PASO 4: Esperas hasta el viernes programado
        └─ Botón muestra: "Examen: Viernes 15:00"
        └─ Desactivado (info)

PASO 5: Viernes 15:00 - Examen automático + opcional del jugador
        └─ Botón: "Hacer Examen" (1 hora)
        └─ Resultado: Aprobado/Suspenso

PASO 6: Vuelve a aparecer "Prematricularse" o "Matricularse"
        └─ Comienza nuevo ciclo
```

---

### Flujo B: ESPERAR MATRICULACIÓN (Sin prematricularse)

```
PASO 1: Haces el examen (Lunes)
        └─ Lunes 14:00 examen

PASO 2: NO presionas "Prematricularse"
        └─ Ignoras el botón

PASO 3: Esperas hasta Lunes-Martes siguiente
        └─ Botón cambia a "Matricularse"
        └─ Presionas → Eliges "Viernes a las 16:00"
        └─ Dinero: Se quita INMEDIATAMENTE (500€)
        └─ Estado: BLOQUEADO

PASO 4: Esperas hasta el viernes
        └─ Botón: "Examen: Viernes 16:00"

PASO 5: Viernes 16:00 - Examen
        └─ Automático + opcional del jugador
        └─ Resultado: Aprobado/Suspenso
```

**Resultado:** Idéntico al Flujo A, pero sin flexibilidad

---

### Flujo C: SUSPENSIÓN Y REINTENTO

```
PASO 1: Haces el examen
        └─ Viernes 14:00 → SUSPENDIDO (<50)

PASO 2: Botón "Prematricularse" disponible
        └─ Exactamente igual que si hubieras aprobado
        └─ Eliges fecha para reintentar
        └─ Dinero: Se quita nuevamente (500€)

PASO 3: Segunda semana
        └─ Botón: "Examen: [Fecha que elegiste]"
        └─ Automático + opcional

PASO 4: Resultado
        └─ Si apruebas: ✅ Avanzan al siguiente año
        └─ Si suspendes de nuevo: Puedes reintentar indefinidamente
```

**Nota:** No hay límite de intentos. Puedes reintentar infinitas veces.

---

### Flujo D: COMPLETAR LA CARRERA

```
AÑOS 1 a (años_totales - 1): Repites Flujo A/B/C

ÚLTIMO AÑO - Examen final (Año 4, o Año 5 en Medicina):
  Viernes 14:00 → APROBADO (≥50)
  
  RESULTADO: 🎓 CARRERA COMPLETADA
    ✅ No aparece "Prematricularse"
    ✅ Botón cambia a "Carrera Completada"
    ✅ Bonus económico +2000€ guardado
    ✅ Entra en Carreras_Completadas (historial de carreras del perfil)
    ✅ Aparece un diploma/certificado en la pestaña Apuntes del Perfil
    ✅ Se desbloquea el trabajo de nómina de esa carrera
    ✅ Variables_Dinamicas.Carrera_Actual = null
```

---

## Timeline de Ejemplos

### Ejemplo 1: Flujo IDEAL (Sin cambios)

```
SEMANA 1 (Lunes-Domingo)
  Lunes 10:00: Presionas "Matricularse"
               → Eliges "Viernes a las 14:00"
               → Se quitan 500€
               
  Viernes 14:00: Examen automático
                 (Personaje progreso: 60, nota: 55)
                 
  Viernes 14:30: Presionas "Hacer Examen"
                 (Respondes 10 preguntas, sacas 80)
                 
  Resultado: nota_final = 55 + 8 = 63 ✅ APROBADO

SEMANA 2 (Lunes-Domingo)
  Domingo anterior (semana 1): Botón "Prematricularse" apareció viernes tarde
                               Presionas: "Jueves a las 15:00"
                               Sin dinero aún
  
  Lunes 00:00: Automáticamente se matricula
               Se quitan 500€
               Bloqueado
               
  Jueves 15:00: Examen automático
                (Personaje: 65, nota: 68)
                
  Jueves 15:15: Presionas "Hacer Examen"
                (Sacas 75)
                
  Resultado: 68 + 7.5 = 75.5 ✅ APROBADO

SEMANA 3-4: Igual...

SEMANA 4 - AÑO 4:
  Viernes 14:00: Examen final automático
  Resultado: APROBADO
  
  🎓 CARRERA COMPLETADA
```

---

### Ejemplo 2: Cambio de idea (Prematriculación flexible)

```
SEMANA 1
  Viernes 14:00: Examen → APROBADO
  
  Viernes 15:00: Presionas "Prematricularse"
                 → Eliges "Martes semana siguiente a las 10:00"
                 → Sin dinero
  
  Sábado: Te das cuenta que es muy poco tiempo
          Presionas el botón de nuevo
          → Cambias a "Jueves a las 14:00"
          → Sin dinero (aún está en prematriculación)
  
  Domingo 15:00: Repientes otra vez
                 → Cambias a "Viernes a las 16:00"
                 → Sin dinero
  
  Lunes 00:00: ⚙️ AUTOMÁTICO
               Prematriculación → Matriculación
               Se quitan 500€
               Bloqueado en "Viernes 16:00"
               
  Viernes 16:00: Examen automático
                 (Tenías tiempo de sobra para estudiar)
                 Nota alta: ✅ APROBADO
```

---

### Ejemplo 3: Sin prematricularse (castigo suave)

```
SEMANA 1
  Viernes 14:00: Examen → APROBADO
  
  Viernes-Domingo: Botón "Prematricularse" visible
  
  ❌ NO presionas nada (olvidas)

SEMANA 2
  Lunes 00:00: Botón automáticamente no cambió
               (No había prematriculación, sigue esperando)
  
  Lunes 10:00: Presionas "Matricularse"
               → Eliges "Viernes a las 14:00"
               → Se quitan 500€ INMEDIATAMENTE
               → Bloqueado
               
  Viernes 14:00: Examen automático
                 (Sin tiempo de preparación si no estudiaste)
                 
  Resultado: Más riesgo de suspender
```

---

### Ejemplo 4: Suspensión y reintento

```
SEMANA 1
  Viernes 14:00: Examen → SUSPENDIDO (35)
  
  Viernes 15:00: Botón "Prematricularse"
                 → Eliges "Viernes siguiente a las 10:00"
                 → Sin dinero (intenta estudiar más)
  
  Lunes siguiente 00:00: Se matricula automáticamente
                         Se quitan 500€
  
  Viernes 10:00: Reintento de examen
                 → APROBADO (52)
                 → Avanzan al siguiente año ✅
```

---

## Dinero y Matrícula

### Coste de Matriculación

| Acción | Coste | Cuándo |
|--------|-------|--------|
| Prematricularse | 0€ | Inmediato (pero flexible) |
| Matricularse (L-Ma) | 500€ | Inmediato (bloqueado) |
| Matriculación automática (Lunes 00:00) | 500€ | Lunes medianoche (bloqueado) |
| Reintento (después de suspenso) | 500€ | Al prematricularse/matricularse |

### Total por Carrera

```
4 años × 500€ = 2000€ MÍNIMO
(Sin suspensiones)

Con suspensiones:
  1 suspensión = +500€
  2 suspensiones = +1000€
  etc.
```

---

## El Examen Real del Jugador

### ¿Qué es?

Un **test con 10 preguntas de opción múltiple** (4 opciones) sobre los contenidos de la carrera y año actual.

### ¿Cuándo se realiza?

- **Una única hora:** Desde que el examen automático se ejecuta hasta 60 minutos después
- **Ejemplo:** Si examen automático es Viernes 14:00, tienes hasta Viernes 15:00 para hacer el test
- **Si no juegas en esa hora:** Pierdes la oportunidad, pero el personaje igual hizo el examen (sin tu bonus)

### ¿Qué valor tiene?

```
Nota real = (preguntas_correctas / 10) × 100

Ejemplo: 8 preguntas correctas = 80 puntos

Suma a nota final:
  nota_final = nota_personaje + (nota_real × 0.1)
  
Ejemplo:
  Personaje: 55
  Jugador: 80
  Final: 55 + 8 = 63 ✅ APROBADO
```

### Contenido

Se define por año y carrera, a partir de `carrera.slug_contenido` (`"ing_informatica"`, `"derecho"`, `"medicina"`, `"bellas_artes"`). Las rutas de apuntes y preguntas se construyen genéricamente:
`.../Contenido/apuntes_<slug_contenido>_anio<N>.txt` y `.../Contenido/preguntas_<slug_contenido>.json`.

| Carrera | Años | Temas por año |
|---|---|---|
| Ingeniería Informática | 4 | 1: Variables/If-Else/Bucles · 2: Arrays/Funciones/Scope · 3: POO/Clases/Herencia · 4: Patrones/Diseño/Buenas Prácticas |
| Derecho | 4 | 1: Fundamentos del Derecho · 2: Derecho Civil · 3: Derecho Penal · 4: Derecho Procesal y Deontología |
| Medicina | **5** | 1: Anatomía y Fisiología · 2: Patología General · 3: Diagnóstico Clínico · 4: Farmacología · 5: Ética Médica y Práctica Clínica |
| Bellas Artes | 4 | 1: Color y Dibujo · 2: Técnicas de Pintura · 3: Historia del Arte · 4: Composición y Crítica de Arte |

---

## Reglas Clave

### 1. Ciclo Semanal

- Cada semana real = 1 año de carrera (4 años total)
- El lunes es el "cutoff" para cambiar entre estados

### 2. Ventanas de Tiempo

| Situación | Ventana |
|-----------|---------|
| Prematriculación después de examen Miércoles | Mi tarde - Do semana actual |
| Prematriculación después de examen Jueves | Ju tarde - Do semana actual |
| Prematriculación después de examen Viernes | V tarde - Do semana actual |
| Matriculación si no estás prematriculado | L-Ma siguiente |
| Examen real disponible | 1 hora desde automático |
| Cambiar fecha prematriculada | Hasta Lunes 00:00 |

### 3. Restricción: Exámenes solo Miércoles-Viernes

**Los exámenes SIEMPRE son Miércoles, Jueves o Viernes:**
- Nunca pueden ser Lunes o Martes
- Los L-Ma son siempre para matriculación/descanso
- Esto crea estructura natural: exámenes en Mi-V, preparación en L-Ma siguiente
- Cuando presionas "Prematricularse" después del examen, solo puedes elegir Mi-V para la próxima semana

### 4. Bloqueos

| Evento | Qué se bloquea |
|--------|---|
| Presionas "Matricularse" (L-Ma) | Fecha del examen (no puedes cambiar) |
| Lunes 00:00 de prematriculación | Fecha del examen (no puedes cambiar) |
| Hora del examen llega | Todo (solo puedes hacer examen o ver resultado) |

### 5. Sin límite de intentos

- Si suspendes, puedes reintentar indefinidamente
- Cada intento cuesta 500€
- No hay "expulsión" de la carrera

### 6. Carrera única activa

- Solo puedes estar matriculado en 1 carrera a la vez
- Variables_Dinamicas.Carrera_Actual = referencia a la carrera actual o null

---

## Fórmula de Nota

```
valor_esperado = (progreso × 0.60) + (habilidades_academicas × 0.20) + (necesidades_examen × 0.20)

habilidades_academicas = (Inteligencia[1] × 0.35) + (Memoria[3] × 0.15) + (Sangre_Fría[6] × 0.50)
necesidades_examen     = (Descanso[3]    × 0.40) + (Salud_Mental[1] × 0.40) + (Hambre[2] × 0.20)

nota_personaje = distribucion_normal(media=valor_esperado, σ=50)  → clamp [0, 100]
nota_final     = nota_personaje + (nota_jugador × 0.1)            → clamp [0, 100]
aprobado       = nota_final ≥ 50
```

**Sangre Fría** — `Variables_Estaticas.Habilidades[6]`, rango 1–100, peso 50% en habilidades académicas.
Es la habilidad de mayor peso en el examen. Representa compostura bajo presión.

### Probabilidades de referencia

| Perfil | Valor Esperado | Prob. Aprobar (≥50) | Prob. Nota Alta (≥70) |
|---|---|---|---|
| Excelente (todo al máximo) | 90 | ~99.9% | ~84% |
| Promedio | 58.55 | ~68% | ~25% |
| Inteligente pero nervioso | 61.41 | ~68% | ~15% |
| Mal preparado | 33.05 | ~15% | ~2% |
| Cansado pero inteligente | 64.65 | ~68% | ~27% |
| Sin esperanza | 23.45 | ~2% | ~0.5% |

---

## Expansión Futura

1. ~~Más carreras: Derecho, Medicina, Bellas Artes~~ — **implementado**, ver [PLAN_EXPANSION_CARRERAS.md](PLAN_EXPANSION_CARRERAS.md).
2. **Matrícula de honor:** Nota ≥ 90 → descuento en matrícula del año siguiente
3. **Sangre Fría:** Reutilizar en otras mecánicas de estrés o presión
4. **Becas:** Sistema de descuentos por rendimiento
5. **Multiplicadores de objeto:** Escritorio premium → +% progreso de carrera
6. **Dificultad por carrera:** de momento solo Medicina varía (5 años en vez de 4); ajustar coste de matrícula o fórmula de nota por carrera queda pendiente.

---

## Estructura de Datos (GDScript)

```gdscript
# Carrera.gd (class_name Carrera, extends Resource)
@export var nombre: String
@export var slug_contenido: String = ""   # "ing_informatica" | "derecho" | "medicina" | "bellas_artes"
@export var emoji: String = "📘"          # icono en miniatura de Inventario, portada de libro y diploma
@export var años_totales: int = 4
@export var costo_matricula_anual: float = 500.0
@export var año_actual: int = 1
@export var progreso_actual: float = 0.0
@export var historial_notas: Array = []        # Array[{año, nota_final, aprobado, ...}]
@export var num_intentos: int = 0
@export var dinero_matricula_gastado: float = 0.0
@export var examen_realizado_esta_semana: bool = false
@export var nota_real_ultima: int = 0          # nota del jugador (0-100)
@export var libros_desbloqueados: Array = []   # ["Anio_1", "Anio_2", ...]
@export var completada: bool = false

# Horario del examen
@export var hora_examen_dia: int = -1          # 0-6 (Lun-Dom), -1 = sin definir
@export var hora_examen_inicio: int = 0        # minutos desde medianoche

# Estado de matriculación
@export var prematriculado: bool = false       # fecha elegida, gratis, cancelable hasta Lunes 00:00
@export var matriculado: bool = false          # 500€ cobrados, bloqueado

# Control de procesado de examen
@export var fin_de_semana_procesado: bool = false  # true = resultado pendiente de ver
@export var ultima_nota_final: float = 0.0
@export var ultimo_resultado_aprobado: bool = false

# Variables_Dinamicas (globales)
var Carrera_Actual: Carrera = null
var Carreras_Completadas: Array = []           # historial de carreras terminadas
var Inicio_Semana_Carrera: int = -1            # minuto absoluto (legacy, no crítico)
```

---

## Archivos de Implementación

| Archivo | Responsabilidad |
|---|---|
| `Scripts/Logica/Escena_Principal/Actividades/Carreras/Carrera.gd` | Modelo de datos (incluye `slug_contenido` y `emoji`) |
| `Scripts/Logica/Escena_Principal/Actividades/Carreras/Carrera_Ingenieria_Informatica.gd` | Carrera concreta (4 años) |
| `Scripts/Logica/Escena_Principal/Actividades/Carreras/Carrera_Derecho.gd` | Carrera concreta (4 años) |
| `Scripts/Logica/Escena_Principal/Actividades/Carreras/Carrera_Medicina.gd` | Carrera concreta (**5 años**) |
| `Scripts/Logica/Escena_Principal/Actividades/Carreras/Carrera_Bellas_Artes.gd` | Carrera concreta (4 años) |
| `Scripts/Logica/Escena_Principal/Actividades/Carreras/Sistema_Examenes.gd` | Autoload: cálculo de notas, progreso |
| `Scripts/Logica/Escena_Principal/Actividades/Actividades.gd` | Conversión Lunes 00:00, disparo examen automático |
| `Scripts/Globales/Script_Principal.gd` | Pantalla Carrera, botón único, máquina de estados y apertura de modales |
| `Scripts/Logica/Escena_Principal/Actividades/Carreras/UI/Modal_Carrera_Base.gd` | Base visual común: velo, tarjeta, cabecera, scroll, pie, confirmaciones |
| `Scripts/Logica/Escena_Principal/Actividades/Carreras/UI/Anillo_Nota.gd` | Anillo animado de nota para las pantallas de resultado |
| `Scripts/Logica/Escena_Principal/Actividades/Carreras/UI/Modal_Seleccionar_Carrera.gd` | Selector de carrera con tarjetas, coste, dificultad y graduaciones |
| `Scripts/Logica/Escena_Principal/Actividades/Carreras/UI/Modal_Seleccionar_Examen.gd` | Elige día (Mi-V) y hora con selector directo |
| `Scripts/Logica/Escena_Principal/Actividades/Carreras/UI/Modal_Examen.gd` | Test de 10 preguntas con opciones táctiles y resultado del test |
| `Scripts/Logica/Escena_Principal/Actividades/Carreras/UI/Modal_Resultado_Examen.gd` | Ficha del resultado oficial del examen automático |
| `Scripts/Logica/Escena_Principal/Actividades/Carreras/UI/Lector_Libros.gd` | Lector de apuntes por año con temario maquetado |
| `Scripts/GUI/Escena_Principal/Lector_Libro.gd` | Lector tipo libro de la pestaña Inventario; también renderiza la página `"diploma"` |
| `Scripts/Logica/Escena_Principal/Actividades/Carreras/Contenido/preguntas_<slug>.json` | Banco de preguntas por carrera (`ing_informatica`, `derecho`, `medicina`, `bellas_artes`) |
| `Scripts/Logica/Escena_Principal/Actividades/Carreras/Contenido/apuntes_<slug>_anioN.txt` | Apuntes por año y carrera |
| `Funcionalidades/Carreras/Tests/test_ui_carreras.gd` | Pruebas GUT de humo de los modales (señales, respuestas y apuntes) |
| `Scripts/Otro/Herramientas/Captura_Carreras.gd` | QA visual de todos los estados y modales de Carreras |
| `Scripts/Otro/Guardar/Guardar_Variables_Dinamicas.gd` | Serialización de Carrera_Actual y Carreras_Completadas (reconstruye por `script_path`, sin cambios) |

---

## Guardado y Persistencia

- `Carrera_Actual` se serializa como Dictionary en `Guardar_Variables_Dinamicas.gd` → `_Carrera_A_Dict` / `_Dict_A_Carrera`
- Incluye fallback `false` para `prematriculado` y `matriculado` en saves antiguos
- `historial_notas` se guarda como `Array[Dictionary]`
- `Carreras_Completadas` se serializa como array de dictionaries

---

## Notas de Implementación

- La conversión prematrícula → matrícula ocurre en `Actividades.Actualizar_Horario()` cuando `Minute_Day % 7 == 0 and Minute_Minute == 0` (Lunes 00:00)
- El examen automático dispara en `Actualizar_Horario()` cuando `dia_semana == hora_examen_dia and Minute_Minute >= hora_examen_inicio + 60 and matriculado and not fin_de_semana_procesado`
- El botón se actualiza en cada frame desde `Actualizar_Dinero()` → `_Actualizar_Botones_Carrera()`
- "Ver Resultado" limpia `fin_de_semana_procesado` y `hora_examen_dia`; si `completada`, mueve la carrera a `Carreras_Completadas` y pone `Carrera_Actual = null`
- `Sistema_Examenes` es autoload registrado en `project.godot`

---

## Rediseño planificado en el Roadmap v3.0 (Prioridad 1)

> **Estado:** Pendiente de implementación (ver `01_ROADMAP_Y_PROGRESO.md` §3.1). Es el **primer foco** de trabajo para discutir y cerrar detalles antes de programar.

- **Problemas detectados en el sistema actual:** doble paso prematrícula/matrícula con reglas ocultas; examen automático donde el test del jugador solo suma +10 %; ventana de 1 hora que castiga al jugador móvil; estudio genérico sin clases; banco corto de 10 preguntas por año; nota opaca y recompensa plana de 2.000 €.
- **Diseño objetivo (MVP):**
  1. **Matrícula única** (sin prematrícula ni conversión del lunes).
  2. **Clases + estudio:** nueva actividad «Asistir a clase» (2 bloques/semana, 90 min) que sube progreso y desbloquea pistas de apuntes.
  3. **Examen pendiente todo el día (00:00–23:59):** el jugador puede hacerlo a cualquier hora de ese día; si no, a las 23:59 se resuelve automáticamente con penalización.
  4. **Test (60 %) + Caso práctico por carrera (40 %):** 10 preguntas cronometradas (25 s) + caso propio de Ingeniería/Derecho/Medicina/Bellas Artes.
  5. **Nueva fórmula de nota:** `40 % progreso + 50 % examen + 10 % estado`, con bonus por tramo (Notable ≥ 70, Matrícula de Honor ≥ 85) y banco ampliado a 30–40 preguntas por año.
  6. **Compatibilidad:** migración explícita para saves antiguos con prematrícula/matriculado.

**Implementación base del 10 de Junio de 2026; UI móvil rediseñada el 21 de Noviembre de 2026.**
