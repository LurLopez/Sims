extends Node

func First_Time_Function():
		Crear_Matriz()
		Crear_Personalidad()
		Crear_Habilidades()
		Crear_Habilidades_Mostradas()
		Crear_Necesidades_Basicas()
		Crear_Progreso()
		Crear_First_Time_Minute()
		Variables_Dinamicas.Dinero=1000
		Crear_Alquiler()
		Crear_Objetos_Iniciales()

#Creará una matriz de 1339 filas y 574 columnas, llena de "". Las filas representaran los minutos de un día y
#las columnas los dias, que seran de 7 dias por 82 años 
func Crear_Matriz(): 
	var filas = 1440
	var columnas = 574
	for i in range(filas):
		Variables_Dinamicas.Matriz_Jugador.append([]) # Agregar una nueva fila vacía
		for j in range(columnas):
			Variables_Dinamicas.Matriz_Jugador[i].append("") # Llenar con cadenas vacías

#Se utilizara para crear la personalidad del personaje. Solo se va a utilizará por una vez.
func Crear_Personalidad():
	var Personalidad_int=Funciones_Globales.Generar_Numero_Aleatorio_Entero(1,3)
	if(Personalidad_int==1):
		Variables_Estaticas.Personalidad="Trabajador_Compulsivo"
	elif(Personalidad_int==2):
		Variables_Estaticas.Personalidad="Culo_Del_Sofa"
	elif(Personalidad_int==3):
		Variables_Estaticas.Personalidad="Deportista"

func Crear_Habilidades():
	for i in range(0,6):

		Variables_Estaticas.Habilidades.append(Funciones_Globales.Generar_Numero_Aleatorio_Entero(1,100))

func Crear_Habilidades_Mostradas():
	for i in range(0,6):
		Variables_Dinamicas.Habilidades_Mostradas.append(0)

func Crear_Alquiler():
	# El personaje empieza con casa. El primer alquiler se cobrará 7 días después.
	Variables_Dinamicas.En_La_Calle = false
	Variables_Dinamicas.Ultima_Fecha_Alquiler = Variables_Dinamicas.Minute_Day * 1440 + Variables_Dinamicas.Minute_Minute

func Crear_Objetos_Iniciales():
	# El jugador empieza con los objetos básicos de cada categoría seleccionados.
	# Estos no se pueden vender si son el único de su categoría (es_basico = true).
	Variables_Dinamicas.Objetos_Poseidos = {
		"Cama_Basica": true,
		"Mesa_Basica": true,
		"Ducha_Basica": true
	}
	Variables_Dinamicas.Objeto_Seleccionado = {
		"Dormir": "Cama_Basica",
		"Comer": "Mesa_Basica",
		"Duchar": "Ducha_Basica"
	}

func Crear_Progreso():
	for i in range(0,3):
		Variables_Dinamicas.Progreso.append(1)

func Crear_Necesidades_Basicas():
	for i in range(0,5):
		Variables_Dinamicas.Necesidades_Basicas.append(50)

func Crear_First_Time_Minute():
	var tiempo_actual = Time.get_unix_time_from_system()
	var dict_fecha = Time.get_date_dict_from_system()
	var dict_hora = Time.get_time_dict_from_system()
	#Queremos que 0 sea Lunes, No 1. Y domingo 6, no 0. Para eso se le suma 6: Lunes sera 7 Martes 8... Domingo 6. Y establecememos el restante con el 7, lunes 0, martes 1... domingo 6
	Variables_Estaticas.First_Time_Minute_Day=((dict_fecha["weekday"])+6)%7
	Variables_Estaticas.First_Time_Minute_Minute=(dict_hora["hour"]*60)+dict_hora["minute"]
	Variables_Estaticas.First_Time_Minute=floor(tiempo_actual / 60)
	# Fecha local del primer arranque para aritmética de días insensible a DST/zona horaria
	Variables_Estaticas.First_Time_Year=dict_fecha["year"]
	Variables_Estaticas.First_Time_Month=dict_fecha["month"]
	Variables_Estaticas.First_Time_Day_Of_Month=dict_fecha["day"]
	Variables_Estaticas.First_Time=false
	Variables_Dinamicas.Minute=Variables_Estaticas.First_Time_Minute
	Variables_Dinamicas.Minute_Day=Variables_Estaticas.First_Time_Minute_Day
	Variables_Dinamicas.Minute_Minute=Variables_Estaticas.First_Time_Minute_Minute
