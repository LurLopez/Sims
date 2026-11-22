extends GutTest
## Tests del catálogo ampliado de muebles y de sus bonificaciones.
##
## Cubre: integridad del catálogo, muebles básicos por categoría, compra/venta/
## equipado en categorías nuevas, multiplicadores de necesidades, bonus de
## progreso de Estudio y bonus de Cocina (progreso y calidad del tupper).

const RUTA_SAVE_DIN: String = "user://test_tienda_objetos_din.dat"

var _dinero: float
var _poseidos: Dictionary
var _seleccionados: Dictionary
var _progreso_cocina: int
var _tuppers: Array
var _tupper_idx: int
var _save_path: String


func before_each() -> void:
	_dinero = Variables_Dinamicas.Dinero
	_poseidos = Variables_Dinamicas.Objetos_Poseidos.duplicate(true)
	_seleccionados = Variables_Dinamicas.Objeto_Seleccionado.duplicate(true)
	_progreso_cocina = Variables_Dinamicas.Progreso_Cocina
	_tuppers = Variables_Dinamicas.Tuppers.duplicate(true)
	_tupper_idx = Variables_Dinamicas.Tupper_Seleccionado_Idx
	_save_path = Guardar_Variables_Dinamicas.save_path
	Guardar_Variables_Dinamicas.save_path = RUTA_SAVE_DIN
	Variables_Dinamicas.Dinero = 5000.0
	Variables_Dinamicas.Objetos_Poseidos = {
		"Cama_Basica": true,
		"Mesa_Basica": true,
		"Ducha_Basica": true,
		"Sofa_Basico": true,
		"Escritorio_Basico": true,
		"Cocina_Basica": true,
	}
	Variables_Dinamicas.Objeto_Seleccionado = {
		"Dormir": "Cama_Basica",
		"Comer": "Mesa_Basica",
		"Duchar": "Ducha_Basica",
		"Salon": "Sofa_Basico",
		"Estudio": "Escritorio_Basico",
		"Cocina": "Cocina_Basica",
	}
	Variables_Dinamicas.Progreso_Cocina = 50
	Variables_Dinamicas.Tuppers = []
	Variables_Dinamicas.Tupper_Seleccionado_Idx = -1


func after_each() -> void:
	Variables_Dinamicas.Dinero = _dinero
	Variables_Dinamicas.Objetos_Poseidos = _poseidos
	Variables_Dinamicas.Objeto_Seleccionado = _seleccionados
	Variables_Dinamicas.Progreso_Cocina = _progreso_cocina
	Variables_Dinamicas.Tuppers = _tuppers
	Variables_Dinamicas.Tupper_Seleccionado_Idx = _tupper_idx
	Guardar_Variables_Dinamicas.save_path = _save_path
	var ruta_abs: String = ProjectSettings.globalize_path(RUTA_SAVE_DIN)
	if FileAccess.file_exists(ruta_abs):
		DirAccess.remove_absolute(ruta_abs)


func test_catalogo_tiene_seis_categorias_y_seis_muebles_cada_una() -> void:
	assert_eq(Catalogo_Tienda.CATEGORIAS.size(), 6)
	for categoria in Catalogo_Tienda.CATEGORIAS:
		var id: String = str(categoria["id"])
		var claves := Catalogo_Tienda.Claves_De_Categoria(id)
		assert_eq(claves.size(), 6, "La categoría %s debe tener 6 muebles" % id)
		for clave in claves:
			assert_true(Variables_Estaticas.Catalogo_Objetos.has(clave),
				"Falta %s en Catalogo_Objetos" % clave)


func test_todas_las_ilustraciones_existen() -> void:
	for datos in Catalogo_Tienda.DATOS:
		var clave: String = str(datos.get("clave", ""))
		var ruta := "res://Imagenes/Tienda/Iconos/%s.png" % clave
		assert_true(ResourceLoader.exists(ruta),
			"Falta la ilustración de tienda para %s" % clave)


func test_cada_categoria_tiene_un_basico_gratis_y_poseible() -> void:
	for categoria in Catalogo_Tienda.CATEGORIAS:
		var clave_basica: String = str(categoria["basico"])
		assert_true(Variables_Estaticas.Catalogo_Objetos.has(clave_basica))
		var objeto: Objeto = Variables_Estaticas.Catalogo_Objetos[clave_basica]
		assert_eq(int(Variables_Estaticas.Obtener_Precio_Objeto(objeto)), 0)


func test_asegurar_basicos_rellena_categorias_nuevas() -> void:
	Variables_Dinamicas.Objetos_Poseidos = {}
	Variables_Dinamicas.Objeto_Seleccionado = {}
	Variables_Estaticas.Asegurar_Objetos_Basicos()
	for categoria in Catalogo_Tienda.CATEGORIAS:
		var id: String = str(categoria["id"])
		var clave_basica: String = str(categoria["basico"])
		assert_true(bool(Variables_Dinamicas.Objetos_Poseidos.get(clave_basica, false)),
			"Debe poseerse %s" % clave_basica)
		assert_eq(str(Variables_Dinamicas.Objeto_Seleccionado.get(id, "")), clave_basica)


func test_compra_y_equipado_en_salon() -> void:
	assert_true(Actividades.Comprar_Objeto("Sofa_Chester"))
	assert_eq(Variables_Dinamicas.Dinero, 4640.0)
	assert_true(bool(Variables_Dinamicas.Objetos_Poseidos.get("Sofa_Chester", false)))
	assert_true(Actividades.Seleccionar_Objeto("Salon", "Sofa_Chester"))
	assert_eq(str(Variables_Dinamicas.Objeto_Seleccionado.get("Salon", "")), "Sofa_Chester")


func test_multiplicadores_de_muebles_seleccionados() -> void:
	Variables_Dinamicas.Objeto_Seleccionado["Dormir"] = "Cama_Imperial"
	assert_almost_eq(
		Actividades_Necesidades_Basicas._Obtener_Multiplicador("Dormir"), 1.15, 0.0001)
	Variables_Dinamicas.Objeto_Seleccionado["Comer"] = "Mesa_Chef"
	assert_almost_eq(
		Actividades_Necesidades_Basicas._Obtener_Multiplicador("Comer_Tupper"), 1.15, 0.0001)
	Variables_Dinamicas.Objeto_Seleccionado["Salon"] = "Sofa_Imperial"
	assert_almost_eq(
		Actividades_Necesidades_Basicas._Obtener_Multiplicador("Ver_La_Television"), 1.16, 0.0001)


func test_bonus_de_estudio_y_cocina() -> void:
	Variables_Dinamicas.Objeto_Seleccionado["Estudio"] = "Biblioteca_Roble"
	assert_almost_eq(Variables_Estaticas.Obtener_Bonus_Progreso_Objeto(1), 0.14, 0.0001)
	assert_almost_eq(Variables_Estaticas.Obtener_Bonus_Progreso_Objeto(2), 0.05, 0.0001)
	Variables_Dinamicas.Objeto_Seleccionado["Cocina"] = "Cocina_Industrial"
	assert_almost_eq(Variables_Estaticas.Obtener_Bonus_Progreso_Cocina_Objeto(), 0.14, 0.0001)
	assert_almost_eq(Variables_Estaticas.Obtener_Bonus_Calidad_Tupper_Objeto(), 0.12, 0.0001)


func test_venta_respeta_seleccionado_y_ultimo_de_categoria() -> void:
	assert_false(Actividades.Vender_Objeto("Sofa_Basico"),
		"No se puede vender el único objeto de la categoría")
	assert_true(Actividades.Comprar_Objeto("Sofa_Chester"))
	assert_true(Actividades.Seleccionar_Objeto("Salon", "Sofa_Chester"))
	assert_false(Actividades.Vender_Objeto("Sofa_Chester"),
		"No se puede vender el objeto equipado")
	assert_true(Actividades.Seleccionar_Objeto("Salon", "Sofa_Basico"))
	var dinero_antes: float = Variables_Dinamicas.Dinero
	assert_true(Actividades.Vender_Objeto("Sofa_Chester"))
	assert_eq(Variables_Dinamicas.Dinero, dinero_antes + 180.0)


func test_calidad_del_tupper_usa_la_cocina_equipada() -> void:
	Variables_Dinamicas.Objeto_Seleccionado["Cocina"] = "Cocina_Industrial"
	var tupper: Dictionary = Alimentacion.Crear_Tupper()
	assert_eq(int(tupper.get("calidad", 0)), 56,
		"50 de Progreso_Cocina con +12% debe dar 56 de calidad")


func test_tienda_se_abre_desde_el_acceso_rapido_de_la_cabecera() -> void:
	var raiz = load("res://Escenas/Escena_Principal/Escena principal.tscn").instantiate()
	var btn_tienda := raiz.get_node_or_null("Tienda_Button") as Button
	assert_not_null(btn_tienda, "La escena conserva el botón Tienda por compatibilidad")
	raiz._Redisenar_Superior()
	assert_false(btn_tienda.visible,
		"La Tienda ya no debe ocupar una pestaña en la barra superior")

	var btn_header := raiz.get_node_or_null("Boton_Tienda_Header") as Button
	assert_not_null(btn_header, "La cabecera debe tener un acceso rápido a la Tienda")
	assert_true(btn_header.visible, "El icono de Tienda debe verse junto al dinero")
	assert_eq(btn_header.position.x, 460.0,
		"El icono de Tienda debe quedar junto al chip del dinero")
	assert_true(btn_header.pressed.is_connected(Callable(raiz, "_on_tienda_tab_pressed")),
		"Pulsar el icono debe abrir la pestaña Tienda")

	raiz._Crear_Pantalla_Economia()
	var pantalla_economia: Control = raiz.get_node_or_null("Pantalla_Economia")
	assert_not_null(pantalla_economia)
	var tiene_tarjeta_tienda := false
	for nodo in pantalla_economia.find_children("*", "Label", true, false):
		if (nodo as Label).text == "Tienda de objetos":
			tiene_tarjeta_tienda = true
			break
	assert_false(tiene_tarjeta_tienda,
		"Economía ya no debe contener la tarjeta de la Tienda")
	raiz.free()

