extends SceneTree
## Genera los PNG que usa el preset de exportación Android a partir de los
## assets maestros de marca (PNG de alta resolución + SVG monocromo).
## Uso: godot --headless --path . --script res://Scripts/Otro/Herramientas/Generar_Iconos_Android.gd

const DIR_SALIDA := "res://Iconos_Android"
const ICONO := "res://Imagenes/Marca/logo_play_store_1024.png"
const MEDALLON := "res://Arte_Fuente/Marca/medallon_completo.png"
const MONOCROMO := "res://Arte_Fuente/Marca/monocromo.svg"
const FONDO := "res://Imagenes/Marca/Fondos/fondo_rojo_432.png"
const COLOR_FONDO_ADAPTATIVO := Color("#d62828")


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR_SALIDA))

	_exportar_png(ICONO, "icono_192.png", 192)
	_exportar_centrado(MEDALLON, "splash_icon_512.png", 512, 0.72)
	_exportar_centrado(MEDALLON, "icono_adaptativo_frente_432.png", 432, 0.60)
	_exportar_svg(MONOCROMO, "icono_monocromo_432.png", 432)
	_copiar_fondo(432, "icono_adaptativo_fondo_432.png")

	print("Iconos de Android generados en: ", DIR_SALIDA)
	quit()


func _exportar_png(ruta: String, nombre: String, tamano: int) -> void:
	var imagen := Image.load_from_file(ProjectSettings.globalize_path(ruta))
	if imagen == null or imagen.is_empty():
		push_error("No se pudo leer el PNG: " + ruta)
		return
	imagen.convert(Image.FORMAT_RGBA8)
	imagen.resize(tamano, tamano, Image.INTERPOLATE_LANCZOS)
	_guardar(imagen, nombre)


func _exportar_centrado(ruta: String, nombre: String, tamano: int, escala: float) -> void:
	var imagen := Image.load_from_file(ProjectSettings.globalize_path(ruta))
	if imagen == null or imagen.is_empty():
		push_error("No se pudo leer el PNG: " + ruta)
		return
	imagen.convert(Image.FORMAT_RGBA8)
	var interior := int(round(tamano * escala))
	imagen.resize(interior, interior, Image.INTERPOLATE_LANCZOS)
	var lienzo := Image.create(tamano, tamano, false, Image.FORMAT_RGBA8)
	lienzo.fill(Color(0, 0, 0, 0))
	lienzo.blit_rect(imagen, Rect2i(0, 0, interior, interior),
		Vector2i((tamano - interior) / 2, (tamano - interior) / 2))
	_guardar(lienzo, nombre)


func _exportar_svg(ruta: String, nombre: String, tamano: int) -> void:
	var svg := FileAccess.get_file_as_string(ruta)
	if svg.is_empty():
		push_error("No se pudo leer el SVG: " + ruta)
		return
	var imagen := Image.new()
	var escala := float(tamano) / 432.0
	var error := imagen.load_svg_from_string(svg, escala)
	if error != OK:
		push_error("No se pudo rasterizar el SVG %s (error %d)" % [ruta, error])
		return
	_guardar(imagen, nombre)


func _copiar_fondo(tamano: int, nombre: String) -> void:
	var imagen := Image.load_from_file(ProjectSettings.globalize_path(FONDO))
	if imagen != null and not imagen.is_empty():
		imagen.convert(Image.FORMAT_RGBA8)
		imagen.resize(tamano, tamano, Image.INTERPOLATE_LANCZOS)
		_guardar(imagen, nombre)
		return
	var lienzo := Image.create(tamano, tamano, false, Image.FORMAT_RGBA8)
	lienzo.fill(COLOR_FONDO_ADAPTATIVO)
	_guardar(lienzo, nombre)


func _guardar(imagen: Image, nombre: String) -> void:
	var ruta_salida := DIR_SALIDA.path_join(nombre)
	var error := imagen.save_png(ruta_salida)
	if error != OK:
		push_error("No se pudo guardar %s (error %d)" % [ruta_salida, error])
	else:
		print("Generado: ", ruta_salida, " ", imagen.get_size())
