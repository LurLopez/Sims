extends Node

# Captura QA de La Granja (lienzo libre 24×24 con huellas reales multi-celda).
# Uso: xvfb-run -a godot --path . res://Escenas/Herramientas/Captura_Granja.tscn

const DIR_SALIDA := "user://capturas_granja"
const AHORA := 1760000000
const Datos := preload("res://Scripts/Logica/Escena_Principal/Granja/Datos_Granja.gd")

var _vp: SubViewport
var _granja: Control


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR_SALIDA))
	await get_tree().process_frame

	Sistema_Granja.Ahora_Forzado = AHORA
	Variables_Estaticas.Modo_Rapido = false
	Variables_Dinamicas.Dinero = 1234.0
	Variables_Dinamicas.Granja_Estado = Sistema_Granja.Estado_Por_Defecto()
	Sistema_Granja.Comprar()

	var estado: Dictionary = Sistema_Granja.Estado()
	estado["Monedas"] = 950
	estado["Convertido_Hoy"] = 0
	estado["Dia_Conversion"] = Sistema_Granja.Dia_Granja()
	estado["Almacen"] = {"trigo": 4, "maiz": 2, "huevo": 2, "harina": 2, "leche": 2}
	estado["Nivel_Terreno"] = 1  # Prado 16×14 (x: 4..19, y: 5..18)

	# Distribución rica mostrando todas las huellas reales (4×4, 4×3, 3×3, 2×2)
	# y todas las animaciones activas (aspas, horno encendido + humo, burbujeo, vaca, gallina, cultivos en 4 fases).
	estado["Objetos"] = [
		{
			"id": 1, "categoria": "maquina", "tipo": "molino",
			"x": 5, "y": 5, "ancho": 4, "alto": 4, "rotado": false, "volteado": false,
			"cultivo": "", "alimentado": false,
			"inicio_en": AHORA - 3600, "fin_en": AHORA + 3600, "coste_pagado": 250,
		},
		{
			"id": 2, "categoria": "maquina", "tipo": "panaderia",
			"x": 10, "y": 5, "ancho": 4, "alto": 3, "rotado": false, "volteado": false,
			"cultivo": "", "alimentado": false,
			"inicio_en": AHORA - 4200, "fin_en": AHORA + 6600, "coste_pagado": 500,
		},
		{
			"id": 3, "categoria": "maquina", "tipo": "queseria",
			"x": 15, "y": 6, "ancho": 3, "alto": 3, "rotado": false, "volteado": false,
			"cultivo": "", "alimentado": false,
			"inicio_en": AHORA - 8000, "fin_en": AHORA + 6400, "coste_pagado": 700,
		},
		{
			"id": 4, "categoria": "animal", "tipo": "vaca",
			"x": 5, "y": 10, "ancho": 3, "alto": 3, "rotado": false, "volteado": false,
			"cultivo": "", "alimentado": true,
			"inicio_en": AHORA - 22000, "fin_en": AHORA - 100, "coste_pagado": 350,
		},
		{
			"id": 5, "categoria": "animal", "tipo": "gallina",
			"x": 9, "y": 10, "ancho": 2, "alto": 2, "rotado": false, "volteado": false,
			"cultivo": "", "alimentado": true,
			"inicio_en": AHORA - 5000, "fin_en": AHORA + 9400, "coste_pagado": 150,
		},
		{
			"id": 6, "categoria": "tierra", "tipo": "tierra",
			"x": 12, "y": 10, "ancho": 2, "alto": 2, "rotado": false, "volteado": false,
			"cultivo": "trigo", "alimentado": false,
			"inicio_en": AHORA - 8000, "fin_en": AHORA - 200, "coste_pagado": 40,
		},
		{
			"id": 7, "categoria": "tierra", "tipo": "tierra",
			"x": 14, "y": 10, "ancho": 2, "alto": 2, "rotado": false, "volteado": false,
			"cultivo": "zanahoria", "alimentado": false,
			"inicio_en": AHORA - 15000, "fin_en": AHORA - 100, "coste_pagado": 40,
		},
		{
			"id": 8, "categoria": "tierra", "tipo": "tierra",
			"x": 16, "y": 10, "ancho": 2, "alto": 2, "rotado": false, "volteado": false,
			"cultivo": "maiz", "alimentado": false,
			"inicio_en": AHORA - 22000, "fin_en": AHORA - 50, "coste_pagado": 40,
		},
		{
			"id": 9, "categoria": "tierra", "tipo": "tierra",
			"x": 12, "y": 12, "ancho": 2, "alto": 2, "rotado": false, "volteado": false,
			"cultivo": "trigo", "alimentado": false,
			"inicio_en": AHORA - 3600, "fin_en": AHORA + 3600, "coste_pagado": 40,
		},
		{
			"id": 10, "categoria": "tierra", "tipo": "tierra",
			"x": 14, "y": 12, "ancho": 2, "alto": 2, "rotado": false, "volteado": false,
			"cultivo": "maiz", "alimentado": false,
			"inicio_en": AHORA - 3000, "fin_en": AHORA + 18600, "coste_pagado": 40,
		},
		{
			"id": 11, "categoria": "tierra", "tipo": "tierra",
			"x": 16, "y": 12, "ancho": 2, "alto": 2, "rotado": false, "volteado": false,
			"cultivo": "", "alimentado": false,
			"inicio_en": 0, "fin_en": 0, "coste_pagado": 40,
		},
	]
	estado["Siguiente_Id"] = 12

	_vp = SubViewport.new()
	_vp.size = Vector2i(1280, 720)
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	_granja = load("res://Escenas/Granja/Granja.tscn").instantiate()
	_vp.add_child(_granja)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout
	await _Capturar("granja_01_principal.png")

	# Captura del modo colocación fantasma (Molino 4×4 sobre el terreno!).
	_granja.call("_Iniciar_Colocacion", "maquina", "molino")
	await get_tree().create_timer(0.3).timeout
	await _Capturar("granja_10_colocar_ghost.png")
	_granja.call("_Establecer_Modo", "normal")

	# Captura del modo vender (50 %).
	_granja.call("_Establecer_Modo_Vender", true)
	await get_tree().create_timer(0.25).timeout
	await _Capturar("granja_09_modo_vender.png")
	_granja.call("_Establecer_Modo_Vender", false)

	# Captura de la barra rápida de siembra (incluyendo semilla activa en modo siembra rápida).
	_granja.call("_Abrir_Selector_Semilla", 11)
	_granja.set("_semilla_activa", "zanahoria")
	_granja.call("_Establecer_Modo", "sembrar")
	_granja.call("_Refrescar_Barra_Siembra")
	await get_tree().create_timer(0.3).timeout
	await _Capturar("granja_02_sembrar.png")
	_granja.call("_Establecer_Modo", "normal")

	# Captura del modal de conversión (Cobrar) y del nuevo modal de Ingresar € -> MG (1:1).
	_granja.call("_Abrir_Conversion", "cobrar")
	await get_tree().create_timer(0.3).timeout
	await _Capturar("granja_03_cobrar.png")
	_granja.call("_Abrir_Conversion", "ingresar")
	await get_tree().create_timer(0.3).timeout
	await _Capturar("granja_13_ingresar.png")
	_granja.call("_Cerrar_Modal")

	# Captura de la tienda con badges visuales de huella (2×2, 3×3, 4×3, 4×4).
	_granja.call("_Abrir_Tienda", "todo")
	await get_tree().create_timer(0.3).timeout
	await _Capturar("granja_04_tienda.png")
	_granja.call("_Cerrar_Modal")

	# Captura de mejoras con barra visual de expansión del prado.
	_granja.call("_Abrir_Mejoras")
	await get_tree().create_timer(0.3).timeout
	await _Capturar("granja_05_mejoras.png")
	_granja.call("_Cerrar_Modal")

	# Captura del inspector contextual flotante (tocando la Panadería en marcha).
	_granja.call("_Abrir_Inspector", 2)
	await get_tree().create_timer(0.25).timeout
	await _Capturar("granja_11_inspector.png")
	_granja.call("_Cerrar_Inspector")

	# Captura del almacén con los nuevos iconos ilustrados.
	_granja.call("_Abrir_Almacen")
	await get_tree().create_timer(0.25).timeout
	await _Capturar("granja_12_almacen.png")
	_granja.call("_Cerrar_Modal")

	print("Capturas de granja en ", ProjectSettings.globalize_path(DIR_SALIDA))
	get_tree().quit()


func _Capturar(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	var imagen := _vp.get_texture().get_image()
	if imagen == null or imagen.is_empty():
		push_error("No se pudo capturar %s" % nombre)
		return
	var ruta := DIR_SALIDA.path_join(nombre)
	var error := imagen.save_png(ruta)
	if error != OK:
		push_error("Error %d guardando %s" % [error, ruta])
	else:
		print("Captura: ", ruta)
