extends SceneTree
## Genera los PNG que usa el preset de exportación Android a partir de los SVG.
## Uso: godot --headless --path . --script res://Scripts/Otro/Herramientas/Generar_Iconos_Android.gd

const DIR_SALIDA := "res://Iconos_Android"
const COLOR_FONDO_ADAPTATIVO := Color("#D62828")


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR_SALIDA))

	_exportar("res://icon.svg", "icono_192.png", 192)
	_exportar("res://Iconos_Android/icono_adaptativo_frente.svg", "icono_adaptativo_frente_432.png", 432)
	_exportar("res://Iconos_Android/icono_monocromo.svg", "icono_monocromo_432.png", 432)
	_exportar("res://icon.svg", "splash_icon_512.png", 512, 0.70)
	_crear_fondo_adaptativo(432, "icono_adaptativo_fondo_432.png")

	print("Iconos de Android generados en: ", DIR_SALIDA)
	quit()


func _exportar(ruta_svg: String, nombre: String, tamano: int, escala_contenido: float = 1.0) -> void:
	var svg := FileAccess.get_file_as_string(ruta_svg)
	if svg.is_empty():
		push_error("No se pudo leer el SVG: " + ruta_svg)
		return

	var imagen := Image.new()
	var error := imagen.load_svg_from_string(svg, float(tamano) / 128.0)
	if error != OK:
		push_error("No se pudo rasterizar el SVG %s (error %d)" % [ruta_svg, error])
		return

	if escala_contenido < 1.0:
		var interior := int(round(tamano * escala_contenido))
		imagen.resize(interior, interior, Image.INTERPOLATE_LANCZOS)
		var lienzo := Image.create(tamano, tamano, false, Image.FORMAT_RGBA8)
		lienzo.fill(Color(0, 0, 0, 0))
		lienzo.blit_rect(imagen, Rect2i(0, 0, interior, interior), Vector2i((tamano - interior) / 2, (tamano - interior) / 2))
		imagen = lienzo

	var ruta_salida := DIR_SALIDA.path_join(nombre)
	error = imagen.save_png(ruta_salida)
	if error != OK:
		push_error("No se pudo guardar %s (error %d)" % [ruta_salida, error])
	else:
		print("Generado: ", ruta_salida)


func _crear_fondo_adaptativo(tamano: int, nombre: String) -> void:
	var imagen := Image.create(tamano, tamano, false, Image.FORMAT_RGBA8)
	imagen.fill(COLOR_FONDO_ADAPTATIVO)
	var ruta_salida := DIR_SALIDA.path_join(nombre)
	var error := imagen.save_png(ruta_salida)
	if error != OK:
		push_error("No se pudo guardar %s (error %d)" % [ruta_salida, error])
	else:
		print("Generado: ", ruta_salida)
