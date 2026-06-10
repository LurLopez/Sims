extends Node
var raiz_path

func Quitar_Todo(raiz):
	Recursivo_Desvisibilizar(raiz)
	Visibilizar_Lo_Basico(raiz)

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
	raiz.visible=true
	for nodo in raiz.get_children():
		if nodo is Button or nodo is BaseButton:
			nodo.visible = true

func Desvisibilizar_Botones(raiz):
	for nodo in raiz.get_children():
		if nodo is Button or nodo is BaseButton:
			nodo.visible = false



func Visibilizar_Lo_Basico(raiz):
	raiz.visible=true
	Recursivo_Visibilizar(raiz.get_node("Barra_Abajo"))
	raiz.get_node("Fondo").visible=true
	raiz.get_node("Moneda").visible=true
	raiz.get_node("Dinero_Label").visible=true
	raiz.get_node("Tienda_Button").visible=true
	raiz.get_node("Alquiler_Button").visible=true
	raiz.get_node("Boton_Perfil").visible=true
	# Botones de carrera (dinámicamente creados)
	if raiz.carrera_button != null:
		raiz.carrera_button.visible = true
	if raiz.libros_button != null:
		raiz.libros_button.visible = raiz.libros_button.visible



func Visibilizar_Actividades(raiz):
	raiz.get_node("Actividades").visible=true


func Visibilizar_Elegir_Actividad(raiz):
	Quitar_Todo(raiz)
	Visibilizar_Actividades(raiz)
	raiz.get_node("Actividades/Elegir_Actividad").visible=true
	raiz.get_node("Actividades/Elegir_Actividad/Tipos_De_Actividades").visible=true
	raiz_path="Actividades/Elegir_Actividad/Tipos_De_Actividades"
	Visibilizar_Botones(raiz.get_node(raiz_path))

func Pulsar_Boton_Opciones_Actividades(opcion,raiz):
	
	Desvisibilizar_Botones(raiz.get_node(raiz_path))
	raiz_path=raiz_path+"/"+opcion+"_Opciones"
	Visibilizar_Botones(raiz.get_node(raiz_path))
	Comprobar_Flecha_Atras(raiz)

func Pulsar_Flecha_Atras(raiz):
	Desvisibilizar_Botones(raiz.get_node(raiz_path))
	raiz_path=raiz_path.get_base_dir()
	Visibilizar_Botones(raiz.get_node(raiz_path))
	Comprobar_Flecha_Atras(raiz)

func Comprobar_Flecha_Atras(raiz):
	if(raiz_path!="Actividades/Elegir_Actividad/Tipos_De_Actividades"):
		raiz.get_node("Actividades/Elegir_Actividad/Flecha_Atras").visible=true
	else: raiz.get_node("Actividades/Elegir_Actividad/Flecha_Atras").visible=false

func Visibilizar_Horario_Semanal(raiz):
	Visibilizar_Actividades(raiz)
	Recursivo_Visibilizar(raiz.get_node("Actividades/Horario_Semanal"))
	raiz.get_node("Actividades/Horario_Semanal/OPCIONES_CALENDARIO/OCUPAR_ACTIVIDAD").visible=false
	raiz.get_node("Actividades/Horario_Semanal/OPCIONES_CALENDARIO/ELIMINAR_ACTIVIDAD").visible=false

func Visibilizar_Seleccionar_Horario(raiz):
	Quitar_Todo(raiz)
	Visibilizar_Actividades(raiz)
	Recursivo_Visibilizar(raiz.get_node("Actividades/Seleccionar_Horario"))

func Actividad_Terminada(raiz):
	Quitar_Todo(raiz)
	raiz_path=""


func Visibilizar_Tienda(raiz):
	Recursivo_Desvisibilizar(raiz)
	raiz.visible = true
	raiz.get_node("Fondo").visible = true
	raiz.get_node("Moneda").visible = true
	raiz.get_node("Dinero_Label").visible = true
	raiz.get_node("Alquiler_Button").visible = true
	Recursivo_Visibilizar(raiz.get_node("Tienda"))
	Mostrar_Categoria_Tienda(raiz, "Dormir")


func Mostrar_Categoria_Tienda(raiz, categoria):
	raiz.get_node("Tienda/Objetos_Dormir").visible = false
	raiz.get_node("Tienda/Objetos_Comer").visible = false
	raiz.get_node("Tienda/Objetos_Duchar").visible = false
	raiz.get_node("Tienda/Objetos_" + categoria).visible = true
	



func Visibilizar_Mensajes(raiz):
	Quitar_Todo(raiz)
	Visibilizar_Lo_Basico(raiz)
	var pantalla = raiz.get_node("Pantalla_Mensajes")
	Recursivo_Visibilizar(pantalla)
	pantalla.get_node("Contenido_Mensaje").visible = false


func devolver_boton_ocupar_actividad(raiz):
	return raiz.get_node("Actividades/Horario_Semanal/OPCIONES_CALENDARIO/OCUPAR_ACTIVIDAD")

func devolver_boton_eliminar_actividad(raiz):
	return raiz.get_node("Actividades/Horario_Semanal/OPCIONES_CALENDARIO/ELIMINAR_ACTIVIDAD")
