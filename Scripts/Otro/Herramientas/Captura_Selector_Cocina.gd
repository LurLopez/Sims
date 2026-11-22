extends Node

# Herramienta de QA visual del selector de niveles de la cocina.
# Uso (con display, no headless):
#   godot --path . res://Escenas/Herramientas/Captura_Selector_Cocina.tscn

const DIR_SALIDA := "/tmp/opencode/capturas_selector"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(DIR_SALIDA)
	await get_tree().process_frame

	Variables_Dinamicas.Dinero = 842.0
	Variables_Dinamicas.Necesidades_Basicas = [80, 80, 80, 80, 80]
	Variables_Estaticas.Habilidades = [50, 50, 50, 50, 50, 50, 50]
	Variables_Dinamicas.Cocina_Estado = Variables_Dinamicas.Cocina_Estado_Por_Defecto()
	Variables_Dinamicas.Cocina_Estado["restaurantes_desbloqueados"] = ["burger_street"]
	Variables_Dinamicas.Cocina_Estado["fondos_cocina"] = 750
	Variables_Dinamicas.Cocina_Estado["estrellas_nivel"] = {
		"burger_street_1": 3,
		"burger_street_2": 3,
		"burger_street_3": 3,
		"burger_street_4": 3,
		"burger_street_5": 3,
		"burger_street_6": 3,
		"burger_street_7": 3,
		"burger_street_8": 3,
		"burger_street_9": 3,
		"burger_street_10": 3,
		"burger_street_11": 3,
		"burger_street_12": 1,
	}

	var ancho: int = int(OS.get_environment("CAPTURA_ANCHO")) if OS.get_environment("CAPTURA_ANCHO") != "" else 1280
	var alto: int = int(OS.get_environment("CAPTURA_ALTO")) if OS.get_environment("CAPTURA_ALTO") != "" else 720
	var vp := SubViewport.new()
	vp.size = Vector2i(ancho, alto)
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	var mini: Control = load("res://Escenas/Minijuego_Cocina/Minijuego_Cocina.tscn").instantiate()
	vp.add_child(mini)
	await get_tree().process_frame
	await get_tree().process_frame

	await _Capturar(vp, "selector_mundos.png")

	# Detalle de Maestría: progreso por estrellas y recompensas de cada rango.
	mini._Abrir_Modal_Maestria()
	await get_tree().create_timer(0.5).timeout
	await _Capturar(vp, "selector_maestria.png")
	mini._modal_maestria.visible = false

	mini._restaurante_actual = "burger_street"
	mini._restaurante_expandido = "burger_street"
	mini._Refrescar_Mapa()
	await get_tree().create_timer(1.1).timeout
	await _Capturar(vp, "selector_niveles.png")

	# Nivel bloqueado + modal de inicio para revisar la coherencia de la ficha.
	mini._Abrir_Modal_Inicio(7)
	await get_tree().process_frame
	await _Capturar(vp, "selector_modal_nivel.png")

	print("Capturas del selector guardadas en ", DIR_SALIDA)
	get_tree().quit()


func _Capturar(vp: SubViewport, nombre: String) -> void:
	await RenderingServer.frame_post_draw
	var imagen := vp.get_texture().get_image()
	if imagen != null and not imagen.is_empty():
		var ruta := DIR_SALIDA.path_join(nombre)
		imagen.save_png(ruta)
		print("Captura: ", ruta, " (", imagen.get_width(), "x", imagen.get_height(), ")")
