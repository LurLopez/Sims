extends Control

# Panel vertical de la Carrera de Futbolista (720x1280, Modo Normal y Rápido).
# Se instancia desde Escena principal.tscn y se muestra como overlay a pantalla
# completa. Toda la lógica vive en Sistema_Futbol / Simulador_Futbol.

signal cerrado

const COLOR_FUTBOL := Color(0.2, 0.6, 0.86)
const COLOR_PARTIDO := Color(0.15, 0.75, 0.35)

var _contenido: VBoxContainer
var _scroll: ScrollContainer
var _refrescando: bool = false
var _dialogo_info: AcceptDialog = null
var _dialogo_rescision: ConfirmationDialog = null
var _dialogo_fichaje: ConfirmationDialog = null


func _ready() -> void:
	z_index = 100
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_Construir()
	_Refrescar()
	get_viewport().size_changed.connect(_Ajustar)
	_Ajustar()


func _Ajustar() -> void:
	if _scroll != null:
		_scroll.offset_top = 86.0
		_scroll.offset_bottom = -14.0


func Refrescar() -> void:
	_Refrescar()


func _Construir() -> void:
	var fondo := ColorRect.new()
	fondo.color = Estilos_UI.FONDO
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)

	var cabecera := Panel.new()
	cabecera.set_anchors_preset(Control.PRESET_TOP_WIDE)
	cabecera.offset_bottom = 76.0
	cabecera.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cabecera.add_theme_stylebox_override("panel", Estilos_UI.caja(
		Estilos_UI.SUPERFICIE, 0, Estilos_UI.BORDE, 0, 1))
	add_child(cabecera)

	var btn_volver := Estilos_UI.boton_icono("arrow-left", Estilos_UI.TINTA, 42)
	btn_volver.position = Vector2(18, 17)
	btn_volver.size = Vector2(42, 42)
	btn_volver.tooltip_text = "Volver"
	btn_volver.pressed.connect(_on_volver)
	cabecera.add_child(btn_volver)

	var titulo := Estilos_UI.titulo("Carrera futbolística", 22, Estilos_UI.TINTA)
	titulo.position = Vector2(72, 12)
	titulo.size = Vector2(620, 30)
	cabecera.add_child(titulo)

	var subtitulo := Estilos_UI.texto("Fútbol · Fase 1 (Modo Jugador)", 12, Estilos_UI.TINTA_SUAVE, 600)
	subtitulo.position = Vector2(72, 41)
	subtitulo.size = Vector2(620, 20)
	cabecera.add_child(subtitulo)

	_scroll = ScrollContainer.new()
	_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scroll.offset_left = 0.0
	_scroll.offset_right = 0.0
	_scroll.offset_top = 86.0
	_scroll.offset_bottom = -14.0
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(_scroll)

	var margen := MarginContainer.new()
	margen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margen.add_theme_constant_override("margin_left", 18)
	margen.add_theme_constant_override("margin_right", 18)
	margen.add_theme_constant_override("margin_top", 12)
	margen.add_theme_constant_override("margin_bottom", 24)
	_scroll.add_child(margen)

	_contenido = VBoxContainer.new()
	_contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_contenido.add_theme_constant_override("separation", 12)
	margen.add_child(_contenido)


func _Limpiar_Contenido() -> void:
	for hijo in _contenido.get_children():
		_contenido.remove_child(hijo)
		hijo.queue_free()


func _Tarjeta() -> VBoxContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(16, 2))
	_contenido.add_child(card)
	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 18)
	margen.add_theme_constant_override("margin_right", 18)
	margen.add_theme_constant_override("margin_top", 16)
	margen.add_theme_constant_override("margin_bottom", 16)
	card.add_child(margen)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	margen.add_child(v)
	return v


func _Refrescar(ir_al_inicio: bool = false) -> void:
	if _contenido == null:
		return
	var scroll_previo: int = _scroll.scroll_vertical if _scroll != null and not ir_al_inicio else 0
	_Refrescando_UI(true)
	_Limpiar_Contenido()

	var activa: bool = Sistema_Futbol.Carrera_Activa()
	_Cabecera_Hero(activa)
	if activa:
		_Seccion_Club()
		_Seccion_Barras()
		_Seccion_Estadisticas()
		if not Variables_Estaticas.Modo_Rapido and Variables_Dinamicas.Minute_Day % 7 == 6:
			_Seccion_Liga()
		_Seccion_Asistencia()
		_Boton_Rescindir()
	else:
		_Seccion_Sin_Club()

	_Refrescando_UI(false)
	if _scroll != null:
		if ir_al_inicio:
			_scroll.set_deferred("scroll_vertical", 0)
		elif scroll_previo > 0:
			_scroll.set_deferred("scroll_vertical", scroll_previo)


func _Refrescando_UI(valor: bool) -> void:
	_refrescando = valor


func _Cabecera_Hero(activa: bool) -> void:
	var card := PanelContainer.new()
	var st := Estilos_UI.caja_tarjeta(18, 3)
	st.bg_color = Estilos_UI.SUPERFICIE
	card.add_theme_stylebox_override("panel", st)
	_contenido.add_child(card)

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 18)
	margen.add_theme_constant_override("margin_right", 18)
	margen.add_theme_constant_override("margin_top", 18)
	margen.add_theme_constant_override("margin_bottom", 18)
	card.add_child(margen)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	margen.add_child(fila)

	fila.add_child(Estilos_UI.badge_icono("trophy", 54, 27, COLOR_FUTBOL, Color.WHITE, 14))

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 3)
	fila.add_child(col)

	var titulo_txt: String = "Sin club" if not activa else Sistema_Futbol.Obtener_Nombre_Division()
	col.add_child(Estilos_UI.titulo(titulo_txt, 20, Estilos_UI.TINTA))
	var subtitulo: String = "Ficha disponible para la 3ª División Regional"
	if activa:
		subtitulo = "%d años · %s" % [
			Variables_Estaticas.Calcular_Edad(),
			Sistema_Futbol.Obtener_Estado_Legible()]
	col.add_child(Estilos_UI.texto(subtitulo, 13, Estilos_UI.TINTA_SUAVE, 600))

	if activa:
		var color_estado: Color = _Color_Estado()
		var pill := Estilos_UI.pill_estado(
			Sistema_Futbol.Obtener_Estado_Legible(), Color(color_estado, 0.15), color_estado)
		pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(pill)


func _Seccion_Sin_Club() -> void:
	var req: Dictionary = Sistema_Futbol.Cumple_Requisitos_Fichaje()
	var v := _Tarjeta()
	v.add_child(Estilos_UI.titulo("Prueba de fichaje", 17, Estilos_UI.TINTA))
	v.add_child(Estilos_UI.parrafo(
		"Los ojeadores buscan jugadores jóvenes con nivel deportivo. Supera los requisitos y firma tu primer contrato profesional.",
		13, Estilos_UI.TINTA_SUAVE))

	v.add_child(Estilos_UI.divisor_horizontal())
	_Fila_Requisito(v, "Deporte", "%d / %d" % [int(req.get("deporte", 0)),
		int(req.get("requisito_deporte", 25))], bool(req.get("cumple_deporte", false)))
	_Fila_Requisito(v, "Edad", "%d años (menos de %d)" % [int(req.get("edad", 18)),
		int(req.get("requisito_edad", 30))], bool(req.get("cumple_edad", false)))

	var nota: String = ""
	var retirado: bool = str(Variables_Dinamicas.Carrera_Futbol.get(
		"Estado_Temporada", "")) == "Retirado"
	match str(Variables_Dinamicas.Carrera_Futbol.get("Estado_Temporada", "")):
		"Despedido":
			nota = "Tu último club te despidió. Puedes volver a empezar desde la 3ª División."
		"Rescindido":
			nota = "Rescindiste tu contrato anterior. Puedes firmar de nuevo si sigues cumpliendo los requisitos."
		"Retirado":
			nota = "Te has retirado como futbolista. Ya no puedes volver a fichar: tu carrera continúa en «El Mánager»."
	if nota != "":
		v.add_child(Estilos_UI.parrafo(nota, 12, Estilos_UI.AVISO if retirado else Estilos_UI.TINTA_SUAVE))

	var btn := Estilos_UI.boton("Realizar prueba de fichaje", "exito", "trophy", Estilos_UI.EXITO, 54)
	btn.disabled = retirado or not bool(req.get("cumple", false))
	btn.pressed.connect(_Intentar_Fichar)
	v.add_child(btn)
	if retirado:
		v.add_child(Estilos_UI.texto(
			"Tu legado como futbolista te permite fundar un club en el apartado Minijuegos.",
			12, Estilos_UI.TINTA_FANTASMA))
	elif not bool(req.get("cumple", false)):
		v.add_child(Estilos_UI.texto(
			"Mejora tu Deporte o espera a cumplir los requisitos para poder fichar.",
			12, Estilos_UI.TINTA_FANTASMA))


func _Seccion_Club() -> void:
	var v := _Tarjeta()
	v.add_child(Estilos_UI.titulo("Contrato y rutina", 17, Estilos_UI.TINTA))
	_Fila_Dato(v, "División", Sistema_Futbol.Obtener_Nombre_Division())
	var salario: int = Sistema_Futbol.Obtener_Salario_Semanal()
	var salario_txt: String = "%d € / semana" % salario
	if Variables_Estaticas.Modo_Rapido:
		salario_txt = "%d € / día (modo rápido)" % int(round(
			salario * Variables_Estaticas.Multiplicador_Precios()))
	_Fila_Dato(v, "Salario", salario_txt, Estilos_UI.EXITO)
	_Fila_Dato(v, "Entrenamientos", Sistema_Futbol.Obtener_Resumen_Entrenamiento())
	_Fila_Dato(v, "Partidos", Sistema_Futbol.Obtener_Resumen_Partidos())
	if Sistema_Futbol.Hay_Conflicto_Ascenso_Pendiente():
		var datos: Dictionary = Sistema_Futbol.Obtener_Datos_Conflicto_Ascenso()
		var aviso := Estilos_UI.parrafo(
			"Ascenso a %s pendiente de decisión por conflicto con tu trabajo." %
			str(datos.get("nombre_destino", "")), 12, Estilos_UI.AVISO)
		v.add_child(aviso)


func _Seccion_Barras() -> void:
	var v := _Tarjeta()
	v.add_child(Estilos_UI.titulo("Forma deportiva", 17, Estilos_UI.TINTA))
	var deporte: float = float(Variables_Dinamicas.Progreso[0]) if Variables_Dinamicas.Progreso.size() > 0 else 1.0
	_Barra(v, "Progreso de Deporte", deporte, COLOR_FUTBOL)
	var relacion: float = float(Variables_Dinamicas.Carrera_Futbol.get("Relacion_Entrenador", 50.0))
	_Barra(v, "Relación con el entrenador", relacion, _Color_Relacion(relacion))
	var condicion: float = Sistema_Futbol.Obtener_Condicion_Fisica()
	_Barra(v, "Condición física actual", condicion, Estilos_UI.color_valor(condicion))
	if Sistema_Futbol.Esta_Lesionado():
		v.add_child(Estilos_UI.parrafo(
			"Lesión deportiva activa: no serás convocado hasta que te recuperes.",
			12, Estilos_UI.PELIGRO))


func _Seccion_Estadisticas() -> void:
	var v := _Tarjeta()
	v.add_child(Estilos_UI.titulo("Estadísticas de carrera", 17, Estilos_UI.TINTA))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	v.add_child(grid)

	grid.add_child(_Chip_Estadistica("Partidos", str(int(
		Variables_Dinamicas.Carrera_Futbol.get("Partidos_Jugados", 0))), Estilos_UI.AZUL))
	grid.add_child(_Chip_Estadistica("Goles", str(int(
		Variables_Dinamicas.Carrera_Futbol.get("Goles_Totales", 0))), Estilos_UI.EXITO))
	grid.add_child(_Chip_Estadistica("Asistencias", str(int(
		Variables_Dinamicas.Carrera_Futbol.get("Asistencias_Totales", 0))), Estilos_UI.ORO))
	grid.add_child(_Chip_Estadistica("Temporadas", str(int(
		Variables_Dinamicas.Carrera_Futbol.get("Temporadas_Jugadas", 0))), Estilos_UI.MORADO))
	grid.add_child(_Chip_Estadistica("Títulos", str(int(
		Variables_Dinamicas.Carrera_Futbol.get("Titulos_Superliga", 0))), Estilos_UI.PRIMARIO))


func _Chip_Estadistica(nombre: String, valor: String, color: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", Estilos_UI.caja(
		Color(color, 0.08), 12, Color(color, 0.18), 1, 0))
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 12)
	m.add_theme_constant_override("margin_right", 12)
	m.add_theme_constant_override("margin_top", 10)
	m.add_theme_constant_override("margin_bottom", 10)
	p.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	m.add_child(v)
	v.add_child(Estilos_UI.texto(nombre.to_upper(), 10, Estilos_UI.TINTA_SUAVE, 700))
	v.add_child(Estilos_UI.titulo(valor, 22, color))
	return p


func _Seccion_Liga() -> void:
	var v := _Tarjeta()
	v.add_child(Estilos_UI.titulo("Liga dominical", 17, Estilos_UI.TINTA))
	var liga: Dictionary = Variables_Dinamicas.Carrera_Futbol.get("Liga_Domingo", {})
	var jornada: int = int(liga.get("Jornada_Actual", 0))
	var estado_jornada: String = "Jornada %d de 4" % (jornada + 1)
	if jornada >= 4:
		estado_jornada = "Temporada completada"
	var tabla: Array = Sistema_Futbol.Obtener_Tabla_Liga()
	var posicion_actual: int = 1
	for i in range(tabla.size()):
		if bool(tabla[i].get("es_jugador", false)):
			posicion_actual = i + 1
			break
	v.add_child(Estilos_UI.texto("%s · Posición actual: %dº" % [
		estado_jornada, posicion_actual], 12, Estilos_UI.TINTA_SUAVE, 600))

	for i in range(tabla.size()):
		var fila: Dictionary = tabla[i]
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		var es_jugador: bool = bool(fila.get("es_jugador", false))
		var color: Color = Estilos_UI.AZUL if es_jugador else Estilos_UI.TINTA
		var pos := Estilos_UI.texto("%d." % (i + 1), 13, color, 700)
		pos.custom_minimum_size = Vector2(26, 0)
		h.add_child(pos)
		var nombre := Estilos_UI.texto(str(fila.get("nombre", "")), 13, color, 700 if es_jugador else 500)
		nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(nombre)
		h.add_child(Estilos_UI.texto("%d pts" % int(fila.get("puntos", 0)), 13, color, 700))
		v.add_child(h)


func _Seccion_Asistencia() -> void:
	var v := _Tarjeta()
	v.add_child(Estilos_UI.titulo("Asistencia a entrenamientos", 17, Estilos_UI.TINTA))
	var asistencia: Dictionary = Variables_Dinamicas.Carrera_Futbol.get(
		"Entrenamientos_Asistencia", {})
	var horario: Dictionary = Calendario_Futbol.Obtener_Horario_Entrenamiento(
		Sistema_Futbol.Obtener_Division(), Variables_Estaticas.Modo_Rapido)
	var inicio_txt: String = Calendario_Futbol.Formatear_Hora(int(horario.get("inicio", 0)))
	var fin_txt: String = Calendario_Futbol.Formatear_Hora(int(horario.get("fin", 0)))
	v.add_child(Estilos_UI.parrafo(
		"Cada falta resta 12 puntos de relación con el entrenador. Acudir con buena condición física suma más relación.",
		12, Estilos_UI.TINTA_SUAVE))

	if Variables_Estaticas.Modo_Rapido:
		_Crear_Check_Asistencia(v, "Diario", "Todos los días (%s–%s)" % [inicio_txt, fin_txt],
			bool(asistencia.get("Diario", true)))
	else:
		_Crear_Check_Asistencia(v, "Martes", "Martes (%s–%s)" % [inicio_txt, fin_txt],
			bool(asistencia.get("Martes", true)))
		_Crear_Check_Asistencia(v, "Jueves", "Jueves (%s–%s)" % [inicio_txt, fin_txt],
			bool(asistencia.get("Jueves", true)))


func _Crear_Check_Asistencia(parent: VBoxContainer, clave: String, texto: String,
		activo: bool) -> void:
	var check := CheckBox.new()
	check.text = texto
	check.button_pressed = activo
	check.add_theme_font_override("font", Estilos_UI.fuente_ui(600))
	check.add_theme_font_size_override("font_size", 14)
	for estado in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		check.add_theme_color_override(estado, Estilos_UI.TINTA)
	check.toggled.connect(func(valor: bool):
		if _refrescando:
			return
		Sistema_Futbol.Cambiar_Asistencia(clave, valor)
		call_deferred("_Refrescar"))
	parent.add_child(check)


func _Boton_Rescindir() -> void:
	var btn := Estilos_UI.boton("Rescindir contrato", "peligro", "x", Estilos_UI.PELIGRO, 52)
	btn.pressed.connect(_Pedir_Rescision)
	_contenido.add_child(btn)


func _Pedir_Rescision() -> void:
	_Asegurar_Dialogos()
	_dialogo_rescision.dialog_text = (
		"¿Seguro que quieres rescindir tu contrato?\nDejarás de cobrar el salario y se borrarán los entrenamientos y partidos futuros.")
	_dialogo_rescision.popup_centered(Vector2i(560, 250))


func _Intentar_Fichar() -> void:
	var req: Dictionary = Sistema_Futbol.Cumple_Requisitos_Fichaje()
	if not bool(req.get("cumple", false)):
		_Mostrar_Info("Requisitos no cumplidos",
			"Necesitas al menos %d de Deporte y menos de %d años." % [
				int(req.get("requisito_deporte", 25)), int(req.get("requisito_edad", 30))])
		return
	if Sistema_Futbol.Hay_Conflicto_Fichaje():
		_Asegurar_Dialogos()
		var actual: Actividad_Fija_Trabajo = Variables_Dinamicas.Trabajo_Actual
		var nombre_trabajo: String = "tu empleo actual"
		if actual != null:
			nombre_trabajo = actual.nombre.replace("Trabajar_En_", "").replace(
				"Trabajar_De_", "").replace("_", " ")
		_dialogo_fichaje.dialog_text = (
			"Tu trabajo de %s solapa con tus compromisos de fútbol (entrenamientos o partidos).\n\n" \
			+ "Si sigues con el fútbol, dejarás el empleo. Si mantienes el trabajo, no podrás fichar.") \
			% nombre_trabajo
		_dialogo_fichaje.popup_centered(Vector2i(580, 280))
		return
	_Fichar(false)


func _Fichar(despedir_trabajo: bool) -> void:
	var resultado: Dictionary = Sistema_Futbol.Fichar(despedir_trabajo)
	if bool(resultado.get("fichado", false)):
		_Mostrar_Info("Fichaje completado",
			"Has firmado por la 3ª División Regional. Tu primer entrenamiento será el próximo día de la rutina.")
		_Refrescar(true)
		return
	if bool(resultado.get("requiere_conflicto", false)):
		_Intentar_Fichar()
		return
	_Mostrar_Info("No se pudo fichar", str(resultado.get("motivo", "Inténtalo de nuevo más tarde.")))


func _Asegurar_Dialogos() -> void:
	if _dialogo_info == null:
		_dialogo_info = AcceptDialog.new()
		_dialogo_info.title = "Carrera futbolística"
		_dialogo_info.ok_button_text = "Entendido"
		add_child(_dialogo_info)

	if _dialogo_rescision == null:
		_dialogo_rescision = ConfirmationDialog.new()
		_dialogo_rescision.title = "Rescindir contrato"
		_dialogo_rescision.ok_button_text = "Sí, rescindir"
		_dialogo_rescision.get_cancel_button().text = "Cancelar"
		_dialogo_rescision.confirmed.connect(_Confirmar_Rescision)
		add_child(_dialogo_rescision)

	if _dialogo_fichaje == null:
		_dialogo_fichaje = ConfirmationDialog.new()
		_dialogo_fichaje.title = "Fútbol o trabajo"
		_dialogo_fichaje.ok_button_text = "Seguir con el fútbol"
		_dialogo_fichaje.get_cancel_button().text = "Mantener trabajo"
		_dialogo_fichaje.confirmed.connect(func(): _Fichar(true))
		add_child(_dialogo_fichaje)


func _Confirmar_Rescision() -> void:
	Sistema_Futbol.Rescindir_Contrato()
	_Refrescar(true)


func _Mostrar_Info(titulo: String, texto: String) -> void:
	_Asegurar_Dialogos()
	_dialogo_info.title = titulo
	_dialogo_info.dialog_text = texto
	_dialogo_info.popup_centered(Vector2i(560, 220))


func _Fila_Dato(parent: VBoxContainer, etiqueta: String, valor: String,
		color_valor: Color = Estilos_UI.TINTA) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	parent.add_child(h)
	var lbl := Estilos_UI.texto(etiqueta, 13, Estilos_UI.TINTA_SUAVE, 600)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(lbl)
	var val := Estilos_UI.texto(valor, 13, color_valor, 700)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	val.custom_minimum_size = Vector2(210, 0)
	val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(val)


func _Fila_Requisito(parent: VBoxContainer, etiqueta: String, valor: String,
		cumple: bool) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	parent.add_child(h)
	var color: Color = Estilos_UI.EXITO if cumple else Estilos_UI.PELIGRO
	h.add_child(Estilos_UI.icono_rect("circle-check" if cumple else "circle-x", 20, color))
	var lbl := Estilos_UI.texto(etiqueta, 13, Estilos_UI.TINTA, 600)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(lbl)
	h.add_child(Estilos_UI.texto(valor, 13, color, 700))


func _Barra(parent: VBoxContainer, etiqueta: String, valor: float, color: Color) -> void:
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 8)
	parent.add_child(cab)
	var lbl := Estilos_UI.texto(etiqueta, 13, Estilos_UI.TINTA, 600)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(lbl)
	cab.add_child(Estilos_UI.texto("%d%%" % int(round(valor)), 12, color, 700))
	var barra := ProgressBar.new()
	barra.custom_minimum_size = Vector2(0, 14)
	barra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	barra.show_percentage = false
	barra.max_value = 100
	barra.value = clampf(valor, 0, 100)
	barra.add_theme_stylebox_override("background", Estilos_UI.barra_fondo())
	barra.add_theme_stylebox_override("fill", Estilos_UI.barra_relleno(color))
	parent.add_child(barra)


func _Color_Relacion(valor: float) -> Color:
	if valor < 25.0:
		return Estilos_UI.PELIGRO
	if valor <= 60.0:
		return Estilos_UI.AVISO
	return Estilos_UI.EXITO


func _Color_Estado() -> Color:
	match str(Variables_Dinamicas.Carrera_Futbol.get("Estado_Temporada", "En_Curso")):
		"Ascendido", "Campeon":
			return Estilos_UI.EXITO
		"Descendido", "Despedido":
			return Estilos_UI.PELIGRO
		"Ascenso_Pendiente":
			return Estilos_UI.AVISO
		"En_Curso":
			return Estilos_UI.AZUL
		_:
			return Estilos_UI.TINTA_SUAVE


func _on_volver() -> void:
	cerrado.emit()
	queue_free()
