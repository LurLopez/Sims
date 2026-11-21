extends SceneTree
## Exporta variantes personalizadas del lockup con la cara del Sim guardado.
## Los assets oficiales de marca se generan con Arte_Fuente/Marca/generar_logo.py.
## Uso: godot --path . --script res://Scripts/Otro/Herramientas/Exportar_Logo_Marca.gd
##
## Salida: Imagenes/Marca/Personalizado/*.png (no sobrescribe los assets oficiales).

const DIR_SALIDA := "res://Imagenes/Marca/Personalizado"
const FONDO_ROJO := "res://Imagenes/Marca/Fondos/fondo_rojo_1024x240.png"
const FONDO_CLARO := "res://Imagenes/Marca/Fondos/fondo_claro_1024x240.png"
const FONDO_OSCURO := "res://Imagenes/Marca/Fondos/fondo_oscuro_1024x240.png"
const FONDO_FEATURE := "res://Imagenes/Marca/Fondos/fondo_rojo_1024x500.png"
const CREMA := Color("#f6f1e8")


func _initialize() -> void:
	call_deferred("_exportar")


func _exportar() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR_SALIDA))
	var guardar: Node = root.get_node_or_null("Guardar_Variables_Estaticas")
	if guardar != null:
		guardar.call("load_game")

	await _capturar_lockup("logo_horizontal_personalizado_1024x240.png",
		Vector2i(1024, 240), FONDO_ROJO, false)
	await _capturar_lockup("logo_horizontal_claro_personalizado_1024x240.png",
		Vector2i(1024, 240), FONDO_CLARO, true)
	await _capturar_lockup("logo_horizontal_oscuro_personalizado_1024x240.png",
		Vector2i(1024, 240), FONDO_OSCURO, false)
	await _capturar_feature("feature_graphic_personalizado_1024x500.png")

	print("Variantes personalizadas exportadas en: ", DIR_SALIDA)
	quit()


func _capturar_lockup(nombre: String, tam: Vector2i, fondo: String, claro: bool) -> void:
	var vp := _crear_viewport(tam)
	_add_fondo(vp, fondo, tam)
	var logo := _crear_logo(200, claro)
	logo.position = Vector2(172, 20)
	vp.add_child(logo)
	await _guardar(vp, nombre)


func _capturar_feature(nombre: String) -> void:
	var tam := Vector2i(1024, 500)
	var vp := _crear_viewport(tam)
	_add_fondo(vp, FONDO_FEATURE, tam)
	var logo := _crear_logo(300, false)
	logo.tamano_subtitulo = 31
	logo.position = Vector2(52, 100)
	vp.add_child(logo)
	await _guardar(vp, nombre)


func _add_fondo(vp: SubViewport, ruta: String, tam: Vector2i) -> void:
	var textura: Texture2D = load(ruta)
	if textura != null:
		var fondo := TextureRect.new()
		fondo.texture = textura
		fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fondo.stretch_mode = TextureRect.STRETCH_SCALE
		fondo.size = Vector2(tam)
		vp.add_child(fondo)
	else:
		var color := ColorRect.new()
		color.color = CREMA
		color.size = Vector2(tam)
		vp.add_child(color)


func _crear_viewport(tam: Vector2i) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = tam
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	return vp


func _crear_logo(insignia: int, claro: bool) -> Logo_Juego:
	var logo := Logo_Juego.new()
	logo.tamano_insignia = insignia
	logo.animar_retrato = false
	logo.variante_oscura = claro
	logo.subtitulo = "Simulador de vida en tiempo real"
	return logo


func _guardar(vp: SubViewport, nombre: String) -> void:
	for i in range(8):
		await process_frame
	var img := vp.get_texture().get_image()
	if img == null or img.is_empty():
		push_error("No se pudo capturar " + nombre)
		return
	var error := img.save_png(ProjectSettings.globalize_path(DIR_SALIDA.path_join(nombre)))
	if error != OK:
		push_error("No se pudo guardar %s (error %d)" % [nombre, error])
	else:
		print("Exportado: ", nombre, " ", img.get_size())
