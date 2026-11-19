class_name Carrera_Medicina
extends Carrera

func _init():
	nombre = "Medicina"
	slug_contenido = "medicina"
	emoji = "🩺"
	años_totales = 5
	costo_matricula_anual = 750.0
	ajuste_dificultad = -10.0
	año_actual = 1
	progreso_actual = 0.0
	historial_notas = []
	num_intentos = 0
	dinero_matricula_gastado = 0.0
	examen_realizado_esta_semana = false
	nota_real_ultima = 0
	libros_desbloqueados = ["Anio_1"]
	completada = false
