extends Node

var horario :SeleccionarHorarioReloj
var horariobloque :HorarioDesdeBloque



func Comprobar_Visibilidad(raiz,horarioblquee):
	horario=SeleccionarHorarioReloj.new()
	horario.inicializar(raiz)
	horariobloque=horarioblquee
	Comprobar_Visibilidad_Abajo_Inicio()
	Comprobar_Visibilidad_Arriba_Final()
	Comprobar_Visibilidad_Medio()
	UltimaComprobacion()
	horario.Actualizar_Todo_Contexto()


func Comprobar_Visibilidad_Abajo_Inicio():
	
	if horario.dia_inicio_a_int()==horariobloque.dia_inicio_int() :  #Comprobar dia
		Funciones_Globales.Desvisibilizar_Objeto([horario.dia_inicio_abajo])
		if horario.hora_inicio_texto.text.to_int()<=horariobloque.hora_inicio:   #Comprobar hora
			DesvisibilizarObjetoYCambiarTexto(horario.hora_inicio_abajo,horario.hora_inicio_texto,horariobloque.hora_inicio)
			if horario.minuto_inicio_texto.text.to_int()<=horariobloque.minuto_inicio:   #Comprobar minuto
				DesvisibilizarObjetoYCambiarTexto(horario.minuto_inicio_abajo,horario.minuto_inicio_texto,horariobloque.minuto_inicio)
			else: Funciones_Globales.Visibilizar_Objeto([horario.minuto_inicio_abajo]) 
		else: Funciones_Globales.Visibilizar_Objeto([horario.hora_inicio_abajo,horario.minuto_inicio_abajo])
	else: Funciones_Globales.Visibilizar_Objeto([horario.dia_inicio_abajo,horario.hora_inicio_abajo,horario.minuto_inicio_abajo])

func Comprobar_Visibilidad_Arriba_Final():
	
	if horario.dia_final_a_int()==horariobloque.dia_final_int():
		Funciones_Globales.Desvisibilizar_Objeto([horario.dia_final_arriba]) 
		if horario.hora_final_texto.text.to_int()>=horariobloque.hora_final:
			DesvisibilizarObjetoYCambiarTexto(horario.hora_final_arriba,horario.hora_final_texto,horariobloque.hora_final)
			if horario.minuto_final_texto.text.to_int()>=horariobloque.minuto_final:
				DesvisibilizarObjetoYCambiarTexto(horario.minuto_final_arriba,horario.minuto_final_texto,horariobloque.minuto_final)
			else: Funciones_Globales.Visibilizar_Objeto([horario.minuto_final_arriba])
		else: Funciones_Globales.Visibilizar_Objeto([horario.minuto_final_arriba,horario.hora_final_arriba])
	else: 
		Funciones_Globales.Visibilizar_Objeto([horario.dia_final_arriba,horario.hora_final_arriba,horario.minuto_final_arriba])


func Comprobar_Visibilidad_Medio():
	
	if(horario.dia_inicio_a_int()==horario.dia_final_a_int()):
		Funciones_Globales.Desvisibilizar_Objeto([horario.dia_inicio_arriba,horario.dia_final_abajo])
		Comprobar_Extremos_Hora_Mismo_Dia()
		if(horario.minuto_final_texto.text.to_int()==0): Comprobar_Minuto_Final_Cero()
		elif(horario.hora_inicio_texto.text.to_int()>horario.hora_final_texto.text.to_int()):
			DesvisibilizarArrayObjetoYCambiarArrayTexto([horario.hora_inicio_arriba,horario.hora_final_abajo],
			[horario.hora_inicio_texto,horario.minuto_inicio_texto],
			[horario.hora_final_texto.text.to_int(),horario.minuto_final_texto.text.to_int()-5])
		elif(horario.hora_inicio_texto.text.to_int()==horario.hora_final_texto.text.to_int()):
			Funciones_Globales.Desvisibilizar_Objeto([horario.hora_inicio_arriba,horario.hora_final_abajo])
			Comprobar_Minutos_Limite_Mismo_Dia_Hora()
			if(horario.minuto_inicio_texto.text.to_int()+5>=horario.minuto_final_texto.text.to_int()):
				DesvisibilizarArrayObjetoYCambiarTexto([horario.minuto_inicio_arriba,horario.minuto_final_abajo],horario.minuto_inicio_texto,horario.minuto_final_texto.text.to_int()-5)
				print(horario.minuto_inicio_texto)
			else:
				Funciones_Globales.Visibilizar_Objeto([horario.minuto_inicio_arriba,horario.minuto_final_abajo])
		else:
			Funciones_Globales.Visibilizar_Objeto([horario.minuto_inicio_arriba,horario.hora_inicio_arriba,horario.minuto_final_abajo,horario.hora_final_abajo])
	else:
		Funciones_Globales.Visibilizar_Objeto([horario.minuto_inicio_arriba,horario.hora_inicio_arriba,horario.dia_inicio_arriba,horario.minuto_final_abajo,horario.hora_final_abajo,horario.dia_final_abajo])
	Comprobar_Extremos_Dia_Cuando_Hora_Y_Minuto_Cero()
	Comprobar_Fecha_Final_Domingo_Medianoche_Final() #Lo pongo aqui porque si pongo en Comprobar_Visibilidad_Abajo_Inicio() luego este metodo, hace visible a horario.minuto_final_abajo




func Comprobar_Minutos_Limite_Mismo_Dia_Hora():  #Si el inicial y el final tienen el mismo dia y hora, cuando minuto inicial este en 0, no podra bajar, y si minuto inicial esta en 55 no podra subir
	if(horario.minuto_inicio_texto.text.to_int()==0): Funciones_Globales.Desvisibilizar_Objeto([horario.minuto_inicio_abajo])
	if(horario.minuto_final_texto.text.to_int()==55): Funciones_Globales.Desvisibilizar_Objeto([horario.minuto_final_arriba])


func Comprobar_Minuto_Final_Cero():   #Comprobar si minuto_final es 00. Si es asi, cuando sea el mismo dia y una hora menos, no se podra subir la hora inicial
		if(horario.hora_inicio_texto.text.to_int()+1>=horario.hora_final_texto.text.to_int()):
				DesvisibilizarArrayObjetoYCambiarTexto([horario.hora_inicio_arriba,horario.hora_final_abajo],horario.hora_inicio_texto,horario.hora_final_texto.text.to_int()-1)




func Comprobar_Extremos_Hora_Mismo_Dia(): #Si estan en el mismo dia, cuando hora_inicial este en 0 no podra bajar la hora, y si la hora_final esta en 23 o 24, no se podra subir mas la hora
	#Visibilidad de Hora_Inicio
	if(horario.hora_inicio_texto.text.to_int()==0): Funciones_Globales.Desvisibilizar_Objeto([horario.hora_inicio_abajo])
	
	#Visibilidad de Hora_Final
	if(horario.hora_final_texto.text.to_int()==23 or horario.hora_final_texto.text.to_int()==24): Funciones_Globales.Desvisibilizar_Objeto([horario.hora_final_arriba])



func Comprobar_Extremos_Dia_Cuando_Hora_Y_Minuto_Cero():  #Cuando la fecha final sea x 0:0, si el dia inicial es x-1, no se podra subir el dia inicial ni tampoco bajar el dia_final 
		if(horario.hora_final_texto.text.to_int()==0 and horario.minuto_final_texto.text.to_int()==0):
			if(horario.dia_inicio_a_int()+1>= horario.dia_final_a_int()):
				Funciones_Globales.Desvisibilizar_Objeto([horario.dia_final_abajo,horario.dia_inicio_arriba])


func Comprobar_Fecha_Final_Domingo_Medianoche_Final():   #Cuando la fecha final sea Domingo 24:00, no se podra cambiar el minuto, y ni subir la hora ni el dia
	if(horario.dia_final_a_int()==6 and horario.hora_final_texto.text==str(24)):
		Funciones_Globales.Desvisibilizar_Objeto([horario.minuto_final_abajo,horario.minuto_final_arriba,horario.hora_final_arriba,horario.dia_final_arriba])


func UltimaComprobacion():
	if(Comparar_Horas_Ini(horariobloque.dia_inicio_int(),horariobloque.hora_inicio,horariobloque.minuto_inicio,horario.dia_inicio_a_int(),horario.hora_inicio_texto.text.to_int(),horario.minuto_inicio_texto.text.to_int(),false)):   #Comprobar_Inicio
		Restart()
	elif(Comparar_Horas_Ini(horario.dia_final_a_int(),horario.hora_final_texto.text.to_int(),horario.minuto_final_texto.text.to_int(),horariobloque.dia_final_int(),horariobloque.hora_final,horariobloque.minuto_final,false)):      #Comprobar_Final
		Restart()
	elif(Comparar_Horas_Ini(horario.dia_inicio_a_int(),horario.hora_inicio_texto.text.to_int(),horario.minuto_inicio_texto.text.to_int(),horario.dia_final_a_int(),horario.hora_final_texto.text.to_int(),horario.minuto_final_texto.text.to_int(),true)): #Comprobar_Medio
		Restart()
	Comprobar_Negativos()



func Restart():
	horario.dia_inicio_texto.text=Funciones_Globales.Devolver_Dia_Reducido(horariobloque.dia_inicio_int())
	horario.hora_inicio_texto.text=str(horariobloque.hora_inicio)
	horario.minuto_inicio_texto.text=str(horariobloque.minuto_inicio)
	
	horario.dia_final_texto.text=Funciones_Globales.Devolver_Dia_Reducido(horariobloque.dia_final_int())
	horario.hora_final_texto.text=str(horariobloque.hora_final)
	horario.minuto_final_texto.text=str(horariobloque.minuto_final)
	
	Comprobar_Visibilidad_Abajo_Inicio()
	Comprobar_Visibilidad_Arriba_Final()
	Comprobar_Visibilidad_Medio()

func Comparar_Horas_Ini(dia_ini,hora_ini,min_ini,dia_fin,hora_fin,min_fin,comprobacion_medio):   
	
	if(dia_ini>dia_fin):
		return true
	elif(dia_ini<dia_fin):
		return false
	elif(hora_ini>hora_fin):
		return true
	elif(hora_ini<hora_fin):
		return false
	elif(min_ini>=min_fin and comprobacion_medio):
		return true
	elif(min_ini>min_fin and !comprobacion_medio):
		return true
	else: return false



func Comprobar_Negativos():
	if (horario.dia_inicio_a_int()==-1 or horario.dia_final_a_int()==-1): return true
	if (horario.hora_inicio_texto.text.to_int()<0 or horario.hora_inicio_texto.text.to_int()>=24): return true
	if (horario.minuto_inicio_texto.text.to_int()<0 or horario.minuto_inicio_texto.text.to_int()>60): return true
	if (horario.dia_final_a_int()==6):
		if (horario.hora_final_texto.text.to_int()>24 or horario.hora_final_texto.text.to_int()<0): return true
	else: 
		if (horario.hora_final_texto.text.to_int()>=24 or horario.hora_final_texto.text.to_int()<0): return true
	if (horario.minuto_final_texto.text.to_int()<0 or horario.minuto_final_texto.text.to_int()>60): return true
	return false

func DesvisibilizarObjetoYCambiarTexto(boton,texto_objeto,texto):
	DesvisibilizarArrayObjetoYCambiarTexto([boton],texto_objeto,texto)

func  DesvisibilizarArrayObjetoYCambiarTexto(arrayboton,texto_objeto,texto):
	for boton in arrayboton:
		Funciones_Globales.Desvisibilizar_Objeto([boton])
	texto_objeto.text=str(texto)

func DesvisibilizarArrayObjetoYCambiarArrayTexto(arrayboton,array_texto_objeto,array_texto):
	for boton in arrayboton:
		Funciones_Globales.Desvisibilizar_Objeto([boton])
	for i in array_texto_objeto.size():
		array_texto_objeto[i].text=str(array_texto[i])
