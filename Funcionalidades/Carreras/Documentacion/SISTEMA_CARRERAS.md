# Sistema de Carreras Universitarias - Documentación Completa

**Versión:** 1.1  
**Estado:** Implementado  
**Última actualización:** 10 de Junio de 2026  

---

## Tabla de Contenidos

1. [Visión General](#visión-general)
2. [Duración Total](#duración-total)
3. [Ciclo Semanal Completo](#ciclo-semanal-completo)
4. [Estados del Botón](#estados-del-botón)
5. [Flujos Detallados](#flujos-detallados)
6. [Timeline de Ejemplos](#timeline-de-ejemplos)
7. [Dinero y Matrícula](#dinero-y-matrícula)
8. [El Examen Real del Jugador](#el-examen-real-del-jugador)
9. [Reglas Clave](#reglas-clave)

---

## Visión General

El sistema de carreras universitarias es una **mecánica híbrida de 4 semanas reales** (= 4 años de juego) donde:

- El **personaje estudia automáticamente** progresando aleatoriamente
- El **personaje hace exámenes automáticos** a hora programada
- El **jugador real puede hacer exámenes** para sumar +10% bonus a la nota final
- **Matriculación y prematriculación** crean estructura y compromiso

**Objetivo final:** Completar 4 años de carrera en ~4 semanas reales de juego

---

## Duración Total

- **4 semanas reales = 4 años de juego**
- **1 semana real = 1 año académico**
- **4 exámenes total** (1 por semana)
- Una carrera se completa en ~1 mes real

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

**Al completar Año 4:**
```
Después de aprobar Año 4:
  → 🎓 CARRERA COMPLETADA
  → Bonus económico (a definir)
  → Se guarda en historial de carreras
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
AÑOS 1-3: Repites Flujo A/B/C

AÑO 4 - Examen final:
  Viernes 14:00 → APROBADO (≥50)
  
  RESULTADO: 🎓 CARRERA COMPLETADA
    ✅ No aparece "Prematricularse"
    ✅ Botón cambia a "Carrera Completada"
    ✅ Bonus económico guardado
    ✅ Entra en historial de carreras del perfil
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

Se define por año y carrera. **Ejemplo Ing. Informática:**

| Año | Temas |
|-----|-------|
| 1 | Bucles, If-Else, Variables |
| 2 | Arrays, Funciones, Scope |
| 3 | POO, Clases, Herencia |
| 4 | Patrones, Diseño, Buenas Prácticas |

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

1. **Más carreras:** Derecho, Medicina, Bellas Artes
2. **Matrícula de honor:** Nota ≥ 90 → descuento en matrícula del año siguiente
3. **Sangre Fría:** Reutilizar en otras mecánicas de estrés o presión
4. **Becas:** Sistema de descuentos por rendimiento
5. **Multiplicadores de objeto:** Escritorio premium → +% progreso de carrera

---

## Estructura de Datos (GDScript)

```gdscript
# Carrera.gd (class_name Carrera, extends Resource)
@export var nombre: String
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
| `Scripts/Logica/Escena_Principal/Actividades/Carreras/Carrera.gd` | Modelo de datos |
| `Scripts/Logica/Escena_Principal/Actividades/Carreras/Carrera_Ingenieria_Informatica.gd` | Carrera concreta |
| `Scripts/Logica/Escena_Principal/Actividades/Carreras/Sistema_Examenes.gd` | Autoload: cálculo de notas, progreso |
| `Scripts/Logica/Escena_Principal/Actividades/Actividades.gd` | Conversión Lunes 00:00, disparo examen automático |
| `Scripts/Globales/Script_Principal.gd` | Botón único, máquina de estados, modales |
| `Scripts/Logica/Escena_Principal/Actividades/Carreras/UI/Modal_Seleccionar_Examen.gd` | Elige día (solo Mi-V) y hora |
| `Scripts/Logica/Escena_Principal/Actividades/Carreras/UI/Modal_Examen.gd` | Test 10 preguntas |
| `Scripts/Logica/Escena_Principal/Actividades/Carreras/UI/Lector_Libros.gd` | Apuntes por año |
| `Scripts/Logica/Escena_Principal/Actividades/Carreras/Contenido/preguntas_ing_informatica.json` | Banco de preguntas |
| `Scripts/Logica/Escena_Principal/Actividades/Carreras/Contenido/apuntes_ing_informatica_anioN.txt` | Apuntes años 1-4 |
| `Scripts/Otro/Guardar/Guardar_Variables_Dinamicas.gd` | Serialización de Carrera_Actual y Carreras_Completadas |

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

**Implementación completada el 10 de Junio de 2026.**
