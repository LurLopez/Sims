extends SceneTree
## Exporta el lockup de marca con la cara del Sim guardado.
## Uso: godot --path . --script res://Scripts/Otro/Herramientas/Exportar_Logo_Marca.gd

const DIR_SALIDA := "res://Imagenes/Marca"
const ROJO := Color("#d62828")
const ROJO_OSCURO := Color("#a81c1c")
const CREMA := Color("#f6f1e8")


func _initialize() -> void:
	call_deferred("_exportar")


func _exportar() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR_SALIDA))
	var guardar: Node = root.get_node_or_null("Guardar_Variables_Estaticas")
	if guardar != null:
		guardar.call("load_game")

	await _capturar_lockup("logo_horizontal_1024x240.png", Vector2i(1024, 240), 168, 62, 22, 18, true)
	await _capturar_lockup("logo_horizontal_claro_1024x240.png", Vector2i(1024, 240), 168, 62, 22, 18, false)
	await _capturar_feature_graphic()

	print("Logo de marca exportado en: ", DIR_SALIDA)
	quit()


func _capturar_lockup(nombre: String, tam: Vector2i, insignia: int, titulo: int,
		secundario: int, sub: int, fondo_rojo: bool) -> void:
	var vp := _crear_viewport(tam)
	if fondo_rojo:
		var banda := Estilos_UI.BannerRayasBitLife.new(ROJO, ROJO_OSCURO, 4.0, 0.065)
		banda.size = Vector2(tam)
		vp.add_child(banda)
	else:
		var fondo := ColorRect.new()
		fondo.color = CREMA
		fondo.size = Vector2(tam)
		vp.add_child(fondo)

	var centrar := CenterContainer.new()
	centrar.set_anchors_preset(Control.PRESET_FULL_RECT)
	vp.add_child(centrar)

	var logo := _crear_logo(insignia, titulo, secundario, sub, not fondo_rojo)
	centrar.add_child(logo)
	await _guardar(vp, nombre)


func _capturar_feature_graphic() -> void:
	var tam := Vector2i(1024, 500)
	var vp := _crear_viewport(tam)
	var banda := Estilos_UI.BannerRayasBitLife.new(ROJO, ROJO_OSCURO, 5.0, 0.065)
	banda.size = Vector2(tam)
	vp.add_child(banda)

	var centrar := CenterContainer.new()
	centrar.set_anchors_preset(Control.PRESET_FULL_RECT)
	vp.add_child(centrar)

	var logo := _crear_logo(210, 82, 26, 22, false)
	logo.tamano_subtitulo = 22
	centrar.add_child(logo)
	await _guardar(vp, "feature_graphic_1024x500.png")


func _crear_viewport(tam: Vector2i) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = tam
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	return vp


func _crear_logo(insignia: int, titulo: int, secundario: int, sub: int, sobre_claro: bool) -> Logo_Juego:
	var logo := Logo_Juego.new()
	logo.tamano_insignia = insignia
	logo.tamano_texto_principal = titulo
	logo.tamano_texto_secundario = secundario
	logo.tamano_subtitulo = sub
	logo.animar_retrato = false
	if sobre_claro:
		logo.color_texto = Estilos_UI.TINTA
		logo.color_subtitulo = Estilos_UI.TINTA_SUAVE
		logo.color_pill_fondo = Estilos_UI.ROJO_BIT
		logo.color_pill_texto = Color.WHITE
	return logo


func _guardar(vp: SubViewport, nombre: String) -> void:
	for i in range(5):
		await process_frame
	var img := vp.get_texture().get_image()
	if img == null or img.is_empty():
		push_error("No se pudo capturar " + nombre)
		return
	img.save_png(ProjectSettings.globalize_path(DIR_SALIDA.path_join(nombre)))
	print("Exportado: ", nombre, " ", img.get_size())
