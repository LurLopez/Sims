extends "res://Scripts/Logica/Escena_Principal/Actividades/Carreras/UI/Modal_Carrera_Base.gd"

# Test real del jugador dentro de la hora del examen.
#
# Mantiene la lógica original (10 preguntas, nota 0-100 y señal
# examen_enviado) pero cambia por completo la presentación: progreso fijo,
# tarjetas de pregunta táctiles con opciones A-D, aviso de respuestas
# pendientes y pantalla de resultado con la nota y el bonus que aporta.

const PREGUNTAS_PATH_BASE: String = "res://Scripts/Logica/Escena_Principal/Actividades/Carreras/Contenido/preguntas_%s.json"
const Anillo_Nota = preload("res://Scripts/Logica/Escena_Principal/Actividades/Carreras/UI/Anillo_Nota.gd")
const LETRAS := ["A", "B", "C", "D"]

var preguntas_seleccionadas: Array = []
var respuestas_seleccionadas: Array = []
var grupos_botones: Array = []
var carrera: Carrera = null

signal examen_enviado(nota_real: int)

var _preparado := false
var _enviado := false
var _aviso_enviado := false
var _error_preguntas := ""
var _color_acento := Estilos_UI.PRIMARIO

var _opciones_preguntas: Array = []
var _tarjetas_preguntas: Array = []
var _lbl_progreso: Label
var _lbl_estado_progreso: Label
var _barra_progreso: ProgressBar
var _panel_aviso: PanelContainer
var _lbl_aviso: Label
var _btn_enviar: Button
var _btn_salir: Button


func _Al_Listo() -> void:
	permitir_cerrar_al_fondo = false
	actualizar_cabecera("Examen", "Pon a prueba lo que has estudiado",
		"EVALUACIÓN", "notebook-pen")
	_Construir_Pie()
	if carrera != null:
		_Preparar_Examen()
	else:
		_Mostrar_Cargando()


func _Construir_Pie() -> void:
	if not pie.get_children().is_empty():
		return
	_btn_salir = Estilos_UI.boton("Salir", "secundario", "arrow-left", Estilos_UI.TINTA, 50)
	_btn_salir.custom_minimum_size = Vector2(112, 50)
	_btn_salir.pressed.connect(_Solicitar_Cierre)
	pie.add_child(_btn_salir)

	_btn_enviar = Estilos_UI.boton("Enviar respuestas", "primario", "circle-check",
		Estilos_UI.PRIMARIO, 50)
	_btn_enviar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_enviar.pressed.connect(_Al_Pulsar_Enviar)
	pie.add_child(_btn_enviar)


func Configurar(_carrera: Carrera) -> void:
	carrera = _carrera
	if carrera == null:
		return
	if is_node_ready():
		_Preparar_Examen()


func _Preparar_Examen() -> void:
	if _preparado or carrera == null:
		return
	_preparado = true
	_color_acento = color_carrera(carrera.nombre).darkened(0.06)
	var nombre := nombre_carrera(carrera.nombre)
	actualizar_cabecera(
		"Examen",
		"%s · Año %d de %d" % [nombre, carrera.año_actual, carrera.años_totales],
		"EVALUACIÓN · TEST DEL JUGADOR",
		"notebook-pen")

	if not _Verificar_Horario_Correcto():
		push_error("No es la hora del examen")
		_Mostrar_Error("La ventana de este examen ya no está abierta.")
		return

	_Cargar_Preguntas()
	if _error_preguntas != "":
		_Mostrar_Error(_error_preguntas)
		return
	_Construir_Examen()


func _Verificar_Horario_Correcto() -> bool:
	if carrera == null or carrera.hora_examen_dia < 0:
		return false
	var minuto_del_dia = Variables_Dinamicas.Minute_Minute
	var es_dia_examen: bool
	if Variables_Estaticas.Modo_Rapido:
		es_dia_examen = (Variables_Dinamicas.Minute_Day == carrera.hora_examen_dia)
	else:
		var dia_semana_actual = Variables_Dinamicas.Minute_Day % 7
		es_dia_examen = (dia_semana_actual == carrera.hora_examen_dia)
	if not es_dia_examen:
		return false
	var hora_inicio = carrera.hora_examen_inicio
	var hora_fin = hora_inicio + 60
	return minuto_del_dia >= hora_inicio and minuto_del_dia < hora_fin


func _Cargar_Preguntas() -> void:
	_error_preguntas = ""
	var ruta = PREGUNTAS_PATH_BASE % carrera.slug_contenido
	var contenido = FileAccess.get_file_as_string(ruta)
	if contenido == "":
		_error_preguntas = "No se pudieron cargar las preguntas de este examen."
		return
	var json = JSON.new()
	if json.parse(contenido) != OK:
		_error_preguntas = "Las preguntas de este examen no se pueden leer."
		return
	var datos = json.data
	var clave = "Anio_%d" % carrera.año_actual
	if not datos.has(clave):
		_error_preguntas = "Todavía no hay preguntas para este año."
		return
	var todas = datos[clave].duplicate()
	if todas.is_empty():
		_error_preguntas = "Todavía no hay preguntas para este año."
		return
	todas.shuffle()
	preguntas_seleccionadas = todas.slice(0, min(10, todas.size()))
	respuestas_seleccionadas.resize(preguntas_seleccionadas.size())
	for i in range(respuestas_seleccionadas.size()):
		respuestas_seleccionadas[i] = -1


# ----------------------------------------------------------------------------
# Construcción del examen
# ----------------------------------------------------------------------------

func _Limpiar(contenedor: Node) -> void:
	for hijo in contenedor.get_children():
		contenedor.remove_child(hijo)
		hijo.queue_free()


func _Mostrar_Cargando() -> void:
	_Limpiar(contenido)
	_Limpiar(area_fija)
	var lbl := Estilos_UI.parrafo("Preparando el examen…", 14, Estilos_UI.TINTA_SUAVE)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	contenido.add_child(lbl)


func _Mostrar_Error(mensaje: String) -> void:
	_Limpiar(contenido)
	_Limpiar(area_fija)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Color("#fff7ed"), 18, Color("#fed7aa"), 1, 1))
	contenido.add_child(card)
	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 22)
	margen.add_theme_constant_override("margin_right", 22)
	margen.add_theme_constant_override("margin_top", 26)
	margen.add_theme_constant_override("margin_bottom", 26)
	card.add_child(margen)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 12)
	margen.add_child(v)
	var badge := Estilos_UI.badge_icono("triangle-alert", 56, 27,
		Estilos_UI.AVISO_SUAVE, Estilos_UI.ORO, 16)
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(badge)
	var titulo := Estilos_UI.titulo("Examen no disponible", 21, Estilos_UI.TINTA)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(titulo)
	var texto := Estilos_UI.parrafo(mensaje, 14, Estilos_UI.TINTA_SUAVE)
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(texto)
	if _btn_enviar != null:
		_btn_enviar.visible = false
	if _btn_salir != null:
		_btn_salir.text = "Cerrar"
		_btn_salir.icon = Estilos_UI.icono("x")
		_btn_salir.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _Construir_Examen() -> void:
	_Limpiar(contenido)
	_Limpiar(area_fija)
	contenido.alignment = BoxContainer.ALIGNMENT_BEGIN
	contenido.custom_minimum_size.y = 0
	area_fija.visible = true
	_opciones_preguntas.clear()
	_tarjetas_preguntas.clear()
	grupos_botones.clear()
	_enviado = false
	_aviso_enviado = false

	area_fija.add_child(_Crear_Cabecera_Progreso())
	_Construir_Aviso()
	if _btn_enviar != null:
		_btn_enviar.visible = true
		_btn_enviar.text = "Enviar respuestas"
		_btn_enviar.icon = Estilos_UI.icono("circle-check")
		_btn_enviar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if not _btn_enviar.pressed.is_connected(_Al_Pulsar_Enviar):
			_btn_enviar.pressed.connect(_Al_Pulsar_Enviar)
	if _btn_salir != null:
		_btn_salir.visible = true
		_btn_salir.text = "Salir"
		_btn_salir.icon = Estilos_UI.icono("arrow-left")

	for i in range(preguntas_seleccionadas.size()):
		var tarjeta := _Crear_Tarjeta_Pregunta(i)
		_tarjetas_preguntas.append(tarjeta)
		contenido.add_child(tarjeta)

	_Actualizar_Progreso()
	scroll_principal.set_deferred("scroll_vertical", 0)


func _Crear_Cabecera_Progreso() -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Color("#f8f5ef"), 14, Color("#e8dfce"), 1, 0))
	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 14)
	margen.add_theme_constant_override("margin_right", 14)
	margen.add_theme_constant_override("margin_top", 11)
	margen.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margen)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 7)
	margen.add_child(v)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	v.add_child(fila)
	_lbl_estado_progreso = Estilos_UI.texto("Responde todas las preguntas",
		12, Estilos_UI.TINTA_SUAVE, 600)
	_lbl_estado_progreso.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(_lbl_estado_progreso)
	_lbl_progreso = Estilos_UI.texto("0 / %d" % preguntas_seleccionadas.size(),
		13, _color_acento, 700)
	fila.add_child(_lbl_progreso)

	_barra_progreso = ProgressBar.new()
	_barra_progreso.custom_minimum_size = Vector2(0, 10)
	_barra_progreso.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_barra_progreso.show_percentage = false
	_barra_progreso.max_value = maxi(preguntas_seleccionadas.size(), 1)
	_barra_progreso.value = 0
	_barra_progreso.add_theme_stylebox_override("background", Estilos_UI.barra_fondo())
	_barra_progreso.add_theme_stylebox_override("fill", Estilos_UI.barra_relleno(_color_acento))
	v.add_child(_barra_progreso)
	return card


func _Construir_Aviso() -> void:
	_panel_aviso = PanelContainer.new()
	_panel_aviso.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Estilos_UI.AVISO_SUAVE, 10, Color(Estilos_UI.AVISO, 0.28), 1, 0))
	_panel_aviso.visible = false
	area_fija.add_child(_panel_aviso)
	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 10)
	margen.add_theme_constant_override("margin_right", 10)
	margen.add_theme_constant_override("margin_top", 8)
	margen.add_theme_constant_override("margin_bottom", 8)
	_panel_aviso.add_child(margen)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	margen.add_child(fila)
	var ic := Estilos_UI.icono_rect("triangle-alert", 17, Estilos_UI.ORO)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(ic)
	_lbl_aviso = Estilos_UI.parrafo("", 12, Color("#92400e"))
	_lbl_aviso.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(_lbl_aviso)


func _Crear_Tarjeta_Pregunta(indice: int) -> Control:
	var pregunta: Dictionary = preguntas_seleccionadas[indice]
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Estilos_UI.SUPERFICIE, 16, Estilos_UI.BORDE, 1, 1))
	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 16)
	margen.add_theme_constant_override("margin_right", 16)
	margen.add_theme_constant_override("margin_top", 14)
	margen.add_theme_constant_override("margin_bottom", 15)
	card.add_child(margen)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 11)
	margen.add_child(v)

	var cabecera := HBoxContainer.new()
	cabecera.add_theme_constant_override("separation", 10)
	v.add_child(cabecera)

	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(32, 32)
	badge.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Color(_color_acento, 0.13), 999, Color(_color_acento, 0.18), 1, 0))
	cabecera.add_child(badge)
	var num := Estilos_UI.texto(str(indice + 1), 13, _color_acento.darkened(0.16), 700)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(num)

	var lbl_pregunta := Estilos_UI.texto(str(pregunta.get("pregunta", "")), 16, Estilos_UI.TINTA, 700)
	lbl_pregunta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_pregunta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_pregunta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cabecera.add_child(lbl_pregunta)

	var grupo := ButtonGroup.new()
	grupos_botones.append(grupo)
	var refs: Array = []
	var opciones: Array = pregunta.get("opciones", [])
	for j in range(opciones.size()):
		var ref := _Crear_Opcion(indice, j, str(opciones[j]), grupo)
		refs.append(ref)
		v.add_child(ref["btn"])
	_opciones_preguntas.append(refs)
	return card


func _Crear_Opcion(pregunta_idx: int, opcion_idx: int, texto_opcion: String,
		grupo: ButtonGroup) -> Dictionary:
	var btn := Button.new()
	btn.toggle_mode = true
	btn.button_group = grupo
	btn.custom_minimum_size = Vector2(0, 54)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.set_meta("_estilo_propio", true)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_Aplicar_Estilo_Opcion(btn)

	var fila := HBoxContainer.new()
	fila.set_anchors_preset(Control.PRESET_FULL_RECT)
	fila.offset_left = 11
	fila.offset_right = -12
	fila.offset_top = 8
	fila.offset_bottom = -8
	fila.add_theme_constant_override("separation", 10)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(fila)

	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(27, 27)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(badge)
	var letra := Estilos_UI.texto(LETRAS[opcion_idx] if opcion_idx < LETRAS.size() else "?",
		12, Estilos_UI.TINTA_SUAVE, 700)
	letra.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letra.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	letra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(letra)

	var lbl := Estilos_UI.texto(texto_opcion, 14, Estilos_UI.TINTA_SUAVE, 500)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(lbl)

	var check := Estilos_UI.icono_rect("circle-check", 18, _color_acento)
	check.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	check.visible = false
	fila.add_child(check)

	var ref := {
		"btn": btn,
		"badge": badge,
		"letra": letra,
		"texto": lbl,
		"check": check,
	}
	_Actualizar_Visual_Opcion(ref, false)
	btn.toggled.connect(_on_opcion_toggled.bind(pregunta_idx, opcion_idx))
	btn.button_down.connect(func(): btn.pivot_offset = btn.size * 0.5)
	Estilos_UI.animar_presion(btn)
	return ref


func _Aplicar_Estilo_Opcion(btn: Button) -> void:
	var normal := Estilos_UI.caja(Estilos_UI.SUPERFICIE, 12, Estilos_UI.BORDE, 1, 0)
	var hover := Estilos_UI.caja(Estilos_UI.SUPERFICIE_2, 12, Estilos_UI.BORDE_FUERTE, 1, 0)
	var pressed := Estilos_UI.caja(Color(_color_acento, 0.09), 12, _color_acento, 2, 0)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("hover_pressed", pressed)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("disabled", normal)


func _Actualizar_Visual_Opcion(ref: Dictionary, seleccionado: bool) -> void:
	var badge: PanelContainer = ref["badge"]
	var letra: Label = ref["letra"]
	var texto: Label = ref["texto"]
	var check: TextureRect = ref["check"]
	if seleccionado:
		badge.add_theme_stylebox_override("panel",
			Estilos_UI.caja(_color_acento, 999, _color_acento, 1, 0))
		letra.add_theme_color_override("font_color", Color.WHITE)
		texto.add_theme_color_override("font_color", Estilos_UI.TINTA)
		texto.add_theme_font_override("font", Estilos_UI.fuente_ui(600))
		check.visible = true
	else:
		badge.add_theme_stylebox_override("panel",
			Estilos_UI.caja(Estilos_UI.SUPERFICIE_2, 999, Estilos_UI.BORDE, 1, 0))
		letra.add_theme_color_override("font_color", Estilos_UI.TINTA_SUAVE)
		texto.add_theme_color_override("font_color", Estilos_UI.TINTA_SUAVE)
		texto.add_theme_font_override("font", Estilos_UI.fuente_ui(500))
		check.visible = false


func _on_opcion_toggled(activo: bool, pregunta_idx: int, opcion_idx: int) -> void:
	if not activo or pregunta_idx >= respuestas_seleccionadas.size():
		return
	respuestas_seleccionadas[pregunta_idx] = opcion_idx
	var refs: Array = _opciones_preguntas[pregunta_idx]
	for j in range(refs.size()):
		_Actualizar_Visual_Opcion(refs[j], j == opcion_idx)
	_Ocultar_Aviso()
	_Actualizar_Progreso()


func _Actualizar_Progreso() -> void:
	if _lbl_progreso == null:
		return
	var respondidas := 0
	for respuesta in respuestas_seleccionadas:
		if int(respuesta) >= 0:
			respondidas += 1
	var total := respuestas_seleccionadas.size()
	var completo := respondidas == total and total > 0
	var color := Estilos_UI.EXITO if completo else _color_acento
	_lbl_progreso.text = "%d / %d" % [respondidas, total]
	_lbl_progreso.add_theme_color_override("font_color", color)
	if _lbl_estado_progreso != null:
		_lbl_estado_progreso.text = "Todo listo para enviar" if completo else "Responde todas las preguntas"
		_lbl_estado_progreso.add_theme_color_override("font_color",
			Estilos_UI.EXITO_OSCURO if completo else Estilos_UI.TINTA_SUAVE)
	if _barra_progreso != null:
		Estilos_UI.animar_barra(_barra_progreso, respondidas, color)


func _Mostrar_Aviso(mensaje: String) -> void:
	if _panel_aviso == null:
		return
	_lbl_aviso.text = mensaje
	_panel_aviso.visible = true


func _Ocultar_Aviso() -> void:
	if _panel_aviso != null:
		_panel_aviso.visible = false
	_aviso_enviado = false


# ----------------------------------------------------------------------------
# Envío y resultado
# ----------------------------------------------------------------------------

func _Al_Pulsar_Enviar() -> void:
	if _enviado or preguntas_seleccionadas.is_empty():
		return
	var primera_sin_responder := -1
	var pendientes := 0
	for i in range(respuestas_seleccionadas.size()):
		if int(respuestas_seleccionadas[i]) < 0:
			pendientes += 1
			if primera_sin_responder < 0:
				primera_sin_responder = i
	if pendientes > 0 and not _aviso_enviado:
		_aviso_enviado = true
		_Mostrar_Aviso("Te quedan %d respuestas. Pulsa de nuevo para enviar así." % pendientes)
		if primera_sin_responder >= 0 and primera_sin_responder < _tarjetas_preguntas.size():
			scroll_principal.ensure_control_visible(_tarjetas_preguntas[primera_sin_responder])
		return

	var correctas := 0
	for i in range(preguntas_seleccionadas.size()):
		var correcta: int = int(preguntas_seleccionadas[i].get("respuesta_correcta", -1))
		if int(respuestas_seleccionadas[i]) == correcta:
			correctas += 1
	var total := preguntas_seleccionadas.size()
	var nota_real := int(round(float(correctas) * 100.0 / float(total)))
	if carrera != null:
		carrera.nota_real_ultima = nota_real
		carrera.examen_realizado_esta_semana = true

	_enviado = true
	_Mostrar_Resultado(nota_real, correctas, total)
	examen_enviado.emit(nota_real)


func _Mostrar_Resultado(nota: int, correctas: int, total: int) -> void:
	_Limpiar(contenido)
	contenido.alignment = BoxContainer.ALIGNMENT_CENTER
	contenido.custom_minimum_size.y = maxf(get_viewport().get_visible_rect().size.y - 230.0, 560.0)
	if area_fija != null:
		area_fija.visible = false
	_Ocultar_Aviso()

	var color := Estilos_UI.EXITO if nota >= 50 else Estilos_UI.AVISO
	var color_suave := Estilos_UI.EXITO_SUAVE if nota >= 50 else Estilos_UI.AVISO_SUAVE
	var titulo_txt := "¡Gran trabajo!"
	var subtitulo_txt := "Tu test suma un buen impulso a la nota final."
	var estado_txt := "Excelente test"
	if nota < 50:
		titulo_txt = "Examen enviado"
		subtitulo_txt = "Aun así suma puntos. El resultado oficial llegará al terminar la hora."
		estado_txt = "Puedes mejorar"
	elif nota < 80:
		titulo_txt = "Buen examen"
		subtitulo_txt = "Has demostrado una base sólida del temario."
		estado_txt = "Buen trabajo"

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Color("#fbfaf7"), 20, Color("#e8dfce"), 1, 1))
	contenido.add_child(card)
	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 18)
	margen.add_theme_constant_override("margin_right", 18)
	margen.add_theme_constant_override("margin_top", 20)
	margen.add_theme_constant_override("margin_bottom", 20)
	card.add_child(margen)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 13)
	margen.add_child(v)

	var pill := Estilos_UI.pill_estado(estado_txt, color_suave, color)
	pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(pill)

	var titulo := Estilos_UI.titulo(titulo_txt, 27, Estilos_UI.TINTA)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(titulo)

	var sub := Estilos_UI.parrafo(subtitulo_txt, 13, Estilos_UI.TINTA_SUAVE)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)

	var anillo_cont := Control.new()
	anillo_cont.custom_minimum_size = Vector2(166, 166)
	anillo_cont.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(anillo_cont)
	var anillo := Anillo_Nota.new(nota, color)
	anillo.set_anchors_preset(Control.PRESET_FULL_RECT)
	anillo_cont.add_child(anillo)
	var centro := VBoxContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.alignment = BoxContainer.ALIGNMENT_CENTER
	centro.add_theme_constant_override("separation", -2)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	anillo_cont.add_child(centro)
	var nota_lbl := Estilos_UI.titulo(str(nota), 42, color)
	nota_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	centro.add_child(nota_lbl)
	var cien := Estilos_UI.texto("sobre 100", 11, Estilos_UI.TINTA_FANTASMA, 600)
	cien.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	centro.add_child(cien)

	var aciertos := Estilos_UI.texto("Has acertado %d de %d preguntas" % [correctas, total],
		14, Estilos_UI.TINTA, 600)
	aciertos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(aciertos)

	var detalles := PanelContainer.new()
	detalles.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Estilos_UI.SUPERFICIE, 14, Estilos_UI.BORDE, 1, 0))
	v.add_child(detalles)
	var dm := MarginContainer.new()
	dm.add_theme_constant_override("margin_left", 14)
	dm.add_theme_constant_override("margin_right", 14)
	dm.add_theme_constant_override("margin_top", 12)
	dm.add_theme_constant_override("margin_bottom", 12)
	detalles.add_child(dm)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 9)
	dm.add_child(dv)
	dv.add_child(_Fila_Detalle("Nota del test", "%d / 100" % nota, color))
	dv.add_child(Estilos_UI.divisor_horizontal())
	dv.add_child(_Fila_Detalle("Bonus para la nota final", "+%.1f puntos" % (float(nota) * 0.1),
		Estilos_UI.EXITO_OSCURO))
	dv.add_child(Estilos_UI.divisor_horizontal())
	dv.add_child(_Fila_Detalle("Preguntas acertadas", "%d de %d" % [correctas, total],
		Estilos_UI.TINTA))

	var aviso := PanelContainer.new()
	aviso.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Estilos_UI.AZUL_SUAVE, 12, Color(Estilos_UI.AZUL, 0.18), 1, 0))
	v.add_child(aviso)
	var am := MarginContainer.new()
	am.add_theme_constant_override("margin_left", 12)
	am.add_theme_constant_override("margin_right", 12)
	am.add_theme_constant_override("margin_top", 10)
	am.add_theme_constant_override("margin_bottom", 10)
	aviso.add_child(am)
	var ah := HBoxContainer.new()
	ah.add_theme_constant_override("separation", 8)
	am.add_child(ah)
	var ai := Estilos_UI.icono_rect("info", 17, Estilos_UI.AZUL)
	ai.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ah.add_child(ai)
	var at := Estilos_UI.parrafo(
		"El resultado oficial se publicará al terminar la hora del examen. Tu test añade hasta un 10 % a la nota del personaje.",
		12, Estilos_UI.AZUL)
	at.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ah.add_child(at)

	if _btn_salir != null:
		_btn_salir.visible = false
	if _btn_enviar != null:
		_btn_enviar.visible = true
		_btn_enviar.text = "Cerrar"
		_btn_enviar.icon = Estilos_UI.icono("check")
		_btn_enviar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		Estilos_UI.aplicar_estilo_boton(_btn_enviar, "exito" if nota >= 50 else "oro")
		if _btn_enviar.pressed.is_connected(_Al_Pulsar_Enviar):
			_btn_enviar.pressed.disconnect(_Al_Pulsar_Enviar)
		if not _btn_enviar.pressed.is_connected(cerrar):
			_btn_enviar.pressed.connect(cerrar)

	scroll_principal.set_deferred("scroll_vertical", 0)


func _Fila_Detalle(etiqueta: String, valor: String, color: Color) -> Control:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	var l := Estilos_UI.texto(etiqueta, 13, Estilos_UI.TINTA_SUAVE, 500)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(l)
	var v := Estilos_UI.texto(valor, 13, color, 700)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fila.add_child(v)
	return fila


func _Solicitar_Cierre() -> void:
	if _enviado or not is_node_ready():
		cerrar()
		return
	var hay_respuestas := false
	for respuesta in respuestas_seleccionadas:
		if int(respuesta) >= 0:
			hay_respuestas = true
			break
	if not hay_respuestas:
		cerrar()
		return
	mostrar_confirmacion(
		"¿Salir del examen?",
		"Se perderán las respuestas marcadas y tu test no se enviará.",
		"Salir",
		cerrar)
