class_name Modal_Anuncio_Bienestar
extends CanvasLayer

# ============================================================================
# Reproducción de un anuncio recompensado SIMULADO.
#
# El anuncio dura 5–8 segundos. Al terminar emite `visto(token)` y la pantalla
# que lo abrió pide la recompensa a Recompensas. Si el jugador cierra antes
# (botón, Escape o atrás en Android), emite `cancelado(token)` y no se concede
# nada. La UI nunca decide por sí sola que el anuncio se ha visto.
# ============================================================================

signal visto(token: int)
signal cancelado(token: int)
signal cerrado

var anuncio: Dictionary = {}
var token: int = 0

var _duracion: float = 5.0
var _restante: float = 5.0
var _procesando: bool = false
var _verificando: bool = false
var _completado: bool = false
var _cerrando: bool = false
var _ultimo_segundo: int = -1
var _contenido_principal: Control
var _creativo: Control
var _btn_cerrar: Button
var _lbl_cuenta: Label
var _lbl_tiempo_grande: Label
var _lbl_recompensa: Label
var _barra: ProgressBar
var _overlay_recompensa: Control
var _overlay_verificando: Control
var _overlay_error: Control
var _lbl_error: Label
var _lbl_recompensa_grande: Label
var _lbl_detalle_recompensa: Label
var _lbl_saldo_recompensa: Label
var _pill_saldo_recompensa: PanelContainer
var _confeti: Visual_Bienestar.Confeti
var _estallido: Visual_Bienestar.Estallido
var _lbl_pie_progreso: Label


func _ready() -> void:
	layer = 113
	process_mode = Node.PROCESS_MODE_ALWAYS
	_duracion = clampf(float(anuncio.get("duracion_simulada", 5.0)), 2.0, 30.0)
	_restante = _duracion
	_Construir_UI()
	_Animar_Entrada()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_Cerrar()


func _notification(que: int) -> void:
	if que == NOTIFICATION_WM_GO_BACK_REQUEST:
		_Cerrar()


func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	if _procesando or _verificando or _completado:
		return
	_restante = maxf(0.0, _restante - delta)
	var segundo := int(ceil(_restante))
	if segundo != _ultimo_segundo:
		_ultimo_segundo = segundo
		_Actualizar_Textos()
	var avance := 1.0 - (_restante / maxf(0.001, _duracion))
	if _barra != null:
		_barra.value = clampf(avance * 100.0, 0.0, 100.0)
	if _restante <= 0.0:
		_verificando = true
		_btn_cerrar.disabled = true
		_btn_cerrar.modulate.a = 0.4
		_Mostrar_Verificando()
		visto.emit(token)


# ----------------------------------------------------------------------------
# Construcción
# ----------------------------------------------------------------------------

func _Construir_UI() -> void:
	var raiz := Control.new()
	raiz.name = "Raiz_Anuncio"
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(raiz)

	var fondo := Fondo_Pantalla.new()
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.add_child(fondo)

	var margen := MarginContainer.new()
	margen.set_anchors_preset(Control.PRESET_FULL_RECT)
	margen.add_theme_constant_override("margin_left", 26)
	margen.add_theme_constant_override("margin_right", 26)
	margen.add_theme_constant_override("margin_top", 20)
	margen.add_theme_constant_override("margin_bottom", 22)
	raiz.add_child(margen)

	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 16)
	margen.add_child(columna)

	columna.add_child(_Crear_Cabecera())

	var contenido := VBoxContainer.new()
	contenido.alignment = BoxContainer.ALIGNMENT_CENTER
	contenido.size_flags_vertical = Control.SIZE_EXPAND_FILL
	contenido.custom_minimum_size = Vector2(0, 700)
	contenido.add_theme_constant_override("separation", 16)
	_contenido_principal = contenido
	columna.add_child(_contenido_principal)

	_creativo = _Crear_Creativo()
	_creativo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_contenido_principal.add_child(_creativo)

	_Crear_Progreso(_contenido_principal)

	_overlay_verificando = _Crear_Overlay_Verificando(raiz)
	_overlay_error = _Crear_Overlay_Error(raiz)
	_overlay_recompensa = _Crear_Overlay_Recompensa(raiz)

	_Actualizar_Textos()


func _Crear_Cabecera() -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	fila.custom_minimum_size = Vector2(0, 48)

	var chip := Estilos_UI.pill_estado("ANUNCIO SIMULADO", Color(0.98, 0.75, 0.14, 0.16), Color("#fbbf24"))
	fila.add_child(chip)

	var etiqueta := Estilos_UI.texto("Publicidad · recompensa garantizada al terminar", 12, Color("#94a3b8"), 500)
	etiqueta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(etiqueta)

	var cuenta := HBoxContainer.new()
	cuenta.add_theme_constant_override("separation", 6)
	cuenta.add_child(Estilos_UI.icono_rect("clock", 14, Color("#cbd5e1")))
	_lbl_cuenta = Estilos_UI.texto("5 s", 13, Color("#e2e8f0"), 700)
	_lbl_cuenta.custom_minimum_size = Vector2(30, 0)
	cuenta.add_child(_lbl_cuenta)
	fila.add_child(cuenta)

	_btn_cerrar = Estilos_UI.boton_icono("x", Color("#e2e8f0"), 40)
	_btn_cerrar.name = "Cerrar_Anuncio"
	_btn_cerrar.tooltip_text = "Espera a que termine el anuncio"
	_btn_cerrar.disabled = true
	_btn_cerrar.modulate.a = 0.4
	_btn_cerrar.add_theme_stylebox_override("normal",
		Estilos_UI.caja(Color(1, 1, 1, 0.08), 10, Color(1, 1, 1, 0.12), 1, 0))
	_btn_cerrar.add_theme_stylebox_override("hover",
		Estilos_UI.caja(Color(1, 1, 1, 0.16), 10, Color(1, 1, 1, 0.22), 1, 0))
	_btn_cerrar.add_theme_stylebox_override("pressed",
		Estilos_UI.caja(Color(1, 1, 1, 0.24), 10, Color(1, 1, 1, 0.30), 1, 0))
	_btn_cerrar.pressed.connect(_Cerrar)
	fila.add_child(_btn_cerrar)
	return fila


func _Crear_Creativo() -> Control:
	var creativo_data := Recompensas_Catalogo.Obtener_Creativo(str(anuncio.get("creativo", "burger")))
	var tarjeta := Control.new()
	tarjeta.name = "Creatividad"
	tarjeta.custom_minimum_size = Vector2(0, 510)

	var fondo := Visual_Bienestar.Fondo_Creativo.new()
	fondo.color_a = _color(creativo_data.get("color_fondo", Color("#f59e0b")))
	fondo.color_b = _color(creativo_data.get("color_fondo_2", Color("#dc2626")))
	fondo.radio = 26.0
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	tarjeta.add_child(fondo)

	var margen := MarginContainer.new()
	margen.set_anchors_preset(Control.PRESET_FULL_RECT)
	margen.add_theme_constant_override("margin_left", 34)
	margen.add_theme_constant_override("margin_right", 34)
	margen.add_theme_constant_override("margin_top", 28)
	margen.add_theme_constant_override("margin_bottom", 26)
	tarjeta.add_child(margen)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 18)
	margen.add_child(fila)

	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.size_flags_vertical = Control.SIZE_EXPAND_FILL
	textos.add_theme_constant_override("separation", 8)
	fila.add_child(textos)

	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 8)
	textos.add_child(chips)
	chips.add_child(Estilos_UI.pill_estado("PATROCINADO", Color(0, 0, 0, 0.22), Color(1, 1, 1, 0.86)))
	chips.add_child(Estilos_UI.pill_estado(
		str(creativo_data.get("etiqueta", "NUEVO")),
		_color(creativo_data.get("color_acento", Color("#fef3c7"))),
		_color(creativo_data.get("color_fondo_2", Color("#dc2626")))))

	var marca := HBoxContainer.new()
	marca.add_theme_constant_override("separation", 7)
	textos.add_child(marca)
	marca.add_child(Estilos_UI.icono_rect(str(creativo_data.get("icono", "utensils")), 16, Color(1, 1, 1, 0.88)))
	marca.add_child(Estilos_UI.texto(str(creativo_data.get("marca", "")), 12, Color(1, 1, 1, 0.88), 700))

	var titular := Estilos_UI.titulo(str(creativo_data.get("titular", "")), 40, Color.WHITE)
	titular.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titular.custom_minimum_size = Vector2(0, 110)
	textos.add_child(titular)

	var subtitulo := Estilos_UI.texto(str(creativo_data.get("subtitulo", "")), 15, Color(1, 1, 1, 0.82), 500)
	subtitulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	textos.add_child(subtitulo)

	textos.add_child(Estilos_UI.separador(4))

	var cta := Estilos_UI.pill_estado(
		str(creativo_data.get("cta", "Descubrir")), Color(1, 1, 1, 0.94),
		_color(creativo_data.get("color_fondo_2", Color("#dc2626"))))
	cta.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	textos.add_child(cta)

	var ruta := str(creativo_data.get("imagen", ""))
	if ruta != "" and ResourceLoader.exists(ruta):
		var imagen_marco := PanelContainer.new()
		imagen_marco.custom_minimum_size = Vector2(238, 238)
		imagen_marco.size_flags_horizontal = Control.SIZE_SHRINK_END
		imagen_marco.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var estilo_marco := Estilos_UI.caja(Color(1, 1, 1, 0.18), 999, Color(1, 1, 1, 0.25), 1, 0)
		estilo_marco.content_margin_left = 12
		estilo_marco.content_margin_right = 12
		estilo_marco.content_margin_top = 12
		estilo_marco.content_margin_bottom = 12
		imagen_marco.add_theme_stylebox_override("panel", estilo_marco)
		fila.add_child(imagen_marco)

		var imagen := TextureRect.new()
		imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		imagen.mouse_filter = Control.MOUSE_FILTER_IGNORE
		imagen.texture = load(ruta) as Texture2D
		imagen_marco.add_child(imagen)
	else:
		# Creatividad sin foto: un medallón con el icono de la campaña.
		var medallon := PanelContainer.new()
		medallon.custom_minimum_size = Vector2(176, 176)
		medallon.size_flags_horizontal = Control.SIZE_SHRINK_END
		medallon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		medallon.add_theme_stylebox_override("panel",
			Estilos_UI.caja(Color(1, 1, 1, 0.14), 999, Color(1, 1, 1, 0.24), 1, 0))
		fila.add_child(medallon)
		var centro_medallon := CenterContainer.new()
		medallon.add_child(centro_medallon)
		centro_medallon.add_child(Estilos_UI.icono_rect(
			str(creativo_data.get("icono", "sparkles")), 74, Color(1, 1, 1, 0.92)))

	var aviso := Estilos_UI.texto("ANUNCIO SIMULADO · SIN MARCA REAL", 10, Color(1, 1, 1, 0.72), 700)
	aviso.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	aviso.offset_left = 32
	aviso.offset_top = -28
	aviso.offset_right = 330
	aviso.offset_bottom = -10
	tarjeta.add_child(aviso)

	return tarjeta


func _Crear_Progreso(raiz: Control) -> void:
	var panel := PanelContainer.new()
	panel.name = "Progreso_Anuncio"
	panel.custom_minimum_size = Vector2(0, 176)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Color(0.07, 0.11, 0.19, 0.94), 18, Color(1, 1, 1, 0.10), 1, 2))

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 20)
	margen.add_theme_constant_override("margin_right", 20)
	margen.add_theme_constant_override("margin_top", 14)
	margen.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margen)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 9)
	margen.add_child(v)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	v.add_child(fila)

	var color := _color(anuncio.get("color", Color("#7c3aed")))
	fila.add_child(Estilos_UI.badge_icono(
		str(anuncio.get("icono", "gift")), 42, 21, color, Color.WHITE, 11))

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 0)
	fila.add_child(info)
	info.add_child(Estilos_UI.texto("TU RECOMPENSA", 10, Color("#94a3b8"), 700))
	_lbl_recompensa = Estilos_UI.texto(str(anuncio.get("recompensa_texto", "Recompensa")), 19, Color.WHITE)
	info.add_child(_lbl_recompensa)

	_lbl_tiempo_grande = Estilos_UI.titulo("5 s", 29, Color("#fbbf24"))
	_lbl_tiempo_grande.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_lbl_tiempo_grande.custom_minimum_size = Vector2(62, 0)
	fila.add_child(_lbl_tiempo_grande)

	_barra = ProgressBar.new()
	_barra.custom_minimum_size = Vector2(0, 8)
	_barra.show_percentage = false
	_barra.max_value = 100.0
	_barra.value = 0.0
	_barra.add_theme_stylebox_override("background", Estilos_UI.barra_fondo(999))
	_barra.add_theme_stylebox_override("fill", Estilos_UI.barra_relleno(color, 999))
	v.add_child(_barra)

	_lbl_pie_progreso = Estilos_UI.texto(
		"Si cierras antes de que termine, no se concede la recompensa.",
		11, Color("#94a3b8"), 500)
	_lbl_pie_progreso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_lbl_pie_progreso)
	raiz.add_child(panel)


# ----------------------------------------------------------------------------
# Estados
# ----------------------------------------------------------------------------

func _Actualizar_Textos() -> void:
	var segundos := int(ceil(_restante))
	if _lbl_cuenta != null:
		_lbl_cuenta.text = "%d s" % segundos
	if _lbl_tiempo_grande != null:
		_lbl_tiempo_grande.text = "%d s" % segundos
	if _lbl_recompensa != null:
		_lbl_recompensa.text = str(anuncio.get("recompensa_texto", "Recompensa"))


func _Mostrar_Verificando() -> void:
	_overlay_verificando.visible = true
	_overlay_verificando.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_overlay_verificando, "modulate:a", 1.0, 0.18)


func Mostrar_Recompensa(resultado: Dictionary) -> void:
	_procesando = false
	_verificando = false
	_completado = true
	_overlay_verificando.visible = false
	_overlay_error.visible = false
	_overlay_recompensa.visible = true
	_btn_cerrar.disabled = false
	_btn_cerrar.modulate.a = 1.0
	_btn_cerrar.tooltip_text = "Cerrar"

	_lbl_recompensa_grande.text = str(anuncio.get("recompensa_texto", "Recompensa"))
	if _lbl_cuenta != null:
		_lbl_cuenta.text = "Completado"
	if _lbl_tiempo_grande != null:
		_lbl_tiempo_grande.text = "OK"
		_lbl_tiempo_grande.add_theme_color_override("font_color", Estilos_UI.EXITO)
	if _barra != null:
		_barra.value = 100.0
	if _lbl_pie_progreso != null:
		_lbl_pie_progreso.text = "Recompensa acreditada en tu partida."
		_lbl_pie_progreso.add_theme_color_override("font_color", Estilos_UI.EXITO)
	if _lbl_cuenta != null:
		_lbl_cuenta.add_theme_color_override("font_color", Estilos_UI.EXITO)
	var detalle := _Detalle_Recompensa(resultado)
	_lbl_detalle_recompensa.text = detalle
	if _lbl_saldo_recompensa != null and is_instance_valid(_lbl_saldo_recompensa):
		_lbl_saldo_recompensa.text = _Resumen_Recompensa(resultado)
		_lbl_saldo_recompensa.visible = true
	if _pill_saldo_recompensa != null and is_instance_valid(_pill_saldo_recompensa):
		_pill_saldo_recompensa.visible = true

	_overlay_recompensa.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_overlay_recompensa, "modulate:a", 1.0, 0.2)
	call_deferred("_Lanzar_Estallido")
	call_deferred("_Lanzar_Confeti")


func Mostrar_Error(mensaje: String) -> void:
	_procesando = false
	_verificando = false
	_overlay_verificando.visible = false
	_overlay_error.visible = true
	_lbl_error.text = mensaje
	_btn_cerrar.disabled = false
	_btn_cerrar.modulate.a = 1.0
	_overlay_error.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_overlay_error, "modulate:a", 1.0, 0.18)


func _Lanzar_Estallido() -> void:
	if _estallido != null and is_instance_valid(_estallido):
		_estallido.Disparar()


func _Lanzar_Confeti() -> void:
	if _confeti == null or not is_instance_valid(_confeti):
		return
	_confeti.radio_inicial = 190.0
	_confeti.visible = true
	_confeti.Reiniciar([
		Color("#fbbf24"), Color("#a78bfa"), Color("#34d399"),
		Color("#fb7185"), Color.WHITE,
	], 68)


# ----------------------------------------------------------------------------
# Overlays
# ----------------------------------------------------------------------------

func _Crear_Overlay_Verificando(raiz: Control) -> Control:
	var overlay := Control.new()
	overlay.name = "Overlay_Verificando"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	raiz.add_child(overlay)

	var velo := ColorRect.new()
	velo.color = Color(0.02, 0.04, 0.08, 0.66)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(velo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(centro)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(440, 210)
	panel.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Color("#121d30"), 22, Color(1, 1, 1, 0.10), 1, 4))
	centro.add_child(panel)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)

	var spinner := Indicador_Carga.new()
	spinner.color = Color("#fbbf24")
	spinner.custom_minimum_size = Vector2(48, 48)
	spinner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(spinner)
	var tit := Estilos_UI.titulo("Verificando recompensa…", 19, Color.WHITE)
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tit)
	var sub := Estilos_UI.texto("La red simulada está confirmando el anuncio.", 12, Color("#94a3b8"), 500)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	return overlay


func _Crear_Overlay_Error(raiz: Control) -> Control:
	var overlay := Control.new()
	overlay.name = "Overlay_Error_Anuncio"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	raiz.add_child(overlay)

	var velo := ColorRect.new()
	velo.color = Color(0.02, 0.04, 0.08, 0.76)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(velo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(centro)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 320)
	panel.add_theme_stylebox_override("panel", Estilos_UI.caja(Estilos_UI.SUPERFICIE, 22, Estilos_UI.BORDE, 1, 4))
	centro.add_child(panel)

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 28)
	margen.add_theme_constant_override("margin_right", 28)
	margen.add_theme_constant_override("margin_top", 24)
	margen.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margen)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 12)
	margen.add_child(v)
	v.add_child(Estilos_UI.badge_icono("triangle-alert", 64, 30, Estilos_UI.PELIGRO_SUAVE, Estilos_UI.PELIGRO, 999))
	var tit := Estilos_UI.titulo("No se pudo verificar", 21, Estilos_UI.TINTA)
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tit)
	_lbl_error = Estilos_UI.parrafo(
		"La red simulada no ha podido confirmar la recompensa.", 13, Estilos_UI.TINTA_SUAVE)
	_lbl_error.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_lbl_error)
	var btn := Estilos_UI.boton("Entendido", "primario", "check", Estilos_UI.PRIMARIO, 48)
	btn.custom_minimum_size = Vector2(220, 48)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(_Cerrar)
	v.add_child(btn)
	return overlay


func _Crear_Overlay_Recompensa(raiz: Control) -> Control:
	var overlay := Control.new()
	overlay.name = "Overlay_Recompensa"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	raiz.add_child(overlay)

	var velo := ColorRect.new()
	velo.color = Color(0.02, 0.04, 0.08, 0.72)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(velo)

	_confeti = Visual_Bienestar.Confeti.new()
	_confeti.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confeti.visible = false
	overlay.add_child(_confeti)

	_estallido = Visual_Bienestar.Estallido.new()
	_estallido.set_anchors_preset(Control.PRESET_FULL_RECT)
	_estallido.color = Color("#fbbf24")
	_estallido.visible = false
	overlay.add_child(_estallido)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(centro)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	panel.add_theme_stylebox_override("panel", Estilos_UI.caja(Estilos_UI.SUPERFICIE, 24, Estilos_UI.BORDE, 1, 4))
	centro.add_child(panel)

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 30)
	margen.add_theme_constant_override("margin_right", 30)
	margen.add_theme_constant_override("margin_top", 28)
	margen.add_theme_constant_override("margin_bottom", 26)
	panel.add_child(margen)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 10)
	margen.add_child(v)

	var color := _color(anuncio.get("color", Color("#7c3aed")))
	var marca := PanelContainer.new()
	marca.custom_minimum_size = Vector2(88, 88)
	marca.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	marca.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Color(color, 0.12), 999, Color(color, 0.38), 2, 2))
	var centro_marca := CenterContainer.new()
	marca.add_child(centro_marca)
	centro_marca.add_child(Estilos_UI.icono_rect(str(anuncio.get("icono", "gift")), 42, color))
	v.add_child(marca)

	var tit := Estilos_UI.titulo("¡Recompensa conseguida!", 24, Estilos_UI.TINTA)
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tit)

	_lbl_recompensa_grande = Estilos_UI.titulo(
		str(anuncio.get("recompensa_texto", "Recompensa")), 30, color)
	_lbl_recompensa_grande.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_lbl_recompensa_grande)

	_lbl_detalle_recompensa = Estilos_UI.parrafo(
		"La recompensa se ha añadido a tu partida.", 13, Estilos_UI.TINTA_SUAVE)
	_lbl_detalle_recompensa.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_lbl_detalle_recompensa)

	_pill_saldo_recompensa = Estilos_UI.pill_estado("", Color(color, 0.12), color)
	_pill_saldo_recompensa.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_pill_saldo_recompensa.visible = false
	_lbl_saldo_recompensa = _pill_saldo_recompensa.get_child(0) as Label
	v.add_child(_pill_saldo_recompensa)

	v.add_child(Estilos_UI.separador(4))

	var btn := Estilos_UI.boton("Continuar", "primario", "check", color, 50)
	btn.name = "Continuar_Anuncio"
	btn.custom_minimum_size = Vector2(280, 50)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(_Cerrar)
	v.add_child(btn)
	return overlay


# ----------------------------------------------------------------------------
# Cierre
# ----------------------------------------------------------------------------

func _Cerrar() -> void:
	if _cerrando:
		return
	if _procesando or _verificando:
		return
	_cerrando = true
	if not _completado:
		cancelado.emit(token)
	cerrado.emit()
	queue_free()


func _Animar_Entrada() -> void:
	if _contenido_principal == null:
		return
	_contenido_principal.modulate.a = 0.0
	_contenido_principal.scale = Vector2(0.98, 0.98)
	await get_tree().process_frame
	if not is_instance_valid(_contenido_principal):
		return
	_contenido_principal.pivot_offset = _contenido_principal.size * 0.5
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_contenido_principal, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_contenido_principal, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _Detalle_Recompensa(resultado: Dictionary) -> String:
	for recompensa in resultado.get("recompensas", []):
		if not (recompensa is Dictionary):
			continue
		match str(recompensa.get("tipo", "")):
			"rejuvenecer":
				return "Ahora tienes %d años. El cambio se nota al instante." % int(
					resultado.get("edad", 18))
			"euros":
				return "Tu cartera ha subido a %s." % _Formatear_Euros(
					float(resultado.get("dinero", Variables_Dinamicas.Dinero)))
			"necesidades_todas", "necesidades_sumar":
				return "Tus necesidades básicas se han recuperado."
			"tuppers":
				return "Los tuppers ya están en tu despensa."
	return "La recompensa se ha añadido a tu partida."


func _Resumen_Recompensa(resultado: Dictionary) -> String:
	for recompensa in resultado.get("recompensas", []):
		if not (recompensa is Dictionary):
			continue
		if str(recompensa.get("tipo", "")) == "rejuvenecer":
			return "−%d año%s recuperado%s" % [
				int(recompensa.get("cantidad", 0)),
				"" if int(recompensa.get("cantidad", 0)) == 1 else "s",
				"" if int(recompensa.get("cantidad", 0)) == 1 else "s",
			]
	return "Recompensa aplicada a tu partida"


func _Formatear_Euros(valor: float) -> String:
	var numero := int(round(valor))
	var s := str(absi(numero))
	var salida := ""
	var contador := 0
	for i in range(s.length() - 1, -1, -1):
		salida = s[i] + salida
		contador += 1
		if contador % 3 == 0 and i > 0:
			salida = "." + salida
	return ("-" if numero < 0 else "") + salida + " €"


func _color(valor) -> Color:
	if valor is Color:
		return valor
	return Color(str(valor))


# ============================================================================
# Fondo de pantalla del anuncio
# ============================================================================

class Fondo_Pantalla extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var s := size
		if s.x < 2.0 or s.y < 2.0:
			return
		var arriba := Color("#111d31")
		var abajo := Color("#070c15")
		var alto := int(ceil(s.y))
		for y in range(alto):
			var t := float(y) / maxf(1.0, s.y - 1.0)
			draw_rect(Rect2(0, float(y), s.x, 1.0), arriba.lerp(abajo, t))
		for i in range(6):
			draw_circle(Vector2(s.x * 0.5, s.y * 0.14), 90.0 + float(i) * 34.0,
				Color(0.98, 0.75, 0.14, 0.010))
		for i in range(30):
			var x := fposmod(sin(float(i) * 12.9898) * 43758.5453, 1.0) * s.x
			var y := fposmod(sin(float(i) * 78.233) * 12543.123, 1.0) * s.y
			draw_circle(Vector2(x, y), 1.0, Color(1, 1, 1, 0.08))


class Indicador_Carga extends Control:
	var color: Color = Color("#fbbf24")
	var _angulo: float = 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(true)

	func _process(delta: float) -> void:
		_angulo += delta * 4.2
		queue_redraw()

	func _draw() -> void:
		var centro := size * 0.5
		var radio := minf(size.x, size.y) * 0.5 - 3.0
		if radio <= 1.0:
			return
		draw_arc(centro, radio, 0.0, TAU, 48, Color(color, 0.16), 4.0, true)
		draw_arc(centro, radio, _angulo, _angulo + PI * 1.25, 32, color, 4.0, true)
		draw_circle(centro + Vector2(cos(_angulo + PI * 1.25), sin(_angulo + PI * 1.25)) * radio,
			2.5, Color.WHITE)
