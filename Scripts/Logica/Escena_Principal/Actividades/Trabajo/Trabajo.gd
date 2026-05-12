extends Node

func Trabajar_En_Comida_Rapida():
	Trabajar("Trabajar_En_Comida_Rapida",480,960)

func Trabajar_De_Carpintero():
	Trabajar("Trabajar_De_Carpintero",360,840)

func Trabajar_De_Cientifico():
	Trabajar("Trabajar_De_Cientifico",480,960)



func Trabajar(nombre,inicio,final):
	var Numero_De_Semana=floor(Variables_Dinamicas.Minute_Day/7)
	for i in range((Numero_De_Semana+1)*7, 573):
		var Fin_De_Semana=i%7
		if (Fin_De_Semana!=5 and Fin_De_Semana!=6):
			for j in range(inicio,final):
				Variables_Dinamicas.Matriz_Jugador[j][i]=nombre
	Funciones_Globales.Guardar_Matriz_Dia(10)
	Funciones_Globales.Guardar_Matriz()
	


 
func _process(delta):
	pass
