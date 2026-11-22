extends "res://Scripts/Logica/Escena_Principal/Actividades/Carreras/UI/Modal_Carrera_Base.gd"

# Resultado oficial del examen automático.
#
# Sustituye el AcceptDialog de texto por una ficha de expediente: estado,
# anillo con la nota final, desglose y recompensa de graduación. El cierre
# emite `cerrado`, que Script_Principal usa para confirmar el resultado.

const Anillo_Nota = preload("res://Scripts/Logica/Escena_Principal/Actividades/Carreras/UI/Anillo_Nota.gd")

var carrera: Carrera = null
var _btn_continuar: Button


func _Al_Listo() -> void:
	permitir_cerrar_al_fondo = false
	actualizar_cabecera("Resultado del examen", "Consulta tu nota final",
		"EXPEDIENTE ACADÉMICO", "badge-check")
	_Construir_Pie()
	if carrera != null:
		_Renderizar()
	else:
		_Mostrar_Error("No hay ningún resultado que mostrar.")


func Configurar(_carrera: Carrera) -> void:
	carrera = _carrera
	if is_node_ready():
		_Renderizar()


func _Construir_Pie() -> void:
	if not pie.get_children().is_empty():
		return
	_btn_continuar = Estilos_UI.boton("Continuar", "primario", "check",
		Estilos_UI.EXITO, 50)
	_btn_continuar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_continuar.pressed.connect(cerrar)
	pie.add_child(_btn_continuar)


func _Renderizar() -> void:
	if carrera == null:
		return
	var aprobado: bool = carrera.ultimo_resultado_aprobado
	var completada: bool = carrera.completada
	var nota: float = carrera.ultima_nota_final
	var color := Estilos_UI.EXITO
	var color_suave := Estilos_UI.EXITO_SUAVE
	var color_oscuro := Estilos_UI.EXITO_OSCURO
	var icono := "badge-check"
	var titulo := "¡Aprobado!"
	var estado := "Aprobado"
	var subtitulo := "Has superado el Año %d. Ya estás en el Año %d." % [
		maxi(carrera.año_actual - 1, 1), carrera.año_actual]
	var titulo_cabecera := "Resultado del examen"
	var texto_boton := "Continuar"

	if completada:
		color = Estilos_UI.ORO
		color_suave = Estilos_UI.ORO_SUAVE
		color_oscuro = Color("#92400e")
		icono = "trophy"
		titulo = "¡Titulación conseguida!"
		estado = "Graduado"
		subtitulo = "Has superado el último curso. Tu título ya forma parte de tu perfil."
		titulo_cabecera = "Carrera completada"
		texto_boton = "Continuar"
	elif not aprobado:
		color = Estilos_UI.PELIGRO
		color_suave = Estilos_UI.PELIGRO_SUAVE
		color_oscuro = Color("#991b1b")
		icono = "circle-x"
		titulo = "Suspendido"
		estado = "Suspendido"
		subtitulo = "No has alcanzado el 50. Puedes volver a intentarlo con otra matrícula."

	var nombre := nombre_carrera(carrera.nombre)
	var subtitulo_cabecera := nombre
	if completada:
		subtitulo_cabecera += " · Titulación completada"
	else:
		subtitulo_cabecera += " · Año %d de %d" % [
			min(carrera.año_actual, carrera.años_totales), carrera.años_totales]
	actualizar_cabecera(titulo_cabecera, subtitulo_cabecera,
		"EXPEDIENTE ACADÉMICO", icono, color.darkened(0.10))

	for hijo in contenido.get_children():
		contenido.remove_child(hijo)
		hijo.queue_free()
	contenido.alignment = BoxContainer.ALIGNMENT_CENTER
	contenido.custom_minimum_size.y = maxf(get_viewport().get_visible_rect().size.y - 230.0, 620.0)

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

	var badge := Estilos_UI.badge_icono(icono, 72, 36, color_suave, color_oscuro, 22)
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(badge)

	var pill := Estilos_UI.pill_estado(estado, color_suave, color_oscuro)
	pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(pill)

	var titulo_lbl := Estilos_UI.titulo(titulo, 27, Estilos_UI.TINTA)
	titulo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(titulo_lbl)

	var sub := Estilos_UI.parrafo(subtitulo, 13, Estilos_UI.TINTA_SUAVE)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)

	var anillo_cont := Control.new()
	anillo_cont.custom_minimum_size = Vector2(182, 182)
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
	var nota_lbl := Estilos_UI.titulo("%.1f" % nota, 40, color_oscuro)
	nota_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	centro.add_child(nota_lbl)
	var cien := Estilos_UI.texto("nota final sobre 100", 11, Estilos_UI.TINTA_FANTASMA, 600)
	cien.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	centro.add_child(cien)

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

	dv.add_child(_Fila_Detalle("Nota final", "%.1f / 100" % nota, color_oscuro))
	dv.add_child(Estilos_UI.divisor_horizontal())
	dv.add_child(_Fila_Detalle("Resultado", estado, color_oscuro))

	var ultima_nota_jugador := 0
	if not carrera.historial_notas.is_empty():
		var ultima: Dictionary = carrera.historial_notas[-1]
		ultima_nota_jugador = int(ultima.get("nota_real_jugador", 0))
	if ultima_nota_jugador > 0:
		dv.add_child(Estilos_UI.divisor_horizontal())
		dv.add_child(_Fila_Detalle("Test del jugador", "%d / 100" % ultima_nota_jugador,
			Estilos_UI.AZUL))

	if completada:
		var bonus := int(Variables_Estaticas.Obtener_Bonus_Carrera(
			Sistema_Examenes.BONUS_DINERO_CARRERA_COMPLETADA))
		dv.add_child(Estilos_UI.divisor_horizontal())
		dv.add_child(_Fila_Detalle("Bonus por graduarte", "+%d €" % bonus,
			Estilos_UI.EXITO_OSCURO))
		dv.add_child(Estilos_UI.divisor_horizontal())
		dv.add_child(_Fila_Detalle("Nuevo título", nombre, Estilos_UI.TINTA))
	elif aprobado:
		dv.add_child(Estilos_UI.divisor_horizontal())
		dv.add_child(_Fila_Detalle("Nuevo curso", "Año %d" % min(carrera.año_actual, carrera.años_totales),
			Estilos_UI.TINTA))

	if completada:
		var aviso := PanelContainer.new()
		aviso.add_theme_stylebox_override("panel",
			Estilos_UI.caja(Estilos_UI.ORO_SUAVE, 12, Color(Estilos_UI.ORO, 0.24), 1, 0))
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
		var ai := Estilos_UI.icono_rect("graduation-cap", 17, Color("#92400e"))
		ai.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ah.add_child(ai)
		var at := Estilos_UI.parrafo(
			"El diploma está disponible en la pestaña Apuntes de tu perfil. También has desbloqueado un nuevo empleo cualificado.",
			12, Color("#92400e"))
		at.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ah.add_child(at)
	elif not aprobado:
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
			"Estudiar sube el progreso y cuidar tus necesidades mejora la nota del próximo intento.",
			12, Estilos_UI.AZUL)
		at.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ah.add_child(at)

	if _btn_continuar != null:
		_btn_continuar.text = texto_boton
		_btn_continuar.icon = Estilos_UI.icono("check")
		Estilos_UI.aplicar_estilo_boton(_btn_continuar, "primario", color_oscuro, "check")
		_btn_continuar.custom_minimum_size = Vector2(0, 50)

	scroll_principal.set_deferred("scroll_vertical", 0)


func _Mostrar_Error(mensaje: String) -> void:
	for hijo in contenido.get_children():
		contenido.remove_child(hijo)
		hijo.queue_free()
	var lbl := Estilos_UI.parrafo(mensaje, 14, Estilos_UI.TINTA_SUAVE)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	contenido.add_child(lbl)


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
