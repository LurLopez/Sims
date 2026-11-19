extends AcceptDialog

const APUNTES_PATH_BASE: String = "res://Scripts/Logica/Escena_Principal/Actividades/Carreras/Contenido/apuntes_%s_anio%d.txt"

var carrera: Carrera = null
var año_actual_lectura: int = 1
var label_titulo: Label
var text_edit: TextEdit
var contenedor_pestañas: HBoxContainer


func _ready():
	title = "Apuntes"
	min_size = Vector2(640, 880)
	ok_button_text = "Cerrar"
	_Construir_UI_Base()
	Estilos_UI.estilizar_dialogo(self)


func Configurar(_carrera: Carrera):
	carrera = _carrera
	año_actual_lectura = carrera.año_actual
	_Construir_Pestañas()
	_Mostrar_Año(año_actual_lectura)


func _Construir_UI_Base():
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.custom_minimum_size = Vector2(600, 720)
	vbox.add_theme_constant_override("separation", 12)
	add_child(vbox)

	label_titulo = Estilos_UI.texto("", 18, Estilos_UI.TINTA, 700)
	vbox.add_child(label_titulo)

	contenedor_pestañas = HBoxContainer.new()
	contenedor_pestañas.add_theme_constant_override("separation", 8)
	vbox.add_child(contenedor_pestañas)

	text_edit = TextEdit.new()
	text_edit.editable = false
	text_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_edit.custom_minimum_size = Vector2(600, 620)
	text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	text_edit.add_theme_font_override("font", Estilos_UI.fuente_ui(400))
	text_edit.add_theme_font_size_override("font_size", 15)
	text_edit.add_theme_color_override("font_color", Estilos_UI.TINTA)
	text_edit.add_theme_color_override("font_readonly_color", Estilos_UI.TINTA)
	var te_style := Estilos_UI.caja(Color("#fdfbf7"), 12, Estilos_UI.BORDE, 1, 0)
	te_style.content_margin_left = 14
	te_style.content_margin_right = 14
	te_style.content_margin_top = 12
	te_style.content_margin_bottom = 12
	text_edit.add_theme_stylebox_override("normal", te_style)
	text_edit.add_theme_stylebox_override("read_only", te_style)
	vbox.add_child(text_edit)


func _Construir_Pestañas():
	for hijo in contenedor_pestañas.get_children():
		hijo.queue_free()
	if carrera == null:
		return
	for libro in carrera.libros_desbloqueados:
		var año: int = str(libro).replace("Año ", "").replace("Anio_", "").to_int()
		var btn = Button.new()
		btn.text = "Año %d" % año
		btn.set_meta("_estilo_propio", true)
		btn.set_meta("anio", año)
		btn.pressed.connect(_on_pestaña_pressed.bind(año))
		contenedor_pestañas.add_child(btn)


func _on_pestaña_pressed(año: int):
	año_actual_lectura = año
	_Mostrar_Año(año)


func _Mostrar_Año(año: int):
	for btn in contenedor_pestañas.get_children():
		if btn is Button:
			var activo: bool = int(btn.get_meta("anio", -1)) == año
			Estilos_UI.aplicar_estilo_boton(btn, "primario" if activo else "chip", Estilos_UI.PRIMARIO)
			btn.add_theme_font_size_override("font_size", 13)

	var ruta = APUNTES_PATH_BASE % [carrera.slug_contenido, año]
	var nombre_carrera = carrera.nombre.replace("_", " ") if carrera != null else ""
	if not FileAccess.file_exists(ruta):
		text_edit.text = "Apuntes no disponibles para Año %d" % año
		label_titulo.text = "%s · Año %d" % [nombre_carrera, año]
		return
	text_edit.text = FileAccess.get_file_as_string(ruta)
	label_titulo.text = "%s · Año %d" % [nombre_carrera, año]
