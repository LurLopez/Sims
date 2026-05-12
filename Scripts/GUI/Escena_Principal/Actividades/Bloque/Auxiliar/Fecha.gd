extends Node

class_name fecha


var dia
var minuto

func Inicializar(d,m):
	
	dia=d
	minuto=m

func Comparar_Dos_Fechas(f:fecha):   #Si es true, significa que la fecha del parametro es antes que el otro
	if(dia>f.dia):
		return true
	elif(dia<f.dia): return false
	if(minuto>=f.minuto):
		return true
	else: return false
