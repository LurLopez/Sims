extends Node

const COLOR_PASADO    = Color("#f1f5f9")
const COLOR_LIBRE     = Color("#ecfdf5")
const COLOR_OCUPADO   = Color("#dbeafe")
const COLOR_PASADO_P  = Color("#cbd5e1")
const COLOR_LIBRE_P   = Color("#86efac")
const COLOR_OCUPADO_P = Color("#93c5fd")

var bloque_columna

var semana
var presionado
var posicion_minuto_inicio
var dia_inicio
var posicion_minuto_final
var dia_final

var tamaño_bloque=0
var excepcion

var matriz_bloques
var libre
var ultimo_diferente
func Inicializar(r):
	bloque_columna=BloqueDiaColumna.new()
	bloque_columna.Inicializar(r)

func Añadir_Horas_Al_Horario():
	for i in range(48):
		var hora_inicio = (i * 30) / 60
		var minuto_inicio = (i * 30) % 60

		var total_minutos_final = i * 30 + 30
		var hora_final = total_minutos_final / 60
		var minuto_final = total_minutos_final % 60

		var texto = "%02d:%02d" % [hora_inicio, minuto_inicio]

		var boton = Button.new()
		boton.mouse_filter=Control.MOUSE_FILTER_PASS
		boton.text = texto
		boton.connect("pressed", Callable(self, "_on_button_pressed"))  # clásico
		
		
		var estilo = StyleBoxFlat.new()
		estilo.bg_color = Color("#f8f9fb")
		estilo.corner_radius_top_left = 0
		estilo.corner_radius_top_right = 0
		estilo.corner_radius_bottom_left = 0
		estilo.corner_radius_bottom_right = 0
		estilo.border_width_left = 0
		estilo.border_width_right = 1
		estilo.border_width_bottom = 2
		estilo.border_width_top = 0
		estilo.border_color = Color("#e2e6ed")
		estilo.content_margin_right = 8
		boton.add_theme_stylebox_override("normal", estilo)
		boton.add_theme_stylebox_override("hover", estilo)
		boton.add_theme_font_override("font", Estilos_UI.fuente_ui(500))
		boton.add_theme_color_override("font_color", Color("#6b7280"))
		boton.add_theme_font_size_override("font_size", 11)
		boton.alignment = HORIZONTAL_ALIGNMENT_RIGHT
		boton.custom_minimum_size=Vector2(70,30)
		bloque_columna.horario_columna.add_child(boton)
func Agregar_Bloques(mirar_semana, raiz):
	matriz_bloques = Funciones_Globales.Devolver_Bloque_Matriz_Semana_(mirar_semana)
	var hoy = fecha.new()
	hoy.Inicializar(Variables_Dinamicas.Minute_Day, Variables_Dinamicas.Minute_Minute)

	for i in range(7):
		var j := 0
		while j < 288:
			var act_actual = matriz_bloques[j][i]
			var es_pasado := _Es_Bloque_Pasado(hoy, mirar_semana, i, j)
			var inicio := j
			j += 1
			while j < 288:
				var sig_pasado := _Es_Bloque_Pasado(hoy, mirar_semana, i, j)
				if sig_pasado != es_pasado or not _Misma_Actividad(matriz_bloques[j][i], act_actual):
					break
				j += 1
			_Crear_Boton_Bloque(i, j - inicio, act_actual, raiz, es_pasado)


func _Es_Bloque_Pasado(hoy: fecha, mirar_semana: int, dia_idx: int, slot_j: int) -> bool:
	var mirar = fecha.new()
	mirar.Inicializar(mirar_semana * 7 + dia_idx, (slot_j + 1) * 5)
	return hoy.Comparar_Dos_Fechas(mirar)


func _Misma_Actividad(a, b) -> bool:
	return typeof(a) == typeof(b) and a == b


func _Crear_Boton_Bloque(i: int, cantidad_slots: int, act_actual, raiz, crear_boton_del_pasado: bool):
					var boton=Button.new()
					boton.mouse_filter=Control.MOUSE_FILTER_PASS
					boton.focus_mode=Control.FOCUS_NONE
					boton.connect("pressed", Callable(self, "click_bloque").bind(boton,raiz))  # clásico
					var estilo = StyleBoxFlat.new()
					estilo.set_border_width_all(0)
					estilo.border_width_bottom = 1
					estilo.border_width_left = 1
					estilo.border_color = Color("#e2e6ed")
					estilo.set_corner_radius_all(4)
					estilo.content_margin_left = 4
					estilo.content_margin_right = 4
					estilo.content_margin_top = 0
					estilo.content_margin_bottom = 0
					
					var estilo_pulsado= StyleBoxFlat.new()
					estilo_pulsado.set_border_width_all(2)
					estilo_pulsado.border_color = Estilos_UI.PRIMARIO
					estilo_pulsado.set_corner_radius_all(4)
					estilo_pulsado.content_margin_top = 0
					estilo_pulsado.content_margin_bottom = 0
					
					var nombre_bloque: String = str(act_actual) if act_actual is String else str(act_actual.nombre)
					if(crear_boton_del_pasado):
						estilo.bg_color = COLOR_PASADO
						estilo_pulsado.bg_color = COLOR_PASADO_P
						estilo_pulsado.border_color = Color("#64748b")
						boton.set_meta("estado", "pasado")
					elif(act_actual is String and act_actual == ""):
						estilo.bg_color = COLOR_LIBRE
						estilo_pulsado.bg_color = COLOR_LIBRE_P
						estilo_pulsado.border_color = Color("#16a34a")
						boton.set_meta("estado", "libre")
					else:
						var act_cat = Variables_Estaticas.Catalogo_Actividades.get(nombre_bloque, null)
						if act_cat != null and act_cat is Actividad:
							var c_base: Color = act_cat.color.lerp(Color.WHITE, 0.78)
							estilo.bg_color = c_base
							estilo.border_width_left = 3
							estilo.border_color = act_cat.color.lerp(Color.WHITE, 0.20)
							estilo_pulsado.bg_color = act_cat.color.lerp(Color.WHITE, 0.35)
							estilo_pulsado.border_color = act_cat.color
						else:
							estilo.bg_color = COLOR_OCUPADO
							estilo.border_width_left = 3
							estilo.border_color = Color("#3b82f6")
							estilo_pulsado.bg_color = COLOR_OCUPADO_P
							estilo_pulsado.border_color = Color("#2563eb")
						boton.set_meta("estado", "ocupado")
					boton.add_theme_stylebox_override("normal",estilo)
					boton.add_theme_stylebox_override("pressed", estilo_pulsado)
					
					boton.set_meta("actividad", act_actual)   #crear un "atributo" llamado "actividad" al boton, y darle el valor de act_actual
					
					boton.add_theme_stylebox_override("hover", estilo)
					boton.add_theme_stylebox_override("hover_pressed", estilo_pulsado)
					boton.toggle_mode = true

					if not (act_actual is String) and boton.get_meta("estado") == "ocupado" and act_actual.icono != null:
						var tex_rect = TextureRect.new()
						tex_rect.texture = act_actual.icono
						tex_rect.stretch_mode = TextureRect.STRETCH_TILE
						tex_rect.anchor_left = 0.0
						tex_rect.anchor_top = 0.0
						tex_rect.anchor_right = 1.0
						tex_rect.anchor_bottom = 1.0
						tex_rect.offset_left = 0
						tex_rect.offset_top = 0
						tex_rect.offset_right = 0
						tex_rect.offset_bottom = 0
						tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
						boton.clip_contents = true
						boton.add_child(tex_rect)

					boton.custom_minimum_size = Vector2(0, cantidad_slots * 5.0)

					if not crear_boton_del_pasado and nombre_bloque != "" and nombre_bloque != "Actividad_Aleatoria" and boton.custom_minimum_size.y >= 24.0:
						var lbl_b := Label.new()
						lbl_b.text = _Formatear_Nombre_Actividad(nombre_bloque)
						lbl_b.add_theme_font_override("font", Estilos_UI.fuente_ui(600))
						lbl_b.add_theme_font_size_override("font_size", 10)
						lbl_b.add_theme_color_override("font_color", Estilos_UI.TINTA)
						lbl_b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
						lbl_b.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
						lbl_b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
						lbl_b.set_anchors_preset(Control.PRESET_FULL_RECT)
						lbl_b.offset_left = 3
						lbl_b.offset_right = -3
						lbl_b.mouse_filter = Control.MOUSE_FILTER_IGNORE
						boton.clip_contents = true
						boton.add_child(lbl_b)
					
					
					match i:
						0:
							bloque_columna.lunes_columna.add_child(boton)
						1:
							bloque_columna.martes_columna.add_child(boton)
						2:
							bloque_columna.miercoles_columna.add_child(boton)
						3:
							bloque_columna.jueves_columna.add_child(boton)
						4:
							bloque_columna.viernes_columna.add_child(boton)
						5:
							bloque_columna.sabado_columna.add_child(boton)
						6:
							bloque_columna.domingo_columna.add_child(boton)

func AgregarBloquesPasados(i,j,mirar_semana):
	var hoy=fecha.new()
	hoy.Inicializar(Variables_Dinamicas.Minute_Day,Variables_Dinamicas.Minute_Minute)
	var mirar=fecha.new()
	mirar.Inicializar(mirar_semana*7+i,(j+1)*5)
	if(!hoy.Comparar_Dos_Fechas(mirar)):
		excepcion=false
		
	
	

func _Formatear_Nombre_Actividad(nombre: String) -> String:
	if nombre == "":
		return "Tiempo libre"
	if nombre == "Actividad_Aleatoria":
		return "Actividad aleatoria"
	if nombre == "Examen_Carrera":
		return "Examen"
	return nombre.replace("Trabajar_En_", "").replace("Trabajar_De_", "").replace("_", " ")


func click_bloque(boton,raiz):
	bloque_columna.desactivar_todos_los_botones()
	
	boton.set_toggle_mode(true)
	boton.set_pressed(true)
	
	comprobar_color_boton_seleccionado(boton,raiz)
	comprobar_izquierda(boton,raiz)
	comprobar_derecha(boton,raiz)
	var act_meta = boton.get_meta("actividad")
	var estado = boton.get_meta("estado", "")
	var texto_sel := ""
	if estado == "pasado":
		texto_sel = "Bloque pasado"
	elif act_meta is String:
		texto_sel = _Formatear_Nombre_Actividad(act_meta)
	else:
		texto_sel = _Formatear_Nombre_Actividad(str(act_meta.nombre))
	raiz.get_node("Actividades/Horario_Semanal/OPCIONES_CALENDARIO/Actividad_Texto").text = texto_sel
func comprobar_izquierda(boton,raiz):
	var comprobar_izq=true
	var ver_dia=primer_dia_comprobar(boton,raiz)
	while(ver_dia!="" and comprobar_izq==true):
		var boton2=obtener_ultimo_bloques_dia(ver_dia,raiz)
		comprobar_izq=fusinar_botones(boton,boton2)
		boton=boton2
		ver_dia=primer_dia_comprobar(boton,raiz)
func comprobar_derecha(boton,raiz):
	var comprobar_der=true
	var ver_dia=ultimo_dia_comprobar(boton,raiz)
	while(ver_dia!="" and comprobar_der==true):
		var boton2=obtener_primer_bloque_dia(ver_dia,raiz)
		comprobar_der=fusinar_botones(boton,boton2)
		boton=boton2
		ver_dia=ultimo_dia_comprobar(boton,raiz)
func fusinar_botones(boton1,boton2):
	var act1 = boton1.get_meta("actividad", null)
	var act2 = boton2.get_meta("actividad", null)
	var est1 = boton1.get_meta("estado", "")
	var est2 = boton2.get_meta("estado", "")
	if typeof(act1) == typeof(act2) and act1 == act2 and est1 == est2:
		boton2.set_pressed(true)
		boton2.set_toggle_mode(true)
		return true
	else: return false
func obtener_primer_bloque_dia(dia,raiz):
	var vbox_cont = raiz.get_node(NodePath("Actividades/Horario_Semanal/Mover_Vertical/Todo calendario/Dias/" + dia))
	return(vbox_cont.get_child(0))
func obtener_ultimo_bloques_dia(dia,raiz):
	var vbox_cont = raiz.get_node(NodePath("Actividades/Horario_Semanal/Mover_Vertical/Todo calendario/Dias/" + dia))
	return(vbox_cont.get_child(vbox_cont.get_child_count() - 1))
func primer_dia_comprobar(boton,raiz):
	var bloques_list=devolver_primeros_botones(raiz)
	var dia=""
	for i in range(1,7):
		if bloques_list[i-1]==boton:
			dia=Funciones_Globales.Devolver_Dia(i-1)
	return dia
func ultimo_dia_comprobar(boton,raiz):
	var bloques_list=devolver_ultimos_botones(raiz)
	var dia=""
	
	for i in 6:
		if bloques_list[i]==boton:
			dia=Funciones_Globales.Devolver_Dia(i+1)
	return dia
func devolver_ultimos_botones(raiz):
	var bloque_list = []
	for i in 6:
		var dia=Funciones_Globales.Devolver_Dia(i)
		var vbox_cont = raiz.get_node(NodePath("Actividades/Horario_Semanal/Mover_Vertical/Todo calendario/Dias/" + dia))
		bloque_list.append(vbox_cont.get_child(vbox_cont.get_child_count() - 1))
	return bloque_list
func devolver_primeros_botones(raiz):
	var bloque_list = []
	for i in range (1,7):
		var dia=Funciones_Globales.Devolver_Dia(i)
		var vbox_cont = raiz.get_node(NodePath("Actividades/Horario_Semanal/Mover_Vertical/Todo calendario/Dias/" + dia))
		bloque_list.append(vbox_cont.get_child(0))
	return bloque_list

func comprobar_color_boton_seleccionado(boton,raiz):
	var estado = boton.get_meta("estado", "libre")
	if estado == "libre":
		verde_seleccionado(raiz)
	elif estado == "ocupado":
		rojo_seleccionado(raiz)
	elif estado == "pasado":
		azul_seleccionado(raiz)

func verde_seleccionado(raiz):
	devolver_boton_ocupar_actividad(raiz).visible = not raiz.calendario_solo_lectura
	devolver_boton_eliminar_actividad(raiz).visible=false

func rojo_seleccionado(raiz):
	devolver_boton_eliminar_actividad(raiz).visible=true
	devolver_boton_ocupar_actividad(raiz).visible=false

func azul_seleccionado(raiz):
	devolver_boton_ocupar_actividad(raiz).visible=false
	devolver_boton_eliminar_actividad(raiz).visible=false

func devolver_boton_ocupar_actividad(raiz):
	return Gestionar_Visibilidad.devolver_boton_ocupar_actividad(raiz)

func devolver_boton_eliminar_actividad(raiz):
	return Gestionar_Visibilidad.devolver_boton_eliminar_actividad(raiz)

## on_ocupar_actividad_pressed
func devolver_hora_desde_posiciones():
	var dia_inicio_string=Funciones_Globales.Devolver_Dia(dia_inicio)
	var cincominuto_inicio=roundi(posicion_minuto_inicio/5.0)
	var hora_inicio=int(cincominuto_inicio/12)
	var minuto_inicio=int(cincominuto_inicio%12)*5
	var cincominuto_final=roundi(posicion_minuto_final/5.0)
	var dia_final_res: int = dia_final
	var hora_final=int(cincominuto_final/12)
	var minuto_final=int(cincominuto_final%12)*5
	if cincominuto_final >= 288:
		if dia_final_res < 6:
			dia_final_res += 1
			hora_final = 0
			minuto_final = 0
		else:
			hora_final = 24
			minuto_final = 0
	var dia_final_string=Funciones_Globales.Devolver_Dia(dia_final_res)
	
	var horariobloque=HorarioDesdeBloque.new()
	horariobloque.Inicializar(dia_inicio_string,hora_inicio,minuto_inicio,dia_final_string,hora_final,minuto_final)
	return horariobloque
func comprobar_seleccionado():
	presionado=false
	var verde=false
	posicion_minuto_inicio=-1
	dia_inicio=-1
	if(
	comprobar_seleccionado_dia(bloque_columna.lunes_columna) and
	comprobar_seleccionado_dia(bloque_columna.martes_columna) and
	comprobar_seleccionado_dia(bloque_columna.miercoles_columna) and
	comprobar_seleccionado_dia(bloque_columna.jueves_columna) and
	comprobar_seleccionado_dia(bloque_columna.viernes_columna) and
	comprobar_seleccionado_dia(bloque_columna.sabado_columna) and
	comprobar_seleccionado_dia(bloque_columna.domingo_columna) 
	):
		verde=true
	if(verde and presionado):
		return true
	else: return false
func comprobar_seleccionado_dia(dia):
	var verde=true
	for child in dia.get_children():
		if child is Button:
			if child.button_pressed:
					presionado=true
					dia_final=calcular_dia(dia)
					posicion_minuto_final=child.position.y+int(child.size.y)
					if(dia_inicio==-1):
						dia_inicio=calcular_dia(dia)
						posicion_minuto_inicio=child.position.y
					if child.get_meta("estado", "") == "pasado":
						verde=false
	return verde
func calcular_dia(dia):
	if dia==bloque_columna.lunes_columna:
		return 0
	if dia==bloque_columna.martes_columna:
		return 1
	if dia==bloque_columna.miercoles_columna:
		return 2
	if dia==bloque_columna.jueves_columna:
		return 3
	if dia==bloque_columna.viernes_columna:
		return 4
	if dia==bloque_columna.sabado_columna:
		return 5
	if dia==bloque_columna.domingo_columna:
		return 6
