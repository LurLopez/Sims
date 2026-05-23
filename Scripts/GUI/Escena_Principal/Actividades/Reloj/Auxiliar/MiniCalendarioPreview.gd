extends Node

class_name MiniCalendarioPreview

const HDR_H: int = 26
const ROW_H: int = 25
const HORA_W: int = 44
const DIA_W: int = 96
const SCROLL_H: int = 600      # exact fit: 24 rows * 25 px = 600 (no scroll needed)

const COLOR_PASADO      = Color(0.22, 0.45, 0.75, 1)
const COLOR_LIBRE       = Color(0.08, 0.65, 0.42, 1)
const COLOR_OCUPADO     = Color(0.75, 0.18, 0.20, 1)
const COLOR_BLINK_ON    = Color(0.22, 0.90, 0.58, 1)   # verde claro brillante
const COLOR_BLINK_OFF   = Color(0.02, 0.26, 0.14, 1)   # verde oscuro
const COLOR_HEADER_BG   = Color(0.40, 0.47, 0.55, 1)
const COLOR_HORA_COL_BG = Color(0.35, 0.41, 0.48, 0.90)
const COLOR_GRID_BG     = Color(0.09, 0.13, 0.17, 1)
const COLOR_COL_SEP     = Color(0.42, 0.48, 0.56, 1)
const COLOR_ROW_SEP     = Color(0.42, 0.48, 0.56, 1)

var _semana: int = 0
var _contenedor = null
var _scroll = null
var _celdas: Array = []
var _colores_base: Array = []
var _blink_celdas: Array = []

func crear(raiz: Node, semana: int) -> void:
	_semana = semana
	_celdas = []
	_colores_base = []
	_blink_celdas = []

	_contenedor = Control.new()
	_contenedor.name = "MiniCalendario"
	_contenedor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_contenedor.position = Vector2(0, 52)
	_contenedor.size = Vector2(720, HDR_H + SCROLL_H)

	_construir_header()
	_construir_scroll()

	raiz.get_node("Actividades/Seleccionar_Horario").add_child(_contenedor)
	_actualizar_colores()

func _construir_header() -> void:
	var hdr_bg = ColorRect.new()
	hdr_bg.color = COLOR_HEADER_BG
	hdr_bg.position = Vector2(0, 0)
	hdr_bg.size = Vector2(720, HDR_H)
	hdr_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_contenedor.add_child(hdr_bg)

	var hora_hdr = Label.new()
	hora_hdr.text = "Hora"
	hora_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hora_hdr.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hora_hdr.position = Vector2(0, 0)
	hora_hdr.size = Vector2(HORA_W, HDR_H)
	hora_hdr.add_theme_font_size_override("font_size", 13)
	hora_hdr.add_theme_color_override("font_color", Color.WHITE)
	hora_hdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_contenedor.add_child(hora_hdr)

	var dias_abrev = ["L", "M", "X", "J", "V", "S", "D"]
	for d in range(7):
		var sep = ColorRect.new()
		sep.color = COLOR_COL_SEP
		sep.position = Vector2(HORA_W + d * DIA_W, 0)
		sep.size = Vector2(1, HDR_H)
		sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_contenedor.add_child(sep)

		var lbl = Label.new()
		lbl.text = dias_abrev[d]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.position = Vector2(HORA_W + d * DIA_W + 1, 0)
		lbl.size = Vector2(DIA_W - 1, HDR_H)
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_contenedor.add_child(lbl)

func _construir_scroll() -> void:
	_scroll = ScrollContainer.new()
	_scroll.position = Vector2(0, HDR_H)
	_scroll.size = Vector2(720, SCROLL_H)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_contenedor.add_child(_scroll)

	var inner = Control.new()
	inner.name = "InnerGrid"
	inner.custom_minimum_size = Vector2(720, 24 * ROW_H)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scroll.add_child(inner)

	var grid_bg = ColorRect.new()
	grid_bg.color = COLOR_GRID_BG
	grid_bg.position = Vector2(0, 0)
	grid_bg.size = Vector2(720, 24 * ROW_H)
	grid_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(grid_bg)

	var hora_col_bg = ColorRect.new()
	hora_col_bg.color = COLOR_HORA_COL_BG
	hora_col_bg.position = Vector2(0, 0)
	hora_col_bg.size = Vector2(HORA_W, 24 * ROW_H)
	hora_col_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(hora_col_bg)

	for d in range(7):
		_celdas.append([])
		_colores_base.append([])
		for h in range(24):
			_celdas[d].append(null)
			_colores_base[d].append(Color.WHITE)

	for h in range(24):
		var hora_lbl = Label.new()
		hora_lbl.text = "%02d:00" % h
		hora_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hora_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hora_lbl.position = Vector2(0, h * ROW_H)
		hora_lbl.size = Vector2(HORA_W, ROW_H)
		hora_lbl.add_theme_font_size_override("font_size", 12)
		hora_lbl.add_theme_color_override("font_color", Color(0.88, 0.92, 0.96, 1))
		hora_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(hora_lbl)

		var row_sep = ColorRect.new()
		row_sep.color = COLOR_ROW_SEP
		row_sep.position = Vector2(HORA_W, h * ROW_H)
		row_sep.size = Vector2(720 - HORA_W, 2)
		row_sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(row_sep)

		for d in range(7):
			var col_sep = ColorRect.new()
			col_sep.color = COLOR_COL_SEP
			col_sep.position = Vector2(HORA_W + d * DIA_W, h * ROW_H)
			col_sep.size = Vector2(2, ROW_H)
			col_sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
			inner.add_child(col_sep)

			var cell = ColorRect.new()
			cell.position = Vector2(HORA_W + d * DIA_W + 2, h * ROW_H + 2)
			cell.size = Vector2(DIA_W - 2, ROW_H - 2)
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			inner.add_child(cell)
			_celdas[d][h] = cell

func _actualizar_colores() -> void:
	var matriz = Funciones_Globales.Devolver_Bloque_Matriz_Semana_(_semana)
	var hoy = fecha.new()
	hoy.Inicializar(Variables_Dinamicas.Minute_Day, Variables_Dinamicas.Minute_Minute)

	for d in range(7):
		for h in range(24):
			var contenido = matriz[h * 12][d]
			var mirar_f = fecha.new()
			mirar_f.Inicializar(_semana * 7 + d, (h + 1) * 60)
			var es_pasado = hoy.Comparar_Dos_Fechas(mirar_f)
			var color: Color
			if es_pasado:
				color = COLOR_PASADO
			elif contenido == "" or contenido == "Actividad_Aleatoria":
				color = COLOR_LIBRE
			else:
				color = COLOR_OCUPADO
			_colores_base[d][h] = color
			if _celdas[d][h] != null:
				_celdas[d][h].color = color

func actualizar_rango(dia_ini: int, hora_ini: int, min_ini: int, dia_fin: int, hora_fin: int, min_fin: int) -> void:
	_blink_celdas = []
	_actualizar_colores()

	# Una celda-hora (d, h) parpadea si tiene CUALQUIER solapamiento con [abs_ini, abs_fin).
	#   inicio 21:XX → hora 21 parpadea siempre (contiene el inicio)
	#   final 18:YY → hora 18 parpadea siempre (contiene el final)
	#   inicio 10:05 → hora 10 parpadea (contiene 10:05–11:00)
	var abs_ini: int = dia_ini * 1440 + hora_ini * 60 + min_ini
	var abs_fin: int = dia_fin * 1440 + hora_fin * 60 + min_fin

	for d in range(7):
		for h in range(24):
			var celda_ini: int = d * 1440 + h * 60
			var celda_fin: int = celda_ini + 60
			if celda_ini < abs_fin and celda_fin > abs_ini:
				_blink_celdas.append([d, h])

	# Auto-scroll para mostrar la hora de inicio del rango (deferred para que el layout esté listo)
	if _scroll != null:
		var target_scroll = max(0, hora_ini * ROW_H - int(SCROLL_H / 2) + ROW_H)
		_scroll.set_deferred("scroll_vertical", target_scroll)

func aplicar_blink(estado: bool) -> void:
	var color_blink = COLOR_BLINK_ON if estado else COLOR_BLINK_OFF
	for par in _blink_celdas:
		var d = par[0]
		var h = par[1]
		if _celdas[d][h] != null:
			_celdas[d][h].color = color_blink

func limpiar() -> void:
	if _contenedor != null and is_instance_valid(_contenedor):
		_contenedor.queue_free()
	_contenedor = null
	_scroll = null
	_celdas = []
	_colores_base = []
	_blink_celdas = []
