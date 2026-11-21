extends Node

# Herramienta de QA visual de la pantalla de Mejoras de Cocina.
# Uso:
#   godot --headless --path . res://Escenas/Herramientas/Captura_Mejoras_Cocina.tscn
#
# Genera una captura por mejora, además de los estados de Caja insuficiente,
# nivel máximo y compra recién realizada.

const DIR_SALIDA := "user://capturas_mejoras_cocina"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR_SALIDA))
	await get_tree().process_frame
	await _Preparar()
	await _Capturar_Mejora("plancha", "01_mejoras_plancha.png")
	await _Capturar_Mejora("emplatado", "02_mejoras_emplatado.png")
	await _Capturar_Mejora("termostato", "03_mejoras_termostato.png")
	await _Capturar_Mejora("ingredientes", "04_mejoras_ingredientes.png")
	await _Capturar_Mejora("ambiente", "05_mejoras_ambiente.png")
	await _Capturar_Sin_Caja()
	await _Capturar_Maximo()
	await _Capturar_Compra()
	print("Capturas de mejoras guardadas en ", ProjectSettings.globalize_path(DIR_SALIDA))
	get_tree().quit()


var _vp: SubViewport
var _mini: Control


func _Preparar() -> void:
	Variables_Dinamicas.Cocina_Estado = Variables_Dinamicas.Cocina_Estado_Por_Defecto()
	Variables_Dinamicas.Cocina_Estado["restaurantes_desbloqueados"] = ["burger_street"]
	Variables_Dinamicas.Cocina_Estado["fondos_cocina"] = 450
	Variables_Dinamicas.Cocina_Estado["rango_logro"] = 2
	Variables_Dinamicas.Cocina_Estado["estrellas_nivel"] = {
		"burger_street_1": 3, "burger_street_2": 2, "burger_street_3": 1
	}
	Variables_Dinamicas.Necesidades_Basicas = [80, 80, 80, 80, 80]
	Variables_Estaticas.Habilidades = [50, 50, 50, 50, 50, 50, 50]

	_vp = SubViewport.new()
	_vp.size = Vector2i(720, 1280)
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)

	_mini = load("res://Escenas/Minijuego_Cocina/Minijuego_Cocina.tscn").instantiate()
	_vp.add_child(_mini)
	await get_tree().process_frame
	await get_tree().process_frame
	_mini._restaurante_actual = "burger_street"
	_mini._restaurante_expandido = "burger_street"
	_mini._Refrescar_Mapa()
	await get_tree().process_frame


func _Capturar_Mejora(mejora_id: String, nombre: String) -> void:
	_mini._restaurante_actual = "burger_street"
	_mini._Abrir_Modal_Mejoras()
	var modal: Control = _mini._modal_mejoras
	if modal.has_method("seleccionar_mejora"):
		modal.call("seleccionar_mejora", mejora_id)
	await _Esperar(0.45)
	await _Guardar(nombre)


func _Capturar_Sin_Caja() -> void:
	Variables_Dinamicas.Cocina_Estado["fondos_cocina"] = 40
	var modal: Control = _mini._modal_mejoras
	modal.call("abrir", "burger_street")
	modal.call("seleccionar_mejora", "plancha")
	await _Esperar(0.35)
	await _Guardar("06_mejoras_sin_caja.png")


func _Capturar_Maximo() -> void:
	Variables_Dinamicas.Cocina_Estado["fondos_cocina"] = 900
	Variables_Dinamicas.Cocina_Estado["mejoras"]["burger_street"]["plancha"] = 3
	var modal: Control = _mini._modal_mejoras
	modal.call("abrir", "burger_street")
	modal.call("seleccionar_mejora", "plancha")
	await _Esperar(0.35)
	await _Guardar("07_mejoras_nivel_maximo.png")


func _Capturar_Compra() -> void:
	# Estado posterior a una compra real (el flujo de compra lo cubre el test
	# GUT); así la herramienta de QA no escribe en la partida del usuario.
	Variables_Dinamicas.Cocina_Estado["mejoras"]["burger_street"]["ambiente"] = 2
	Variables_Dinamicas.Cocina_Estado["fondos_cocina"] = 790
	var modal: Control = _mini._modal_mejoras
	modal.call("abrir", "burger_street")
	modal.call("seleccionar_mejora", "ambiente")
	await get_tree().process_frame
	modal.call("_Celebrar_Nivel", 2)
	await _Esperar(0.22)
	await _Guardar("08_mejoras_compra.png")


func _Esperar(segundos: float) -> void:
	await get_tree().create_timer(segundos).timeout
	await RenderingServer.frame_post_draw


func _Guardar(nombre: String) -> void:
	var imagen := _vp.get_texture().get_image()
	if imagen == null or imagen.is_empty():
		push_error("No se pudo capturar %s" % nombre)
		return
	var ruta := DIR_SALIDA.path_join(nombre)
	imagen.save_png(ruta)
	print("Captura: ", ruta, " (", imagen.get_width(), "x", imagen.get_height(), ")")
