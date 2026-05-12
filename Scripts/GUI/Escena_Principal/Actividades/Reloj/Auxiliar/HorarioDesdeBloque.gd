extends Node

class_name HorarioDesdeBloque

var dia_inicio
var hora_inicio
var minuto_inicio

var dia_final
var hora_final
var minuto_final

func Inicializar(dia_i,hora_i,minuto_i,dia_f,hora_f,minuto_f):
	dia_inicio=dia_i
	hora_inicio=hora_i
	minuto_inicio=minuto_i
	dia_final=dia_f
	hora_final=hora_f
	minuto_final=minuto_f


	
func dia_inicio_int():
	return Funciones_Globales.Dia_A_Numero(dia_inicio)

func dia_final_int():
	return Funciones_Globales.Dia_A_Numero(dia_final)
