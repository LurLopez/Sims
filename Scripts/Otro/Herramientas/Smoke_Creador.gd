extends Node

# Comprobación rápida del creador de personaje: recorre los 6 pasos, pulsa
# opciones representativas y confirma la apariencia final.

const CREADOR := preload("res://Scripts/GUI/Menu/Creador_Personaje.gd")

var _vp: SubViewport
var _c: CanvasLayer
var _confirmada: Array = []


func _ready() -> void:
	await get_tree().process_frame
	_vp = SubViewport.new()
	_vp.size = Vector2i(720, 1280)
	add_child(_vp)
	_c = CREADOR.new()
	_vp.add_child(_c)
	_c.confirmado.connect(func(ap: Dictionary, _pos: Vector2): _confirmada.append(ap))
	await get_tree().process_frame
	await get_tree().process_frame

	# 1) Nombre + género + personalidad.
	_c._input_nombre.text = "Lucía"
	_c._input_nombre.text_changed.emit("Lucía")
	await _pulsar("Mujer")
	assert(_c._apariencia["genero"] == "mujer")
	assert(_c._apariencia["vello_facial"] == "ninguno")
	await _pulsar("Deportista")
	assert(_c._apariencia["personalidad"] == "Deportista")

	# 2) Estilos rápidos.
	await _pulsar("Elegante")
	assert(_c._apariencia["ropa_superior"] == "camisa")

	# 3) Recorrer todos los pasos y elegir opciones.
	_c._ir_a_paso(1)
	await get_tree().process_frame
	await _pulsar("Atlético")
	assert(_c._apariencia["complexion"] == "atletico")

	_c._ir_a_paso(2)
	await get_tree().process_frame
	await _pulsar("Redonda")
	assert(_c._apariencia["forma_cara"] == "redonda")

	_c._ir_a_paso(3)
	await get_tree().process_frame
	_c._scroll.scroll_vertical = 600
	await get_tree().process_frame
	await _pulsar("Bob flequillo")
	assert(_c._apariencia["estilo_pelo"] == "bob")
	# El scroll debe conservarse al cambiar una opción del mismo paso.
	assert(_c._scroll.scroll_vertical > 0)

	_c._ir_a_paso(4)
	await get_tree().process_frame
	assert(_c._scroll.scroll_vertical == 0)
	await _pulsar("Falda")
	assert(_c._apariencia["ropa_inferior"] == "falda")

	_c._ir_a_paso(5)
	await get_tree().process_frame
	await _pulsar("Con pecas")
	assert(bool(_c._apariencia["pecas"]))

	# 4) El atajo "Cambiar a Hombre" del paso Pelo desbloquea el vello facial.
	_c._ir_a_paso(3)
	await get_tree().process_frame
	await _pulsar("Cambiar a Hombre")
	assert(_c._apariencia["genero"] == "hombre")
	assert(_buscar_boton(_c._panel_contenido, "Barba corta") != null)

	# 5) Las pestañas llevan al paso correcto.
	_c._tab_botones["ropa"].pressed.emit()
	await get_tree().process_frame
	assert(_c._paso == 4)
	_c._tab_botones["identidad"].pressed.emit()
	await get_tree().process_frame
	assert(_c._paso == 0)

	# 6) Aleatorio conserva la personalidad.
	_c._on_aleatorio()
	await get_tree().process_frame
	assert(_c._apariencia["personalidad"] == "Deportista")

	# 6) Confirmar desde el último paso.
	_c._ir_a_paso(5)
	await get_tree().process_frame
	_c._paso_siguiente()
	await get_tree().process_frame
	assert(_confirmada.size() == 1)
	assert(_confirmada[0]["genero"] in ["hombre", "mujer"])
	print("SMOKE_CREADOR_OK apariencia=", _confirmada[0])
	get_tree().quit()


func _pulsar(texto: String) -> void:
	var btn := _buscar_boton(_c._panel_contenido, texto)
	if btn == null:
		push_error("No se encontró el botón '%s'" % texto)
		get_tree().quit(1)
		return
	btn.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame


func _buscar_boton(nodo: Node, texto: String) -> Button:
	for hijo in nodo.get_children():
		if hijo is Button:
			var b := hijo as Button
			if b.text == texto or str(b.get_meta("titulo", "")) == texto:
				return b
		var encontrado := _buscar_boton(hijo, texto)
		if encontrado != null:
			return encontrado
	return null
