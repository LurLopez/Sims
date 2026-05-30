extends AcceptDialog

const APUNTES_PATH_BASE: String = "res://Scripts/Logica/Escena_Principal/Actividades/Carreras/Contenido/apuntes_ing_informatica_anio%d.txt"

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

func Configurar(_carrera: Carrera):
	carrera = _carrera
	año_actual_lectura = carrera.año_actual
	_Construir_Pestañas()
	_Mostrar_Año(año_actual_lectura)

func _Construir_UI_Base():
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.custom_minimum_size = Vector2(600, 700)
	add_child(vbox)
	label_titulo = Label.new()
	label_titulo.add_theme_font_size_override("font_size", 18)
	vbox.add_child(label_titulo)
	contenedor_pestañas = HBoxContainer.new()
	contenedor_pestañas.add_theme_constant_override("separation", 8)
	vbox.add_child(contenedor_pestañas)
	text_edit = TextEdit.new()
	text_edit.editable = false
	text_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_edit.custom_minimum_size = Vector2(600, 600)
	text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	vbox.add_child(text_edit)

func _Construir_Pestañas():
	for hijo in contenedor_pestañas.get_children():
		hijo.queue_free()
	if carrera == null:
		return
	for libro in carrera.libros_desbloqueados:
		var año = int(String(libro).replace("Anio_", ""))
		var btn = Button.new()
		btn.text = "Año %d" % año
		btn.pressed.connect(_on_pestaña_pressed.bind(año))
		contenedor_pestañas.add_child(btn)

func _on_pestaña_pressed(año: int):
	año_actual_lectura = año
	_Mostrar_Año(año)

func _Mostrar_Año(año: int):
	var ruta = APUNTES_PATH_BASE % año
	if not FileAccess.file_exists(ruta):
		text_edit.text = "Apuntes no disponibles para Año %d" % año
		label_titulo.text = "Apuntes Año %d" % año
		return
	text_edit.text = FileAccess.get_file_as_string(ruta)
	var nombre_carrera = carrera.nombre if carrera != null else ""
	label_titulo.text = "Apuntes %s - Año %d" % [nombre_carrera, año]
