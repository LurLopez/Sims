class_name Objeto_Ropa
extends Objeto
## Prenda equipable. Además de sus bonificaciones de juego, define cómo se
## dibuja el atuendo sobre el personaje (estilo y paleta) en todas las
## animaciones (escenario de Inicio, avatar, retrato del perfil y vestuario).

## Cómo se consigue la prenda:
## - "inicio": gratis y disponible desde el primer día.
## - "tienda": se compra con dinero desde el Vestuario.
## - "rango": se desbloquea con Maestría Culinaria.
@export var desbloqueo: String = "inicio"
## Categoría del armario: diario, deporte, elegante, trabajo, fiesta o cocina.
@export var categoria: String = "diario"

@export var bonus_salario_general: float = 0.0
@export var bonus_salario_hosteleria: float = 0.0
@export var reduccion_higiene_trabajo: float = 0.0
@export var reduccion_higiene_cualquier_trabajo: float = 0.0
@export var bonus_propinas_minijuego: float = 0.0
@export var descripcion_efecto: String = ""

## Identificador visual: "base", "delantal", "chef", "gala", "michelin",
## "casual", "deportivo", "verano", "invierno", "traje", "bata", "mono",
## "camarero", "pijama", "fiesta", "futbol", "cuero", "astronauta" o "vestido".
@export var estilo_visual: String = "base"

## Prendas base que sustituyen a las del creador. Si están vacías se usa la
## combinación por defecto del estilo visual.
@export var prenda_superior: String = ""
@export var prenda_inferior: String = ""
@export var calzado: String = ""

## Detalle decorativo del estilo (cuadros, corbata, bufanda, estrellas...).
@export var detalle_visual: String = ""

## Paleta del atuendo. Los colores vacíos usan el color elegido en el creador
## de personaje (así la ropa de calle conserva la personalización del jugador).
@export var color_principal: String = ""
@export var color_secundario: String = ""
@export var color_detalle: String = ""
@export var color_pantalon: String = ""
@export var color_zapatillas: String = ""
