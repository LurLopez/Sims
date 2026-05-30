# Sistema de Carreras Universitarias - Referencia Rápida para IA

## Resumen Ejecutivo
Sistema híbrido donde el personaje estudia una carrera de 4 años (4 semanas reales) con exámenes semanales. El jugador real realiza exámenes tipo test que suman a la nota final del personaje. Mecánica probabilística basada en Progreso (60%), Habilidades Académicas (20%) y Necesidades Básicas (20%).

---

## Fórmula Central

```
valor_esperado = (progreso × 0.60) + (habilidades_academicas × 0.20) + (necesidades_examen × 0.20)

donde:
  habilidades_academicas = (Inteligencia × 0.35) + (Memoria × 0.15) + (Sangre_Fría × 0.50)
  necesidades_examen = (Descanso × 0.40) + (Salud_Mental × 0.40) + (Hambre × 0.20)

nota_examen_personaje = valor_esperado ± desviación_normal(σ=50, máx ±100)

nota_final = (nota_examen_personaje × 1.0) + (nota_jugador × 0.1)
aprobacion = nota_final ≥ 50
```

---

## Decisiones de Diseño

### 1. Cuándo se realiza el examen real
- **Voluntario:** Jugador elige cuándo durante la semana
- **Un intento por semana:** Bloqueado después de realizarlo
- **Si no se presenta:** 0 puntos automáticamente

### 2. Dónde aparece el botón
- **Barra inferior** (como botón de Alquiler)
- **Nombre:** "Examen de [Carrera] - [Año] de [4]"
- **Solo visible si:** `Carrera_Actual != null`
- **Al pulsar:** Modal con 10 preguntas tipo test

### 3. Qué pasa al aprobar un año
- **Automático al final de semana:** Calcula nota_final
- **Si aprobado (≥50):** año_actual += 1, desbloquea libro siguiente
- **Si suspendido (<50):** Mismo año siguiente semana, puede reintentar

### 4. Integración con "Estudiar Carrera X"
- **Actividad especial:** `Actividad_Carrera` (extends `Actividad_Temporal`)
- **Efecto:** Suma progreso a `Carrera_Actual.progreso_actual` (no a `Progreso[1]`)
- **Otras actividades de "Estudiar":** NO suman a carrera

### 5. Costo de matrícula
- **Cuándo:** Cada año (años 1-4)
- **Cantidad:** 500€/año
- **Si no tiene dinero:** No puede matricularse/continuar

### 6. Guardar y estructura
- **Herencia:** `Carrera` (base) → `Carrera_Ingenieria_Informatica`
- **En Variables_Dinamicas:** `Carrera_Actual: Carrera` (null si no estudia)
- **Campos por instancia:**
  - `año_actual: int`
  - `progreso_actual: float`
  - `historial_notas: Array` (nota por año)
  - `num_intentos: int`
  - `dinero_matricula: float`
  - `examen_realizado_esta_semana: bool`
  - `nota_real_ultima: int`

### 7. Sangre Fría
- **De momento:** Solo exámenes (peso 50%)
- **Futura expansión:** Otras mecánicas de presión
- **Nueva habilidad:** `Variables_Estaticas.Habilidades[6]`

---

## Estructura de Clases

### Carrera (Resource)
```gdscript
@export var nombre: String  # "Ingeniería Informática"
@export var años_totales: int = 4
@export var costo_matricula_anual: float = 500.0

var año_actual: int = 1
var progreso_actual: float = 0.0
var historial_notas: Array = []  # Array de notas finales
var num_intentos: int = 0
var dinero_matricula_gastado: float = 0.0
var examen_realizado_esta_semana: bool = false
var nota_real_ultima: int = 0
```

### Carrera_Ingenieria_Informatica (extends Carrera)
```gdscript
# Particularidades de esta carrera
var libros_desbloqueados: Array = ["Año 1"]
var contenido_preguntas: Dictionary  # Preguntas por año
```

---

## Flujo de Ejecución

### 1. Matricularse (Primer año)
1. Jugador selecciona "Estudiar Carrera"
2. Selecciona "Ingeniería Informática"
3. Sistema resta 500€ de `Variables_Dinamicas.Dinero`
4. Crea instancia: `Variables_Dinamicas.Carrera_Actual = Carrera_Ingenieria_Informatica.new()`
5. Desbloquea libro año 1
6. Guarda

### 2. Durante la semana (Estudio)
1. Actividad "Estudiar Ingeniería Informática - Año 1" disponible
2. Cada uso suma progreso aleatorio a `Carrera_Actual.progreso_actual`
3. Botón "Examen..." visible en barra inferior
4. Opción para leer libro del año actual

### 3. Realizar examen (Jugador real)
1. Jugador toca botón "Examen..."
2. Modal abre con 10 preguntas del año actual
3. Jugador responde todas
4. Sistema calcula: `nota_real = (correctas / 10) * 100`
5. Guarda en `Carrera_Actual.nota_real_ultima`
6. Marca `Carrera_Actual.examen_realizado_esta_semana = true`
7. Bloquea botón para esa semana

### 4. Fin de semana (Cálculo automático)
1. `Actividades.Actualizar_Horario()` termina la semana
2. Sistema calcula:
   ```
   valor_esperado = (progreso × 0.60) + (hab_acad × 0.20) + (nec × 0.20)
   nota_examen = distribucion_normal(valor_esperado, σ=50)
   nota_final = (nota_examen × 1.0) + (nota_real × 0.1)
   ```
3. Si `nota_final >= 50`:
   - Aprobado ✅
   - `año_actual += 1`
   - Si `año_actual <= 4`: Desbloquea libro siguiente
   - Si `año_actual > 4`: Carrera completada 🎓
4. Si `nota_final < 50`:
   - Suspendido ❌
   - Mismo año, siguiente semana
   - `num_intentos += 1`
5. Guarda en `historial_notas` y borra `progreso_actual` para nuevo año

### 5. Si no realiza examen
1. `nota_real = 0`
2. Mismo cálculo de nota_final
3. Muy probable suspender (sin el +10% del jugador real)

---

## Integración con Sistemas Existentes

### Variables_Dinamicas (nuevos campos)
```gdscript
Carrera_Actual: Carrera = null
Carreras_Completadas: Array = []  # Histórico de carreras terminadas
```

### Actividades.gd (modificaciones)
- Integrar `Actividad_Carrera` en la lista de actividades disponibles
- En `Actualizar_Horario()`, al final de semana, llamar `Sistema_Examenes.Calcular_Nota_Final()`

### Guardar_Variables_Dinamicas.gd
- Al guardar: convertir `Carrera_Actual` a diccionario serializable
- Al cargar: reconstruir instancia de carrera

### GUI
- Añadir `Boton_Examen` en barra inferior (siempre visible si hay carrera activa)
- Integrar `Lector_Libros` en menú de perfil/inventario

---

## Clases a Implementar

### Core
- `Carrera.gd` - Clase base Resource
- `Carrera_Ingenieria_Informatica.gd` - Carrera específica
- `Sistema_Examenes.gd` - Cálculo de notas probabilísticas
- `Actividad_Carrera.gd` - Actividad de estudio

### UI
- `Modal_Examen.tscn` + `Modal_Examen.gd` - Interfaz examen
- `Boton_Examen.gd` - Botón barra inferior
- `Lector_Libros.tscn` + `Lector_Libros.gd` - Visualizador de apuntes

### Contenido
- `preguntas_ing_informatica.json` - 40 preguntas (10 por año)
- `apuntes_ing_informatica_año*.txt` - Contenido teórico

### Tests
- `test_carrera.gd` - Tests de clase Carrera
- `test_examenes.gd` - Tests de Sistema_Examenes
- `test_integracion.gd` - Tests end-to-end

---

## Habilidades Académicas (Nueva)

### Sangre Fría (Habilidad[6])
- **Rango:** 1-100
- **Generación:** Aleatoria en primera partida
- **Peso en examen:** 50%
- **Interpretación:** Compostura bajo presión

### Fórmula:
```
habilidades_academicas = (Inteligencia[1] × 0.35) + (Memoria[3] × 0.15) + (Sangre_Fría[6] × 0.50)
```

---

## Probabilidades de Referencia

| Perfil | Valor Esperado | Prob. Aprobar (≥50) | Prob. Nota Alta (≥70) |
|--------|---|---|---|
| Excelente | 90 | ~99.9% | ~84% |
| Promedio | 58.55 | ~68% | ~25% |
| Inteligente Nervioso | 61.41 | ~68% | ~15% |
| Malo | 33.05 | ~15% | ~2% |
| Destruido/Cansado | 64.65 | ~68% | ~27% |
| Milagro | 23.45 | ~2% | ~0.5% |

---

## Notas de Implementación

### GDScript 4.4 Compatibility
- Usar `Resource` para clases serializables
- `JSON.parse()` para cargar preguntas
- `randn_binom()` para distribución normal

### Performance
- Preguntas se cargan una sola vez (caché)
- Libros se cachean en memoria
- Cálculo de nota es O(1)

### Edge Cases
- Jugador lleva 80 años, puede releer libros antiguos
- Dinero negativo: bloquear matrícula siguiente
- `nota_real = 0` si no se presenta: castigo automático

---

## Expansión Futura

1. **Más carreras:** Derecho, Medicina, Bellas Artes
2. **Matrícula de honor:** Descuento en matrícula siguiente año
3. **Sangre Fría afecta:** Otras mecánicas de estrés
4. **Becas:** Sistema de descuentos por nota
5. **Múltiples carreras:** Simultáneas (requiere rediseño)