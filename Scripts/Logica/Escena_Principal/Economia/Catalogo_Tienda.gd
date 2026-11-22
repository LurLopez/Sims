class_name Catalogo_Tienda
extends RefCounted
## Catálogo central de muebles de la Tienda.
##
## Cada entrada construye un `Objeto` con su categoría (que actúa como ranura
## exclusiva: solo se puede equipar un objeto por categoría), precio, aspecto y
## bonificaciones. Para añadir un mueble basta con añadir su diccionario a
## `DATOS` y su PNG (mismo nombre de clave) a `Imagenes/Tienda/Iconos/`.
##
## Las categorías con multiplicador mejoran una actividad concreta:
##   Dormir  → Dormir            (Descanso)
##   Comer   → Comer_Tupper/Basura (Hambre)
##   Duchar  → Duchar            (Higiene)
##   Salon   → Ver_La_Television (Salud mental y Descanso)
## Estudio y Cocina usan bonificaciones de progreso en lugar de multiplicador.

const CATEGORIAS: Array[Dictionary] = [
	{
		"id": "Dormir",
		"nombre": "Dormir",
		"icono": "bed-double",
		"color": "#1d7afc",
		"fondo": "#eef5fc",
		"basico": "Cama_Basica",
	},
	{
		"id": "Comer",
		"nombre": "Comer",
		"icono": "utensils",
		"color": "#d97706",
		"fondo": "#fdf7e8",
		"basico": "Mesa_Basica",
	},
	{
		"id": "Duchar",
		"nombre": "Duchar",
		"icono": "shower-head",
		"color": "#0d9488",
		"fondo": "#eaf8f2",
		"basico": "Ducha_Basica",
	},
	{
		"id": "Salon",
		"nombre": "Salón",
		"icono": "armchair",
		"color": "#7c3aed",
		"fondo": "#f3eeff",
		"basico": "Sofa_Basico",
	},
	{
		"id": "Estudio",
		"nombre": "Estudio",
		"icono": "book-open",
		"color": "#2563eb",
		"fondo": "#eef4ff",
		"basico": "Escritorio_Basico",
	},
	{
		"id": "Cocina",
		"nombre": "Cocina",
		"icono": "chef-hat",
		"color": "#ea580c",
		"fondo": "#fff3e8",
		"basico": "Cocina_Basica",
	},
]

const DATOS: Array[Dictionary] = [
	# ------------------------------------------------------------------ Dormir
	{
		"clave": "Cama_Basica",
		"nombre": "Cama Básica",
		"categoria": "Dormir",
		"precio": 0.0,
		"multiplicador": 1.0,
		"tier": "basico",
		"efecto": "×1.00 Descanso",
		"descripcion": "Cama individual de pino con manta teal. Sencilla y funcional.",
	},
	{
		"clave": "Litera_Compacta",
		"nombre": "Litera Compacta",
		"categoria": "Dormir",
		"precio": 90.0,
		"multiplicador": 1.02,
		"tier": "basico",
		"efecto": "×1.02 Descanso (+2%)",
		"descripcion": "Litera de pino que aprovecha el espacio sin renunciar al confort.",
	},
	{
		"clave": "Cama_Premium",
		"nombre": "Cama Premium",
		"categoria": "Dormir",
		"precio": 200.0,
		"multiplicador": 1.05,
		"tier": "premium",
		"efecto": "×1.05 Descanso (+5%)",
		"descripcion": "Cama doble de nogal con cabecero acolchado y ribete dorado.",
	},
	{
		"clave": "Cama_Nube",
		"nombre": "Cama Nube",
		"categoria": "Dormir",
		"precio": 460.0,
		"multiplicador": 1.07,
		"tier": "premium",
		"efecto": "×1.07 Descanso (+7%)",
		"descripcion": "Colchón mullido y dosel suave: dormir aquí sabe a flotar.",
	},
	{
		"clave": "Cama_Lujo",
		"nombre": "Cama de Lujo",
		"categoria": "Dormir",
		"precio": 800.0,
		"multiplicador": 1.10,
		"tier": "lujo",
		"efecto": "×1.10 Descanso (+10%)",
		"descripcion": "Cama king de terciopelo esmeralda con detalles dorados.",
	},
	{
		"clave": "Cama_Imperial",
		"nombre": "Cama Imperial",
		"categoria": "Dormir",
		"precio": 1800.0,
		"multiplicador": 1.15,
		"tier": "elite",
		"efecto": "×1.15 Descanso (+15%)",
		"descripcion": "Suite privada dentro de casa: dosel, seda y descanso de reyes.",
	},

	# ------------------------------------------------------------------- Comer
	{
		"clave": "Mesa_Basica",
		"nombre": "Mesa Básica",
		"categoria": "Comer",
		"precio": 0.0,
		"multiplicador": 1.0,
		"tier": "basico",
		"efecto": "×1.00 Hambre",
		"descripcion": "Mesa rectangular de pino puesta para uno. Cumple su función.",
	},
	{
		"clave": "Mesa_Familiar",
		"nombre": "Mesa Familiar",
		"categoria": "Comer",
		"precio": 120.0,
		"multiplicador": 1.03,
		"tier": "basico",
		"efecto": "×1.03 Hambre (+3%)",
		"descripcion": "Mesa robusta con mantel y espacio para compartir cada comida.",
	},
	{
		"clave": "Mesa_Roble",
		"nombre": "Mesa de Roble",
		"categoria": "Comer",
		"precio": 260.0,
		"multiplicador": 1.05,
		"tier": "premium",
		"efecto": "×1.05 Hambre (+5%)",
		"descripcion": "Roble macizo, vajilla de cerámica y una pequeña bandeja central.",
	},
	{
		"clave": "Mesa_Cristal",
		"nombre": "Mesa de Cristal",
		"categoria": "Comer",
		"precio": 450.0,
		"multiplicador": 1.07,
		"tier": "premium",
		"efecto": "×1.07 Hambre (+7%)",
		"descripcion": "Sobre transparente con base cromada y sillas de diseño.",
	},
	{
		"clave": "Isla_Desayuno",
		"nombre": "Isla de Desayuno",
		"categoria": "Comer",
		"precio": 750.0,
		"multiplicador": 1.10,
		"tier": "lujo",
		"efecto": "×1.10 Hambre (+10%)",
		"descripcion": "Isla de mármol con taburetes altos y luz cálida.",
	},
	{
		"clave": "Mesa_Chef",
		"nombre": "Mesa del Chef",
		"categoria": "Comer",
		"precio": 1500.0,
		"multiplicador": 1.15,
		"tier": "elite",
		"efecto": "×1.15 Hambre (+15%)",
		"descripcion": "Mesa de banquete con servicio completo y candelabros.",
	},

	# ------------------------------------------------------------------ Duchar
	{
		"clave": "Ducha_Basica",
		"nombre": "Ducha Básica",
		"categoria": "Duchar",
		"precio": 0.0,
		"multiplicador": 1.0,
		"tier": "basico",
		"efecto": "×1.00 Higiene",
		"descripcion": "Plato blanco, azulejo, cortina y cromados. Limpia y sencilla.",
	},
	{
		"clave": "Banera_Clasica",
		"nombre": "Bañera Clásica",
		"categoria": "Duchar",
		"precio": 160.0,
		"multiplicador": 1.03,
		"tier": "basico",
		"efecto": "×1.03 Higiene (+3%)",
		"descripcion": "Bañera con patas de porcelana y grifería dorada.",
	},
	{
		"clave": "Ducha_Premium",
		"nombre": "Ducha Premium",
		"categoria": "Duchar",
		"precio": 200.0,
		"multiplicador": 1.05,
		"tier": "premium",
		"efecto": "×1.05 Higiene (+5%)",
		"descripcion": "Walk-in de pizarra, cristal y lluvia de latón cepillado.",
	},
	{
		"clave": "Ducha_Lluvia",
		"nombre": "Ducha Lluvia",
		"categoria": "Duchar",
		"precio": 390.0,
		"multiplicador": 1.07,
		"tier": "premium",
		"efecto": "×1.07 Higiene (+7%)",
		"descripcion": "Cabezal de lluvia amplio y mampara de cristal sin marco.",
	},
	{
		"clave": "Banera_Jacuzzi",
		"nombre": "Bañera Jacuzzi",
		"categoria": "Duchar",
		"precio": 850.0,
		"multiplicador": 1.10,
		"tier": "lujo",
		"efecto": "×1.10 Higiene (+10%)",
		"descripcion": "Espuma, chorros y una bandeja con sales para desconectar.",
	},
	{
		"clave": "Cabina_Spa",
		"nombre": "Cabina Spa",
		"categoria": "Duchar",
		"precio": 1750.0,
		"multiplicador": 1.15,
		"tier": "elite",
		"efecto": "×1.15 Higiene (+15%)",
		"descripcion": "Cabina de hidromasaje con vapor, luz cálida y banco de té.",
	},

	# ------------------------------------------------------------------- Salón
	{
		"clave": "Sofa_Basico",
		"nombre": "Sofá Básico",
		"categoria": "Salon",
		"precio": 0.0,
		"multiplicador": 1.0,
		"tier": "basico",
		"efecto": "×1.00 Salud mental",
		"descripcion": "Sofá de dos plazas con cojines cómodos y tela resistente.",
	},
	{
		"clave": "Sofa_Esquinero",
		"nombre": "Sofá Esquinero",
		"categoria": "Salon",
		"precio": 180.0,
		"multiplicador": 1.03,
		"tier": "basico",
		"efecto": "×1.03 Salud mental (+3%)",
		"descripcion": "Sofá en L con chaise longue y mesa baja delante.",
	},
	{
		"clave": "Sofa_Chester",
		"nombre": "Sofá Chester",
		"categoria": "Salon",
		"precio": 360.0,
		"multiplicador": 1.05,
		"tier": "premium",
		"efecto": "×1.05 Salud mental (+5%)",
		"descripcion": "Cuero capitoné, patas de madera y lámpara de lectura.",
	},
	{
		"clave": "Sofa_Relax",
		"nombre": "Sofá Relax",
		"categoria": "Salon",
		"precio": 620.0,
		"multiplicador": 1.08,
		"tier": "premium",
		"efecto": "×1.08 Salud mental (+8%)",
		"descripcion": "Reclinable con reposapiés, manta y mesa de centro.",
	},
	{
		"clave": "Sofa_Modular",
		"nombre": "Sofá Modular",
		"categoria": "Salon",
		"precio": 980.0,
		"multiplicador": 1.11,
		"tier": "lujo",
		"efecto": "×1.11 Salud mental (+11%)",
		"descripcion": "Módulos de terciopelo, alfombra persa y televisión integrada.",
	},
	{
		"clave": "Sofa_Imperial",
		"nombre": "Salón Imperial",
		"categoria": "Salon",
		"precio": 1900.0,
		"multiplicador": 1.16,
		"tier": "elite",
		"efecto": "×1.16 Salud mental (+16%)",
		"descripcion": "Salón de cine con butacas, chimenea y lámparas de pie.",
	},

	# ----------------------------------------------------------------- Estudio
	{
		"clave": "Escritorio_Basico",
		"nombre": "Escritorio Básico",
		"categoria": "Estudio",
		"precio": 0.0,
		"multiplicador": 1.0,
		"tier": "basico",
		"efecto": "Sin bonificación",
		"descripcion": "Mesa de trabajo de pino con lámpara y estantería sencilla.",
		"bonus_academico": 0.0,
		"bonus_manualidades": 0.0,
	},
	{
		"clave": "Escritorio_Moderno",
		"nombre": "Escritorio Moderno",
		"categoria": "Estudio",
		"precio": 150.0,
		"multiplicador": 1.0,
		"tier": "basico",
		"efecto": "Académico +4%",
		"descripcion": "Escritorio blanco, silla ergonómica y lámpara articulada.",
		"bonus_academico": 0.04,
		"bonus_manualidades": 0.0,
	},
	{
		"clave": "Escritorio_Ejecutivo",
		"nombre": "Escritorio Ejecutivo",
		"categoria": "Estudio",
		"precio": 340.0,
		"multiplicador": 1.0,
		"tier": "premium",
		"efecto": "Académico +7%",
		"descripcion": "Nogal oscuro, sillón de cuero y biblioteca lateral.",
		"bonus_academico": 0.07,
		"bonus_manualidades": 0.0,
	},
	{
		"clave": "Mesa_Dibujo",
		"nombre": "Mesa de Dibujo",
		"categoria": "Estudio",
		"precio": 520.0,
		"multiplicador": 1.0,
		"tier": "premium",
		"efecto": "Manualidades +9%",
		"descripcion": "Tablero inclinado con reglas, botes de pinceles y buena luz.",
		"bonus_academico": 0.0,
		"bonus_manualidades": 0.09,
	},
	{
		"clave": "Escritorio_Gaming",
		"nombre": "Escritorio Gaming",
		"categoria": "Estudio",
		"precio": 900.0,
		"multiplicador": 1.0,
		"tier": "lujo",
		"efecto": "Académico +10% · Manualidades +3%",
		"descripcion": "Doble monitor, iluminación LED y silla de competición.",
		"bonus_academico": 0.10,
		"bonus_manualidades": 0.03,
	},
	{
		"clave": "Biblioteca_Roble",
		"nombre": "Biblioteca de Roble",
		"categoria": "Estudio",
		"precio": 1700.0,
		"multiplicador": 1.0,
		"tier": "elite",
		"efecto": "Académico +14% · Manualidades +5%",
		"descripcion": "Biblioteca de suelo a techo con mesa de lectura y escalera.",
		"bonus_academico": 0.14,
		"bonus_manualidades": 0.05,
	},

	# ------------------------------------------------------------------ Cocina
	{
		"clave": "Cocina_Basica",
		"nombre": "Cocina Básica",
		"categoria": "Cocina",
		"precio": 0.0,
		"multiplicador": 1.0,
		"tier": "basico",
		"efecto": "Sin bonificación",
		"descripcion": "Encimera de pino, fogones y armarios blancos. Lo esencial.",
		"bonus_cocina": 0.0,
		"bonus_calidad_tupper": 0.0,
	},
	{
		"clave": "Cocina_Modular",
		"nombre": "Cocina Modular",
		"categoria": "Cocina",
		"precio": 170.0,
		"multiplicador": 1.0,
		"tier": "basico",
		"efecto": "Cocina +4%",
		"descripcion": "Módulos claros, encimera de cuarzo y buen orden.",
		"bonus_cocina": 0.04,
		"bonus_calidad_tupper": 0.0,
	},
	{
		"clave": "Cocina_Isla",
		"nombre": "Cocina con Isla",
		"categoria": "Cocina",
		"precio": 320.0,
		"multiplicador": 1.0,
		"tier": "premium",
		"efecto": "Cocina +6%",
		"descripcion": "Isla central con fregadero, taburetes y colgadores.",
		"bonus_cocina": 0.06,
		"bonus_calidad_tupper": 0.0,
	},
	{
		"clave": "Cocina_Chef",
		"nombre": "Cocina del Chef",
		"categoria": "Cocina",
		"precio": 680.0,
		"multiplicador": 1.0,
		"tier": "premium",
		"efecto": "Cocina +8% · Tupper +5%",
		"descripcion": "Fogones profesionales, horno doble y encimera de acero.",
		"bonus_cocina": 0.08,
		"bonus_calidad_tupper": 0.05,
	},
	{
		"clave": "Cocina_Pro",
		"nombre": "Cocina Pro",
		"categoria": "Cocina",
		"precio": 1150.0,
		"multiplicador": 1.0,
		"tier": "lujo",
		"efecto": "Cocina +10% · Tupper +8%",
		"descripcion": "Campana de acero, robot de cocina y despensa iluminada.",
		"bonus_cocina": 0.10,
		"bonus_calidad_tupper": 0.08,
	},
	{
		"clave": "Cocina_Industrial",
		"nombre": "Cocina Industrial",
		"categoria": "Cocina",
		"precio": 2100.0,
		"multiplicador": 1.0,
		"tier": "elite",
		"efecto": "Cocina +14% · Tupper +12%",
		"descripcion": "Acero inoxidable, fuego alto y espacio para cocinar en serie.",
		"bonus_cocina": 0.14,
		"bonus_calidad_tupper": 0.12,
	},
]

static var _datos_por_clave: Dictionary = {}


static func Registrar_En(catalogo: Dictionary) -> void:
	_datos_por_clave.clear()
	for datos in DATOS:
		var objeto := Objeto.new()
		var clave: String = str(datos.get("clave", ""))
		objeto.nombre = clave
		objeto.nombre_visible = str(datos.get("nombre", clave.replace("_", " ")))
		objeto.descripcion = str(datos.get("descripcion", ""))
		objeto.precio = float(datos.get("precio", 0.0))
		objeto.multiplicador = float(datos.get("multiplicador", 1.0))
		objeto.afecta_a = str(datos.get("categoria", ""))
		objeto.tier = str(datos.get("tier", "basico"))
		objeto.etiqueta_efecto = str(datos.get("efecto", ""))
		objeto.es_basico = objeto.precio <= 0.0
		objeto.bonus_progreso_deporte = float(datos.get("bonus_deporte", 0.0))
		objeto.bonus_progreso_academico = float(datos.get("bonus_academico", 0.0))
		objeto.bonus_progreso_manualidades = float(datos.get("bonus_manualidades", 0.0))
		objeto.bonus_progreso_cocina = float(datos.get("bonus_cocina", 0.0))
		objeto.bonus_calidad_tupper = float(datos.get("bonus_calidad_tupper", 0.0))
		catalogo[clave] = objeto
		_datos_por_clave[clave] = datos


static func Datos_De(clave: String) -> Dictionary:
	return _datos_por_clave.get(clave, {})


static func Categoria_De(clave: String) -> String:
	return str(Datos_De(clave).get("categoria", ""))


static func Categorias_Tienda() -> Array[Dictionary]:
	return CATEGORIAS


static func Categoria_Por_Id(id: String) -> Dictionary:
	for categoria in CATEGORIAS:
		if str(categoria.get("id", "")) == id:
			return categoria
	return {}


static func Claves_De_Categoria(id: String) -> Array[String]:
	var claves: Array[String] = []
	for datos in DATOS:
		if str(datos.get("categoria", "")) == id:
			claves.append(str(datos.get("clave", "")))
	return claves


static func Es_Categoria_De_Objetos(id: String) -> bool:
	return not Categoria_Por_Id(id).is_empty()
