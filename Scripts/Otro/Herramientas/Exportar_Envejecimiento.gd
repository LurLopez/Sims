extends SceneTree
## Genera una lámina de comparación del envejecimiento del personaje.
##
## Uso:
##   godot --path . --script res://Scripts/Otro/Herramientas/Exportar_Envejecimiento.gd
##
## Guarda el PNG en Funcionalidades/Personaje/Envejecimiento/Documentacion/Capturas/edades.png
## (y una copia en /tmp/opencode/envejecimiento.png para revisión rápida).

const RUTA_SALIDA := "res://Funcionalidades/Personaje/Envejecimiento/Documentacion/Capturas/edades.png"
const RUTA_TMP := "/tmp/opencode/envejecimiento.png"
const EDADES: Array[int] = [18, 30, 42, 52, 62, 72, 82]
const TAM_CELDA := Vector2i(230, 300)


func _initialize() -> void:
	call_deferred("_exportar")


func _exportar() -> void:
	var sep := 12
	var filas := 2
	var total := Vector2i(
		TAM_CELDA.x * EDADES.size() + sep * (EDADES.size() + 1),
		(TAM_CELDA.y + 46) * filas + sep * (filas + 1))
	var vp := SubViewport.new()
	vp.size = total
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)

	var fondo := ColorRect.new()
	fondo.color = Color("#eef2f7")
	fondo.size = Vector2(total)
	vp.add_child(fondo)

	for fila in range(filas):
		for i in range(EDADES.size()):
			var ap := Apariencia_Personaje.por_defecto()
			ap["genero"] = "hombre" if fila == 0 else "mujer"
			ap["color_pelo"] = "#432818" if fila == 0 else "#7c4728"
			ap["estilo_pelo"] = "corto" if fila == 0 else "media_melena"
			ap["color_ropa"] = "#2563eb"
			var retrato := Personaje_Visual.new(ap, "retrato" if fila == 0 else "retrato_cercano")
			retrato.edad = EDADES[i]
			retrato.expresion = "feliz"
			retrato.animar_idle = false
			retrato.margen_retrato = 4.0
			retrato.position = Vector2(sep + i * (TAM_CELDA.x + sep),
				sep + fila * (TAM_CELDA.y + 46) + 36)
			retrato.size = Vector2(TAM_CELDA)
			vp.add_child(retrato)

			var etiqueta := Label.new()
			etiqueta.text = "%d años · %s" % [EDADES[i], Envejecimiento_Personaje.etapa(EDADES[i])]
			etiqueta.position = Vector2(sep + i * (TAM_CELDA.x + sep),
				sep + fila * (TAM_CELDA.y + 46) + 6)
			etiqueta.size = Vector2(TAM_CELDA.x, 26)
			etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			etiqueta.add_theme_font_size_override("font_size", 16)
			etiqueta.add_theme_color_override("font_color", Color("#0f172a"))
			vp.add_child(etiqueta)

	for i in range(10):
		await process_frame

	var img := vp.get_texture().get_image()
	if img == null or img.is_empty():
		push_error("No se pudo renderizar la lámina de envejecimiento")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(RUTA_SALIDA.get_base_dir()))
	var error := img.save_png(ProjectSettings.globalize_path(RUTA_SALIDA))
	if error != OK:
		push_error("No se pudo guardar la lámina (%d)" % error)
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(RUTA_TMP.get_base_dir())
	img.save_png(RUTA_TMP)
	print("Lámina de envejecimiento exportada: ", RUTA_SALIDA)
	quit()
