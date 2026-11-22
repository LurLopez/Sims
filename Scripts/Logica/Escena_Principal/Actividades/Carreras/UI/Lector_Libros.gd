extends "res://Scripts/Logica/Escena_Principal/Actividades/Carreras/UI/Modal_Carrera_Base.gd"

# Lector de apuntes de la pantalla Carrera.
#
# Sustituye el antiguo AcceptDialog con TextEdit por un lector a pantalla
# completa: cabecera con la identidad de la carrera, selector de año fijo,
# temario maquetado por secciones y un pie de cierre siempre accesible.

const APUNTES_PATH_BASE: String = "res://Scripts/Logica/Escena_Principal/Actividades/Carreras/Contenido/apuntes_%s_anio%d.txt"
const CONECTORES := ["a", "al", "con", "de", "del", "el", "en", "la", "las", "los", "o", "para", "por", "u", "y"]

var carrera: Carrera = null
var año_actual_lectura: int = 1

var _chips_anio: HBoxContainer
var _secciones: Array = []
var _titulo_tema := ""
var _eyebrow_tema := ""
var _num_palabras := 0
var _color_acento := Estilos_UI.PRIMARIO
var _color_acento_oscuro := Estilos_UI.PRIMARIO_OSCURO
var _pie_cerrar: Button


func _Al_Listo() -> void:
	permitir_cerrar_al_fondo = true
	actualizar_cabecera("Apuntes", "Repasa el temario de tu carrera",
		"BIBLIOTECA DE CARRERA", "book-open")
	_chips_anio = HBoxContainer.new()
	_chips_anio.name = "Chips_Anio"
	_chips_anio.add_theme_constant_override("separation", 8)
	area_fija.add_child(_chips_anio)
	_contenido_apuntes_estilo_fondo()
	_Construir_Pie()
	if carrera != null:
		_Preparar_Carrera()
		_Construir_Chips()
		_Mostrar_Año(año_actual_lectura)
	else:
		_Mostrar_Vacio("Selecciona una carrera para consultar sus apuntes.")


func _Construir_Pie() -> void:
	if not pie.get_children().is_empty():
		return
	_pie_cerrar = Estilos_UI.boton("Cerrar", "secundario", "x", Estilos_UI.TINTA, 50)
	_pie_cerrar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pie_cerrar.pressed.connect(cerrar)
	pie.add_child(_pie_cerrar)


func Configurar(_carrera: Carrera) -> void:
	carrera = _carrera
	if carrera == null:
		return
	año_actual_lectura = clampi(carrera.año_actual, 1, maxi(carrera.años_totales, 1))
	_Preparar_Carrera()
	if is_node_ready():
		_Construir_Chips()
		_Mostrar_Año(año_actual_lectura)


func _Preparar_Carrera() -> void:
	_color_acento = color_carrera(carrera.nombre)
	_color_acento_oscuro = _color_acento.darkened(0.18)
	var nombre_visible := nombre_carrera(carrera.nombre)
	actualizar_cabecera(
		"Apuntes",
		"%s · Año %d de %d" % [nombre_visible, año_actual_lectura, carrera.años_totales],
		"BIBLIOTECA DE CARRERA",
		"book-open",
		_color_acento.darkened(0.10))
	if is_node_ready():
		_chips_anio.visible = true


func _Construir_Chips() -> void:
	if _chips_anio == null:
		return
	for hijo in _chips_anio.get_children():
		_chips_anio.remove_child(hijo)
		hijo.queue_free()

	var anios: Array = []
	for libro in carrera.libros_desbloqueados:
		var año := str(libro).replace("Año ", "").replace("Anio_", "").to_int()
		if año > 0 and not anios.has(año):
			anios.append(año)
	anios.sort()
	_chips_anio.visible = not anios.is_empty()
	if anios.is_empty():
		return
	if not anios.has(año_actual_lectura):
		año_actual_lectura = anios[0]

	for año in anios:
		var btn := Button.new()
		btn.text = "Año %d" % año
		btn.custom_minimum_size = Vector2(0, 44)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.set_meta("anio", año)
		btn.pressed.connect(_on_pestaña_pressed.bind(año))
		_chips_anio.add_child(btn)

	_Actualizar_Estilos_Chips()


func _Actualizar_Estilos_Chips() -> void:
	for btn in _chips_anio.get_children():
		if not (btn is Button):
			continue
		var activo: bool = int(btn.get_meta("anio", -1)) == año_actual_lectura
		Estilos_UI.aplicar_estilo_boton(btn, "primario" if activo else "chip", _color_acento)
		btn.add_theme_font_size_override("font_size", 13)
		btn.add_theme_font_override("font", Estilos_UI.fuente_ui(700 if activo else 600))


func _on_pestaña_pressed(año: int) -> void:
	if año == año_actual_lectura:
		return
	año_actual_lectura = año
	_Mostrar_Año(año)


func _Mostrar_Año(año: int) -> void:
	if carrera == null:
		return
	año_actual_lectura = año
	var nombre_visible := nombre_carrera(carrera.nombre)
	actualizar_cabecera(
		"Apuntes",
		"%s · Año %d de %d" % [nombre_visible, año, carrera.años_totales],
		"BIBLIOTECA DE CARRERA",
		"book-open",
		_color_acento.darkened(0.10))
	_Actualizar_Estilos_Chips()
	_Limpiar_Contenido()

	var ruta := APUNTES_PATH_BASE % [carrera.slug_contenido, año]
	if not FileAccess.file_exists(ruta):
		_Mostrar_Vacio("Apuntes no disponibles para Año %d.\nSigue avanzando en la carrera para desbloquear el temario." % año)
		return
	var texto := FileAccess.get_file_as_string(ruta)
	if texto.strip_edges() == "":
		_Mostrar_Vacio("El temario de Año %d está vacío." % año)
		return

	_Parsear(texto)
	_Renderizar_Tema()
	scroll_principal.scroll_vertical = 0
	scroll_principal.set_deferred("scroll_vertical", 0)


# ----------------------------------------------------------------------------
# Parseo del temario
# ----------------------------------------------------------------------------

func _Parsear(texto: String) -> void:
	_secciones = []
	_titulo_tema = ""
	_eyebrow_tema = ""
	_num_palabras = 0
	var lineas := texto.replace("\r", "").split("\n")
	var regex := RegEx.new()
	regex.compile("^(\\d+)\\.\\s+(.+)$")

	var primera := ""
	var indice_primera := 0
	for i in range(lineas.size()):
		if lineas[i].strip_edges() != "":
			primera = lineas[i].strip_edges()
			indice_primera = i
			break

	var separador := primera.rfind(":")
	if separador >= 0:
		_eyebrow_tema = primera.substr(0, separador).strip_edges().replace(" - ", " · ")
		_titulo_tema = _Titulo_Bonito(primera.substr(separador + 1))
	else:
		_titulo_tema = _Titulo_Bonito(primera)

	var actual: Dictionary = {}
	for i in range(indice_primera + 1, lineas.size()):
		var linea := lineas[i]
		var limpia := linea.strip_edges()
		var coincidencia := regex.search(limpia)
		if coincidencia != null:
			if not actual.is_empty():
				_secciones.append(actual)
			actual = {
				"numero": coincidencia.get_string(1).to_int(),
				"titulo": _Titulo_Bonito(coincidencia.get_string(2)),
				"cuerpo": [],
			}
		elif not actual.is_empty():
			actual["cuerpo"].append(linea)

	if not actual.is_empty():
		_secciones.append(actual)

	if _secciones.is_empty():
		# Texto sin secciones numeradas: se muestra como un único bloque.
		var cuerpo: Array = []
		for i in range(indice_primera + 1, lineas.size()):
			cuerpo.append(lineas[i])
		_secciones.append({"numero": 0, "titulo": _titulo_tema, "cuerpo": cuerpo})
		_titulo_tema = ""

	for seccion in _secciones:
		_num_palabras += str(seccion.get("titulo", "")).split(" ", false).size()
		for linea in seccion.get("cuerpo", []):
			_num_palabras += str(linea).split(" ", false).size()


func _Titulo_Bonito(texto: String) -> String:
	var palabras := texto.to_lower().split(" ", false)
	var resultado: Array = []
	for i in range(palabras.size()):
		var palabra: String = palabras[i]
		if palabra == "":
			continue
		if i > 0 and CONECTORES.has(palabra):
			resultado.append(palabra)
		else:
			resultado.append(palabra.substr(0, 1).to_upper() + palabra.substr(1))
	return " ".join(resultado)


# ----------------------------------------------------------------------------
# Render
# ----------------------------------------------------------------------------

func _Limpiar_Contenido() -> void:
	for hijo in contenido.get_children():
		contenido.remove_child(hijo)
		hijo.queue_free()


func _Mostrar_Vacio(mensaje: String) -> void:
	_Limpiar_Contenido()
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Color("#fbf7ee"), 18, Color("#eadfcb"), 1, 1))
	contenido.add_child(card)

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 22)
	margen.add_theme_constant_override("margin_right", 22)
	margen.add_theme_constant_override("margin_top", 26)
	margen.add_theme_constant_override("margin_bottom", 26)
	card.add_child(margen)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 10)
	margen.add_child(v)

	var badge := Estilos_UI.badge_icono("library", 54, 26, Color(_color_acento, 0.14), _color_acento_oscuro, 16)
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(badge)

	var titulo := Estilos_UI.titulo("Temario no disponible", 20, Estilos_UI.TINTA)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(titulo)

	var texto := Estilos_UI.parrafo(mensaje, 14, Estilos_UI.TINTA_SUAVE)
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(texto)


func _Renderizar_Tema() -> void:
	_Limpiar_Contenido()
	_contenido_apuntes_estilo_fondo()
	contenido.add_child(_Crear_Cabecera_Tema())

	for seccion in _secciones:
		contenido.add_child(_Crear_Seccion(seccion))

	contenido.add_child(_Crear_Pie_Tema())


func _contenido_apuntes_estilo_fondo() -> void:
	# El área de lectura se tiñe de papel cálido; las tarjetas del temario
	# quedan encima en blanco roto para que la lectura sea descansada.
	var st := StyleBoxFlat.new()
	st.bg_color = Color("#f7f3ea")
	st.set_corner_radius_all(0)
	st.anti_aliasing = true
	scroll_principal.add_theme_stylebox_override("panel", st)


func _Crear_Cabecera_Tema() -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Color("#fffdf8"), 18, Color("#e8dfce"), 1, 1))
	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 18)
	margen.add_theme_constant_override("margin_right", 18)
	margen.add_theme_constant_override("margin_top", 16)
	margen.add_theme_constant_override("margin_bottom", 16)
	card.add_child(margen)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 9)
	margen.add_child(v)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 13)
	v.add_child(fila)

	var badge := Estilos_UI.badge_icono(icono_carrera(carrera.nombre), 48, 24,
		Color(_color_acento, 0.14), _color_acento_oscuro, 14)
	fila.add_child(badge)

	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.alignment = BoxContainer.ALIGNMENT_CENTER
	textos.add_theme_constant_override("separation", 2)
	fila.add_child(textos)

	var eyebrow := Estilos_UI.texto(_eyebrow_tema, 10, _color_acento_oscuro, 700)
	eyebrow.visible = _eyebrow_tema != ""
	textos.add_child(eyebrow)

	var titulo := Label.new()
	titulo.text = _titulo_tema
	titulo.add_theme_font_override("font", Estilos_UI.fuente_editorial(700))
	titulo.add_theme_font_size_override("font_size", 25)
	titulo.add_theme_color_override("font_color", Estilos_UI.TINTA)
	titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.add_child(titulo)

	var meta := HBoxContainer.new()
	meta.add_theme_constant_override("separation", 7)
	v.add_child(meta)

	var minutos := maxi(1, int(ceil(float(_num_palabras) / 180.0)))
	meta.add_child(Estilos_UI.icono_rect("list-todo", 15, _color_acento_oscuro))
	meta.add_child(Estilos_UI.texto("%d temas" % _secciones.size(), 12, Estilos_UI.TINTA_SUAVE, 600))
	var punto := Estilos_UI.texto("·", 12, Estilos_UI.TINTA_FANTASMA, 700)
	meta.add_child(punto)
	meta.add_child(Estilos_UI.icono_rect("clock", 15, _color_acento_oscuro))
	meta.add_child(Estilos_UI.texto("%d min de lectura" % minutos, 12, Estilos_UI.TINTA_SUAVE, 600))
	return card


func _Crear_Seccion(seccion: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Color("#fffdf8"), 16, Color("#e8dfce"), 1, 1))
	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 17)
	margen.add_theme_constant_override("margin_right", 17)
	margen.add_theme_constant_override("margin_top", 15)
	margen.add_theme_constant_override("margin_bottom", 16)
	card.add_child(margen)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	margen.add_child(v)

	var cabecera := HBoxContainer.new()
	cabecera.add_theme_constant_override("separation", 10)
	v.add_child(cabecera)

	var numero: int = int(seccion.get("numero", 0))
	if numero > 0:
		var badge := PanelContainer.new()
		badge.custom_minimum_size = Vector2(34, 34)
		badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		badge.add_theme_stylebox_override("panel",
			Estilos_UI.caja(Color(_color_acento, 0.13), 10, Color(_color_acento, 0.16), 1, 0))
		cabecera.add_child(badge)
		var num_lbl := Estilos_UI.texto("%02d" % numero, 12, _color_acento_oscuro, 700)
		num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_child(num_lbl)

	var titulo := Label.new()
	titulo.text = str(seccion.get("titulo", ""))
	titulo.add_theme_font_override("font", Estilos_UI.fuente_titulo(600))
	titulo.add_theme_font_size_override("font_size", 18)
	titulo.add_theme_color_override("font_color", Estilos_UI.TINTA)
	titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cabecera.add_child(titulo)

	var divisor := ColorRect.new()
	divisor.color = Color("#eee7d9")
	divisor.custom_minimum_size = Vector2(0, 1)
	divisor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(divisor)

	var cuerpo := VBoxContainer.new()
	cuerpo.add_theme_constant_override("separation", 8)
	v.add_child(cuerpo)

	var bloques := _Agrupar_Bloques(seccion.get("cuerpo", []))
	if bloques.is_empty():
		cuerpo.add_child(_Crear_Parrafo("Sin contenido para este apartado."))
	else:
		for bloque in bloques:
			if bloque.get("tipo", "") == "ul":
				for item in bloque.get("items", []):
					cuerpo.add_child(_Crear_Bullet(item))
			else:
				cuerpo.add_child(_Crear_Parrafo(bloque.get("texto", "")))
	return card


func _Agrupar_Bloques(lineas: Array) -> Array:
	var bloques: Array = []
	var parrafo := ""
	for linea_cruda in lineas:
		var linea := str(linea_cruda)
		var limpia := linea.strip_edges()
		if limpia == "":
			if parrafo != "":
				bloques.append({"tipo": "p", "texto": parrafo})
				parrafo = ""
			continue
		if limpia.begins_with("- "):
			if parrafo != "":
				bloques.append({"tipo": "p", "texto": parrafo})
				parrafo = ""
			if not bloques.is_empty() and bloques[-1].get("tipo", "") == "ul":
				bloques[-1]["items"].append(limpia.substr(2).strip_edges())
			else:
				bloques.append({"tipo": "ul", "items": [limpia.substr(2).strip_edges()]})
		else:
			if parrafo == "":
				parrafo = limpia
			else:
				parrafo += " " + limpia
	if parrafo != "":
		bloques.append({"tipo": "p", "texto": parrafo})
	return bloques


func _Crear_Parrafo(texto: String) -> RichTextLabel:
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = true
	rt.scroll_active = false
	rt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rt.add_theme_font_override("normal_font", Estilos_UI.fuente_ui(400))
	rt.add_theme_font_override("bold_font", Estilos_UI.fuente_ui(700))
	rt.add_theme_font_size_override("normal_font_size", 15)
	rt.add_theme_font_size_override("bold_font_size", 15)
	rt.add_theme_color_override("default_color", Estilos_UI.TINTA)
	rt.add_theme_constant_override("line_separation", 4)
	rt.text = _Escapar_BBCode(texto)
	return rt


func _Crear_Bullet(texto: String) -> Control:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 9)

	var columna := VBoxContainer.new()
	columna.custom_minimum_size = Vector2(12, 0)
	columna.add_theme_constant_override("separation", 0)
	var hueco := Control.new()
	hueco.custom_minimum_size = Vector2(0, 7)
	columna.add_child(hueco)
	columna.add_child(Punto_Apunte.new(_color_acento))
	fila.add_child(columna)

	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = true
	rt.scroll_active = false
	rt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rt.add_theme_font_override("normal_font", Estilos_UI.fuente_ui(400))
	rt.add_theme_font_override("bold_font", Estilos_UI.fuente_ui(700))
	rt.add_theme_font_size_override("normal_font_size", 14)
	rt.add_theme_font_size_override("bold_font_size", 14)
	rt.add_theme_color_override("default_color", Estilos_UI.TINTA_SUAVE)
	rt.add_theme_constant_override("line_separation", 3)
	rt.text = _Texto_Bullet(texto)
	fila.add_child(rt)
	return fila


func _Texto_Bullet(texto: String) -> String:
	var idx := texto.find(":")
	if idx > 0 and idx <= 70:
		return "[b]%s[/b]%s" % [
			_Escapar_BBCode(texto.substr(0, idx + 1)),
			_Escapar_BBCode(texto.substr(idx + 1)),
		]
	return _Escapar_BBCode(texto)


func _Escapar_BBCode(texto: String) -> String:
	return texto.replace("[", "[lb]")


func _Crear_Pie_Tema() -> Control:
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 8)
	fila.add_child(Estilos_UI.icono_rect("circle-check", 16, _color_acento))
	var lbl := Estilos_UI.texto("Fin del tema · Año %d" % año_actual_lectura, 12,
		Estilos_UI.TINTA_FANTASMA, 600)
	fila.add_child(lbl)
	return fila


class Punto_Apunte extends Control:
	var _color: Color

	func _init(color: Color) -> void:
		_color = color
		custom_minimum_size = Vector2(7, 7)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_circle(Vector2(3.5, 3.5), 3.0, _color)
