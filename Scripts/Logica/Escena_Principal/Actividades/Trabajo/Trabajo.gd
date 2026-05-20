extends Node

func Trabajar_En_Comida_Rapida():
	Trabajar(Variables_Estaticas.Catalogo_Actividades["Trabajar_En_Comida_Rapida"])

func Trabajar_De_Carpintero():
	Trabajar(Variables_Estaticas.Catalogo_Actividades["Trabajar_De_Carpintero"])

func Trabajar_De_Cientifico():
	Trabajar(Variables_Estaticas.Catalogo_Actividades["Trabajar_De_Cientifico"])


func Trabajar(actividad: Actividad_Fija_Trabajo):
	var Numero_De_Semana = floor(Variables_Dinamicas.Minute_Day / 7)
	for i in range((Numero_De_Semana + 1) * 7, 573):
		var dia_semana = i % 7
		if dia_semana not in actividad.dias_laborales:
			continue
		for j in range(actividad.hora_inicio, actividad.hora_final):
			Variables_Dinamicas.Matriz_Jugador[j][i] = actividad
	Funciones_Globales.Guardar_Matriz_Dia(10)
	Funciones_Globales.Guardar_Matriz()


func _process(delta):
	pass
