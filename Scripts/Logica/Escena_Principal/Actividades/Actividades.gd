extends Node

func Ejecutar_Actividad(Actividad):
	#Trabajo
	if(Actividad=="Trabajar_En_Comida_Rapida"):
		Actividades_Necesidades_Basicas.Ejecutar_Actividad_Necesidades_Basicas_Array([-1,-1,-1,-2,-1])
		Actividades_Habilidades.Ejecutar_Actividad_Progreso_Array([0,0,0])
		
		
		#Aumentan Habilidades
	if (Actividad=="Estudiar"):
		Actividades_Necesidades_Basicas.Ejecutar_Actividad_Necesidades_Basicas_Array([-1,-2,-1,-2,-1])
		Actividades_Habilidades.Ejecutar_Actividad_Progreso_Array([0,4,0])
	if (Actividad=="Salir_A_Correr"):
		Actividades_Necesidades_Basicas.Ejecutar_Actividad_Necesidades_Basicas_Array([4,2,-3,-3,-4])
		Actividades_Habilidades.Ejecutar_Actividad_Progreso_Array([4,0,0])
	if (Actividad=="Practicar_Manualidades"):
		Actividades_Necesidades_Basicas.Ejecutar_Actividad_Necesidades_Basicas_Array([-2,-1,-1,-2,-1])
		Actividades_Habilidades.Ejecutar_Actividad_Progreso_Array([0,0,4])
	#Afectan Necesidades Fisicas
	
	if (Actividad=="Duchar"):
		Actividades_Necesidades_Basicas.Ejecutar_Actividad_Necesidades_Basicas_Array([1,1,-1,-1,20])
	if(Actividad=="Dormir"):
		Actividades_Necesidades_Basicas.Ejecutar_Actividad_Necesidades_Basicas_Array([1,1,-1,4,-1])
	if(Actividad=="Comer"):
		Actividades_Necesidades_Basicas.Ejecutar_Actividad_Necesidades_Basicas_Array([-1,2,20,-1,-1])
	if(Actividad=="Ver_La_Television"):
		Actividades_Necesidades_Basicas.Ejecutar_Actividad_Necesidades_Basicas_Array([-1,5,-1,2,-1])



func Crear_Actividad_Aleatoria():
	var necesidad_baja=100
	var ind_baja
	for i in range (0,Variables_Dinamicas.Necesidades_Basicas.size()):
		if(Variables_Dinamicas.Necesidades_Basicas[i]<necesidad_baja):
			necesidad_baja=Variables_Dinamicas.Necesidades_Basicas[i]
			ind_baja=i

	if(necesidad_baja<30):
		return Crear_Actividad_Aleatoria_Debajo_De_30(ind_baja)
	else:
		return Crear_Actividad_Aleatoria_Mas_De_30()

func Crear_Actividad_Aleatoria_Debajo_De_30(indice):
	if(indice==0):
		return "Salir_A_Correr"
	elif(indice==1):
		return "Ver_La_Television"
	elif (indice==2):
		return "Comer"
	elif (indice==3):
		return "Dormir"
	elif (indice==4):
		return "Duchar"

func Crear_Actividad_Aleatoria_Mas_De_30():
	var personalidad=Variables_Estaticas.Personalidad
	var valor=Funciones_Globales.Generar_Numero_Aleatorio_Entero(0,Variables_Estaticas.Actividades.size()*2)
	if(valor>=Variables_Estaticas.Actividades.size()):
		if(personalidad=="Trabajador_Compulsivo"):
			return "Estudiar"
		if(personalidad=="Deportista"):
			return "Salir_A_Correr"
		if(personalidad=="Culo_Del_Sofa"):
			return "Ver_La_Television"
	else:
		return Variables_Estaticas.Actividades[valor]
	
func Crear_Actividad_Especifica(semana,dia_inicio,dia_final,hora_inicio,hora_final,minuto_inicio,minuto_final,actividad):
	var i_inicio=semana*7+dia_inicio
	var i_final=semana*7+dia_final
	var j_inicio=hora_inicio*60+minuto_inicio
	var j_final=hora_final*60+minuto_final
	var seguir=true
	while(seguir):
		if(j_final==0):
			if(i_inicio+1>=i_final):
				if(j_inicio>=1439):
					seguir=false
			elif j_inicio>=1440:
				i_inicio+=1
				j_inicio=0
		else:
			if(i_inicio>=i_final):
				if(j_inicio+1>=j_final):
					seguir=false
			elif j_inicio>=1440:
				i_inicio+=1
				j_inicio=0
		Crear_Actividad(i_inicio,j_inicio,actividad)
		j_inicio+=1
	Guardar_Variables_Estaticas.save_game()
	Guardar_Variables_Dinamicas.save_game()
func Crear_Actividad(i,j,actividad):
	Variables_Dinamicas.Matriz_Jugador[j][i]=actividad



func Actualizar_Horario(minuto_actual):
	var diferencia=minuto_actual-Variables_Dinamicas.Minute
	
	for i in range(0,diferencia+1):             #+1 para que cuando sea 00:00 por ejemplo, tambien ocupe la casilla numero 0. Si se quiere que cuando sea 00:01 cambiar la casilla 0, entonces hay que quitar ese +1.       
		#en _delta si quiere cambiar a como estaba antes, se tiene que hacer if(minuto_actual-Variables_Dinamicas.Minute!=0) para conseguir una mejor opcimizacion
		if(Variables_Dinamicas.Matriz_Jugador[Variables_Dinamicas.Minute_Minute][Variables_Dinamicas.Minute_Day]==""):
			Variables_Dinamicas.Matriz_Jugador[Variables_Dinamicas.Minute_Minute][Variables_Dinamicas.Minute_Day]="Actividad_Aleatoria"
		Actividades.Ejecutar_Actividad(Crear_Actividad_Aleatoria())
		
		if(Variables_Dinamicas.Minute_Minute==1439):
			Variables_Dinamicas.Minute_Day=Variables_Dinamicas.Minute_Day+1
			Variables_Dinamicas.Minute_Minute=0
		else:
			Variables_Dinamicas.Minute_Minute=Variables_Dinamicas.Minute_Minute+1
			
		Variables_Dinamicas.Minute=Variables_Dinamicas.Minute+1
	Funciones_Globales.Guardar_Matriz()
