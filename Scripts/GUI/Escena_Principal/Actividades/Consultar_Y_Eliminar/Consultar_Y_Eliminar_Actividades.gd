extends Node

const COLOR_LIBRE   = Color(0.08, 0.65, 0.42, 1)
const COLOR_OCUPADO = Color(0.75, 0.18, 0.2,  1)
const COLOR_LIBRE_P   = Color(0.04, 0.38, 0.24, 1)
const COLOR_OCUPADO_P = Color(0.42, 0.08, 0.1,  1)

var bloque_columna

var semana
var presionado
var posicion_minuto_inicio
var dia_inicio
var posicion_minuto_final
var dia_final
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

		var texto = "%02d:%02d - %02d:%02d" % [hora_inicio, minuto_inicio, hora_final, minuto_final]

		var boton = Button.new()
		boton.mouse_filter=Control.MOUSE_FILTER_PASS
		boton.text = texto
		boton.connect("pressed", Callable(self, "_on_button_pressed"))  # clásico
		
		
		var estilo = StyleBoxFlat.new()
		estilo.bg_color = Color(0.42, 0.48, 0.56, 1)
		estilo.corner_radius_top_left = 0
		estilo.corner_radius_top_right = 0
		estilo.corner_radius_bottom_left = 0
		estilo.corner_radius_bottom_right = 0
		estilo.border_width_left = 0
		estilo.border_width_right = 1
		estilo.border_width_bottom = 1
		estilo.border_width_top = 0
		estilo.border_color = Color(0.28, 0.33, 0.4, 1)
		boton.add_theme_stylebox_override("normal", estilo)
		boton.add_theme_stylebox_override("hover", estilo)
		boton.add_theme_color_override("font_color", Color(0.95, 0.97, 1, 1))
		boton.add_theme_font_size_override("font_size", 15)
		boton.custom_minimum_size=Vector2(0,60)
		bloque_columna.horario_columna.add_child(boton)
func Agregar_Bloques(mirar_semana,raiz):
	var matriz_bloques=Funciones_Globales.Devolver_Bloque_Matriz_Semana_(mirar_semana)
	var tamaño_bloque=0
	
	
	for i in range (7):
		var libre=matriz_bloques[0][i]
		var ultimo_diferente=false
		var j=0
		while(j!=288):
				if(libre==matriz_bloques[j][i] and j!=287):
					tamaño_bloque+=1
				else:
					var boton=Button.new()
					boton.mouse_filter=Control.MOUSE_FILTER_PASS
					boton.focus_mode=Control.FOCUS_NONE
					boton.connect("button_up", Callable(self, "desactivar_todos_los_botones").bind(boton,raiz))  # clásico
					boton.connect("pressed", Callable(self, "click_bloque").bind(boton,raiz))  # clásico
					var estilo = StyleBoxFlat.new()
					estilo.set_border_width_all(1)
					estilo.border_color = Color(0.1, 0.1, 0.1)
					
					var estilo_pulsado= StyleBoxFlat.new()
					estilo_pulsado.set_border_width_all(0)
					estilo_pulsado.border_color = Color(0, 0, 0, 0)
					
					
					if(libre==""):
						estilo.bg_color = COLOR_LIBRE
						estilo_pulsado.bg_color = COLOR_LIBRE_P
					else:
						estilo.bg_color = COLOR_OCUPADO
						estilo_pulsado.bg_color = COLOR_OCUPADO_P
					boton.add_theme_stylebox_override("normal",estilo)
					boton.add_theme_stylebox_override("pressed", estilo_pulsado)
					
					
					
					boton.add_theme_stylebox_override("hover", estilo)
					boton.add_theme_stylebox_override("hover_pressed", estilo_pulsado)
					boton.toggle_mode = true
					
					
					if(libre!=matriz_bloques[j][i]):
						
						boton.custom_minimum_size=Vector2(0,10*(tamaño_bloque))
						libre=matriz_bloques[j][i]
						tamaño_bloque=1
						if(ultimo_diferente==false and j==287):
							ultimo_diferente=true
							j=286
							tamaño_bloque=0
					else:
						boton.custom_minimum_size=Vector2(0,10*(1+tamaño_bloque)) 
						tamaño_bloque=0
					
					
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
				j+=1
func click_bloque(boton,raiz):
	bloque_columna.desactivar_todos_los_botones()
	
	boton.set_toggle_mode(true)
	boton.set_pressed(true)
	
	comprobar_izquierda(boton,raiz)
	comprobar_derecha(boton,raiz)
func comprobar_izquierda(boton,raiz):
	var ver_dia=primer_dia_comprobar(boton,raiz)
	while(ver_dia!=""):
		var boton2=obtener_ultimo_bloques_dia(ver_dia,raiz)
		fusinar_botones(boton,boton2)
		boton=boton2
		ver_dia=primer_dia_comprobar(boton,raiz)
func comprobar_derecha(boton,raiz):
	var ver_dia=ultimo_dia_comprobar(boton,raiz)
	while(ver_dia!=""):
		var boton2=obtener_primer_bloque_dia(ver_dia,raiz)
		fusinar_botones(boton,boton2)
		boton=boton2
		ver_dia=ultimo_dia_comprobar(boton,raiz)
func fusinar_botones(boton1,boton2):
	var stylebox1=boton1.get_theme_stylebox("normal", "Button")
	var stylebox2=boton2.get_theme_stylebox("normal", "Button")
	if (stylebox1.bg_color==stylebox2.bg_color):
		boton2.set_pressed(true)
		boton2.set_toggle_mode(true)
func obtener_primer_bloque_dia(dia,raiz):
	var vbox_cont = raiz.get_node(NodePath("Horario_Semanal/Mover_Vertical/Todo calendario/Dias/" + dia))
	return(vbox_cont.get_child(0))
func obtener_ultimo_bloques_dia(dia,raiz):
	var vbox_cont = raiz.get_node(NodePath("Horario_Semanal/Mover_Vertical/Todo calendario/Dias/" + dia))
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
		var vbox_cont = raiz.get_node(NodePath("Horario_Semanal/Mover_Vertical/Todo calendario/Dias/" + dia))
		bloque_list.append(vbox_cont.get_child(vbox_cont.get_child_count() - 1))
	return bloque_list
func devolver_primeros_botones(raiz):
	var bloque_list = []
	for i in range (1,7):
		var dia=Funciones_Globales.Devolver_Dia(i)
		var vbox_cont = raiz.get_node(NodePath("Horario_Semanal/Mover_Vertical/Todo calendario/Dias/" + dia))
		bloque_list.append(vbox_cont.get_child(0))
	return bloque_list



## on_ocupar_actividad_pressed
func devolver_hora_desde_posiciones():
	var dia_inicio_string=Funciones_Globales.Devolver_Dia(dia_inicio)
	var dia_final_string=Funciones_Globales.Devolver_Dia(dia_final)
	var cincominuto_inicio=int(posicion_minuto_inicio/10)
	var hora_inicio=int(cincominuto_inicio/12)
	var minuto_inicio=int(cincominuto_inicio%12)*5
	var cincominuto_final=int(posicion_minuto_final/10)
	var hora_final=int(cincominuto_final/12)
	var minuto_final=int(cincominuto_final%12)*5
	
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
					var stylebox=child.get_theme_stylebox("normal", "Button")
					var color=stylebox.bg_color
					dia_final=calcular_dia(dia)
					posicion_minuto_final=child.position.y+int(child.size.y)
					if(dia_inicio==-1):
						dia_inicio=calcular_dia(dia)
						posicion_minuto_inicio=child.position.y
					if(color!=COLOR_LIBRE):
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
