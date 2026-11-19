extends AcceptDialog

signal carrera_elegida(script_path: String)

const CARRERAS_DISPONIBLES: Array = [
	"res://Scripts/Logica/Escena_Principal/Actividades/Carreras/Carrera_Ingenieria_Informatica.gd",
	"res://Scripts/Logica/Escena_Principal/Actividades/Carreras/Carrera_Derecho.gd",
	"res://Scripts/Logica/Escena_Principal/Actividades/Carreras/Carrera_Medicina.gd",
	"res://Scripts/Logica/Escena_Principal/Actividades/Carreras/Carrera_Bellas_Artes.gd",
]

const ICONOS_CARRERA: Dictionary = {
	"Ingenieria_Informatica": ["zap", Color("#1d7afc")],
	"Derecho": ["scale", Color("#7c3aed")],
	"Medicina": ["stethoscope", Color("#d62828")],
	"Bellas_Artes": ["palette", Color("#ec4899")],
}

func _ready():
	title = "Elegir carrera"
	min_size = Vector2(580, 520)
	ok_button_text = "Cancelar"
	_Construir_UI()
	Estilos_UI.estilizar_dialogo(self)
	Estilos_UI.aplicar_estilo_boton(get_ok_button(), "secundario")
	get_ok_button().custom_minimum_size = Vector2(128, 44)


func _Construir_UI():
	var margen := MarginContainer.new()
	margen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margen.add_theme_constant_override("margin_left", 8)
	margen.add_theme_constant_override("margin_right", 8)
	margen.add_theme_constant_override("margin_top", 8)
	margen.add_theme_constant_override("margin_bottom", 8)
	add_child(margen)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.custom_minimum_size = Vector2(500, 400)
	vbox.add_theme_constant_override("separation", 12)
	margen.add_child(vbox)

	var instrucciones = Estilos_UI.parrafo(
		"Elige una titulación universitaria. Solo puedes cursar una a la vez.",
		14, Estilos_UI.TINTA_SUAVE)
	vbox.add_child(instrucciones)

	for script_path in CARRERAS_DISPONIBLES:
		var carrera = load(script_path).new()
		var nombre_visible = str(carrera.nombre).replace("_", " ")
		var ya_completada = _Esta_Completada(carrera.nombre)
		var ic_info: Array = ICONOS_CARRERA.get(carrera.nombre, ["graduation-cap", Estilos_UI.ROJO_BIT])
		var ic_nombre: String = ic_info[0]
		var ic_color: Color = Estilos_UI.EXITO if ya_completada else ic_info[1]

		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 72)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.text = ""
		btn.set_meta("_estilo_propio", true)
		Estilos_UI.aplicar_estilo_boton(btn, "tarjeta", ic_color)

		var row := HBoxContainer.new()
		row.set_anchors_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 14
		row.offset_right = -14
		row.add_theme_constant_override("separation", 14)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(row)

		var badge := Estilos_UI.badge_icono(ic_nombre, 42, 20, ic_color, Color.WHITE, 11)
		row.add_child(badge)

		var txt_col := VBoxContainer.new()
		txt_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		txt_col.alignment = BoxContainer.ALIGNMENT_CENTER
		txt_col.add_theme_constant_override("separation", 2)
		txt_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(txt_col)

		var lbl_n := Estilos_UI.texto(nombre_visible, 16, Estilos_UI.TINTA_FANTASMA if ya_completada else Estilos_UI.TINTA, 700)
		lbl_n.mouse_filter = Control.MOUSE_FILTER_IGNORE
		txt_col.add_child(lbl_n)

		var costo_mat := int(Variables_Estaticas.Obtener_Costo_Matricula(carrera))
		var sub_txt := "Ya completada" if ya_completada else "%d años · %d €/año" % [carrera.años_totales, costo_mat]
		var lbl_s := Estilos_UI.texto(sub_txt, 13, Estilos_UI.EXITO if ya_completada else Estilos_UI.TINTA_SUAVE, 500)
		lbl_s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		txt_col.add_child(lbl_s)

		if ya_completada:
			btn.disabled = true
			row.add_child(Estilos_UI.pill_estado("Completada", Estilos_UI.EXITO_SUAVE, Estilos_UI.EXITO))
		else:
			btn.pressed.connect(_on_carrera_pressed.bind(script_path))
			var chev := Estilos_UI.icono_rect("chevron-right", 18, Estilos_UI.TINTA_FANTASMA)
			chev.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(chev)

		vbox.add_child(btn)


func _Esta_Completada(nombre_carrera: String) -> bool:
	for c in Variables_Dinamicas.Carreras_Completadas:
		if c.nombre == nombre_carrera:
			return true
	return false


func _on_carrera_pressed(script_path: String):
	carrera_elegida.emit(script_path)
	queue_free()
