extends Node
var raiz_path


func Quitar_Todo(raiz):
	Recursivo_Desvisibilizar(raiz)
	Visibilizar_Lo_Basico(raiz)
	if raiz.has_node("Barra_Abajo"):
		Estilos_UI.marcar_nav_activo(raiz.get_node("Barra_Abajo"), "Boton_Inicio")


func Recursivo_Desvisibilizar(raiz):
	if raiz is CanvasItem:
		raiz.visible = false
	for control in raiz.get_children():
		if control != null:
			Recursivo_Desvisibilizar(control)


func Recursivo_Visibilizar(raiz):
	if raiz is CanvasItem:
		raiz.visible = true
	for control in raiz.get_children():
		if control != null:
			Recursivo_Visibilizar(control)


func Visibilizar_Botones(raiz):
	raiz.visible = true
	for nodo in raiz.get_children():
		if nodo is Button or nodo is BaseButton:
			nodo.visible = true
			var card = nodo.get_node_or_null("Card_Contenido")
			if card != null:
				var pill = card.get_node_or_null("Pill_Actual")
				var pill_vis = pill.visible if pill != null else false
				Recursivo_Visibilizar(card)
				if pill != null:
					pill.visible = pill_vis


func Desvisibilizar_Botones(raiz):
	for nodo in raiz.get_children():
		if nodo is Button or nodo is BaseButton:
			nodo.visible = false


func Visibilizar_Lo_Basico(raiz):
	raiz.visible = true
	Recursivo_Visibilizar(raiz.get_node("Barra_Abajo"))
	raiz.get_node("Fondo").visible = true
	raiz.get_node("Moneda").visible = true
	raiz.get_node("Dinero_Label").visible = true
	raiz.get_node("Boton_Perfil").visible = true
	raiz.get_node("Economia_Button").visible = true
	raiz.get_node("Calendario_Button").visible = true
	raiz.get_node("Carrera_Button").visible = true
	for n in ["Header_BitLife", "Logo_Marca", "Logo_Titulo", "Logo_BitLife", "Reloj_Header", "Nav_Superior", "Dock_Fondo", "Moneda_Fondo"]:
		if raiz.has_node(n):
			raiz.get_node(n).visible = true
	for n_rec in ["Header_Superior", "Avatar_Header_Btn"]:
		if raiz.has_node(n_rec):
			Recursivo_Visibilizar(raiz.get_node(n_rec))
	if raiz.has_node("Home"):
		Recursivo_Visibilizar(raiz.get_node("Home"))


func Visibilizar_Actividades(raiz):
	if raiz.has_node("Home"):
		raiz.get_node("Home").visible = false
	raiz.get_node("Actividades").visible = true
	for n in ["Fondo_Seccion", "Titulo_Actividades", "Subtitulo_Actividades"]:
		if raiz.get_node("Actividades").has_node(n):
			raiz.get_node("Actividades").get_node(n).visible = true


func Visibilizar_Elegir_Actividad(raiz):
	Quitar_Todo(raiz)
	Visibilizar_Actividades(raiz)
	raiz.get_node("Actividades/Elegir_Actividad").visible = true
	raiz.get_node("Actividades/Elegir_Actividad/Tipos_De_Actividades").visible = true
	raiz_path = "Actividades/Elegir_Actividad/Tipos_De_Actividades"
	Visibilizar_Botones(raiz.get_node(raiz_path))
	Comprobar_Flecha_Atras(raiz)


func Pulsar_Boton_Opciones_Actividades(opcion, raiz):
	Desvisibilizar_Botones(raiz.get_node(raiz_path))
	raiz_path = raiz_path + "/" + opcion + "_Opciones"
	Visibilizar_Botones(raiz.get_node(raiz_path))
	Comprobar_Flecha_Atras(raiz)


func Pulsar_Flecha_Atras(raiz):
	Desvisibilizar_Botones(raiz.get_node(raiz_path))
	raiz_path = raiz_path.get_base_dir()
	Visibilizar_Botones(raiz.get_node(raiz_path))
	Comprobar_Flecha_Atras(raiz)


func Comprobar_Flecha_Atras(raiz):
	var en_raiz: bool = (raiz_path == "Actividades/Elegir_Actividad/Tipos_De_Actividades")
	raiz.get_node("Actividades/Elegir_Actividad/Flecha_Atras").visible = not en_raiz
	var tit := raiz.get_node_or_null("Actividades/Titulo_Actividades") as Control
	var sub := raiz.get_node_or_null("Actividades/Subtitulo_Actividades") as Control
	var x_pos := 20.0 if en_raiz else 74.0
	if tit != null:
		tit.position.x = x_pos
	if sub != null:
		sub.position.x = x_pos
		if en_raiz:
			sub.text = "Tipo de actividad"
		elif raiz_path.ends_with("Trabajo_Opciones"):
			sub.text = "Fijas · Empleo"
		elif raiz_path.ends_with("Fijas_Opciones"):
			sub.text = "Actividades fijas"
		elif raiz_path.ends_with("Progreso_Opciones"):
			sub.text = "Temporales · Progreso"
		elif raiz_path.ends_with("Necesidades_Basicas_Opciones"):
			sub.text = "Temporales · Necesidades"
		else:
			sub.text = "Actividades temporales"


func Visibilizar_Horario_Semanal(raiz):
	Visibilizar_Actividades(raiz)
	Recursivo_Desvisibilizar(raiz.get_node("Actividades/Elegir_Actividad"))
	Recursivo_Visibilizar(raiz.get_node("Actividades/Horario_Semanal"))
	raiz.get_node("Actividades/Horario_Semanal/OPCIONES_CALENDARIO/OCUPAR_ACTIVIDAD").visible = false
	raiz.get_node("Actividades/Horario_Semanal/OPCIONES_CALENDARIO/ELIMINAR_ACTIVIDAD").visible = false


func Visibilizar_Seleccionar_Horario(raiz):
	Quitar_Todo(raiz)
	Visibilizar_Actividades(raiz)
	for n in ["Titulo_Actividades", "Subtitulo_Actividades"]:
		if raiz.get_node("Actividades").has_node(n):
			raiz.get_node("Actividades").get_node(n).visible = false
	Recursivo_Visibilizar(raiz.get_node("Actividades/Seleccionar_Horario"))


func Actividad_Terminada(raiz):
	Quitar_Todo(raiz)
	raiz_path = ""


func Visibilizar_Tienda(raiz):
	Recursivo_Desvisibilizar(raiz)
	raiz.visible = true
	Visibilizar_Lo_Basico(raiz)
	if raiz.has_node("Home"):
		raiz.get_node("Home").visible = false
	Recursivo_Visibilizar(raiz.get_node("Tienda"))
	Mostrar_Categoria_Tienda(raiz, "Dormir")


func Mostrar_Categoria_Tienda(raiz, categoria):
	raiz.get_node("Tienda/Objetos_Dormir").visible = false
	raiz.get_node("Tienda/Objetos_Comer").visible = false
	raiz.get_node("Tienda/Objetos_Duchar").visible = false
	raiz.get_node("Tienda/Objetos_" + categoria).visible = true


func Visibilizar_Perfil(raiz):
	Quitar_Todo(raiz)
	if raiz.has_node("Home"):
		raiz.get_node("Home").visible = false
	Visibilizar_Lo_Basico(raiz)
	if raiz.has_node("Home"):
		raiz.get_node("Home").visible = false
	var pantalla = raiz.get_node("Pantalla_Mensajes")
	Recursivo_Visibilizar(pantalla)
	var hb: Control = pantalla.get_node_or_null("Header_Bar") as Control
	if hb != null:
		hb.visible = false
	pantalla.get_node("Contenido_Mensaje").visible = false
	pantalla.get_node("Panel_Info").visible = false
	pantalla.get_node("Lista_Mensajes").visible = false
	pantalla.get_node("Panel_Apuntes").visible = false


func devolver_boton_ocupar_actividad(raiz):
	return raiz.get_node("Actividades/Horario_Semanal/OPCIONES_CALENDARIO/OCUPAR_ACTIVIDAD")


func devolver_boton_eliminar_actividad(raiz):
	return raiz.get_node("Actividades/Horario_Semanal/OPCIONES_CALENDARIO/ELIMINAR_ACTIVIDAD")
