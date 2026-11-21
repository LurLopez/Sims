class_name Modal_Tratamiento
extends CanvasLayer

# ============================================================================
# Confirmación y resultado de un servicio de la clínica de bienestar.
#
# El modal no cobra ni aplica nada: solo muestra el antes/después y emite
# `confirmado`. La pantalla de la tienda llama a Recompensas.Comprar_Servicio y
# devuelve el resultado con Mostrar_Exito/Mostrar_Error.
# ============================================================================

signal confirmado
signal cerrado

var servicio: Dictionary = {}
var coste: float = 0.0
var dinero_disponible: float = 0.0
var edad_actual: int = 18
var edad_objetivo: int = 18
var es_rejuvenecimiento: bool = true

var _procesando: bool = false
var _completado: bool = false
var _cerrando: bool = false
var _color: Color = Color("#0d9488")
var _vista_formulario: VBoxContainer
var _vista_exito: VBoxContainer
var _lbl_error: Label
var _btn_confirmar: Button
var _btn_cancelar: Button
var _btn_cerrar: Button
var _lbl_exito_titulo: Label
var _lbl_exito_grande: Label
var _lbl_exito_detalle: Label
var _lbl_exito_saldo: Label
var _confeti: Visual_Bienestar.Confeti


func _ready() -> void:
	layer = 112
	process_mode = Node.PROCESS_MODE_ALWAYS
	_color = _color_de(servicio.get("color", Color("#0d9488")))
	_Construir_UI()
	_Animar_Entrada()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_Cerrar()


func _notification(que: int) -> void:
	if que == NOTIFICATION_WM_GO_BACK_REQUEST:
		_Cerrar()


# ----------------------------------------------------------------------------
# Construcción
# ----------------------------------------------------------------------------

func _Construir_UI() -> void:
	var raiz := Control.new()
	raiz.name = "Raiz_Tratamiento"
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(raiz)

	var velo := ColorRect.new()
	velo.color = Color(0.02, 0.04, 0.08, 0.66)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo.mouse_filter = Control.MOUSE_FILTER_STOP
	raiz.add_child(velo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.add_child(centro)

	var panel := PanelContainer.new()
	panel.name = "Panel_Tratamiento"
	panel.custom_minimum_size = Vector2(560, 0)
	panel.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Estilos_UI.SUPERFICIE, 24, Estilos_UI.BORDE, 1, 5))
	centro.add_child(panel)

	_confeti = Visual_Bienestar.Confeti.new()
	_confeti.name = "Confeti_Tratamiento"
	_confeti.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confeti.visible = false
	raiz.add_child(_confeti)

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 26)
	margen.add_theme_constant_override("margin_right", 26)
	margen.add_theme_constant_override("margin_top", 22)
	margen.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margen)

	_vista_formulario = VBoxContainer.new()
	_vista_formulario.add_theme_constant_override("separation", 13)
	margen.add_child(_vista_formulario)

	_vista_formulario.add_child(_Crear_Cabecera())

	var titulo := Estilos_UI.titulo(str(servicio.get("titulo", "Servicio")), 24, Estilos_UI.TINTA)
	_vista_formulario.add_child(titulo)

	var desc := Estilos_UI.parrafo(str(servicio.get("descripcion", "")), 13, Estilos_UI.TINTA_SUAVE)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vista_formulario.add_child(desc)

	if es_rejuvenecimiento:
		_vista_formulario.add_child(_Crear_Bloque_Rejuvenecimiento())
	else:
		_vista_formulario.add_child(_Crear_Bloque_Cuidado())

	_vista_formulario.add_child(_Crear_Bloque_Precio())

	_lbl_error = Estilos_UI.texto("", 11, Estilos_UI.PELIGRO, 600)
	_lbl_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_error.visible = false
	_vista_formulario.add_child(_lbl_error)

	_vista_formulario.add_child(Estilos_UI.separador(2))
	_vista_formulario.add_child(_Crear_Pie_Botones())

	_vista_exito = _Crear_Vista_Exito()
	_vista_exito.visible = false
	margen.add_child(_vista_exito)


func _Crear_Cabecera() -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 11)

	fila.add_child(Estilos_UI.badge_icono(str(servicio.get("icono", "sparkles")), 50, 24,
		_color, Color.WHITE, 14))

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 0)
	fila.add_child(info)
	var etiqueta := str(servicio.get("etiqueta", "SERVICIO"))
	info.add_child(Estilos_UI.texto(etiqueta, 10, _color, 700))
	info.add_child(Estilos_UI.texto(str(servicio.get("subtitulo", "")), 12, Estilos_UI.TINTA_SUAVE, 600))

	_btn_cerrar = Estilos_UI.boton_icono("x", Estilos_UI.TINTA_SUAVE, 36)
	_btn_cerrar.name = "Cerrar_Tratamiento"
	_btn_cerrar.add_theme_stylebox_override("normal",
		Estilos_UI.caja(Estilos_UI.SUPERFICIE_2, 10, Estilos_UI.BORDE, 1, 0))
	_btn_cerrar.add_theme_stylebox_override("hover",
		Estilos_UI.caja(Estilos_UI.FONDO_2, 10, Estilos_UI.BORDE_FUERTE, 1, 0))
	_btn_cerrar.add_theme_stylebox_override("pressed",
		Estilos_UI.caja(Estilos_UI.FONDO_2, 10, Estilos_UI.BORDE_FUERTE, 1, 0))
	_btn_cerrar.pressed.connect(_Cerrar)
	fila.add_child(_btn_cerrar)
	return fila


func _Crear_Bloque_Rejuvenecimiento() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Color(_color, 0.08), 16, Color(_color, 0.24), 1, 2))

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 16)
	margen.add_theme_constant_override("margin_right", 16)
	margen.add_theme_constant_override("margin_top", 13)
	margen.add_theme_constant_override("margin_bottom", 13)
	panel.add_child(margen)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	margen.add_child(fila)

	var antes := _Crear_Columna_Edad("AHORA", edad_actual, Estilos_UI.TINTA_SUAVE)
	antes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(antes)

	var flecha := VBoxContainer.new()
	flecha.alignment = BoxContainer.ALIGNMENT_CENTER
	flecha.custom_minimum_size = Vector2(44, 0)
	fila.add_child(flecha)
	flecha.add_child(Estilos_UI.icono_rect("chevron-right", 22, _color))

	var despues := _Crear_Columna_Edad("DESPUÉS", edad_objetivo, _color)
	despues.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(despues)

	var ahorro := int(maxi(0, edad_actual - edad_objetivo))
	var pill := Estilos_UI.pill_estado("−%d año%s" % [ahorro, "" if ahorro == 1 else "s"],
		Color(_color, 0.14), _color)
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(pill)
	return panel


func _Crear_Columna_Edad(etiqueta: String, edad: int, color: Color) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 1)
	var lbl := Estilos_UI.texto(etiqueta, 9, Estilos_UI.TINTA_FANTASMA, 700)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(lbl)
	var valor := Estilos_UI.titulo("%d años" % edad, 22, color)
	valor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(valor)
	return v


func _Crear_Bloque_Cuidado() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Color(_color, 0.08), 16, Color(_color, 0.24), 1, 2))

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 16)
	margen.add_theme_constant_override("margin_right", 16)
	margen.add_theme_constant_override("margin_top", 13)
	margen.add_theme_constant_override("margin_bottom", 13)
	panel.add_child(margen)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 11)
	margen.add_child(fila)
	fila.add_child(Estilos_UI.icono_rect(str(servicio.get("icono", "heart-pulse")), 26, _color))
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 1)
	fila.add_child(v)
	v.add_child(Estilos_UI.texto("RECIBIRÁS", 9, Estilos_UI.TINTA_FANTASMA, 700))
	v.add_child(Estilos_UI.titulo(str(servicio.get("recompensa_texto", "Recompensa")), 18, _color))
	return panel


func _Crear_Bloque_Precio() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Estilos_UI.SUPERFICIE_2, 14, Estilos_UI.BORDE, 1, 0))

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 14)
	margen.add_theme_constant_override("margin_right", 14)
	margen.add_theme_constant_override("margin_top", 10)
	margen.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margen)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	margen.add_child(fila)

	var izq := VBoxContainer.new()
	izq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	izq.add_theme_constant_override("separation", 0)
	fila.add_child(izq)
	izq.add_child(Estilos_UI.texto("COSTE DEL SERVICIO", 9, Estilos_UI.TINTA_FANTASMA, 700))
	var precio := Estilos_UI.titulo(_Formatear_Euros(coste), 22, Estilos_UI.TINTA)
	izq.add_child(precio)

	var der := VBoxContainer.new()
	der.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	der.alignment = BoxContainer.ALIGNMENT_END
	der.add_theme_constant_override("separation", 0)
	fila.add_child(der)
	der.add_child(Estilos_UI.texto("SALDO DESPUÉS", 9, Estilos_UI.TINTA_FANTASMA, 700))
	var saldo := Estilos_UI.titulo(
		_Formatear_Euros(maxf(0.0, dinero_disponible - coste)),
		18, Estilos_UI.EXITO if dinero_disponible >= coste else Estilos_UI.PELIGRO)
	saldo.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	der.add_child(saldo)
	return panel


func _Crear_Pie_Botones() -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)

	_btn_cancelar = Estilos_UI.boton("Cancelar", "fantasma", "", Estilos_UI.TINTA_SUAVE, 46)
	_btn_cancelar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_cancelar.add_theme_font_size_override("font_size", 13)
	_btn_cancelar.pressed.connect(_Cerrar)
	fila.add_child(_btn_cancelar)

	_btn_confirmar = Estilos_UI.boton(
		"Reservar por %s" % _Formatear_Euros(coste), "primario",
		"sparkles" if es_rejuvenecimiento else "check", _color, 46)
	_btn_confirmar.name = "Confirmar_Tratamiento"
	_btn_confirmar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_confirmar.add_theme_font_size_override("font_size", 13)
	_btn_confirmar.disabled = dinero_disponible < coste
	_btn_confirmar.pressed.connect(_Confirmar)
	fila.add_child(_btn_confirmar)
	return fila


func _Crear_Vista_Exito() -> VBoxContainer:
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 10)

	var marca := PanelContainer.new()
	marca.custom_minimum_size = Vector2(84, 84)
	marca.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	marca.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Color(_color, 0.12), 999, Color(_color, 0.38), 2, 2))
	var centro_marca := CenterContainer.new()
	marca.add_child(centro_marca)
	centro_marca.add_child(Estilos_UI.icono_rect("circle-check", 40, _color))
	v.add_child(marca)

	_lbl_exito_titulo = Estilos_UI.titulo("¡Tratamiento completado!", 23, Estilos_UI.TINTA)
	_lbl_exito_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_lbl_exito_titulo)

	_lbl_exito_grande = Estilos_UI.titulo("−1 año", 34, _color)
	_lbl_exito_grande.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_exito_grande.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_exito_grande.custom_minimum_size = Vector2(0, 42)
	v.add_child(_lbl_exito_grande)

	_lbl_exito_detalle = Estilos_UI.parrafo("Tu Sim se siente más joven.", 14, Estilos_UI.TINTA_SUAVE)
	_lbl_exito_detalle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_lbl_exito_detalle)

	_lbl_exito_saldo = Estilos_UI.texto("", 12, Estilos_UI.TINTA_SUAVE, 600)
	_lbl_exito_saldo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_lbl_exito_saldo)

	v.add_child(Estilos_UI.separador(4))

	var btn := Estilos_UI.boton("Genial", "primario", "check", _color, 48)
	btn.name = "Cerrar_Exito_Tratamiento"
	btn.custom_minimum_size = Vector2(260, 48)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(_Cerrar)
	v.add_child(btn)
	return v


# ----------------------------------------------------------------------------
# Estados públicos
# ----------------------------------------------------------------------------

func Mostrar_Procesando() -> void:
	if _btn_confirmar != null and is_instance_valid(_btn_confirmar):
		_btn_confirmar.disabled = true
		_btn_confirmar.text = "Procesando…"
	if _btn_cancelar != null and is_instance_valid(_btn_cancelar):
		_btn_cancelar.disabled = true


func Mostrar_Error(mensaje: String) -> void:
	_procesando = false
	if _lbl_error != null and is_instance_valid(_lbl_error):
		_lbl_error.text = mensaje
		_lbl_error.visible = true
	if _btn_confirmar != null and is_instance_valid(_btn_confirmar):
		_btn_confirmar.disabled = dinero_disponible < coste
		_btn_confirmar.text = "Reservar por %s" % _Formatear_Euros(coste)
	if _btn_cancelar != null and is_instance_valid(_btn_cancelar):
		_btn_cancelar.disabled = false


func Mostrar_Exito(resultado: Dictionary) -> void:
	_completado = true
	_procesando = false
	if _vista_formulario != null and is_instance_valid(_vista_formulario):
		_vista_formulario.visible = false
	if _vista_exito != null and is_instance_valid(_vista_exito):
		_vista_exito.visible = true
		_vista_exito.modulate.a = 0.0

	var aplicados := _Anios_Aplicados(resultado)
	var edad_final := int(resultado.get("edad", edad_objetivo))
	if es_rejuvenecimiento:
		_lbl_exito_grande.add_theme_font_size_override("font_size", 34)
		_lbl_exito_grande.text = "−%d año%s" % [aplicados, "" if aplicados == 1 else "s"]
		_lbl_exito_detalle.text = "Ahora tienes %d años. El cambio se ve al instante en tu Sim." % edad_final
	else:
		_lbl_exito_titulo.text = "¡Servicio completado!"
		_lbl_exito_grande.add_theme_font_size_override("font_size", 24)
		_lbl_exito_grande.text = str(servicio.get("recompensa_texto", "Aplicado"))
		_lbl_exito_detalle.text = "La recompensa ya forma parte de tu partida."
	_lbl_exito_saldo.text = "Saldo restante · %s" % _Formatear_Euros(int(round(float(resultado.get("dinero", 0.0)))))

	if _vista_exito != null and is_instance_valid(_vista_exito):
		var tw := create_tween()
		tw.tween_property(_vista_exito, "modulate:a", 1.0, 0.22)
	call_deferred("_Lanzar_Confeti")


func _Lanzar_Confeti() -> void:
	if _confeti == null or not is_instance_valid(_confeti):
		return
	_confeti.radio_inicial = 0.0
	_confeti.visible = true
	_confeti.Reiniciar([
		Color("#5eead4"), Color("#fbbf24"), Color("#a78bfa"),
		Color("#fb7185"), Color.WHITE,
	], 64)


# ----------------------------------------------------------------------------
# Acciones
# ----------------------------------------------------------------------------

func _Confirmar() -> void:
	if _procesando or _completado:
		return
	_procesando = true
	if _lbl_error != null and is_instance_valid(_lbl_error):
		_lbl_error.visible = false
	Mostrar_Procesando()
	confirmado.emit()


func _Cerrar() -> void:
	if _cerrando or _procesando:
		return
	_cerrando = true
	cerrado.emit()
	queue_free()


func _Animar_Entrada() -> void:
	if _vista_formulario == null:
		return
	_vista_formulario.modulate.a = 0.0
	_vista_formulario.scale = Vector2(0.98, 0.98)
	await get_tree().process_frame
	if not is_instance_valid(_vista_formulario):
		return
	_vista_formulario.pivot_offset = _vista_formulario.size * 0.5
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_vista_formulario, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_vista_formulario, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ----------------------------------------------------------------------------
# Utilidades
# ----------------------------------------------------------------------------

func _Anios_Aplicados(resultado: Dictionary) -> int:
	var recompensas = resultado.get("recompensas", [])
	if recompensas is Array:
		for recompensa in recompensas:
			if recompensa is Dictionary and str(recompensa.get("tipo", "")) == "rejuvenecer":
				return maxi(0, int(recompensa.get("cantidad", 0)))
	return 0


func _Formatear_Euros(valor) -> String:
	var numero := int(round(float(valor)))
	var negativo := numero < 0
	var s := str(absi(numero))
	var salida := ""
	var contador := 0
	for i in range(s.length() - 1, -1, -1):
		salida = s[i] + salida
		contador += 1
		if contador % 3 == 0 and i > 0:
			salida = "." + salida
	return ("-" if negativo else "") + salida + " €"


func _color_de(valor) -> Color:
	if valor is Color:
		return valor
	return Color(str(valor))
