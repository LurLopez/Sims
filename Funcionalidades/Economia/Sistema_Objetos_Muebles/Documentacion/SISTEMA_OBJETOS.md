# Sistema de Objetos/Muebles

## Descripción

Tienda de muebles con **36 objetos repartidos en 6 categorías**. Cada categoría
funciona como una ranura exclusiva: el Sim equipa un solo mueble por categoría y
ese mueble modula una actividad o aporta una bonificación pasiva.

| Categoría | Ranura | Qué mejora |
|---|---|---|
| **Dormir** | Cama | Descanso de `Dormir` |
| **Comer** | Mesa | Hambre de `Comer_Tupper` y `Comer_Basura` |
| **Duchar** | Ducha/bañera | Higiene de `Duchar` |
| **Salón** | Conjunto de salón | Salud mental y Descanso de `Ver_La_Television` |
| **Estudio** | Escritorio/biblioteca | Progreso Académico y Manualidades |
| **Cocina** | Cocina | Progreso Culinario y calidad de los tuppers |

## Estructura

### Clases

```
Scripts/Logica/Escena_Principal/Economia/
├── Catalogo_Tienda.gd          ← datos de las 6 categorías y los 36 muebles
├── Herencia/
│   ├── Objeto.gd               ← precio, multiplicador, tier, efecto y bonus
│   ├── Objeto_Dormir.gd
│   ├── Objeto_Comer.gd
│   ├── Objeto_Duchar.gd
│   └── Objeto_Ropa.gd          ← ropa equipable del Vestuario
└── Ropa_Catalogo.gd
```

`Catalogo_Tienda.Registrar_En()` materializa cada diccionario de `DATOS` como un
`Objeto` dentro de `Variables_Estaticas.Catalogo_Objetos`.

### Campos de `Objeto`

```gdscript
@export var nombre: String             # clave interna (Cama_Premium)
@export var nombre_visible: String     # nombre de la tarjeta (Cama Premium)
@export var descripcion: String        # tooltip de la tarjeta
@export var precio: float
@export var multiplicador: float       # 1.0 = sin efecto
@export var afecta_a: String           # categoría/ranura
@export var es_basico: bool            # gratis y entregado al empezar
@export var tier: String               # basico | premium | lujo | elite
@export var etiqueta_efecto: String    # "×1.05 Descanso (+5%)"
@export var bonus_progreso_deporte: float
@export var bonus_progreso_academico: float
@export var bonus_progreso_manualidades: float
@export var bonus_progreso_cocina: float
@export var bonus_calidad_tupper: float
```

### Variables dinámicas

```gdscript
var Objetos_Poseidos: Dictionary = {
    "Cama_Basica": true,
    "Sofa_Chester": true,
    # ...
}

var Objeto_Seleccionado: Dictionary = {
    "Dormir": "Cama_Basica",
    "Comer": "Mesa_Basica",
    "Duchar": "Ducha_Basica",
    "Salon": "Sofa_Basico",
    "Estudio": "Escritorio_Basico",
    "Cocina": "Cocina_Basica",
    "Ropa": "Ropa_Calle",
}
```

`Variables_Estaticas.Asegurar_Objetos_Basicos()` garantiza que cada categoría
tenga su mueble básico poseído y seleccionado. Se llama al crear partida y al
cargar cualquier save, de modo que las partidas antiguas reciben gratis los
básicos de Salón, Estudio y Cocina.

## Flujos

### Compra

```gdscript
Actividades.Comprar_Objeto("Cama_Premium")
```

- Valida que el objeto exista, no se posea y haya dinero.
- Descuenta el precio y marca `Objetos_Poseidos[clave] = true`.
- La UI muestra un aviso si falta dinero o si la compra se completa.

### Venta

```gdscript
Actividades.Vender_Objeto("Cama_Premium")
```

- No permite vender el único objeto de la categoría.
- No permite vender el objeto equipado.
- Devuelve el **50 %** del precio.

### Equipado

```gdscript
Actividades.Seleccionar_Objeto("Dormir", "Cama_Premium")
```

- Valida posesión y categoría.
- Actualiza `Objeto_Seleccionado[categoría]`.
- El cambio se refleja en la siguiente actividad y en el resumen de Necesidades.

## Bonificaciones

### Multiplicador de necesidades

`Actividades_Necesidades_Basicas._Obtener_Multiplicador()` traduce la actividad
a su ranura y lee el mueble equipado:

```gdscript
const _CATEGORIA_POR_ACTIVIDAD := {
    "Dormir": "Dormir",
    "Duchar": "Duchar",
    "Comer_Tupper": "Comer",
    "Comer_Basura": "Comer",
    "Ver_La_Television": "Salon",
}
```

El multiplicador **solo acelera efectos positivos**, así que una cama mejor no
acelera la caída de hambre ni de higiene. Ejemplo: `Cama_Imperial` (×1.15)
reduce el intervalo de +4 Descanso de 15 a ~13 minutos.

### Progreso de Estudio

`Variables_Estaticas.Obtener_Bonus_Progreso_Objeto(indice)` devuelve el bonus del
mueble equipado en `Estudio` para Deporte/Académico/Manualidades.
`Actividades_Habilidades.Ejecutar_Actividad_Progreso()` lo aplica como una
división extra del intervalo, igual que los bonus de ropa.

### Cocina

- `Obtener_Bonus_Progreso_Cocina_Objeto()` acelera `Progreso_Cocina` en
  `Actividades_Habilidades.Calcular_Max_Progreso_Cocina()`.
- `Obtener_Bonus_Calidad_Tupper_Objeto()` multiplica la calidad base al crear
  un tupper en `Alimentacion.Crear_Tupper()`.
- Los bonus de cocina y ropa se acumulan de forma secuencial.

## Catálogo implementado (36 muebles)

### Dormir — multiplicador de Descanso

| Clave | Precio | Multiplicador | Tier |
|---|---:|---:|---|
| `Cama_Basica` | 0 € | ×1.00 | Básico |
| `Litera_Compacta` | 90 € | ×1.02 | Básico |
| `Cama_Premium` | 200 € | ×1.05 | Premium |
| `Cama_Nube` | 460 € | ×1.07 | Premium |
| `Cama_Lujo` | 800 € | ×1.10 | Lujo |
| `Cama_Imperial` | 1.800 € | ×1.15 | Élite |

### Comer — multiplicador de Hambre

| Clave | Precio | Multiplicador | Tier |
|---|---:|---:|---|
| `Mesa_Basica` | 0 € | ×1.00 | Básico |
| `Mesa_Familiar` | 120 € | ×1.03 | Básico |
| `Mesa_Roble` | 260 € | ×1.05 | Premium |
| `Mesa_Cristal` | 450 € | ×1.07 | Premium |
| `Isla_Desayuno` | 750 € | ×1.10 | Lujo |
| `Mesa_Chef` | 1.500 € | ×1.15 | Élite |

### Duchar — multiplicador de Higiene

| Clave | Precio | Multiplicador | Tier |
|---|---:|---:|---|
| `Ducha_Basica` | 0 € | ×1.00 | Básico |
| `Banera_Clasica` | 160 € | ×1.03 | Básico |
| `Ducha_Premium` | 200 € | ×1.05 | Premium |
| `Ducha_Lluvia` | 390 € | ×1.07 | Premium |
| `Banera_Jacuzzi` | 850 € | ×1.10 | Lujo |
| `Cabina_Spa` | 1.750 € | ×1.15 | Élite |

### Salón — multiplicador de Salud mental

| Clave | Precio | Multiplicador | Tier |
|---|---:|---:|---|
| `Sofa_Basico` | 0 € | ×1.00 | Básico |
| `Sofa_Esquinero` | 180 € | ×1.03 | Básico |
| `Sofa_Chester` | 360 € | ×1.05 | Premium |
| `Sofa_Relax` | 620 € | ×1.08 | Premium |
| `Sofa_Modular` | 980 € | ×1.11 | Lujo |
| `Sofa_Imperial` | 1.900 € | ×1.16 | Élite |

### Estudio — bonus de progreso

| Clave | Precio | Efecto | Tier |
|---|---:|---|---|
| `Escritorio_Basico` | 0 € | Sin bonificación | Básico |
| `Escritorio_Moderno` | 150 € | Académico +4 % | Básico |
| `Escritorio_Ejecutivo` | 340 € | Académico +7 % | Premium |
| `Mesa_Dibujo` | 520 € | Manualidades +9 % | Premium |
| `Escritorio_Gaming` | 900 € | Académico +10 % · Manualidades +3 % | Lujo |
| `Biblioteca_Roble` | 1.700 € | Académico +14 % · Manualidades +5 % | Élite |

### Cocina — progreso y calidad

| Clave | Precio | Efecto | Tier |
|---|---:|---|---|
| `Cocina_Basica` | 0 € | Sin bonificación | Básico |
| `Cocina_Modular` | 170 € | Cocina +4 % | Básico |
| `Cocina_Isla` | 320 € | Cocina +6 % | Premium |
| `Cocina_Chef` | 680 € | Cocina +8 % · Tupper +5 % | Premium |
| `Cocina_Pro` | 1.150 € | Cocina +10 % · Tupper +8 % | Lujo |
| `Cocina_Industrial` | 2.100 € | Cocina +14 % · Tupper +12 % | Élite |

## UI de la Tienda

### Estructura

`Escenas/Escena_Principal/Tienda.tscn` es una escena mínima:

```
Tienda (Control, script Tienda_Objetos.gd)
├── Fondo_Seccion (ColorRect)
├── Flecha_Atras (Button)
├── Titulo (Label)
└── Objetos_Ventajas (Control, Tienda_Bienestar.gd)
```

`Tienda_Objetos.gd` construye en código:

- **Barra de categorías** desplazable horizontalmente: Dormir, Comer, Duchar,
  Salón, Estudio, Cocina y Bienestar.
- **Rejilla de tarjetas** de 2 columnas dentro de un `ScrollContainer` vertical
  (332×390 por tarjeta), por lo que el catálogo puede crecer sin tocar la
  escena ni usar posiciones fijas.
- **Toast** de confirmación/aviso para compras, ventas, equipado y dinero
  insuficiente.

Cada tarjeta contiene:

- `Imagen_Placeholder` (Panel) con fondo tintado por categoría.
- `Icono_Item` (`TextureRect`) con el PNG del mueble o un icono Lucide de
  respaldo.
- `Tier_Pill` con BÁSICO/PREMIUM/LUJO/ÉLITE.
- `Nombre`, `Precio`, `Multiplicador` (efecto) y `En_Uso`/`Estado`.
- `Comprar`, `Elegir` y `Vender`, que se muestran según el estado.

### Reglas de visibilidad

| Botón | Visible cuando |
|---|---|
| `Comprar` | No poseído |
| `Elegir` | Poseído y no seleccionado |
| `Vender` | Poseído, no seleccionado y existe otro objeto de la categoría |
| Estado «En uso» | Seleccionado |
| Estado «En propiedad» | Poseído y no seleccionado |
| Estado «Te faltan N €» | No poseído y sin dinero suficiente |

### Navegación

`Gestionar_Visibilidad.Visibilizar_Tienda()` muestra la tienda y llama a
`Tienda.Abrir_Categoria("Dormir")`. La tienda ya no tiene pestaña superior: el
nodo `Tienda_Button` permanece en la escena por compatibilidad, pero
`_Redisenar_Superior()` y `Visibilizar_Lo_Basico()` lo ocultan. El único acceso
es el icono rápido `Boton_Tienda_Header`, junto al dinero, que llama a
`_on_tienda_tab_pressed()`. La flecha de vuelta lleva al inicio, salvo cuando se
abre desde Necesidades, que regresa a esa pantalla.
`Mostrar_Categoria_Tienda()` delega en el mismo método. Los wrappers
`_on_tab_<categoria>_pressed()` de `Script_Principal` se mantienen para las
capturas de QA.

## Ilustraciones

- **Originales de una sola pieza:** JPG/PNG con fondo magenta en
  `Arte_Fuente/Tienda/Fuente/`.
- **Láminas 2×2 nuevas:** `Lamina_Salon.png`, `Lamina_Dormir_Comer_1.png`,
  `Lamina_Comer_1.png`, `Lamina_Duchar_1.png`, etc. Se cortan con
  `python3 tools/cortar_sprites.py <lamina> Arte_Fuente/Tienda/Fuente
  --grid 2x2 --names ...`.
- **Runtime:** PNG 512×512 con alfa en `Imagenes/Tienda/Iconos/`, con el nombre
  exacto de la clave del catálogo.
- **Pipeline:** `python3 tools/procesar_iconos_tienda.py --preview preview.png`
  acepta JPG con magenta (recorta por croma) y PNG ya recortados (usa su alfa),
  limpia motas, recorta al contenido y centra con un 5 % de margen.
- **Carga:** `Estilos_UI.icono_tienda(clave)` resuelve automáticamente
  `res://Imagenes/Tienda/Iconos/<clave>.png`; no hay que ampliar un diccionario
  al añadir un mueble. La carga es perezosa (solo los 6 muebles de la categoría
  abierta) y la caché es débil, así que al cambiar de categoría se liberan las
  texturas que ya no se ven.
- **Capturas de QA:** `Documentacion/Capturas/01_tienda_dormir.png` …
  `07_tienda_estados.png` (Dormir, Comer, Duchar, Salón, Estudio, Cocina y
  estados Equipar/Vender).

## Testing

`Funcionalidades/Economia/Sistema_Objetos_Muebles/Tests/test_tienda_objetos.gd`
cubre:

- 6 categorías × 6 muebles y básicos gratis.
- `Asegurar_Objetos_Basicos()`.
- Compra, equipado y venta con restricciones.
- Multiplicadores de Dormir, Comer y Salón.
- Bonus de Estudio y Cocina.
- Calidad del tupper con `Cocina_Industrial`.

## Cómo ampliar el catálogo

1. Añade un diccionario a `Catalogo_Tienda.DATOS` con `clave`, `nombre`,
   `categoria`, `precio`, `tier`, `efecto` y los bonus que correspondan.
2. Guarda su ilustración como `<clave>.jpg` (fondo magenta) o `<clave>.png`
   (alfa) en `Arte_Fuente/Tienda/Fuente/`.
3. Ejecuta `python3 tools/procesar_iconos_tienda.py`.
4. Si es el primer mueble de una categoría nueva, añade la categoría a
   `Catalogo_Tienda.CATEGORIAS`, su `basico` y su icono Lucide; la barra y la
   rejilla se generan solas.
5. Si la categoría mejora una actividad nueva, añádela al mapa
   `_CATEGORIA_POR_ACTIVIDAD` de `Actividades_Necesidades_Basicas.gd` o usa los
   campos de bonus de progreso.

## Estado actual

- **Implementado:** 36 muebles, 6 categorías, tienda con scroll, compra/venta/
  equipado, multiplicadores de necesidades, bonus de progreso de Estudio,
  bonus de Cocina y calidad de tupper, migración de saves, toasts y arte 2.5D.
- **Planeado:** efectos negativos (< 1.0), más categorías (Deporte, Oficina) y
  filtros/ordenación dentro de cada categoría.
