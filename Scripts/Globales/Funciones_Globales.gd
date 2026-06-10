extends Node

func Guardar_Matriz():
	var filas =1439 
	var columnas = 574
	Crear_Todas_Las_Carpetas()
	
	var file = FileAccess.open("user://guardado//otros//Guardar_Matriz.txt", FileAccess.ModeFlags.WRITE)
	
	for col in range(columnas):
		var column = []
		file.store_line(str(col))
		file.store_line(str(Devolver_Dia(col)))
		for i in range (24):	
			file.store_line(str(i))
			for row in range(60):
				column.append(Variables_Dinamicas.Matriz_Jugador[i*60+row][col])
			file.store_line(str(column))
			column=[]

func Guardar_Matriz_Dia(dia):
	var filas =1439 
	Crear_Carpeta("user://guardado//otros")
	var file = FileAccess.open("user://guardado//otros//Matriz_Dia.txt", FileAccess.ModeFlags.WRITE)
	var column=[]
	file.store_line(str(dia))
	for i in range (24):	
		file.store_line(str(i))
		for row in range(60):
			column.append(Variables_Dinamicas.Matriz_Jugador[row][dia])
		file.store_line(str(column))
		column=[]
		
	return column

func Print_Matriz_Dia_Y_Minuto(dia,minuto):
	dia=Guardar_Matriz_Dia(dia)
	print(dia[minuto])
func Dia_A_Numero(dia):
	if(dia=="Lunes"):
		return 0
	if(dia=="Martes"):
		return 1
	if(dia=="Miercoles"):
		return 2
	if(dia=="Jueves"):
		return 3
	if(dia=="Viernes"):
		return 4
	if(dia=="Sabado"):
		return 5
	if(dia=="Domingo"):
		return 6
	return -1

func Devolver_Dia(numero):
	var dia_de_semana=numero%7
	if(dia_de_semana==0):
		return "Lunes"
	if (dia_de_semana==1):
		return "Martes"
	if (dia_de_semana==2):
		return "Miercoles"
	if(dia_de_semana==3):
		return "Jueves"
	if (dia_de_semana==4):
		return "Viernes"
	if (dia_de_semana==5):
		return "Sabado"
	if (dia_de_semana==6):
		return "Domingo"

func Devolver_Dia_Reducido(numero):
	var dia_de_semana=numero%7
	if(dia_de_semana==0):
		return "L"
	if (dia_de_semana==1):
		return "M"
	if (dia_de_semana==2):
		return "X"
	if(dia_de_semana==3):
		return "J"
	if (dia_de_semana==4):
		return "V"
	if (dia_de_semana==5):
		return "S"
	if (dia_de_semana==6):
		return "D"

func Dia_Reducido_A_Numero(dia):
	if(dia=="L"):
		return 0
	if(dia=="M"):
		return 1
	if(dia=="X"):
		return 2
	if(dia=="J"):
		return 3
	if(dia=="V"):
		return 4
	if(dia=="S"):
		return 5
	if(dia=="D"):
		return 6
	else: return -1
func Crear_Carpeta(guardado):
	var dir = DirAccess.open("user://")
	if not dir.dir_exists(guardado):
		dir.make_dir(guardado)

func Crear_Todas_Las_Carpetas():
	Crear_Carpeta("user://guardado")
	Crear_Carpeta("user://guardado//variables")
	Crear_Carpeta("user://guardado//otros")

func Devolver_Bloque_Matriz_Semana_(semana):
	var devolver_matriz = []
	var fila = 288
	var columna = 7
	for i in range(fila):
		devolver_matriz.append([])
		for j in range(columna):
			devolver_matriz[i].append("")

	var minuto_principio=0
	var dia_principio=semana*7
	var dia_final=dia_principio+7
	var dia_de_la_matriz=0

	while(dia_principio<dia_final):
		var libre=_Celda_A_Clave(Variables_Dinamicas.Matriz_Jugador[minuto_principio*5][dia_principio])
		for i in range(0,5):
			var buscar_minuto=minuto_principio*5+i
			var celda=Variables_Dinamicas.Matriz_Jugador[buscar_minuto][dia_principio]
			if celda is String and celda=="Actividad_Aleatoria":
				libre="Actividad_Aleatoria"
		devolver_matriz[minuto_principio][dia_de_la_matriz]=libre
		if(minuto_principio==287):
			minuto_principio=0
			dia_principio+=1
			dia_de_la_matriz+=1
		else:
			minuto_principio+=1

	return devolver_matriz

func _Celda_A_Clave(celda) -> String:
	if celda is Actividad:
		return celda.nombre
	if celda is String:
		return celda
	return ""
	




#Por_Cuanto es la variable que le dira por cuanto afectara a las necesidades basicas.Por Ejemplo, Higiene sera 20. Si se resta sera negativo
#indice sera el indice de las necesidades basicas. 1 sera salud fisica, 2 salud mental...
# Frecuancia sera la media de la que deberia de cambiar. Por ejemplo, Salud fisica, sera cada 30 minutos. Si es x3, por ejemplo, en ese caso la frecuencia sera de 10 minutos.



func Valor_Absoluto(valor):
	if(valor<0):
		return(-valor)
	else:
		return valor

func Es_Positivo_Int(valor):
	if(valor>0):
		return 1
	else:
		return -1



func Es_Positivo(valor):
	if(valor>0):
		return true
	else:
		return false
		

func Es_Cero(valor):
	if(valor==0):
		return true

func Generar_Numero_Aleatorio_Entero(min: int, max: int) -> int:
	var random = RandomNumberGenerator.new()
	random.randomize()  # Inicializa el generador con una semilla aleatoria
	return random.randi_range(min, max)

func Generar_Numero_Aleatorio_Entero_Es_Cero(max):
	var numero = Generar_Numero_Aleatorio_Entero(1,max)
	if(numero==1):
		return true

func Visibilizar_Objeto(ObjectoList):
	for node in ObjectoList:
		node.modulate.a = 1.0    #hace que no sea transparente
		node.disabled = false    #hace que el boton vuelva a hacer algo

func Desvisibilizar_Objeto(ObjectoList):
	for node in ObjectoList:
		node.modulate.a = 0.0    #hace completamente transparente
		node.disabled = true     #cuando le des al boton no hace nada


func Convertir_Minuto_A_Fecha_Hora(minuto: int) -> String:
	var dia_absoluto = minuto / 1440
	var minuto_del_dia = minuto % 1440
	var hora = minuto_del_dia / 60
	var min_final = minuto_del_dia % 60
	var dias_semana = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]
	var dia_nombre = dias_semana[dia_absoluto % 7]
	return "%s, %d:%02d" % [dia_nombre, hora, min_final]

#Para la interfaz:
func Mostrar_Habilidades():
	pass
