extends Node

const COLOR_PASADO       := Color("#e2e8f0")
const COLOR_PASADO_BORDE := Color("#cbd5e1")
const COLOR_PASADO_P     := Color("#cbd5e1")

const COLOR_LIBRE        := Color("#dcfce7")
const COLOR_LIBRE_HOVER  := Color("#bbf7d0")
const COLOR_LIBRE_BORDE  := Color("#86efac")
const COLOR_LIBRE_P      := Color("#4ade80")

const COLOR_OCUPADO      := Color("#dbeafe")
const COLOR_OCUPADO_P    := Color("#93c5fd")

const PALETA_ACTIVIDADES := {
	"Dormir": Color("#4f46e5"),
	"Cocinar": Color("#ea580c"),
	"Comer_Tupper": Color("#059669"),
	"Comer_Basura": Color("#e11d48"),
	"Duchar": Color("#0284c7"),
	"Ver_La_Television": Color("#7c3aed"),
	"Estudiar": Color("#2563eb"),
	"Estudiar_Carrera": Color("#1d4ed8"),
	"Salir_A_Correr": Color("#16a34a"),
	"Practicar_Manualidades": Color("#d97706"),
	"Salir_De_Fiesta": Color("#db2777"),
	"Examen_Carrera": Color("#dc2626"),
	"Carrera_Deportiva": Color("#ea580c"),
	"Entrenamiento_Futbol": Color("#0284c7"),
	"Partido_Futbol": Color("#16a34a"),
	"Trabajar_En_Comida_Rapida": Color("#d97706"),
	"Trabajar_De_Carpintero": Color("#b45309"),
	"Trabajar_De_Cientifico": Color("#0284c7"),
	"Trabajar_De_Abogado": Color("#4338ca"),
	"Trabajar_De_Medico": Color("#dc2626"),
	"Trabajar_De_Artista": Color("#c026d3"),
	"Trabajar_De_Ayudante_Cocina": Color("#ea580c"),
	"Trabajar_De_Cocinero_Partida": Color("#c2410c"),
	"Trabajar_De_Chef_Ejecutivo": Color("#991b1b"),
}

var bloque_columna

var semana
var presionado
var posicion_minuto_inicio
var dia_inicio
var posicion_minuto_final
var dia_final

var tamaño_bloque = 0
var excepcion

var matriz_bloques
var libre
var ultimo_diferente


static func color_para_actividad(nombre_bloque: String) -> Color:
	if PALETA_ACTIVIDADES.has(nombre_bloque):
		return PALETA_ACTIVIDADES[nombre_bloque]
	var act_cat = Variables_Estaticas.Catalogo_Actividades.get(nombre_bloque, null)
	if act_cat != null and act_cat is Actividad:
		return act_cat.color
	return Color("#2563eb")


func Inicializar(r):
	if bloque_columna == null or not is_instance_valid(bloque_columna):
		bloque_columna = BloqueDiaColumna.new()
	bloque_columna.Inicializar(r)


func Añadir_Horas_Al_Horario():
	for i in range(48):
		var hora_inicio: int = (i * 30) / 60
		var minuto_inicio: int = (i * 30) % 60
		var es_en_punto: bool = (minuto_inicio == 0)

		var texto := "%02d:%02d" % [hora_inicio, minuto_inicio]

		var boton := Button.new()
		boton.mouse_filter = Control.MOUSE_FILTER_PASS
		boton.focus_mode = Control.FOCUS_NONE
		boton.text = texto

		var estilo := StyleBoxFlat.new()
		estilo.bg_color = Color("#f1f5f9") if es_en_punto else Color("#f8fafc")
		estilo.set_corner_radius_all(0)
		estilo.border_width_left = 0
		estilo.border_width_right = 1
		estilo.border_width_top = 0
		estilo.border_width_bottom = 1 if es_en_punto else 2
		estilo.border_color = Color("#e2e8f0") if es_en_punto else Color("#cbd5e1")
		estilo.content_margin_right = 8
		estilo.content_margin_top = 0
		estilo.content_margin_bottom = 0

		boton.add_theme_stylebox_override("normal", estilo)
		boton.add_theme_stylebox_override("hover", estilo)
		boton.add_theme_stylebox_override("pressed", estilo)
		boton.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		boton.add_theme_font_override("font", Estilos_UI.fuente_ui(700 if es_en_punto else 500))
		boton.add_theme_color_override("font_color", Color("#334155") if es_en_punto else Color("#94a3b8"))
		boton.add_theme_color_override("font_hover_color", Color("#334155") if es_en_punto else Color("#94a3b8"))
		boton.add_theme_color_override("font_pressed_color", Color("#334155") if es_en_punto else Color("#94a3b8"))
		boton.add_theme_font_size_override("font_size", 11 if es_en_punto else 10)
		boton.alignment = HORIZONTAL_ALIGNMENT_RIGHT
		boton.custom_minimum_size = Vector2(68, 30)
		bloque_columna.horario_columna.add_child(boton)


func Agregar_Bloques(mirar_semana, raiz):
	matriz_bloques = Funciones_Globales.Devolver_Bloque_Matriz_Semana_(mirar_semana)
	var hoy := fecha.new()
	hoy.Inicializar(Variables_Dinamicas.Minute_Day, Variables_Dinamicas.Minute_Minute)

	for i in range(7):
		var j := 0
		while j < 288:
			var act_actual = matriz_bloques[j][i]
			var es_pasado: bool = _Es_Bloque_Pasado(hoy, mirar_semana, i, j) or (act_actual is String and act_actual == "Actividad_Aleatoria")
			var act_norm = _Normalizar_Act_Bloque(act_actual, es_pasado)
			var inicio := j
			j += 1
			while j < 288:
				var sig_raw = matriz_bloques[j][i]
				var sig_pasado: bool = _Es_Bloque_Pasado(hoy, mirar_semana, i, j) or (sig_raw is String and sig_raw == "Actividad_Aleatoria")
				var sig_norm = _Normalizar_Act_Bloque(sig_raw, sig_pasado)
				if sig_pasado != es_pasado or not _Misma_Actividad(sig_norm, act_norm):
					break
				j += 1
			_Crear_Boton_Bloque(i, j - inicio, act_norm, raiz, es_pasado, inicio)

	hoy.free()


func _Normalizar_Act_Bloque(act, es_pasado: bool):
	if es_pasado and act is String and act == "Actividad_Aleatoria":
		return ""
	return act


func _Es_Bloque_Pasado(hoy: fecha, mirar_semana: int, dia_idx: int, slot_j: int) -> bool:
	var mirar := fecha.new()
	# Un slot de 5 min [slot_j*5, (slot_j+1)*5) ya es pasado si el minuto actual superó su inicio.
	mirar.Inicializar(mirar_semana * 7 + dia_idx, slot_j * 5 + 1)
	var pasado: bool = hoy.Comparar_Dos_Fechas(mirar)
	mirar.free()
	return pasado


func _Misma_Actividad(a, b) -> bool:
	return typeof(a) == typeof(b) and a == b


func _Crear_Boton_Bloque(i: int, cantidad_slots: int, act_actual, raiz, crear_boton_del_pasado: bool, slot_inicio: int = 0):
	var boton := Button.new()
	boton.mouse_filter = Control.MOUSE_FILTER_PASS
	boton.focus_mode = Control.FOCUS_NONE
	# Forzar font_size mínimo en el Button base para que Godot 4 no imponga ~22px
	# de alto mínimo en bloques cortos de 5, 10, 15 o 20 minutos.
	boton.add_theme_font_size_override("font_size", 1)
	boton.connect("pressed", Callable(self, "click_bloque").bind(boton, raiz))

	var estilo := StyleBoxFlat.new()
	estilo.set_border_width_all(1)
	estilo.border_color = Color("#e2e8f0")
	estilo.set_corner_radius_all(4)
	estilo.content_margin_left = 2
	estilo.content_margin_right = 2
	estilo.content_margin_top = 0
	estilo.content_margin_bottom = 0

	var estilo_hover := estilo.duplicate() as StyleBoxFlat

	var estilo_pulsado := StyleBoxFlat.new()
	estilo_pulsado.set_border_width_all(2)
	estilo_pulsado.border_color = Estilos_UI.PRIMARIO
	estilo_pulsado.set_corner_radius_all(4)
	estilo_pulsado.content_margin_left = 2
	estilo_pulsado.content_margin_right = 2
	estilo_pulsado.content_margin_top = 0
	estilo_pulsado.content_margin_bottom = 0

	var nombre_bloque: String = str(act_actual) if act_actual is String else str(act_actual.nombre)
	var color_texto_lbl: Color = Estilos_UI.TINTA

	if crear_boton_del_pasado:
		if nombre_bloque != "" and nombre_bloque != "Actividad_Aleatoria":
			var c_pas: Color = color_para_actividad(nombre_bloque)
			estilo.bg_color = c_pas.lerp(Color("#e2e8f0"), 0.78)
			estilo.border_width_left = 3
			estilo.border_color = c_pas.lerp(Color("#94a3b8"), 0.55)
			estilo_hover.bg_color = c_pas.lerp(Color("#cbd5e1"), 0.72)
			estilo_hover.border_width_left = 3
			estilo_hover.border_color = estilo.border_color
			estilo_pulsado.bg_color = c_pas.lerp(Color("#cbd5e1"), 0.58)
			estilo_pulsado.border_width_left = 4
			estilo_pulsado.border_color = Color("#475569")
			color_texto_lbl = Color("#475569")
		else:
			estilo.bg_color = COLOR_PASADO
			estilo.border_color = COLOR_PASADO_BORDE
			estilo_hover.bg_color = Color("#d8e0ea")
			estilo_hover.border_color = COLOR_PASADO_BORDE
			estilo_pulsado.bg_color = COLOR_PASADO_P
			estilo_pulsado.border_color = Color("#64748b")
			color_texto_lbl = Color("#64748b")
		boton.set_meta("estado", "pasado")
	elif act_actual is String and (act_actual == "" or act_actual == "Actividad_Aleatoria"):
		estilo.bg_color = COLOR_LIBRE
		estilo.border_color = COLOR_LIBRE_BORDE
		estilo_hover.bg_color = COLOR_LIBRE_HOVER
		estilo_hover.border_color = Color("#4ade80")
		estilo_pulsado.bg_color = COLOR_LIBRE_P
		estilo_pulsado.border_color = Color("#15803d")
		boton.set_meta("estado", "libre")
	else:
		var c_act: Color = color_para_actividad(nombre_bloque)
		estilo.bg_color = c_act.lerp(Color.WHITE, 0.74)
		estilo.border_width_left = 4
		estilo.border_color = c_act.lerp(Color.WHITE, 0.18)
		estilo_hover.bg_color = c_act.lerp(Color.WHITE, 0.64)
		estilo_hover.border_width_left = 4
		estilo_hover.border_color = c_act
		estilo_pulsado.bg_color = c_act.lerp(Color.WHITE, 0.38)
		estilo_pulsado.border_width_left = 5
		estilo_pulsado.border_color = c_act.darkened(0.20)
		color_texto_lbl = c_act.darkened(0.45)
		boton.set_meta("estado", "ocupado")

	boton.add_theme_stylebox_override("normal", estilo)
	boton.add_theme_stylebox_override("hover", estilo_hover)
	boton.add_theme_stylebox_override("pressed", estilo_pulsado)
	boton.add_theme_stylebox_override("hover_pressed", estilo_pulsado)
	boton.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	boton.set_meta("actividad", act_actual)
	boton.set_meta("slot_inicio", slot_inicio)
	boton.set_meta("slot_final", slot_inicio + cantidad_slots)
	boton.set_meta("dia_idx", i)
	boton.toggle_mode = true

	var act_obj = Variables_Estaticas.Catalogo_Actividades.get(nombre_bloque, null)
	if not (act_actual is String) and boton.get_meta("estado") == "ocupado" and act_actual.icono != null:
		var tex_rect := TextureRect.new()
		tex_rect.texture = act_actual.icono
		tex_rect.stretch_mode = TextureRect.STRETCH_TILE
		tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		boton.clip_contents = true
		boton.add_child(tex_rect)
	elif act_obj is Actividad and boton.get_meta("estado") == "ocupado" and act_obj.icono != null:
		var tex_rect2 := TextureRect.new()
		tex_rect2.texture = act_obj.icono
		tex_rect2.stretch_mode = TextureRect.STRETCH_TILE
		tex_rect2.set_anchors_preset(Control.PRESET_FULL_RECT)
		tex_rect2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		boton.clip_contents = true
		boton.add_child(tex_rect2)

	var alto_px: float = cantidad_slots * 5.0
	boton.custom_minimum_size = Vector2(0, alto_px)

	if nombre_bloque != "" and nombre_bloque != "Actividad_Aleatoria" and alto_px >= 18.0:
		var lbl_b := Label.new()
		lbl_b.text = _Formatear_Nombre_Actividad(nombre_bloque)
		lbl_b.add_theme_font_override("font", Estilos_UI.fuente_ui(700 if not crear_boton_del_pasado else 600))
		lbl_b.add_theme_font_size_override("font_size", 10 if alto_px >= 24.0 else 9)
		lbl_b.add_theme_color_override("font_color", color_texto_lbl)
		lbl_b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_b.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		lbl_b.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl_b.offset_left = 4
		lbl_b.offset_right = -2
		lbl_b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		boton.clip_contents = true
		boton.add_child(lbl_b)

	match i:
		0: bloque_columna.lunes_columna.add_child(boton)
		1: bloque_columna.martes_columna.add_child(boton)
		2: bloque_columna.miercoles_columna.add_child(boton)
		3: bloque_columna.jueves_columna.add_child(boton)
		4: bloque_columna.viernes_columna.add_child(boton)
		5: bloque_columna.sabado_columna.add_child(boton)
		6: bloque_columna.domingo_columna.add_child(boton)


func AgregarBloquesPasados(i, j, mirar_semana):
	var hoy := fecha.new()
	hoy.Inicializar(Variables_Dinamicas.Minute_Day, Variables_Dinamicas.Minute_Minute)
	var mirar := fecha.new()
	mirar.Inicializar(mirar_semana * 7 + i, (j + 1) * 5)
	if not hoy.Comparar_Dos_Fechas(mirar):
		excepcion = false
	hoy.free()
	mirar.free()


func _Formatear_Nombre_Actividad(nombre: String) -> String:
	if nombre == "":
		return "Tiempo libre"
	if nombre == "Actividad_Aleatoria":
		return "Actividad aleatoria"
	if nombre == "Examen_Carrera":
		return "Examen"
	if nombre == "Comer_Tupper":
		return "Comida casera"
	if nombre == "Comer_Basura":
		return "Comida rápida"
	if nombre == "Carrera_Deportiva":
		return "Carrera deportiva"
	if nombre == "Entrenamiento_Futbol":
		return "Entrenamiento"
	if nombre == "Partido_Futbol":
		return "Partido"
	if nombre == "Estudiar_Carrera":
		return "Estudiar carrera"
	return nombre.replace("Trabajar_En_", "").replace("Trabajar_De_", "").replace("_", " ")


func _Formatear_Rango_Seleccionado() -> String:
	var d_ini := -1
	var m_ini := 0
	var d_fin := -1
	var m_fin := 0
	var cols := [
		bloque_columna.lunes_columna,
		bloque_columna.martes_columna,
		bloque_columna.miercoles_columna,
		bloque_columna.jueves_columna,
		bloque_columna.viernes_columna,
		bloque_columna.sabado_columna,
		bloque_columna.domingo_columna,
	]
	for idx in range(cols.size()):
		var col = cols[idx]
		if col == null:
			continue
		for child in col.get_children():
			if child is Button and child.button_pressed:
				var s_ini: int = int(child.get_meta("slot_inicio", roundi(child.position.y / 5.0)))
				var s_fin: int = int(child.get_meta("slot_final", roundi((child.position.y + child.size.y) / 5.0)))
				if d_ini == -1:
					d_ini = idx
					m_ini = s_ini * 5
				d_fin = idx
				m_fin = s_fin * 5
	if d_ini == -1:
		return ""
	var h_i: int = m_ini / 60
	var min_i: int = m_ini % 60
	var h_f: int = m_fin / 60
	var min_f: int = m_fin % 60
	var dur_min: int = (d_fin - d_ini) * 1440 + (m_fin - m_ini)
	var dur_txt := ""
	if dur_min >= 60:
		var dh: int = dur_min / 60
		var dm: int = dur_min % 60
		dur_txt = "%dh" % dh if dm == 0 else "%dh %02dm" % [dh, dm]
	elif dur_min > 0:
		dur_txt = "%d min" % dur_min

	var nombres_dias := ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]
	if d_ini == d_fin:
		return "%s %02d:%02d–%02d:%02d%s" % [
			nombres_dias[d_ini], h_i, min_i, h_f, min_f,
			(" (" + dur_txt + ")") if dur_txt != "" else ""
		]
	else:
		return "%s %02d:%02d – %s %02d:%02d" % [
			nombres_dias[d_ini], h_i, min_i, nombres_dias[d_fin], h_f, min_f
		]


func click_bloque(boton, raiz):
	bloque_columna.desactivar_todos_los_botones()

	boton.set_toggle_mode(true)
	boton.set_pressed(true)

	comprobar_color_boton_seleccionado(boton, raiz)
	comprobar_izquierda(boton, raiz)
	comprobar_derecha(boton, raiz)

	var act_meta = boton.get_meta("actividad")
	var estado: String = str(boton.get_meta("estado", ""))
	var nombre_act: String = _Formatear_Nombre_Actividad(str(act_meta) if act_meta is String else str(act_meta.nombre))
	var rango_txt: String = _Formatear_Rango_Seleccionado()
	var texto_sel := ""
	if estado == "pasado":
		if nombre_act != "" and nombre_act != "Tiempo libre" and nombre_act != "Actividad aleatoria":
			texto_sel = "Bloque pasado · %s" % nombre_act
		else:
			texto_sel = "Bloque pasado"
	else:
		texto_sel = nombre_act
	if rango_txt != "":
		texto_sel += "  ·  " + rango_txt

	var lbl_texto := raiz.get_node_or_null("Actividades/Horario_Semanal/OPCIONES_CALENDARIO/Actividad_Texto") as Label
	if lbl_texto != null:
		lbl_texto.text = texto_sel
	if raiz.has_method("_Actualizar_Panel_Seleccion_Horario"):
		raiz._Actualizar_Panel_Seleccion_Horario(estado, texto_sel)


func comprobar_izquierda(boton, raiz):
	var comprobar_izq = true
	var ver_dia = primer_dia_comprobar(boton, raiz)
	while ver_dia != "" and comprobar_izq == true:
		var boton2 = obtener_ultimo_bloques_dia(ver_dia, raiz)
		comprobar_izq = fusinar_botones(boton, boton2)
		boton = boton2
		ver_dia = primer_dia_comprobar(boton, raiz)


func comprobar_derecha(boton, raiz):
	var comprobar_der = true
	var ver_dia = ultimo_dia_comprobar(boton, raiz)
	while ver_dia != "" and comprobar_der == true:
		var boton2 = obtener_primer_bloque_dia(ver_dia, raiz)
		comprobar_der = fusinar_botones(boton, boton2)
		boton = boton2
		ver_dia = ultimo_dia_comprobar(boton, raiz)


func fusinar_botones(boton1, boton2):
	if boton1 == null or boton2 == null:
		return false
	var act1 = boton1.get_meta("actividad", null)
	var act2 = boton2.get_meta("actividad", null)
	var est1 = boton1.get_meta("estado", "")
	var est2 = boton2.get_meta("estado", "")
	if typeof(act1) == typeof(act2) and act1 == act2 and est1 == est2:
		boton2.set_pressed(true)
		boton2.set_toggle_mode(true)
		return true
	else:
		return false


func obtener_primer_bloque_dia(dia, raiz):
	var vbox_cont = raiz.get_node(NodePath("Actividades/Horario_Semanal/Mover_Vertical/Todo calendario/Dias/" + dia))
	if vbox_cont.get_child_count() == 0:
		return null
	return vbox_cont.get_child(0)


func obtener_ultimo_bloques_dia(dia, raiz):
	var vbox_cont = raiz.get_node(NodePath("Actividades/Horario_Semanal/Mover_Vertical/Todo calendario/Dias/" + dia))
	if vbox_cont.get_child_count() == 0:
		return null
	return vbox_cont.get_child(vbox_cont.get_child_count() - 1)


func primer_dia_comprobar(boton, raiz):
	var bloques_list = devolver_primeros_botones(raiz)
	var dia = ""
	for i in range(1, 7):
		if i - 1 < bloques_list.size() and bloques_list[i - 1] == boton:
			dia = Funciones_Globales.Devolver_Dia(i - 1)
	return dia


func ultimo_dia_comprobar(boton, raiz):
	var bloques_list = devolver_ultimos_botones(raiz)
	var dia = ""
	for i in 6:
		if i < bloques_list.size() and bloques_list[i] == boton:
			dia = Funciones_Globales.Devolver_Dia(i + 1)
	return dia


func devolver_ultimos_botones(raiz):
	var bloque_list = []
	for i in 6:
		var dia = Funciones_Globales.Devolver_Dia(i)
		var vbox_cont = raiz.get_node(NodePath("Actividades/Horario_Semanal/Mover_Vertical/Todo calendario/Dias/" + dia))
		if vbox_cont.get_child_count() > 0:
			bloque_list.append(vbox_cont.get_child(vbox_cont.get_child_count() - 1))
		else:
			bloque_list.append(null)
	return bloque_list


func devolver_primeros_botones(raiz):
	var bloque_list = []
	for i in range(1, 7):
		var dia = Funciones_Globales.Devolver_Dia(i)
		var vbox_cont = raiz.get_node(NodePath("Actividades/Horario_Semanal/Mover_Vertical/Todo calendario/Dias/" + dia))
		if vbox_cont.get_child_count() > 0:
			bloque_list.append(vbox_cont.get_child(0))
		else:
			bloque_list.append(null)
	return bloque_list


func comprobar_color_boton_seleccionado(boton, raiz):
	var estado = boton.get_meta("estado", "libre")
	if estado == "libre":
		verde_seleccionado(raiz)
	elif estado == "ocupado":
		rojo_seleccionado(raiz)
	elif estado == "pasado":
		azul_seleccionado(raiz)


func verde_seleccionado(raiz):
	devolver_boton_ocupar_actividad(raiz).visible = not raiz.calendario_solo_lectura
	devolver_boton_eliminar_actividad(raiz).visible = false


func rojo_seleccionado(raiz):
	devolver_boton_eliminar_actividad(raiz).visible = true
	devolver_boton_ocupar_actividad(raiz).visible = false


func azul_seleccionado(raiz):
	devolver_boton_ocupar_actividad(raiz).visible = false
	devolver_boton_eliminar_actividad(raiz).visible = false


func devolver_boton_ocupar_actividad(raiz):
	return Gestionar_Visibilidad.devolver_boton_ocupar_actividad(raiz)


func devolver_boton_eliminar_actividad(raiz):
	return Gestionar_Visibilidad.devolver_boton_eliminar_actividad(raiz)


## on_ocupar_actividad_pressed
func devolver_hora_desde_posiciones():
	var dia_inicio_string = Funciones_Globales.Devolver_Dia(dia_inicio)
	var cincominuto_inicio = roundi(posicion_minuto_inicio / 5.0)
	var hora_inicio = int(cincominuto_inicio / 12)
	var minuto_inicio = int(cincominuto_inicio % 12) * 5
	var cincominuto_final = roundi(posicion_minuto_final / 5.0)
	var dia_final_res: int = dia_final
	var hora_final = int(cincominuto_final / 12)
	var minuto_final = int(cincominuto_final % 12) * 5
	if cincominuto_final >= 288:
		if dia_final_res < 6:
			dia_final_res += 1
			hora_final = 0
			minuto_final = 0
		else:
			hora_final = 24
			minuto_final = 0
	var dia_final_string = Funciones_Globales.Devolver_Dia(dia_final_res)

	var horariobloque = HorarioDesdeBloque.new()
	horariobloque.Inicializar(dia_inicio_string, hora_inicio, minuto_inicio, dia_final_string, hora_final, minuto_final)
	return horariobloque


func comprobar_seleccionado():
	presionado = false
	var verde = true
	posicion_minuto_inicio = -1
	dia_inicio = -1
	for col in [
		bloque_columna.lunes_columna,
		bloque_columna.martes_columna,
		bloque_columna.miercoles_columna,
		bloque_columna.jueves_columna,
		bloque_columna.viernes_columna,
		bloque_columna.sabado_columna,
		bloque_columna.domingo_columna,
	]:
		if not comprobar_seleccionado_dia(col):
			verde = false
	return verde and presionado


func comprobar_seleccionado_dia(dia):
	var verde = true
	if dia == null:
		return true
	for child in dia.get_children():
		if child is Button:
			if child.button_pressed:
				presionado = true
				dia_final = calcular_dia(dia)
				if child.has_meta("slot_final"):
					posicion_minuto_final = int(child.get_meta("slot_final")) * 5
				else:
					posicion_minuto_final = child.position.y + int(child.size.y)
				if dia_inicio == -1:
					dia_inicio = calcular_dia(dia)
					if child.has_meta("slot_inicio"):
						posicion_minuto_inicio = int(child.get_meta("slot_inicio")) * 5
					else:
						posicion_minuto_inicio = child.position.y
				if child.get_meta("estado", "") == "pasado":
					verde = false
	return verde


func calcular_dia(dia):
	if dia == bloque_columna.lunes_columna:
		return 0
	if dia == bloque_columna.martes_columna:
		return 1
	if dia == bloque_columna.miercoles_columna:
		return 2
	if dia == bloque_columna.jueves_columna:
		return 3
	if dia == bloque_columna.viernes_columna:
		return 4
	if dia == bloque_columna.sabado_columna:
		return 5
	if dia == bloque_columna.domingo_columna:
		return 6
	return 0
