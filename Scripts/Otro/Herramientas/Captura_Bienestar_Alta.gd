extends Node

# QA visual puntual: renderiza la escena principal en un SubViewport de
# 720x1600 (pantalla alargada) y guarda la pestaña Bienestar.

const ANCHO := 720
const ALTO := 1600
const DIR_SALIDA := "user://capturas_bienestar"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR_SALIDA))
	await get_tree().process_frame
	Variables_Estaticas.Tutorial_Completado = true
	Recompensas._ruta_guardado = "user://captura_bienestar_alta.cfg"
	var vp := SubViewport.new()
	vp.name = "Viewport_Alto"
	vp.size = Vector2i(ANCHO, ALTO)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var escena: Node = load("res://Escenas/Escena_Principal/Escena principal.tscn").instantiate()
	vp.add_child(escena)
	await get_tree().process_frame
	await get_tree().process_frame
	escena.set_process(false)
	escena.set_process_unhandled_input(false)
	escena._on_tienda_button_pressed()
	await get_tree().process_frame
	escena._on_tab_ventajas_pressed()
	await get_tree().create_timer(1.0).timeout
	var bienestar := escena.get_node_or_null("Tienda/Objetos_Ventajas") as Tienda_Bienestar
	if bienestar == null:
		get_tree().quit()
		return
	Variables_Dinamicas.Minute_Day = Variables_Estaticas.First_Time_Minute_Day + 140
	Variables_Dinamicas.Rejuvenecimiento_Anios = 3
	Variables_Dinamicas.Tratamientos_Rejuvenecimiento = 2
	Variables_Dinamicas.Dinero = 2450.0
	bienestar._Sincronizar(false)
	await get_tree().process_frame
	await _Capturar(vp, "bienestar_alta_01.png")
	bienestar._scroll.scroll_vertical = 900
	await get_tree().process_frame
	await get_tree().process_frame
	await _Capturar(vp, "bienestar_alta_02.png")
	print("Capturas altas guardadas")
	get_tree().quit()


func _Capturar(vp: SubViewport, nombre: String) -> void:
	await RenderingServer.frame_post_draw
	var imagen := vp.get_texture().get_image()
	if imagen != null and not imagen.is_empty():
		var ruta := DIR_SALIDA.path_join(nombre)
		imagen.save_png(ruta)
		print("Captura: ", ruta, " (", imagen.get_width(), "x", imagen.get_height(), ")")
