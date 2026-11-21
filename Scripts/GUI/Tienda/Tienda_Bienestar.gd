class_name Tienda_Bienestar
extends Control

# ============================================================================
# Pestaña "Bienestar" de la tienda.
#
# Presenta tres bloques, todos conectados con la partida real:
#   1. Héroe de la clínica: edad actual del Sim y años recuperados.
#   2. Tratamientos de rejuvenecimiento pagados con euros del juego.
#   3. Anuncios recompensados simulados (dinero, necesidades, comida, años).
#
# La pantalla es deliberadamente "tonta": no concede nada por su cuenta.
# Toda compra o anuncio pasa por el autoload Recompensas, que valida, aplica
# la recompensa y persiste sus esperas. Los modales son componentes
# independientes y emiten señales; aquí se orquesta el flujo.
# ============================================================================

const MODAL_TRATAMIENTO := preload("res://Scripts/GUI/Tienda/Modal_Tratamiento.gd")
const MODAL_ANUNCIO := preload("res://Scripts/GUI/Tienda/Modal_Anuncio_Bienestar.gd")
const SFX_COIN := preload("res://Sonidos/SFX/coin.wav")
const SFX_DING := preload("res://Sonidos/SFX/ding.wav")
const SFX_POP := preload("res://Sonidos/SFX/pop.wav")

const TEAL := Color("#0d9488")
const TEAL_SUAVE := Color("#ccfbf1")
const INDIGO := Color("#4f46e5")
const CORAL := Color("#e11d48")
const ORO := Color("#d97706")

var _scroll: ScrollContainer
var _contenido: VBoxContainer
var _lbl_edad: Label
var _lbl_edad_rejuvenecida: Label
var _lbl_dinero: Label
var _badge_dinero: PanelContainer
var _lbl_edad_hero: Label
var _lbl_rejuvenecido_hero: Label
var _medidor_edad: Visual_Bienestar.Medidor_Edad
var _timer_cooldowns: Timer
var _ads_refs: Dictionary = {}
var _servicios_refs: Dictionary = {}
var _modal_tratamiento: Modal_Tratamiento = null
var _modal_anuncio: Modal_Anuncio_Bienestar = null
var _toast_raiz: Control
var _toast_panel: PanelContainer
var _toast_label: Label
var _toast_icono: TextureRect
var _toast_timer: Timer
var _toast_tween: Tween
var _toast_mostrando: bool = false
var _sfx_player: AudioStreamPlayer
var _tween_dinero: Tween
var _dinero_mostrado: int = -999999
var _construido: bool = false
var _primera_entrada: bool = true
var _reset_dialogo: ConfirmationDialog = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_Construir_UI()
	_Crear_Reproductor_SFX()
	_timer_cooldowns = Timer.new()
	_timer_cooldowns.name = "Timer_Cooldowns_Anuncios"
	_timer_cooldowns.wait_time = 1.0
	_timer_cooldowns.timeout.connect(_Tick_Cooldowns)
	add_child(_timer_cooldowns)
	_toast_timer = Timer.new()
	_toast_timer.name = "Timer_Toast"
	_toast_timer.one_shot = true
	_toast_timer.wait_time = 2.7
	_toast_timer.timeout.connect(_Ocultar_Toast)
	add_child(_toast_timer)
	if not Recompensas.estado_cambiado.is_connected(_On_Estado_Cambiado):
		Recompensas.estado_cambiado.connect(_On_Estado_Cambiado)
	visibility_changed.connect(_On_Visibilidad_Cambiada)
	_construido = true
	_Sincronizar(true)


func _exit_tree() -> void:
	if Recompensas.estado_cambiado.is_connected(_On_Estado_Cambiado):
		Recompensas.estado_cambiado.disconnect(_On_Estado_Cambiado)
	if _modal_anuncio != null and is_instance_valid(_modal_anuncio) and _modal_anuncio.token > 0:
		Recompensas.Cancelar_Anuncio(_modal_anuncio.token)


func _On_Visibilidad_Cambiada() -> void:
	if not visible:
		if _timer_cooldowns != null:
			_timer_cooldowns.stop()
		if _toast_panel != null:
			_toast_mostrando = false
			_toast_panel.visible = false
		if _toast_timer != null:
			_toast_timer.stop()
		return
	_Sincronizar()
	if _scroll != null:
		_scroll.scroll_vertical = 0
	if _primera_entrada:
		_primera_entrada = false
		call_deferred("_Animar_Entrada")
	else:
		_Animar_Entrada()


# ----------------------------------------------------------------------------
# Construcción de la interfaz
# ----------------------------------------------------------------------------

func _Construir_UI() -> void:
	_scroll = ScrollContainer.new()
	_scroll.name = "Scroll_Bienestar"
	_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.follow_focus = true
	add_child(_scroll)

	var margen := MarginContainer.new()
	margen.name = "Margen_Bienestar"
	margen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margen.add_theme_constant_override("margin_left", 20)
	margen.add_theme_constant_override("margin_right", 20)
	margen.add_theme_constant_override("margin_top", 16)
	margen.add_theme_constant_override("margin_bottom", 30)
	_scroll.add_child(margen)

	_contenido = VBoxContainer.new()
	_contenido.name = "Contenido_Bienestar"
	_contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_contenido.add_theme_constant_override("separation", 18)
	margen.add_child(_contenido)

	_contenido.add_child(_Crear_Barra_Estado())
	_contenido.add_child(_Crear_Heroe_Clinica())
	_contenido.add_child(_Crear_Seccion_Rejuvenecimiento())
	_contenido.add_child(_Crear_Seccion_Cuidado())
	_contenido.add_child(_Crear_Seccion_Anuncios())
	_contenido.add_child(_Crear_Pie_Informacion())
	_Crear_Toast()


func _Crear_Barra_Estado() -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.name = "Barra_Estado"
	fila.add_theme_constant_override("separation", 10)

	# Edad del Sim.
	var card_edad := PanelContainer.new()
	card_edad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_edad.custom_minimum_size = Vector2(0, 66)
	card_edad.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(15, 2))
	fila.add_child(card_edad)

	var me := MarginContainer.new()
	me.add_theme_constant_override("margin_left", 12)
	me.add_theme_constant_override("margin_right", 10)
	me.add_theme_constant_override("margin_top", 9)
	me.add_theme_constant_override("margin_bottom", 9)
	card_edad.add_child(me)

	var he := HBoxContainer.new()
	he.add_theme_constant_override("separation", 10)
	me.add_child(he)

	he.add_child(Estilos_UI.badge_icono("hourglass", 38, 19, TEAL, Color.WHITE, 11))
	var ve := VBoxContainer.new()
	ve.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ve.alignment = BoxContainer.ALIGNMENT_CENTER
	ve.add_theme_constant_override("separation", 0)
	he.add_child(ve)
	ve.add_child(_Etiqueta_Mini("EDAD DEL SIM", Estilos_UI.TINTA_FANTASMA))
	var fila_edad := HBoxContainer.new()
	fila_edad.add_theme_constant_override("separation", 5)
	ve.add_child(fila_edad)
	_lbl_edad = Estilos_UI.titulo("18", 21, Estilos_UI.TINTA)
	fila_edad.add_child(_lbl_edad)
	var lbl_anios := Estilos_UI.texto("años", 11, Estilos_UI.TINTA_SUAVE, 600)
	lbl_anios.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila_edad.add_child(lbl_anios)
	_lbl_edad_rejuvenecida = Estilos_UI.texto("", 9, TEAL, 700)
	ve.add_child(_lbl_edad_rejuvenecida)

	# Cartera de euros.
	var card_dinero := PanelContainer.new()
	card_dinero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_dinero.custom_minimum_size = Vector2(0, 66)
	card_dinero.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(15, 2))
	fila.add_child(card_dinero)

	var md := MarginContainer.new()
	md.add_theme_constant_override("margin_left", 12)
	md.add_theme_constant_override("margin_right", 12)
	md.add_theme_constant_override("margin_top", 9)
	md.add_theme_constant_override("margin_bottom", 9)
	card_dinero.add_child(md)

	var hd := HBoxContainer.new()
	hd.add_theme_constant_override("separation", 10)
	md.add_child(hd)
	_badge_dinero = Estilos_UI.badge_icono("wallet", 38, 19, Estilos_UI.EXITO, Color.WHITE, 11)
	hd.add_child(_badge_dinero)
	var vd := VBoxContainer.new()
	vd.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vd.alignment = BoxContainer.ALIGNMENT_CENTER
	vd.add_theme_constant_override("separation", 0)
	hd.add_child(vd)
	vd.add_child(_Etiqueta_Mini("DINERO DISPONIBLE", Estilos_UI.TINTA_FANTASMA))
	var fila_dinero := HBoxContainer.new()
	fila_dinero.add_theme_constant_override("separation", 5)
	vd.add_child(fila_dinero)
	_lbl_dinero = Estilos_UI.titulo("0 €", 21, Estilos_UI.TINTA)
	fila_dinero.add_child(_lbl_dinero)
	var lbl_uso := Estilos_UI.texto("para tratamientos", 9, Estilos_UI.TINTA_SUAVE, 600)
	lbl_uso.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila_dinero.add_child(lbl_uso)

	return fila


func _Crear_Heroe_Clinica() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "Heroe_Clinica"
	panel.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Estilos_UI.NAVY, 22, Color(0, 0, 0, 0), 0, 4))

	var fondo := Visual_Bienestar.Fondo_Heroe_Clinica.new()
	fondo.name = "Fondo_Heroe"
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(fondo)

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 20)
	margen.add_theme_constant_override("margin_right", 20)
	margen.add_theme_constant_override("margin_top", 18)
	margen.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margen)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	margen.add_child(v)

	var cabecera := HBoxContainer.new()
	cabecera.add_theme_constant_override("separation", 11)
	v.add_child(cabecera)

	var medallon := PanelContainer.new()
	medallon.custom_minimum_size = Vector2(54, 54)
	medallon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	medallon.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Color(0.37, 0.94, 0.84, 0.14), 999, Color(0.37, 0.94, 0.84, 0.38), 2, 0))
	cabecera.add_child(medallon)
	var centro_medallon := CenterContainer.new()
	medallon.add_child(centro_medallon)
	centro_medallon.add_child(Estilos_UI.icono_rect("hourglass", 26, Color("#5eead4")))

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 0)
	cabecera.add_child(info)
	info.add_child(Estilos_UI.texto("CLÍNICA REJUVENECE", 17, Color.WHITE, 700))
	info.add_child(Estilos_UI.texto("Cuidado, longevidad y segundas oportunidades", 10, Color("#a7f3d0"), 500))

	var chip := _Crear_Pill_Con_Icono("sparkles", "EDAD BIOLÓGICA",
		Color(0.52, 0.94, 0.84, 0.14), Color("#5eead4"))
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cabecera.add_child(chip)

	var fila_edad := HBoxContainer.new()
	fila_edad.add_theme_constant_override("separation", 7)
	v.add_child(fila_edad)
	_lbl_edad_hero = Estilos_UI.titulo("18 años", 33, Color.WHITE)
	_lbl_edad_hero.custom_minimum_size = Vector2(0, 38)
	fila_edad.add_child(_lbl_edad_hero)
	var lbl_minimo := Estilos_UI.texto("mínimo 18", 10, Color("#94a3b8"), 600)
	lbl_minimo.size_flags_vertical = Control.SIZE_SHRINK_END
	lbl_minimo.custom_minimum_size = Vector2(0, 28)
	fila_edad.add_child(lbl_minimo)

	var subtitulo := Estilos_UI.texto(
		"Cada tratamiento resta años reales a tu Sim. El precio sube con cada sesión.",
		12, Color("#cbd5e1"), 500)
	subtitulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(subtitulo)

	_medidor_edad = Visual_Bienestar.Medidor_Edad.new()
	_medidor_edad.custom_minimum_size = Vector2(0, 34)
	v.add_child(_medidor_edad)

	var pie := HBoxContainer.new()
	pie.add_theme_constant_override("separation", 8)
	v.add_child(pie)
	pie.add_child(Estilos_UI.texto("18", 9, Color("#64748b"), 600))
	var relleno := Control.new()
	relleno.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pie.add_child(relleno)
	_lbl_rejuvenecido_hero = Estilos_UI.texto("Aún sin tratamientos", 10, Color("#5eead4"), 600)
	pie.add_child(_lbl_rejuvenecido_hero)
	var relleno2 := Control.new()
	relleno2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pie.add_child(relleno2)
	pie.add_child(Estilos_UI.texto("100", 9, Color("#64748b"), 600))

	return panel


func _Crear_Seccion_Rejuvenecimiento() -> VBoxContainer:
	var seccion := VBoxContainer.new()
	seccion.name = "Seccion_Rejuvenecimiento"
	seccion.add_theme_constant_override("separation", 10)
	seccion.add_child(_Cabecera_Seccion(
		"sparkles", "Rejuvenecimiento", "Resta años reales a tu Sim. Mínimo: 18 años.",
		TEAL, "PAGO CON EUROS"))

	var lista := VBoxContainer.new()
	lista.add_theme_constant_override("separation", 9)
	seccion.add_child(lista)
	for producto in Recompensas_Catalogo.Servicios_De_Grupo(
			Recompensas_Catalogo.GRUPO_REJUVENECIMIENTO):
		lista.add_child(_Crear_Tarjeta_Servicio(producto))
	return seccion


func _Crear_Seccion_Cuidado() -> VBoxContainer:
	var seccion := VBoxContainer.new()
	seccion.name = "Seccion_Cuidado"
	seccion.add_theme_constant_override("separation", 10)
	seccion.add_child(_Cabecera_Seccion(
		"heart-pulse", "Cuidado exprés", "Servicios instantáneos para salir del apuro.",
		CORAL, "SIN ESPERAS"))

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	seccion.add_child(fila)
	for producto in Recompensas_Catalogo.Servicios_De_Grupo(Recompensas_Catalogo.GRUPO_CUIDADO):
		var card := _Crear_Tarjeta_Cuidado(producto)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(card)
	return seccion


func _Crear_Tarjeta_Servicio(producto: Dictionary) -> PanelContainer:
	var id := str(producto.get("id", ""))
	var color := _Color(producto.get("color", TEAL))
	var card := PanelContainer.new()
	card.name = "Servicio_%s" % id
	card.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(15, 2))

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 13)
	margen.add_theme_constant_override("margin_right", 13)
	margen.add_theme_constant_override("margin_top", 11)
	margen.add_theme_constant_override("margin_bottom", 11)
	card.add_child(margen)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	margen.add_child(fila)

	fila.add_child(Estilos_UI.badge_icono(str(producto.get("icono", "sparkles")), 44, 21,
		color, Color.WHITE, 12))

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	fila.add_child(info)

	var fila_titulo := HBoxContainer.new()
	fila_titulo.add_theme_constant_override("separation", 7)
	info.add_child(fila_titulo)
	fila_titulo.add_child(Estilos_UI.texto(str(producto.get("titulo", "")), 15, Estilos_UI.TINTA, 700))
	fila_titulo.add_child(_Crear_Mini_Pill(str(producto.get("subtitulo", "")),
		Color(color, 0.10), color))

	var desc := Estilos_UI.texto(str(producto.get("descripcion", "")), 11, Estilos_UI.TINTA_SUAVE, 500)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(0, 28)
	info.add_child(desc)

	var estado := Estilos_UI.texto("", 10, Estilos_UI.TINTA_FANTASMA, 600)
	info.add_child(estado)

	var derecha := VBoxContainer.new()
	derecha.alignment = BoxContainer.ALIGNMENT_CENTER
	derecha.custom_minimum_size = Vector2(104, 0)
	derecha.add_theme_constant_override("separation", 4)
	fila.add_child(derecha)

	var precio := Estilos_UI.titulo("0 €", 17, Estilos_UI.TINTA)
	precio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	derecha.add_child(precio)

	var btn := Estilos_UI.boton("Reservar", "primario", "sparkles", color, 34)
	btn.name = "Reservar_%s" % id
	btn.add_theme_font_size_override("font_size", 11)
	btn.custom_minimum_size = Vector2(100, 34)
	_Aplicar_Estilo_Deshabilitado(btn, color)
	btn.pressed.connect(_Abrir_Tratamiento.bind(producto))
	derecha.add_child(btn)

	_servicios_refs[id] = {
		"producto": producto,
		"btn": btn,
		"precio": precio,
		"estado": estado,
		"color": color,
		"rejuvenece": _Es_Rejuvenecimiento(producto),
	}
	return card


func _Crear_Tarjeta_Cuidado(producto: Dictionary) -> PanelContainer:
	var id := str(producto.get("id", ""))
	var color := _Color(producto.get("color", CORAL))
	var card := PanelContainer.new()
	card.name = "Servicio_%s" % id
	card.custom_minimum_size = Vector2(0, 156)
	card.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(15, 2))

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 12)
	margen.add_theme_constant_override("margin_right", 12)
	margen.add_theme_constant_override("margin_top", 11)
	margen.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margen)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 5)
	margen.add_child(v)

	var cabecera := HBoxContainer.new()
	cabecera.add_theme_constant_override("separation", 8)
	v.add_child(cabecera)
	cabecera.add_child(Estilos_UI.badge_icono(str(producto.get("icono", "heart-pulse")), 34, 17,
		color, Color.WHITE, 10))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 0)
	cabecera.add_child(info)
	info.add_child(Estilos_UI.texto(str(producto.get("titulo", "")), 14, Estilos_UI.TINTA, 700))
	info.add_child(Estilos_UI.texto(str(producto.get("subtitulo", "")), 10, color, 600))

	var desc := Estilos_UI.texto(str(producto.get("descripcion", "")), 10, Estilos_UI.TINTA_SUAVE, 500)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(0, 30)
	v.add_child(desc)

	var estado := Estilos_UI.texto("", 10, Estilos_UI.TINTA_FANTASMA, 600)
	estado.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(estado)

	var pie := HBoxContainer.new()
	pie.add_theme_constant_override("separation", 8)
	v.add_child(pie)
	var precio := Estilos_UI.titulo("0 €", 16, Estilos_UI.TINTA)
	precio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	precio.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pie.add_child(precio)

	var btn := Estilos_UI.boton("Comprar", "primario", "check", color, 32)
	btn.name = "Comprar_%s" % id
	btn.add_theme_font_size_override("font_size", 11)
	btn.custom_minimum_size = Vector2(92, 32)
	_Aplicar_Estilo_Deshabilitado(btn, color)
	btn.pressed.connect(_Abrir_Tratamiento.bind(producto))
	pie.add_child(btn)

	_servicios_refs[id] = {
		"producto": producto,
		"btn": btn,
		"precio": precio,
		"estado": estado,
		"color": color,
		"rejuvenece": false,
	}
	return card


func _Crear_Seccion_Anuncios() -> VBoxContainer:
	var seccion := VBoxContainer.new()
	seccion.name = "Seccion_Anuncios"
	seccion.add_theme_constant_override("separation", 10)
	seccion.add_child(_Cabecera_Seccion(
		"video", "Anuncios", "Recompensas gratis cada pocos minutos.",
		Estilos_UI.INDIGO, "GRATIS"))

	var lista := VBoxContainer.new()
	lista.add_theme_constant_override("separation", 9)
	seccion.add_child(lista)
	for producto in Recompensas_Catalogo.Productos_De(Recompensas_Catalogo.SECCION_ANUNCIOS):
		lista.add_child(_Crear_Tarjeta_Anuncio(producto))
	return seccion


func _Crear_Tarjeta_Anuncio(producto: Dictionary) -> PanelContainer:
	var id := str(producto.get("id", ""))
	var color := _Color(producto.get("color", INDIGO))
	var card := PanelContainer.new()
	card.name = "Anuncio_%s" % id
	card.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(15, 2))

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 13)
	margen.add_theme_constant_override("margin_right", 13)
	margen.add_theme_constant_override("margin_top", 11)
	margen.add_theme_constant_override("margin_bottom", 11)
	card.add_child(margen)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 11)
	margen.add_child(fila)

	fila.add_child(Estilos_UI.badge_icono(str(producto.get("icono", "gift")), 44, 21,
		color, Color.WHITE, 12))

	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 2)
	fila.add_child(v)

	var titulo := Estilos_UI.texto(str(producto.get("titulo", "")), 15, Estilos_UI.TINTA, 700)
	v.add_child(titulo)
	var desc := Estilos_UI.texto(str(producto.get("descripcion", "")), 11, Estilos_UI.TINTA_SUAVE, 500)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(0, 28)
	v.add_child(desc)

	var meta := HBoxContainer.new()
	meta.add_theme_constant_override("separation", 7)
	v.add_child(meta)
	var duracion := int(round(float(producto.get("duracion_simulada", 5.0))))
	var chip := _Crear_Mini_Pill("ANUNCIO · %d s" % duracion,
		Color(color, 0.12), color)
	meta.add_child(chip)
	var lbl_estado := Estilos_UI.texto("Disponible ahora", 10, Estilos_UI.EXITO, 600)
	lbl_estado.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta.add_child(lbl_estado)

	var barra := ProgressBar.new()
	barra.name = "Progreso_Cooldown"
	barra.custom_minimum_size = Vector2(0, 4)
	barra.max_value = 100.0
	barra.value = 100.0
	barra.show_percentage = false
	barra.add_theme_stylebox_override("background", Estilos_UI.barra_fondo(999))
	barra.add_theme_stylebox_override("fill", Estilos_UI.barra_relleno(color, 999))
	barra.set_meta("_tema_aplicado", true)
	v.add_child(barra)

	var derecha := VBoxContainer.new()
	derecha.alignment = BoxContainer.ALIGNMENT_CENTER
	derecha.custom_minimum_size = Vector2(122, 0)
	derecha.add_theme_constant_override("separation", 6)
	fila.add_child(derecha)
	var recompensa := _Crear_Pill_Con_Icono(
		str(producto.get("icono", "gift")),
		str(producto.get("recompensa_texto", "")),
		Color(color, 0.12), color)
	recompensa.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	derecha.add_child(recompensa)

	var btn := Estilos_UI.boton("Ver", "primario", "play", color, 36)
	btn.name = "Ver_%s" % id
	btn.add_theme_font_size_override("font_size", 12)
	btn.custom_minimum_size = Vector2(112, 36)
	var st_cooldown := Estilos_UI.caja(Color(color, 0.11), 10, Color(color, 0.24), 1, 0)
	btn.add_theme_stylebox_override("disabled", st_cooldown)
	btn.add_theme_color_override("font_disabled_color", color)
	btn.add_theme_color_override("icon_disabled_color", color)
	btn.pressed.connect(_Ver_Anuncio.bind(producto))
	derecha.add_child(btn)

	_ads_refs[id] = {
		"producto": producto,
		"card": card,
		"btn": btn,
		"lbl_estado": lbl_estado,
		"barra": barra,
		"color": color,
	}
	return card


func _Crear_Pie_Informacion() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "Pie_Informacion"
	panel.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Estilos_UI.SUPERFICIE_2, 15, Estilos_UI.BORDE, 1, 0))

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 14)
	margen.add_theme_constant_override("margin_right", 14)
	margen.add_theme_constant_override("margin_top", 12)
	margen.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margen)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	margen.add_child(v)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	v.add_child(fila)
	fila.add_child(Estilos_UI.icono_rect("info", 18, Estilos_UI.TINTA_SUAVE))
	var texto := Estilos_UI.parrafo(
		"Los anuncios son simulados: no se muestra publicidad real ni se realiza " +
		"ningún cargo. Las recompensas y los tratamientos se aplican a tu partida " +
		"y se pagan con los euros del juego.",
		11, Estilos_UI.TINTA_SUAVE)
	texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(texto)

	var segunda := HBoxContainer.new()
	segunda.add_theme_constant_override("separation", 10)
	segunda.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(segunda)
	var proveedor := Estilos_UI.texto(
		Recompensas.Obtener_Proveedor_Anuncios_Nombre(),
		9, Estilos_UI.TINTA_FANTASMA, 500)
	proveedor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	segunda.add_child(proveedor)
	var btn_reset := Estilos_UI.boton("Reiniciar esperas", "fantasma", "rotate-ccw",
		Estilos_UI.TINTA, 28)
	btn_reset.name = "Reiniciar_Esperas"
	btn_reset.add_theme_font_size_override("font_size", 10)
	btn_reset.custom_minimum_size = Vector2(132, 28)
	btn_reset.pressed.connect(_Abrir_Reset)
	segunda.add_child(btn_reset)
	return panel


# ----------------------------------------------------------------------------
# Helpers visuales
# ----------------------------------------------------------------------------

func _Cabecera_Seccion(icono: String, titulo: String, subtitulo: String,
		color: Color, pill: String = "") -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.custom_minimum_size = Vector2(0, 36)
	fila.add_theme_constant_override("separation", 10)
	fila.add_child(Estilos_UI.badge_icono(icono, 36, 18, color, Color.WHITE, 10))
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 0)
	fila.add_child(v)
	v.add_child(Estilos_UI.titulo(titulo, 18, Estilos_UI.TINTA))
	v.add_child(Estilos_UI.texto(subtitulo, 11, Estilos_UI.TINTA_SUAVE, 500))
	if pill != "":
		var p := _Crear_Mini_Pill(pill, Color(color, 0.10), color)
		p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(p)
	return fila


func _Crear_Mini_Pill(texto: String, fondo: Color, color_texto: Color) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.set_meta("_tema_aplicado", true)
	var estilo := Estilos_UI.caja(fondo, 999, Color(color_texto, 0.16), 1, 0)
	estilo.content_margin_left = 8
	estilo.content_margin_right = 8
	estilo.content_margin_top = 3
	estilo.content_margin_bottom = 3
	pill.add_theme_stylebox_override("panel", estilo)
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lbl := Estilos_UI.texto(texto, 9, color_texto, 700)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(lbl)
	return pill


func _Crear_Pill_Con_Icono(icono: String, texto: String, fondo: Color,
		color_texto: Color) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.set_meta("_tema_aplicado", true)
	var estilo := Estilos_UI.caja(fondo, 999, Color(color_texto, 0.16), 1, 0)
	estilo.content_margin_left = 8
	estilo.content_margin_right = 8
	estilo.content_margin_top = 4
	estilo.content_margin_bottom = 4
	pill.add_theme_stylebox_override("panel", estilo)
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 5)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(h)
	h.add_child(Estilos_UI.icono_rect(icono, 13, color_texto))
	var lbl := Estilos_UI.texto(texto, 10, color_texto, 700)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(lbl)
	return pill


func _Etiqueta_Mini(texto: String, color: Color) -> Label:
	var lbl := Estilos_UI.texto(texto, 9, color, 700)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl


func _Color(valor) -> Color:
	if valor is Color:
		return valor
	return Color(str(valor))


func _Formatear_Numero(numero: int) -> String:
	var negativo := numero < 0
	var s := str(absi(numero))
	var salida := ""
	var contador := 0
	for i in range(s.length() - 1, -1, -1):
		salida = s[i] + salida
		contador += 1
		if contador % 3 == 0 and i > 0:
			salida = "." + salida
	return ("-" if negativo else "") + salida


func _Formatear_Euros(valor: int) -> String:
	return "%s €" % _Formatear_Numero(valor)


func _Formatear_Segundos(segundos: int) -> String:
	var seg := maxi(0, segundos)
	return "%d:%02d" % [seg / 60, seg % 60]


func _Aplicar_Estilo_Deshabilitado(btn: Button, color: Color) -> void:
	# Un botón bloqueado sigue siendo legible: fondo suave del color del
	# servicio y texto/icono en ese mismo color, como en las tarjetas de anuncio.
	var st := Estilos_UI.caja(Color(color, 0.10), 10, Color(color, 0.22), 1, 0)
	btn.add_theme_stylebox_override("disabled", st)
	btn.add_theme_color_override("font_disabled_color", color)
	btn.add_theme_color_override("icon_disabled_color", color)


func _Es_Rejuvenecimiento(producto: Dictionary) -> bool:
	for recompensa in Recompensas_Catalogo.Obtener_Recompensas(producto):
		if recompensa is Dictionary and str(recompensa.get("tipo", "")) == "rejuvenecer":
			return true
	return false


# ----------------------------------------------------------------------------
# Sincronización de estado
# ----------------------------------------------------------------------------

func _On_Estado_Cambiado() -> void:
	_Sincronizar()


func _Sincronizar(animar: bool = true) -> void:
	if not _construido:
		return
	_Actualizar_Edad()
	_Actualizar_Dinero(animar)
	_Actualizar_Servicios()
	_Actualizar_Anuncios()


func _Actualizar_Edad() -> void:
	var edad := Recompensas.Obtener_Edad_Actual()
	var rejuvenecidos := Recompensas.Obtener_Anios_Rejuvenecidos()
	if _lbl_edad != null:
		_lbl_edad.text = str(edad)
	if _lbl_edad_rejuvenecida != null:
		_lbl_edad_rejuvenecida.text = ("−%d años recuperados" % rejuvenecidos) if rejuvenecidos > 0 else "Sin tratamientos"
		_lbl_edad_rejuvenecida.add_theme_color_override("font_color",
			TEAL if rejuvenecidos > 0 else Estilos_UI.TINTA_FANTASMA)
	if _lbl_edad_hero != null:
		_lbl_edad_hero.text = "%d años" % edad
	if _lbl_rejuvenecido_hero != null:
		_lbl_rejuvenecido_hero.text = (
			"−%d años recuperados" % rejuvenecidos) if rejuvenecidos > 0 else "Aún sin tratamientos"
	if _medidor_edad != null and is_instance_valid(_medidor_edad):
		_medidor_edad.Establecer(edad, edad + rejuvenecidos)


func _Actualizar_Dinero(animar: bool = true) -> void:
	if _lbl_dinero == null:
		return
	var objetivo := int(round(Variables_Dinamicas.Dinero))
	_lbl_dinero.add_theme_color_override("font_color",
		Estilos_UI.EXITO if objetivo >= 0 else Estilos_UI.PELIGRO)
	if _tween_dinero != null and _tween_dinero.is_valid():
		_tween_dinero.kill()
	if not animar or _dinero_mostrado == -999999 or not is_inside_tree():
		_dinero_mostrado = objetivo
		_lbl_dinero.text = _Formatear_Euros(objetivo)
		return
	if _dinero_mostrado == objetivo:
		_lbl_dinero.text = _Formatear_Euros(objetivo)
		return
	var desde := _dinero_mostrado
	_dinero_mostrado = objetivo
	_lbl_dinero.add_theme_color_override("font_color",
		Estilos_UI.EXITO if objetivo >= 0 else Estilos_UI.PELIGRO)
	_tween_dinero = create_tween()
	_tween_dinero.tween_method(Callable(self, "_Poner_Dinero_Animado"),
		float(desde), float(objetivo), 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if _badge_dinero != null and is_instance_valid(_badge_dinero):
		_badge_dinero.pivot_offset = _badge_dinero.size * 0.5
		var tw := create_tween()
		tw.tween_property(_badge_dinero, "scale", Vector2(1.08, 1.08), 0.10)
		tw.tween_property(_badge_dinero, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _Poner_Dinero_Animado(valor: float) -> void:
	if _lbl_dinero != null and is_instance_valid(_lbl_dinero):
		_lbl_dinero.text = _Formatear_Euros(int(round(valor)))


func _Actualizar_Servicios() -> void:
	var dinero := int(round(Variables_Dinamicas.Dinero))
	var edad := Recompensas.Obtener_Edad_Actual()
	for id in _servicios_refs:
		var ref: Dictionary = _servicios_refs[id]
		var producto: Dictionary = ref["producto"]
		var btn: Button = ref["btn"]
		var precio: Label = ref["precio"]
		var estado: Label = ref["estado"]
		if not is_instance_valid(btn) or not is_instance_valid(precio) or not is_instance_valid(estado):
			continue
		var coste := int(round(Recompensas.Obtener_Coste_Servicio(id)))
		var rejuvenece := bool(ref.get("rejuvenece", false))
		var bloqueado_edad := rejuvenece and edad <= 18
		var sin_dinero := dinero < coste
		precio.text = _Formatear_Euros(coste)
		precio.add_theme_color_override("font_color",
			Estilos_UI.PELIGRO if sin_dinero and not bloqueado_edad else Estilos_UI.TINTA)
		if bloqueado_edad:
			estado.text = "Edad mínima alcanzada"
			estado.add_theme_color_override("font_color", Estilos_UI.TINTA_FANTASMA)
			btn.disabled = true
			btn.text = "Al máximo"
		elif sin_dinero:
			estado.text = "Te faltan %s" % _Formatear_Euros(coste - dinero)
			estado.add_theme_color_override("font_color", Estilos_UI.PELIGRO)
			btn.disabled = true
			btn.text = "Sin saldo"
		else:
			if rejuvenece:
				estado.text = "El precio sube con cada sesión"
			else:
				estado.text = "Disponible al instante"
			estado.add_theme_color_override("font_color", Estilos_UI.TINTA_FANTASMA)
			btn.disabled = false
			btn.text = "Reservar" if rejuvenece else "Comprar"


func _Actualizar_Anuncios() -> void:
	var hay_cooldown := false
	for id in _ads_refs:
		var ref: Dictionary = _ads_refs[id]
		var estado := Recompensas.Obtener_Estado_Anuncio(id)
		if not bool(estado.get("disponible", false)):
			hay_cooldown = true
		_Aplicar_Estado_Anuncio(ref, estado)
	if hay_cooldown and is_visible_in_tree():
		if _timer_cooldowns != null and _timer_cooldowns.is_stopped():
			_timer_cooldowns.start()
	elif _timer_cooldowns != null:
		_timer_cooldowns.stop()


func _Aplicar_Estado_Anuncio(ref: Dictionary, estado: Dictionary) -> void:
	var btn: Button = ref["btn"]
	var card: PanelContainer = ref["card"]
	var lbl_estado: Label = ref["lbl_estado"]
	var barra: ProgressBar = ref["barra"]
	var color: Color = ref["color"]
	if not is_instance_valid(btn) or not is_instance_valid(lbl_estado):
		return
	var disponible := bool(estado.get("disponible", false))
	var restantes := int(estado.get("segundos_restantes", 0))
	if disponible:
		btn.disabled = false
		btn.text = "Ver"
		btn.icon = Estilos_UI.icono("play")
		var producto: Dictionary = ref["producto"]
		if _Es_Rejuvenecimiento(producto) and Recompensas.Obtener_Edad_Actual() <= 18:
			btn.disabled = true
			btn.text = "Al máximo"
			lbl_estado.text = "Ya tienes 18 años"
			lbl_estado.add_theme_color_override("font_color", Estilos_UI.TINTA_FANTASMA)
		else:
			lbl_estado.text = "Disponible ahora"
			lbl_estado.add_theme_color_override("font_color", Estilos_UI.EXITO)
		barra.value = 100.0
		barra.add_theme_stylebox_override("fill", Estilos_UI.barra_relleno(color, 999))
		if is_instance_valid(card):
			card.modulate = Color.WHITE
	else:
		btn.disabled = true
		btn.text = _Formatear_Segundos(restantes)
		btn.icon = Estilos_UI.icono("clock")
		lbl_estado.text = "Disponible en %s" % _Formatear_Segundos(restantes)
		lbl_estado.add_theme_color_override("font_color", ORO)
		barra.value = float(estado.get("progreso", 0.0)) * 100.0
		barra.add_theme_stylebox_override("fill", Estilos_UI.barra_relleno(color, 999))
		if is_instance_valid(card):
			card.modulate = Color(1, 1, 1, 0.92)


func _Tick_Cooldowns() -> void:
	# Solo actualiza las tarjetas de anuncios: no reconstruye la pantalla ni
	# toca el scroll, así la cuenta atrás es fluida y barata.
	_Actualizar_Anuncios()


# ----------------------------------------------------------------------------
# Flujos: tratamiento y anuncio
# ----------------------------------------------------------------------------

func _Abrir_Tratamiento(producto: Dictionary) -> void:
	if _modal_tratamiento != null and is_instance_valid(_modal_tratamiento):
		return
	var id := str(producto.get("id", ""))
	var coste := Recompensas.Obtener_Coste_Servicio(id)
	var dinero := float(Variables_Dinamicas.Dinero)
	if dinero < coste:
		_Mostrar_Toast("Te faltan %s. Prueba con un anuncio." % _Formatear_Euros(int(ceil(coste - dinero))), "error")
		return
	var rejuvenece := _Es_Rejuvenecimiento(producto)
	var edad_actual := Recompensas.Obtener_Edad_Actual()
	if rejuvenece and edad_actual <= 18:
		_Mostrar_Toast("Tu Sim ya tiene 18 años: no puede rejuvenecer más.", "info")
		return

	var modal := MODAL_TRATAMIENTO.new()
	modal.servicio = producto
	modal.coste = coste
	modal.dinero_disponible = dinero
	modal.edad_actual = edad_actual
	modal.edad_objetivo = maxi(18, edad_actual - _Anios_Del_Servicio(producto)) if rejuvenece else edad_actual
	modal.es_rejuvenecimiento = rejuvenece
	modal.confirmado.connect(_Procesar_Tratamiento.bind(modal, producto))
	modal.cerrado.connect(func() -> void: _modal_tratamiento = null)
	_modal_tratamiento = modal
	add_child(modal)
	_Reproducir_SFX("pop")


func _Procesar_Tratamiento(modal: Modal_Tratamiento, producto: Dictionary) -> void:
	if not is_instance_valid(modal):
		return
	modal.Mostrar_Procesando()
	var resultado: Dictionary = await Recompensas.Comprar_Servicio(str(producto.get("id", "")))
	if not is_instance_valid(modal):
		return
	if bool(resultado.get("ok", false)):
		modal.Mostrar_Exito(resultado)
		_Reproducir_SFX("coin")
	else:
		modal.Mostrar_Error(str(resultado.get("mensaje", "No se pudo completar el tratamiento.")))
		_Reproducir_SFX("pop")


func _Anios_Del_Servicio(producto: Dictionary) -> int:
	for recompensa in Recompensas_Catalogo.Obtener_Recompensas(producto):
		if recompensa is Dictionary and str(recompensa.get("tipo", "")) == "rejuvenecer":
			return maxi(1, int(recompensa.get("cantidad", 1)))
	return 0


func _Ver_Anuncio(producto: Dictionary) -> void:
	if _modal_anuncio != null and is_instance_valid(_modal_anuncio):
		return
	var solicitud: Dictionary = Recompensas.Solicitar_Anuncio(str(producto.get("id", "")))
	if not bool(solicitud.get("ok", false)):
		_Mostrar_Toast(str(solicitud.get("mensaje", "No se pudo abrir el anuncio.")),
			"info" if str(solicitud.get("codigo", "")) == "cooldown" else "error")
		return

	var modal := MODAL_ANUNCIO.new()
	modal.anuncio = producto
	modal.token = int(solicitud.get("token", 0))
	modal.visto.connect(_Completar_Anuncio.bind(modal))
	modal.cancelado.connect(_Cancelar_Anuncio)
	modal.cerrado.connect(func() -> void: _modal_anuncio = null)
	_modal_anuncio = modal
	add_child(modal)
	_Reproducir_SFX("pop")


func _Completar_Anuncio(token: int, modal: Modal_Anuncio_Bienestar) -> void:
	var resultado: Dictionary = await Recompensas.Completar_Anuncio(token)
	if not is_instance_valid(modal):
		return
	if bool(resultado.get("ok", false)):
		modal.Mostrar_Recompensa(resultado)
		_Reproducir_SFX("coin")
	else:
		modal.Mostrar_Error(str(resultado.get("mensaje", "No se pudo verificar la recompensa.")))
		_Reproducir_SFX("pop")


func _Cancelar_Anuncio(token: int) -> void:
	Recompensas.Cancelar_Anuncio(token)
	_Mostrar_Toast("Anuncio cerrado. No se ha concedido la recompensa.", "info")


# ----------------------------------------------------------------------------
# Reset de esperas
# ----------------------------------------------------------------------------

func _Abrir_Reset() -> void:
	if _reset_dialogo != null and is_instance_valid(_reset_dialogo):
		return
	_reset_dialogo = ConfirmationDialog.new()
	_reset_dialogo.title = "Reiniciar esperas de los anuncios"
	_reset_dialogo.dialog_text = (
		"Se pondrán a cero las esperas de los anuncios y el historial de la tienda. " +
		"Tu partida, tu edad y tus euros no cambian."
	)
	_reset_dialogo.ok_button_text = "Reiniciar"
	add_child(_reset_dialogo)
	Estilos_UI.estilizar_dialogo(_reset_dialogo)
	_reset_dialogo.get_cancel_button().text = "Cancelar"
	_reset_dialogo.confirmed.connect(_Confirmar_Reset)
	_reset_dialogo.canceled.connect(_Cerrar_Reset)
	_reset_dialogo.popup_centered()
	Estilos_UI.fijar_tamano_dialogo.call_deferred(_reset_dialogo, Vector2i(610, 380))


func _Confirmar_Reset() -> void:
	Recompensas.Reiniciar_Esperas()
	_Mostrar_Toast("Esperas reiniciadas. ¡A por otra recompensa!", "exito")
	_Cerrar_Reset()


func _Cerrar_Reset() -> void:
	if _reset_dialogo != null and is_instance_valid(_reset_dialogo):
		_reset_dialogo.queue_free()
	_reset_dialogo = null


# ----------------------------------------------------------------------------
# Toasts y sonido
# ----------------------------------------------------------------------------

func _Crear_Toast() -> void:
	_toast_raiz = Control.new()
	_toast_raiz.name = "Toasts_Bienestar"
	_toast_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_toast_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_raiz.z_index = 90
	add_child(_toast_raiz)

	var margen := MarginContainer.new()
	margen.set_anchors_preset(Control.PRESET_FULL_RECT)
	margen.add_theme_constant_override("margin_left", 48)
	margen.add_theme_constant_override("margin_right", 48)
	margen.add_theme_constant_override("margin_bottom", 112)
	margen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_raiz.add_child(margen)

	var columna := VBoxContainer.new()
	columna.alignment = BoxContainer.ALIGNMENT_END
	columna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margen.add_child(columna)

	_toast_panel = PanelContainer.new()
	_toast_panel.name = "Toast"
	_toast_panel.visible = false
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_panel.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Color("#111927"), 13, Color(1, 1, 1, 0.12), 1, 3))
	columna.add_child(_toast_panel)
	_toast_panel.visibility_changed.connect(_On_Toast_Visibility_Changed)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 9)
	_toast_panel.add_child(h)
	var acento := ColorRect.new()
	acento.name = "Acento"
	acento.custom_minimum_size = Vector2(4, 0)
	acento.color = Estilos_UI.EXITO
	acento.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(acento)
	_toast_icono = Estilos_UI.icono_rect("circle-check", 17, Estilos_UI.EXITO)
	h.add_child(_toast_icono)
	_toast_label = Estilos_UI.texto("", 12, Color.WHITE, 600)
	_toast_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_label.custom_minimum_size = Vector2(0, 28)
	h.add_child(_toast_label)


func _On_Toast_Visibility_Changed() -> void:
	# Gestionar_Visibilidad.Visibilizar_Tienda recorre todos los CanvasItem y
	# los pone visible=true. El toast debe seguir oculto hasta que se pida.
	if _toast_panel != null and _toast_panel.visible and not _toast_mostrando:
		_toast_panel.visible = false


func _Mostrar_Toast(mensaje: String, tipo: String = "info") -> void:
	if _toast_panel == null:
		return
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	var color := Estilos_UI.AZUL
	var icono := "info"
	if tipo == "exito":
		color = Estilos_UI.EXITO
		icono = "circle-check"
	elif tipo == "error":
		color = Estilos_UI.PELIGRO
		icono = "triangle-alert"
	_toast_icono.texture = Estilos_UI.icono(icono)
	_toast_icono.self_modulate = color
	var acento := _toast_panel.find_child("Acento", true, false) as ColorRect
	if acento != null:
		acento.color = color
	_toast_label.text = mensaje
	_toast_label.add_theme_color_override("font_color", Color.WHITE)
	_toast_mostrando = true
	_toast_panel.visible = true
	_toast_panel.modulate.a = 0.0
	_toast_panel.scale = Vector2(0.97, 0.97)
	await get_tree().process_frame
	if not is_instance_valid(_toast_panel):
		return
	_toast_panel.pivot_offset = _toast_panel.size * 0.5
	_toast_tween = create_tween()
	_toast_tween.set_parallel(true)
	_toast_tween.tween_property(_toast_panel, "modulate:a", 1.0, 0.16)
	_toast_tween.tween_property(_toast_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_toast_timer.start()


func _Ocultar_Toast() -> void:
	if _toast_panel == null or not is_instance_valid(_toast_panel):
		return
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast_panel, "modulate:a", 0.0, 0.18)
	_toast_tween.tween_callback(func() -> void:
		_toast_mostrando = false
		if is_instance_valid(_toast_panel):
			_toast_panel.visible = false
	)


func _Crear_Reproductor_SFX() -> void:
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.name = "SFX_Bienestar"
	_sfx_player.bus = Ajustes.BUS_SFX
	add_child(_sfx_player)


func _Reproducir_SFX(nombre: String) -> void:
	if _sfx_player == null:
		return
	match nombre:
		"coin": _sfx_player.stream = SFX_COIN
		"ding": _sfx_player.stream = SFX_DING
		_: _sfx_player.stream = SFX_POP
	_sfx_player.play()


# ----------------------------------------------------------------------------
# Animación de entrada
# ----------------------------------------------------------------------------

func _Animar_Entrada() -> void:
	if _contenido == null:
		return
	var hijos := _contenido.get_children()
	for i in range(hijos.size()):
		var hijo := hijos[i] as Control
		if hijo == null:
			continue
		hijo.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_interval(float(i) * 0.035)
		tw.tween_property(hijo, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
