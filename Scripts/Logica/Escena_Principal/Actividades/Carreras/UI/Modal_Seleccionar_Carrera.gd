extends "res://Scripts/Logica/Escena_Principal/Actividades/Carreras/UI/Modal_Carrera_Base.gd"

# Selector de titulación. Conserva la señal y la lista de carreras originales,
# pero presenta cada grado como una tarjeta táctil con su color, duración,
# coste, dificultad y estado de graduación.

signal carrera_elegida(script_path: String)

const CARRERAS_DISPONIBLES: Array = [
	"res://Scripts/Logica/Escena_Principal/Actividades/Carreras/Carrera_Ingenieria_Informatica.gd",
	"res://Scripts/Logica/Escena_Principal/Actividades/Carreras/Carrera_Derecho.gd",
	"res://Scripts/Logica/Escena_Principal/Actividades/Carreras/Carrera_Medicina.gd",
	"res://Scripts/Logica/Escena_Principal/Actividades/Carreras/Carrera_Bellas_Artes.gd",
]


func _Al_Listo() -> void:
	permitir_cerrar_al_fondo = true
	actualizar_cabecera(
		"Elige tu carrera",
		"Solo puedes cursar una titulación a la vez",
		"VIDA UNIVERSITARIA",
		"graduation-cap")
	_Construir_Contenido()
	_Construir_Pie()


func _Construir_Pie() -> void:
	if not pie.get_children().is_empty():
		return
	var btn := Estilos_UI.boton("Cancelar", "secundario", "x", Estilos_UI.TINTA, 50)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(cerrar)
	pie.add_child(btn)


func _Construir_Contenido() -> void:
	for hijo in contenido.get_children():
		contenido.remove_child(hijo)
		hijo.queue_free()

	contenido.add_child(_Crear_Introduccion())

	for script_path in CARRERAS_DISPONIBLES:
		var recurso = load(script_path)
		if recurso == null:
			continue
		var carrera = recurso.new()
		if carrera == null:
			continue
		contenido.add_child(_Crear_Tarjeta_Carrera(carrera, script_path))

	var nota := Estilos_UI.texto(
		"Al graduarte conservarás el título en tu perfil y desbloquearás un empleo cualificado.",
		11, Estilos_UI.TINTA_FANTASMA, 500)
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nota.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	contenido.add_child(nota)


func _Crear_Introduccion() -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Color("#f8f5ef"), 16, Color("#e8dfce"), 1, 0))
	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 15)
	margen.add_theme_constant_override("margin_right", 15)
	margen.add_theme_constant_override("margin_top", 13)
	margen.add_theme_constant_override("margin_bottom", 13)
	card.add_child(margen)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 11)
	margen.add_child(fila)
	var badge := Estilos_UI.badge_icono("school", 38, 19,
		Color(Estilos_UI.ROJO_BIT, 0.12), Estilos_UI.PRIMARIO, 11)
	fila.add_child(badge)

	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.add_theme_constant_override("separation", 2)
	fila.add_child(textos)
	textos.add_child(Estilos_UI.texto("Una carrera a la vez", 14, Estilos_UI.TINTA, 700))
	var p := Estilos_UI.parrafo(
		"Elige la titulación que quieres estudiar. Cada semana de juego equivale a un curso.",
		12, Estilos_UI.TINTA_SUAVE)
	textos.add_child(p)
	return card


func _Crear_Tarjeta_Carrera(carrera: Carrera, script_path: String) -> Control:
	var completada := _Esta_Completada(carrera.nombre)
	var accent: Color = Estilos_UI.ORO if completada else color_carrera(carrera.nombre)
	var accent_oscuro: Color = Color("#92400e") if completada else accent.darkened(0.18)
	var icono: String = "trophy" if completada else icono_carrera(carrera.nombre)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 88)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.text = ""
	btn.set_meta("_estilo_propio", true)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_Aplicar_Estilo_Tarjeta(btn, accent, completada)

	var fila := HBoxContainer.new()
	fila.set_anchors_preset(Control.PRESET_FULL_RECT)
	fila.offset_left = 14
	fila.offset_right = -14
	fila.offset_top = 12
	fila.offset_bottom = -12
	fila.add_theme_constant_override("separation", 13)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(fila)

	var badge := Estilos_UI.badge_icono(icono, 48, 23,
		Color(accent, 0.14), accent_oscuro, 13)
	fila.add_child(badge)

	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.alignment = BoxContainer.ALIGNMENT_CENTER
	textos.add_theme_constant_override("separation", 5)
	textos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(textos)

	var nombre_visible := nombre_carrera(carrera.nombre)
	var nombre := Estilos_UI.texto(nombre_visible, 17,
		Estilos_UI.TINTA_FANTASMA if completada else Estilos_UI.TINTA, 700)
	nombre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	textos.add_child(nombre)

	var meta := HBoxContainer.new()
	meta.add_theme_constant_override("separation", 6)
	meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	textos.add_child(meta)

	var color_meta := Estilos_UI.TINTA_FANTASMA if completada else Estilos_UI.TINTA_SUAVE
	meta.add_child(Estilos_UI.icono_rect("clock", 14, color_meta))
	meta.add_child(Estilos_UI.texto("%d años" % carrera.años_totales, 12, color_meta, 500))

	var punto1 := Estilos_UI.texto("·", 12, Estilos_UI.TINTA_FANTASMA, 700)
	meta.add_child(punto1)

	var costo_mat := int(Variables_Estaticas.Obtener_Costo_Matricula(carrera))
	meta.add_child(Estilos_UI.icono_rect("euro", 14, color_meta))
	meta.add_child(Estilos_UI.texto("%d €/año" % costo_mat, 12, color_meta, 500))

	if not completada:
		var punto2 := Estilos_UI.texto("·", 12, Estilos_UI.TINTA_FANTASMA, 700)
		meta.add_child(punto2)
		var dif := _Datos_Dificultad(carrera.ajuste_dificultad)
		meta.add_child(Estilos_UI.pill_estado(dif[0], dif[1], dif[2]))

	for hijo in meta.get_children():
		if hijo is Control:
			hijo.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if completada:
		var pill := Estilos_UI.pill_estado("Graduado", Estilos_UI.ORO_SUAVE, Estilos_UI.ORO)
		pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(pill)
		btn.disabled = true
		btn.modulate.a = 0.82
	else:
		var chev := Estilos_UI.icono_rect("chevron-right", 20, Estilos_UI.TINTA_FANTASMA)
		chev.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(chev)
		btn.pressed.connect(_on_carrera_pressed.bind(script_path))
		Estilos_UI.animar_presion(btn)
	return btn


func _Aplicar_Estilo_Tarjeta(btn: Button, accent: Color, completada: bool) -> void:
	var normal := Estilos_UI.caja(
		Color("#fbfaf7") if completada else Estilos_UI.SUPERFICIE,
		16, Color("#e8dfce") if completada else Estilos_UI.BORDE, 1, 1)
	var hover := Estilos_UI.caja(Color("#fafbfd"), 16, Color(accent, 0.50), 1, 2)
	var pressed := Estilos_UI.caja(Color(accent, 0.07), 16, accent, 1, 0)
	var disabled := normal.duplicate() as StyleBoxFlat
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _Datos_Dificultad(ajuste: float) -> Array:
	if ajuste >= 5.0:
		return ["Fácil", Estilos_UI.EXITO_SUAVE, Estilos_UI.EXITO_OSCURO]
	elif ajuste <= -10.0:
		return ["Muy difícil", Estilos_UI.PELIGRO_SUAVE, Estilos_UI.PELIGRO]
	elif ajuste < 0.0:
		return ["Difícil", Estilos_UI.ORO_SUAVE, Estilos_UI.ORO]
	return ["Media", Estilos_UI.AZUL_SUAVE, Estilos_UI.AZUL]


func _Esta_Completada(nombre_carrera: String) -> bool:
	for c in Variables_Dinamicas.Carreras_Completadas:
		if c.nombre == nombre_carrera:
			return true
	return false


func _on_carrera_pressed(script_path: String) -> void:
	carrera_elegida.emit(script_path)
	cerrar()
