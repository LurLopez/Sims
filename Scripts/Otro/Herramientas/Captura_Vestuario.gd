extends Node

# Herramienta de QA visual del Vestuario.
# Uso:
#   godot --path . res://Escenas/Herramientas/Captura_Vestuario.tscn
# (con --headless no se generan texturas; usa una sesión gráfica)

const DIR_SALIDA := "user://capturas_vestuario"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR_SALIDA))
	await get_tree().process_frame
	await _Capturar_Pantalla("vestuario_720x1280.png", true, "", "")
	await _Capturar_Pantalla("vestuario_tienda_720x1280.png", false, "elegante", "Traje_Ejecutivo")
	await _Capturar_Pantalla("vestuario_sin_saldo_720x1280.png", false, "elegante", "Traje_Ejecutivo", 100.0)
	await _Capturar_Pantalla("vestuario_astronauta_720x1280.png", false, "trabajo", "Traje_Astronauta")
	await _Capturar_Pantalla("vestuario_cocina_720x1280.png", false, "cocina", "")
	await _Capturar_Grid("atuendos_grid.png", "hombre")
	await _Capturar_Grid("atuendos_grid_mujer.png", "mujer")
	print("Capturas del vestuario guardadas en ", ProjectSettings.globalize_path(DIR_SALIDA))
	get_tree().quit()


func _Preparar_Escena(todo_desbloqueado: bool, genero: String = "hombre") -> void:
	var ap := Apariencia_Personaje.por_defecto()
	ap["genero"] = genero
	if genero == "mujer":
		ap["estilo_pelo"] = "largo"
	Variables_Estaticas.Apariencia = Apariencia_Personaje.normalizar(ap)
	Variables_Estaticas.Modo_Rapido = false
	Variables_Estaticas.Record_Max_Niveles_Cocina = 45 if todo_desbloqueado else 0
	Variables_Dinamicas.Cocina_Estado = Variables_Dinamicas.Cocina_Estado_Por_Defecto()
	Variables_Dinamicas.Cocina_Estado["estrellas_nivel"] = {}
	var restante_estrellas: int = Sistema_Cocina.ESTRELLAS_TOTALES_MAX if todo_desbloqueado else 34
	for rest_id in Sistema_Cocina.ORDEN_RESTAURANTES:
		for n in range(1, 16):
			if restante_estrellas <= 0:
				break
			var valor_estrellas: int = mini(3, restante_estrellas)
			Variables_Dinamicas.Cocina_Estado["estrellas_nivel"]["%s_%d" % [rest_id, n]] = valor_estrellas
			restante_estrellas -= valor_estrellas
		if restante_estrellas <= 0:
			break
	Variables_Dinamicas.Dinero = 950.0
	Variables_Dinamicas.Objetos_Poseidos["Ropa_Calle"] = true
	if todo_desbloqueado:
		for clave in Sistema_Cocina.ORDEN_ROPA:
			Variables_Dinamicas.Objetos_Poseidos[clave] = true
	else:
		for clave in Sistema_Cocina.ORDEN_ROPA:
			Variables_Dinamicas.Objetos_Poseidos.erase(clave)
		Sistema_Cocina.Asegurar_Prendas_Iniciales()
	Variables_Dinamicas.Objeto_Seleccionado["Ropa"] = "Ropa_Calle"


func _Capturar_Pantalla(nombre: String, todo_desbloqueado: bool, filtro: String,
		seleccion: String, dinero: float = 950.0) -> void:
	_Preparar_Escena(todo_desbloqueado)
	Variables_Dinamicas.Dinero = dinero
	var vp := SubViewport.new()
	vp.size = Vector2i(720, 1280)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	var pantalla := Pantalla_Vestuario.new()
	vp.add_child(pantalla)
	await get_tree().process_frame
	pantalla.abrir()
	await get_tree().process_frame
	if filtro != "":
		pantalla._Cambiar_Filtro(filtro)
	if seleccion != "":
		pantalla.seleccionar_atuendo(seleccion)
	await get_tree().process_frame
	await get_tree().create_timer(0.45).timeout
	await RenderingServer.frame_post_draw
	var imagen := vp.get_texture().get_image()
	if imagen != null and not imagen.is_empty():
		var ruta := DIR_SALIDA.path_join(nombre)
		imagen.save_png(ruta)
		print("Captura: ", ruta, " (", imagen.get_width(), "x", imagen.get_height(), ")")
	vp.queue_free()
	await get_tree().process_frame


func _Capturar_Grid(nombre: String, genero: String) -> void:
	_Preparar_Escena(true, genero)
	var vp := SubViewport.new()
	vp.size = Vector2i(1180, 1640)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	var fondo := ColorRect.new()
	fondo.color = Color("#eef2f8")
	fondo.size = Vector2(vp.size)
	vp.add_child(fondo)

	var margen := MarginContainer.new()
	margen.set_anchors_preset(Control.PRESET_FULL_RECT)
	margen.add_theme_constant_override("margin_left", 20)
	margen.add_theme_constant_override("margin_right", 20)
	margen.add_theme_constant_override("margin_top", 20)
	margen.add_theme_constant_override("margin_bottom", 20)
	vp.add_child(margen)

	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	margen.add_child(grid)

	for clave in Sistema_Cocina.ORDEN_ROPA:
		grid.add_child(_Crear_Card(clave))
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.35).timeout
	await RenderingServer.frame_post_draw
	var imagen := vp.get_texture().get_image()
	if imagen != null and not imagen.is_empty():
		var ruta := DIR_SALIDA.path_join(nombre)
		imagen.save_png(ruta)
		print("Captura: ", ruta, " (", imagen.get_width(), "x", imagen.get_height(), ")")
	vp.queue_free()


func _Crear_Card(clave: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(220, 300)
	card.add_theme_stylebox_override("panel", Estilos_UI.caja(Color.WHITE, 16, Estilos_UI.BORDE, 1, 2))

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	card.add_child(col)

	var escenario := Control.new()
	escenario.custom_minimum_size = Vector2(0, 230)
	escenario.clip_contents = true
	col.add_child(escenario)

	var ap := Sistema_Cocina.Obtener_Apariencia_Con_Ropa(
		Apariencia_Personaje.normalizar(Variables_Estaticas.Apariencia), clave)
	var pj := Personaje_Visual.new(ap, "cuerpo_completo")
	pj.set_anchors_preset(Control.PRESET_FULL_RECT)
	pj.animar_idle = false
	pj.expresion = "sonrisa"
	pj.edad = 26
	pj.mouse_filter = Control.MOUSE_FILTER_IGNORE
	escenario.add_child(pj)

	var nombre := Estilos_UI.texto(Sistema_Cocina.Obtener_Nombre_Legible_Ropa(clave), 12,
		Estilos_UI.TINTA, 700)
	nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nombre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nombre.max_lines_visible = 2
	col.add_child(nombre)
	var estado := Estilos_UI.texto("%s · %s" % [
		Sistema_Cocina.Obtener_Categoria_Ropa(clave).capitalize(),
		"SIN BONUS" if clave == "Ropa_Calle" else "ATUENDO"], 10,
		Estilos_UI.TINTA_FANTASMA, 600)
	estado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(estado)
	return card
