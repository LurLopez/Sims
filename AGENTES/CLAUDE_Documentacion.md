# CLAUDE.md — Modo: Documentación de Funcionalidades

**Tu única tarea en esta conversación: documentar una funcionalidad del juego creando los archivos MD, HTML y tests.**

---

## Cómo se usa este agente

El usuario te dirá algo como:
> "Documenta la funcionalidad Inventario dentro de Perfil"
> "Crea la documentación de Sistema_Tienda en Economia"

Eso define la **ruta destino** y el **nombre de la funcionalidad**. Si no está claro, pregunta antes de empezar.

---

## Estructura de carpetas que debes crear

```
Funcionalidades/
└── <Categoria>/          ← puede tener subcategorías (ej: Perfil, Economia, etc.)
    └── <Nombre>/
        ├── Documentacion/
        │   ├── <NOMBRE>.md      ← Técnico, para la IA
        │   └── <NOMBRE>.html    ← Visual, para el humano
        └── Tests/
            └── test_<nombre>.gd ← Tests con GUT
```

**Ejemplo:** "Inventario dentro de Perfil" →
- `Funcionalidades/Perfil/Inventario/Documentacion/INVENTARIO.md`
- `Funcionalidades/Perfil/Inventario/Documentacion/INVENTARIO.html`
- `Funcionalidades/Perfil/Inventario/Tests/test_inventario.gd`

---

## Antes de escribir nada: investiga el código

1. Lee los archivos `.gd` relevantes a la funcionalidad (búscalos en `Scripts/`).
2. Revisa `Variables_Dinamicas.gd` y `Variables_Estaticas.gd` para identificar variables afectadas.
3. Si hay GUI, revisa `Gestionar_Visibilidad.gd` y el `.tscn` de la escena principal.
4. Mira el `CLAUDE.md` principal del proyecto para entender convenciones.
5. Si hay funcionalidades relacionadas ya documentadas en `Funcionalidades/`, léelas para mantener coherencia.

**No inventes código ni comportamiento.** Documenta solo lo que está implementado o lo que el usuario describe explícitamente.

---

## Archivo 1: `<NOMBRE>.md` — Técnico para la IA

Este archivo lo leerá Claude en futuras conversaciones para entender la funcionalidad. Debe ser preciso, completo y con código real.

### Estructura obligatoria

```markdown
# <Nombre de la Funcionalidad>

## Descripción General
<Qué hace, por qué existe, objetivo en el juego>

---

## Clases / Resources
<Para cada clase relevante: ubicación, tipo, @export properties con tabla>

---

## Variables Dinámicas / Estáticas afectadas
<Solo las que esta funcionalidad usa o modifica>

---

## Flujo de Ejecución
<Paso a paso con código GDScript real de los archivos, comentado donde sea crítico>

---

## UI: Nodos y Visibilidad
<Jerarquía de nodos, integración en Gestionar_Visibilidad, z_index si aplica>

---

## Persistencia (Save/Load)
<Qué se guarda, formato, cómo se restaura>

---

## Casos de Uso
<3-5 escenarios concretos: qué pasa, qué se espera>

---

## Notas Técnicas
<Tabla con aspectos clave: límites, edge cases, invariantes importantes>

---

## Convenciones de Nombres (Godot)
<Nodos, recursos, funciones específicos de esta funcionalidad>

---

## Checklist de Implementación
<Lista con [ ] de todo lo que hay que crear/modificar para que funcione>
```

### Reglas para el MD

- Usa GDScript real extraído de los archivos, no pseudocódigo.
- Marca con `# CRÍTICO:` los fragmentos donde el orden o valor importa mucho.
- Si algo no está implementado todavía pero el usuario lo describe, ponlo en un bloque `> **FUTURO:**`.
- Secciones vacías (sin contenido): omítelas.

---

## Archivo 2: `<NOMBRE>.html` — Visual para el humano

Este archivo se abre en el navegador. Debe ser fácil de leer de un vistazo: colores, tablas, flujos claros.

### Plantilla base HTML

```html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><Nombre> - Documentación</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; line-height: 1.6; max-width: 900px; margin: 0 auto; padding: 20px; background: #f5f5f5; color: #333; }
        .container { background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; border-bottom: 3px solid <COLOR_ACENTO>; padding-bottom: 10px; }
        h2 { color: #34495e; margin-top: 30px; padding-top: 15px; border-top: 1px solid #ecf0f1; }
        h3 { color: #7f8c8d; }
        .section { margin: 20px 0; padding: 15px; background: #ecf0f1; border-left: 4px solid <COLOR_ACENTO>; border-radius: 4px; }
        .critical { background: #fadbd8; border-left-color: #e74c3c; color: #c0392b; font-weight: bold; }
        .info { background: #d6eaf8; border-left-color: #2980b9; }
        .success { background: #d5f4e6; border-left-color: #27ae60; }
        .warning { background: #fef9e7; border-left-color: #f39c12; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; background: white; border-radius: 4px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
        th { background: <COLOR_ACENTO>; color: white; padding: 12px; text-align: left; }
        td { padding: 10px 12px; border-bottom: 1px solid #ecf0f1; }
        tr:last-child td { border-bottom: none; }
        code { background: #f8f9fa; padding: 2px 6px; border-radius: 3px; font-family: monospace; font-size: 0.9em; }
        pre { background: #2c3e50; color: #ecf0f1; padding: 15px; border-radius: 6px; overflow-x: auto; }
        pre code { background: none; color: inherit; padding: 0; }
        .flow-step { display: flex; align-items: flex-start; margin: 10px 0; }
        .step-number { background: <COLOR_ACENTO>; color: white; border-radius: 50%; width: 28px; height: 28px; display: flex; align-items: center; justify-content: center; font-weight: bold; margin-right: 12px; flex-shrink: 0; }
        .checklist li { margin: 8px 0; }
        .checklist li::before { content: "☐ "; color: #7f8c8d; }
    </style>
</head>
<body>
<div class="container">
    <!-- Contenido aquí -->
</div>
</body>
</html>
```

### Color de acento por categoría

| Categoría | Color |
|---|---|
| Economia | `#27ae60` (verde) |
| Perfil | `#9b59b6` (morado) |
| Trabajo / Carreras | `#e67e22` (naranja) |
| Core / Gameplay | `#2980b9` (azul) |
| Sin categoría / Nuevo | `#7f8c8d` (gris) |

### Contenido mínimo del HTML

1. **Título + descripción general** en una sección destacada.
2. **Tabla de variables afectadas** (nombre, tipo, rango, descripción).
3. **Flujo numerado** con `div.flow-step` + `div.step-number` para visualizar pasos.
4. **Tabla de casos de uso** (escenario, qué ocurre, resultado).
5. **Checklist de implementación** (`ul.checklist`).
6. **Notas críticas** en `div.section.critical` si hay invariantes importantes.

---

## Archivo 3: `test_<nombre>.gd` — Tests con GUT

### Plantilla

```gdscript
extends GutTest

# Tests para <Nombre>
# <Una línea describiendo qué cubre este archivo>

func test_<caso_basico>():
    # <Descripción: qué se verifica>
    # Setup
    # ...
    # Assert
    assert_eq(valor_real, valor_esperado)

func test_<caso_edge>():
    # <Edge case o invariante importante>
    # ...
```

### Reglas para los tests

- Usa `extends GutTest` siempre (framework GUT de Godot).
- **5–8 tests** que cubran: caso básico, casos límite, y al menos 1 invariante crítica.
- Cada test tiene un comentario de 1 línea explicando qué verifica.
- No uses mocks. Usa directamente `Variables_Dinamicas`, `Variables_Estaticas`, y las clases del juego.
- Nombra los tests descriptivamente: `test_cobrar_alquiler_sin_dinero`, `test_timestamp_preserva_hora_evento`, etc.
- Si la funcionalidad tiene una invariante crítica (ej: "el minuto del mensaje debe ser el del evento, no el actual"), escribe un test que la verifique explícitamente.

---

## Actualizar CLAUDE.md principal

Al terminar, añade la funcionalidad al listado de **"Funcionalidades Implementadas"** en `CLAUDE.md` del proyecto (sección al final). Sigue el formato de las entradas existentes:

```markdown
#### N. Nombre_Funcionalidad
**Ubicación:** `Funcionalidades/Categoria/Nombre_Funcionalidad/`
- **Tests:** `Tests/test_nombre.gd` - N casos de prueba cubriendo X
- **Documentación:** `Documentacion/NOMBRE.html`

**Descripción:** <1-2 frases>

**Variables afectadas:**
- `Variables_Dinamicas.X` (tipo)
- ...

**Funciones principales:**
- `Modulo.Funcion()` - qué hace
- ...
```

---

## Checklist final antes de terminar

- [ ] `<NOMBRE>.md` creado con todas las secciones relevantes y código real
- [ ] `<NOMBRE>.html` creado, abre bien en navegador, sin estilos rotos
- [ ] `test_<nombre>.gd` creado con 5–8 tests significativos
- [ ] Entrada añadida en `CLAUDE.md` principal
- [ ] No hay secciones inventadas: todo lo documentado está en el código o lo describió el usuario

---

## NO hagas en esta conversación

- No implementes la funcionalidad si no existe. Documenta lo que hay.
- No crees archivos `.gd` fuera de `Tests/` (los scripts reales son tarea de Lógica).
- No toques `.tscn` ni cambios visuales (eso es Diseño).
- No modifiques scripts existentes (solo el `CLAUDE.md` principal para añadir la entrada).
