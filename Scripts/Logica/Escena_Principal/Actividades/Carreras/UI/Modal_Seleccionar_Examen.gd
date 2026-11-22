extends "res://Scripts/Logica/Escena_Principal/Actividades/Carreras/UI/Modal_Carrera_Base.gd"

# Programación del examen.
#
# En lugar de dos filas con flechas, el jugador toca directamente el día y la
# hora. El resumen inferior deja claro si la matrícula se cobra al confirmar
# o si queda como prematrícula gratuita hasta el lunes.

signal examen_programado(dia: int, hora: int)

const DIAS_EXAMEN = [2, 3, 4]
const NOMBRES_DIAS_EXAMEN = ["Miércoles", "Jueves", "Viernes"]
const HORA_MIN = 8
const HORA_MAX = 18

var indice_dia: int = 2
var hora_seleccionada: int = 15
var _dias_opciones: Array = DIAS_EXAMEN
var _nombres_opciones: Array = NOMBRES_DIAS_EXAMEN
var _horas_disponibles: Array = []

var carrera: Carrera = null
var _directa := false
var _color_acento := Estilos_UI.PRIMARIO

var _fila_dias: HBoxContainer
var _contenedor_horas: VBoxContainer
var _lbl_resumen_titulo: Label
var _lbl_resumen_detalle: Label
var _icono_resumen: TextureRect
var _panel_resumen: PanelContainer
var _btn_confirmar: Button
var _btn_cancelar: Button


func _Al_Listo() -> void:
	permitir_cerrar_al_fondo = true
	_Preparar_Opciones()
	if carrera != null:
		_Aplicar_Cabecera_Carrera()
	else:
		actualizar_cabecera("Programar examen", "Elige el día y la hora de tu prueba",
			"MATRÍCULA · HORARIO", "calendar-days")
	_Construir_Pie()
	_Construir_Contenido()
	_Actualizar_Resumen()


func Configurar(_carrera: Carrera = null, directa: bool = false) -> void:
	carrera = _carrera
	_directa = directa
	_Aplicar_Cabecera_Carrera()
	if is_node_ready():
		_Construir_Contenido()
		_Actualizar_Resumen()


func _Aplicar_Cabecera_Carrera() -> void:
	if carrera == null:
		return
	_color_acento = color_carrera(carrera.nombre).darkened(0.06)
	var nombre := nombre_carrera(carrera.nombre)
	actualizar_cabecera(
		"Programar examen",
		"%s · Año %d de %d" % [nombre, carrera.año_actual, carrera.años_totales],
		"MATRÍCULA · HORARIO",
		"calendar-days",
		_color_acento.darkened(0.10))


func _Preparar_Opciones() -> void:
	if Variables_Estaticas.Modo_Rapido:
		var hoy: int = int(Variables_Dinamicas.Minute_Day)
		var hora_actual: int = int(Variables_Dinamicas.Minute_Minute / 60)
		if hora_actual < HORA_MAX - 1:
			_dias_opciones = [hoy, hoy + 1]
			_nombres_opciones = ["Hoy", "Mañana"]
			indice_dia = 0
			hora_seleccionada = maxi(HORA_MIN, hora_actual + 1)
		else:
			_dias_opciones = [hoy + 1]
			_nombres_opciones = ["Mañana"]
			indice_dia = 0
			hora_seleccionada = 15
	else:
		_dias_opciones = DIAS_EXAMEN
		_nombres_opciones = NOMBRES_DIAS_EXAMEN
		indice_dia = 2
		hora_seleccionada = 15


func _Construir_Pie() -> void:
	if not pie.get_children().is_empty():
		return
	_btn_cancelar = Estilos_UI.boton("Cancelar", "secundario", "x", Estilos_UI.TINTA, 50)
	_btn_cancelar.custom_minimum_size = Vector2(118, 50)
	_btn_cancelar.pressed.connect(cerrar)
	pie.add_child(_btn_cancelar)
	_btn_confirmar = Estilos_UI.boton("Confirmar horario", "primario", "check",
		_color_acento, 50)
	_btn_confirmar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_confirmar.pressed.connect(_on_confirmar_pressed)
	pie.add_child(_btn_confirmar)


func _Construir_Contenido() -> void:
	for hijo in contenido.get_children():
		contenido.remove_child(hijo)
		hijo.queue_free()

	contenido.add_child(_Etiqueta_Seccion("Día del examen", "calendar-days"))

	_fila_dias = HBoxContainer.new()
	_fila_dias.add_theme_constant_override("separation", 8)
	contenido.add_child(_fila_dias)
	for i in range(_nombres_opciones.size()):
		var btn := _Crear_Boton_Dia(i)
		_fila_dias.add_child(btn)
	_Pintar_Dias()

	contenido.add_child(_Etiqueta_Seccion("Hora de inicio", "clock", "Dura 1 hora"))

	_contenedor_horas = VBoxContainer.new()
	_contenedor_horas.add_theme_constant_override("separation", 8)
	contenido.add_child(_contenedor_horas)
	_Construir_Horas()

	_panel_resumen = _Crear_Panel_Resumen()
	contenido.add_child(_panel_resumen)

	contenido.add_child(_Crear_Nota_Inferior())


func _Etiqueta_Seccion(titulo: String, icono: String, extra: String = "") -> Control:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 7)
	fila.add_child(Estilos_UI.icono_rect(icono, 15, _color_acento.darkened(0.12)))
	fila.add_child(Estilos_UI.texto(titulo.to_upper(), 11, Estilos_UI.TINTA_FANTASMA, 700))
	if extra != "":
		var punto := Estilos_UI.texto("·", 11, Estilos_UI.TINTA_FANTASMA, 700)
		fila.add_child(punto)
		fila.add_child(Estilos_UI.texto(extra, 11, Estilos_UI.TINTA_FANTASMA, 500))
	return fila


func _Crear_Boton_Dia(indice: int) -> Button:
	var btn := Button.new()
	btn.text = _nombres_opciones[indice]
	btn.custom_minimum_size = Vector2(0, 66)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.set_meta("_estilo_propio", true)
	btn.set_meta("indice_dia", indice)
	btn.pressed.connect(_on_dia_pressed.bind(indice))
	Estilos_UI.animar_presion(btn)
	return btn


func _Pintar_Dias() -> void:
	if _fila_dias == null:
		return
	for btn in _fila_dias.get_children():
		if btn is Button:
			_Pintar_Opcion(btn, int(btn.get_meta("indice_dia", -1)) == indice_dia, 15)


func _Pintar_Opcion(btn: Button, activo: bool, tam_fuente: int) -> void:
	btn.add_theme_font_override("font", Estilos_UI.fuente_ui(700 if activo else 600))
	btn.add_theme_font_size_override("font_size", tam_fuente)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if activo:
		var normal := Estilos_UI.caja(_color_acento, 12, _color_acento.darkened(0.22), 1, 1)
		var hover := Estilos_UI.caja(_color_acento.lightened(0.06), 12, _color_acento.darkened(0.22), 1, 1)
		var pressed := Estilos_UI.caja(_color_acento.darkened(0.10), 12, _color_acento.darkened(0.28), 1, 0)
		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", pressed)
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_color_override("font_hover_color", Color.WHITE)
		btn.add_theme_color_override("font_pressed_color", Color.WHITE)
		btn.add_theme_color_override("font_focus_color", Color.WHITE)
	else:
		var normal := Estilos_UI.caja(Estilos_UI.SUPERFICIE, 12, Estilos_UI.BORDE, 1, 0)
		var hover := Estilos_UI.caja(Estilos_UI.SUPERFICIE_2, 12, Estilos_UI.BORDE_FUERTE, 1, 0)
		var pressed := Estilos_UI.caja(Color(_color_acento, 0.10), 12, _color_acento, 1, 0)
		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", pressed)
		btn.add_theme_color_override("font_color", Estilos_UI.TINTA)
		btn.add_theme_color_override("font_hover_color", Estilos_UI.TINTA)
		btn.add_theme_color_override("font_pressed_color", _color_acento.darkened(0.18))
		btn.add_theme_color_override("font_focus_color", Estilos_UI.TINTA)


func _on_dia_pressed(indice: int) -> void:
	if indice == indice_dia:
		return
	indice_dia = indice
	_Pintar_Dias()
	_Construir_Horas()
	_Actualizar_Resumen()


func _Horas_Para_Dia(indice: int) -> Array:
	var horas: Array = []
	var inicio := HORA_MIN
	if Variables_Estaticas.Modo_Rapido:
		var hoy: int = int(Variables_Dinamicas.Minute_Day)
		if int(_dias_opciones[indice]) == hoy:
			var hora_actual: int = int(Variables_Dinamicas.Minute_Minute / 60)
			inicio = maxi(HORA_MIN, hora_actual + 1)
	for h in range(inicio, HORA_MAX):
		horas.append(h)
	return horas


func _Construir_Horas() -> void:
	if _contenedor_horas == null:
		return
	for hijo in _contenedor_horas.get_children():
		_contenedor_horas.remove_child(hijo)
		hijo.queue_free()

	_horas_disponibles = _Horas_Para_Dia(indice_dia)
	if not _horas_disponibles.has(hora_seleccionada):
		hora_seleccionada = int(_horas_disponibles[0]) if not _horas_disponibles.is_empty() else HORA_MIN

	if _horas_disponibles.is_empty():
		var vacio := Estilos_UI.parrafo(
			"No quedan horas para hoy. Elige otro día.", 13, Estilos_UI.TINTA_SUAVE)
		_contenedor_horas.add_child(vacio)
		return

	var fila: HBoxContainer = null
	for i in range(_horas_disponibles.size()):
		if i % 5 == 0:
			fila = HBoxContainer.new()
			fila.add_theme_constant_override("separation", 8)
			_contenedor_horas.add_child(fila)
		var hora: int = int(_horas_disponibles[i])
		var btn := Button.new()
		btn.text = "%02d:00" % hora
		btn.custom_minimum_size = Vector2(0, 46)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.set_meta("_estilo_propio", true)
		btn.set_meta("hora", hora)
		btn.pressed.connect(_on_hora_pressed.bind(hora))
		_Pintar_Opcion(btn, hora == hora_seleccionada, 14)
		Estilos_UI.animar_presion(btn)
		fila.add_child(btn)
	if fila != null:
		var restantes := 5 - (fila.get_child_count() % 5)
		if restantes < 5:
			for _i in range(restantes):
				var relleno := Control.new()
				relleno.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				relleno.mouse_filter = Control.MOUSE_FILTER_IGNORE
				fila.add_child(relleno)


func _on_hora_pressed(hora: int) -> void:
	if hora == hora_seleccionada:
		return
	hora_seleccionada = hora
	_Pintar_Horas()
	_Actualizar_Resumen()


func _Pintar_Horas() -> void:
	if _contenedor_horas == null:
		return
	for fila in _contenedor_horas.get_children():
		for btn in fila.get_children():
			if btn is Button:
				_Pintar_Opcion(btn, int(btn.get_meta("hora", -1)) == hora_seleccionada, 14)


func _Crear_Panel_Resumen() -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Color(_color_acento, 0.08), 14, Color(_color_acento, 0.20), 1, 0))
	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 14)
	margen.add_theme_constant_override("margin_right", 14)
	margen.add_theme_constant_override("margin_top", 12)
	margen.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margen)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 11)
	margen.add_child(fila)

	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(38, 38)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Color(_color_acento, 0.14), 11, Color(1, 1, 1, 0), 0, 0))
	fila.add_child(badge)
	_icono_resumen = Estilos_UI.icono_rect("calendar-check-2", 20, _color_acento.darkened(0.12))
	_icono_resumen.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_icono_resumen.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.add_child(_icono_resumen)

	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.alignment = BoxContainer.ALIGNMENT_CENTER
	textos.add_theme_constant_override("separation", 2)
	fila.add_child(textos)

	_lbl_resumen_titulo = Estilos_UI.texto("", 16, Estilos_UI.TINTA, 700)
	textos.add_child(_lbl_resumen_titulo)
	_lbl_resumen_detalle = Estilos_UI.parrafo("", 12, Estilos_UI.TINTA_SUAVE)
	textos.add_child(_lbl_resumen_detalle)
	return card


func _Es_Directa_Actual() -> bool:
	if Variables_Estaticas.Modo_Rapido:
		return int(_dias_opciones[indice_dia]) == int(Variables_Dinamicas.Minute_Day)
	return _directa


func _Hora_Actual_Seleccionada() -> int:
	return hora_seleccionada


func _Costo_Matricula() -> int:
	if carrera == null:
		return 0
	return int(Variables_Estaticas.Obtener_Costo_Matricula(carrera))


func _Actualizar_Resumen() -> void:
	if _lbl_resumen_titulo == null:
		return
	var dia: String = str(_nombres_opciones[indice_dia])
	var hora := _Hora_Actual_Seleccionada()
	_lbl_resumen_titulo.text = "%s · %02d:00 – %02d:00" % [dia, hora, hora + 1]

	var costo := _Costo_Matricula()
	var directa := _Es_Directa_Actual()
	var saldo_insuficiente := false
	if directa:
		var falta := costo - int(Variables_Dinamicas.Dinero)
		saldo_insuficiente = falta > 0
		if saldo_insuficiente:
			_lbl_resumen_detalle.text = "Saldo insuficiente: te faltan %d € para matricularte." % falta
			_lbl_resumen_detalle.add_theme_color_override("font_color", Estilos_UI.PELIGRO)
		else:
			_lbl_resumen_detalle.text = "Matrícula directa · pagas %d € ahora" % costo
			_lbl_resumen_detalle.add_theme_color_override("font_color", Estilos_UI.TINTA_SUAVE)
	else:
		var cuando := "mañana a las 00:00" if Variables_Estaticas.Modo_Rapido else "el lunes"
		_lbl_resumen_detalle.text = "Prematrícula gratuita · se cobrarán %d € %s" % [costo, cuando]
		_lbl_resumen_detalle.add_theme_color_override("font_color", Estilos_UI.TINTA_SUAVE)

	if _btn_confirmar != null:
		_btn_confirmar.disabled = saldo_insuficiente or _horas_disponibles.is_empty()
		if saldo_insuficiente:
			_btn_confirmar.text = "Saldo insuficiente"
		elif _horas_disponibles.is_empty():
			_btn_confirmar.text = "Sin horas disponibles"
		elif directa:
			_btn_confirmar.text = "Matricularse · %d €" % costo
		else:
			_btn_confirmar.text = "Guardar prematrícula"
		_btn_confirmar.icon = Estilos_UI.icono("check")
		Estilos_UI.aplicar_estilo_boton(_btn_confirmar, "primario", _color_acento, "check")
		_btn_confirmar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_btn_confirmar.custom_minimum_size = Vector2(0, 50)


func _Crear_Nota_Inferior() -> Control:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	fila.add_child(Estilos_UI.icono_rect("info", 15, Estilos_UI.TINTA_FANTASMA))
	var textos := "Puedes programar el examen para hoy o mañana. Si eliges hoy, la matrícula se cobra al confirmar." if Variables_Estaticas.Modo_Rapido else "Elige el día y la hora. Durante la hora del examen podrás hacer el test para sumar hasta 10 puntos a tu nota final."
	var lbl := Estilos_UI.parrafo(textos, 11, Estilos_UI.TINTA_FANTASMA)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(lbl)
	return fila


func _on_confirmar_pressed() -> void:
	if _horas_disponibles.is_empty():
		return
	examen_programado.emit(int(_dias_opciones[indice_dia]), hora_seleccionada * 60)
	cerrar()
