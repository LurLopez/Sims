extends Node

class_name MiniCalendarioPreview

const HDR_H: int = 32
const ROW_H: int = 23
const HORA_W: int = 56
const DIA_W: int = 90
const SCROLL_H: int = 550

const COLOR_PASADO      := Color("#e2e8f0")
const COLOR_LIBRE       := Color("#dcfce7")
const COLOR_OCUPADO     := Color("#dbeafe")
const COLOR_BLINK_ON    := Color("#2563eb")
const COLOR_BLINK_OFF   := Color("#93c5fd")
const COLOR_HEADER_BG   := Color("#182234")
const COLOR_HORA_COL_BG := Color("#f1f5f9")
const COLOR_GRID_BG     := Color("#ffffff")
const COLOR_COL_SEP     := Color("#cbd5e1")
const COLOR_ROW_SEP     := Color("#e2e8f0")

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

var _semana: int = 0
var _contenedor: Panel = null
var _scroll: ScrollContainer = null
var _celdas: Array = []
var _acentos: Array = []
var _colores_base: Array = []
var _colores_acento: Array = []
var _blink_celdas: Array = []


func _color_actividad(nombre: String) -> Color:
	if PALETA_ACTIVIDADES.has(nombre):
		return PALETA_ACTIVIDADES[nombre]
	var act_cat = Variables_Estaticas.Catalogo_Actividades.get(nombre, null)
	if act_cat != null and act_cat is Actividad:
		return act_cat.color
	return Color("#2563eb")


func crear(raiz: Node, semana: int) -> void:
	_semana = semana
	_celdas = []
	_acentos = []
	_colores_base = []
	_colores_acento = []
	_blink_celdas = []

	_contenedor = Panel.new()
	_contenedor.name = "MiniCalendario"
	_contenedor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_contenedor.position = Vector2(16, 174)
	_contenedor.size = Vector2(688, HDR_H + SCROLL_H + 2)
	_contenedor.clip_contents = true
	_contenedor.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Estilos_UI.SUPERFICIE, 14, Estilos_UI.BORDE_FUERTE, 1, 2))

	_construir_header()
	_construir_scroll()

	var borde_overlay := Panel.new()
	borde_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	borde_overlay.position = Vector2.ZERO
	borde_overlay.size = _contenedor.size
	borde_overlay.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Color(0, 0, 0, 0), 14, Estilos_UI.BORDE_FUERTE, 1, 0))
	_contenedor.add_child(borde_overlay)

	raiz.get_node("Actividades/Seleccionar_Horario").add_child(_contenedor)
	_actualizar_colores()


func _construir_header() -> void:
	var hdr_bg := Panel.new()
	hdr_bg.position = Vector2(1, 1)
	hdr_bg.size = Vector2(686, HDR_H - 1)
	hdr_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st_hdr := StyleBoxFlat.new()
	st_hdr.bg_color = COLOR_HEADER_BG
	st_hdr.corner_radius_top_left = 13
	st_hdr.corner_radius_top_right = 13
	hdr_bg.add_theme_stylebox_override("panel", st_hdr)
	_contenedor.add_child(hdr_bg)

	var hora_hdr := Label.new()
	hora_hdr.text = "Hora"
	hora_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hora_hdr.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hora_hdr.position = Vector2(1, 0)
	hora_hdr.size = Vector2(HORA_W, HDR_H)
	hora_hdr.add_theme_font_override("font", Estilos_UI.fuente_ui(700))
	hora_hdr.add_theme_font_size_override("font_size", 11)
	hora_hdr.add_theme_color_override("font_color", Color("#94a3b8"))
	hora_hdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_contenedor.add_child(hora_hdr)

	var dias_abrev := ["L", "M", "X", "J", "V", "S", "D"]
	var semana_actual: int = int(Variables_Dinamicas.Minute_Day) / 7
	var hoy: int = int(Variables_Dinamicas.Minute_Day) % 7
	var es_semana_actual: bool = (_semana == semana_actual)

	for d in range(7):
		var sep := ColorRect.new()
		sep.color = Color(1, 1, 1, 0.10)
		sep.position = Vector2(1 + HORA_W + d * DIA_W, 5)
		sep.size = Vector2(1, HDR_H - 10)
		sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_contenedor.add_child(sep)

		var es_hoy: bool = es_semana_actual and (d == hoy)
		if es_hoy:
			var hoy_pill := Panel.new()
			hoy_pill.position = Vector2(1 + HORA_W + d * DIA_W + 14, 4)
			hoy_pill.size = Vector2(DIA_W - 28, HDR_H - 8)
			hoy_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hoy_pill.add_theme_stylebox_override("panel",
				Estilos_UI.caja(Estilos_UI.ROJO_BIT, 7, Color(0, 0, 0, 0), 0, 0))
			_contenedor.add_child(hoy_pill)

		var lbl := Label.new()
		lbl.text = dias_abrev[d]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.position = Vector2(1 + HORA_W + d * DIA_W + 1, 0)
		lbl.size = Vector2(DIA_W - 1, HDR_H)
		lbl.add_theme_font_override("font", Estilos_UI.fuente_ui(700))
		lbl.add_theme_font_size_override("font_size", 12)
		var col_dia := Color.WHITE if es_hoy else (Color("#cbd5e1") if d >= 5 else Color("#f1f5f9"))
		lbl.add_theme_color_override("font_color", col_dia)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_contenedor.add_child(lbl)


func _construir_scroll() -> void:
	_scroll = ScrollContainer.new()
	_scroll.position = Vector2(1, HDR_H)
	_scroll.size = Vector2(686, SCROLL_H)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_contenedor.add_child(_scroll)

	var inner := Control.new()
	inner.name = "InnerGrid"
	inner.custom_minimum_size = Vector2(686, 24 * ROW_H)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scroll.add_child(inner)

	var grid_bg := ColorRect.new()
	grid_bg.color = COLOR_GRID_BG
	grid_bg.position = Vector2.ZERO
	grid_bg.size = Vector2(686, 24 * ROW_H)
	grid_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(grid_bg)

	var hora_col_bg := ColorRect.new()
	hora_col_bg.color = COLOR_HORA_COL_BG
	hora_col_bg.position = Vector2.ZERO
	hora_col_bg.size = Vector2(HORA_W, 24 * ROW_H)
	hora_col_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(hora_col_bg)

	for d in range(7):
		_celdas.append([])
		_acentos.append([])
		_colores_base.append([])
		_colores_acento.append([])
		for h in range(24):
			_celdas[d].append(null)
			_acentos[d].append(null)
			_colores_base[d].append(Color.WHITE)
			_colores_acento[d].append(Color(0, 0, 0, 0))

	for h in range(24):
		var hora_lbl := Label.new()
		hora_lbl.text = "%02d:00" % h
		hora_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hora_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hora_lbl.position = Vector2(0, h * ROW_H)
		hora_lbl.size = Vector2(HORA_W, ROW_H)
		hora_lbl.add_theme_font_override("font", Estilos_UI.fuente_ui(700 if h % 2 == 0 else 500))
		hora_lbl.add_theme_font_size_override("font_size", 10)
		hora_lbl.add_theme_color_override("font_color", Color("#334155") if h % 2 == 0 else Color("#64748b"))
		hora_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(hora_lbl)

		var row_sep := ColorRect.new()
		row_sep.color = COLOR_ROW_SEP
		row_sep.position = Vector2(0, h * ROW_H)
		row_sep.size = Vector2(686, 1)
		row_sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(row_sep)

		for d in range(7):
			var col_sep := ColorRect.new()
			col_sep.color = COLOR_COL_SEP
			col_sep.position = Vector2(HORA_W + d * DIA_W, h * ROW_H)
			col_sep.size = Vector2(1, ROW_H)
			col_sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
			inner.add_child(col_sep)

			var cell := ColorRect.new()
			cell.position = Vector2(HORA_W + d * DIA_W + 1, h * ROW_H + 1)
			cell.size = Vector2(DIA_W - 1, ROW_H - 1)
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			inner.add_child(cell)
			_celdas[d][h] = cell

			var acento := ColorRect.new()
			acento.position = Vector2(HORA_W + d * DIA_W + 1, h * ROW_H + 1)
			acento.size = Vector2(3, ROW_H - 1)
			acento.color = Color(0, 0, 0, 0)
			acento.mouse_filter = Control.MOUSE_FILTER_IGNORE
			inner.add_child(acento)
			_acentos[d][h] = acento


func _actualizar_colores() -> void:
	var matriz = Funciones_Globales.Devolver_Bloque_Matriz_Semana_(_semana)
	var hoy_dia: int = int(Variables_Dinamicas.Minute_Day)
	var hoy_min: int = int(Variables_Dinamicas.Minute_Minute)

	for d in range(7):
		var dia_abs: int = _semana * 7 + d
		for h in range(24):
			var act_hora: String = ""
			var tiene_aleatoria: bool = false
			for s in range(12):
				var c: String = str(matriz[h * 12 + s][d])
				if c != "" and c != "Actividad_Aleatoria":
					act_hora = c
					break
				elif c == "Actividad_Aleatoria":
					tiene_aleatoria = true

			var fin_hora_min: int = (h + 1) * 60
			var es_pasado: bool = (dia_abs < hoy_dia) or (dia_abs == hoy_dia and fin_hora_min <= hoy_min) or (act_hora == "" and tiene_aleatoria)

			var color: Color
			var acento_col := Color(0, 0, 0, 0)
			if es_pasado:
				if act_hora != "":
					var c_pas := _color_actividad(act_hora)
					color = c_pas.lerp(Color("#e2e8f0"), 0.78)
					acento_col = c_pas.lerp(Color("#94a3b8"), 0.55)
				else:
					color = COLOR_PASADO
			elif act_hora == "":
				color = COLOR_LIBRE
			else:
				var c_act := _color_actividad(act_hora)
				color = c_act.lerp(Color.WHITE, 0.70)
				acento_col = c_act

			_colores_base[d][h] = color
			_colores_acento[d][h] = acento_col
			if _celdas[d][h] != null:
				_celdas[d][h].color = color
			if _acentos[d][h] != null:
				_acentos[d][h].color = acento_col


func actualizar_rango(dia_ini: int, hora_ini: int, min_ini: int, dia_fin: int, hora_fin: int, min_fin: int) -> void:
	_blink_celdas = []
	_actualizar_colores()

	var abs_ini: int = dia_ini * 1440 + hora_ini * 60 + min_ini
	var abs_fin: int = dia_fin * 1440 + hora_fin * 60 + min_fin
	if abs_fin <= abs_ini and dia_fin == dia_ini:
		abs_fin += 1440

	for d in range(7):
		for h in range(24):
			var celda_ini: int = d * 1440 + h * 60
			var celda_fin: int = celda_ini + 60
			if celda_ini < abs_fin and celda_fin > abs_ini:
				_blink_celdas.append([d, h])

	if _scroll != null:
		var target_scroll = max(0, hora_ini * ROW_H - int(SCROLL_H / 2) + ROW_H)
		_scroll.set_deferred("scroll_vertical", target_scroll)


func aplicar_blink(estado: bool) -> void:
	var color_blink := COLOR_BLINK_ON if estado else COLOR_BLINK_OFF
	var acento_blink := Color("#1e40af") if estado else Color("#2563eb")
	for par in _blink_celdas:
		var d: int = par[0]
		var h: int = par[1]
		if _celdas[d][h] != null:
			_celdas[d][h].color = color_blink
		if _acentos[d][h] != null:
			_acentos[d][h].color = acento_blink


func limpiar() -> void:
	if _contenedor != null and is_instance_valid(_contenedor):
		_contenedor.queue_free()
	_contenedor = null
	_scroll = null
	_celdas = []
	_acentos = []
	_colores_base = []
	_colores_acento = []
	_blink_celdas = []
