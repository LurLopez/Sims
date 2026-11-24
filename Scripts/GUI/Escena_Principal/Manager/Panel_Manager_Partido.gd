class_name Panel_Manager_Partido
extends Control

# Partido en vivo de «El Mánager»: visor 2D animado del estadio, banquillo con
# el Sim entrenador, teletipo con etiquetas, barras comparativas en los colores
# de cada club, pausa, velocidades x1/x2/x4/x8, descanso al 45', mentalidad/presión
# en directo y hasta 5 sustituciones con retratos.

signal cerrado

const COLOR_NOCHE := Color("#0b1220")
const COLOR_NOCHE_2 := Color("#111c30")
const COLOR_NOCHE_3 := Color("#1a2740")
const COLOR_ORO := Color("#fbbf24")

var _estado: Dictionary = {}
var _velocidad: int = 1
var _pausado: bool = false
var _acumulador: float = 0.0
var _jugando: bool = false
var _resultado_mostrado: bool = false
var _descanso_mostrado: bool = false

var _reloj: Label
var _fase_pill: PanelContainer
var _fase_lbl: Label
var _progreso_minuto: ProgressBar
var _marcador: Label
var _subtitulo: Label
var _btn_pausa: Button
var _btn_cambios: Button
var _btn_velocidades: Array = []
var _botones_ment: Dictionary = {}
var _botones_pres: Dictionary = {}

var _campo_vivo: Vista_Partido_Campo
var _charla_coach_lbl: Label
var _retrato_coach_wrap: Control
var _ultimo_animo_coach: String = ""

var _feed_scroll: ScrollContainer
var _feed: VBoxContainer
var _eventos_mostrados: int = 0
var _stats: VBoxContainer

var _modal_cambios: Control = null
var _cambio_sale: String = ""
var _cambio_entra: String = ""
var _modal_descanso: Control = null
var _modal_resultado: Control = null

var _cresta_local: Cresta_Manager
var _cresta_visitante: Cresta_Manager
var _nombre_local: Label
var _nombre_visitante: Label
var _colores_local: Array = ["#0f766e", "#ffffff"]
var _colores_visitante: Array = ["#dc2626", "#ffffff"]
var _patron_local: int = 1
var _patron_visitante: int = 1


func _ready() -> void:
	z_index = 300
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_Construir()
	set_process(true)


func abrir(estado: Dictionary) -> void:
	_estado = estado
	_velocidad = 1
	_pausado = false
	_acumulador = 0.0
	_jugando = true
	_resultado_mostrado = false
	_descanso_mostrado = int(estado.get("minuto", 0)) >= 45
	_eventos_mostrados = 0
	_ultimo_animo_coach = ""
	_Actualizar_Identidad()
	_Actualizar_Todo()
	_Anadir_Nuevos_Eventos()
	_Actualizar_Velocidades()
	_Actualizar_Botones_Tactica()
	if not bool(_estado.get("finalizado", false)):
		Estilo_Manager.reproducir_sfx("start")
	else:
		_jugando = false
		_Mostrar_Resultado()


func _process(delta: float) -> void:
	if not _jugando or _pausado or _estado.is_empty():
		return
	if bool(_estado.get("finalizado", false)):
		_jugando = false
		_Mostrar_Resultado()
		return
	_acumulador += delta * float(_velocidad)
	var seguridad: int = 0
	while _acumulador >= Datos_Manager.SEGUNDOS_POR_MINUTO_X1 \
			and not bool(_estado.get("finalizado", false)) and seguridad < 12:
		_acumulador -= Datos_Manager.SEGUNDOS_POR_MINUTO_X1
		Sistema_Manager.Avanzar_Minuto_Partido()
		_Anadir_Nuevos_Eventos()
		seguridad += 1
		if int(_estado.get("minuto", 0)) == 45 and not _descanso_mostrado:
			_descanso_mostrado = true
			_pausado = true
			_Actualizar_Todo()
			_Abrir_Modal_Descanso()
			return
	_Actualizar_Todo()
	if bool(_estado.get("finalizado", false)):
		_jugando = false
		_Mostrar_Resultado()


func _Construir() -> void:
	var fondo := ColorRect.new()
	fondo.color = COLOR_NOCHE
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)

	var brillo := ColorRect.new()
	brillo.color = Color("#166534", 0.22)
	brillo.set_anchors_preset(Control.PRESET_TOP_WIDE)
	brillo.offset_bottom = 270.0
	brillo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(brillo)

	var margen := MarginContainer.new()
	margen.set_anchors_preset(Control.PRESET_FULL_RECT)
	margen.add_theme_constant_override("margin_left", 14)
	margen.add_theme_constant_override("margin_right", 14)
	margen.add_theme_constant_override("margin_top", 10)
	margen.add_theme_constant_override("margin_bottom", 12)
	add_child(margen)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	margen.add_child(v)

	# Cabecera.
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 6)
	v.add_child(cab)
	var btn_salir := Estilos_UI.boton_icono("arrow-left", Estilos_UI.TINTA, 42)
	btn_salir.pressed.connect(_Intentar_Salir)
	cab.add_child(btn_salir)

	var tit := VBoxContainer.new()
	tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tit.clip_contents = true
	tit.add_theme_constant_override("separation", 1)
	cab.add_child(tit)
	_subtitulo = Estilos_UI.texto("PARTIDO EN VIVO", 10, Color(1, 1, 1, 0.65), 700)
	_subtitulo.clip_text = true
	tit.add_child(_subtitulo)
	var reloj_fila := HBoxContainer.new()
	reloj_fila.add_theme_constant_override("separation", 6)
	tit.add_child(reloj_fila)
	_reloj = Estilos_UI.titulo("0'", 22, Color.WHITE)
	reloj_fila.add_child(_reloj)
	_fase_pill = Estilos_UI.pill_estado("1ª PARTE", Color("#1e3a8a"), Color("#93c5fd"))
	reloj_fila.add_child(_fase_pill)
	for hijo in _fase_pill.get_children():
		if hijo is Label:
			_fase_lbl = hijo
			break

	_btn_pausa = Estilo_Manager.boton("Pausa", "chip", "pause", Color.WHITE, 42)
	_btn_pausa.add_theme_font_size_override("font_size", 11)
	_btn_pausa.pressed.connect(_Alternar_Pausa)
	cab.add_child(_btn_pausa)

	_btn_cambios = Estilo_Manager.boton("Cambios 0/5", "suave", "users", Color.WHITE, 42)
	_btn_cambios.add_theme_font_size_override("font_size", 11)
	_btn_cambios.pressed.connect(_Abrir_Modal_Cambios)
	cab.add_child(_btn_cambios)

	# Marcador panorámico compacto.
	var marcador_card := PanelContainer.new()
	marcador_card.add_theme_stylebox_override("panel", Estilos_UI.caja(
		COLOR_NOCHE_2, 14, Color(1, 1, 1, 0.12), 1, 0))
	v.add_child(marcador_card)
	var mm := MarginContainer.new()
	mm.add_theme_constant_override("margin_left", 16)
	mm.add_theme_constant_override("margin_right", 16)
	mm.add_theme_constant_override("margin_top", 8)
	mm.add_theme_constant_override("margin_bottom", 8)
	marcador_card.add_child(mm)
	var mv := VBoxContainer.new()
	mv.add_theme_constant_override("separation", 6)
	mm.add_child(mv)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	mv.add_child(fila)

	var bloque_local := HBoxContainer.new()
	bloque_local.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bloque_local.alignment = BoxContainer.ALIGNMENT_END
	bloque_local.add_theme_constant_override("separation", 10)
	fila.add_child(bloque_local)
	_nombre_local = Estilos_UI.texto("Local", 15, Color.WHITE, 700)
	_nombre_local.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_nombre_local.clip_text = true
	_nombre_local.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bloque_local.add_child(_nombre_local)
	_cresta_local = Cresta_Manager.new()
	_cresta_local.custom_minimum_size = Vector2(36, 40)
	_cresta_local.size = Vector2(36, 40)
	_cresta_local.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bloque_local.add_child(_cresta_local)

	_marcador = Estilos_UI.titulo("0 - 0", 30, Color.WHITE)
	_marcador.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_marcador.custom_minimum_size = Vector2(116, 0)
	_marcador.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(_marcador)

	var bloque_visitante := HBoxContainer.new()
	bloque_visitante.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bloque_visitante.alignment = BoxContainer.ALIGNMENT_BEGIN
	bloque_visitante.add_theme_constant_override("separation", 10)
	fila.add_child(bloque_visitante)
	_cresta_visitante = Cresta_Manager.new()
	_cresta_visitante.custom_minimum_size = Vector2(36, 40)
	_cresta_visitante.size = Vector2(36, 40)
	_cresta_visitante.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bloque_visitante.add_child(_cresta_visitante)
	_nombre_visitante = Estilos_UI.texto("Visitante", 15, Color.WHITE, 700)
	_nombre_visitante.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_nombre_visitante.clip_text = true
	_nombre_visitante.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bloque_visitante.add_child(_nombre_visitante)

	_progreso_minuto = ProgressBar.new()
	_progreso_minuto.custom_minimum_size = Vector2(0, 5)
	_progreso_minuto.max_value = 90.0
	_progreso_minuto.show_percentage = false
	_progreso_minuto.add_theme_stylebox_override("background", Estilos_UI.caja(
		Color(1, 1, 1, 0.12), 999, Color(0, 0, 0, 0), 0, 0))
	_progreso_minuto.add_theme_stylebox_override("fill", Estilos_UI.barra_relleno(Color("#22c55e")))
	mv.add_child(_progreso_minuto)

	# Cuerpo apaisado en 2 columnas: Campo + Controles (izq) | Stats + Crónica (der).
	var arena := HBoxContainer.new()
	arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arena.add_theme_constant_override("separation", 12)
	v.add_child(arena)

	var col_izq := VBoxContainer.new()
	col_izq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_izq.size_flags_stretch_ratio = 1.3
	col_izq.add_theme_constant_override("separation", 8)
	arena.add_child(col_izq)

	var col_der := VBoxContainer.new()
	col_der.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_der.size_flags_stretch_ratio = 0.9
	col_der.add_theme_constant_override("separation", 8)
	arena.add_child(col_der)

	# Campo 2D animado en vivo.
	var campo_card := PanelContainer.new()
	campo_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	campo_card.add_theme_stylebox_override("panel", Estilos_UI.caja(
		COLOR_NOCHE_2, 14, Color(1, 1, 1, 0.14), 1, 0))
	campo_card.clip_contents = true
	col_izq.add_child(campo_card)
	_campo_vivo = Vista_Partido_Campo.new()
	_campo_vivo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_campo_vivo.custom_minimum_size = Vector2(0, 290)
	campo_card.add_child(_campo_vivo)

	# Velocidades y salto.
	var controles := HBoxContainer.new()
	controles.add_theme_constant_override("separation", 6)
	col_izq.add_child(controles)
	for velocidad in Datos_Manager.VELOCIDADES:
		var btn := Estilo_Manager.boton("x%d" % int(velocidad), "chip", "", Color.WHITE, 40)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 13)
		var valor: int = int(velocidad)
		btn.pressed.connect(func():
			Estilo_Manager.reproducir_sfx("click")
			_velocidad = valor
			if _pausado:
				_pausado = false
			_Actualizar_Velocidades())
		controles.add_child(btn)
		_btn_velocidades.append(btn)
	var btn_saltar := Estilo_Manager.boton("Saltar", "oro", "play", COLOR_ORO, 40)
	btn_saltar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_saltar.add_theme_font_size_override("font_size", 13)
	btn_saltar.pressed.connect(_Saltar_Al_Final)
	controles.add_child(btn_saltar)

	# Banquillo humano + controles tácticos en 1 toque.
	var coach_card := PanelContainer.new()
	coach_card.add_theme_stylebox_override("panel", Estilos_UI.caja(
		COLOR_NOCHE_3, 14, Color(1, 1, 1, 0.12), 1, 0))
	col_izq.add_child(coach_card)
	var cm := MarginContainer.new()
	cm.add_theme_constant_override("margin_left", 10)
	cm.add_theme_constant_override("margin_right", 10)
	cm.add_theme_constant_override("margin_top", 8)
	cm.add_theme_constant_override("margin_bottom", 8)
	coach_card.add_child(cm)
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 6)
	cm.add_child(cv)

	var coach_top := HBoxContainer.new()
	coach_top.add_theme_constant_override("separation", 10)
	cv.add_child(coach_top)
	_retrato_coach_wrap = HBoxContainer.new()
	coach_top.add_child(_retrato_coach_wrap)
	var coach_txt_col := VBoxContainer.new()
	coach_txt_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	coach_txt_col.add_theme_constant_override("separation", 1)
	coach_top.add_child(coach_txt_col)
	coach_txt_col.add_child(Estilos_UI.texto("BANQUILLO", 9, Color("#93c5fd"), 700))
	_charla_coach_lbl = Estilos_UI.parrafo(
		"«Concentrados desde el pitido inicial, equipo.»", 12, Color.WHITE)
	coach_txt_col.add_child(_charla_coach_lbl)

	var fila_ment := HBoxContainer.new()
	fila_ment.add_theme_constant_override("separation", 5)
	cv.add_child(fila_ment)
	for m_id in Datos_Manager.MENTALIDADES:
		var m_str: String = str(m_id)
		var b_m := Estilo_Manager.boton(m_str.capitalize(), "chip", "", Color("#0d9488"), 36)
		b_m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b_m.add_theme_font_size_override("font_size", 11)
		b_m.pressed.connect(func(): _Cambiar_Mentalidad(m_str))
		fila_ment.add_child(b_m)
		_botones_ment[m_str] = b_m

	var fila_pres := HBoxContainer.new()
	fila_pres.add_theme_constant_override("separation", 5)
	cv.add_child(fila_pres)
	for p_id in Datos_Manager.PRESIONES:
		var p_str: String = str(p_id)
		var b_p := Estilo_Manager.boton("Presión " + p_str, "chip", "", Color("#0284c7"), 36)
		b_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b_p.add_theme_font_size_override("font_size", 11)
		b_p.pressed.connect(func(): _Cambiar_Presion(p_str))
		fila_pres.add_child(b_p)
		_botones_pres[p_str] = b_p

	# Estadísticas comparativas (columna derecha).
	var stats_card := PanelContainer.new()
	stats_card.add_theme_stylebox_override("panel", Estilos_UI.caja(
		COLOR_NOCHE_2, 14, Color(1, 1, 1, 0.10), 1, 0))
	col_der.add_child(stats_card)
	var sm := MarginContainer.new()
	sm.add_theme_constant_override("margin_left", 12)
	sm.add_theme_constant_override("margin_right", 12)
	sm.add_theme_constant_override("margin_top", 8)
	sm.add_theme_constant_override("margin_bottom", 8)
	stats_card.add_child(sm)
	_stats = VBoxContainer.new()
	_stats.add_theme_constant_override("separation", 6)
	sm.add_child(_stats)

	# Teletipo (columna derecha).
	var feed_card := PanelContainer.new()
	feed_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	feed_card.add_theme_stylebox_override("panel", Estilos_UI.caja(
		COLOR_NOCHE_2, 14, Color(1, 1, 1, 0.10), 1, 0))
	col_der.add_child(feed_card)
	var fm := MarginContainer.new()
	fm.add_theme_constant_override("margin_left", 12)
	fm.add_theme_constant_override("margin_right", 12)
	fm.add_theme_constant_override("margin_top", 8)
	fm.add_theme_constant_override("margin_bottom", 8)
	feed_card.add_child(fm)
	var fv := VBoxContainer.new()
	fv.add_theme_constant_override("separation", 5)
	fm.add_child(fv)
	fv.add_child(Estilos_UI.texto("CRÓNICA MINUTO A MINUTO", 10, Color(1, 1, 1, 0.50), 700))
	_feed_scroll = ScrollContainer.new()
	_feed_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_feed_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	fv.add_child(_feed_scroll)
	_feed = VBoxContainer.new()
	_feed.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_feed.add_theme_constant_override("separation", 6)
	_feed_scroll.add_child(_feed)
	_feed.add_child(Estilos_UI.texto(
		"El árbitro da el pitido inicial. ¡Rueda el balón!", 12,
		Color(1, 1, 1, 0.65), 500))


func _Actualizar_Identidad() -> void:
	if _estado.is_empty():
		return
	var local_id: String = str(_estado.get("local_id", ""))
	var visitante_id: String = str(_estado.get("visitante_id", ""))
	var club_local: Dictionary = Sistema_Manager.Obtener_Club(local_id)
	var club_visitante: Dictionary = Sistema_Manager.Obtener_Club(visitante_id)
	_colores_local = club_local.get("colores", Datos_Manager.COLORES_POR_DEFECTO)
	_colores_visitante = club_visitante.get("colores", Datos_Manager.COLORES_POR_DEFECTO)
	_patron_local = int(club_local.get("escudo_patron", 1))
	_patron_visitante = int(club_visitante.get("escudo_patron", 1))
	_cresta_local.configurar(str(_estado.get("local_nombre", "")),
		_colores_local, _patron_local, false)
	_cresta_visitante.configurar(str(_estado.get("visitante_nombre", "")),
		_colores_visitante, _patron_visitante, false)
	_nombre_local.text = str(_estado.get("local_nombre", "Local")).to_upper()
	_nombre_visitante.text = str(_estado.get("visitante_nombre", "Visitante")).to_upper()
	var tipo_p: String = "PARTIDO AMISTOSO" if bool(_estado.get("es_amistoso", false)) \
		else "TEMPORADA %d · JORNADA %d" % [
			int(_estado.get("temporada", 1)), int(_estado.get("jornada", 0)) + 1]
	_subtitulo.text = "%s · EN VIVO" % tipo_p
	if _campo_vivo != null:
		_campo_vivo.configurar_colores(_colores_local, _colores_visitante)
	_Actualizar_Retrato_Coach("concentrado", "«Concentrados desde el pitido inicial, equipo.»")


func _Actualizar_Retrato_Coach(expresion: String, frase: String) -> void:
	if _charla_coach_lbl != null:
		_charla_coach_lbl.text = frase
	if _retrato_coach_wrap == null or _ultimo_animo_coach == expresion:
		return
	_ultimo_animo_coach = expresion
	for h in _retrato_coach_wrap.get_children():
		_retrato_coach_wrap.remove_child(h)
		h.queue_free()
	var lado: String = str(_estado.get("lado_usuario", "local"))
	var cols: Array = _colores_local if lado == "local" else _colores_visitante
	_retrato_coach_wrap.add_child(Estilo_Manager.crear_retrato_manager(46, cols, expresion, false))


func _Actualizar_Todo() -> void:
	if _estado.is_empty():
		return
	var minuto: int = int(_estado.get("minuto", 0))
	_reloj.text = "%d'" % minuto
	_progreso_minuto.value = float(minuto)
	if _fase_lbl != null:
		if bool(_estado.get("finalizado", false)):
			_fase_lbl.text = "FINAL"
		elif _pausado:
			_fase_lbl.text = "PAUSA"
		elif minuto < 45:
			_fase_lbl.text = "1ª PARTE"
		elif minuto == 45:
			_fase_lbl.text = "DESCANSO"
		else:
			_fase_lbl.text = "2ª PARTE"
	if _btn_pausa != null:
		_btn_pausa.text = "Seguir" if _pausado else "Pausa"
		_btn_pausa.icon = Estilos_UI.icono("play" if _pausado else "pause")
		Estilos_UI.aplicar_estilo_boton(_btn_pausa,
			"exito" if _pausado else "chip",
			Estilos_UI.EXITO if _pausado else Color.WHITE)
		_btn_pausa.add_theme_font_size_override("font_size", 12)

	var gl: int = int(_estado.get("goles_local", 0))
	var gv: int = int(_estado.get("goles_visitante", 0))
	_marcador.text = "%d - %d" % [gl, gv]

	var lado_usuario: String = str(_estado.get("lado_usuario", "local"))
	var dif: int = (gl - gv) if lado_usuario == "local" else (gv - gl)
	if dif > 0:
		_Actualizar_Retrato_Coach("feliz", "«¡Buen trabajo! Mantened la posesión y el orden.»")
	elif dif < 0:
		_Actualizar_Retrato_Coach("sorpresa", "«¡Arriba líneas! Podemos darle la vuelta al marcador.»")
	else:
		_Actualizar_Retrato_Coach("concentrado", "«Partido muy igualado. Un detalle decide esto.»")

	var cambios_usuario: int = int(_estado.get("cambios_%s" % lado_usuario, 0))
	var cansados: int = _Contar_Titulares_Cansados(lado_usuario)
	_btn_cambios.text = "Cambios %d/%d" % [cambios_usuario, Datos_Manager.CAMBIOS_MAXIMOS] + (" (!)" if cansados > 0 else "")
	Estilos_UI.aplicar_estilo_boton(_btn_cambios,
		"oro" if cansados > 0 and cambios_usuario < Datos_Manager.CAMBIOS_MAXIMOS else "suave",
		COLOR_ORO if cansados > 0 else Color.WHITE, "users")
	_btn_cambios.add_theme_font_size_override("font_size", 11)

	if _campo_vivo != null:
		_campo_vivo.actualizar_estado(_estado)

	_Actualizar_Botones_Tactica()

	for hijo in _stats.get_children():
		_stats.remove_child(hijo)
		hijo.queue_free()
	var pos_l: float = Simulador_Manager.Posesion_Local(_estado)
	var col_l: Color = Color(str(_colores_local[0]))
	var col_v: Color = Color(str(_colores_visitante[0]))
	if Vector3(col_l.r - col_v.r, col_l.g - col_v.g, col_l.b - col_v.b).length() < 0.25:
		col_v = Color("#38bdf8")
	_stats.add_child(Estilo_Manager.barra_comparativa("Posesión", pos_l, 100.0 - pos_l,
		"%d%%" % int(round(pos_l)), "%d%%" % int(round(100.0 - pos_l)), col_l, col_v, true))
	var tl: int = int(_estado.get("tiros_local", 0))
	var tv: int = int(_estado.get("tiros_visitante", 0))
	_stats.add_child(Estilo_Manager.barra_comparativa("Tiros", float(tl), float(tv),
		str(tl), str(tv), col_l, col_v, true))
	var pl: int = int(_estado.get("tiros_puerta_local", 0))
	var pv: int = int(_estado.get("tiros_puerta_visitante", 0))
	_stats.add_child(Estilo_Manager.barra_comparativa("A puerta", float(pl), float(pv),
		str(pl), str(pv), col_l, col_v, true))
	var cl: int = int(_estado.get("corners_local", 0))
	var cv_c: int = int(_estado.get("corners_visitante", 0))
	_stats.add_child(Estilo_Manager.barra_comparativa("Córners", float(cl), float(cv_c),
		str(cl), str(cv_c), col_l, col_v, true))


func _Contar_Titulares_Cansados(lado: String) -> int:
	var energia = _estado.get("energia", {})
	var alineacion = _estado.get("alineacion_%s" % lado, [])
	if not (energia is Dictionary) or not (alineacion is Array):
		return 0
	var n: int = 0
	for jid in alineacion:
		if float(energia.get(str(jid), 100.0)) < 50.0:
			n += 1
	return n


func _Actualizar_Botones_Tactica() -> void:
	if _estado.is_empty():
		return
	var lado: String = str(_estado.get("lado_usuario", "local"))
	var tac = _estado.get("tactica_%s" % lado, {})
	var ment_act: String = str(tac.get("mentalidad", "equilibrada")) if tac is Dictionary else "equilibrada"
	var pres_act: String = str(tac.get("presion", "media")) if tac is Dictionary else "media"
	for m_id in _botones_ment.keys():
		var btn = _botones_ment[m_id]
		if is_instance_valid(btn):
			var act: bool = m_id == ment_act
			Estilos_UI.aplicar_estilo_boton(btn, "primario" if act else "chip",
				Color("#0f766e") if act else Color.WHITE)
			btn.add_theme_font_size_override("font_size", 11)
	for p_id in _botones_pres.keys():
		var btn2 = _botones_pres[p_id]
		if is_instance_valid(btn2):
			var act2: bool = p_id == pres_act
			Estilos_UI.aplicar_estilo_boton(btn2, "primario" if act2 else "chip",
				Color("#0284c7") if act2 else Color.WHITE)
			btn2.add_theme_font_size_override("font_size", 11)


func _Cambiar_Mentalidad(mentalidad: String) -> void:
	if _estado.is_empty() or bool(_estado.get("finalizado", false)):
		return
	Estilo_Manager.reproducir_sfx("click")
	Sistema_Manager.Cambiar_Mentalidad_Partido(mentalidad)
	_Anadir_Nuevos_Eventos()
	_Actualizar_Todo()


func _Cambiar_Presion(presion: String) -> void:
	if _estado.is_empty() or bool(_estado.get("finalizado", false)):
		return
	Estilo_Manager.reproducir_sfx("click")
	Sistema_Manager.Cambiar_Presion_Partido(presion)
	_Anadir_Nuevos_Eventos()
	_Actualizar_Todo()


func _Alternar_Pausa() -> void:
	if bool(_estado.get("finalizado", false)):
		return
	Estilo_Manager.reproducir_sfx("click")
	_pausado = not _pausado
	_Actualizar_Todo()


func _Anadir_Nuevos_Eventos() -> void:
	var eventos = _estado.get("eventos", [])
	if not (eventos is Array):
		return
	while _eventos_mostrados < eventos.size():
		var evento = eventos[_eventos_mostrados]
		_eventos_mostrados += 1
		if not (evento is Dictionary):
			continue
		_Anadir_Linea_Evento(evento)
		if _jugando and str(evento.get("tipo", "")) == "gol":
			var lado_u: String = str(_estado.get("lado_usuario", "local"))
			if str(evento.get("equipo", "")) == lado_u:
				Estilo_Manager.reproducir_sfx("happy")
			else:
				Estilo_Manager.reproducir_sfx("angry")


func _Anadir_Linea_Evento(evento: Dictionary) -> void:
	var tipo: String = str(evento.get("tipo", "info"))
	var color: Color = Color(1, 1, 1, 0.85)
	var bg: Color = Color(1, 1, 1, 0.03)
	var badge_txt: String = "•"
	var badge_col: Color = Color("#64748b")
	var tam: int = 12
	match tipo:
		"gol":
			color = COLOR_ORO
			bg = Color("#fbbf24", 0.14)
			badge_txt = "GOL"
			badge_col = Color("#d97706")
			tam = 13
		"tarjeta":
			color = Color("#fde047")
			bg = Color("#facc15", 0.08)
			badge_txt = "TAR"
			badge_col = Color("#ca8a04")
		"cambio":
			color = Color("#7dd3fc")
			bg = Color("#38bdf8", 0.08)
			badge_txt = "CAM"
			badge_col = Color("#0284c7")
		"tactica":
			color = Color("#a7f3d0")
			badge_txt = "TAC"
			badge_col = Color("#0d9488")
		"ocasion":
			color = Color("#cbd5e1")
			badge_txt = "OCA"
			badge_col = Color("#475569")
		"corner":
			color = Color("#cbd5e1")
			badge_txt = "COR"
			badge_col = Color("#475569")
		"final":
			color = Color.WHITE
			bg = Color("#22c55e", 0.16)
			badge_txt = "FIN"
			badge_col = Color("#16a34a")
			tam = 13

	var fila_card := PanelContainer.new()
	fila_card.add_theme_stylebox_override("panel", Estilos_UI.caja(
		bg, 8, Color(0, 0, 0, 0), 0, 0))
	_feed.add_child(fila_card)
	var fm := MarginContainer.new()
	fm.add_theme_constant_override("margin_left", 6)
	fm.add_theme_constant_override("margin_right", 6)
	fm.add_theme_constant_override("margin_top", 4)
	fm.add_theme_constant_override("margin_bottom", 4)
	fila_card.add_child(fm)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	fm.add_child(h)

	var minuto := Estilos_UI.texto("%d'" % int(evento.get("minuto", 0)), 11,
		Color(1, 1, 1, 0.55), 700)
	minuto.custom_minimum_size = Vector2(28, 0)
	h.add_child(minuto)

	h.add_child(Estilos_UI.pill_estado(badge_txt, badge_col, Color.WHITE))

	var lbl := Estilos_UI.texto(str(evento.get("texto", "")), tam, color,
		700 if (tipo == "gol" or tipo == "final") else 500)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(lbl)

	if evento.has("marcador"):
		var marc := Estilos_UI.texto(str(evento["marcador"]), 11, Color(1, 1, 1, 0.65), 700)
		h.add_child(marc)
	_feed_scroll.set_deferred("scroll_vertical",
		int(_feed_scroll.get_v_scroll_bar().max_value))


func _Actualizar_Velocidades() -> void:
	for i in range(_btn_velocidades.size()):
		var btn = _btn_velocidades[i]
		if not is_instance_valid(btn):
			continue
		var valor: int = int(Datos_Manager.VELOCIDADES[i])
		Estilos_UI.aplicar_estilo_boton(btn,
			"oro" if valor == _velocidad else "chip",
			COLOR_ORO if valor == _velocidad else Color.WHITE)
		btn.add_theme_font_size_override("font_size", 13)


func _Saltar_Al_Final() -> void:
	if _estado.is_empty() or bool(_estado.get("finalizado", false)):
		return
	Estilo_Manager.reproducir_sfx("click")
	_Cerrar_Modal_Descanso()
	Sistema_Manager.Simular_Resto_Partido()
	_jugando = false
	_Anadir_Nuevos_Eventos()
	_Actualizar_Todo()
	_Mostrar_Resultado()


# ------------------------------------------------------------------
# Descanso al minuto 45'
# ------------------------------------------------------------------

func _Abrir_Modal_Descanso() -> void:
	_Cerrar_Modal_Descanso()
	var overlay := ColorRect.new()
	overlay.color = Color(0.03, 0.05, 0.09, 0.78)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 25
	add_child(overlay)
	_modal_descanso = overlay

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(centro)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(620, 0)
	card.add_theme_stylebox_override("panel", Estilos_UI.caja(
		Estilos_UI.SUPERFICIE, 20, Estilos_UI.BORDE_FUERTE, 1, 5))
	centro.add_child(card)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 20)
	m.add_theme_constant_override("margin_right", 20)
	m.add_theme_constant_override("margin_top", 18)
	m.add_theme_constant_override("margin_bottom", 18)
	card.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	m.add_child(v)

	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 12)
	v.add_child(cab)
	var lado: String = str(_estado.get("lado_usuario", "local"))
	var cols: Array = _colores_local if lado == "local" else _colores_visitante
	cab.add_child(Estilo_Manager.crear_retrato_manager(62, cols, "concentrado", true))
	var tit_c := VBoxContainer.new()
	tit_c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tit_c.add_theme_constant_override("separation", 2)
	cab.add_child(tit_c)
	tit_c.add_child(Estilos_UI.titulo("Descanso · 45'", 22, Estilos_UI.TINTA))
	tit_c.add_child(Estilos_UI.texto("Marcador: %s %d - %d %s" % [
		str(_estado.get("local_nombre", "")), int(_estado.get("goles_local", 0)),
		int(_estado.get("goles_visitante", 0)), str(_estado.get("visitante_nombre", ""))],
		13, Estilos_UI.TINTA_SUAVE, 600))

	v.add_child(Estilos_UI.parrafo(
		"El equipo pasa por vestuarios. Elige tu consigna para la segunda parte o aprovecha para hacer cambios.",
		13, Estilos_UI.TINTA_SUAVE))

	for charla in [
		["ofensiva", "¡A por la victoria! (Mentalidad ofensiva)", "exito", Estilos_UI.EXITO],
		["equilibrada", "Mantener el plan (Mentalidad equilibrada)", "primario", Estilo_Manager.COLOR_MANAGER],
		["defensiva", "Cerrar líneas atrás (Mentalidad defensiva)", "suave", Estilos_UI.AZUL]
	]:
		var ment_id: String = str(charla[0])
		var b := Estilo_Manager.boton(str(charla[1]), str(charla[2]), "target", charla[3], 48)
		b.pressed.connect(func():
			_Cambiar_Mentalidad(ment_id)
			_Cerrar_Modal_Descanso()
			_pausado = false
			_Actualizar_Todo())
		v.add_child(b)

	var btn_sub := Estilo_Manager.boton("Hacer cambios ahora", "oro", "users", COLOR_ORO, 46)
	btn_sub.pressed.connect(func():
		_Cerrar_Modal_Descanso()
		_Abrir_Modal_Cambios())
	v.add_child(btn_sub)


func _Cerrar_Modal_Descanso() -> void:
	if _modal_descanso != null and is_instance_valid(_modal_descanso):
		_modal_descanso.queue_free()
	_modal_descanso = null


# ------------------------------------------------------------------
# Cambios (con retratos y barras de energía)
# ------------------------------------------------------------------

func _Abrir_Modal_Cambios() -> void:
	if _estado.is_empty() or bool(_estado.get("finalizado", false)):
		return
	_pausado = true
	_Construir_Modal_Cambios()


func _Cerrar_Modal_Cambios() -> void:
	if _modal_cambios != null and is_instance_valid(_modal_cambios):
		_modal_cambios.queue_free()
	_modal_cambios = null
	if _modal_descanso == null and not bool(_estado.get("finalizado", false)):
		_pausado = false
		_Actualizar_Todo()


func _Construir_Modal_Cambios() -> void:
	if _modal_cambios != null and is_instance_valid(_modal_cambios):
		_modal_cambios.queue_free()
	var lado: String = str(_estado.get("lado_usuario", ""))
	if lado == "":
		return
	var cols: Array = _colores_local if lado == "local" else _colores_visitante
	var patron: int = _patron_local if lado == "local" else _patron_visitante

	var overlay := ColorRect.new()
	overlay.color = Color(0.03, 0.05, 0.09, 0.76)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 20
	add_child(overlay)
	_modal_cambios = overlay

	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.offset_left = 64.0
	card.offset_right = -64.0
	card.offset_top = 34.0
	card.offset_bottom = -34.0
	card.add_theme_stylebox_override("panel", Estilos_UI.caja(
		Estilos_UI.SUPERFICIE, 18, Estilos_UI.BORDE_FUERTE, 1, 4))
	overlay.add_child(card)
	var v := VBoxContainer.new()
	card.add_child(v)

	var cab := HBoxContainer.new()
	v.add_child(cab)
	var m_cab := MarginContainer.new()
	m_cab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m_cab.add_theme_constant_override("margin_left", 16)
	m_cab.add_theme_constant_override("margin_top", 10)
	cab.add_child(m_cab)
	var v_cab := VBoxContainer.new()
	m_cab.add_child(v_cab)
	v_cab.add_child(Estilos_UI.titulo("Banquillo y cambios", 20, Estilos_UI.TINTA))
	var cambios: int = int(_estado.get("cambios_%s" % lado, 0))
	v_cab.add_child(Estilos_UI.texto("%d de %d cambios utilizados" % [
		cambios, Datos_Manager.CAMBIOS_MAXIMOS], 12, Estilos_UI.TINTA_SUAVE, 600))
	var cerrar := Estilos_UI.boton_icono("x", Estilos_UI.TINTA, 44)
	cerrar.pressed.connect(_Cerrar_Modal_Cambios)
	cab.add_child(cerrar)
	var sep := MarginContainer.new()
	sep.add_theme_constant_override("margin_right", 12)
	cab.add_child(sep)

	var split_m := MarginContainer.new()
	split_m.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split_m.add_theme_constant_override("margin_left", 16)
	split_m.add_theme_constant_override("margin_right", 16)
	split_m.add_theme_constant_override("margin_top", 6)
	split_m.add_theme_constant_override("margin_bottom", 6)
	v.add_child(split_m)

	var cols_c := HBoxContainer.new()
	cols_c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols_c.add_theme_constant_override("separation", 16)
	split_m.add_child(cols_c)

	# Columna izquierda: XI en el campo.
	var col_s := VBoxContainer.new()
	col_s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_s.add_theme_constant_override("separation", 6)
	cols_c.add_child(col_s)
	col_s.add_child(Estilos_UI.texto("1. ELIGE QUIÉN SALE (EN EL CAMPO)", 11, Estilos_UI.TINTA_FANTASMA, 700))
	var scroll_s := ScrollContainer.new()
	scroll_s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col_s.add_child(scroll_s)
	var list_s := VBoxContainer.new()
	list_s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_s.add_theme_constant_override("separation", 6)
	scroll_s.add_child(list_s)

	# Columna derecha: Banquillo.
	var col_e := VBoxContainer.new()
	col_e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_e.add_theme_constant_override("separation", 6)
	cols_c.add_child(col_e)
	col_e.add_child(Estilos_UI.texto("2. ELIGE QUIÉN ENTRA (BANQUILLO)", 11, Estilos_UI.TINTA_FANTASMA, 700))
	var scroll_e := ScrollContainer.new()
	scroll_e.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_e.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col_e.add_child(scroll_e)
	var list_e := VBoxContainer.new()
	list_e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_e.add_theme_constant_override("separation", 6)
	scroll_e.add_child(list_e)

	var tactica = _estado.get("tactica_%s" % lado, {})
	var formacion: String = str(tactica.get("formacion", "4-4-2")) if tactica is Dictionary else "4-4-2"
	var slots: Array = Datos_Manager.ROLES_FORMACION.get(formacion, Datos_Manager.ROLES_FORMACION["4-4-2"])

	var alineacion = _estado.get("alineacion_%s" % lado, [])
	var jugadores = _estado.get("jugadores_%s" % lado, {})
	var energia = _estado.get("energia", {})
	if alineacion is Array:
		for i in range(alineacion.size()):
			var jugador_id: String = str(alineacion[i])
			var jugador = jugadores.get(jugador_id, {}) if jugadores is Dictionary else {}
			if not (jugador is Dictionary) or jugador.is_empty():
				continue
			var ranura: String = str(slots[i]) if i < slots.size() else "MC"
			var sel: bool = jugador_id == _cambio_sale
			var e_val: float = float(energia.get(jugador_id, 100.0))
			list_s.add_child(_Crear_Fila_Jugador_Cambio(
				jugador, ranura, e_val, cols, patron, sel, func():
					Estilo_Manager.reproducir_sfx("click")
					_cambio_sale = jugador_id
					_Construir_Modal_Cambios()))

	var banquillo = _estado.get("banquillo_%s" % lado, [])
	if banquillo is Array:
		for jugador_id2 in banquillo:
			var jugador2 = jugadores.get(str(jugador_id2), {}) if jugadores is Dictionary else {}
			if not (jugador2 is Dictionary) or jugador2.is_empty():
				continue
			var sel2: bool = str(jugador_id2) == _cambio_entra
			var e_val2: float = float(energia.get(str(jugador_id2), 100.0))
			var id_local2: String = str(jugador_id2)
			list_e.add_child(_Crear_Fila_Jugador_Cambio(
				jugador2, Simulador_Manager._Rol_Principal(jugador2), e_val2, cols, patron, sel2, func():
					Estilo_Manager.reproducir_sfx("click")
					_cambio_entra = id_local2
					_Construir_Modal_Cambios()))

	# Pie con vista previa del cambio.
	var pie_box := VBoxContainer.new()
	pie_box.add_theme_constant_override("separation", 6)
	v.add_child(pie_box)
	var m_pie := MarginContainer.new()
	m_pie.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m_pie.add_theme_constant_override("margin_left", 16)
	m_pie.add_theme_constant_override("margin_right", 16)
	m_pie.add_theme_constant_override("margin_bottom", 14)
	m_pie.add_theme_constant_override("margin_top", 6)
	pie_box.add_child(m_pie)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 6)
	m_pie.add_child(pv)

	var resumen_txt: String = "Selecciona un titular y un suplente para realizar el cambio."
	if _cambio_sale != "" and _cambio_entra != "":
		var js: Dictionary = jugadores.get(_cambio_sale, {})
		var je: Dictionary = jugadores.get(_cambio_entra, {})
		resumen_txt = "Sale: %s  →  Entra: %s" % [str(js.get("nombre", "")), str(je.get("nombre", ""))]
	pv.add_child(Estilos_UI.texto(resumen_txt, 12,
		Estilo_Manager.COLOR_MANAGER_OSCURO if (_cambio_sale != "" and _cambio_entra != "") else Estilos_UI.TINTA_SUAVE, 600))

	var btn_confirmar := Estilo_Manager.boton("Confirmar cambio", "exito", "check",
		Estilos_UI.EXITO, 48)
	btn_confirmar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_confirmar.disabled = _cambio_sale == "" or _cambio_entra == "" \
		or cambios >= Datos_Manager.CAMBIOS_MAXIMOS
	btn_confirmar.pressed.connect(_Confirmar_Cambio)
	pv.add_child(btn_confirmar)


func _Crear_Fila_Jugador_Cambio(jugador: Dictionary, rol_txt: String, energia_val: float,
		cols: Array, patron: int, seleccionado: bool, al_tocar: Callable) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", Estilos_UI.caja(
		Estilo_Manager.COLOR_MANAGER_SUAVE if seleccionado else Estilos_UI.SUPERFICIE_2,
		12, Estilo_Manager.COLOR_MANAGER if seleccionado else Estilos_UI.BORDE,
		2 if seleccionado else 1, 0))
	var btn := Button.new()
	btn.flat = true
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.custom_minimum_size = Vector2(0, 54)
	btn.pressed.connect(al_tocar)
	card.add_child(btn)

	var m := MarginContainer.new()
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_theme_constant_override("margin_left", 10)
	m.add_theme_constant_override("margin_right", 10)
	m.add_theme_constant_override("margin_top", 6)
	m.add_theme_constant_override("margin_bottom", 6)
	card.add_child(m)

	var h := HBoxContainer.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", 10)
	m.add_child(h)

	h.add_child(Estilo_Manager.crear_retrato_jugador(jugador, cols, patron, 42, false, "retrato", true))

	var info := VBoxContainer.new()
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	h.add_child(info)
	info.add_child(Estilos_UI.texto(str(jugador.get("nombre", "")), 13, Estilos_UI.TINTA, 700))
	info.add_child(Estilos_UI.texto("%s · Cal %.1f · %s" % [
		rol_txt, float(jugador.get("calidad", 0.0)),
		"★".repeat(clampi(int(jugador.get("estrellas", 1)), 1, 7))],
		11, Estilos_UI.TINTA_SUAVE, 600))

	var e_col := VBoxContainer.new()
	e_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	e_col.custom_minimum_size = Vector2(72, 0)
	e_col.alignment = BoxContainer.ALIGNMENT_CENTER
	e_col.add_theme_constant_override("separation", 3)
	h.add_child(e_col)
	var col_e: Color = Estilos_UI.color_valor(energia_val)
	var lbl_e := Estilos_UI.texto("%d%%" % int(round(energia_val)), 12, col_e, 700)
	lbl_e.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	e_col.add_child(lbl_e)
	var bar := ProgressBar.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.custom_minimum_size = Vector2(72, 7)
	bar.show_percentage = false
	bar.max_value = 100.0
	bar.value = clampf(energia_val, 0.0, 100.0)
	bar.add_theme_stylebox_override("background", Estilos_UI.barra_fondo())
	bar.add_theme_stylebox_override("fill", Estilos_UI.barra_relleno(col_e))
	e_col.add_child(bar)

	return card


func _Confirmar_Cambio() -> void:
	if _cambio_sale == "" or _cambio_entra == "":
		return
	var resultado: Dictionary = Sistema_Manager.Sustituir_Jugador_Partido(
		_cambio_sale, _cambio_entra)
	if not bool(resultado.get("ok", false)):
		_Mensaje_Modal(str(resultado.get("motivo", "")))
		return
	Estilo_Manager.reproducir_sfx("ding")
	_cambio_sale = ""
	_cambio_entra = ""
	_Cerrar_Modal_Cambios()
	_Anadir_Nuevos_Eventos()
	_Actualizar_Todo()


func _Mensaje_Modal(texto: String) -> void:
	var dlg := AcceptDialog.new()
	dlg.title = "Cambio"
	dlg.dialog_text = texto
	dlg.ok_button_text = "Entendido"
	add_child(dlg)
	Estilos_UI.estilizar_dialogo(dlg)
	dlg.popup_centered(Vector2i(540, 200))
	Estilos_UI.fijar_tamano_dialogo(dlg, Vector2i(540, 200))
	dlg.confirmed.connect(dlg.queue_free)
	dlg.close_requested.connect(dlg.queue_free)


# ------------------------------------------------------------------
# Resultado y salida
# ------------------------------------------------------------------

func _Mostrar_Resultado() -> void:
	if _resultado_mostrado or _estado.is_empty():
		return
	_resultado_mostrado = true
	_jugando = false
	_Cerrar_Modal_Descanso()
	_Cerrar_Modal_Cambios()

	var goles_local: int = int(_estado.get("goles_local", 0))
	var goles_visitante: int = int(_estado.get("goles_visitante", 0))
	var lado_usuario: String = str(_estado.get("lado_usuario", "local"))
	var goles_favor: int = goles_local if lado_usuario == "local" else goles_visitante
	var goles_contra: int = goles_visitante if lado_usuario == "local" else goles_local

	if goles_favor > goles_contra:
		Estilo_Manager.reproducir_sfx("level_end")
	elif goles_favor < goles_contra:
		Estilo_Manager.reproducir_sfx("angry")
	else:
		Estilo_Manager.reproducir_sfx("ding")

	var overlay := ColorRect.new()
	overlay.color = Color(0.03, 0.05, 0.09, 0.80)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 30
	add_child(overlay)
	_modal_resultado = overlay
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(centro)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(820, 0)
	card.add_theme_stylebox_override("panel", Estilos_UI.caja(
		Estilos_UI.SUPERFICIE, 22, Estilos_UI.BORDE_FUERTE, 1, 5))
	centro.add_child(card)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 20)
	m.add_theme_constant_override("margin_right", 20)
	m.add_theme_constant_override("margin_top", 18)
	m.add_theme_constant_override("margin_bottom", 18)
	card.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	m.add_child(v)

	var titulo_resultado: String = "Empate"
	var color_resultado: Color = Estilos_UI.AVISO
	var expr_coach: String = "neutral"
	var frase_coach: String = "«Un punto trabajado. Seguimos mejorando cada día.»"
	if goles_favor > goles_contra:
		titulo_resultado = "¡Victoria!"
		color_resultado = Estilos_UI.EXITO
		expr_coach = "feliz"
		frase_coach = "«¡Gran partido, equipo! La afición se va orgullosa a casa.»"
	elif goles_favor < goles_contra:
		titulo_resultado = "Derrota"
		color_resultado = Estilos_UI.PELIGRO
		expr_coach = "cansado"
		frase_coach = "«Toca levantar la cabeza y analizar los fallos en el entrenamiento.»"

	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 12)
	v.add_child(cab)
	var cols_u: Array = _colores_local if lado_usuario == "local" else _colores_visitante
	cab.add_child(Estilo_Manager.crear_retrato_manager(64, cols_u, expr_coach, false))
	var tit_v := VBoxContainer.new()
	tit_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tit_v.add_theme_constant_override("separation", 2)
	cab.add_child(tit_v)
	tit_v.add_child(Estilos_UI.titulo(titulo_resultado, 26, color_resultado))
	var tipo_txt: String = "Partido amistoso" if bool(_estado.get("es_amistoso", false)) \
		else "Temporada %d · Jornada %d" % [
			int(_estado.get("temporada", 1)), int(_estado.get("jornada", 0)) + 1]
	tit_v.add_child(Estilos_UI.texto("Final · %s" % tipo_txt, 12, Estilos_UI.TINTA_SUAVE, 600))
	tit_v.add_child(Estilos_UI.parrafo(frase_coach, 11, Estilos_UI.TINTA_SUAVE))

	# Marcador final con escudos.
	var marcador_box := PanelContainer.new()
	marcador_box.add_theme_stylebox_override("panel", Estilos_UI.caja(
		Estilos_UI.SUPERFICIE_2, 16, Estilos_UI.BORDE, 1, 0))
	v.add_child(marcador_box)
	var mm := MarginContainer.new()
	mm.add_theme_constant_override("margin_left", 14)
	mm.add_theme_constant_override("margin_right", 14)
	mm.add_theme_constant_override("margin_top", 12)
	mm.add_theme_constant_override("margin_bottom", 12)
	marcador_box.add_child(mm)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	mm.add_child(fila)

	var local_v := VBoxContainer.new()
	local_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	local_v.add_theme_constant_override("separation", 4)
	fila.add_child(local_v)
	var cl := Cresta_Manager.new()
	cl.custom_minimum_size = Vector2(48, 48)
	cl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cl.configurar(str(_estado.get("local_nombre", "")), _colores_local, _patron_local, false)
	local_v.add_child(cl)
	var nl := Estilos_UI.texto(str(_estado.get("local_nombre", "")), 12, Estilos_UI.TINTA, 700)
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	local_v.add_child(nl)

	var marcador_final := Estilos_UI.titulo("%d - %d" % [goles_local, goles_visitante],
		40, Estilos_UI.TINTA)
	marcador_final.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marcador_final.custom_minimum_size = Vector2(150, 0)
	fila.add_child(marcador_final)

	var vis_v := VBoxContainer.new()
	vis_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vis_v.add_theme_constant_override("separation", 4)
	fila.add_child(vis_v)
	var cv := Cresta_Manager.new()
	cv.custom_minimum_size = Vector2(48, 48)
	cv.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cv.configurar(str(_estado.get("visitante_nombre", "")), _colores_visitante, _patron_visitante, false)
	vis_v.add_child(cv)
	var nv := Estilos_UI.texto(str(_estado.get("visitante_nombre", "")), 12, Estilos_UI.TINTA, 700)
	nv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nv.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vis_v.add_child(nv)

	var split_res := HBoxContainer.new()
	split_res.add_theme_constant_override("separation", 18)
	v.add_child(split_res)

	var col_goles := VBoxContainer.new()
	col_goles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_goles.add_theme_constant_override("separation", 4)
	split_res.add_child(col_goles)
	var goleadores: Array = []
	for lado in ["local", "visitante"]:
		var lista = _estado.get("goleadores_%s" % lado, [])
		if lista is Array:
			for gol in lista:
				if gol is Dictionary:
					goleadores.append("%d' %s (%s)" % [
						int(gol.get("minuto", 0)), str(gol.get("nombre", "")),
						str(_estado.get("%s_nombre" % lado, ""))])
	if goleadores.is_empty():
		col_goles.add_child(Estilos_UI.parrafo("Partido sin goles.", 12, Estilos_UI.TINTA_SUAVE))
	else:
		col_goles.add_child(Estilos_UI.texto("GOLES", 10, Estilos_UI.TINTA_FANTASMA, 700))
		for i_g in range(mini(6, goleadores.size())):
			col_goles.add_child(Estilos_UI.texto("⚽ " + str(goleadores[i_g]), 12, Estilos_UI.TINTA, 600))

	var col_stats_r := VBoxContainer.new()
	col_stats_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_stats_r.add_theme_constant_override("separation", 8)
	split_res.add_child(col_stats_r)
	var pos_l: float = Simulador_Manager.Posesion_Local(_estado)
	var col_l: Color = Color(str(_colores_local[0]))
	var col_v: Color = Color(str(_colores_visitante[0]))
	if Vector3(col_l.r - col_v.r, col_l.g - col_v.g, col_l.b - col_v.b).length() < 0.25:
		col_v = Estilos_UI.AZUL
	col_stats_r.add_child(Estilo_Manager.barra_comparativa("Posesión", pos_l, 100.0 - pos_l,
		"%d%%" % int(round(pos_l)), "%d%%" % int(round(100.0 - pos_l)), col_l, col_v, false))
	var tl: int = int(_estado.get("tiros_local", 0))
	var tv: int = int(_estado.get("tiros_visitante", 0))
	col_stats_r.add_child(Estilo_Manager.barra_comparativa("Tiros", float(tl), float(tv),
		str(tl), str(tv), col_l, col_v, false))

	var ingresos: int = int(_estado.get("ingresos_%s" % lado_usuario, 0))
	if ingresos > 0:
		col_stats_r.add_child(Estilos_UI.pill_estado("Ingresos para el club: +%d €" % ingresos,
			Estilos_UI.EXITO_SUAVE, Estilos_UI.EXITO_OSCURO))

	var btn_volver := Estilo_Manager.boton("Volver al club", "exito", "arrow-left",
		Estilos_UI.EXITO, 50)
	btn_volver.pressed.connect(_Cerrar)
	v.add_child(btn_volver)


func _Intentar_Salir() -> void:
	if bool(_estado.get("finalizado", false)):
		_Cerrar()
		return
	var was_paused: bool = _pausado
	_pausado = true
	var dlg := ConfirmationDialog.new()
	dlg.title = "Salir del partido"
	dlg.dialog_text = "Si sales ahora, el resto del partido se simulará automáticamente y el resultado se aplicará igualmente."
	dlg.ok_button_text = "Salir y simular"
	dlg.get_cancel_button().text = "Seguir viendo"
	dlg.confirmed.connect(func():
		Sistema_Manager.Simular_Resto_Partido()
		_jugando = false
		_Anadir_Nuevos_Eventos()
		_Actualizar_Todo()
		_Mostrar_Resultado()
		dlg.queue_free())
	dlg.canceled.connect(func():
		_pausado = was_paused
		_Actualizar_Todo()
		dlg.queue_free())
	dlg.close_requested.connect(func():
		_pausado = was_paused
		_Actualizar_Todo()
		dlg.queue_free())
	add_child(dlg)
	Estilos_UI.estilizar_dialogo(dlg)
	dlg.popup_centered(Vector2i(580, 250))
	Estilos_UI.fijar_tamano_dialogo(dlg, Vector2i(580, 250))


func _Cerrar() -> void:
	Estilo_Manager.reproducir_sfx("click")
	_Cerrar_Modal_Descanso()
	_Cerrar_Modal_Cambios()
	cerrado.emit()
	queue_free()
