extends Node

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

		var texto = "%02d:%02d - %02d:%02d" % [hora_inicio, minuto_inicio, hora_final, minuto_final]

		var boton = Button.new()
		boton.mouse_filter=Control.MOUSE_FILTER_PASS
		boton.text = texto
		boton.connect("pressed", Callable(self, "_on_button_pressed"))  # clásico
		
		
		var estilo = StyleBoxFlat.new()
		# estilo.bg_color = Color(0.8, 0.8, 0.8)  Para poner un color al boton
		estilo.corner_radius_top_left = 0
		estilo.corner_radius_top_right = 0
		estilo.corner_radius_bottom_left = 0
		estilo.corner_radius_bottom_right = 0
		
		estilo.border_width_left = 1
		estilo.border_width_right = 1
		estilo.border_width_bottom = 2
		
		estilo.border_color = Color.BLACK  
		
		
		boton.add_theme_stylebox_override("normal",estilo)
		boton.add_theme_stylebox_override("hover", estilo)
		boton.custom_minimum_size=Vector2(0,60)
		bloque_columna.horario_columna.add_child(boton)
func Agregar_Bloques(mirar_semana,raiz):
	matriz_bloques=Funciones_Globales.Devolver_Bloque_Matriz_Semana_(mirar_semana)
	excepcion=true

	
	raiz=raiz
	
	for i in range (7):
		
		libre=matriz_bloques[0][i]
		ultimo_diferente=false
		var j=0
		
		while(j!=288):
				
				if(excepcion==true):
					
					AgregarBloquesPasados(i,j,mirar_semana)
					if((excepcion==false and tamaño_bloque>0)or j==287):
						CrearNuevosBotones(i,j,raiz,true)
					elif(libre!=matriz_bloques[j][i]):
						CrearNuevosBotones(i,j,raiz,true)
						libre=matriz_bloques[j][i]
						
					
						
					else: tamaño_bloque+=1
				else:
					if(libre==null):
						libre=matriz_bloques[j][i]
					if(libre==matriz_bloques[j][i] and j!=287):
						tamaño_bloque+=1
					else:
						CrearNuevosBotones(i,j,raiz,false)
				j+=1


func CrearNuevosBotones(i,j,raiz,crear_boton_del_pasado):
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
					
					if(crear_boton_del_pasado):
						estilo.bg_color = Color(0, 0, 1)   # azul
						estilo_pulsado.bg_color= Color(0, 0, 0.5)  # Azul oscuro
					elif(libre==""):
						estilo.bg_color = Color(0, 1, 0)   # verde
						estilo_pulsado.bg_color= Color(0, 0.5, 0)  # Verde oscuro
					else:
						estilo.bg_color = Color(1, 0, 0)   # rojo
						estilo_pulsado.bg_color=Color(0.5, 0, 0)
					boton.add_theme_stylebox_override("normal",estilo)
					boton.add_theme_stylebox_override("pressed", estilo_pulsado)
					
					boton.set_meta("actividad", libre)   #crear un "atributo" llamado "actividad" al boton, y darle el valor de libre
					
					
					boton.add_theme_stylebox_override("hover", estilo)
					boton.add_theme_stylebox_override("hover_pressed", estilo_pulsado)
					boton.toggle_mode = true
					
					
					
					
					if(libre!=matriz_bloques[j][i] and crear_boton_del_pasado==false):
						boton.custom_minimum_size=Vector2(0,10*(tamaño_bloque))
						libre=matriz_bloques[j][i]
						tamaño_bloque=1
						if(ultimo_diferente==false and j==287):
							ultimo_diferente=true
							tamaño_bloque=0
							CrearNuevosBotones(i,j,raiz,crear_boton_del_pasado)
							
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

func AgregarBloquesPasados(i,j,mirar_semana):
	var hoy=fecha.new()
	hoy.Inicializar(Variables_Dinamicas.Minute_Day,Variables_Dinamicas.Minute_Minute)
	var mirar=fecha.new()
	mirar.Inicializar(mirar_semana*7+i,(j+1)*5)
	if(!hoy.Comparar_Dos_Fechas(mirar)):
		excepcion=false
		
	
	

func click_bloque(boton,raiz):
	bloque_columna.desactivar_todos_los_botones()
	
	boton.set_toggle_mode(true)
	boton.set_pressed(true)
	
	comprobar_color_boton_seleccionado(boton,raiz)
	comprobar_izquierda(boton,raiz)
	comprobar_derecha(boton,raiz)
	raiz.get_node("Actividades/Horario_Semanal/OPCIONES_CALENDARIO/Actividad_Texto").text=boton.get_meta("actividad")
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
	var stylebox1=boton1.get_theme_stylebox("normal", "Button")
	var stylebox2=boton2.get_theme_stylebox("normal", "Button")
	if (stylebox1.bg_color==stylebox2.bg_color and (boton1.get_meta("actividad")==boton2.get_meta("actividad"))):
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
	var estilo_normal = boton.get_theme_stylebox("normal", "Button")
	if estilo_normal is StyleBoxFlat and estilo_normal.bg_color == Color(0, 1, 0):
		verde_seleccionado(raiz)
	elif estilo_normal is StyleBoxFlat and estilo_normal.bg_color == Color(1, 0, 0):
		rojo_seleccionado(raiz)
	elif  estilo_normal is StyleBoxFlat and estilo_normal.bg_color == Color(0, 0, 1):
		azul_seleccionado(raiz)

func verde_seleccionado(raiz):
	devolver_boton_ocupar_actividad(raiz).visible=true
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
	var rojo=true
	for child in dia.get_children():
		if child is Button:
			if child.button_pressed:
					presionado=true
					var stylebox=child.get_theme_stylebox("normal", "Button")
					var color=stylebox.bg_color
					var color_verde_claro=Color(0,1,0)
					var color_rojo_claro=Color(1,0,0)
					dia_final=calcular_dia(dia)
					posicion_minuto_final=child.position.y+int(child.size.y)
					if(dia_inicio==-1):
						dia_inicio=calcular_dia(dia)
						posicion_minuto_inicio=child.position.y
					if(color!=color_verde_claro and color!=color_rojo_claro):
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
