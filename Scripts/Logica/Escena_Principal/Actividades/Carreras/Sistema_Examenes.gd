extends Node

const UMBRAL_APROBACION: int = 50
const SIGMA_DESVIACION: float = 50.0
const PESO_PROGRESO: float = 0.60
const PESO_HABILIDADES: float = 0.20
const PESO_NECESIDADES: float = 0.20
const PESO_NOTA_REAL: float = 0.1
const BONUS_DINERO_CARRERA_COMPLETADA: float = 2000.0

func Calcular_Habilidades_Academicas() -> float:
	var habs = Variables_Estaticas.Habilidades
	if habs.size() < 7:
		return 0.0
	var inteligencia = habs[1]
	var memoria = habs[3]
	var sangre_fria = habs[6]
	return (inteligencia * 0.35) + (memoria * 0.15) + (sangre_fria * 0.50)

func Calcular_Necesidades_Examen() -> float:
	var nec = Variables_Dinamicas.Necesidades_Basicas
	if nec.size() < 5:
		return 0.0
	var salud_mental = nec[1]
	var hambre = nec[2]
	var descanso = nec[3]
	return (descanso * 0.40) + (salud_mental * 0.40) + (hambre * 0.20)

func Distribucion_Normal(media: float, sigma: float = SIGMA_DESVIACION) -> float:
	var u1 = max(randf(), 0.0001)
	var u2 = randf()
	var z = sqrt(-2.0 * log(u1)) * cos(2.0 * PI * u2)
	var resultado = media + (z * sigma)
	return clamp(resultado, 0.0, 100.0)

func Calcular_Nota_Final(carrera: Carrera) -> float:
	var progreso = carrera.progreso_actual
	var hab_acad = Calcular_Habilidades_Academicas()
	var nec = Calcular_Necesidades_Examen()
	var bonus_jugador = carrera.nota_real_ultima * PESO_NOTA_REAL

	# Calcular valor esperado incluyendo TODO
	var valor_esperado = (progreso * PESO_PROGRESO) + (hab_acad * PESO_HABILIDADES) + (nec * PESO_NECESIDADES) + bonus_jugador

	# Aplicar variancia DESPUÉS de sumar todo (puede cambiar aprobado a suspendido)
	var nota_final = Distribucion_Normal(valor_esperado)
	return clamp(nota_final, 0.0, 100.0)

func Procesar_Fin_De_Semana(carrera: Carrera) -> Dictionary:
	var nota_final = Calcular_Nota_Final(carrera)
	var aprobado = nota_final >= UMBRAL_APROBACION
	var matricula_honor = nota_final >= 90
	var resultado = {
		"año": carrera.año_actual,
		"nota_final": nota_final,
		"aprobado": aprobado,
		"matricula_honor": matricula_honor,
		"nota_real_jugador": carrera.nota_real_ultima,
		"carrera_completada": false
	}
	carrera.historial_notas.append(resultado)

	# Guardar en la carrera para mostrar en la UI
	carrera.ultima_nota_final = nota_final
	carrera.ultimo_resultado_aprobado = aprobado

	# Log del resultado
	var estado = "APROBADO" if aprobado else "SUSPENDIDO"
	print("=== FIN DE SEMANA CARRERA ===")
	print("Año %d: %s (Nota: %.1f)" % [carrera.año_actual, estado, nota_final])
	print("  Progreso: %.1f%%" % carrera.progreso_actual)
	print("  Nota jugador: %d" % carrera.nota_real_ultima)
	print("===========================")

	if aprobado:
		carrera.año_actual += 1
		carrera.progreso_actual = 0.0
		carrera.num_intentos = 0
		if carrera.año_actual > carrera.años_totales:
			carrera.completada = true
			resultado["carrera_completada"] = true
			Variables_Dinamicas.Dinero += BONUS_DINERO_CARRERA_COMPLETADA
		else:
			var libro_siguiente = "Anio_%d" % carrera.año_actual
			if not carrera.libros_desbloqueados.has(libro_siguiente):
				carrera.libros_desbloqueados.append(libro_siguiente)
	else:
		carrera.num_intentos += 1

	carrera.examen_realizado_esta_semana = false
	carrera.nota_real_ultima = 0
	return resultado

func Puede_Matricularse(carrera_nombre: String) -> bool:
	if Variables_Dinamicas.Carrera_Actual != null:
		return false
	return Variables_Dinamicas.Dinero >= 500.0

func Matricular(carrera: Carrera) -> bool:
	if Variables_Dinamicas.Carrera_Actual != null:
		return false
	if Variables_Dinamicas.Dinero < carrera.costo_matricula_anual:
		return false
	Variables_Dinamicas.Dinero -= carrera.costo_matricula_anual
	carrera.dinero_matricula_gastado += carrera.costo_matricula_anual
	Variables_Dinamicas.Carrera_Actual = carrera
	return true

const POR_CUANTO_EFECTO_CARRERA: int = 4
const POR_CUANTO_ECUACION_CARRERA: int = 20

func Incrementar_Progreso_Carrera(carrera: Carrera):
	if carrera == null or carrera.completada:
		return
	if carrera.progreso_actual >= 100.0:
		return
	var habs = Variables_Estaticas.Habilidades
	if habs.size() < 7:
		return
	var inteligencia = habs[1]
	var memoria = habs[3]
	var paciencia = habs[5]
	var sum_habilidades = (50 * inteligencia) + (20 * paciencia) + (30 * memoria)
	var max_val = Actividades_Habilidades.Calcular_Max_Numero_Aleatorio(
		int(carrera.progreso_actual),
		sum_habilidades,
		POR_CUANTO_ECUACION_CARRERA
	)
	var max_ajustado = floor(max_val / POR_CUANTO_EFECTO_CARRERA)
	if max_ajustado < 1:
		max_ajustado = 1
	if Funciones_Globales.Generar_Numero_Aleatorio_Entero_Es_Cero(int(max_ajustado)):
		carrera.progreso_actual = min(100.0, carrera.progreso_actual + 1.0)
