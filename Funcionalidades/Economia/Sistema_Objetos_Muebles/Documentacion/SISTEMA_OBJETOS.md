# Sistema de Objetos/Muebles

## Descripción
Sistema de compra, venta y selección de objetos que afectan a necesidades básicas mediante multiplicadores de probabilidad. Inspirado en los Sims.

## Estructura

### Clases
```
Scripts/Logica/Escena_Principal/Economia/Herencia/
├── Objeto.gd (clase_name Objeto)
│   ├── nombre: String
│   ├── precio: float
│   ├── multiplicador: float (1.0 = sin efecto)
│   ├── afecta_a: String (ej: "Dormir", "Comer", "Duchar")
│   └── es_basico: bool (true = no se puede vender si es único)
├── Objeto_Dormir.gd (extends Objeto)
├── Objeto_Comer.gd (extends Objeto)
└── Objeto_Duchar.gd (extends Objeto)
```

### Variables
**Variables_Estaticas:**
```gdscript
var Catalogo_Objetos: Dictionary = {
    "Cama_Basica": Objeto_Dormir(...),    # multiplicador 1.0, es_basico true
    "Cama_Premium": Objeto_Dormir(...),   # multiplicador 1.05
    "Cama_Lujo": Objeto_Dormir(...),      # multiplicador 1.10
    # ... más objetos
}
```

**Variables_Dinamicas:**
```gdscript
var Objetos_Poseidos: Dictionary = {
    "Cama_Basica": true,
    "Cama_Premium": false,
    # ... estado de posesión
}

var Objeto_Seleccionado: Dictionary = {
    "Dormir": "Cama_Basica",    # qué objeto está usando
    "Comer": "Mesa_Basica",
    "Duchar": "Ducha_Basica"
}
```

## Flujos

### Compra
```gdscript
Actividades.Comprar_Objeto("Cama_Premium")
```
- Validación: objeto existe, no lo posee, tiene dinero
- Efecto: `-precio` dinero, `+true` en `Objetos_Poseidos`
- Retorna: `bool` (éxito/fracaso)

### Venta
```gdscript
Actividades.Vender_Objeto("Cama_Premium")
```
- Validación: lo posee, no es único de su categoría, no está seleccionado
- Efecto: `+precio*0.5` dinero, `-false` en `Objetos_Poseidos`
- Retorna: `bool`

### Selección
```gdscript
Actividades.Seleccionar_Objeto("Dormir", "Cama_Premium")
```
- Validación: lo posee, categoría coincide
- Efecto: actualiza `Objeto_Seleccionado["Dormir"]`
- Retorna: `bool`

## Lógica de Multiplicador

### Implementación Actual
En `Actividades_Necesidades_Basicas.gd`:

```gdscript
func _Obtener_Multiplicador(nombre_actividad: String) -> float:
    match nombre_actividad:
        "Dormir", "Comer", "Duchar":
            var clave = Variables_Dinamicas.Objeto_Seleccionado.get(nombre_actividad, "")
            if clave == "" or not Variables_Estaticas.Catalogo_Objetos.has(clave):
                return 1.0
            return Variables_Estaticas.Catalogo_Objetos[clave].multiplicador
        _:
            return 1.0
```

Aplica el multiplicador **solo a efectos positivos**:
```gdscript
if por_cuanto > 0 and multiplicador != 1.0:
    valor_maximo = max(1, floor(valor_maximo / multiplicador))
```

**Ejemplo:**
- Actividad Dormir: efecto +4 descanso cada ~15 min
- Cama Premium (1.05): efecto sube a +4.2, intervalo baja a ~14.3 min
- Resultado: descansa más rápido, NO acelera caída de hambre/higiene

### Expansión Futura (No Implementada)
**Objetivo:** Permitir objetos que reduzcan efectos negativos.

**Ejemplo:** Ropa Premium (multiplicador 0.95 en Higiene)
- Actividad normal pierde higiene cada ~20 min
- Con ropa: pierde cada ~21 min (0.95 * 20)

**Cambio necesario:**
```gdscript
if multiplicador != 1.0:
    if por_cuanto > 0:  # Efectos positivos
        valor_maximo = max(1, floor(valor_maximo / multiplicador))
    else:  # Efectos negativos
        valor_maximo = floor(valor_maximo * multiplicador)
```

**Nuevos objetos:**
- `Objeto_Higiene.gd` (extends Objeto)
- `Ropa_Premium`: precio 150, multiplicador 0.95, afecta_a "Duchar"

## Inicialización

### First_Time
```gdscript
Crear_Objetos_Iniciales()
# Inicia con los básicos de cada categoría
Objetos_Poseidos = {
    "Cama_Basica": true,
    "Mesa_Basica": true,
    "Ducha_Basica": true
}
Objeto_Seleccionado = {
    "Dormir": "Cama_Basica",
    "Comer": "Mesa_Basica",
    "Duchar": "Ducha_Basica"
}
```

### Guardado
En `Guardar_Variables_Dinamicas.gd`:
- Guarda `Objetos_Poseidos` (Dictionary)
- Guarda `Objeto_Seleccionado` (Dictionary)
- Fallback para saves antiguos: inicializa con `_Inicializar_Objetos_Por_Defecto()`

## Restricciones

1. **Obligatoriedad:** Siempre hay al menos un objeto seleccionado por categoría
2. **Venta:** No se puede vender si es el único de su categoría
3. **Venta:** No se puede vender si está actualmente seleccionado
4. **Precio:** Reventa = 50% del precio original

## Catálogo Implementado (7 objetos)

| Nombre | Categoría | Precio | Multiplicador | Básico | Descripción |
|--------|-----------|--------|----------------|--------|-------------|
| **Cama_Basica** | Dormir | 0€ | 1.0 | ✓ | Cama de inicio. No se puede vender si es única. |
| **Cama_Premium** | Dormir | 200€ | 1.05 | ✗ | Descanso 5% más rápido. |
| **Cama_Lujo** | Dormir | 800€ | 1.10 | ✗ | Descanso 10% más rápido. |
| **Mesa_Basica** | Comer | 0€ | 1.0 | ✓ | Mesa de inicio. No se puede vender si es única. |
| **Mesa_Premium** | Comer | 200€ | 1.05 | ✗ | Saciar hambre 5% más rápido. |
| **Ducha_Basica** | Duchar | 0€ | 1.0 | ✓ | Ducha de inicio. No se puede vender si es única. |
| **Ducha_Premium** | Duchar | 200€ | 1.05 | ✗ | Higiene 5% más rápida. |

## Testing

Ubicación: `Funcionalidades/Economia/Sistema_Objetos_Muebles/Tests/`

Tests pendientes:
- [ ] Compra exitosa y fallida (dinero insuficiente, objeto ya poseído)
- [ ] Venta exitosa y fallida (único, seleccionado)
- [ ] Selección de objeto
- [ ] Aplicación de multiplicador en actividades
- [ ] Persistencia en guardado
- [ ] Fallback para saves antiguos

## Cómo Expandir el Catálogo

### Añadir un nuevo objeto (ej: Cama Súper Premium)

```gdscript
# En Variables_Estaticas._Inicializar_Catalogo_Objetos()

var cama_super = Objeto_Dormir.new()
cama_super.nombre = "Cama_Super_Premium"
cama_super.precio = 1500.0
cama_super.multiplicador = 1.15  # +15%
cama_super.afecta_a = "Dormir"
cama_super.es_basico = false
Catalogo_Objetos["Cama_Super_Premium"] = cama_super
```

### Crear una nueva categoría (ej: Objetos para Higiene/efectos negativos)

1. Crear `Objeto_Higiene.gd`:
   ```gdscript
   class_name Objeto_Higiene
   extends Objeto
   ```

2. Añadir objetos en el catálogo:
   ```gdscript
   var ropa_premium = Objeto_Higiene.new()
   ropa_premium.nombre = "Ropa_Premium"
   ropa_premium.precio = 150.0
   ropa_premium.multiplicador = 0.95  # Reduce caída de higiene en 5%
   ropa_premium.afecta_a = "Duchar"
   ropa_premium.es_basico = false
   Catalogo_Objetos["Ropa_Premium"] = ropa_premium
   ```

3. Actualizar lógica de multiplicadores en `Actividades_Necesidades_Basicas.gd` para soportar multiplicadores < 1.0 en efectos negativos (ver sección "Expansión Futura")

## Estado Actual

- **Implementado:** 7 objetos, 3 categorías (Dormir, Comer, Duchar)
- **Pendiente:** UI de tienda (mock en proyecto)
- **Planeado:** Efectos negativos, más categorías (Ocio, Trabajo)
