extends Control

# ============================================================================
# Escenario estático de muestra del pack de sprites de Minijuego_Cocina.
# La escena se genera con tools/generar_escena_godot.py a partir del layout
# aprobado en Arte_Fuente/Minijuego_Cocina/escenario_preview.png.
# Aquí solo se añade una animación idle muy leve para revisar los sprites.
# ============================================================================

const TAMANO_HORIZONTAL := Vector2i(1280, 720)
const TAMANO_VERTICAL := Vector2i(720, 1280)

var _bases: Dictionary = {}
var _tiempo: float = 0.0
var _formato_aplicado: bool = false


func _ready() -> void:
	_Aplicar_Formato_Horizontal()
	for grupo in ["ticket", "chef", "vapor", "sparkle"]:
		for nodo in get_tree().get_nodes_in_group(grupo):
			if nodo is Control:
				_bases[nodo] = (nodo as Control).position
	set_process(true)
	if "--captura" in OS.get_cmdline_user_args():
		_capturar.call_deferred()


func _Aplicar_Formato_Horizontal() -> void:
	_formato_aplicado = true
	if DisplayServer.get_name() in ["android", "ios"]:
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
	var win := get_window()
	if win != null:
		win.content_scale_size = TAMANO_HORIZONTAL
	if OS.has_feature("pc") and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_size(TAMANO_HORIZONTAL)


func _Restaurar_Formato_Vertical() -> void:
	_formato_aplicado = false
	if DisplayServer.get_name() in ["android", "ios"]:
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	var win := get_window()
	if win != null:
		win.content_scale_size = TAMANO_VERTICAL
	if OS.has_feature("pc") and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_size(TAMANO_VERTICAL)


func _exit_tree() -> void:
	if _formato_aplicado:
		_Restaurar_Formato_Vertical()


func _capturar() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var ruta := OS.get_user_data_dir().path_join("escenario_cocina_godot.png")
	img.save_png(ruta)
	print("CAPTURA: ", ruta)
	get_tree().quit()


func _process(delta: float) -> void:
	_tiempo += delta
	for nodo in _bases.keys():
		if not is_instance_valid(nodo):
			_bases.erase(nodo)
			continue
		var c := nodo as Control
		var base: Vector2 = _bases[nodo]
		if c.is_in_group("ticket"):
			c.position = base + Vector2(0.0, sin(_tiempo * 1.6 + base.x * 0.012) * 2.5)
		elif c.is_in_group("chef"):
			c.position = base + Vector2(0.0, sin(_tiempo * 1.2) * 1.6)
		elif c.is_in_group("vapor"):
			c.position = base + Vector2(sin(_tiempo * 0.8 + base.x * 0.02) * 4.0, -fmod(_tiempo * 9.0 + base.x, 20.0))
			c.modulate.a = 0.30 + 0.14 * (0.5 + 0.5 * sin(_tiempo * 1.5 + base.x * 0.03))
		elif c.is_in_group("sparkle"):
			c.modulate.a = 0.55 + 0.35 * (0.5 + 0.5 * sin(_tiempo * 3.0))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
