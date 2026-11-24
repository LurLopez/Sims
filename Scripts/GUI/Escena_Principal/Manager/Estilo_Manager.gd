class_name Estilo_Manager
extends RefCounted

# Helpers visuales compartidos para la interfaz «humana» y de alta visibilidad
# de «El Mánager» (retratos reales con Personaje_Visual, botones con contraste
# legible al deshabilitarse, selectores por píldoras, barras comparativas y SFX).

const COLOR_MANAGER := Color("#0f766e")
const COLOR_MANAGER_OSCURO := Color("#115e59")
const COLOR_MANAGER_SUAVE := Color("#ccfbf1")
const COLOR_ORO := Color("#d97706")
const COLOR_ORO_SUAVE := Color("#fef3c7")

const RUTAS_SFX: Dictionary = {
	"click": "res://Sonidos/SFX/click.wav",
	"pop": "res://Sonidos/SFX/pop.wav",
	"coin": "res://Sonidos/SFX/coin.wav",
	"ding": "res://Sonidos/SFX/ding.wav",
	"happy": "res://Sonidos/SFX/happy.wav",
	"angry": "res://Sonidos/SFX/angry.wav",
	"start": "res://Sonidos/SFX/start.wav",
	"level_end": "res://Sonidos/SFX/level_end.wav",
	"star": "res://Sonidos/SFX/star.wav"
}


static func reproducir_sfx(nombre: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var ruta: String = str(RUTAS_SFX.get(nombre, ""))
	if ruta == "" or not ResourceLoader.exists(ruta):
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return
	var padre: Node = tree.root.get_node_or_null("Sistema_Manager")
	if padre == null:
		padre = tree.root
	var player := padre.get_node_or_null("_SFX_Manager_Player") as AudioStreamPlayer
	if player == null:
		player = AudioStreamPlayer.new()
		player.name = "_SFX_Manager_Player"
		player.bus = "SFX"
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		padre.add_child(player)
	var stream := ResourceLoader.load(ruta) as AudioStream
	if stream != null:
		player.stream = stream
		player.play()


static func color_para_fondo(color_hex_o_color) -> Color:
	var c: Color = color_hex_o_color if color_hex_o_color is Color else Color(str(color_hex_o_color))
	return Color.WHITE if c.get_luminance() < 0.45 else Estilos_UI.TINTA


static func crear_retrato_jugador(jugador: Dictionary, colores_club: Array,
		patron_club: int = 1, tam: int = 54, animar: bool = false,
		modo: String = "retrato", mostrar_dorsal: bool = false) -> Control:
	var col_pri: Color = Color(str(colores_club[0])) if colores_club.size() >= 1 else COLOR_MANAGER
	var rol_p: String = Simulador_Manager._Rol_Principal(jugador)
	var color_rol: Color = Datos_Manager.Color_De_Rol(rol_p)
	var fondo_suave: Color = col_pri.lerp(Color.WHITE, 0.78)

	var cont := Control.new()
	cont.custom_minimum_size = Vector2(tam, tam)
	cont.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cont.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cont.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var marco := PanelContainer.new()
	marco.set_anchors_preset(Control.PRESET_FULL_RECT)
	marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var radio: int = 999 if modo == "retrato" else 16
	var st := Estilos_UI.caja(fondo_suave, radio, color_rol, 2, 1)
	st.content_margin_left = 2
	st.content_margin_right = 2
	st.content_margin_top = 2
	st.content_margin_bottom = 2
	marco.add_theme_stylebox_override("panel", st)
	cont.add_child(marco)

	var clip := Panel.new()
	clip.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var st_clip := StyleBoxFlat.new()
	st_clip.bg_color = fondo_suave
	st_clip.set_corner_radius_all(radio)
	st_clip.anti_aliasing = true
	clip.add_theme_stylebox_override("panel", st_clip)
	marco.add_child(clip)

	var ap: Dictionary = Simulador_Manager.Apariencia_De_Jugador(
		jugador, colores_club, patron_club)
	var pj := Personaje_Visual.new(ap, modo)
	pj.set_anchors_preset(Control.PRESET_FULL_RECT)
	pj.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pj.edad = clampi(int(jugador.get("edad", 22)), Datos_Manager.EDAD_MINIMA,
		Datos_Manager.EDAD_MAXIMA)
	pj.animar_idle = animar
	pj.dibujar_fondo_sunburst = true
	pj.color_fondo_base = fondo_suave
	pj.color_fondo_rayo = col_pri.lerp(Color.WHITE, 0.62)
	pj.pose = "futbol" if modo != "retrato" else "idle"
	var energia: float = float(jugador.get("energia", 100.0))
	if energia < 40.0:
		pj.expresion = "cansado"
	elif int(jugador.get("goles", 0)) >= 2:
		pj.expresion = "feliz"
	else:
		pj.expresion = "sonrisa" if modo == "retrato" else "concentrado"
	pj.margen_retrato = 4.0
	clip.add_child(pj)

	if mostrar_dorsal:
		var badge := PanelContainer.new()
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var st_b := Estilos_UI.caja(col_pri, 999, Color.WHITE, 1, 0)
		st_b.content_margin_left = 4
		st_b.content_margin_right = 4
		st_b.content_margin_top = 1
		st_b.content_margin_bottom = 1
		badge.add_theme_stylebox_override("panel", st_b)
		badge.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		badge.offset_left = -22
		badge.offset_top = -18
		badge.offset_right = 2
		badge.offset_bottom = 2
		var lbl_d := Estilos_UI.texto("#%d" % int(jugador.get("dorsal", 1)), 9,
			color_para_fondo(col_pri), 700)
		lbl_d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.add_child(lbl_d)
		cont.add_child(badge)

	return cont


static func crear_retrato_manager(tam: int = 64, colores_club: Array = [],
		expresion: String = "feliz", animar: bool = true,
		modo: String = "retrato") -> Control:
	var ap: Dictionary = _apariencia_sim_manager(colores_club)
	var col_pri: Color = Color(str(colores_club[0])) if colores_club.size() >= 1 else COLOR_MANAGER
	var fondo_suave: Color = Color("#e0f2fe")

	var cont := Control.new()
	cont.custom_minimum_size = Vector2(tam, tam)
	cont.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cont.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cont.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var marco := PanelContainer.new()
	marco.set_anchors_preset(Control.PRESET_FULL_RECT)
	marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var radio: int = 999 if modo == "retrato" else 16
	var st := Estilos_UI.caja(fondo_suave, radio, col_pri, 2, 2)
	st.content_margin_left = 2
	st.content_margin_right = 2
	st.content_margin_top = 2
	st.content_margin_bottom = 2
	marco.add_theme_stylebox_override("panel", st)
	cont.add_child(marco)

	var clip := Panel.new()
	clip.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var st_clip := StyleBoxFlat.new()
	st_clip.bg_color = fondo_suave
	st_clip.set_corner_radius_all(radio)
	st_clip.anti_aliasing = true
	clip.add_theme_stylebox_override("panel", st_clip)
	marco.add_child(clip)

	var pj := Personaje_Visual.new(ap, modo)
	pj.set_anchors_preset(Control.PRESET_FULL_RECT)
	pj.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pj.edad = -1
	pj.animar_idle = animar
	pj.dibujar_fondo_sunburst = true
	pj.color_fondo_base = fondo_suave
	pj.color_fondo_rayo = col_pri.lerp(Color.WHITE, 0.68)
	pj.expresion = expresion
	pj.margen_retrato = 5.0
	clip.add_child(pj)

	return cont


static func _apariencia_sim_manager(colores_club: Array = []) -> Dictionary:
	var base: Dictionary = Apariencia_Personaje.por_defecto()
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		var ve := tree.root.get_node_or_null("Variables_Estaticas")
		if ve != null and "Apariencia" in ve:
			var ap = ve.get("Apariencia")
			if ap is Dictionary and not ap.is_empty():
				base = Apariencia_Personaje.normalizar(ap)
	var col_corbata: String = str(colores_club[0]) if colores_club.size() >= 1 else "#0f766e"
	base["estilo_ropa"] = "traje"
	base["ropa_superior"] = "camisa"
	base["ropa_inferior"] = "chino"
	base["calzado"] = "zapatos"
	base["color_ropa"] = "#f8fafc"
	base["color_ropa_secundario"] = "#1e293b"
	base["color_ropa_detalle"] = col_corbata
	base["color_pantalon"] = "#1e293b"
	base["detalle_ropa"] = "corbata"
	return base


static func boton(contenido: String, variante: String = "secundario",
		icono_nombre: String = "", color: Color = COLOR_MANAGER, alto: int = 48) -> Button:
	var btn := Estilos_UI.boton(contenido, variante, icono_nombre, color, alto)
	# Contraste legible también cuando el botón está deshabilitado.
	var st_dis := Estilos_UI.caja(Color("#e2e8f0"), Estilos_UI.RADIO_BOTON,
		Color("#cbd5e1"), 1, 0)
	st_dis.content_margin_left = 14
	st_dis.content_margin_right = 14
	st_dis.content_margin_top = 8
	st_dis.content_margin_bottom = 8
	btn.add_theme_stylebox_override("disabled", st_dis)
	btn.add_theme_color_override("font_disabled_color", Color("#64748b"))
	btn.add_theme_color_override("icon_disabled_color", Color("#64748b"))
	return btn


static func selector_chips(opciones: Array, valor_actual: String,
		color_activo: Color, al_elegir: Callable, envolver: bool = false,
		tam_fuente: int = 12) -> Control:
	# opciones: Array de [id: String, etiqueta: String]
	var cont: Container
	if envolver:
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 6)
		flow.add_theme_constant_override("v_separation", 6)
		cont = flow
	else:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 6)
		cont = h
	cont.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	for opt in opciones:
		var id_opt: String = str(opt[0])
		var texto_opt: String = str(opt[1])
		var activa: bool = id_opt == valor_actual
		var btn := boton(texto_opt, "primario" if activa else "chip", "",
			color_activo if activa else Estilos_UI.TINTA_SUAVE, 44)
		if not envolver:
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", tam_fuente)
		var id_local: String = id_opt
		btn.pressed.connect(func():
			reproducir_sfx("click")
			al_elegir.call(id_local))
		cont.add_child(btn)
	return cont


static func toggle_pill(texto: String, activo: bool, color: Color, al_cambiar: Callable) -> Button:
	var btn := boton(texto, "primario" if activo else "chip",
		"circle-check" if activo else "circle-x",
		color if activo else Estilos_UI.TINTA_SUAVE, 44)
	btn.add_theme_font_size_override("font_size", 12)
	btn.pressed.connect(func():
		reproducir_sfx("click")
		al_cambiar.call(not activo))
	return btn


static func barra_atributo(nombre: String, valor: int, destacado: bool = false) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var nombre_lbl := Estilos_UI.texto(("★ " if destacado else "") + nombre, 12,
		COLOR_ORO if destacado else Estilos_UI.TINTA, 700 if destacado else 600)
	nombre_lbl.custom_minimum_size = Vector2(126, 0)
	h.add_child(nombre_lbl)

	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 10)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.show_percentage = false
	bar.max_value = 99
	bar.value = clampi(valor, 1, 99)
	var color_bar: Color = Estilos_UI.EXITO if valor >= 70 else (
		COLOR_MANAGER if valor >= 50 else (Estilos_UI.AVISO if valor >= 35 else Estilos_UI.PELIGRO))
	bar.add_theme_stylebox_override("background", Estilos_UI.barra_fondo())
	bar.add_theme_stylebox_override("fill", Estilos_UI.barra_relleno(color_bar))
	h.add_child(bar)

	var val_lbl := Estilos_UI.texto(str(valor), 13, color_bar, 700)
	val_lbl.custom_minimum_size = Vector2(28, 0)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(val_lbl)
	return h


static func barra_comparativa(etiqueta: String, val_l: float, val_v: float,
		txt_l: String, txt_v: String, col_l: Color, col_v: Color,
		oscuro: bool = false) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)

	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 6)
	v.add_child(cab)

	var col_txt: Color = Color.WHITE if oscuro else Estilos_UI.TINTA
	var col_lbl: Color = Color(1, 1, 1, 0.72) if oscuro else Estilos_UI.TINTA_SUAVE

	var l_lbl := Estilos_UI.texto(txt_l, 12, col_txt, 700)
	l_lbl.custom_minimum_size = Vector2(56, 0)
	cab.add_child(l_lbl)

	var tit := Estilos_UI.texto(etiqueta, 11, col_lbl, 600)
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(tit)

	var v_lbl := Estilos_UI.texto(txt_v, 12, col_txt, 700)
	v_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v_lbl.custom_minimum_size = Vector2(56, 0)
	cab.add_child(v_lbl)

	var suma: float = maxf(0.01, val_l + val_v)
	var ratio_l: float = clampf(val_l / suma, 0.08, 0.92) if (val_l > 0.0 or val_v > 0.0) else 0.5
	var barra := Control.new()
	barra.custom_minimum_size = Vector2(0, 7)
	barra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	barra.draw.connect(func():
		var w: float = barra.size.x
		var h: float = barra.size.y
		if w <= 2.0:
			return
		var bg: Color = Color(1, 1, 1, 0.14) if oscuro else Estilos_UI.GRIS_BARRA
		barra.draw_rect(Rect2(0, 0, w, h), bg)
		var w_l: float = maxf(3.0, w * ratio_l - 1.5)
		var w_v: float = maxf(3.0, w * (1.0 - ratio_l) - 1.5)
		barra.draw_rect(Rect2(0, 0, w_l, h), col_l)
		barra.draw_rect(Rect2(w - w_v, 0, w_v, h), col_v))
	v.add_child(barra)
	return v
