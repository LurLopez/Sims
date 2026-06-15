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
	Variables_Dinamicas.Trabajo_Actual = actividad
	Funciones_Globales.Guardar_Matriz_Dia(10)
	Funciones_Globales.Guardar_Matriz()


# Cancela el trabajo: borra TODAS las celdas futuras (desde el minuto actual)
# que tengan asignada esta actividad de trabajo. El jugador deja de trabajar.
func Dejar_Trabajo(actividad: Actividad_Fija_Trabajo):
	var dia_actual = Variables_Dinamicas.Minute_Day
	var minuto_actual = Variables_Dinamicas.Minute_Minute
	for i in range(dia_actual, 574):
		var inicio_dia = 0
		if i == dia_actual:
			inicio_dia = minuto_actual
		for j in range(inicio_dia, 1440):
			var celda = Variables_Dinamicas.Matriz_Jugador[j][i]
			# Hay que filtrar strings ("" o "Actividad_Aleatoria") antes de comparar
			# con la actividad (objeto), porque String == Object lanza error de tipo.
			if celda is Actividad_Fija_Trabajo and celda == actividad:
				Variables_Dinamicas.Matriz_Jugador[j][i] = ""
	Variables_Dinamicas.Trabajo_Actual = null


func _process(delta):
	pass
