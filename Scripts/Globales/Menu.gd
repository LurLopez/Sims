extends Control

const INTRO_NUEVA_PARTIDA := preload("res://Scripts/GUI/Menu/Intro_Nueva_Partida.gd")
const CREADOR_PERSONAJE := preload("res://Scripts/GUI/Menu/Creador_Personaje.gd")

@onready var contenido: Control = $Contenido

var _boton_principal: Button
var _boton_ajustes: Button
var _panel_ajustes: Panel_Ajustes
var _intro_en_curso := false
var _creador_abierto: CanvasLayer
var _modal_confirmacion: CanvasLayer
var _modo_rapido_seleccionado: bool = false


func _ready() -> void:
	Guardar_Variables_Estaticas.load_game()
	Guardar_Variables_Dinamicas.load_game()
	Musica.Reproducir_General()
	_construir_menu()
	_animar_entrada()
	get_viewport().size_changed.connect(_Ajustar_Pie)

	if Variables_Dinamicas.Muerto:
		_Mostrar_Game_Over()


# Alto visible en coordenadas de diseño; crece en pantallas más alargadas que 16:9.
func _Alto_Pantalla() -> float:
	var alto: float = get_viewport().get_visible_rect().size.y
	return alto if alto >= 1280.0 else 1280.0


func _Ajustar_Pie() -> void:
	var pie := contenido.get_node_or_null("Pie_Menu") as Control
	if pie != null:
		pie.position = Vector2(24, _Alto_Pantalla() - 64.0)


func _abrir_ajustes() -> void:
	if _intro_en_curso or _creador_abierto != null or _modal_confirmacion != null:
		return
	if _panel_ajustes != null and is_instance_valid(_panel_ajustes):
		return
	_panel_ajustes = Panel_Ajustes.new()
	_panel_ajustes.cerrado.connect(func(): _panel_ajustes = null)
	add_child(_panel_ajustes)


func _construir_menu() -> void:
	for hijo in contenido.get_children():
		hijo.queue_free()

	# Banda superior BitLife crimson con franjas diagonales sutiles
	var banda := Estilos_UI.BannerRayasBitLife.new(Estilos_UI.ROJO_BIT, Estilos_UI.ROJO_BIT_OSCURO, 4.0, 0.065)
	banda.position = Vector2.ZERO
	banda.size = Vector2(720, 296)
	contenido.add_child(banda)

	# --- Marca: insignia con la cara real del Sim + wordmark ---
	var header := HBoxContainer.new()
	header.position = Vector2(22, 62)
	header.size = Vector2(676, 112)
	header.add_theme_constant_override("separation", 12)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contenido.add_child(header)

	var marca := Logo_Juego.new()
	marca.name = "Logo_Juego"
	marca.tamano_insignia = 104
	marca.animar_retrato = true
	marca.subtitulo = "Simulador de vida en tiempo real"
	marca.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(marca)

	var version_pill := Estilos_UI.pill_estado("v0.33", Color(0, 0, 0, 0.24), Color.WHITE)
	version_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(version_pill)

	# Un único botón de ajustes: desde el panel se regulan la música y los
	# efectos de sonido.
	_boton_ajustes = Estilos_UI.boton_icono("settings", Estilos_UI.ROJO_BIT, 40)
	_boton_ajustes.name = "Boton_Ajustes"
	_boton_ajustes.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_boton_ajustes.tooltip_text = "Ajustes de sonido"
	_boton_ajustes.pressed.connect(_abrir_ajustes)
	header.add_child(_boton_ajustes)

	# --- Tarjeta principal ---
	var card := PanelContainer.new()
	card.name = "Card"
	card.position = Vector2(20, 184)
	card.size = Vector2(680, 0)
	card.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(18, 3))
	contenido.add_child(card)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 24)
	m.add_theme_constant_override("margin_right", 24)
	m.add_theme_constant_override("margin_top", 24)
	m.add_theme_constant_override("margin_bottom", 24)
	card.add_child(m)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 20)
	m.add_child(v)

	if Variables_Estaticas.First_Time:
		_construir_tarjeta_nueva_partida(v)
	else:
		_construir_tarjeta_partida_activa(v)

	var pie := Estilos_UI.texto("Partida guardada localmente en el dispositivo", 12, Estilos_UI.TINTA_FANTASMA)
	pie.name = "Pie_Menu"
	pie.position = Vector2(24, _Alto_Pantalla() - 64.0)
	pie.size = Vector2(672, 24)
	pie.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	contenido.add_child(pie)


func _construir_tarjeta_nueva_partida(v: VBoxContainer) -> void:
	var cabecera := VBoxContainer.new()
	cabecera.add_theme_constant_override("separation", 8)
	v.add_child(cabecera)

	cabecera.add_child(Estilos_UI.pill_estado("NUEVA VIDA", Estilos_UI.PRIMARIO_SUAVE, Estilos_UI.PRIMARIO))
	cabecera.add_child(Estilos_UI.titulo("Empieza a los 18 años", 26, Estilos_UI.TINTA))
	cabecera.add_child(Estilos_UI.parrafo(
		"Organiza tu semana en tiempo real, cuida tus necesidades, estudia una carrera o busca empleo.",
		15, Estilos_UI.TINTA_SUAVE))

	v.add_child(Estilos_UI.divisor_horizontal())

	var datos := HBoxContainer.new()
	datos.add_theme_constant_override("separation", 10)
	v.add_child(datos)
	var lbl_capital: Label = null
	var lbl_alquiler: Label = null
	for item in [
		["Edad inicial", "18 años", "sparkles", Estilos_UI.AZUL, Estilos_UI.AZUL_SUAVE, "edad"],
		["Capital", "1.000 €", "banknote", Estilos_UI.EXITO, Estilos_UI.EXITO_SUAVE, "capital"],
		["Alquiler", "200 €/sem", "house", Estilos_UI.ORO, Estilos_UI.ORO_SUAVE, "alquiler"],
	]:
		var box := PanelContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var st_box := Estilos_UI.caja(item[4], 14, Color(item[3], 0.22), 1, 0)
		st_box.border_width_bottom = 2
		box.add_theme_stylebox_override("panel", st_box)
		var bm := MarginContainer.new()
		bm.add_theme_constant_override("margin_left", 12)
		bm.add_theme_constant_override("margin_right", 12)
		bm.add_theme_constant_override("margin_top", 12)
		bm.add_theme_constant_override("margin_bottom", 12)
		box.add_child(bm)
		var bv := VBoxContainer.new()
		bv.add_theme_constant_override("separation", 6)
		bm.add_child(bv)
		var ic_row := HBoxContainer.new()
		ic_row.add_theme_constant_override("separation", 6)
		ic_row.add_child(Estilos_UI.badge_icono(item[2], 24, 13, item[3], Color.WHITE, 7))
		ic_row.add_child(Estilos_UI.texto(item[0], 12, Estilos_UI.TINTA_SUAVE, 600))
		bv.add_child(ic_row)
		var val_lbl := Estilos_UI.titulo(item[1], 18, Estilos_UI.TINTA)
		bv.add_child(val_lbl)
		if item[5] == "capital":
			lbl_capital = val_lbl
		elif item[5] == "alquiler":
			lbl_alquiler = val_lbl
		datos.add_child(box)

	var actualizar_datos := func(es_rapido: bool):
		if lbl_capital != null:
			lbl_capital.text = "100 €" if es_rapido else "1.000 €"
		if lbl_alquiler != null:
			lbl_alquiler.text = "20 €/día" if es_rapido else "200 €/sem"
	actualizar_datos.call(_modo_rapido_seleccionado)

	v.add_child(_crear_selector_modo(actualizar_datos))

	var boton := Estilos_UI.boton("Empezar nueva vida", "exito", "play", Estilos_UI.EXITO, 60)
	boton.add_theme_font_override("font", Estilos_UI.fuente_titulo(700))
	boton.add_theme_font_size_override("font_size", 19)
	boton.pressed.connect(_on_continuar)
	v.add_child(boton)
	_boton_principal = boton


func _construir_tarjeta_partida_activa(v: VBoxContainer) -> void:
	# Cabecera personaje + saldo destacado
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	v.add_child(top)

	var borde_av := Estilos_UI.PELIGRO if Variables_Dinamicas.En_La_Calle else Estilos_UI.EXITO
	var avatar := Estilos_UI.avatar_personaje(60, borde_av, 3, {}, true)
	top.add_child(avatar)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 2)
	top.add_child(info)

	var edad := Variables_Estaticas.Calcular_Edad()
	var personalidad := Variables_Estaticas.Personalidad.replace("_", " ").capitalize()
	var nombre_prota := str(Variables_Estaticas.Apariencia.get("nombre", "")).strip_edges()
	var titulo_vida := nombre_prota if nombre_prota != "" else "Tu vida en curso"
	var modo_txt := " · Modo Rápido" if Variables_Estaticas.Modo_Rapido else ""
	info.add_child(Estilos_UI.titulo(titulo_vida, 20, Estilos_UI.TINTA))
	info.add_child(Estilos_UI.texto("%d años · %s%s" % [max(18, edad), personalidad, modo_txt], 13, Estilos_UI.TINTA_SUAVE, 600))

	var color_dinero := Estilos_UI.EXITO if Variables_Dinamicas.Dinero >= 0 else Estilos_UI.PELIGRO
	var fondo_dinero := Estilos_UI.EXITO_SUAVE if Variables_Dinamicas.Dinero >= 0 else Estilos_UI.PELIGRO_SUAVE
	var saldo_pill := PanelContainer.new()
	saldo_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var st_sp := Estilos_UI.caja(fondo_dinero, 14, Color(color_dinero, 0.28), 1, 0)
	st_sp.border_width_bottom = 2
	saldo_pill.add_theme_stylebox_override("panel", st_sp)
	var spm := MarginContainer.new()
	spm.add_theme_constant_override("margin_left", 14)
	spm.add_theme_constant_override("margin_right", 14)
	spm.add_theme_constant_override("margin_top", 8)
	spm.add_theme_constant_override("margin_bottom", 8)
	saldo_pill.add_child(spm)
	var saldo_box := VBoxContainer.new()
	saldo_box.alignment = BoxContainer.ALIGNMENT_CENTER
	saldo_box.add_theme_constant_override("separation", 0)
	spm.add_child(saldo_box)

	var lbl_saldo := Estilos_UI.texto("SALDO", 10, color_dinero, 700)
	lbl_saldo.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	saldo_box.add_child(lbl_saldo)

	var dinero_lbl := Estilos_UI.titulo("%d €" % int(Variables_Dinamicas.Dinero), 20, color_dinero)
	dinero_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	saldo_box.add_child(dinero_lbl)
	top.add_child(saldo_pill)

	# Chips reales de situación actual
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 8)
	v.add_child(chips)

	if Variables_Dinamicas.En_La_Calle:
		chips.add_child(Estilos_UI.pill_estado("Sin vivienda", Estilos_UI.PELIGRO_SUAVE, Estilos_UI.PELIGRO))
	else:
		chips.add_child(Estilos_UI.pill_estado("Con alquiler", Estilos_UI.EXITO_SUAVE, Estilos_UI.EXITO))

	if Variables_Dinamicas.Trabajo_Actual != null:
		var nombre_t := str(Variables_Dinamicas.Trabajo_Actual.nombre).replace("Trabajar_En_", "").replace("Trabajar_De_", "").replace("_", " ")
		chips.add_child(Estilos_UI.pill_estado(nombre_t, Estilos_UI.PRIMARIO_SUAVE, Estilos_UI.PRIMARIO))
	else:
		chips.add_child(Estilos_UI.pill_estado("Sin empleo", Estilos_UI.SUPERFICIE_2, Estilos_UI.TINTA_SUAVE))

	if Variables_Dinamicas.Carrera_Actual != null:
		var nombre_c := str(Variables_Dinamicas.Carrera_Actual.nombre).replace("_", " ")
		chips.add_child(Estilos_UI.pill_estado(nombre_c, Estilos_UI.ORO_SUAVE, Estilos_UI.ORO))

	# Escenario animado en vivo del personaje elegido en la pantalla de inicio
	var escenario_inicio := Escenario_Actividad.new()
	escenario_inicio.custom_minimum_size = Vector2(0, 184)
	v.add_child(escenario_inicio)
	escenario_inicio.actualizar_estado(
		_obtener_actividad_actual_menu(),
		Variables_Dinamicas.En_La_Calle,
		Sistema_Cocina.Obtener_Apariencia_Con_Ropa_Equipada(Variables_Estaticas.Apariencia),
		int(Variables_Dinamicas.Minute_Minute),
		str(Variables_Dinamicas.Objeto_Seleccionado.get("Comer", "Mesa_Basica")),
		str(Variables_Estaticas.Personalidad)
	)

	v.add_child(Estilos_UI.divisor_horizontal())

	# Barras estilo BitLife con iconos y profundidad
	var salud := float(Variables_Dinamicas.Necesidades_Basicas[0]) if Variables_Dinamicas.Necesidades_Basicas.size() > 0 else 50.0
	var mental := float(Variables_Dinamicas.Necesidades_Basicas[1]) if Variables_Dinamicas.Necesidades_Basicas.size() > 1 else 50.0
	var descanso := float(Variables_Dinamicas.Necesidades_Basicas[3]) if Variables_Dinamicas.Necesidades_Basicas.size() > 3 else 50.0
	var academico := float(Variables_Dinamicas.Progreso[1]) if Variables_Dinamicas.Progreso.size() > 1 else 1.0

	var stats := VBoxContainer.new()
	stats.add_theme_constant_override("separation", 12)
	v.add_child(stats)

	_agregar_barra(stats, "Salud física", "heart-pulse", salud, Estilos_UI.color_valor(salud))
	_agregar_barra(stats, "Salud mental", "brain", mental, Estilos_UI.color_valor(mental))
	_agregar_barra(stats, "Descanso", "moon", descanso, Estilos_UI.color_valor(descanso))
	_agregar_barra(stats, "Progreso académico", "book-open", academico, Estilos_UI.AZUL)

	v.add_child(Estilos_UI.separador(4))

	var boton := Estilos_UI.boton("Continuar vida", "exito", "play", Estilos_UI.EXITO, 60)
	boton.add_theme_font_override("font", Estilos_UI.fuente_titulo(700))
	boton.add_theme_font_size_override("font_size", 19)
	boton.pressed.connect(_on_continuar)
	v.add_child(boton)

	var btn_nueva := Estilos_UI.boton("Nueva partida", "suave", "sparkles", Estilos_UI.PELIGRO, 48)
	btn_nueva.add_theme_font_size_override("font_size", 15)
	btn_nueva.pressed.connect(_pedir_confirmacion_nueva_partida)
	v.add_child(btn_nueva)

	var fecha_txt := Funciones_Globales.Convertir_Minuto_A_Fecha_Hora(
		Variables_Dinamicas.Minute_Day * 1440 + Variables_Dinamicas.Minute_Minute)
	var nota := Estilos_UI.texto("Último registro: %s" % fecha_txt, 12, Estilos_UI.TINTA_FANTASMA)
	nota.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nota)


func _obtener_actividad_actual_menu() -> String:
	var dia: int = int(Variables_Dinamicas.Minute_Day)
	var min_dia: int = int(Variables_Dinamicas.Minute_Minute)
	if Variables_Dinamicas.Matriz_Jugador.size() <= min_dia or min_dia < 0:
		return ""
	var fila = Variables_Dinamicas.Matriz_Jugador[min_dia]
	if not (fila is Array) or fila.size() <= dia or dia < 0:
		return ""
	var celda = fila[dia]
	if celda is String:
		if celda == "" or celda == "Actividad_Aleatoria":
			return ""
		return str(celda)
	if celda is Actividad:
		return str(celda.nombre)
	return ""


func _agregar_barra(parent: VBoxContainer, etiqueta: String, nombre_icono: String, valor: float, color_fill: Color) -> void:
	var fila := VBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	parent.add_child(fila)

	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 8)
	fila.add_child(cab)

	cab.add_child(Estilos_UI.badge_icono(nombre_icono, 24, 13, color_fill, Color.WHITE, 7))

	var lbl := Estilos_UI.texto(etiqueta, 14, Estilos_UI.TINTA, 600)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(lbl)

	var pct := Estilos_UI.texto("%d%%" % int(round(valor)), 13, color_fill, 700)
	cab.add_child(pct)

	var barra := ProgressBar.new()
	barra.custom_minimum_size = Vector2(0, 16)
	barra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	barra.show_percentage = false
	barra.max_value = 100
	barra.value = clampf(valor, 0, 100)
	barra.add_theme_stylebox_override("background", Estilos_UI.barra_fondo())
	barra.add_theme_stylebox_override("fill", Estilos_UI.barra_relleno(color_fill))
	fila.add_child(barra)


func _animar_entrada() -> void:
	var card := contenido.get_node_or_null("Card")
	if card != null:
		card.modulate.a = 0.0
		card.position.y += 12.0
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(card, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(card, "position:y", card.position.y - 12.0, 0.34).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _unhandled_input(event: InputEvent) -> void:
	if _intro_en_curso or _creador_abierto != null or _panel_ajustes != null:
		return
	if _modal_confirmacion != null:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_cerrar_confirmacion_nueva_partida()
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
			get_viewport().set_input_as_handled()
			_on_continuar()


func _on_continuar() -> void:
	if _intro_en_curso or _creador_abierto != null or _panel_ajustes != null:
		return
	if Variables_Estaticas.First_Time:
		_abrir_creador_personaje(false)
		return
	_ir_a_escena_principal()


func _abrir_creador_personaje(reiniciar_al_confirmar: bool) -> void:
	if _intro_en_curso or _creador_abierto != null:
		return
	var creador := CREADOR_PERSONAJE.new()
	_creador_abierto = creador
	creador.confirmado.connect(func(apariencia: Dictionary, origen_boton: Vector2):
		_creador_abierto = null
		if reiniciar_al_confirmar:
			_reiniciar_partida_desde_cero()
		Variables_Estaticas.Modo_Rapido = _modo_rapido_seleccionado
		Variables_Estaticas.Apariencia = Apariencia_Personaje.normalizar(apariencia)
		var pers_elegida := str(Variables_Estaticas.Apariencia.get("personalidad", ""))
		if pers_elegida != "":
			Variables_Estaticas.Personalidad = pers_elegida
		_reproducir_intro_nueva_partida(origen_boton, Variables_Estaticas.Apariencia))
	creador.cancelado.connect(func():
		_creador_abierto = null)
	add_child(creador)


func _ir_a_escena_principal(titulo: String = "Tu vida continúa",
		subtitulo: String = "Cargando tu partida…",
		pildora: String = "", fundido_entrada: bool = true) -> void:
	Pantalla_Carga.Ir_A_Escena_Principal(titulo, subtitulo, pildora, fundido_entrada)


# Animación de bienvenida que solo se ve al empezar una nueva partida.
func _reproducir_intro_nueva_partida(origen_personalizado: Vector2 = Vector2(-1, -1),
		apariencia_elegida: Dictionary = {}) -> void:
	_intro_en_curso = true
	# Ve cargando la escena principal mientras se disfruta del cómic.
	Pantalla_Carga.Precargar(Pantalla_Carga.RUTA_ESCENA_PRINCIPAL)
	var intro := INTRO_NUEVA_PARTIDA.new()
	intro.apariencia = Apariencia_Personaje.normalizar(
		apariencia_elegida if not apariencia_elegida.is_empty() else Variables_Estaticas.Apariencia
	)
	if origen_personalizado.x >= 0.0:
		intro.origen = origen_personalizado
	elif _boton_principal != null:
		intro.origen = _boton_principal.get_global_rect().get_center()
	intro.terminada.connect(func():
		_ir_a_escena_principal(
			Pantalla_Carga.TITULO_NUEVA_VIDA,
			Pantalla_Carga.SUB_NUEVA_VIDA,
			Pantalla_Carga.PILL_NUEVA_VIDA,
			false))
	add_child(intro)


func _pedir_confirmacion_nueva_partida() -> void:
	if _intro_en_curso or _modal_confirmacion != null:
		return

	var capa := CanvasLayer.new()
	capa.layer = 100
	add_child(capa)
	_modal_confirmacion = capa

	var velo := ColorRect.new()
	velo.color = Color(0.06, 0.09, 0.15, 0.65)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(velo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(centro)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(580, 0)
	card.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	card.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(18, 3))
	centro.add_child(card)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	card.add_child(outer)

	var banda_modal := Estilos_UI.BannerRayasBitLife.new(Estilos_UI.ROJO_BIT, Estilos_UI.ROJO_BIT_OSCURO, 3.0, 0.08)
	banda_modal.custom_minimum_size = Vector2(0, 62)
	outer.add_child(banda_modal)

	var bm_row := HBoxContainer.new()
	bm_row.set_anchors_preset(Control.PRESET_FULL_RECT)
	bm_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bm_row.add_theme_constant_override("separation", 10)
	banda_modal.add_child(bm_row)
	bm_row.add_child(Estilos_UI.icono_rect("sparkles", 20, Color.WHITE))
	bm_row.add_child(Estilos_UI.titulo("NUEVA PARTIDA", 18, Color.WHITE))

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 28)
	m.add_theme_constant_override("margin_right", 28)
	m.add_theme_constant_override("margin_top", 24)
	m.add_theme_constant_override("margin_bottom", 26)
	outer.add_child(m)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	m.add_child(v)

	var titulo_cab := Estilos_UI.titulo("¿Empezar desde cero?", 24, Estilos_UI.TINTA)
	titulo_cab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(titulo_cab)

	var aviso := Estilos_UI.parrafo(
		"Se borrará todo tu progreso actual (dinero, estudios, empleo y calendario) y empezarás una nueva vida a los 18 años.",
		15, Estilos_UI.TINTA_SUAVE)
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(aviso)

	v.add_child(_crear_selector_modo(Callable()))
	v.add_child(Estilos_UI.separador(6))

	var botones := HBoxContainer.new()
	botones.add_theme_constant_override("separation", 12)
	v.add_child(botones)

	var btn_cancelar := Estilos_UI.boton("Cancelar", "secundario", "", Estilos_UI.TINTA, 50)
	btn_cancelar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_cancelar.pressed.connect(_cerrar_confirmacion_nueva_partida)
	botones.add_child(btn_cancelar)

	var btn_confirmar := Estilos_UI.boton("Sí, empezar", "peligro", "play", Estilos_UI.PELIGRO, 50)
	btn_confirmar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_confirmar.pressed.connect(func():
		var centro_btn := btn_confirmar.get_global_rect().get_center()
		_confirmar_nueva_partida(centro_btn))
	botones.add_child(btn_confirmar)


func _cerrar_confirmacion_nueva_partida() -> void:
	if _modal_confirmacion != null:
		_modal_confirmacion.queue_free()
		_modal_confirmacion = null


func _confirmar_nueva_partida(_origen_boton: Vector2) -> void:
	_cerrar_confirmacion_nueva_partida()
	_abrir_creador_personaje(true)


func _crear_selector_modo(on_cambio: Callable) -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)

	var btn_normal := Estilos_UI.boton("Normal (1 año = 7 días)", "secundario", "", Estilos_UI.TINTA, 44)
	btn_normal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var btn_rapido := Estilos_UI.boton("Rápido (1 año = 1 día)", "secundario", "", Estilos_UI.PRIMARIO, 44)
	btn_rapido.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var refrescar := func():
		if _modo_rapido_seleccionado:
			Estilos_UI.aplicar_estilo_boton(btn_normal, "secundario", Estilos_UI.TINTA_SUAVE)
			Estilos_UI.aplicar_estilo_boton(btn_rapido, "primario", Estilos_UI.PRIMARIO)
		else:
			Estilos_UI.aplicar_estilo_boton(btn_normal, "primario", Estilos_UI.PRIMARIO)
			Estilos_UI.aplicar_estilo_boton(btn_rapido, "secundario", Estilos_UI.TINTA_SUAVE)
		if on_cambio.is_valid():
			on_cambio.call(_modo_rapido_seleccionado)

	btn_normal.pressed.connect(func():
		_modo_rapido_seleccionado = false
		refrescar.call())
	btn_rapido.pressed.connect(func():
		_modo_rapido_seleccionado = true
		refrescar.call())

	refrescar.call()
	fila.add_child(btn_normal)
	fila.add_child(btn_rapido)
	return fila


func _reiniciar_partida_desde_cero() -> void:
	Variables_Estaticas.First_Time = true
	Variables_Estaticas.Modo_Rapido = false
	Variables_Estaticas.Tutorial_Completado = false
	Variables_Estaticas.First_Time_Minute = 0
	Variables_Estaticas.Personalidad = ""
	Variables_Estaticas.Apariencia = Apariencia_Personaje.por_defecto()
	Variables_Estaticas.Habilidades = []
	Variables_Estaticas.First_Time_Minute_Day = 0
	Variables_Estaticas.First_Time_Minute_Minute = 0
	Variables_Estaticas.First_Time_Year = 0
	Variables_Estaticas.First_Time_Month = 0
	Variables_Estaticas.First_Time_Day_Of_Month = 0

	Variables_Dinamicas.Matriz_Jugador = []
	Variables_Dinamicas.Progreso = []
	Variables_Dinamicas.Necesidades_Basicas = []
	Variables_Dinamicas.Progreso_Cocina = 1
	Variables_Dinamicas.Tuppers = []
	Variables_Dinamicas.Tupper_Seleccionado_Idx = -1
	Variables_Dinamicas.Minutos_Cocinando_Actuales = 0
	Variables_Dinamicas.Habilidades_Mostradas = []
	Variables_Dinamicas.Habilidades_Cap_Notificado = [false, false, false, false, false, false, false]
	Variables_Dinamicas.Ultimo_Uso_Progreso = [-1, -1, -1]
	Variables_Dinamicas.Ultimo_Check_Decadencia = [-1, -1, -1]
	Variables_Dinamicas.Ultimas_Pistas_Progreso = []
	Variables_Dinamicas.Dinero = 0
	Variables_Dinamicas.En_La_Calle = false
	Variables_Dinamicas.Ultima_Fecha_Alquiler = -1
	Variables_Dinamicas.Trabajo_Actual = null
	Variables_Dinamicas.Objetos_Poseidos = {"Ropa_Calle": true}
	Variables_Dinamicas.Objeto_Seleccionado = {"Ropa": "Ropa_Calle"}
	Sistema_Cocina.Asegurar_Prendas_Iniciales()
	Variables_Dinamicas.Cocina_Estado = Variables_Dinamicas.Cocina_Estado_Por_Defecto()
	Variables_Dinamicas.Minute_Day = 0
	Variables_Dinamicas.Minute_Minute = 0
	Variables_Dinamicas.Minute = 0
	Variables_Dinamicas.Carrera_Actual = null
	Variables_Dinamicas.Carreras_Completadas = []
	Variables_Dinamicas.Inicio_Semana_Carrera = -1
	Variables_Dinamicas.Carrera_Deportiva_Pendiente = {
		"inscrito": false, "dia": -1, "hora_inicio": -1,
		"semana_inscripcion": -1, "total_inscritos": 0,
		"resultado_puesto": -1, "resultado_procesado": false
	}
	Variables_Dinamicas.Carrera_Futbol = Variables_Dinamicas.Carrera_Futbol_Por_Defecto()
	Variables_Dinamicas.Mensajes = []
	Variables_Dinamicas.Esta_Invirtiendo = false
	Variables_Dinamicas.Dinero_Invertido = 0.0
	Variables_Dinamicas.Valor_Inversion = 0.0
	Variables_Dinamicas.Salud_Mental_Al_Invertir = 50
	Variables_Dinamicas.Progreso_Inversion = 1
	Sistema_Bolsa.Reiniciar_Estado()
	Variables_Dinamicas.Cooldown_Trabajos = {}
	Variables_Dinamicas.Estados_Temporales = {}
	Variables_Dinamicas.Fiesta_Evento_Ocurrido = false
	Variables_Dinamicas.Muerto = false
	Variables_Dinamicas.Edad_Muerte = 0
	Variables_Dinamicas.Prob_Supervivencia_Acumulada = 1.0

	for ruta in [Guardar_Variables_Estaticas.save_path, Guardar_Variables_Dinamicas.save_path]:
		if FileAccess.file_exists(ruta):
			DirAccess.remove_absolute(ruta)


func _Mostrar_Game_Over() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 100
	add_child(capa)

	var velo := ColorRect.new()
	velo.color = Color(0.06, 0.09, 0.15, 0.65)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(velo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(centro)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(600, 0)
	card.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	card.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(18, 3))
	centro.add_child(card)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	card.add_child(outer)

	var banda_go := Estilos_UI.BannerRayasBitLife.new(Estilos_UI.NAVY, Estilos_UI.NAVY_OSCURO, 3.0, 0.06)
	banda_go.custom_minimum_size = Vector2(0, 68)
	outer.add_child(banda_go)

	var go_row := HBoxContainer.new()
	go_row.set_anchors_preset(Control.PRESET_FULL_RECT)
	go_row.alignment = BoxContainer.ALIGNMENT_CENTER
	go_row.add_theme_constant_override("separation", 10)
	banda_go.add_child(go_row)
	go_row.add_child(Estilos_UI.icono_rect("trophy", 20, Color("#fde047")))
	go_row.add_child(Estilos_UI.titulo("FIN DE LA VIDA", 19, Color.WHITE))

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 28)
	m.add_theme_constant_override("margin_right", 28)
	m.add_theme_constant_override("margin_top", 24)
	m.add_theme_constant_override("margin_bottom", 26)
	outer.add_child(m)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	m.add_child(v)

	var titulo_cab := Estilos_UI.titulo("Tu personaje ha fallecido", 26, Estilos_UI.TINTA)
	titulo_cab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(titulo_cab)

	var sub := Estilos_UI.texto("Vivió hasta los %d años" % Variables_Dinamicas.Edad_Muerte, 15, Estilos_UI.TINTA_SUAVE, 500)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)

	v.add_child(Estilos_UI.divisor_horizontal())

	var stats := VBoxContainer.new()
	stats.add_theme_constant_override("separation", 8)
	v.add_child(stats)
	_fila_resumen(stats, "Deporte", "%d / 100" % Variables_Dinamicas.Progreso[0])
	_fila_resumen(stats, "Académico", "%d / 100" % Variables_Dinamicas.Progreso[1])
	_fila_resumen(stats, "Manualidades", "%d / 100" % Variables_Dinamicas.Progreso[2])
	_fila_resumen(stats, "Dinero final", "%d €" % int(Variables_Dinamicas.Dinero))

	if Variables_Dinamicas.Carreras_Completadas.size() > 0:
		v.add_child(Estilos_UI.divisor_horizontal())
		v.add_child(Estilos_UI.texto("Carreras completadas", 12, Estilos_UI.TINTA_FANTASMA, 700))
		for c in Variables_Dinamicas.Carreras_Completadas:
			v.add_child(Estilos_UI.texto("· " + c.nombre.replace("_", " "), 14, Estilos_UI.PRIMARIO, 600))

	var btn := Estilos_UI.boton("Cerrar resumen", "primario", "", Estilos_UI.PRIMARIO, 52)
	btn.pressed.connect(func(): capa.queue_free())
	v.add_child(_crear_selector_modo(Callable()))
	v.add_child(Estilos_UI.separador(6))
	v.add_child(btn)


func _fila_resumen(parent: VBoxContainer, clave: String, valor: String) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var k := Estilos_UI.texto(clave, 14, Estilos_UI.TINTA_SUAVE, 500)
	k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(k)
	h.add_child(Estilos_UI.texto(valor, 14, Estilos_UI.TINTA, 700))
	parent.add_child(h)
