# Sistema de Economía

Estado del sistema de dinero, trabajos y gastos en SIMS 0.33.

---

## ✅ Implementado

### 1. Variable de dinero
- `Variables_Dinamicas.Dinero` (float). Inicializado a **1000** en `First_Time.Crear_First_Time_Function`.
- Persiste en `Guardar_Variables_Dinamicas` (save/load).
- Editable libremente desde código.

### 2. Sistema de trabajos fijos
- Clase `Actividad_Fija_Trabajo` (extiende `Actividad_Fija`) con propiedades:
  - `hora_inicio` / `hora_final` (minutos desde medianoche)
  - `salario` (float — pago **por hora**)
  - `requisito_progreso` (Array de 3 ints — Deporte/Académico/Manualidades mínimos)
  - `dias_laborales` (Array de int — por defecto `[0,1,2,3,4]` = L-V)
- Una instancia de trabajo definida hoy:
  - **Trabajar_En_Comida_Rapida**: L-V de 08:00 a 16:00, salario 10 €/h → **80/día → 400/semana**.

### 3. Programar trabajo
- `Trabajo.Trabajar(actividad)` rellena la matriz desde la siguiente semana hasta la columna 573 (todos los días laborales del trabajo en las horas indicadas).
- Función helper: `Trabajo.Trabajar_En_Comida_Rapida()`.

### 4. Flujo en la GUI
Menú navegable: **Actividades → Actividades Fijas → Trabajo → Comida Rápida**.

Implementado en:
- `Script_Principal.Opciones_Actividades_Fijas`
- `Script_Principal.Opciones_Actividades_Trabajo`
- `Script_Principal._on_comida_rapida_pressed`

Conexiones de señal en [Escena principal.tscn](Escenas/Escena_Principal/Escena%20principal.tscn).

### 5. Pago automático al final del día laboral
- En `Actividades.Ejecutar_Actividad`, cuando la actividad es `Actividad_Fija_Trabajo` y `Minute_Minute == hora_final - 1`, se suma `salario · horas_trabajadas` a `Dinero`.
- El pago se aplica al cruzar el último minuto del turno (15:59 en Comida Rápida → +80 al instante).

### 6. Dejar el trabajo (cancelar)
- `Trabajo.Dejar_Trabajo(actividad)` borra todas las celdas futuras de esa actividad.
- Al pulsar **Eliminar Actividad** sobre un bloque de trabajo, aparece un `ConfirmationDialog`:
  > *"¿Seguro que quieres dejar el trabajo "X"? Dejarás de ganar dinero."*
  - "Sí, dejar" → ejecuta `Dejar_Trabajo`, guarda, refresca calendario.
  - "Cancelar" → no hace nada.

### 7. Mostrar dinero en pantalla
- Label `Dinero_Label` en la esquina superior derecha, junto al icono `Moneda`.
- Color amarillo brillante con borde negro (`outline_size=6`), `z_index=10` → visible sobre cualquier panel.
- Se actualiza en cada `_process` mediante `Actualizar_Dinero()`.
- **Posición dinámica**: el label se desplaza a la izquierda 25px por cada cifra extra (más de 3), para que números largos no se solapen con el icono.
- Siempre visible: `Visibilizar_Lo_Basico` lo incluye junto a Barra_Abajo / Fondo / Moneda.

### 8. Actividades aleatorias no afectan al dinero
- Las actividades aleatorias (cuando el jugador no ha programado nada) **NO** ejecutan progreso ni descubrimiento de habilidades. Solo aplican efectos de necesidades básicas.
- Esto evita que un jugador inactivo gane dinero indirectamente o avance.

---

## ⏳ Pendiente

### 1. Alquiler semanal (Fase 2)
- Variable `Variables_Estaticas.Alquiler_Semanal = 200` (constante).
- Detectar lunes 00:00 (cuando `Minute_Day` cruza un múltiplo de 7) → restar de `Dinero`.
- Si `Dinero < 0` tras el cobro → activar estado de bancarrota.

### 2. Estado "En la calle" (Bancarrota)
- Variable `Variables_Dinamicas.En_La_Calle = false`.
- Cuando `Dinero < 0` por no poder pagar alquiler → `En_La_Calle = true`.
- Penalización: en `Actividades_Necesidades_Basicas.Cambiar_Necesidades_Basicas`, si `En_La_Calle == true`, capar valores de necesidades básicas a un máximo de **20** (no pueden subir más).
- Indicador visual en GUI (badge rojo sobre el icono de dinero, o etiqueta "EN LA CALLE").
- Salir del estado: cuando `Dinero >= Alquiler_Semanal` y pagas un alquiler atrasado → vuelves a normalidad.

### 3. Más trabajos en el catálogo
Las funciones `Trabajar_De_Carpintero` y `Trabajar_De_Cientifico` ya existen en `Trabajo.gd` pero referencian entradas inexistentes del catálogo. Falta añadirlas a `Variables_Estaticas._Inicializar_Catalogo`:

| Trabajo | Horario | Salario/h | Requisito | Total/sem |
|---|---|---:|---|---:|
| Comida Rápida | L-V 08-16 | 10 | — | 400 ✅ |
| Carpintero | L-V 09-17 | 25 | Manualidades ≥ 30 | 1000 |
| Científico | L-V 09-18 | 50 | Académico ≥ 60 | 2250 |

Validar el `requisito_progreso` antes de permitir contratar (mostrar mensaje "Necesitas X de Académico" si no cumple).

### 4. Gastos de actividades
Algunas actividades deberían costar dinero al ejecutarse:
- **Comer**: -5 € (costo de comida)
- **Salir_A_Correr**: 0 € (gratis)
- **Ver_La_Television**: 0 € (asumiendo factura plana)
- **Estudiar**: 0 € (asumiendo libros propios)

Implementación: añadir campo `coste` (float) a la clase `Actividad`, descontar en `Ejecutar_Actividad`.

### 5. Tienda y objetos comprables (Fase 3)
- Pantalla nueva "Tienda" accesible desde un botón (o icono).
- Catálogo de objetos en `Variables_Estaticas.Catalogo_Objetos`:

| Objeto | Precio | Efecto |
|---|---:|---|
| Cama buena | 300 | Dormir → x2 efecto (descansas más rápido) |
| TV moderna | 200 | Ver_La_Television → x1.5 salud mental |
| Material deportivo | 150 | Salir_A_Correr → +1 efecto Deporte por minuto |
| Libros de estudio | 100 | Estudiar → +20% velocidad progreso académico |

- Variable `Variables_Dinamicas.Objetos_Comprados` (Array de strings).
- Aplicar multiplicadores al ejecutar la actividad correspondiente si tienes el objeto.

### 6. Otras fuentes de ingreso (post-MVP)
- **Eventos aleatorios**: "Encuentras 50€ en la calle", "Tu tía te envía 200€ por tu cumple".
- **Premios por hitos**: "Has llegado a Progreso Académico 80 → 500€ de beca".
- **Vender objetos**: revender artículos de la tienda al 50% del precio.

### 7. Sistema de facturas y gastos recurrentes (post-MVP)
- Electricidad, agua, internet: gastos pequeños semanales.
- Aumentan si compras más objetos (cama buena consume más, etc.).

### 8. Polish de la GUI del dinero
- Animación cuando cobras (texto verde flotante "+80€").
- Animación cuando pierdes (texto rojo "-200€").
- Sonido opcional al cobrar.
- Indicador de cuánto te queda hasta el próximo alquiler.

### 9. Validación previa al contratar trabajo
- Si el jugador ya tiene un trabajo, pedir confirmación antes de aceptar uno nuevo (sustituirá al anterior).
- Si no cumple `requisito_progreso`, mostrar mensaje informativo.

---

## Resumen de archivos modificados

| Archivo | Función |
|---|---|
| [Scripts/Globales/Principales_Variables/Variables_Dinamicas.gd](Scripts/Globales/Principales_Variables/Variables_Dinamicas.gd) | `Dinero` |
| [Scripts/Logica/Escena_Principal/Actividades/Trabajo/Trabajo.gd](Scripts/Logica/Escena_Principal/Actividades/Trabajo/Trabajo.gd) | `Trabajar`, `Dejar_Trabajo` |
| [Scripts/Logica/Escena_Principal/Actividades/Actividades.gd](Scripts/Logica/Escena_Principal/Actividades/Actividades.gd) | Pago en `Ejecutar_Actividad` |
| [Scripts/Globales/Script_Principal.gd](Scripts/Globales/Script_Principal.gd) | Handlers de menú, dialogo, `Actualizar_Dinero` |
| [Scripts/GUI/Escena_Principal/Gestionar_Visibilidad.gd](Scripts/GUI/Escena_Principal/Gestionar_Visibilidad.gd) | `Dinero_Label` siempre visible |
| [Escenas/Escena_Principal/Escena principal.tscn](Escenas/Escena_Principal/Escena%20principal.tscn) | Menú nuevo, label de dinero, conexiones |

---

## Próximos pasos recomendados

1. **Implementar alquiler + bancarrota** (Fase 2). Es el siguiente bloque lógico y completa el ciclo económico básico (ingresos + gastos forzados).
2. **Añadir gasto a Comer** (campo `coste` en Actividad). Es trivial y refuerza la presión económica.
3. **Activar Carpintero y Científico** una vez funcionen los requisitos de progreso. Da progresión de carrera al jugador con talento.
4. **Tienda** como último gran bloque cuando el resto esté pulido.
